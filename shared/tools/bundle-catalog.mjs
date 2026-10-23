// ฝังตัววาดเว็บลง shared/docs/widget-catalog.html → ส่งไฟล์เดียวให้ทีมอื่นแล้ว 🎨 สีพื้นหลังตามแอป + ลองวางการ์ด เล่นได้โดยไม่ต้องเปิด sync-server
//
//   node shared/tools/bundle-catalog.mjs            (build-widget-catalog.py เรียกให้เองตอนท้าย · รันซ้ำได้ — ลบก้อนเก่าก่อนฝังใหม่)
//
// ก้อน `window.SC_BUNDLE` = { order, modules, specs, fonts, icons, fixtures, builtAt }
//   modules  = sync-server/web/js/*.js ที่ตัววาดใช้ (เรียงตามลำดับพึ่งพา · หน้าเว็บแปลงเป็น blob:/data: URL ตอนโหลด)
//   specs    = shared/WidgetSpecs/*.json (ชุดเดียวกับ GET /api/specs)
//   fonts    = Noto Sans Thai 7 น้ำหนัก + Mitr เป็น data:
//   icons    = ทุกชื่อไอคอนที่ผัง/fixture/โค้ดอ้างถึง (ph:… sh:… ชื่อ asset) หาด้วย iconResolver ชุดเดียวกับ server → data:
//   fixtures = กรณี `design` ของ present/spec-fixtures/fixtures/<kind>.json (ค่าที่ iOS ใช้วาดภาพนิ่ง)
// รูปตัวอย่าง (โปรไฟล์/ผลงาน) ยังเป็น URL บน img.salehere.co.th — ต้องต่อเน็ต แต่ไม่ต้องมี server ของเรา
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { iconResolver } from '../../sync-server/web-icons.mjs'

const here = path.dirname(fileURLToPath(import.meta.url))
const repo = path.resolve(here, '..', '..')
const OUT = process.argv[2] || path.join(repo, 'shared', 'docs', 'widget-catalog.html')
const jsDir = path.join(repo, 'sync-server', 'web', 'js')
const specDir = path.join(repo, 'shared', 'WidgetSpecs')
const fontDir = path.join(repo, 'StarCard', 'StarCard', 'Resources', 'Fonts')
const fixtureDir = path.join(repo, 'present', 'spec-fixtures', 'fixtures')

// ---- โมดูล: เริ่มจากที่แคตตาล็อก import แล้วไล่ตาม `from './x.js'` → เรียง deps ก่อน
const ENTRIES = ['backdrop-tray.js', 'spec-model.js', 'measure.js', 'data.js', 'chrome.js', 'backdrop.js', 'replay.js', 'theme.js', 'page.js']
const modules = {}, order = []
const deps = (code) => [...code.matchAll(/from '\.\/([\w-]+\.js)'/g)].map((m) => m[1])
function visit(name, stack = []) {
  if (order.includes(name)) return
  if (stack.includes(name)) throw new Error('import วน: ' + [...stack, name].join(' → '))
  const code = fs.readFileSync(path.join(jsDir, name), 'utf8')
  modules[name] = code
  for (const d of deps(code)) visit(d, [...stack, name])
  order.push(name)
}
ENTRIES.forEach((e) => visit(e))

// ---- ผัง + fixture (กรณี design)
const specs = {}, fixtures = {}
for (const f of fs.readdirSync(specDir).filter((f) => f.endsWith('.json')).sort()) {
  const kind = f.slice(0, -5)
  specs[kind] = JSON.parse(fs.readFileSync(path.join(specDir, f), 'utf8'))
  const fx = path.join(fixtureDir, f)
  if (fs.existsSync(fx)) {
    const c = JSON.parse(fs.readFileSync(fx, 'utf8')).cases?.find((c) => c.probe === 'design')
    if (c) fixtures[kind] = c
  }
}

// ---- ฟอนต์
const mimeOf = (f) => ({ '.ttf': 'font/ttf', '.otf': 'font/otf', '.svg': 'image/svg+xml', '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.webp': 'image/webp' })[path.extname(f).toLowerCase()] || 'application/octet-stream'
const dataURL = (file) => `data:${mimeOf(file)};base64,${fs.readFileSync(file).toString('base64')}`
const fonts = {}
for (const f of fs.readdirSync(fontDir).filter((f) => /^(NotoSansThai-\w+|Mitr-Regular)\.ttf$/.test(f))) fonts[f] = dataURL(path.join(fontDir, f))

// ---- ไอคอน: ทุกสตริงในผัง/fixture + ชื่อในโค้ด + แพลตฟอร์มที่ data.js ต่อเป็น 'sh:' + platform
const names = new Set()
const walk = (v) => { if (typeof v === 'string') { if (v.length < 80 && !/\s/.test(v)) names.add(v) } else if (Array.isArray(v)) v.forEach(walk); else if (v && typeof v === 'object') Object.values(v).forEach(walk) }
walk(specs); walk(fixtures)
for (const code of Object.values(modules)) for (const m of code.matchAll(/'((?:ph|sh):[\w-]+)'/g)) names.add(m[1])
for (const p of ['instagram', 'tiktok', 'youtube', 'facebook', 'x', 'lemon8', 'line']) names.add('sh:' + p)   // แพลตฟอร์มของ `socials`/`rates`/`works` (ตรา Sale Here อื่น ๆ จะติดมาเองเมื่อผัง/โค้ดอ้างถึง)
const resolve = iconResolver(repo)
const icons = {}
let probed = 0
for (const n of names) {
  if (n.startsWith('http') || n.startsWith('url:') || n.startsWith('$') || n.startsWith('#')) continue
  let hit = null
  try { hit = resolve(n) } catch { hit = null }
  probed++
  if (!hit) continue
  icons[n] = hit.svg ? `data:image/svg+xml;base64,${Buffer.from(hit.svg, 'utf8').toString('base64')}` : dataURL(hit.file)
}

// ---- ฝัง
const bundle = { builtAt: new Date().toISOString().slice(0, 16).replace('T', ' '), order, modules, specs, fonts, icons, fixtures }
const json = JSON.stringify(bundle).replace(/<\//g, '<\\/').replace(new RegExp('[\\u2028\\u2029]', 'g'), (c) => '\\u' + c.charCodeAt(0).toString(16))   // ตัวคั่นบรรทัดของ JS ต้อง escape ใน <script>
const TAG = '<script id="sc-bundle">'
let html = fs.readFileSync(OUT, 'utf8')
html = html.replace(/<script id="sc-bundle">[\s\S]*?<\/script>\n/, '')
const at = html.indexOf('<script type="module">')
if (at < 0) throw new Error('ไม่พบ <script type="module"> ใน ' + OUT)
html = html.slice(0, at) + `${TAG}window.SC_BUNDLE=${json}</script>\n` + html.slice(at)
fs.writeFileSync(OUT, html)
const kb = (s) => (s / 1024).toFixed(0) + ' KB'
console.log(`bundled → ${path.relative(repo, OUT)} ${(html.length / 1e6).toFixed(1)} MB · modules ${order.length} (${kb(Object.values(modules).join('').length)}) · specs ${Object.keys(specs).length} · fixtures ${Object.keys(fixtures).length} (${kb(JSON.stringify(fixtures).length)}) · fonts ${Object.keys(fonts).length} (${kb(JSON.stringify(fonts).length)}) · icons ${Object.keys(icons).length}/${probed} (${kb(JSON.stringify(icons).length)})`)
