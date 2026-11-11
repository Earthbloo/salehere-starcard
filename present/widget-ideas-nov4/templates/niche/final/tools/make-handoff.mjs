#!/usr/bin/env node
// ชุดข้อมูลส่งทีม API (5 พ.ย. 2569 ฉบับย่อ) → present/starcard-template-handoff/
//   templates.json = โครง 20 ใบ (createStarCardTemplates) · previews/ = ภาพหน้าเลือก template ใบละ 1 ภาพ
// แนวทาง: หน้าเลือก template โชว์ภาพนี้ · ผู้ใช้กดเลือก → createStarCard(templateId) ได้ผัง/ธีม/ชิ้น แล้วแสดงข้อมูลและรูปของผู้ใช้เอง
// ใช้: node tools/make-handoff.mjs   (ต้องเปิด preview "widget-ideas" 8802 + "sync-server" 8787)
import fs from 'node:fs'
import path from 'node:path'
import crypto from 'node:crypto'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'

const here = path.dirname(fileURLToPath(import.meta.url))
const final = path.resolve(here, '..')
const repo = path.resolve(final, '../../../../..')
const OUT = path.join(repo, 'present/starcard-template-handoff')
const SPECS = path.join(repo, 'shared/WidgetSpecs')
const require = createRequire(path.join(repo, 'sync-server/package.json'))
const puppeteer = require('puppeteer-core')
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'

const manifest = JSON.parse(fs.readFileSync(path.join(final, 'manifest.json'), 'utf8'))
const docs = Object.fromEntries(manifest.templates.map((t) => [t.id, JSON.parse(fs.readFileSync(path.join(final, 'out', t.id + '.json'), 'utf8'))]))
const FORMAT = { portrait: 'story', portfolio: 'portfolio' }
const SEAL_AT = { story: { x: 276, y: 786, w: 246, h: 156 }, portfolio: { x: 18, y: 420, w: 366, h: 232 } }
const DPR = 2   // ภาพ = หน่วยออกแบบ × 2
const slug = (s) => s.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')
const list = [...manifest.templates].sort((a, b) => (a.orient === b.orient ? a.final - b.final : a.orient === 'portrait' ? -1 : 1))
const key = (t) => `${FORMAT[t.orient]}-${String(t.final).padStart(2, '0')}-${slug(t.name)}`
const problems = []

fs.rmSync(OUT, { recursive: true, force: true })
for (const d of ['previews', 'widget-specs', 'tools']) fs.mkdirSync(path.join(OUT, d), { recursive: true })

// ── 1. templates.json (createStarCardTemplates)
const templates = list.map((t) => {
  const doc = docs[t.id], format = FORMAT[t.orient], last = doc.snapshot.pages.length - 1, th = doc.snapshot.theme
  return { name: t.name, format, snapshot: { theme: { colors: th.colors, ink: th.ink, backdrop: th.backdrop }, pages: doc.snapshot.pages.map((pg, pi) => ({ items: [
    ...pg.items.map((it) => ({ kind: it.kind, x: it.x, y: it.y, w: it.w, h: it.h, surface: it.surface, border: !!it.border, ...(it.options && Object.keys(it.options).length ? { options: it.options } : {}) })),
    ...(pi === last ? [{ kind: 'proofSeal', ...SEAL_AT[format], surface: 'glass', border: false }] : []),
  ] })) } }
})
fs.writeFileSync(path.join(OUT, 'templates.json'), JSON.stringify(templates, null, 1))
const size = fs.statSync(path.join(OUT, 'templates.json')).size
if (size > 1024 * 1024) problems.push(`templates.json ${size} ไบต์ เกิน 1 MB`)
for (const f of ['story', 'portfolio']) { const n = templates.filter((x) => x.format === f).map((x) => x.name); if (new Set(n).size !== n.length) problems.push(`ชื่อซ้ำใน ${f}`) }
for (const x of templates) {
  if (x.snapshot.pages.at(-1).items.at(-1).kind !== 'proofSeal') problems.push(`${x.name}: ไม่มีตรา`)
  if (x.format === 'portfolio' && x.snapshot.pages.length !== 3) problems.push(`${x.name}: portfolio ต้อง 3 หน้า`)
}

// ── 2. ภาพหน้าเลือก template = แผ่นแบบเดียวกับแอป (StarCardSheetView): story 1 หน้า · portfolio 3 หน้า + ช่องว่าง 26 รอบ/ระหว่าง บนสีธีม
const browser = await puppeteer.launch({ executablePath: CHROME, headless: true, args: ['--hide-scrollbars', '--font-render-hinting=none'] })
const page = await browser.newPage()
await page.setViewport({ width: 3000, height: 1400, deviceScaleFactor: DPR })
page.on('pageerror', (e) => problems.push('หน้า Final error: ' + e.message))
await page.goto('http://localhost:8802/templates/niche/final/index.html?scale=1&sheet', { waitUntil: 'networkidle0', timeout: 300000 })
await page.waitForFunction('window.__done === true', { timeout: 300000 })
await page.addStyleTag({ content: '.page,.page .pg{border-radius:0 !important} #bar{display:none}' })
await page.evaluate(async () => { await document.fonts.ready; await Promise.all([...document.images].map((i) => (i.complete ? i.decode() : new Promise((ok) => { i.onload = i.onerror = ok })).catch(() => {}))) })
await new Promise((ok) => setTimeout(ok, 1500))
const report = await page.evaluate(() => window.__report)
const previews = {}
for (const t of list) {
  const r = report[t.id]
  if (!r || r.over.length || r.dupes.length || r.other) problems.push(`${t.id}: รูปตัวอย่างไม่ผ่าน ${JSON.stringify(r)}`)
  const el = await page.$(`.tpl[data-id="${t.id}"] .page`)
  const file = `previews/${key(t)}.jpg`
  await el.screenshot({ path: path.join(OUT, file), type: 'jpeg', quality: 90 })
  const box = await el.boundingBox()
  previews[t.id] = { file, width: Math.round(box.width * DPR), height: Math.round(box.height * DPR), bytes: fs.statSync(path.join(OUT, file)).size }
}
await browser.close()
for (const t of list) {
  const p = previews[t.id], want = t.orient === 'portrait' ? [540, 960] : [402 * 3 + 26 * 4, 670 + 26 * 2]
  if (p.width !== want[0] * DPR || p.height !== want[1] * DPR) problems.push(`${key(t)}: ภาพ ${p.width}×${p.height} ไม่ใช่ ${want[0] * DPR}×${want[1] * DPR}`)
}

