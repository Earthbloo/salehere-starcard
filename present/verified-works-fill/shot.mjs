// node present/verified-works-fill/shot.mjs [kind...] — แผ่นเทียบ 1–4 ชิ้น × กรอบ 5 รูปทรง → img/<kind>.png
// SRC=dir อ่าน spec จากโฟลเดอร์อื่น (ค่าเริ่ม shared/WidgetSpecs/12-ผลงานยืนยัน) · OUT=dir
import fs from 'node:fs'
import path from 'node:path'
import http from 'node:http'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'
import { iconResolver } from '../../sync-server/web-icons.mjs'
const here = path.dirname(fileURLToPath(import.meta.url))
const repo = path.resolve(here, '../..')
const webDir = path.join(repo, 'sync-server/web'), fontDir = path.join(repo, 'StarCard/StarCard/Resources/Fonts')
const SRC = process.env.SRC || path.join(repo, 'shared/WidgetSpecs/12-ผลงานยืนยัน')
const KINDS = process.argv.slice(2).length ? process.argv.slice(2) : ['proofWork', 'proofTicket', 'wallPolaroid', 'reelBrand']
const FRAMES = [[366, 254], [269, 361], [248, 229], [504, 194], [366, 304]]
const COUNTS = [1, 2, 3, 4]
const MIME = { '.js': 'text/javascript', '.html': 'text/html; charset=utf-8', '.ttf': 'font/ttf', '.otf': 'font/otf', '.svg': 'image/svg+xml', '.png': 'image/png', '.jpg': 'image/jpeg' }
const resolveIcon = iconResolver(repo)
const server = http.createServer((req, res) => {
  const u = new URL(req.url, 'http://x'), rel = decodeURIComponent(u.pathname)
  if (rel.startsWith('/icon/')) {
    const hit = resolveIcon(rel.slice(6))
    if (!hit) { res.statusCode = 404; return res.end() }
    if (hit.svg) { res.setHeader('content-type', 'image/svg+xml'); return res.end(hit.svg) }
    res.setHeader('content-type', path.extname(hit.file) === '.svg' ? 'image/svg+xml' : 'image/png'); return res.end(fs.readFileSync(hit.file))
  }
  const file = rel === '/render.html' ? path.join(here, 'render.html')
    : rel.startsWith('/fonts/') ? path.join(fontDir, rel.slice(7)) : path.join(webDir, rel)
  if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) { res.statusCode = 404; return res.end() }
  res.setHeader('content-type', MIME[path.extname(file)] ?? 'application/octet-stream'); fs.createReadStream(file).pipe(res)
})
await new Promise((ok) => server.listen(0, '127.0.0.1', ok))
const puppeteer = createRequire(path.join(repo, 'sync-server/package.json'))('puppeteer-core')
const browser = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: true,
  userDataDir: path.join(process.env.TMPDIR || '/tmp', 'vwf-chrome-' + process.pid), args: ['--force-device-scale-factor=1.5', '--no-first-run', '--no-default-browser-check'], timeout: 90000 })
const tab = await browser.newPage()
await tab.setViewport({ width: 2000, height: 1200, deviceScaleFactor: 1.5 })
tab.on('pageerror', (e) => console.error('pageerror', e.message))
tab.on('console', (m) => { if (m.type() === 'error') console.error('console', m.text()) })
await tab.goto(`http://127.0.0.1:${server.address().port}/render.html`)
await tab.waitForFunction('window.ready === true', { timeout: 60000 })
const OUT = process.env.OUT || path.join(here, 'img'); fs.mkdirSync(OUT, { recursive: true })
for (const k of KINDS) {
  const json = JSON.parse(fs.readFileSync(path.join(SRC, k + '.json'), 'utf8'))
  await tab.evaluate((j, f, c) => window.sheet(j, f, c), json, FRAMES, COUNTS)
  await new Promise((r) => setTimeout(r, 800)); await (await tab.$('#stage')).screenshot({ path: path.join(OUT, k + '.png') })
  console.log('ok', k)
}
await browser.close(); server.close(); process.exit(0)
