// ถ่ายภาพ 3 widget ผลงาน ก่อน/หลัง × มี/ไม่มี engagement จาก sync-server/web/dev/work-text.html (ตัววาดเว็บตัวจริง)
// ใช้: node present/work-text/shoot.mjs [--server http://localhost:8787]
import { createRequire } from 'node:module'
import fs from 'node:fs'
import path from 'node:path'
import url from 'node:url'
const here = path.dirname(url.fileURLToPath(import.meta.url))
const repo = path.resolve(here, '../..')
const argv = process.argv.slice(2)
const server = argv.includes('--server') ? argv[argv.indexOf('--server') + 1] : 'http://localhost:8787'
const require = createRequire(path.join(repo, 'sync-server/web/test/measure-parity.mjs'))
const puppeteer = require('puppeteer-core')
fs.mkdirSync(path.join(here, 'shots'), { recursive: true })
const browser = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: true, timeout: 180000, args: ['--hide-scrollbars', '--font-render-hinting=none'] })
const page = await browser.newPage()
await page.setViewport({ width: 1200, height: 900, deviceScaleFactor: 2 })
const names = ['eng-before', 'eng-after', 'zero-before', 'zero-after']
// [ชื่อไฟล์, kind, ขนาดกรอบ] — wallPolaroidWide = กรอบแนวนอน 620×200 (เหมือนวางเต็มกว้างการ์ดแต่เตี้ย)
for (const [kind, k, size] of [['proofTicket', 'proofTicket', ''], ['proofWork', 'proofWork', ''], ['wallPolaroid', 'wallPolaroid', ''], ['wallPolaroidWide', 'wallPolaroid', '&w=620&h=200']]) {
  await page.goto(`${server}/card/dev/work-text.html?kind=${k}${size}`, { waitUntil: 'networkidle0' })
  await page.waitForFunction(() => document.querySelectorAll('.cell img').length > 0 && [...document.images].every((i) => i.complete))
  await new Promise((r) => setTimeout(r, 800))
  const cells = await page.$$('.cell')
  for (let i = 0; i < cells.length; i++) {
    await cells[i].screenshot({ path: path.join(here, 'shots', `${kind}-${names[i]}.png`) })
    console.log(kind, names[i])
  }
}
await browser.close()
