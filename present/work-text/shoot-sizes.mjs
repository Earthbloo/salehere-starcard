// ถ่ายหน้า dev/work-sizes.html ทีละ widget (หลายขนาด × มี/ไม่มี engagement) → present/work-text/sizes/<kind>[-n<N>].png
// ใช้: node present/work-text/shoot-sizes.mjs [--server http://localhost:8787] [--n 3] [--scale 1]
import { createRequire } from 'node:module'
import fs from 'node:fs'
import path from 'node:path'
import url from 'node:url'
const here = path.dirname(url.fileURLToPath(import.meta.url))
const repo = path.resolve(here, '../..')
const argv = process.argv.slice(2)
const opt = (k, d) => (argv.includes(k) ? argv[argv.indexOf(k) + 1] : d)
const server = opt('--server', 'http://localhost:8787')
const n = opt('--n', '')
const scale = Number(opt('--scale', '1'))
const pageName = opt('--page', 'work-sizes')
const only = opt('--kind', '')
const extra = opt('--query', '')   // ต่อท้าย URL เช่น &sizes=…&counts=…
const tag = opt('--tag', '')
const require = createRequire(path.join(repo, 'sync-server/web/test/measure-parity.mjs'))
const puppeteer = require('puppeteer-core')
fs.mkdirSync(path.join(here, 'sizes'), { recursive: true })
const browser = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: true, timeout: 180000, args: ['--hide-scrollbars', '--font-render-hinting=none'] })
const page = await browser.newPage()
await page.setViewport({ width: 1600, height: 900, deviceScaleFactor: scale })
for (const kind of (only ? only.split(',') : ['proofTicket', 'proofWork', 'wallPolaroid'])) {
  await page.goto(`${server}/card/dev/${pageName}.html?kind=${kind}${n ? `&n=${n}` : ''}${extra}`, { waitUntil: 'networkidle0' })
  await page.waitForFunction(() => document.querySelectorAll('.cell img').length > 0 && [...document.images].every((i) => i.complete))
  await new Promise((r) => setTimeout(r, 600))
  const sec = await page.$('section')
  const file = path.join(here, 'sizes', `${kind}${pageName === 'work-sizes' ? '' : '-' + pageName}${tag ? '-' + tag : ''}${n ? `-n${n}` : ''}.png`)
  await sec.screenshot({ path: file })
  console.log(file)
}
await browser.close()
