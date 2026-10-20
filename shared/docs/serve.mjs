#!/usr/bin/env node
// เสิร์ฟ shared/docs แบบไม่ให้เบราว์เซอร์แคช — widget-catalog.html ถูก regen บ่อย ถ้าใช้ python http.server
// เบราว์เซอร์จะจำไฟล์เก่าไว้ (ไม่มี Cache-Control) แล้วแท็บที่เปิดค้างเห็นแคตตาล็อกเวอร์ชันก่อน
//   node shared/docs/serve.mjs            (พอร์ต 8801 หรือ PORT)  — หรือ preview "shared-docs" ใน .claude/launch.json
import http from 'node:http'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.dirname(fileURLToPath(import.meta.url))
const port = Number(process.env.PORT || 8801)
const MIME = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.mjs': 'text/javascript', '.css': 'text/css', '.json': 'application/json',
  '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.webp': 'image/webp', '.svg': 'image/svg+xml', '.md': 'text/markdown; charset=utf-8' }

http.createServer((req, res) => {
  let p = decodeURIComponent(new URL(req.url, 'http://x').pathname)
  if (p.endsWith('/')) p += 'index.html'
  const file = path.resolve(root, '.' + p)
  if (!file.startsWith(root) || !fs.existsSync(file) || !fs.statSync(file).isFile()) { res.writeHead(404); return res.end('not found') }
  res.writeHead(200, { 'Content-Type': MIME[path.extname(file)] || 'application/octet-stream', 'Cache-Control': 'no-store', 'Access-Control-Allow-Origin': '*' })
  fs.createReadStream(file).pipe(res)
}).listen(port, '0.0.0.0', () => console.log(`shared/docs → http://localhost:${port}/widget-catalog.html (no-store)`))
