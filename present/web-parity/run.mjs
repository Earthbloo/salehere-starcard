#!/usr/bin/env node
// พิสูจน์ "ผัง JSON ชุดเดียว → iOS กับ **เว็บ** วาดออกมาเหมือนกัน" (คู่กับ present/spec-parity ที่เทียบ iOS↔Android)
//
//   1. iOS: ./present/spec-fixtures/sync.sh <udid>      → present/spec-fixtures/{fixtures,cells}
//   2. เปิด sync-server (preview "sync-server" · พอร์ต 8787) — เว็บวาดจาก /card/dev/gallery.html ด้วย fixture ชุดเดียวกับ iOS
//   3. node present/web-parity/run.mjs [kind…] [--server http://localhost:8787] [--chrome <path>] [--no-compare]
//
// เว็บถูกถ่ายด้วย Chrome headless (puppeteer-core ของ sync-server) ที่ deviceScaleFactor 2 = สเกลของตัวส่งออก iOS
// ทีละใบ ขนาด (w+24)×(h+24) px เท่ารูป `cell-<kind>-design.png` ของ iOS เป๊ะ → present/web-parity/web/cell-<kind>-design.png
// แล้วส่งให้ present/spec-parity/compare.py (ตัวเดียวกับ iOS↔Android) → present/web-parity/out/report.html
// (ตัวเลข/ตัววัดของเว็บพิสูจน์แยกด้วย `cd sync-server/web && npm test` — ที่นี่เทียบเฉพาะภาพ จึงใช้ fixture ของ iOS ทั้งสองข้าง)

import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'
import { spawnSync } from 'node:child_process'

const here = path.dirname(fileURLToPath(import.meta.url))
const repo = path.resolve(here, '../..')
const iosDir = path.join(repo, 'present/spec-fixtures')
const webDir = path.join(here, 'web')
const iosShaped = path.join(here, 'ios')     // โฟลเดอร์หน้าตาเหมือน Documents/Specs ของซิม (compare.py ต้องการ cells ที่ราก + fixtures/)
const outDir = path.join(here, 'out')

