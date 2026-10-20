// node sync-server/web/test/measure-parity.mjs [kind…] [--out <dir>] [--chrome <path>]
//
// พิสูจน์ **ตัววัดข้อความของเว็บ** (`WebMeasurer` ใน web/js/measure.js) เทียบกับ iOS (`IOSSpecMeasurer` · CoreText):
// เปิด Chrome แบบ headless (puppeteer-core — ใช้ Google Chrome ที่ติดตั้งอยู่ ไม่โหลด Chromium) โหลดฟอนต์ของแอป
// ด้วย `loadFonts()` ตัวเดียวกับหน้าเว็บ แล้วถาม **คำถามเดียวกับที่ iOS ถาม** ทุกข้อจาก fixture
// (`measures[]`: ข้อความ + ฟอนต์ + ความกว้าง → w / lines · `lineHeights[]`: ฟอนต์ → v)
//
// รายงานต่อชนิด: w ต่างไม่เกิน 0.5pt · เท่าทุกบิต (≤ 0.01) · บรรทัดเท่ากัน · lineHeight เท่ากัน
// + ตาราง 25 ค่าที่ต่างมากสุด (รูปแบบเดียวกับ `worstMeasures` ของ present/spec-parity/compare.py)
// → ตารางใน terminal + `<out>/summary.json` (ค่าตั้งต้น sync-server/web/test/out/measure-parity/)
//
// ต่างจาก replay.mjs: replay เล่นคำตอบที่ iOS จดไว้ซ้ำ (พิสูจน์อัลกอริทึมของ solver) · ตัวนี้ให้เว็บ **วัดเอง** (พิสูจน์ตัววัด)

import fs from 'node:fs'
import path from 'node:path'
import http from 'node:http'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'

const here = path.dirname(fileURLToPath(import.meta.url))
const repo = path.resolve(here, '../../..')
const webDir = path.resolve(here, '..')
const fontDir = path.join(repo, 'StarCard/StarCard/Resources/Fonts')
const fixtureDir = path.join(repo, 'present/spec-fixtures/fixtures')

const argv = process.argv.slice(2)
const opt = (name, dflt) => { const i = argv.indexOf(name); return i >= 0 ? argv[i + 1] : dflt }
const outDir = path.resolve(opt('--out', path.join(here, 'out/measure-parity')))
const chromePath = opt('--chrome', process.env.CHROME ?? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome')
const explain = opt('--explain', null) // พิมพ์บรรทัดที่เว็บตัด + ความกว้างของทุกค่าที่ต่างซึ่งข้อความมีคำนี้ (ไว้ไล่สาเหตุ)
const only = argv.filter((a, i) => !a.startsWith('--') && argv[i - 1] !== '--out' && argv[i - 1] !== '--chrome' && argv[i - 1] !== '--explain')

const require = createRequire(import.meta.url)
let puppeteer
try { puppeteer = require('puppeteer-core') } catch { console.error('ต้องติดตั้งก่อน: cd sync-server && npm install'); process.exit(2) }
if (!fs.existsSync(chromePath)) { console.error(`ไม่พบ Chrome ที่ ${chromePath} — ใส่ --chrome <path> หรือ env CHROME`); process.exit(2) }

// MARK: เซิร์ฟเวอร์ไฟล์เล็ก ๆ — FontFace/ESM ต้องมาจาก http (เหมือน server.mjs: /fonts/* = Resources/Fonts · ที่เหลือ = web/)
const MIME = { '.js': 'text/javascript', '.html': 'text/html; charset=utf-8', '.ttf': 'font/ttf', '.json': 'application/json' }
const page = `<!doctype html><meta charset="utf-8"><title>measure-parity</title>
<script type="module">
  import { loadFonts, WebMeasurer, fontCSS } from '/js/measure.js'
  await loadFonts('/fonts/')
  const m = new WebMeasurer()
  // คำถามชุดหนึ่ง → คำตอบของเว็บ (ลำดับเดิม)
  window.ask = (qs) => qs.map((q) => {
    const f = { face: q.face, size: q.size, weight: q.weight, italic: !!q.italic, tracking: q.tracking || 0, kerning: q.kerning || 0, lineHeight: q.lineHeight ?? 1 }
    if (q.kind === 'lh') return { v: m.lineHeight(f) }
    const r = m.measure(q.t, f, q.width == null ? null : q.width)
    const out = { w: r.w, h: r.h, lines: r.lines }
    if (q.explain) {
      out.explain = m.layoutLines(q.t, f, q.width == null ? null : q.width).map((l) => [l.text, l.width]).concat([['stops', m.stops(q.t).join(',')]])
      const sh = m.shape(q.t, fontCSS(q.face, q.weight, !!q.italic))
      out.explain.push(['units', sh.starts.map((st) => st + ':' + sh.units.get(st)).join(',')])
    }
    return out
  })
  window.fontsReady = [...document.fonts].filter((f) => f.status === 'loaded').length
</script>`
const server = http.createServer((req, res) => {
  const rel = decodeURIComponent(new URL(req.url, 'http://x').pathname)
  if (rel === '/' || rel === '/harness.html') { res.setHeader('content-type', MIME['.html']); return res.end(page) }
  const file = rel.startsWith('/fonts/') ? path.join(fontDir, rel.slice(7)) : path.join(webDir, rel)
  if (!file.startsWith(fontDir) && !file.startsWith(webDir)) { res.statusCode = 403; return res.end() }
  if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) { res.statusCode = 404; return res.end('not found ' + rel) }
  res.setHeader('content-type', MIME[path.extname(file)] ?? 'application/octet-stream')
  fs.createReadStream(file).pipe(res)
})
await new Promise((ok) => server.listen(0, '127.0.0.1', ok))
const base = `http://127.0.0.1:${server.address().port}`

