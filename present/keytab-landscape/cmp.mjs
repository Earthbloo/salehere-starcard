// ถ่ายภาพก่อน/หลังสำหรับ compare.html แล้วถ่าย compare.html ทั้งหน้า → compare.png
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'
const here = path.dirname(fileURLToPath(import.meta.url))
const puppeteer = createRequire(path.resolve(here, '../../sync-server/package.json'))('puppeteer-core')
const browser = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: 'new' })
const page = await browser.newPage()
await page.setViewport({ width: 420, height: 360, deviceScaleFactor: 2 })
const jobs = []
for (const v of ['old', 'current']) for (const n of [3, 5]) {
  jobs.push([v, n, 342, 155, 'purple'], [v, n, 250, 135, 'light'], [v, n, 109, 307, 'purple'])
}
for (const [v, n, w, h, t] of jobs) {
  await page.goto(`http://localhost:8794/keytab-landscape/lab.html?v=${v}&n=${n}&w=${w}&h=${h}&t=${t}`, { waitUntil: 'networkidle0' })
  await page.waitForFunction('window.__ready === true', { timeout: 15000 })
  await (await page.$('#shot')).screenshot({ path: path.join(here, 'shots', `cmp-${v}-n${n}-${w}x${h}-${t}.png`) })
}
await page.setViewport({ width: 1188, height: 800, deviceScaleFactor: 2 })
await page.goto('http://localhost:8794/keytab-landscape/compare.html', { waitUntil: 'networkidle0' })
await page.screenshot({ path: path.join(here, 'compare.png'), fullPage: true })
await browser.close()
console.log('ok')