const argv = process.argv.slice(2)
const opt = (name, dflt) => { const i = argv.indexOf(name); return i >= 0 ? argv[i + 1] : dflt }
const server = opt('--server', 'http://localhost:8787')
const chromePath = opt('--chrome', process.env.CHROME ?? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome')
const sim = opt('--sim', 'E68D4085-0BD3-4DBB-A231-51EFE7795BB0')   // ซิม iOS ที่ export มา — รูปครีเอเตอร์/ผลงานของมันถูกส่งให้เว็บใช้ชุดเดียวกัน
const themeArg = opt('--theme', null)   // JSON choice ของถาด เช่น '{"primary":"#282B4A","secondary":"#EEEBDA","tone":"dark"}' (ไม่ใส่ = ธีมตั้งต้นของตัวส่งออก)
const only = argv.filter((a, i) => !a.startsWith('--') && !['--server', '--chrome', '--sim', '--theme'].includes(argv[i - 1]))

const require = createRequire(path.join(repo, 'sync-server/web/test/measure-parity.mjs'))
let puppeteer
try { puppeteer = require('puppeteer-core') } catch { console.error('ต้องติดตั้งก่อน: cd sync-server && npm install'); process.exit(2) }
if (!fs.existsSync(chromePath)) { console.error(`ไม่พบ Chrome ที่ ${chromePath} — ใส่ --chrome <path> หรือ env CHROME`); process.exit(2) }
try { await fetch(`${server}/api/specs`) } catch { console.error(`sync-server ไม่ตอบที่ ${server} — เปิด preview "sync-server" ก่อน`); process.exit(2) }

// เตรียมโฟลเดอร์ — เว็บ: fixtures ของ iOS (ภาพเท่านั้นที่ต่าง) + รูปที่ถ่าย · iOS: cells ของ sync.sh ยกมาที่ราก
fs.rmSync(webDir, { recursive: true, force: true }); fs.mkdirSync(path.join(webDir, 'fixtures'), { recursive: true })
fs.rmSync(iosShaped, { recursive: true, force: true }); fs.mkdirSync(path.join(iosShaped, 'fixtures'), { recursive: true })
for (const f of fs.readdirSync(path.join(iosDir, 'fixtures'))) {
  fs.copyFileSync(path.join(iosDir, 'fixtures', f), path.join(webDir, 'fixtures', f))
  fs.copyFileSync(path.join(iosDir, 'fixtures', f), path.join(iosShaped, 'fixtures', f))
}
for (const f of fs.readdirSync(path.join(iosDir, 'cells'))) if (f.endsWith('-design.png')) fs.copyFileSync(path.join(iosDir, 'cells', f), path.join(iosShaped, f))

// รูปชุดเดียวกับ iOS: ก๊อปรูปครีเอเตอร์ 1–3 + ผลงานจาก Documents/starcard-portfolio ของซิมเข้าคลังรูปของ sync-server (id = md5)
// แล้วส่งให้ gallery ทาง ?mock= (= photoFor() สาขา mock: ช่อง 1–3 = creators[n-1] · ช่องอื่น = works[slot % n] — กติกาเดียวกับ PhotoStore.library ของ iOS)
import { createHash } from 'node:crypto'
import { execFileSync } from 'node:child_process'
let mockParam = ''
try {
  const container = execFileSync('xcrun', ['simctl', 'get_app_container', sim, 'com.salehere.alpha.app.starcard', 'data'], { encoding: 'utf8' }).trim()
  const folio = path.join(container, 'Documents/starcard-portfolio')
  const manifest = JSON.parse(fs.readFileSync(path.join(folio, 'manifest.json'), 'utf8'))
  const imageDir = path.join(repo, 'sync-server/data/images')
  fs.mkdirSync(imageDir, { recursive: true })
  const put = (file) => {
    if (!fs.existsSync(file)) return null
    const buf = fs.readFileSync(file); const id = createHash('md5').update(buf).digest('hex')
    fs.writeFileSync(path.join(imageDir, id), buf); fs.writeFileSync(path.join(imageDir, id + '.type'), 'image/jpeg')
    return id
  }
  const creators = [0, 1, 2].map((i) => put(path.join(folio, `creator-${i}.jpg`))).filter(Boolean)
  const works = (manifest.works || []).map((id) => put(path.join(folio, `work-${id}.jpg`))).filter(Boolean)
  mockParam = '&mock=' + Buffer.from(JSON.stringify({ creators, works })).toString('base64')
  console.log(`รูปจากซิม iOS: creators ${creators.length} · works ${works.length}`)
} catch (e) { console.error('ไม่ได้รูปจากซิม iOS — เว็บจะใช้รูป sample ของตัวเอง:', e.message) }
const themeParamStr = themeArg ? '&theme=' + Buffer.from(themeArg).toString('base64') : ''

const browser = await puppeteer.launch({ executablePath: chromePath, headless: true, args: ['--hide-scrollbars', '--force-device-scale-factor=2', '--font-render-hinting=none'] })
const page = await browser.newPage()
await page.setViewport({ width: 1400, height: 1200, deviceScaleFactor: 2 })
page.on('pageerror', (e) => console.error('page error:', e.message))
const failed = []
page.on('requestfailed', (r) => failed.push(r.url()))
page.on('response', (r) => { if (r.status() >= 400) failed.push(`${r.status()} ${r.url()}`) })
const url = `${server}/card/dev/gallery.html?${only.length === 1 ? `kind=${only[0]}` : ''}${mockParam}${themeParamStr}`
await page.goto(url, { waitUntil: 'networkidle0', timeout: 120000 })
await page.addStyleTag({ content: '.tag{display:none!important}' })
await page.evaluate(async () => {
  await document.fonts.ready
  await Promise.all([...document.images].map((im) => im.complete ? null : new Promise((ok) => { im.onload = im.onerror = ok })))
})
await new Promise((ok) => setTimeout(ok, 1500))

const kinds = await page.evaluate(() => [...document.querySelectorAll('.cell')].map((c) => c.querySelector('.head b').textContent))
let shot = 0
for (const kind of kinds) {
  if (only.length && !only.includes(kind)) continue
  // ย้ายกล่องเว็บของใบนี้ไปมุม (0,0) แบบ fixed ชั่วคราว → clip เป็นจำนวนเต็มเป๊ะ ไม่มีเศษพิกเซลจาก layout ของกริด
  const box = await page.evaluate((k) => {
    const cell = [...document.querySelectorAll('.cell')].find((c) => c.querySelector('.head b').textContent === k)
    const web = cell.querySelector('.pair > div')
    web.dataset.prev = web.style.cssText
    web.style.cssText += ';position:fixed;left:0;top:0;z-index:9999;margin:0'
    document.documentElement.scrollTop = 0
    const r = web.getBoundingClientRect()
    return { w: Math.round(r.width), h: Math.round(r.height) }
  }, kind)
  await page.screenshot({ path: path.join(webDir, `cell-${kind}-design.png`), clip: { x: 0, y: 0, width: box.w, height: box.h }, omitBackground: false })
  await page.evaluate((k) => {
    const cell = [...document.querySelectorAll('.cell')].find((c) => c.querySelector('.head b').textContent === k)
    const web = cell.querySelector('.pair > div'); web.style.cssText = web.dataset.prev
  }, kind)
  shot++
}
await browser.close()
if (failed.length) console.error(`คำขอที่ล้ม/404 ${failed.length}:`, [...new Set(failed)].slice(0, 20).join('\n  '))
console.log(`ถ่ายเว็บ ${shot} ใบ → ${webDir}`)

if (!argv.includes('--no-compare')) {
  const r = spawnSync('python3', ['-I', path.join(repo, 'present/spec-parity/compare.py'), iosShaped, webDir, outDir, '--probes', 'design', '--label', 'web'], { stdio: 'inherit' })
  if (r.status !== 0) process.exit(r.status ?? 1)
  console.log(`→ ${path.join(outDir, 'report.html')}`)
}