// MARK: เปิด Chrome
const browser = await puppeteer.launch({ executablePath: chromePath, headless: true, timeout: 120_000, args: ['--no-first-run', '--disable-gpu', '--force-device-scale-factor=1', '--lang=th-TH'] })
const tab = await browser.newPage()
tab.on('pageerror', (e) => console.error('page error:', e.message))
await tab.goto(`${base}/harness.html`)
await tab.waitForFunction('typeof window.ask === "function"', { timeout: 30_000 })
const fontsReady = await tab.evaluate('window.fontsReady')
if (fontsReady < 8) { console.error(`ฟอนต์โหลดได้ ${fontsReady}/8`); process.exit(2) }

// MARK: ถามทุกข้อ ทีละชนิด
const TOL = 0.0101
const kinds = []
const worst = []
let explained = 0
const allDiffs = [] // ทุกค่าที่ต่าง (ไว้วิเคราะห์สาเหตุ) → <out>/diffs.json
let T = { m: 0, w05: 0, exact: 0, strict: 0, lines: 0, lh: 0, lhSame: 0 }
const kindFiles = fs.readdirSync(fixtureDir).filter((f) => f.endsWith('.json')).sort()
  .filter((f) => !only.length || only.includes(f.slice(0, -5)))

for (const f of kindFiles) {
  const kind = f.slice(0, -5)
  const fixture = JSON.parse(fs.readFileSync(path.join(fixtureDir, f), 'utf8'))
  // คำถามเดียวกัน (ข้อความ · ฟอนต์ · ความกว้าง) ถามครั้งเดียว — iOS จดซ้ำได้หลายกรอบ
  const qs = new Map()
  for (const c of fixture.cases) {
    for (const m of c.measures ?? []) {
      const k = `m|${m.t}|${m.face}|${m.weight}|${m.size}|${m.tracking ?? 0}|${m.kerning ?? 0}|${m.italic ? 1 : 0}|${m.lineHeight ?? 1}|${m.width ?? ''}`
      if (!qs.has(k)) qs.set(k, { kind: 'm', ...m, probe: c.probe, explain: explain != null && m.t.includes(explain) })
    }
    for (const l of c.lineHeights ?? []) {
      const k = `lh|${l.face}|${l.weight}|${l.size}|${l.italic ? 1 : 0}|${l.lineHeight ?? 1}`
      if (!qs.has(k)) qs.set(k, { kind: 'lh', ...l, probe: c.probe })
    }
  }
  const list = [...qs.values()]
  const answers = []
  for (let i = 0; i < list.length; i += 2000) answers.push(...await tab.evaluate((q) => window.ask(q), list.slice(i, i + 2000)))
  const row = { kind, measures: 0, within05: 0, exact: 0, strict: 0, sameLines: 0, lineHeights: 0, lineHeightsSame: 0, firstDiffs: [] }
  list.forEach((q, i) => {
    const a = answers[i]
    if (q.kind === 'lh') {
      row.lineHeights++
      if (Math.abs(a.v - q.v) <= TOL) row.lineHeightsSame++
      else if (row.firstDiffs.length < 6) row.firstDiffs.push(`lineHeight ${q.face} ${q.size}/${q.weight} ×${q.lineHeight ?? 1}: web ${a.v} ≠ ios ${q.v}`)
      return
    }
    row.measures++
    const dw = Math.abs(a.w - q.w)
    if (dw <= 0.5) row.within05++
    if (dw <= TOL) row.exact++
    if (dw < 0.001) row.strict++
    if (a.lines === q.lines) row.sameLines++
    else if (row.firstDiffs.length < 6) row.firstDiffs.push(`lines ${a.lines} ≠ ${q.lines} «${q.t.slice(0, 30)}» ${q.face} ${q.size}/${q.weight} width ${q.width}`)
    // (dw, ข้อความ, face, size, weight, iOS w, web w, iOS lines, web lines) = ลำดับของ compare.py
    worst.push([dw, q.t.slice(0, 30), q.face, q.size, q.weight, q.w, a.w, q.lines, a.lines, kind, q.width ?? null])
    if (a.explain && (dw > (process.env.EXPLAIN_NEAR ? 0.001 : TOL) || a.lines !== q.lines || process.env.EXPLAIN_ALL) && explained++ < (process.env.EXPLAIN_ALL ? 100000 : 12)) console.log(`  explain «${q.t}» ${q.face} ${q.size}/${q.weight} tr ${q.tracking ?? 0} k ${q.kerning ?? 0} @${q.width}: ios ${q.w}/${q.lines} web ${a.w}/${a.lines}`, JSON.stringify(a.explain))
    if (dw > TOL || a.lines !== q.lines) allDiffs.push({ kind, t: q.t, face: q.face, size: q.size, weight: q.weight, tracking: q.tracking ?? 0, kerning: q.kerning ?? 0, width: q.width ?? null, ios: { w: q.w, lines: q.lines }, web: { w: a.w, lines: a.lines } })
  })
  kinds.push(row)
  T.m += row.measures; T.w05 += row.within05; T.exact += row.exact; T.strict += row.strict; T.lines += row.sameLines; T.lh += row.lineHeights; T.lhSame += row.lineHeightsSame
  const ok = row.exact === row.measures && row.sameLines === row.measures && row.lineHeightsSame === row.lineHeights
  console.log(`${kind.padEnd(18)} ${ok ? 'PASS' : 'DIFF'} measures ${String(row.measures).padStart(4)}  ≤0.5pt ${String(row.within05).padStart(4)}  exact ${String(row.exact).padStart(4)}  lines= ${String(row.sameLines).padStart(4)}  lineHeight= ${String(row.lineHeightsSame).padStart(3)}/${String(row.lineHeights).padStart(3)}`)
  for (const d of row.firstDiffs.slice(0, 3)) console.log('    ' + d)
}
await browser.close()
server.close()

