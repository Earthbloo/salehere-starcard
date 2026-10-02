// Star Profile Journeys — ประกอบหน้า present จากข้อมูลชุดเดียว
//   node build.mjs  →  page.html (สำหรับ Artifact: ไม่มี doctype/html/head/body) + index.html (เปิดจากเครื่อง)
// ข้อมูลที่ "ได้เพิ่ม" ของแต่ละจอมาจากโค้ด iOS (StarWizard.next + ฟอร์มสมัคร) และถูกตรวจกับ state จริง
// ที่จดจาก Simulator ตอนจบแต่ละ journey (state/*.json) — ไม่ตรง = build หยุด
import { readFileSync, writeFileSync, existsSync, readdirSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const here = dirname(fileURLToPath(import.meta.url))

// ───────── หัวข้อข้อมูล 16 ข้อของ Star Profile (ชื่อสั้นสำหรับป้าย) ─────────
const T = {
  kind: 'ประเภท', socials: 'ช่องทาง', rate: 'เรท', insight: 'ข้อมูลผู้ติดตาม', categories: 'สายที่ใช่',
  media: 'รูปและผลงาน', about: 'แนะนำตัว', province: 'พื้นที่', availability: 'วันว่าง', kyc: 'ยืนยันตัวตน',
  contact: 'ช่องทางติดต่อ', address: 'ที่อยู่', draftRounds: 'รอบแก้งาน', bank: 'บัญชีรับเงิน', limits: 'งานที่ขอผ่าน', religion: 'ศาสนา',
}
const ALL = Object.keys(T)

// ───────── ชิ้นส่วนของแถบ flow ─────────
const shot = (img, title, o = {}) => ({ type: 'shot', img, title, ...o })
const group = (label, tiles, why) => ({ type: 'group', label, tiles, why })
const tile = (img, label, gain) => ({ img, label, gain })
const arrow = (note) => ({ type: 'arrow', note })
const stub = (title, lines, tag) => ({ type: 'stub', title, lines, tag })

const journeys = [
  {
    id: 'j1', n: '1', want: 'ต้องการจะรับของไปรีวิว', nav: 'รับของไปรีวิว', title: 'เห็นงานในแอป อยากลงทะเบียน',
    line: 'ถามแค่ 8 ข้อที่แบรนด์ใช้คัดเลือก Star · ที่อยู่ถามตอนได้งาน',
    state: 'j1-end.json',
    steps: [
      shot('j1-02-campaign', 'เห็นงาน กดลงทะเบียน'),
      arrow(),
      shot('j1-03-intro', 'บอกก่อนว่าจะถามอะไร'),
      arrow(),
      group('ถาม 8 ข้อ', [
        tile('j1-04-kind', 'ประเภท', ['kind']),
        tile('j1-05-channels', 'ช่องทาง + เรท', ['socials', 'rate']),
        tile('j1-06-categories', 'สายที่ใช่', ['categories']),
        tile('j1-07-media-top', 'รูปและผลงาน', ['media']),
        tile('j1-08-province', 'พื้นที่', ['province']),
        tile('j1-09-availability', 'วันว่าง', ['availability']),
        tile('j1-09b-contact', 'ช่องทางติดต่อ', ['contact']),
        tile('j1-10-kyc', 'ยืนยันตัวตน', ['kyc']),
      ], 'แบรนด์ใช้คัดเลือก Star'),
      arrow(),
      shot('j1-11-reveal', 'เป็น STAR แล้ว'),
      arrow(),
      shot('j1-12-register', 'ฟอร์มสมัคร Line ID เติมให้แล้ว'),
      arrow(),
      shot('j1-13-registered', 'ลงทะเบียนสำเร็จ', { goal: 'สมัครงานได้' }),
      arrow('แบรนด์คัดเลือก'),
      shot('j1-14-selected', 'ได้รับเลือก กดตอบรับ'),
      arrow(),
      group('ถามเพิ่ม 2 ข้อ', [
        tile('j1-15-address', 'ที่อยู่', ['address']),
        tile('j1-16-draftrounds', 'รอบแก้งาน', ['draftRounds']),
      ]),
      arrow(),
      shot('j1-17-accept', 'ตอบรับ ที่อยู่เติมให้แล้ว', { goal: 'รับงานได้' }),
      arrow('รับของ · ทำดราฟต์'),
      shot('j1-18-linkbar', 'ดราฟต์ผ่าน กดส่งลิงก์'),
      arrow(),
      shot('j1-20-link', 'ส่งลิงก์รีวิว'),
      arrow(),
      shot('j1-21-done', 'ส่งรีวิวแล้ว', { goal: 'จบงาน' }),
    ],
    later: [
      { when: 'ฟอร์มรับเงิน (มีอยู่แล้ว)', keys: ['bank'] },
      { when: 'เติมเองใน Star Profile', keys: ['limits', 'religion'] },
      { when: 'ไม่บังคับ ข้ามได้', keys: ['insight', 'about'] },
    ],
  },
  {
    id: 'j2', n: '2', want: 'ต้องการจะเป็น Star', nav: 'เป็น Star', title: 'ตั้งใจมาเป็น Star จากลิงก์ของ MKT',
    line: 'กรอก 13 ข้อรวดเดียว · ปิดกลางทางแล้วกลับมาทำต่อได้',
    state: 'j2-end.json',
    steps: [
      stub('ลิงก์ที่ MKT วาง', ['พาเข้าหน้า Star Profile'], 'ยังไม่ได้สร้าง'),
      arrow(),
      shot('j2-01-starprofile-new', 'Star Profile กดสมัครเป็น STAR'),
      arrow(),
      group('ถาม 13 ข้อ', [
        tile('j2-02-q01', 'ประเภท', ['kind']),
        tile('j2-03-q02', 'ช่องทาง + เรท', ['socials', 'rate', 'insight']),
        tile('j2-04-q03', 'สายที่ใช่', ['categories']),
        tile('j2-05-q04', 'รูปและผลงาน', ['media', 'about']),
        tile('j2-06-q05', 'ยืนยันตัวตน', ['kyc']),
        tile('j2-07-q06', 'พื้นที่', ['province']),
        tile('j2-08-q07', 'วันว่าง', ['availability']),
        tile('j2-09-q08', 'ช่องทางติดต่อ', ['contact']),
        tile('j2-10-q09', 'ที่อยู่', ['address']),
        tile('j2-11-q10', 'บัญชีรับเงิน', ['bank']),
        tile('j2-12-q11', 'รอบแก้งาน', ['draftRounds']),
        tile('j2-13-q12', 'งานที่ขอผ่าน', ['limits']),
        tile('j2-14-q13', 'ศาสนา', ['religion']),
      ]),
      arrow(),
      shot('j2-15-starprofile-done', 'ข้อมูลครบ', { goal: 'เป็น STAR ข้อมูลครบ' }),
    ],
    later: [],
  },
  {
    id: 'j3', n: '3', want: 'ต้องการจะสร้าง Star Card', nav: 'สร้าง Star Card', title: 'เห็น Star Card ของคนอื่น อยากมีบ้าง',
    line: 'ตอบ 3 ข้อ เลือก Template ก็ได้การ์ด · ข้อมูลอื่นกรอกเมื่ออยากใช้ widget นั้น',
    state: 'j3-end.json',
    steps: [
      shot('x-export-card', 'Star Card ที่คนอื่นแชร์ สแกน QR หรือกดลิงก์', { wide: true, tag: 'ทางเข้ายังไม่ได้สร้าง' }),
      arrow(),
      stub('เข้าแอป', ['มีแอปแล้ว: เปิดได้เลย', 'ยังไม่มี: โหลดแอป แล้วล็อกอิน'], null),
      arrow(),
      shot('j2-01-starprofile-new', 'Star Profile กดเปิดการ์ดของฉัน'),
      arrow(),
      group('ถาม 3 ข้อ', [
        tile('j3-02-q1', 'ประเภท', ['kind']),
        tile('j3-03-q2', 'สายที่ใช่', ['categories']),
        tile('j3-04-q3', 'รูปและผลงาน', ['media', 'about']),
      ]),
      arrow(),
      shot('j3-04b-templates', 'ยังไม่เคยมีการ์ด เลือก Template'),
      arrow(),
      shot('j3-05-editor', 'การ์ดเปิดในห้องแต่ง', { goal: 'ได้ Star Card' }),
      arrow(),
      shot('j3-06-locked', 'ข้อมูลที่ยังไม่มี ล็อกไว้'),
      arrow(),
      group('อยากใช้ กรอก 1 ข้อ', [tile('j3-07-fill', 'ช่องทาง + เรท', ['socials', 'rate'])]),
      arrow(),
      shot('j3-08-unlocked', 'ปลดล็อก ขึ้นค่าจริง'),
      arrow(),
      shot('j3-09-share', 'แชร์การ์ด'),
    ],
    later: [
      { when: 'ตอนลงทะเบียนงาน', keys: ['province', 'availability', 'contact', 'kyc'] },
      { when: 'ตอนตอบรับงาน', keys: ['address', 'draftRounds'] },
      { when: 'ฟอร์มรับเงิน (มีอยู่แล้ว)', keys: ['bank'] },
      { when: 'เติมเองใน Star Profile', keys: ['limits', 'religion'] },
      { when: 'ไม่บังคับ ข้ามได้', keys: ['insight'] },
    ],
  },
]

// ───────── ตรวจความถูกต้องก่อน render ─────────
const fail = (m) => { console.error('✗ ' + m); process.exit(1) }
const used = new Set()
const file = (img) => (img.includes('.') ? img : img + '.jpg')
const need = (img) => { used.add(file(img)); if (!existsSync(join(here, 'shots', file(img)))) fail(`ไม่มีภาพ shots/${file(img)}`) }

for (const j of journeys) {
  const got = []
  for (const s of j.steps) {
    if (s.type === 'shot') { need(s.img); got.push(...(s.gain ?? [])) }
    if (s.type === 'group') for (const t of s.tiles) { need(t.img); got.push(...t.gain) }
  }
  const dup = got.filter((k, i) => got.indexOf(k) !== i)
  if (dup.length) fail(`${j.id}: หัวข้อได้ซ้ำ ${dup}`)
  const later = j.later.flatMap((l) => l.keys)
  const all = [...got, ...later].sort().join()
  if (all !== [...ALL].sort().join()) fail(`${j.id}: ได้ + ยังไม่ถาม ไม่ครบ 16 หัวข้อ (${got.length} + ${later.length})`)
  // state จริงจาก Simulator: have + ยืนยันตัวตน
  const st = JSON.parse(readFileSync(join(here, 'state', j.state), 'utf8'))
  const real = new Set(st.have)
  if (st.verify === 'approved') real.add('kyc')
  if ([...real].sort().join() !== [...got].sort().join()) fail(`${j.id}: ไม่ตรงกับ state จริง\n  หน้า : ${[...got].sort()}\n  แอป : ${[...real].sort()}`)
  j.got = got
  console.log(`✓ ${j.id}: ได้ ${got.length} · ยังไม่ถาม ${later.length} · ตรงกับ state จริง`)
}
for (const img of ['o-11-gate1', 'o-12-steps', 'o-13-step1', 'o-14-gate2.png', 'o-15-hub', 're-01-campaign', 're-02-intro']) need(img)
const orphan = readdirSync(join(here, 'shots')).filter((f) => /\.(jpg|png)$/.test(f) && !used.has(f))
if (orphan.length) console.log('· ภาพที่ไม่ได้ใช้: ' + orphan.join(', '))

// ───────── render ─────────
const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;')
const img = (name, alt, cls = '') => `<img${cls ? ` class="${cls}"` : ''} src="shots/${file(name)}" alt="${esc(alt)}">`
const plus = (keys) => keys?.length ? `<span class="plus">${keys.map((k) => `<i>+ ${T[k]}</i>`).join('')}</span>` : ''

function step(s) {
  if (s.type === 'arrow') return `<div class="arrow${s.note ? ' noted' : ''}" aria-hidden="true">${s.note ? `<span>${esc(s.note)}</span>` : ''}</div>`
  if (s.type === 'stub') return `<div class="stub">${s.tag ? `<em class="tag">${esc(s.tag)}</em>` : ''}<b>${esc(s.title)}</b>${s.lines.map((l) => `<span>${esc(l)}</span>`).join('')}</div>`
  if (s.type === 'group') return `<div class="group${s.tiles.length > 7 ? ' many' : ''}"><div class="group-h">${esc(s.label)}${s.why ? `<span>${esc(s.why)}</span>` : ''}</div><div class="tiles">${s.tiles.map((t) =>
    `<figure class="tile">${img(t.img, t.label)}<figcaption>${esc(t.label)}</figcaption></figure>`).join('')}</div></div>`
  return `<figure class="shot${s.wide ? ' wide' : ''}">${img(s.img, s.title)}<figcaption>${s.tag ? `<em class="tag">${esc(s.tag)}</em>` : ''}<b>${esc(s.title)}</b>${plus(s.gain)}${s.goal ? `<span class="goal">${esc(s.goal)}</span>` : ''}</figcaption></figure>`
}

const end = (j) => `<aside class="end">
  <h4>จบ Journey ${j.n}</h4>
  <p class="k">ได้แล้ว ${j.got.length} จาก ${ALL.length}</p>
  <div class="chips">${ALL.filter((k) => j.got.includes(k)).map((k) => `<i class="have">${T[k]}</i>`).join('')}</div>
  ${j.later.length ? '<p class="k">ยังไม่ถาม</p>' : '<p class="k">ครบทุกข้อแล้ว</p>'}
  ${j.later.map((l) => `<div class="later"><div class="chips">${l.keys.map((k) => `<i class="miss">${T[k]}</i>`).join('')}</div><span>${esc(l.when)}</span></div>`).join('')}
</aside>`

const lane = (j) => `<section class="lane" id="${j.id}">
  <header class="lane-h">
    <span class="num">${j.n}</span>
    <div><h2>${esc(j.title)}</h2><p>${esc(j.line)}</p></div>
    <div class="nudge"><button type="button" data-dir="-1" aria-label="เลื่อนกลับ">‹</button><button type="button" data-dir="1" aria-label="เลื่อนไปขั้นถัดไป">›</button></div>
  </header>
  <div class="strip" tabindex="0" role="group" aria-label="Journey ${j.n} ${esc(j.title)} เลื่อนไปทางขวาเพื่อดูขั้นถัดไป">
    <div class="track">${j.steps.map(step).join('')}${end(j)}</div>
  </div>
</section>`

// Flow เก่า: ทุกเป้าหมายต้องผ่านชุดเดียวกัน = 3 ขั้นสร้างโปรไฟล์ (welcomeProgress 3 ค่า) + โปรไฟล์ 100% (profileProgress 6 ส่วน)
// นับแบบเดียวกับ flow ใหม่: 1 หน้า/แผ่นที่ต้องเข้าไปกรอก = 1 ขั้น — 6 ส่วนของโปรไฟล์ 100% แตกเป็น 10 หน้า
//   ข้อมูลส่วนตัว → ชื่อเล่น · เพศ · สัดส่วน (ชื่อ-นามสกุล · วันเกิด · สัญชาติ อ่านจากยืนยันตัวตน แก้ไม่ได้ · ข้อมูลติดต่อไม่บังคับ)
//   โซเชียล & การรับงาน → ประเภทคอนเทนต์ · วันและเวลา · จังหวัด (บัญชีโซเชียล · หมวดหมู่ ทำแล้วในด่าน 1)
// ที่มา: salehere-ios ValidateRegisterSaleHereStarManagerInteractor · CreatorProfilePageMainView · CreatorEditUserInfoPageMainView
//        · CreatorTextFieldPageMainView (isEnabled: false) · CreatorProfileAvailabilityMainView · gateway user-creator-profile.type.js
const OLD_GATE1 = ['ผูกโซเชียล + ราคา', 'เลือกหมวด 3 หมวด', 'ยืนยันตัวตน']
const OLD_GATE2 = [
  'ข้อมูลผู้ใช้', 'รูปโปรไฟล์ 3 รูป',
  'ส่วนตัว: ชื่อเล่น', 'ส่วนตัว: เพศ', 'ส่วนตัว: สัดส่วน 6 ช่อง',
  'รับงาน: ประเภทคอนเทนต์', 'รับงาน: วันและเวลา', 'รับงาน: จังหวัด',
  'ที่อยู่', 'ผลงาน รูป 2 + วิดีโอ 2',
]
const OLD_STEPS = OLD_GATE1.length, OLD_PARTS = OLD_GATE2.length
const reqChips = (list) => `<div class="chips">${list.map((t) => `<i class="req">${esc(t)}</i>`).join('')}</div>`
// ช่องแรกของตารางเทียบ = ชื่อ journey ตามที่ผู้ใช้เรียก (เลขตรงกับแถบ journey ด้านล่าง)
const jCell = (i) => `<td><b class="jn">${journeys[i].n}</b>${esc(journeys[i].want)}</td>`
const oldCell = `<td class="old">${OLD_STEPS + OLD_PARTS} ขั้น<small>${OLD_STEPS} ขั้น + โปรไฟล์ 100% อีก ${OLD_PARTS} ขั้น</small></td>`

const body = `<title>Star Profile Journeys</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Anuphan:wght@400;500;600;700&family=Instrument+Serif:ital@1&display=swap">
<style>
/* แถบภาพจอเรียงแนวนอนหนึ่งแถบต่อหนึ่ง journey · ตัวหนังสือเป็นแค่ป้ายกำกับ ภาพกับลูกศรเล่าเรื่อง */
:root{
  --bg:#F5F6F8; --surface:#FFFFFF; --ink:#1C1E24; --muted:#666D7A; --line:#E2E5EB; --soft:#ECEEF2;
  --red:#E11B22; --ok:#0B8F62; --ok-soft:#E2F5EC; --warn:#8A5200; --warn-soft:#FFEFD0;
  --shadow:0 1px 2px rgba(22,24,30,.06),0 12px 30px rgba(22,24,30,.10);
  --sans:"Anuphan","Noto Sans Thai","Thonburi",system-ui,sans-serif;
  --serif:"Instrument Serif","Didot",Georgia,serif;
}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){
  --bg:#101115; --surface:#191B21; --ink:#F0F1F3; --muted:#99A0AC; --line:#2A2D36; --soft:#20232A;
  --red:#FF5C62; --ok:#3ED6A0; --ok-soft:#12301F; --warn:#F3B84C; --warn-soft:#37290E;
  --shadow:0 1px 2px rgba(0,0,0,.4),0 12px 30px rgba(0,0,0,.5); color-scheme:dark}}
:root[data-theme="dark"]{
  --bg:#101115; --surface:#191B21; --ink:#F0F1F3; --muted:#99A0AC; --line:#2A2D36; --soft:#20232A;
  --red:#FF5C62; --ok:#3ED6A0; --ok-soft:#12301F; --warn:#F3B84C; --warn-soft:#37290E;
  --shadow:0 1px 2px rgba(0,0,0,.4),0 12px 30px rgba(0,0,0,.5); color-scheme:dark}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--ink);font-family:var(--sans);font-size:15px;line-height:1.5;-webkit-font-smoothing:antialiased}
h1,h2,h3,h4,p,figure{margin:0}
i,em{font-style:normal}
.wrap{max-width:1240px;margin:0 auto;padding-inline:24px}

/* หัวหน้า */
.top{padding-block:44px 22px}
.top .eyebrow{font-size:12.5px;font-weight:600;letter-spacing:.08em;text-transform:uppercase;color:var(--red)}
.top h1{font-size:clamp(34px,5vw,54px);font-weight:700;line-height:1.08;letter-spacing:-.01em;margin-top:8px;text-wrap:balance}
.top h1 span{font-family:var(--serif);font-style:italic;font-weight:400;letter-spacing:0}
.top p{font-size:clamp(16px,2vw,19px);color:var(--muted);margin-top:12px;max-width:34em;text-wrap:balance}

/* เมนูกระโดด */
.jump{position:sticky;top:env(safe-area-inset-top,0px);z-index:5;background:color-mix(in srgb,var(--bg) 88%,transparent);backdrop-filter:blur(10px);border-bottom:1px solid var(--line)}
.jump .wrap{display:flex;gap:6px;overflow-x:auto;padding-block:10px;scrollbar-width:none}
.jump a{flex:none;font-size:14px;font-weight:600;color:var(--muted);text-decoration:none;padding:6px 13px;border-radius:999px;border:1px solid transparent}
.jump a:hover,.jump a:focus-visible{color:var(--ink);border-color:var(--line);background:var(--surface);outline:none}
.jump a b{color:var(--red);font-weight:700;margin-right:5px}

section{scroll-margin-top:64px}
.sec-h{padding-block:44px 18px}
.sec-h h2{font-size:clamp(22px,3vw,30px);font-weight:700;line-height:1.2;text-wrap:balance}
.sec-h p{color:var(--muted);font-size:16px;margin-top:6px}

/* ป้าย */
.tag{display:inline-block;font-size:11.5px;font-weight:600;color:var(--warn);background:var(--warn-soft);padding:2px 8px;border-radius:999px}
.chips{display:flex;flex-wrap:wrap;gap:6px}
.chips i{font-size:12.5px;font-weight:600;padding:3px 10px;border-radius:999px;white-space:nowrap}
.chips .have{background:var(--ink);color:var(--bg)}
.chips .miss{border:1.4px dashed var(--muted);color:var(--muted);padding:2px 9px}
.chips .req{background:var(--soft);color:var(--ink)}

/* Flow เก่า */
.gates{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,430px),1fr));gap:18px}
.gate{background:var(--surface);border:1px solid var(--line);border-radius:22px;padding:20px}
.gate h3{font-size:18px;font-weight:700}
.gate h3 small{display:block;font-size:12.5px;font-weight:600;color:var(--red);letter-spacing:.06em;margin-bottom:2px}
.gate .chips{margin-top:10px}
.gate .pics{display:flex;gap:12px;margin-top:16px;overflow-x:auto;padding-bottom:4px}
.gate .pics img.onblack{background:#0B0B0D;object-fit:contain}
.gate .pics img{flex:none;width:150px;aspect-ratio:1206/2622;object-fit:cover;object-position:top;border-radius:18px;border:1px solid var(--line);background:var(--soft)}
.old-foot{display:flex;align-items:center;gap:10px;margin-top:16px;font-weight:600;font-size:16px}
.old-foot::before{content:"";width:28px;height:2px;background:var(--ink);border-radius:2px}

/* แถบ journey */
.lane{border-top:1px solid var(--line);margin-top:44px;padding-top:30px}
.lane-h{display:flex;align-items:center;gap:16px;max-width:1240px;margin:0 auto;padding-inline:24px}
.lane-h .num{flex:none;width:52px;height:52px;border-radius:16px;background:var(--red);color:#fff;font-size:26px;font-weight:700;display:grid;place-items:center}
.lane-h h2{font-size:clamp(20px,2.8vw,28px);font-weight:700;line-height:1.2;text-wrap:balance}
.lane-h p{color:var(--muted);font-size:15.5px;margin-top:3px}
.nudge{margin-left:auto;display:flex;gap:8px;flex:none}
.nudge button{width:40px;height:40px;border-radius:999px;border:1px solid var(--line);background:var(--surface);color:var(--ink);font:600 22px/1 var(--sans);cursor:pointer;padding:0 0 3px}
.nudge button:hover{border-color:var(--muted)}
.nudge button:focus-visible{outline:2px solid var(--red);outline-offset:2px}
.strip{overflow-x:auto;margin-top:18px;padding-block:8px 26px;scrollbar-width:thin;scrollbar-color:var(--line) transparent}
.strip:focus-visible{outline:2px solid var(--red);outline-offset:-2px}
.track{display:flex;align-items:flex-start;width:max-content;padding-inline:max(24px,calc((100vw - 1240px)/2 + 24px))}

.shot{flex:none;width:208px}
.shot img{display:block;width:100%;aspect-ratio:1206/2622;object-fit:cover;object-position:top;border-radius:26px;border:1px solid var(--line);background:var(--soft);box-shadow:var(--shadow)}
.shot.wide{width:420px;padding-top:86px}
.shot.wide img{aspect-ratio:3132/2020;border-radius:16px}
figcaption{display:flex;flex-direction:column;align-items:flex-start;gap:5px;margin-top:11px}
figcaption b{font-size:14.5px;font-weight:600;line-height:1.3}
.plus{display:flex;flex-wrap:wrap;gap:4px}
.plus i{font-size:12px;font-weight:600;color:var(--ok);background:var(--ok-soft);padding:2px 8px;border-radius:999px;white-space:nowrap}
.goal{font-size:12px;font-weight:700;color:#fff;background:var(--ok);padding:3px 10px 3px 8px;border-radius:999px}
.goal::before{content:"✓ "}
:root[data-theme="dark"] .goal{color:#06231A}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]) .goal{color:#06231A}}

.arrow{flex:none;width:44px;height:454px;position:relative}
.arrow::before{content:"";position:absolute;left:7px;right:9px;top:50%;height:2px;background:var(--muted);border-radius:2px;opacity:.55}
.arrow::after{content:"";position:absolute;right:8px;top:50%;width:8px;height:8px;border-top:2px solid var(--muted);border-right:2px solid var(--muted);transform:translateY(-4px) rotate(45deg);opacity:.75}
.arrow.noted{width:128px}
.arrow span{position:absolute;left:50%;top:50%;transform:translate(-50%,-150%);font-size:12px;font-weight:600;color:var(--muted);background:var(--bg);border:1px solid var(--line);padding:3px 9px;border-radius:999px;white-space:nowrap}

.group{flex:none;border:1.5px dashed var(--line);border-radius:26px;padding:14px 14px 12px;background:color-mix(in srgb,var(--surface) 60%,transparent);margin-top:40px}
.group-h{font-size:14px;font-weight:700;margin-bottom:10px}
.group-h span{font-weight:500;color:var(--muted)}
.group-h span::before{content:" · "}
.tiles{display:grid;grid-auto-flow:column;grid-template-rows:auto;gap:10px}
.group.many{margin-top:0}
.group.many .tiles{grid-auto-flow:row;grid-template-columns:repeat(6,92px)}
.group.many .tile,.group.many .tile img{width:92px}
.tile{width:118px}
.tile img{display:block;width:118px;aspect-ratio:1206/2622;object-fit:cover;object-position:top;border-radius:15px;border:1px solid var(--line);background:var(--soft)}
.tile figcaption{display:block;margin-top:6px;font-size:12px;font-weight:600;color:var(--ok);line-height:1.25}
.tile figcaption::before{content:"+ "}

.stub{flex:none;width:168px;margin-top:150px;border:1.5px dashed var(--muted);border-radius:18px;padding:14px;display:flex;flex-direction:column;gap:5px;align-items:flex-start}
.stub b{font-size:15px;font-weight:700;line-height:1.3}
.stub span{font-size:13px;color:var(--muted);line-height:1.35}

.end{flex:none;width:292px;margin-left:30px;margin-top:40px;background:var(--surface);border:1px solid var(--line);border-radius:22px;padding:18px;box-shadow:var(--shadow)}
.end h4{font-size:17px;font-weight:700}
.end .k{font-size:12.5px;font-weight:600;color:var(--muted);margin:14px 0 7px}
.end .later{display:flex;flex-direction:column;gap:4px;margin-bottom:9px}
.end .later span{font-size:12.5px;color:var(--muted)}
.end .later span::before{content:"→ "}

/* ภาพขยาย · ตารางเทียบ (อยู่ต่อจาก Flow เก่า ก่อนเข้า journey) · ตัวอย่างไม่ถามซ้ำ */
.shot img,.tile img,.pics img{cursor:zoom-in}
dialog.zoom{border:0;padding:0;background:transparent;max-width:none;max-height:none;width:100vw;height:100vh;display:none;place-items:center;cursor:zoom-out}
dialog.zoom[open]{display:grid}
dialog.zoom::backdrop{background:rgba(10,11,14,.82)}
dialog.zoom img{max-width:min(92vw,1200px);max-height:92vh;border-radius:22px;box-shadow:0 30px 80px rgba(0,0,0,.5)}
.cmp{width:100%;border-collapse:separate;border-spacing:0;background:var(--surface);border:1px solid var(--line);border-radius:20px;overflow:hidden}
.cmp th,.cmp td{text-align:left;vertical-align:top;padding:14px 18px;border-bottom:1px solid var(--line);font-size:15.5px}
.cmp tr:last-child td{border-bottom:0}
.cmp th{font-size:12.5px;font-weight:600;color:var(--muted);letter-spacing:.04em;background:var(--soft)}
.cmp td:first-child{font-weight:700;white-space:nowrap}
.cmp td.new,.cmp td.old{font-weight:600}
.cmp td small{display:block;font-size:13px;font-weight:400;color:var(--muted);margin-top:2px}
.cmp td .why{font-weight:400;margin-left:.3em}
.cmp .jn{color:var(--red);font-weight:700;margin-right:8px}
.cmp-note{font-size:13px;color:var(--muted);margin-top:10px}
.tablebox{overflow-x:auto}
.again{display:flex;align-items:flex-start;width:max-content}
.again .have6{flex:none;width:210px;margin-top:150px;background:var(--surface);border:1px solid var(--line);border-radius:18px;padding:14px}
.again .have6 b{display:block;font-size:14.5px;margin-bottom:8px}
footer{color:var(--muted);font-size:13px;padding-block:44px 56px}
footer .tag{margin-right:6px}

@media (max-width:640px){
  .nudge{display:none}
  .group.many .tiles{grid-template-columns:repeat(6,80px)}
  .group.many .tile,.group.many .tile img{width:80px}
  .wrap,.lane-h{padding-inline:16px}
  .track{padding-inline:16px}
  .shot{width:168px}.shot.wide{width:300px;padding-top:86px}
  .arrow{height:366px}
  .group{margin-top:24px}.tile{width:96px}.tile img{width:96px}
  .stub{margin-top:110px;width:150px}
  .lane-h .num{width:42px;height:42px;font-size:21px;border-radius:13px}
  .cmp th,.cmp td{padding:11px 12px;font-size:14px}
  .cmp td:first-child{white-space:normal}
}
@media (prefers-reduced-motion:no-preference){html{scroll-behavior:smooth}}
</style>

<header class="top"><div class="wrap">
  <div class="eyebrow">Sale Here STAR</div>
  <h1>Star Profile <span>Journeys</span></h1>
  <p>Flow ใหม่ถามเฉพาะข้อมูลที่เป้าหมายนั้นต้องใช้ ที่เหลือถามเมื่อถึงเวลา</p>
</div></header>

<nav class="jump" aria-label="ไปยังตอน"><div class="wrap">
  <a href="#old">Flow เก่า</a>
  <a href="#cmp">เก่า vs ใหม่</a>
  ${journeys.map((j) => `<a href="#${j.id}"><b>${j.n}</b>${esc(j.nav)}</a>`).join('\n  ')}
  <a href="#re">ไม่ถามซ้ำ</a>
</div></nav>

<main>
<section id="old"><div class="wrap">
  <div class="sec-h"><h2>Flow เก่า: ทุกคนต้องผ่าน 2 ด่านเดียวกัน</h2><p>จะสมัครงานหรือสร้าง Star Card ก็ต้องครบทั้งหมดนี้ก่อน</p></div>
  <div class="gates">
    <div class="gate">
      <h3><small>ด่าน 1</small>สร้างโปรไฟล์ครีเอเตอร์ 3 ขั้น</h3>
      ${reqChips(OLD_GATE1)}
      <div class="pics">${img('o-11-gate1', 'ป๊อปอัป ก่อนลงทะเบียน สร้าง STAR PROFILE ให้สำเร็จเพื่อรับงาน')}${img('o-12-steps', 'แผ่นสร้างโปรไฟล์ครีเอเตอร์ 3 ขั้นตอน')}${img('o-13-step1', 'ขั้นตอนที่ 1 ผูกบัญชีโซเชียลมีเดีย')}</div>
    </div>
    <div class="gate">
      <h3><small>ด่าน 2</small>โปรไฟล์ครีเอเตอร์ 100% อีก ${OLD_PARTS} ขั้น</h3>
      ${reqChips(OLD_GATE2)}
      <div class="pics">${img('o-14-gate2.png', 'หน้าเต็มจอ โปรไฟล์ของคุณยังไม่สมบูรณ์ กรอกข้อมูลให้ครบก่อนรับงานรีวิว', 'onblack')}${img('o-15-hub', 'หน้าโปรไฟล์ครีเอเตอร์ แถบความสมบูรณ์ 100%')}</div>
    </div>
  </div>
  <div class="old-foot">รวม ${OLD_STEPS + OLD_PARTS} ขั้น ครบแล้วจึงเปิดฟอร์มสมัครได้</div>
</div></section>

<section id="cmp"><div class="wrap">
  <div class="sec-h"><h2>เป้าหมายเดียวกัน ต้องทำอะไรก่อน</h2></div>
  <div class="tablebox"><table class="cmp">
    <thead><tr><th>Journey</th><th>Flow เก่า</th><th>Flow ใหม่</th></tr></thead>
    <tbody>
      <tr>${jCell(0)}${oldCell}<td class="new">8 ข้อ<span class="why">ที่แบรนด์ใช้คัดเลือก Star</span><small>ที่อยู่ถามตอนตอบรับ</small></td></tr>
      <tr>${jCell(1)}${oldCell}<td class="new">13 ข้อในหน้า Star Profile<small>ปิดกลางทางได้ กลับมาทำต่อเฉพาะข้อที่เหลือ</small></td></tr>
      <tr>${jCell(2)}${oldCell}<td class="new">3 ข้อ<small>ที่เหลือกรอกเมื่ออยากใช้</small></td></tr>
    </tbody>
  </table></div>
  <p class="cmp-note">1 ขั้น / 1 ข้อ = 1 หน้าที่ต้องเข้าไปกรอก</p>
</div></section>

${journeys.map(lane).join('\n')}

<section id="re"><div class="wrap">
  <div class="sec-h"><h2>กรอกแล้วไม่ถามซ้ำ</h2><p>คนที่ทำ Star Card ไปแล้ว มาลงทะเบียนงาน ถูกถามแค่ 4 ข้อที่ยังไม่เคยตอบ</p></div>
</div>
<div class="strip" tabindex="0" role="group" aria-label="ตัวอย่างกรอกแล้วไม่ถามซ้ำ"><div class="track again">
  <div class="have6"><b>จบ Journey 3 มีแล้ว</b><div class="chips">${journeys[2].got.map((k) => `<i class="have">${T[k]}</i>`).join('')}</div></div>
  ${step(arrow())}
  ${step(shot('re-01-campaign', 'กดลงทะเบียนงาน'))}
  ${step(arrow())}
  ${step(shot('re-02-intro', 'ถามเฉพาะ 4 ข้อที่ยังขาด'))}
</div></div>
</section>
</main>

<dialog class="zoom" aria-label="ภาพขยาย"><img alt=""></dialog>
<footer><div class="wrap">
  <span class="tag">ยังไม่ได้สร้าง</span>= ขั้นที่ยังไม่มีในต้นแบบ · ภาพ Flow ใหม่จากต้นแบบ iOS · ภาพ Flow เก่าจากแอป Sale Here จริง · 2 ต.ค. 2569
</div></footer>
<script>
// เลื่อนแถบทีละช่วง + แตะภาพเพื่อดูใหญ่
document.querySelectorAll('.nudge button').forEach(function (b) {
  b.addEventListener('click', function () {
    var strip = b.closest('.lane').querySelector('.strip')
    strip.scrollBy({ left: Number(b.dataset.dir) * strip.clientWidth * 0.7, behavior: 'smooth' })
  })
})
var zoom = document.querySelector('dialog.zoom')
document.addEventListener('click', function (e) {
  if (zoom.open) { zoom.close(); return }
  var im = e.target.closest('.shot img, .tile img, .pics img')
  if (!im) return
  var big = zoom.querySelector('img')
  big.src = im.currentSrc || im.src; big.alt = im.alt
  zoom.showModal()
})
</script>
`

writeFileSync(join(here, 'page.html'), body)
writeFileSync(join(here, 'index.html'), `<!doctype html>
<html lang="th"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover"></head>
<body>
${body}</body></html>
`)
console.log(`✓ เขียน page.html + index.html (${(body.length / 1024).toFixed(1)} KB)`)
