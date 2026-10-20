// สร้างแถบ "Flow" ของ widget-catalog.html — flow เส้นตรงเล่าทีละขั้น: ภาพจอ → ปุ่มที่กด → ภาพถัดไป (ไม่มีเส้นแยก — ผู้ใช้ 19 ต.ค. 2569: "ไม่เอาทางแยก แบบนี้งง")
//   node shared/docs/flow/build-flow.mjs            → เขียน flow-fragment.json + flow-preview.html ไว้ในโฟลเดอร์นี้ (ดูเดี่ยว ๆ)
//   node shared/docs/flow/build-flow.mjs --splice   → ต่อเข้า shared/docs/widget-catalog.html (idempotent: ลบของเก่าก่อน)
// ภาพใน img/ = แคปจาก Simulator (build iOS 19 ต.ค. 2569) ย่อเหลือกว้าง 349px
import { readFileSync, writeFileSync, readdirSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const here = dirname(fileURLToPath(import.meta.url))
const CATALOG = join(here, '..', 'widget-catalog.html')

// ───────── ขั้นของเรื่อง ─────────
// step(img, title, sub, press, note)
//   press = ปุ่มที่กดเพื่อไปขั้นถัดไป (ป้ายบนลูกศร) · note = หมายเหตุสั้น ๆ ใต้ภาพ (ทางลัด/ทางเลือก — ไม่วาดเป็นเส้นแยก)
const step = (img, title, sub = '', press = '', note = '') => ({ img, title, sub, press, note })
// anim(prefix, n, …) = ขั้นที่เล่นเป็นแอนิเมชัน: เฟรม img/anim/<prefix>-00..n-1.jpg (12 fps วนซ้ำ) — ผู้ใช้ 19 ต.ค. 2569: "ใน journey ต้องมี UI เล่น animate ตอนเปิดการ์ดด้วย"
const anim = (prefix, n, title, sub = '', press = '', note = '') => ({ img: `anim/${prefix}-00`, anim: prefix, n, title, sub, press, note })

const LANES = [
  {
    id: 'open', n: '1', title: 'กดเข้า Star Card → ได้การ์ดใบแรก',
    lede: 'ถามแค่ 3 ข้อ: เกี่ยวกับฉัน · สายงาน · social — ไม่ต้องเป็น STAR · หัวข้ออื่นยังไม่ถาม (ไปล็อกในตู้วิดเจ็ตแทน)',
    steps: [
      step('u01-starprofile-new', 'Star Profile ผู้ใช้ใหม่', 'ยังไม่มีการ์ด · แถบเทมเพลตเลื่อนเอง', 'เปิดใช้งาน', 'แตะใบในแถบก็ได้ ไปทางเดียวกัน'),
      step('u02-cardwizard', 'ถาม 1/3 เกี่ยวกับคุณ', 'หัว "เปิด Star Card" · รูปของคุณ · รูปผลงาน · แนะนำตัว', 'ถัดไป', 'มีครบ 3 ข้ออยู่แล้ว = ข้ามไปขั้น 5 ทันที (motion ก็เล่น)'),
      step('u03-step2', 'ถาม 2/3 สายงาน', 'เลือก 3–5 สาย', 'ถัดไป'),
      step('u04-step3', 'ถาม 3/3 social', 'ผูก 1 ช่องพอ · ตั้งเรทได้ตอนเชื่อม', 'ไปเลือกแบบการ์ด'),
      anim('reveal', 30, 'motion "ST★R Card" (เล่นจริง)', 'เต็มจอ ~2.5 วิ · "เลือกแบบการ์ดใบแรก · ข้อมูลของคุณเติมลงการ์ดให้เอง" · อัดจากต้นแบบ 12 fps', '', 'เล่นครั้งเดียว · ครั้งต่อไปข้ามไป Template เลย'),
      step('s09-templates', 'Template', 'เลือกแนวก่อน: แนวนอน 3 หน้า / แนวตั้ง 1 หน้า (ดูตอนที่ 2) · "เริ่มจากว่าง" ก็ได้', 'แตะเทมเพลต'),
      step('s10-editor', 'ห้องแต่ง', 'ได้การ์ดใบแรก วิดเจ็ตในแบบนั้นเติมข้อมูลของคุณให้แล้ว', '‹ กลับ', 'ออกโดยไม่แตะอะไร = ทิ้งใบนั้น'),
      step('v01-starprofile', 'Star Profile มีการ์ดแล้ว', 'มีการ์ดก่อนเป็น STAR (38%) · ดูการ์ด · แชร์ · ยอดวิว', '', 'จบตอนที่ 1'),
    ],
  },
  {
    id: 'cards', n: '2', title: 'แนวนอน / แนวตั้ง · มีได้หลายใบ',
    lede: 'แนวนอน = 3 หน้าต่อกัน (ส่งให้แบรนด์ · ส่งออกเป็นรูปยาว) · แนวตั้ง = สตอรี่ 1 หน้า 9:16 (ลง IG Story) · กด + ในคลังสร้างเพิ่มได้เรื่อย ๆ ทุกใบมีลิงก์ของตัวเอง แต่ "กำลังแสดงอยู่" มีใบเดียว',
    steps: [
      step('c00-gallery', 'คลังการ์ด', 'มีใบแรกแล้ว (แนวนอน) · ป้าย "กำลังแสดงอยู่" · ลิงก์หลัก', '+'),
      step('t03-templates', 'Template แนวนอน', '3 หน้าต่อกัน · ปัดดูทีละหน้า', 'สลับ "แนวตั้ง"'),
      step('c01-template-story', 'Template แนวตั้ง', 'สตอรี่ 1 หน้า 9:16 · แบบเดียวกันจัดใหม่ให้พอดีจอ', 'แตะเทมเพลต'),
      step('c02-story-editor', 'ห้องแต่ง แนวตั้ง', 'หน้าเดียว ไม่มีจุดหน้า · แต่งเหมือนกันทุกอย่าง', '‹ กลับคลัง'),
      step('c04-gallery-story', 'คลังมีหลายใบ', 'ปัดดูทีละใบ · ใบใหม่ยังไม่แสดง · มีลิงก์ของใบเอง (/c/…)', 'ใช้ใบนี้'),
      step('c05-use-this', 'ใบนี้ "กำลังแสดงอยู่"', 'ลิงก์หลักชี้ใบนี้ · ใบอื่นยังแชร์แยกได้ · ⋯ = ทำสำเนา / เปลี่ยนชื่อ / ลบ', '', 'จบตอนที่ 2'),
    ],
  },
  {
    id: 'widget', n: '3', title: 'เพิ่มวิดเจ็ต → เลือกอันใหม่',
    lede: 'ตู้วิดเจ็ตเรียงแท็บตามหัวข้อของ Star Profile · หัวข้อที่กรอกแล้ววางได้เลย · ใบเดียวกันมีหลายแบบ เปลี่ยนได้ในชีตของใบ',
    steps: [
      step('t05-editor-blank', 'ห้องแต่ง', 'แถบล่าง 3 ปุ่ม: พื้นหลัง · ข้อความ · วิดเจ็ต', 'วิดเจ็ต'),
      step('t06-widgetgallery', 'ตู้วิดเจ็ต', 'แท็บบน = หัวข้อ Star Profile · เปิดมาที่ "โปรไฟล์"', 'แตะแท็บ "ช่องทาง"'),
      step('t08-tab-channels', 'แท็บ "ช่องทาง"', 'ใบเดียวกันหลายแบบ ข้อมูลจริงของคุณทุกใบ', 'แตะใบ'),
      step('t09-placed', 'วางลงการ์ด + ชีตของใบเปิดทันที', 'แบบ · ช่องทาง · พื้นหลัง · มุม · ขอบ · ลบ', 'แตะ "แบบ" อื่น'),
      step('t10-variant2', 'เปลี่ยนแบบ', 'ข้อมูลเดิม หน้าตาใหม่ · เปลี่ยนไปมาได้', '‹ ปิดชีต'),
      step('t11-card-widget', 'การ์ดมีวิดเจ็ตแล้ว', 'กลับแถบหลัก · กด "วิดเจ็ต" เพิ่มใบต่อไป', '', 'ลากย้าย · มุมขวาล่างย่อขยาย · ชิ้นอื่นหลบให้เอง'),
    ],
  },
  {
    id: 'locked', n: '4', title: 'หัวข้อที่ยังไม่กรอก = ล็อก · กดแล้วไปไหน',
    lede: 'ชิปเส้นประ = ยังไม่กรอก · ใบมีกุญแจ แตะแล้วถาม 1 ข้อ ปลดทั้งหมวด + วางใบที่แตะให้เลย · แบรนด์/ผลงานยืนยัน ล็อกจนทำงานกับ Sale Here จบ 1 งาน',
    steps: [
      step('v03-tabs', 'ปัดแถบแท็บ', 'ชิปเส้นประ = ยังไม่กรอก (ยืนยันตัวตน · ติดต่อ · สัดส่วน · เรท …)', 'แตะ "ติดต่อ"'),
      step('v04-contact-locked', 'หมวดที่ล็อก', 'ใบมีกุญแจ เห็นตัวอย่างใต้ม่าน · ปุ่ม "กรอกช่องทางติดต่อ"', 'แตะใบ'),
      step('t13-topicfill', 'ถาม 1 ข้อ', 'หน้าเดียวกับใน Star Profile · ข้อมูลไปขึ้น Star Profile ด้วย', 'บันทึก', '"ข้ามไว้ก่อน" = กลับตู้ ใบยังล็อก'),
      step('t14-autoplaced', 'ปลดทั้งหมวด + วางใบที่แตะให้เลย', 'ชีตของใบเปิดต่อ เปลี่ยนแบบได้ทันที', 'ปัดไปแท็บ "ผลงาน"'),
      step('t18-tab-works', 'แบรนด์ · ผลงานยืนยัน', 'ล็อกถาวร "ทำงานกับ Sale Here ก่อน" — กรอกเองไม่ได้', 'แตะใบ'),
      step('t19-locked-alert', 'กล่องบอกเงื่อนไข', '"โลโก้แบรนด์และผลงานยืนยันมาจากงานที่ทำจบผ่าน Sale Here"', 'ดูงานที่เปิดรับ', '"ไว้ก่อน" = กลับตู้'),
      step('j1-02-campaign', 'หน้าแรก กิจกรรม STAR', 'ไปรับงานแรก · จบงานแล้วใบพวกนี้ปลดเอง', '', 'จบตอนที่ 4'),
    ],
  },
]

// ───────── ภาพ (base64) เฉพาะที่ใช้ ─────────
const IMG = {}
const used = new Set(LANES.flatMap(l => l.steps.flatMap(s => s.anim ? Array.from({ length: s.n }, (_, i) => `anim/${s.anim}-${String(i).padStart(2, '0')}`) : [s.img])))
for (const f of readdirSync(join(here, 'img'))) {
  const k = f.replace(/\.jpg$/, '')
  if (f.endsWith('.jpg') && used.has(k)) IMG[k] = 'data:image/jpeg;base64,' + readFileSync(join(here, 'img', f)).toString('base64')
}
for (const f of readdirSync(join(here, 'img', 'anim'))) {
  const k = 'anim/' + f.replace(/\.jpg$/, '')
  if (f.endsWith('.jpg') && used.has(k)) IMG[k] = 'data:image/jpeg;base64,' + readFileSync(join(here, 'img', 'anim', f)).toString('base64')
}
for (const k of used) if (!IMG[k]) throw new Error('ไม่มีภาพ img/' + k + '.jpg')

// ───────── CSS ─────────
const CSS = `
  /* ===== แถบ Flow ===== */
  #flow { display:none; } body.flow #flow { display:block; } body.flow #home, body.flow article.wd { display:none !important; }
  #flow .fw-top { padding-top:26px; }
  .fw-chips { position:sticky; top:50px; z-index:7; display:flex; gap:6px; overflow-x:auto; padding:8px 16px 10px; margin:0 -16px; background:color-mix(in srgb, var(--bg) 94%, transparent); backdrop-filter:blur(8px); -webkit-backdrop-filter:blur(8px); scrollbar-width:none; }
  .fw-chips button { flex:none; font:600 13px var(--display); padding:6px 12px; border-radius:999px; border:1px solid var(--line); background:var(--paper); color:var(--mute); cursor:pointer; white-space:nowrap; }
  .fw-chips button b { color:var(--accent); margin-right:5px; } .fw-chips button:hover { color:var(--ink); border-color:var(--ink); }
  .fw-lane { margin-top:36px; scroll-margin-top:104px; }
  .fw-head { display:flex; align-items:flex-start; gap:14px; margin-bottom:12px; }
  .fw-head .n { flex:none; width:36px; height:36px; border-radius:50%; background:var(--ink); color:var(--paper); font:700 17px/36px var(--display); text-align:center; }
  .fw-head h2 { margin:0; font:700 22px/1.25 var(--display); } .fw-head h2 small { font:400 13px var(--body); color:var(--faint); margin-left:8px; }
  .fw-head p { margin:4px 0 0; color:var(--mute); font-size:13.5px; max-width:70em; }
  .fw-strip { overflow-x:auto; overscroll-behavior-x:contain; border:1px solid var(--line); border-radius:16px; background:var(--paper); padding:26px 24px 22px; scroll-snap-type:x proximity; }
  .fw-track { display:flex; align-items:flex-start; gap:0; width:max-content; }
  .fw-step { flex:none; width:172px; scroll-snap-align:start; position:relative; }
  .fw-step .k { position:absolute; top:-12px; left:-6px; z-index:2; width:26px; height:26px; border-radius:50%; background:var(--ink); color:var(--paper); font:700 12.5px/26px var(--display); text-align:center; box-shadow:0 0 0 3px var(--paper); }
  .fw-step img { display:block; width:172px; height:374px; object-fit:cover; object-position:top; border-radius:18px; border:1px solid var(--line); box-shadow:0 8px 22px rgba(0,0,0,.14); cursor:zoom-in; background:#111; }
  .fw-step b { display:block; margin-top:10px; font:700 14px/1.3 var(--display); color:var(--ink); }
  .fw-step span { display:block; margin-top:3px; font-size:12px; line-height:1.4; color:var(--mute); }
  .fw-step em { display:block; margin-top:7px; font-style:normal; font-size:11.5px; line-height:1.35; color:var(--mute); padding:5px 8px; border-radius:8px; background:var(--chip); border-left:3px solid var(--line); }
  .fw-step em.end { background:#0B8F62; color:#fff; border-left:0; font-weight:700; text-align:center; }
  .fw-arrow { flex:none; width:118px; height:374px; display:flex; flex-direction:column; align-items:center; justify-content:center; gap:6px; }
  .fw-arrow i { display:block; width:100%; height:0; border-top:2px solid var(--ink); position:relative; }
  .fw-arrow i::after { content:""; position:absolute; right:-1px; top:-6px; border:5px solid transparent; border-left:7px solid var(--ink); border-right:0; }
  .fw-arrow s { text-decoration:none; font:700 12.5px var(--display); padding:5px 10px; border-radius:999px; background:var(--paper); border:1.5px solid var(--ink); color:var(--ink); text-align:center; max-width:112px; line-height:1.25; }
  .fw-arrow.auto i { border-top-style:dashed; border-color:var(--faint); } .fw-arrow.auto i::after { border-left-color:var(--faint); } .fw-arrow.auto s { border-style:dashed; border-color:var(--faint); color:var(--mute); font-weight:500; }
  .fw-step img:hover { box-shadow:0 12px 30px rgba(0,0,0,.24); }
  .fw-step .fw-live { position:absolute; top:10px; right:10px; z-index:2; font:700 10.5px var(--display); font-style:normal; color:#fff; background:rgba(200,30,40,.92); padding:3px 8px; border-radius:999px; letter-spacing:.02em; }
  .fw-isanim img { box-shadow:0 0 0 2px rgba(255,200,80,.55), 0 8px 22px rgba(0,0,0,.14); }
  #flb { position:fixed; inset:0; background:rgba(0,0,0,.84); z-index:60; display:none; align-items:center; justify-content:center; cursor:zoom-out; }
  #flb.on { display:flex; } #flb img { height:min(92vh, 1300px); border-radius:30px; box-shadow:0 20px 60px rgba(0,0,0,.6); }
  #flb figcaption { position:absolute; bottom:20px; left:0; right:0; text-align:center; color:#fff; font:600 15px var(--display); }
  @media (max-width:640px) { .fw-strip { padding:22px 14px; } .fw-step { width:140px; } .fw-step img { width:140px; height:305px; } .fw-arrow { width:84px; height:305px; } }
`

// ───────── HTML ─────────
const esc = s => String(s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;')
const laneHTML = l => `
    <section class="fw-lane" id="fw-${l.id}">
      <div class="fw-head"><span class="fw-n">${l.n}</span><div><h2>${esc(l.title)}<small>${l.steps.length} ขั้น</small></h2><p>${esc(l.lede)}</p></div></div>
      <div class="fw-strip"><div class="fw-track">${l.steps.map((s, i) => {
        const last = i === l.steps.length - 1
        const note = s.note ? `<em class="${/^จบ/.test(s.note) ? 'end' : ''}">${esc(s.note)}</em>` : ''
        const arrow = last ? '' : `<div class="fw-arrow${s.press ? '' : ' auto'}"><s>${esc(s.press || 'ระบบพาไปเอง')}</s><i></i></div>`
        const animAttr = s.anim ? ` data-anim="${s.anim}" data-n="${s.n}"` : ''
        const badge = s.anim ? '<i class="fw-live">▶ เล่นอยู่</i>' : ''
        return `<figure class="fw-step${s.anim ? ' fw-isanim' : ''}"><span class="fw-k">${i + 1}</span>${badge}<img alt="" data-img="${s.img}" data-t="${esc(s.title)}"${animAttr}><figcaption><b>${esc(s.title)}</b>${s.sub ? `<span>${esc(s.sub)}</span>` : ''}${note}</figcaption></figure>${arrow}`
      }).join('')}</div></div>
    </section>`

const SECTION = `
<section id="flow" aria-label="Flow">
  <div class="fw-top">
    <header class="top">
      <div class="eyebrow">Star Card · Flow</div>
      <h1>กดเข้า Star Card → Template → เพิ่มวิดเจ็ต</h1>
      <p class="lede">เล่าเป็นเส้นตรงทีละขั้น: ภาพจอ → ปุ่มที่กด → ภาพถัดไป · ภาพจริงจาก build iOS 19 ต.ค. 2569 · แตะภาพเพื่อขยาย · เลื่อนแถบไปทางขวา</p>
    </header>
    <nav class="fw-chips" aria-label="ไปยังตอน">${LANES.map(l => `<button type="button" data-fl="${l.id}"><b>${l.n}</b>${esc(l.title)}</button>`).join('')}</nav>
    <div id="flow-lanes">${LANES.map(laneHTML).join('')}
    </div>
  </div>
</section>
<div id="flb" role="dialog" aria-label="ภาพขยาย"><figure><img alt=""><figcaption></figcaption></figure></div>`

// ───────── JS ─────────
const JS = `
// ---------- Flow: เติมภาพ + lightbox ----------
(() => {
  const FLOWIMG = ${JSON.stringify(IMG)};
  const lb = document.getElementById('flb');
  lb.addEventListener('click', () => lb.classList.remove('on'));
  document.addEventListener('keydown', ev => { if (ev.key === 'Escape') lb.classList.remove('on'); });
  let filled = false;
  // แอนิเมชัน: วนเฟรม 12 fps ค้างเฟรมสุดท้าย 1.2 วิ แล้วเริ่มใหม่ · lightbox เล่นตามเฟรมเดียวกัน
  const anims = [];
  setInterval(() => {
    for (const a of anims) {
      a.tick += 1;
      const hold = 14; // เฟรมที่ค้างท้าย
      const i = a.tick % (a.n + hold); const f = Math.min(i, a.n - 1);
      const src = FLOWIMG['anim/' + a.key + '-' + String(f).padStart(2, '0')];
      if (src && a.frame !== f) { a.frame = f; a.img.src = src; if (lb.classList.contains('on') && lb.dataset.anim === a.key) lb.querySelector('img').src = src; }
    }
  }, 1000 / 12);
  function open() {
    if (filled) return; filled = true;
    document.querySelectorAll('#flow img[data-img]').forEach(img => {
      img.src = FLOWIMG[img.dataset.img] || '';
      if (img.dataset.anim) anims.push({ key: img.dataset.anim, n: +img.dataset.n, img, tick: 0, frame: -1 });
      img.addEventListener('click', () => { lb.dataset.anim = img.dataset.anim || ''; lb.querySelector('img').src = img.src; lb.querySelector('figcaption').textContent = img.dataset.t; lb.classList.add('on'); });
    });
  }
  document.querySelectorAll('.fw-chips button').forEach(b => b.addEventListener('click', () => document.getElementById('fl-' + b.dataset.fw-lane)?.scrollIntoView({ behavior: 'smooth', block: 'start' })));
  // ไม่ดักล้อเมาส์บนแถบ — เคยแปลงเป็นเลื่อนแนวนอน แล้วหน้าเลื่อนขึ้นลงไม่ได้ (ผู้ใช้ 19 ต.ค. 2569) · ปัดซ้ายขวาด้วย trackpad/แถบเลื่อนของแถบเอง
  window.addEventListener('flow-open', open);
  if (location.hash === '#flow') open();
})();
`

// ───────── เขียนไฟล์ ─────────
const NAV = '<a href="#flow" data-tab="flow">Flow <small>Star Card → Template → วิดเจ็ต</small></a>'
writeFileSync(join(here, 'flow-fragment.json'), JSON.stringify({ css: CSS, nav: NAV, section: SECTION, js: JS }))
writeFileSync(join(here, 'flow-preview.html'), `<!doctype html><html lang="th"><meta charset="utf-8"><title>flow preview</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Anuphan:wght@500;600;700&family=IBM+Plex+Sans+Thai:wght@400;500;600&display=swap">
<style>:root { --bg:#f6f4f5; --paper:#fff; --ink:#1d1416; --mute:#6c5d61; --faint:#a1959a; --line:#e6dde0; --chip:#f2edef; --accent:#9c2236; --display:"Anuphan",sans-serif; --body:"IBM Plex Sans Thai",sans-serif; }
body { margin:0; background:var(--bg); color:var(--ink); font:15px/1.6 var(--body); padding:0 16px 80px; } .page { max-width:1120px; margin:0 auto; } .top .eyebrow{font-size:12px;color:var(--accent);font-weight:600} .top h1{margin:4px 0;font:700 30px var(--display)} .lede{color:var(--mute)}
${CSS}</style><body class="flow"><div class="page">${SECTION}</div><script>${JS}</script>`)
console.log('fragment ok · images', Object.keys(IMG).length, '· lanes', LANES.length, '· steps', LANES.reduce((n, l) => n + l.steps.length, 0), '· js', (JS.length / 1e6).toFixed(2), 'MB')

if (process.argv.includes('--splice')) {
  let html = readFileSync(CATALOG, 'utf8')
  // ลบของเก่า (ถ้าเคยต่อแล้ว)
  html = html.replace(/\n  \/\* ===== แถบ Flow ===== \*\/[\s\S]*?(?=\n<\/style>)/, '')
  html = html.replace(/<a href="#flow" data-tab="flow">[^<]*<small>[^<]*<\/small><\/a>/, '')
  html = html.replace(/\n<section id="flow" aria-label="Flow">[\s\S]*?<\/section>\n<div id="flb"[^\n]*\n/, '\n')
  html = html.replace(/\n<script>\n\/\/ ---------- Flow: [^\n]*\n[\s\S]*?<\/script>\n?$/, '\n')
  // ต่อใหม่
  const nStyle = html.indexOf('\n</style>'); html = html.slice(0, nStyle) + '\n' + CSS.trimEnd() + html.slice(nStyle)
  html = html.replace('<small>ข้อมูล merge ตรงไหน</small></a></nav>', '<small>ข้อมูล merge ตรงไหน</small></a>' + NAV + '</nav>')
  html = html.replace('</section>\n</div>\n<script>', '</section>' + SECTION + '\n</div>\n<script>')
  html = html.replace("const view = (h === 'play' || h === 'render') ? h : 'cat';", "const view = (h === 'play' || h === 'render' || h === 'flow') ? h : 'cat';")
  html = html.replace("document.body.classList.toggle('render', view === 'render');", "document.body.classList.toggle('render', view === 'render'); document.body.classList.toggle('flow', view === 'flow');")
  html = html.replace("document.title = (view === 'play' ? 'ลองวางการ์ด' : 'วิธีวาด') + ' · Widget Catalog';", "document.title = ({ play: 'ลองวางการ์ด', render: 'วิธีวาด', flow: 'Flow' })[view] + ' · Widget Catalog';")
  html = html.trimEnd() + '\n<script>' + JS + '</script>\n'
  for (const must of ['data-tab="flow"', 'id="flow"', "h === 'flow'", "toggle('flow'", 'Flow: เติมภาพ', '===== แถบ Flow']) if (!html.includes(must)) throw new Error('splice ไม่ครบ: ' + must)
  if ((html.match(/id="flow"/g) || []).length !== 1) throw new Error('มี section flow ซ้ำ')
  writeFileSync(CATALOG, html)
  console.log('spliced →', CATALOG, (html.length / 1e6).toFixed(1), 'MB')
}
