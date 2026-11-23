// ถ่ายหน้า dev/reel-brand.html → present/reel-brand/<name>.png
// ใช้: node present/reel-brand/shoot.mjs [--server http://localhost:8787] [--sizes 366x300,...] [--n 4] [--out name] [--scale 2]
import { createRequire } from 'node:module'
import fs from 'node:fs'
import path from 'node:path'
import url from 'node:url'
const here = path.dirname(url.fileURLToPath(import.meta.url))
const repo = path.resolve(here, '../..')
const argv = process.argv.slice(2)
const opt = (k, d) => (argv.includes(k) ? argv[argv.indexOf(k) + 1] : d)
const server = opt('--server', 'http://localhost:8787')
const sizes = opt('--sizes', '')
const n = opt('--n', '')
const name = opt('--out', 'reelBrand')
const scale = Number(opt('--scale', '2'))
const require = createRequire(path.join(repo, 'sync-server/web/test/measure-parity.mjs'))
const puppeteer = require('puppeteer-core')
const browser = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: true, timeout: 180000, args: ['--hide-scrollbars', '--font-render-hinting=none'] })
const page = await browser.newPage()
await page.setViewport({ width: 3400, height: 900, deviceScaleFactor: scale })
const q = new URLSearchParams()
if (sizes) q.set('sizes', sizes)
if (n) q.set('n', n)
await page.goto(`${server}/card/dev/reel-brand.html?${q}`, { waitUntil: 'networkidle2', timeout: 90000 })
await page.waitForFunction(() => document.querySelectorAll('.cell img').length > 0 && [...document.images].every((i) => i.complete))
await new Promise((r) => setTimeout(r, 800))
const sec = await page.$('section')
const file = path.join(here, `${name}.png`)
await sec.screenshot({ path: file })
console.log(file)
await browser.close()
