// node measure.mjs kind W H n id,id — พิมพ์กล่องของโหนด (หน่วยผัง) จาก web solver
import fs from 'node:fs'; import path from 'node:path'; import http from 'node:http'
import { fileURLToPath } from 'node:url'; import { createRequire } from 'node:module'
const here = path.dirname(fileURLToPath(import.meta.url)), repo = path.resolve(here, '../..')
const webDir = path.join(repo, 'sync-server/web'), fontDir = path.join(repo, 'StarCard/StarCard/Resources/Fonts')
const SRC = process.env.SRC || path.join(repo, 'shared/WidgetSpecs/12-ผลงานยืนยัน')
const server = http.createServer((req, res) => {
  const rel = decodeURIComponent(new URL(req.url, 'http://x').pathname)
  const file = rel === '/render.html' ? path.join(here, 'render.html') : rel.startsWith('/fonts/') ? path.join(fontDir, rel.slice(7)) : path.join(webDir, rel)
  if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) { res.statusCode = 404; return res.end() }
  res.setHeader('content-type', file.endsWith('.js') ? 'text/javascript' : file.endsWith('.html') ? 'text/html; charset=utf-8' : 'application/octet-stream'); fs.createReadStream(file).pipe(res)
})
await new Promise((ok) => server.listen(0, '127.0.0.1', ok))
const puppeteer = createRequire(path.join(repo, 'sync-server/package.json'))('puppeteer-core')
const browser = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: true, userDataDir: path.join(process.env.TMPDIR || '/tmp', 'vwf-m-' + process.pid), args: ['--no-first-run'] })
const tab = await browser.newPage()
await tab.goto(`http://127.0.0.1:${server.address().port}/render.html`)
await tab.waitForFunction('window.ready === true', { timeout: 60000 })
const [kind, W, H, n, ids, surface] = process.argv.slice(2)
const json = JSON.parse(fs.readFileSync(path.join(SRC, kind + '.json'), 'utf8'))
const r = await tab.evaluate((j, W, H, n, ids, s) => window.measure(j, W, H, n, ids, s), json, +W, +H, +n, ids.split(','), surface)
for (const b of r) console.log(b.id.padEnd(14), b.path.padEnd(30), b.x, b.y, b.width, b.height)
await browser.close(); server.close(); process.exit(0)
