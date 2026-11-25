// node present/qa-reject-nov23/shot.mjs — ภาพก่อน (before/ = JSON ก่อนแก้ (25 พ.ย.)) / หลัง (shared/WidgetSpecs) ของทุกเคสใน cases.json → img/
import fs from 'node:fs'
import path from 'node:path'
import http from 'node:http'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'
import { iconResolver } from '../../sync-server/web-icons.mjs'
const here = path.dirname(fileURLToPath(import.meta.url))
const repo = path.resolve(here, '../..')
const webDir = path.join(repo, 'sync-server/web'), fontDir = path.join(repo, 'StarCard/StarCard/Resources/Fonts')
const load = (dir) => {
  const out = {}
  const walk = (d) => { for (const f of fs.readdirSync(d)) { const p = path.join(d, f); if (fs.statSync(p).isDirectory()) walk(p); else if (f.endsWith('.json')) { const j = JSON.parse(fs.readFileSync(p, 'utf8')); if (j.kind) out[j.kind] = j } } }
  walk(dir); return out
}
const before = load(path.join(here, 'before')), after = load(process.env.AFTER ? path.resolve(process.env.AFTER) : path.join(repo, 'shared/WidgetSpecs'))
const cases = JSON.parse(fs.readFileSync(path.join(here, 'cases.json'), 'utf8'))
const only = process.argv.slice(2)

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
  const file = rel.startsWith('/qa/') ? path.join(here, rel.slice(4)) : rel === '/render.html' ? path.join(here, 'render.html')
    : rel.startsWith('/fonts/') ? path.join(fontDir, rel.slice(7)) : path.join(webDir, rel)
  if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) { res.statusCode = 404; return res.end() }
  res.setHeader('content-type', MIME[path.extname(file)] ?? 'application/octet-stream'); fs.createReadStream(file).pipe(res)
})
await new Promise((ok) => server.listen(0, '127.0.0.1', ok))
const puppeteer = createRequire(path.join(repo, 'sync-server/package.json'))('puppeteer-core')
const browser = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: true, userDataDir: process.env.CHROME_PROF, args: ['--force-device-scale-factor=2', '--no-first-run', '--no-default-browser-check'], timeout: 90000 })
const tab = await browser.newPage()
await tab.setViewport({ width: 1400, height: 1000, deviceScaleFactor: 2 })
tab.on('pageerror', (e) => console.error('pageerror', e.message))
tab.on('console', (m) => { if (m.type() === 'error') console.error('console', m.text()) })
await tab.goto(`http://127.0.0.1:${server.address().port}/render.html`)
await tab.waitForFunction('window.ready === true', { timeout: 60000 })
fs.mkdirSync(path.join(here, 'img'), { recursive: true })
for (const c of cases) {
  if (only.length && !only.includes(c.id)) continue
  for (const sh of c.shots) {
    for (const [tag, set] of [['before', before], ['after', after]]) {
      if (sh.only && sh.only !== tag) continue
      await tab.evaluate((j, o) => window.render(j, o), set[c.kind], { card: c.card, ...sh.opts })
      const name = `${c.id}-${sh.key}-${tag}.png`
      await (await tab.$('#cell')).screenshot({ path: path.join(here, 'img', name) })
      console.log('ok', name)
    }
  }
}
await browser.close(); server.close()
