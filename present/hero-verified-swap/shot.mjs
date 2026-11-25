// node present/hero-verified-swap/shot.mjs — เรนเดอร์ทุกแบบใน variants.mjs × (paper, glass) × การ์ด 2 สี → img/
import fs from 'node:fs'
import path from 'node:path'
import http from 'node:http'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'
import { iconResolver } from '../../sync-server/web-icons.mjs'
import { VARIANTS, apply } from './variants.mjs'
const here = path.dirname(fileURLToPath(import.meta.url))
const repo = path.resolve(here, '../..')
const webDir = path.join(repo, 'sync-server/web'), fontDir = path.join(repo, 'StarCard/StarCard/Resources/Fonts')
// ค่าเริ่ม = before/ (JSON ก่อนแก้ 25 พ.ย. ที่ยังมีแถว VERIFIED) · LIVE=1 = ไฟล์จริงใน shared/WidgetSpecs
const SRC = process.env.LIVE ? path.join(repo, 'shared/WidgetSpecs/01-โปรไฟล์') : path.join(here, 'before')
const spec = (k) => JSON.parse(fs.readFileSync(path.join(SRC, k + '.json'), 'utf8'))
const KINDS = { paper: spec('popHeroPaper'), glass: spec('popHeroGlass') }
const SZ = process.env.W ? { w: +process.env.W, h: +process.env.H } : {}
const CARDS = [{ id: 'grey', card: '#3B3B3D', tone: 'dark', ...SZ }, { id: 'lilac', card: '#B9A6F0', tone: 'light', ...SZ }]

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
  userDataDir: path.join(process.env.TMPDIR || '/tmp', 'hero-swap-chrome-' + process.pid), args: ['--force-device-scale-factor=2', '--no-first-run', '--no-default-browser-check'], timeout: 90000 })
const tab = await browser.newPage()
await tab.setViewport({ width: 900, height: 700, deviceScaleFactor: 2 })
tab.on('pageerror', (e) => console.error('pageerror', e.message))
tab.on('console', (m) => { if (m.type() === 'error') console.error('console', m.text()) })
await tab.goto(`http://127.0.0.1:${server.address().port}/render.html`)
await tab.waitForFunction('window.ready === true', { timeout: 60000 })
const OUT = process.env.OUT || path.join(here, 'img'); fs.mkdirSync(OUT, { recursive: true })
const only = process.argv.slice(2)
for (const v of VARIANTS) {
  if (only.length && !only.includes(v.id)) continue
  for (const [skin, json] of Object.entries(KINDS)) {
    const j = apply(json, v)
    if (!process.env.LIVE) fs.mkdirSync(path.join(here, 'json', v.id), { recursive: true })
    if (!process.env.LIVE) fs.writeFileSync(path.join(here, 'json', v.id, j.kind + '.json'), JSON.stringify(j, null, 1) + '\n')
    for (const c of CARDS) {
      await tab.evaluate((j, o) => window.render(j, o), j, c)
      const name = `${v.id}-${skin}-${c.id}.png`
      await (await tab.$('#cell')).screenshot({ path: path.join(OUT, name) })
      console.log('ok', name)
    }
  }
}
await browser.close(); server.close(); process.exit(0)
