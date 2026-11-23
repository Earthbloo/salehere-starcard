// node present/text-overlap-audit/shot.mjs <out.png> <kind> "<label>|W|H|text|k" …   (text '-' = คำเดิม)
import fs from 'node:fs'
import path from 'node:path'
import http from 'node:http'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'
import { iconResolver } from '../../sync-server/web-icons.mjs'
const here = path.dirname(fileURLToPath(import.meta.url))
const repo = path.resolve(here, '../..')
const webDir = path.join(repo, 'sync-server/web'), fontDir = path.join(repo, 'StarCard/StarCard/Resources/Fonts'), specDir = path.join(repo, 'shared/WidgetSpecs')
const [out, kind, ...cs] = process.argv.slice(2)
const walk = (d) => fs.readdirSync(d, { withFileTypes: true }).flatMap((e) => e.isDirectory() ? walk(path.join(d, e.name)) : e.name.endsWith('.json') ? [path.join(d, e.name)] : [])
const json = walk(specDir).map((f) => JSON.parse(fs.readFileSync(f, 'utf8'))).find((j) => j.kind === kind)
const cases = cs.map((c) => { const [l, W, H, t, k] = c.split('|'); return [l, +W || json.design.w, +H || json.design.h, t === '-' || !t ? null : t, +k || 1] })
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
  if (rel === '/harness.html') { res.setHeader('content-type', MIME['.html']); return res.end(fs.readFileSync(path.join(here, 'harness.html'))) }
  const file = rel.startsWith('/fonts/') ? path.join(fontDir, rel.slice(7)) : path.join(webDir, rel)
  if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) { res.statusCode = 404; return res.end() }
  res.setHeader('content-type', MIME[path.extname(file)] ?? 'application/octet-stream'); fs.createReadStream(file).pipe(res)
})
await new Promise((ok) => server.listen(0, '127.0.0.1', ok))
const puppeteer = createRequire(path.join(repo, 'sync-server/package.json'))('puppeteer-core')
const browser = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: true, args: ['--force-device-scale-factor=2'] })
const tab = await browser.newPage()
await tab.goto(`http://127.0.0.1:${server.address().port}/harness.html`)
await tab.waitForFunction('window.ready === true', { timeout: 60000 })
await tab.evaluate(() => { window.showFrames = !!process_env_frames }).catch(() => {}); await tab.evaluate((f) => { window.showFrames = f }, !!process.env.FRAMES); await tab.evaluate((j, c) => window.showCases(j, c), json, cases)
await (await tab.$('#stage')).screenshot({ path: out })
await browser.close(); server.close()