worst.sort((a, b) => b[0] - a[0])
const pct = (a, b) => (b ? (100 * a / b).toFixed(2) : '0.00') + '%'
const summary = {
  date: new Date().toISOString(), chrome: await (async () => { try { return fs.readFileSync(path.join(path.dirname(chromePath), '../Info.plist'), 'utf8').match(/CFBundleShortVersionString<\/key>\s*<string>([^<]+)/)?.[1] ?? '' } catch { return '' } })(),
  kinds: kinds.length, kindsExact: kinds.filter((k) => k.exact === k.measures && k.sameLines === k.measures && k.lineHeightsSame === k.lineHeights).length,
  measures: T.m, measuresWithin05: T.w05, measuresExact: T.exact, measuresStrict: T.strict, measuresSameLines: T.lines,
  lineHeights: T.lh, lineHeightsSame: T.lhSame,
  worstMeasures: worst.slice(0, 25), perKind: kinds,
}
fs.mkdirSync(outDir, { recursive: true })
fs.writeFileSync(path.join(outDir, 'summary.json'), JSON.stringify(summary, null, 1))
fs.writeFileSync(path.join(outDir, 'diffs.json'), JSON.stringify(allDiffs, null, 1))

console.log('\n=== การวัดตัวอักษรที่ต่างมากสุด (iOS vs เว็บ) ===')
console.log('ต่าง    iOS w    เว็บ w   บรรทัด  ฟอนต์              ชนิด             ข้อความ')
for (const w of summary.worstMeasures) {
  console.log(`${w[0].toFixed(2).padStart(5)}  ${w[5].toFixed(2).padStart(7)}  ${w[6].toFixed(2).padStart(7)}  ${String(w[7]).padStart(2)}/${String(w[8]).padEnd(3)}  ${(w[2] + ' ' + w[3] + '/' + w[4]).padEnd(18)} ${w[9].padEnd(16)} «${w[1]}»${w[10] != null ? ` @${w[10]}` : ''}`)
}
console.log(`\n=== kinds ${summary.kindsExact}/${summary.kinds} ทุกค่าเท่าทุกบิต · measures ${T.m}: ≤0.5pt ${T.w05} (${pct(T.w05, T.m)}) · exact ≤0.01 ${T.exact} (${pct(T.exact, T.m)}) · ไม่ต่างเลย ${T.strict} (${pct(T.strict, T.m)}) · same lines ${T.lines} (${pct(T.lines, T.m)}) · lineHeight ${T.lhSame}/${T.lh} ===`)
console.log(`summary: ${path.relative(process.cwd(), path.join(outDir, 'summary.json'))}`)
