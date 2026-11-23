// node present/text-overlap-audit/run.mjs [kind…]
//
// QA (SIT · STAR Card): แก้คำหัวข้อของ widget แล้วย่อ/ขยายกรอบ → ตัวอักษรล้นกล่องไปทับรูป/ข้อความอื่น
// สคริปต์นี้ไล่ **ทุกใบใน shared/WidgetSpecs** ด้วยตัวคำนวณ + ตัววัดของเว็บ (Chrome headless · ฟอนต์ของแอป)
//
// ต่อใบ: ขนาดกรอบหลายแบบ (ออกแบบ · หด · ขยาย · กว้าง · สูง · แคบ · เตี้ย — ตามที่ใบยอมให้ resize)
//        × คำหัวข้อหลายแบบ (คำของดีไซน์ · ไทยสั้น · ไทยกลาง · ไทยยาว · ไทยสระซ้อน · อังกฤษยาว) ใส่แทน `text` ของโหนด `editable`
// ตรวจ: กรอบหมึกของข้อความ (บนชิดกล่อง สูง = ที่วัดได้จริง — iOS/เว็บ วาด topLeading) ทับ รูป/ไอคอน/ข้อความอื่น
//       เพิ่มจากรอบคำของดีไซน์ที่ขนาดเดียวกัน · ข้อความหลุดขอบ widget · ข้อความสูงเกินกล่องตัวเอง
// ออก: present/text-overlap-audit/out/report.json + ภาพเคสที่แย่สุดต่อใบ (out/shots/<kind>.png)

import fs from 'node:fs'
import path from 'node:path'
import http from 'node:http'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'
import { iconResolver } from '../../sync-server/web-icons.mjs'

const here = path.dirname(fileURLToPath(import.meta.url))
const repo = path.resolve(here, '../..')
const webDir = path.join(repo, 'sync-server/web')
const fontDir = path.join(repo, 'StarCard/StarCard/Resources/Fonts')
const specDir = path.join(repo, 'shared/WidgetSpecs')
const outDir = path.join(here, 'out')
fs.mkdirSync(path.join(outDir, 'shots'), { recursive: true })
const only = process.argv.slice(2)

const require = createRequire(path.join(repo, 'sync-server/package.json'))
const puppeteer = require('puppeteer-core')
const chromePath = process.env.CHROME ?? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'

const walk = (d) => fs.readdirSync(d, { withFileTypes: true }).flatMap((e) => e.isDirectory() ? walk(path.join(d, e.name)) : e.name.endsWith('.json') ? [path.join(d, e.name)] : [])
const specs = walk(specDir).map((f) => ({ file: path.relative(specDir, f), json: JSON.parse(fs.readFileSync(f, 'utf8')) }))
  .filter((s) => s.json.kind && s.json.root && (!only.length || only.includes(s.json.kind)))

const MIME = { '.js': 'text/javascript', '.html': 'text/html; charset=utf-8', '.ttf': 'font/ttf', '.otf': 'font/otf', '.json': 'application/json', '.png': 'image/png', '.jpg': 'image/jpeg', '.svg': 'image/svg+xml' }
const resolveIcon = iconResolver(repo)
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
  if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) { res.statusCode = 404; return res.end('nf ' + rel) }
  res.setHeader('content-type', MIME[path.extname(file)] ?? 'application/octet-stream')
  fs.createReadStream(file).pipe(res)
})
await new Promise((ok) => server.listen(0, '127.0.0.1', ok))
const base = `http://127.0.0.1:${server.address().port}`

const browser = await puppeteer.launch({ executablePath: chromePath, headless: true, args: ['--no-first-run', '--disable-gpu', '--force-device-scale-factor=2', '--lang=th-TH'] })
const tab = await browser.newPage()
tab.on('pageerror', (e) => console.error('page error:', e.message))
tab.on('console', (m) => { if (m.type() === 'error') console.error('console:', m.text()) })
await tab.goto(`${base}/harness.html`)
await tab.waitForFunction('window.ready === true', { timeout: 60_000 })

const results = []
for (const s of specs) {
  const r = await tab.evaluate((j) => window.audit(j), s.json)
  r.file = s.file
  results.push(r)
  if (r.worst) {
    await tab.evaluate((j, c) => window.show(j, c), s.json, r.worst)
    const el = await tab.$('#stage')
    await el.screenshot({ path: path.join(outDir, 'shots', `${s.json.kind}.png`) })
  }
  process.stdout.write(r.issues.length ? '!' : '.')
}
console.log()
fs.writeFileSync(path.join(outDir, 'report.json'), JSON.stringify(results, null, 1))
const bad = results.filter((r) => r.issues.length)
for (const r of bad) {
  const kinds = [...new Set(r.issues.map((i) => i.type))].join(',')
  console.log(`${r.kind.padEnd(22)} ${String(r.issues.length).padStart(4)}  ${kinds}  ${r.worst ? r.worst.label : ''}`)
}
console.log(`\n${bad.length}/${results.length} ใบมีปัญหา · ใบที่มีคำแก้ได้ ${results.filter((r) => r.editable.length).length}`)
await browser.close(); server.close()
