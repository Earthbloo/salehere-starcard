// node present/text-overlap-audit/compose.mjs — รวม out/rows/*.png เป็นแผ่นละ 8 ภาพ (out/sheet-N.png)
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'
const here = path.dirname(fileURLToPath(import.meta.url))
const rows = fs.readdirSync(path.join(here, 'out/after')).filter((f) => f.endsWith('.png')).sort()
const puppeteer = createRequire(path.join(here, '../../sync-server/package.json'))('puppeteer-core')
const browser = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: true, args: ['--allow-file-access-from-files'] })
const tab = await browser.newPage()
await tab.setViewport({ width: 2000, height: 1000, deviceScaleFactor: 1 })
for (let k = 0; k < rows.length; k += 4) {
  const imgs = rows.slice(k, k + 4).map((f) => `<img src="file://${path.join(here, 'out/after', f)}">`).join('')
  const html = `<html><body style="margin:0;background:#111;display:grid;grid-template-columns:1fr;gap:6px;width:2000px">${imgs}<style>img{width:100%;height:auto;display:block}</style></body></html>`
  const f = path.join(here, `out/_sheet.html`); fs.writeFileSync(f, html)
  await tab.goto('file://' + f, { waitUntil: 'load' })
  await tab.screenshot({ path: path.join(here, `out/after-${k / 4 + 1}.png`), fullPage: true })
}
await browser.close()
