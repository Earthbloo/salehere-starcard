// node present/insight-social/render.mjs — วาดวิดเจ็ต Insight ทั้ง 11 ตัว (ขนาดออกแบบ, 2x) + kitInsight แบบซ่อนหัวข้อ → img/*.png
import fs from 'node:fs'
import path from 'node:path'
import http from 'node:http'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'
import { iconResolver } from '../../sync-server/web-icons.mjs'
const here = path.dirname(fileURLToPath(import.meta.url))
const repo = path.resolve(here, '../..')
const webDir = path.join(repo, 'sync-server/web'), fontDir = path.join(repo, 'StarCard/StarCard/Resources/Fonts')
const specDir = path.join(repo, 'shared/WidgetSpecs/05-ผู้ชม')
const specs = Object.fromEntries(fs.readdirSync(specDir).filter((f) => f.endsWith('.json'))
  .map((f) => JSON.parse(fs.readFileSync(path.join(specDir, f), 'utf8'))).map((j) => [j.kind, j]))

// [ชื่อไฟล์, kind, hide]
const JOBS = Object.keys(specs).map((k) => [k, k, null])
const TOPICS = ['city', 'gender', 'age']
for (const k of Object.keys(specs).filter((k) => k.startsWith('kitInsight'))) {
  // ช่องมีหัวข้อชุดไหน → ซ่อนที่เหลือ
  for (let m = 1; m < 7; m++) {
    const has = TOPICS.filter((_, i) => m & (1 << i))
    if (has.length === 3) continue
    JOBS.push([`${k}--${has.join('-')}`, k, TOPICS.filter((t) => !has.includes(t)).join(',')])
  }
}

const MIME = { '.js': 'text/javascript', '.html': 'text/html; charset=utf-8', '.ttf': 'font/ttf', '.otf': 'font/otf' }
const resolveIcon = iconResolver(repo)
const server = http.createServer((req, res) => {
  const rel = decodeURIComponent(new URL(req.url, 'http://x').pathname)
  if (rel.startsWith('/icon/')) {
    const hit = resolveIcon(rel.slice(6))
    if (!hit) { res.statusCode = 404; return res.end() }
    if (hit.svg) { res.setHeader('content-type', 'image/svg+xml'); return res.end(hit.svg) }
    res.setHeader('content-type', path.extname(hit.file) === '.svg' ? 'image/svg+xml' : 'image/png'); return res.end(fs.readFileSync(hit.file))
  }
  if (rel === '/render.html') { res.setHeader('content-type', MIME['.html']); return res.end(fs.readFileSync(path.join(here, 'render.html'))) }
  const file = rel.startsWith('/fonts/') ? path.join(fontDir, rel.slice(7)) : path.join(webDir, rel)
  if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) { res.statusCode = 404; return res.end() }
  res.setHeader('content-type', MIME[path.extname(file)] ?? 'application/octet-stream'); fs.createReadStream(file).pipe(res)
})
await new Promise((ok) => server.listen(0, '127.0.0.1', ok))
const puppeteer = createRequire(path.join(repo, 'sync-server/package.json'))('puppeteer-core')
const browser = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: true, args: ['--force-device-scale-factor=2'] })
const tab = await browser.newPage()
await tab.setViewport({ width: 1200, height: 900, deviceScaleFactor: 2 })
tab.on('pageerror', (e) => console.error('pageerror', e.message))
await tab.goto(`http://127.0.0.1:${server.address().port}/render.html`)
await tab.waitForFunction('window.ready === true', { timeout: 60000 })
fs.mkdirSync(path.join(here, 'img'), { recursive: true })
for (const [name, kind, hide] of JOBS) {
  await tab.evaluate((j, h) => window.render(j, h), specs[kind], hide)
  await (await tab.$('#cell')).screenshot({ path: path.join(here, 'img', name + '.png') })
  console.log('ok', name)
}
await browser.close(); server.close()
