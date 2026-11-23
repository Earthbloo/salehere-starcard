// node present/text-overlap-audit/sheet.mjs — แผ่นรวมภาพ: ต่อใบ = ดีไซน์ | เคสแรกที่พัง (จาก out/first.json)
import fs from 'node:fs'
import path from 'node:path'
import http from 'node:http'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'
import { iconResolver } from '../../sync-server/web-icons.mjs'
const here = path.dirname(fileURLToPath(import.meta.url))
const repo = path.resolve(here, '../..')
const webDir = path.join(repo, 'sync-server/web'), fontDir = path.join(repo, 'StarCard/StarCard/Resources/Fonts'), specDir = path.join(repo, 'shared/WidgetSpecs')
const walk = (d) => fs.readdirSync(d, { withFileTypes: true }).flatMap((e) => e.isDirectory() ? walk(path.join(d, e.name)) : e.name.endsWith('.json') ? [path.join(d, e.name)] : [])
const specs = Object.fromEntries(walk(specDir).map((f) => JSON.parse(fs.readFileSync(f, 'utf8'))).filter((j) => j.kind).map((j) => [j.kind, j]))
const TEXT = { 'คำเดิม': null, 'ไทยสั้น': 'เทส', 'ไทยกลาง': 'ผลงานของฉัน', 'ไทยยาว': 'รีวิวสินค้าความงามและไลฟ์สไตล์ทุกวัน', 'สระซ้อน': 'ปั้นยิ้มที่นี่ญี่ปุ่น', 'อังกฤษยาว': 'MY LATEST COLLABORATIONS 2026' }
const K = { M: 1, L: 1.3, XL: 1.7, XXL: 2.2 }
const list = JSON.parse(fs.readFileSync(path.join(here, 'out/first.json'), 'utf8'))
const resolveIcon = iconResolver(repo)
const MIME = { '.js': 'text/javascript', '.html': 'text/html; charset=utf-8', '.ttf': 'font/ttf', '.otf': 'font/otf' }
const server = http.createServer((req, res) => {
  const rel = decodeURIComponent(new URL(req.url, 'http://x').pathname)
  if (rel.startsWith('/icon/')) {
    const hit = resolveIcon(rel.slice(6))
    if (!hit) { res.statusCode = 404; return res.end() }
    if (hit.svg) { res.setHeader('content-type', 'image/svg+xml'); return res.end(hit.svg) }
    res.setHeader('content-type', path.extname(hit.file) === '.svg' ? 'image/svg+xml' : 'image/png'); return res.end(fs.readFileSync(hit.file))
  }
  if (rel === '/harness.html') { res.setHeader('content-type', MIME['.html']); return res.end(fs.readFileSync(path.join(here, 'harness.html'))) }
  const file = rel.startsWith('/fonts/') ? path.join(fontDir, rel.slice(7)) : path.join(webDir, rel)
  if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) { res.statusCode = 404; return res.end() }
  res.setHeader('content-type', MIME[path.extname(file)] ?? 'application/octet-stream'); fs.createReadStream(file).pipe(res)
})
await new Promise((ok) => server.listen(0, '127.0.0.1', ok))
const puppeteer = createRequire(path.join(repo, 'sync-server/package.json'))('puppeteer-core')
const browser = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: true, args: ['--force-device-scale-factor=1.5'] })
const tab = await browser.newPage()
await tab.goto(`http://127.0.0.1:${server.address().port}/harness.html`)
await tab.waitForFunction('window.ready === true', { timeout: 60000 })
fs.mkdirSync(path.join(here, 'out/rows'), { recursive: true })
let n = 0
for (const x of list) {
  n++
  const j = specs[x.kind]
  const cases = [[`${n}. ${x.kind} · ดีไซน์`, j.design.w, j.design.h, null, 1],
    [`${x.size} ${x.W}×${x.H} · "${x.text}" ขนาด ${x.factor}`, x.W, x.H, TEXT[x.text], K[x.factor]]]
  await tab.evaluate((j, c) => window.showCases(j, c), j, cases)
  await (await tab.$('#stage')).screenshot({ path: path.join(here, `out/rows/${String(n).padStart(2, '0')}-${x.kind}.png`) })
}
await browser.close(); server.close()
