// node compare.mjs <beforeDir> — ภาพก่อน/หลังของใบที่แก้ (out/after/NN-kind.png)
import fs from 'node:fs'
import path from 'node:path'
import http from 'node:http'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'
import { iconResolver } from '../../sync-server/web-icons.mjs'
const here = path.dirname(fileURLToPath(import.meta.url))
const repo = path.resolve(here, '../..')
const webDir = path.join(repo, 'sync-server/web'), fontDir = path.join(repo, 'StarCard/StarCard/Resources/Fonts'), specDir = path.join(repo, 'shared/WidgetSpecs')
const before = process.argv[2]
const walk = (d) => fs.readdirSync(d, { withFileTypes: true }).flatMap((e) => e.isDirectory() ? walk(path.join(d, e.name)) : e.name.endsWith('.json') ? [path.join(d, e.name)] : [])
const now = Object.fromEntries(walk(specDir).map((f) => JSON.parse(fs.readFileSync(f, 'utf8'))).filter((j) => j.kind).map((j) => [j.kind, j]))
const T = { s: 'เทส', m: 'ผลงานของฉัน', l: 'รีวิวสินค้าความงามและไลฟ์สไตล์ทุกวัน', x: 'ปั้นยิ้มที่นี่ญี่ปุ่น', e: 'MY LATEST COLLABORATIONS 2026', '-': null }
// [kind, [label, W, H, textKey, k], ...]  W/H 0 = ขนาดออกแบบ
const PLAN = [
  [1, 'portfolioWindow', ['สระซ้อน M', 0, 0, 'x', 1], ['เทส XL', 0, 0, 's', 1.7]],
  [2, 'portfolioGingham', ['เทส M', 0, 0, 's', 1], ['เทส XL', 0, 0, 's', 1.7]],
  [4, 'scrapAbout', ['ไทยยาว M', 0, 0, 'l', 1], ['ไทยกลาง XL', 0, 0, 'm', 1.7]],
  [7, 'reelBrand', ['สระซ้อน M', 0, 0, 'x', 1], ['ไทยยาว L', 0, 0, 'l', 1.3]],
  [8, 'reelShowcase', ['เทส XL (เคส QA)', 0, 0, 's', 1.7], ['สระซ้อน M', 0, 0, 'x', 1]],
  [10, 'artPortfolio', ['สระซ้อน M', 0, 0, 'x', 1], ['เทส XL', 0, 0, 's', 1.7]],
  [21, 'kitSocialNight', ['อังกฤษยาว M', 0, 0, 'e', 1], ['ไทยยาว L', 0, 0, 'l', 1.3]],
  [23, 'audiencePoster', ['หด 0.55', 201, 286, '-', 1], ['สระซ้อน M', 0, 0, 'x', 1]],
  [24, 'scrapStats', ['สระซ้อน M', 0, 0, 'x', 1], ['คำเดิม L', 0, 0, '-', 1.3]],
  [26, 'wallMemory', ['แคบ ไทยยาว', 238, 366, 'l', 1], ['ออกแบบ', 0, 0, '-', 1]],
  [31, 'kitSocialMac', ['แคบ อังกฤษยาว', 215, 330, 'e', 1], ['ไทยยาว L', 0, 0, 'l', 1.3]],
  [36, 'scrapInfo', ['ไทยกลาง XXL', 0, 0, 'm', 2.2], ['คำเดิม XL', 0, 0, '-', 1.7]],
]
const resolveIcon = iconResolver(repo)
const server = http.createServer((req, res) => {
  const rel = decodeURIComponent(new URL(req.url, 'http://x').pathname)
  if (rel.startsWith('/icon/')) { const hit = resolveIcon(rel.slice(6)); if (!hit) { res.statusCode = 404; return res.end() } if (hit.svg) { res.setHeader('content-type', 'image/svg+xml'); return res.end(hit.svg) } res.setHeader('content-type', path.extname(hit.file) === '.svg' ? 'image/svg+xml' : 'image/png'); return res.end(fs.readFileSync(hit.file)) }
  if (rel === '/harness.html') { res.setHeader('content-type', 'text/html; charset=utf-8'); return res.end(fs.readFileSync(path.join(here, 'harness.html'))) }
  const file = rel.startsWith('/fonts/') ? path.join(fontDir, rel.slice(7)) : path.join(webDir, rel)
  if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) { res.statusCode = 404; return res.end() }
  res.setHeader('content-type', file.endsWith('.js') ? 'text/javascript' : 'application/octet-stream'); fs.createReadStream(file).pipe(res)
})
await new Promise((ok) => server.listen(0, '127.0.0.1', ok))
const puppeteer = createRequire(path.join(repo, 'sync-server/package.json'))('puppeteer-core')
const browser = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: true, args: ['--force-device-scale-factor=1.5'] })
const tab = await browser.newPage()
await tab.goto(`http://127.0.0.1:${server.address().port}/harness.html`)
await tab.waitForFunction('window.ready === true', { timeout: 60000 })
fs.mkdirSync(path.join(here, 'out/after'), { recursive: true })
for (const [n, kind, ...cases] of PLAN) {
  const b = JSON.parse(fs.readFileSync(path.join(before, kind + '.json'), 'utf8')), a = now[kind]
  const list = []
  for (const [lab, W, H, t, k] of cases) {
    list.push([b, `${n}. ${kind} · ก่อน · ${lab}`, W || b.design.w, H || b.design.h, T[t], k])
    list.push([a, `หลัง · ${lab}`, W || a.design.w, H || a.design.h, T[t], k])
  }
  await tab.evaluate((l) => window.showMulti(l), list)
  await (await tab.$('#stage')).screenshot({ path: path.join(here, `out/after/${String(n).padStart(2, '0')}-${kind}.png`) })
}
await browser.close(); server.close()
