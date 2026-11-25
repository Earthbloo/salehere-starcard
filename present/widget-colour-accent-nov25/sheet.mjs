// node sheet.mjs before|after [ids…] → sheet-<tag>-N.png (แถว = widget · คอลัมน์ = สีวิดเจ็ต)
import fs from 'node:fs'; import path from 'node:path'; import { fileURLToPath } from 'node:url'; import { createRequire } from 'node:module'
const here = path.dirname(fileURLToPath(import.meta.url)), repo = path.resolve(here, '../..')
const [tag, ...only] = process.argv.slice(2)
const cases = JSON.parse(fs.readFileSync(path.join(here, 'cases.json'))).filter((c) => !only.length || only.includes(c.id))
const puppeteer = createRequire(path.join(repo, 'sync-server/package.json'))('puppeteer-core')
const browser = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: true, userDataDir: process.env.CHROME_PROF, args: ['--no-first-run', '--allow-file-access-from-files'], timeout: 90000 })
const tab = await browser.newPage(); await tab.setViewport({ width: 1900, height: 800, deviceScaleFactor: 1 })
for (let p = 0; p * 5 < cases.length; p++) {
  const rows = cases.slice(p * 5, p * 5 + 5).map((c) => `<div style="font:14px sans-serif;margin:8px 0 2px">${c.id} — ${c.shots.map((s) => s.key).join(' · ')}</div><div style="display:flex;gap:6px;align-items:start">${c.shots.map((s) => `<img style="width:370px" src="file://${here}/img/${c.id}-${s.key}-${tag}.png">`).join('')}</div>`).join('')
  const f = path.join(here, `_sheet.html`); fs.writeFileSync(f, `<body style="margin:6px;background:#fff">${rows}</body>`)
  await tab.goto('file://' + f); await new Promise((r) => setTimeout(r, 400))
  await tab.screenshot({ path: path.join(here, `sheet-${tag}-${p}.png`), fullPage: true })
}
fs.rmSync(path.join(here, '_sheet.html')); await browser.close()
