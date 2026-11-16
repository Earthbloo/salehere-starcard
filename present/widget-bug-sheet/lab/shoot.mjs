#!/usr/bin/env node
// node shoot.mjs cases.json [nameFilter] → shots/<name>.png  (ต้องเปิด preview sync-server 8787 + remove-bg-picker 8794)
import fs from 'node:fs'; import path from 'node:path'; import { fileURLToPath } from 'node:url'; import { createRequire } from 'node:module'
const here = path.dirname(fileURLToPath(import.meta.url))
const require = createRequire(path.resolve(here, '../../../sync-server/package.json'))
const puppeteer = require('puppeteer-core')
const cases = JSON.parse(fs.readFileSync(path.join(here, process.argv[2] || 'cases.json'), 'utf8'))
const only = process.argv[3]
const browser = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: 'new' })
const page = await browser.newPage()
page.on('pageerror', e => console.log('PAGEERR', e.message))
await page.setViewport({ width: 900, height: 900, deviceScaleFactor: 2 })
for (const c of cases) {
  if (only && !c.name.includes(only)) continue
  await page.goto('http://localhost:8794/widget-bug-sheet/lab/lab.html?c=' + encodeURIComponent(JSON.stringify(c)), { waitUntil: 'networkidle0' })
  await page.waitForFunction('window.__ready === true', { timeout: 20000 })
  const err = await page.evaluate('window.__err || ""'); if (err) console.log('ERR', c.name, err.slice(0, 300))
  await (await page.$('#shot')).screenshot({ path: path.join(here, 'shots', c.name + '.png') })
}
await browser.close(); console.log('done')