// ── 3. widget ที่ใช้ + ค่าตรวจไฟล์ (เทียบเวอร์ชันกับ server)
const kinds = [...new Set(templates.flatMap((x) => x.snapshot.pages.flatMap((p) => p.items.map((i) => i.kind))))].sort()
// ผังแบ่งโฟลเดอร์ย่อยตามหมวดถาดของ API (`<NN-หมวด>/<kind>.json`) → กวาดทุกชั้น · คืน path เต็ม เรียงตามชื่อไฟล์ (= kind)
const specFiles = (d) => fs.readdirSync(d, { withFileTypes: true }).flatMap((e) => e.isDirectory() ? specFiles(path.join(d, e.name)) : e.name.endsWith('.json') ? [path.join(d, e.name)] : [])
const listSpecs = (d) => specFiles(d).sort((a, b) => path.basename(a) < path.basename(b) ? -1 : 1)
const specPath = Object.fromEntries(specFiles(SPECS).map((p) => [path.basename(p, '.json'), p]))
const widgets = kinds.map((k) => {
  const f = specPath[k] || path.join(SPECS, k + '.json')
  if (!fs.existsSync(f)) { problems.push('ไม่มี spec ' + k); return { kind: k } }
  fs.copyFileSync(f, path.join(OUT, 'widget-specs', k + '.json'))
  return { kind: k, sha256: crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex'), bytes: fs.statSync(f).size,
    usedBy: templates.filter((x) => x.snapshot.pages.some((p) => p.items.some((i) => i.kind === k))).length }
})

// ── 4. ไฟล์ประกอบ
const index = list.map((t, i) => ({ key: key(t), name: t.name, format: FORMAT[t.orient], order: t.final, preview: previews[t.id], theme: templates[i].snapshot.theme, mergedFrom: t.mergedFrom, note: t.why }))
fs.writeFileSync(path.join(OUT, 'templates-index.json'), JSON.stringify(index, null, 1))
fs.writeFileSync(path.join(OUT, 'preview-urls.json'), JSON.stringify(Object.fromEntries(index.map((r) => [r.preview.file, null])), null, 1))
fs.writeFileSync(path.join(OUT, 'widgets.json'), JSON.stringify(widgets, null, 1))
fs.copyFileSync(path.join(here, 'fill-preview-urls.mjs'), path.join(OUT, 'tools', 'fill-preview-urls.mjs'))
fs.copyFileSync(path.join(here, 'handoff-README.md'), path.join(OUT, 'README.md'))

// ── 5. ภาพรวมทุกใบ
{
  const b2 = await puppeteer.launch({ executablePath: CHROME, headless: true, args: ['--allow-file-access-from-files'] })
  const p2 = await b2.newPage()
  for (const [f, w, label, h] of [['story', 1500, 'แนวตั้ง (story) 10 ใบ', 480], ['portfolio', 2160, 'แนวนอน (portfolio 3 หน้า) 10 ใบ', 300]]) {
    const cards = index.filter((t) => t.format === f).map((t) => `<div style="display:inline-block;margin:0 14px 18px 0;vertical-align:top"><div style="font:600 15px sans-serif;color:#eee;margin:0 0 6px">${t.order} · ${t.name}</div><img src="file://${path.join(OUT, t.preview.file)}" style="height:${h}px;border-radius:${f === 'story' ? 18 : 14}px;display:block"></div>`).join('')
    const html = path.join(OUT, `.overview-${f}.html`)
    fs.writeFileSync(html, `<html><body style="margin:0;padding:20px;background:#15151a;width:${w - 40}px"><div style="font:700 24px sans-serif;color:#fff;margin:0 0 16px">${label}</div>${cards}</body></html>`)
    await p2.setViewport({ width: w, height: 800, deviceScaleFactor: 1 })
    await p2.goto('file://' + html, { waitUntil: 'networkidle0' })
    await p2.screenshot({ path: path.join(OUT, `overview-${f}.png`), fullPage: true })
    fs.rmSync(html)
  }
  await b2.close()
}

const mb = (n) => (n / 1e6).toFixed(1)
console.log(`template ${templates.length} ใบ (story ${templates.filter((x) => x.format === 'story').length} · portfolio ${templates.filter((x) => x.format === 'portfolio').length}) · templates.json ${(size / 1024).toFixed(0)} KB`)
console.log(`ภาพตัวอย่าง ${Object.keys(previews).length} ภาพ · รวม ${mb(Object.values(previews).reduce((a, p) => a + p.bytes, 0))} MB · widget ${widgets.length} ชนิด`)
console.log(problems.length ? 'ปัญหา:\n' + problems.join('\n') : 'ตรวจผ่านทุกข้อ')
if (problems.length) process.exitCode = 1
