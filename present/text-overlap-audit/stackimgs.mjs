// node stackimgs.mjs out.png a.png b.png … — ต่อภาพแนวตั้ง
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'
const here = path.dirname(fileURLToPath(import.meta.url))
const [out, ...ins] = process.argv.slice(2)
const puppeteer = createRequire(path.join(here, '../../sync-server/package.json'))('puppeteer-core')
const browser = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: true, args: ['--allow-file-access-from-files'] })
const tab = await browser.newPage()
await tab.setViewport({ width: 1600, height: 800, deviceScaleFactor: 1 })
const f = path.join(here, 'out/_stack.html')
fs.writeFileSync(f, `<body style="margin:0;background:#111;width:1600px">${ins.map((p) => `<img src="file://${path.resolve(p)}" style="display:block;max-width:1600px;margin-bottom:4px">`).join('')}</body>`)
await tab.goto('file://' + f, { waitUntil: 'load' })
await tab.screenshot({ path: out, fullPage: true })
await browser.close()
