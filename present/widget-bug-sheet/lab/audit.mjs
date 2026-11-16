#!/usr/bin/env node
// ไล่ทุกชนิด: render ด้วยตัววาดเว็บ แล้วรายงาน error · ข้อความถูกตัด "…" · ข้อความล้นกรอบ
//   node audit.mjs <scale> [kindFilter]   → audit-<scale>.json  (ต้องเปิด preview 8787 + 8794)
import fs from 'node:fs'; import path from 'node:path'; import { fileURLToPath } from 'node:url'; import { createRequire } from 'node:module'
const here = path.dirname(fileURLToPath(import.meta.url))
const require = createRequire(path.resolve(here, '../../../sync-server/package.json'))
const puppeteer = require('puppeteer-core')
const scale = Number(process.argv[2] || 1), only = process.argv[3]
const specDir = path.resolve(here, '../../../shared/WidgetSpecs')
const kinds = []
for (const d of fs.readdirSync(specDir)) { const p = path.join(specDir, d); if (!fs.statSync(p).isDirectory()) continue
  for (const f of fs.readdirSync(p)) if (f.endsWith('.json')) { const j = JSON.parse(fs.readFileSync(path.join(p, f), 'utf8')); kinds.push({ kind: j.kind, dir: d, design: j.design, w: j.widget }) } }
const socials = [['instagram', 'https://instagram.com/tnn_health', 37778], ['tiktok', 'https://tiktok.com/@taotaoaima', 1703983], ['facebook', 'https://facebook.com/share', 673000], ['youtube', 'https://youtube.com/@TrueVisionsOfficial', 5710000], ['lemon8', 'https://lemon8-app.com/x', 218000]].map(([type, link, followers]) => ({ type, link, followers, enabled: true, source: 'connected' }))
const owner = { values: { name: 'หกห้า มาแล้ว', about: 'หกห้า มาแล้ว มาร่วมความสนุก รีวิวของกินของใช้ สายสุขภาพ ออกกำลังกายทุกวัน', handle: 'sit167', lineId: '@sit167', phone: '0811111165', website: 'https://salehere.co.th' },
  list: { categories: ['ความงามและสุขภาพ', 'แฟชั่นและช้อปปิ้ง', 'อาหารและเครื่องดื่ม', 'การเงินการของและขนส่ง', 'ท่องเที่ยว'] },
  intake: { socials, availability: { provinces: ['กรุงเทพมหานคร', 'นครศรีธรรมราช', 'นครสวรรค์', 'ปัตตานี', 'ยโสธร'], days: [6, 0], slots: ['evening'] } } }
const browser = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: 'new' })
const page = await browser.newPage(); await page.setViewport({ width: 900, height: 1000, deviceScaleFactor: 2 })
const out = []
fs.mkdirSync(path.join(here, 'audit'), { recursive: true })
for (const k of kinds) {
  if (only && !k.kind.includes(only)) continue
  const f = Math.min(1, 342 / k.design.w) * scale
  const c = { name: k.kind, kind: k.kind, w: Math.round(k.design.w * f), h: Math.round(k.design.h * f), t: 'navy', src: 'work', owner, item: { border: k.w.border ?? !k.w.ownSurface } }
  await page.goto('http://localhost:8794/widget-bug-sheet/lab/lab.html?c=' + encodeURIComponent(JSON.stringify(c)), { waitUntil: 'networkidle0' })
  await page.waitForFunction('window.__ready === true', { timeout: 20000 })
  const r = await page.evaluate(() => {
    const root = document.querySelector('[data-kind]'); if (!root) return { err: window.__err || 'no root' }
    const R = root.getBoundingClientRect(); const cut = [], over = []
    const tw = document.createTreeWalker(root, NodeFilter.SHOW_TEXT)
    for (let n = tw.nextNode(); n; n = tw.nextNode()) { const t = n.textContent.trim(); if (!t) continue
      const rg = document.createRange(); rg.selectNodeContents(n); const b = rg.getBoundingClientRect(); if (!b.width) continue
      if (t.endsWith('…')) cut.push(t)
      const dx = Math.max(R.left - b.left, b.right - R.right), dy = Math.max(R.top - b.top, b.bottom - R.bottom)
      if (dx > 2 || dy > 2) over.push([t.slice(0, 24), Math.round(Math.max(dx, 0)), Math.round(Math.max(dy, 0))]) }
    return { err: window.__err || '', cut, over }
  })
  if (r.err || r.cut?.length || r.over?.length) await (await page.$('#shot')).screenshot({ path: path.join(here, 'audit', `${k.kind}-${scale}.png`) })
  out.push({ kind: k.kind, dir: k.dir, title: k.w.title, w: c.w, h: c.h, ...r })
}
await browser.close()
fs.writeFileSync(path.join(here, `audit-${scale}.json`), JSON.stringify(out, null, 1))
const bad = out.filter(o => o.err || o.cut?.length || o.over?.length)
console.log(`scale ${scale}: ${out.length} kinds · flagged ${bad.length}`)
for (const o of bad) console.log(' ', o.kind, o.err ? 'ERR ' + o.err.slice(0, 80) : '', o.cut?.length ? 'CUT ' + JSON.stringify(o.cut.slice(0, 3)) : '', o.over?.length ? 'OVER ' + JSON.stringify(o.over.slice(0, 3)) : '')
