#!/usr/bin/env node
// ถ่ายทุกแบบของ lab.html (เว็บเรนเดอร์จริง) ที่ 2× → shots/<v>-n<n>-<w>x<h>-<t>.png
// ต้องเปิด preview "sync-server" (8787) + "remove-bg-picker" (8794 เสิร์ฟ present/)
//   node present/keytab-landscape/shoot.mjs [A B …]
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'

const here = path.dirname(fileURLToPath(import.meta.url))
const require = createRequire(path.resolve(here, '../../sync-server/package.json'))
const puppeteer = require('puppeteer-core')
const VARIANTS = [...fs.readFileSync(path.join(here, 'variants.js'), 'utf8').matchAll(/\bid: '([^']+)', name/g)].map((m) => ({ id: m[1] }))
const only = process.argv.slice(2)
const out = path.join(here, 'shots')
fs.mkdirSync(out, { recursive: true })

const SIZES = [[342, 155], [342, 110], [250, 135]]
const COUNTS = [1, 3, 5, 6]
const THEMES = ['purple', 'light']

const browser = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: 'new' })
const page = await browser.newPage()
await page.setViewport({ width: 420, height: 240, deviceScaleFactor: 2 })
for (const v of VARIANTS) {
  if (only.length && !only.includes(v.id)) continue
  for (const [w, h] of SIZES) for (const n of COUNTS) for (const t of THEMES) {
    const url = `http://localhost:8794/keytab-landscape/lab.html?v=${v.id}&n=${n}&w=${w}&h=${h}&t=${t}`
    await page.goto(url, { waitUntil: 'networkidle0' })
    await page.waitForFunction('window.__ready === true', { timeout: 15000 })
    const el = await page.$('#shot')
    await el.screenshot({ path: path.join(out, `${v.id}-n${n}-${w}x${h}-${t}.png`) })
  }
  console.log('done', v.id)
}
await browser.close()
