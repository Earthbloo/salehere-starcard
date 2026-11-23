// node present/text-overlap-audit/evalh.mjs '<js expression using measurer>' — evaluate in the harness page
import fs from 'node:fs'
import path from 'node:path'
import http from 'node:http'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'
const here = path.dirname(fileURLToPath(import.meta.url))
const repo = path.resolve(here, '../..')
const webDir = path.join(repo, 'sync-server/web'), fontDir = path.join(repo, 'StarCard/StarCard/Resources/Fonts')
const server = http.createServer((req, res) => {
  const rel = decodeURIComponent(new URL(req.url, 'http://x').pathname)
  if (rel === '/harness.html') { res.setHeader('content-type', 'text/html; charset=utf-8'); return res.end(fs.readFileSync(path.join(here, 'harness.html'))) }
  const file = rel.startsWith('/fonts/') ? path.join(fontDir, rel.slice(7)) : path.join(webDir, rel)
  if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) { res.statusCode = 404; return res.end() }
  res.setHeader('content-type', file.endsWith('.js') ? 'text/javascript' : 'application/octet-stream'); fs.createReadStream(file).pipe(res)
})
await new Promise((ok) => server.listen(0, '127.0.0.1', ok))
const puppeteer = createRequire(path.join(repo, 'sync-server/package.json'))('puppeteer-core')
const browser = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: true })
const tab = await browser.newPage()
await tab.goto(`http://127.0.0.1:${server.address().port}/harness.html`)
await tab.waitForFunction('window.ready === true', { timeout: 60000 })
console.log(JSON.stringify(await tab.evaluate(process.argv[2]), null, 1))
await browser.close(); server.close()
