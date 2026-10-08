// Star Profile Journeys — ประกอบหน้า present จากข้อมูลชุดเดียว
//   node build.mjs  →  page.html (สำหรับ Artifact: ไม่มี doctype/html/head/body) + index.html (เปิดจากเครื่อง)
// ข้อมูลที่ "ได้เพิ่ม" ของแต่ละจอมาจากโค้ด iOS (StarWizard.next + ฟอร์มสมัคร) และถูกตรวจกับ state จริง
// ที่จดจาก Simulator ตอนจบแต่ละ journey (state/*.json) — ไม่ตรง = build หยุด
import { readFileSync, writeFileSync, existsSync, readdirSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const here = dirname(fileURLToPath(import.meta.url))

// ───────── หัวข้อข้อมูล 13 ข้อของ Star Profile (ชื่อสั้นสำหรับป้าย) ─────────
// 4 ต.ค. 2569: ตัด รอบแก้งาน · งานที่ขอผ่าน · ศาสนา ออกจาก flow ("เอาออกไปเลย ไม่ต้องมีละ จะได้ลด step") — เดิม 16 ข้อ
// 6 ต.ค. 2569: เพิ่ม สัดส่วน (6 ช่องเดียวกับหน้า "สัดส่วน" ของแอปหลัก) — ถามต่อท้ายเฉพาะ journey 2 ที่ตั้งใจมาเป็น Star · ทางอื่นเข้ามากรอกเองใน Star Profile
//   และช่วงเวลาว่างเปลี่ยนจาก เช้า/บ่าย/เย็น เป็น 4 ช่วงนาฬิกาเดียวกับแอปหลัก (09.00–12.00 · 12.00–14.00 · 14.00–17.00 · 17.00 เป็นต้นไป) — 14 ข้อ
// 6 ต.ค. 2569 (เย็น): STAR = ครบ 8 ข้อที่แบรนด์ใช้คัดเลือก (รวมยืนยันตัวตนผ่าน) — ทุกทางเข้าถาม 8 ข้อนี้ก่อนเสมอ ครบ = motion "คุณเป็น STAR แล้ว" แล้วค่อยทำต่อ
//   (7 ต.ค. 2569 ตาม salehere-ios: % กลับมาเฉพาะก่อนเป็น STAR · หลังเป็น = การ์ดทอง "ใช้สมัครเป็น STAR" + การ์ดเทา "ใช้ให้แบรนด์คัดเลือก") เดิม: หน้า Star Profile ไม่มี % แล้ว: ก่อนเป็น STAR เห็นแค่ 8 ข้อ · เป็นแล้ว ยุบเป็น "ครบแล้ว" + กลุ่ม "เติมเมื่อถึงเวลา" (ที่อยู่ · บัญชี · สัดส่วน · แนะนำตัว · ข้อมูลผู้ติดตาม)
// 7 ต.ค. 2569: ชื่อข้อ = ชื่อเดียวกับแอปหลัก (salehere-ios STAR-FLOW-RULES ข้อ 1 "ชื่อข้อใช้คำเดียวกันทุกที่") · STAR เก่าที่มียศ = เป็น STAR แม้ 8 ข้อยังไม่ครบ (สถานะ C)
const T = {
  kind: 'ประเภทครีเอเตอร์', socials: 'ช่องทางของฉัน', rate: 'เรทรับงาน', insight: 'ข้อมูลผู้ติดตาม', categories: 'สายที่ใช่',
  media: 'เกี่ยวกับคุณ', about: 'แนะนำตัว', province: 'พื้นที่รับงาน', availability: 'วันเวลาว่างรับงาน', kyc: 'ยืนยันตัวตน',
  contact: 'ช่องทางติดต่อ', address: 'ที่อยู่รับของ', bank: 'การรับเงิน', body: 'สัดส่วน',
}
const ALL = Object.keys(T)

// ───────── ชิ้นส่วนของแถบ flow ─────────
const shot = (img, title, o = {}) => ({ type: 'shot', img, title, ...o })
const group = (label, tiles, why) => ({ type: 'group', label, tiles, why })
const tile = (img, label, gain) => ({ img, label, gain })
const arrow = (note) => ({ type: 'arrow', note })
const stub = (title, lines, tag) => ({ type: 'stub', title, lines, tag })
const or = (note) => ({ type: 'or', note })

const journeys = [
  {
    id: 'j1', n: '1', want: 'ต้องการจะรับของไปรีวิว', notes: ['เล่นอยู่ในแอป', 'เข้ามาจะเอาของเลย'], nav: 'รับของไปรีวิว', title: 'เห็นงานในแอป อยากลงทะเบียน',
    line: 'ถามแค่ 8 ข้อที่แบรนด์ใช้คัดเลือก Star · ที่อยู่กรอกในฟอร์มสมัครเหมือนเดิม',
    state: 'j1-end.json',
    steps: [
      shot('j1-02-campaign', 'เห็นงาน กดลงทะเบียน'),
      arrow(),
      shot('j1-03-intro', 'บอกก่อนว่าจะถามอะไร ช่องเส้นประ 1 ช่องต่อ 1 ข้อ'),
      arrow(),
      group('ถาม 8 ข้อ', [
        tile('j1-04-kind', 'ประเภทครีเอเตอร์', ['kind']),
        tile('j1-05-channels', 'ช่องทางของฉัน + เรท', ['socials', 'rate']),
        tile('j1-06-categories', 'สายที่ใช่', ['categories']),
        tile('j1-07-media-top', 'เกี่ยวกับคุณ', ['media']),
        tile('j1-08-province', 'พื้นที่รับงาน', ['province']),
        tile('j1-09-availability', 'วันเวลาว่างรับงาน', ['availability']),
        tile('j1-09b-contact', 'ช่องทางติดต่อ', ['contact']),
        tile('j1-10-kyc', 'ยืนยันตัวตน', ['kyc']),
      ], 'แบรนด์ใช้คัดเลือก Star'),
      arrow(),
      shot('j1-11-reveal', 'เป็น STAR แล้ว'),
      arrow(),
      // 6 ต.ค. 2569: ที่อยู่กลับไปอยู่ในฟอร์มสมัครเดิม 7 ช่องเหมือนแอปหลัก ("ไม่ต้องแทรกจังหวะตอบรับ") — เดิมเป็นข้อแทรกก่อนตอบรับ
      shot('j1-12-register', 'ฟอร์มสมัครเดิม ที่อยู่ 7 ช่อง Line ID เติมให้แล้ว', { gain: ['address'] }),
      arrow(),
      shot('j1-13-registered', 'ลงทะเบียนสำเร็จ', { goal: 'สมัครงานได้' }),
      arrow('แบรนด์คัดเลือก'),
      shot('j1-14-selected', 'ได้รับเลือก กดตอบรับ'),
      arrow(),
      shot('j1-17-accept', 'ตอบรับ ที่อยู่จากฟอร์มสมัคร ไม่ถามซ้ำ', { goal: 'รับงานได้' }),
      arrow('รับของ · ทำดราฟต์'),
      shot('j1-18-linkbar', 'ดราฟต์ผ่าน กดส่งลิงก์'),
      arrow(),
      shot('j1-20-link', 'ส่งลิงก์รีวิว'),
      arrow(),
      shot('j1-21-done', 'ส่งรีวิวแล้ว', { goal: 'จบงาน' }),
    ],
    later: [
      { when: 'ฟอร์มรับเงิน (มีอยู่แล้ว)', keys: ['bank'] },
      { when: 'เข้ามากรอกเองใน Star Profile', keys: ['body'] },
      { when: 'ไม่บังคับ ข้ามได้', keys: ['insight', 'about'] },
    ],
  },
  {
    id: 'j2', n: '2', want: 'ต้องการจะเป็น Star', notes: ['เข้ามาอยากเป็น Star เลย', 'MKT วางลิงก์สมัคร Star จากข้างนอก'], nav: 'เป็น Star', title: 'ตั้งใจมาเป็น Star จากลิงก์ของ MKT',
    line: '8 ข้อเดียวกับทางลงทะเบียน → เป็น STAR → ต่ออีก 3 ข้อในรอบเดียว · ปิดกลางทางแล้วกลับมาทำต่อได้',
    state: 'j2-end.json',
    steps: [
      stub('ลิงก์ที่ MKT วาง', ['พาเข้าหน้า Star Profile'], 'ยังไม่ได้สร้าง'),
      arrow(),
      shot('j2-01-starprofile-new', 'Star Profile หัว "สมัครเป็น STAR" % ทางไปเป็น STAR · ข้อที่ขาดยังแตะไม่ได้ ไปทางปุ่มล่าง'),
      arrow(),
      group('ถาม 8 ข้อ', [
        tile('j2-02-q01', 'ประเภทครีเอเตอร์', ['kind']),
        tile('j2-03-q02', 'ช่องทางของฉัน + เรท', ['socials', 'rate', 'insight']),
        tile('j2-04-q03', 'สายที่ใช่', ['categories']),
        tile('j2-05-q04', 'เกี่ยวกับคุณ', ['media', 'about']),
        tile('j2-06-q05', 'พื้นที่รับงาน', ['province']),
        tile('j2-07-q06', 'วันเวลาว่างรับงาน', ['availability']),
        tile('j2-08-q07', 'ช่องทางติดต่อ', ['contact']),
        tile('j2-09-q08', 'ยืนยันตัวตน', ['kyc']),
      ], 'แบรนด์ใช้คัดเลือก Star · ชุดเดียวกับ Journey 1'),
      arrow('ครบ 8 ข้อ'),
      shot('j2-13-star', 'เป็น STAR แล้ว motion กลางทาง'),
      arrow('ทำต่อเลย'),
      group('ต่ออีก 3 ข้อ', [
        tile('j2-10-q09', 'ที่อยู่รับของ', ['address']),
        tile('j2-11-q10', 'การรับเงิน', ['bank']),
        tile('j2-12-q11', 'สัดส่วน', ['body']),
      ], 'ไม่ใช่ด่าน ใช้เมื่อถึงเวลา · ถามต่อเลยเพราะคนที่ตั้งใจมาเป็น STAR กรอกอยู่แล้ว'),
      arrow(),
      shot('j2-15-starprofile-done', 'Star Profile การ์ดทอง "ใช้สมัครเป็น STAR" ครบ 8 ข้อ + การ์ดเทา "ใช้ให้แบรนด์คัดเลือก" ครบ 5 ข้อ', { goal: 'เป็น STAR ข้อมูลครบ' }),
    ],
    later: [],
  },
  {
    id: 'j3', n: '3', want: 'ต้องการจะสร้าง Star Card', notes: ['อยากมี Star Card'], nav: 'สร้าง Star Card', title: 'เห็น Star Card ของคนอื่น อยากมีบ้าง',
    line: 'เปิดการ์ดก็ต้องเป็น STAR ก่อน: 8 ข้อเดียวกัน → เป็น STAR → เลือก Template ได้การ์ด · ที่เหลือกรอกเมื่อถึงเวลา',
    state: 'j3-end.json',
    steps: [
      shot('x-export-card', 'Star Card ที่คนอื่นแชร์ สแกน QR หรือกดลิงก์', { wide: true, tag: 'ทางเข้ายังไม่ได้สร้าง' }),
      arrow(),
      stub('เข้าแอป', ['มีแอปแล้ว: เปิดได้เลย', 'ยังไม่มี: โหลดแอป แล้วล็อกอิน'], null),
      arrow(),
      shot('j2-01-starprofile-new', 'Star Profile กดเปิดใช้งานการ์ด'),
      arrow(),
      // 6 ต.ค. 2569 (เย็น): ทางลัด 3 ข้อให้การ์ดเกิดถูกตัด — ก่อนเป็น STAR ทุกทางถาม 8 ข้อเดียวกัน (ภาพชุดเดียวกับ Journey 1)
      group('ถาม 8 ข้อ', [
        tile('j1-04-kind', 'ประเภทครีเอเตอร์', ['kind']),
        tile('j1-05-channels', 'ช่องทางของฉัน + เรท', ['socials', 'rate']),
        tile('j1-06-categories', 'สายที่ใช่', ['categories']),
        tile('j1-07-media-top', 'เกี่ยวกับคุณ', ['media']),
        tile('j1-08-province', 'พื้นที่รับงาน', ['province']),
        tile('j1-09-availability', 'วันเวลาว่างรับงาน', ['availability']),
        tile('j1-09b-contact', 'ช่องทางติดต่อ', ['contact']),
        tile('j1-10-kyc', 'ยืนยันตัวตน', ['kyc']),
      ], 'แบรนด์ใช้คัดเลือก Star · ชุดเดียวกับ Journey 1'),
      arrow('ครบ 8 ข้อ'),
      shot('j2-13-star', 'เป็น STAR แล้ว'),
      arrow(),
      shot('j3-04b-templates', 'ยังไม่เคยมีการ์ด เลือก Template'),
      arrow(),
      shot('j3-05-editor', 'การ์ดเปิดในห้องแต่ง', { goal: 'ได้ Star Card' }),
      arrow(),
      shot('j3-09-share', 'แชร์การ์ด'),
    ],
    later: [
      { when: 'ตอนลงทะเบียนงาน (ฟอร์มสมัคร)', keys: ['address'] },
      { when: 'ฟอร์มรับเงิน (มีอยู่แล้ว)', keys: ['bank'] },
      { when: 'เข้ามากรอกเองใน Star Profile · widget ที่ต้องใช้ล็อกไว้', keys: ['body', 'insight', 'about'] },
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
  if (all !== [...ALL].sort().join()) fail(`${j.id}: ได้ + ยังไม่ถาม ไม่ครบ ${ALL.length} หัวข้อ (${got.length} + ${later.length})`)
  // state จริงจาก Simulator: have + ยืนยันตัวตน
  const st = JSON.parse(readFileSync(join(here, 'state', j.state), 'utf8'))
  const real = new Set(st.have)
  if (st.verify === 'approved') real.add('kyc')
  if ([...real].sort().join() !== [...got].sort().join()) fail(`${j.id}: ไม่ตรงกับ state จริง\n  หน้า : ${[...got].sort()}\n  แอป : ${[...real].sort()}`)
  j.got = got
  console.log(`✓ ${j.id}: ได้ ${got.length} · ยังไม่ถาม ${later.length} · ตรงกับ state จริง`)
}
// ───────── ศูนย์กลาง (ตอนปิดท้าย): ทางเข้า 3 ทาง → Star Profile ที่เดียว ─────────
// 1 ข้อ = 1 หน้าคำถาม · ชุดเต็ม = 11 ข้อของ journey 2 (8 ข้อ + ต่ออีก 3) · ทางเข้าแต่ละทาง = ทุกกล่องคำถามของ journey นั้น
const firstAsk = (j) => j.steps.filter((s) => s.type === 'group').flatMap((s) => s.tiles.map((t) => t.label))
const PAGES = firstAsk(journeys[1])
for (const j of journeys) for (const l of firstAsk(j)) if (!PAGES.includes(l)) fail(`${j.id}: ข้อ "${l}" ไม่อยู่ในชุด ${PAGES.length} ข้อ`)

// จอ Star Profile จริงตามสถานะ: ถ่ายจากต้นแบบ iOS ด้วย state ที่มีครบเท่ากับข้อที่ทางเข้านั้นถาม (shots/hub-<จำนวนข้อ>.jpg)
// 0 = ยังไม่เป็น STAR (8 ข้อ + %) · 8 = เป็น STAR แล้ว การ์ดทองครบ + การ์ดเทา "ใช้ให้แบรนด์คัดเลือก" ยังขาด · 11 = ครบทุกอย่าง
const doorSets = journeys.map((j) => firstAsk(j).map((l) => PAGES.indexOf(l)))
const HUB_COUNTS = [...new Set([0, 1, 2, 3, 4, 5, 6, 7].map((m) => new Set(doorSets.filter((_, i) => m >> i & 1).flat()).size))].sort((a, b) => a - b)
for (const n of HUB_COUNTS) need(`hub-${n}`)

for (const img of ['o-11-gate1', 'o-12-steps', 'o-13-step1', 'o-14-gate2.png', 'o-15-hub']) need(img)

// ───────── Insight (4 ต.ค. 2569): มีการ์ดแล้ว รู้ว่าใครมาดู — หัวข้อเพิ่มท้ายหน้า ไม่แตะ flow ข้างบน ─────────
// ทางเข้า 2 ทาง (แจ้งเตือน · ปุ่มยอดวิวใน Star Profile) → หน้า Star Insight หน้าเดียว 3 เรื่อง
// ภาพแจ้งเตือน = mock/noti-lockscreen.html ถ่ายเป็นภาพ (ยังไม่ได้สร้างในแอป) · หน้า Insight อยู่ในต้นแบบ iOS แล้ว ตัวเลขเป็นข้อมูลจำลอง
const insight = {
  id: 'insight', nav: 'ใครมาดูการ์ด', title: 'มีการ์ดแล้ว อยากรู้ว่าใครมาดู',
  line: 'มีแบรนด์มาดู แอปแจ้งเตือนเรียกกลับมา · เปิดมาเห็น 3 เรื่องในหน้าเดียว',
  steps: [
    shot('in-01-noti', 'แบรนด์มาดู แอปแจ้งเตือน', { tag: 'ยังไม่ได้สร้าง' }),
    or('หรือ'),
    shot('in-02-profile', 'กดปุ่มยอดวิวใน Star Profile'),
    arrow('แตะ'),
    shot('in-03-insight', 'Star Insight หน้าเดียว 3 เรื่อง', { goal: 'รู้ว่าใครมาดู' }),
    arrow(),
    stub('ทำต่อจากหน้านี้', ['แต่งการ์ดให้ตรงสายที่แบรนด์ดู', 'แชร์การ์ดเพิ่มยอดวิว'], null),
  ],
  sees: ['ยอดวิว', 'กดเข้ามาดูการ์ด', 'แบรนด์สายไหน'],
  noti: ['บอกจำนวน + สาย', 'รวมรอบเดียวตอนเย็น', 'ไม่เกินวันละครั้ง'],
  todo: ['ระบบนับยอดวิว', 'ส่งแจ้งเตือนจริง'],
}
for (const s of insight.steps) if (s.type === 'shot') need(s.img)

// ───────── ยืนยันตัวตน (6 ต.ค. 2569): ต้องผ่านก่อนส่งใบสมัคร — เพิ่มทาง "รอตรวจ" กับ "ตีกลับ" ต่อจากทาง "ผ่านทันที" ที่อยู่ใน journey 1 แล้ว ─────────
// ผ่านทันที = OCR อ่านได้ (เคสส่วนใหญ่) · รอตรวจ = AI อ่านไม่ผ่านจนตกไปกรอกมือ ส่ง staff · ตีกลับ = staff กดไม่ผ่านพร้อมเหตุผล (ส่งใหม่ได้ทันที)
// กติกา "ต้องผ่านก่อน" = ของแอปหลักอยู่แล้ว (CheckTypeUserViewController:44 ติ๊ก welcome step 3 เฉพาะ approved) — เดิม prototype ผ่อนให้สมัครระหว่างรอ
// ที่มา: salehere-ios VerifyUserStatusFormViewController · notification-service user-verify.controller.ts (push approve/reject) · user-verify.repository.js (resubmit ได้ทันที)
const kyc = {
  id: 'kyc', nav: 'รอตรวจ / ตีกลับ', title: 'ยืนยันตัวตนไม่ผ่านทันที: รอตรวจ หรือ ตีกลับ',
  line: 'ต้องผ่านก่อนส่งใบสมัคร · คำตอบที่กรอกไว้ยังอยู่ครบ · ผ่านแล้วแจ้งเตือนพากลับมาสมัครต่อ',
  steps: [
    // 6 ต.ค. 2569 บ่าย: หน้ายืนยันตัวตน = UI ของ salehere-ios ยกมาทั้งชุด ("ไปเอาของ salehere-ios มาเลย ไม่ต้องทำใหม่")
    group('หน้าเดิมของแอปหลัก', [
      tile('ky-10-type', 'เลือกเอกสาร', []),
      tile('ky-11-instruction', 'วิธีการถ่ายรูป', []),
      tile('ky-12-camera-preview', 'กล้อง ยืนยันข้อมูล', []),
    ], 'เลือกเอกสาร · วิธีถ่าย · กล้องบัตร · วิธีถ่ายรูปคู่ · กล้อง · ฟอร์ม'),
    arrow('OCR อ่านไม่ผ่าน'),
    shot('ky-13-ocr-error', 'modal เตือนเดิม ลองใหม่อีกครั้ง'),
    arrow('ครั้งที่ 3'),
    shot('ky-14-prompt-manual', 'ฟอร์มเติมจาก OCR กดส่งเอง prompt เดิม มีคำเตือนแดง'),
    arrow(),
    shot('ky-15-sent', 'ส่งคำขอยืนยันตัวตนสำเร็จ รอการอนุมัติ (แอปหลักเขียน 7 วันทำการ)'),
    arrow(),
    shot('ky-01-campaign-wait', 'หน้ากิจกรรมเดิม ปุ่มลงทะเบียนเหมือนเดิม ไม่แก้'),
    arrow('แตะ'),
    shot('ky-02-status-wait', 'หน้าสถานะโครงเดียวกับ wizard หัวข้อ ชิป ภาพ ปุ่ม ยกเลิกคำขอได้'),
    or('ระหว่างรอ'),
    shot('ky-08-profile-wait', 'ขั้นยืนยันตัวตนใน Star Profile ก็ UI เดียวกัน'),
    arrow('staff กดผล'),
    shot('ky-03-push-ok', 'ผ่าน แจ้งเตือน แตะแล้วเปิดฟอร์มสมัครใบที่ค้างไว้', { goal: 'สมัครต่อได้' }),
    or('หรือ'),
    shot('ky-04-push-reject', 'ไม่ผ่าน แจ้งเตือนพร้อมเหตุผลจาก staff'),
    arrow('แตะ'),
    shot('ky-05-status-reject', 'หน้าสถานะเดียวกัน เหตุผลจาก staff ปุ่มเดียว ส่งใหม่'),
    arrow(),
    shot('ky-06-reject-form', 'ฟอร์มเดิมของแอปหลัก การ์ดสถานะแดง เหตุผล ถ่ายใหม่หรือส่งเลย'),
    arrow('ถ่ายใหม่ OCR ผ่าน'),
    group('จบแบบผ่านทันที', [
      tile('ky-16-prompt-auto', 'ยืนยันข้อมูลจาก OCR', []),
      tile('ky-17-success-auto', 'ยืนยันตัวตนเสร็จสมบูรณ์', []),
    ], 'เคสส่วนใหญ่ ไม่ต้องรอ'),
  ],
  rules: ['ต้องผ่านก่อนสมัคร', 'แจ้งผล 3 วันทำการ', 'ส่งใหม่ได้ทันที', 'ยกเลิกคำขอได้เฉพาะตอนรอ · แตะ 2 ครั้ง', 'หน้าสถานะเฉพาะตอนเหลือแค่ข้อนี้'],
  api: ['push approve / reject เดิม', 'เหตุผล UserVerify.reason เดิม', 'ด่านเช็กฝั่ง client'],
  todo: ['preset เหตุผลตีกลับให้ staff', 'คิวด่วน คนมีงานค้างสมัคร', 'เลขวันรอให้ตรงกัน (7 vs 1–3)'],
}
for (const s of kyc.steps) { if (s.type === 'shot') need(s.img); if (s.type === 'group') for (const t of s.tiles) need(t.img) }

// ───────── ชวนสมัครเป็น STAR (6 ต.ค. 2569): banner แทน "ทำโปรไฟล์ให้สมบูรณ์กันเถอะ" ─────────
// ของเดิม (salehere-ios WelcomeOnboardingSectionView) ชวนไป "กรอกให้ครบ" + sheet 3 ขั้น · ใหม่ชวน "เป็น STAR" แล้วถามข้อแรกทันที
// 7 ต.ค. 2569 (ผู้ใช้): เช็คแค่ 8 ข้อ · % เฉพาะตอนทำ STAR (วงทองรอบรูป + ป้าย %) · เป็น STAR แล้วหายไปเลย · สูงเท่ากันทุกสถานะ (fixed height)
// ภาพจาก web flow (`desktop/` พอร์ต 8796) ขนาดมือถือ 393×852 @3x — แคปผ่าน iframe 393px + `?seed=` (สคริปต์ใน scratchpad ของ session) · แคนวาส: https://claude.ai/artifact/EqkgAb2jepd8wWApV4v9fh
const invite = {
  id: 'invite', nav: 'ชวนสมัครเป็น STAR', title: 'ชวนด้วยสถานะ "เป็น STAR" ไม่ใช่ "กรอกให้ครบ"',
  line: 'banner ใบเดียว สูงเท่ากันทุกสถานะ · % ทางไปเป็น STAR · แตะแล้วถามเฉพาะข้อที่ขาด · STAR ครบ 8 ข้อ = banner หายเลย · STAR เก่าที่ยังไม่ครบ = เติมข้อมูล STAR',
  steps: [
    shot('inv-01-home-s0', 'หน้าแรก ยังไม่เป็น STAR: วงทองรอบรูป + 63% อีก 3 ข้อ'),
    arrow('แตะ'),
    shot('inv-02-wizard-s0', 'ถามเฉพาะข้อที่ขาดใน 8 ข้อ (1/3) ไม่มีหน้ารายการขั้น'),
    arrow('ครบ 8 ข้อ'),
    shot('inv-03-home-star', 'เป็น STAR แล้ว banner หายไปเลย', { goal: 'ไม่มี banner' }),
    or('เหลือแค่ยืนยันตัวตน รอตรวจ'),
    shot('inv-05-home-wait', 'ใบเดิม ขนาดเดิม · ป้ายนาฬิกาที่รูป · 88%'),
    arrow('แตะ'),
    shot('inv-06-wait-status', 'หน้าสถานะยืนยันตัวตน รอผล'),
    or('ไม่ผ่าน'),
    shot('inv-07-home-reject', 'ใบเดิม ขนาดเดิม · ป้าย ! แดงที่รูป สีแดงที่เดียว'),
    arrow('แตะ'),
    shot('inv-08-kyc', 'หน้าสถานะ ไม่ผ่าน บอกเหตุผล + ส่งใหม่', { goal: 'ส่งใหม่' }),
    or('หน้าโปรไฟล์'),
    shot('inv-09-profile-s0', 'ใบเดียวกันเหนือช่องโพสต์ แทนที่ของเดิม'),
    or('STAR เก่า ข้อมูลยังไม่ครบ'),
    shot('inv-10-home-c', 'เติมข้อมูล STAR · ขาด 5 ข้อ วงทองเต็ม ไม่มี %'),
    arrow('แตะรูปโปรไฟล์ครีเอเตอร์'),
    shot('inv-11-profile-c', 'เป็น STAR ทุกที่ การ์ดทองกางให้ ข้อที่ขาดมีปุ่มเพิ่ม'),
    or('กดสมัครกิจกรรม'),
    shot('inv-12-intro-c', 'บังคับเติมก่อน แบรนด์ขอข้อมูลเพิ่ม · เติมข้อมูล 5 ข้อ', { goal: 'ครบแล้วไปฟอร์มสมัคร' }),
  ],
  rules: ['สูงเท่ากันทุกสถานะ', 'ปุ่มวงกลมลูกศร ไม่มีข้อความ', 'เช็คแค่ 8 ข้อ', '% เฉพาะก่อนเป็น STAR', 'STAR ครบ = หายเลย', 'รอตรวจ/ไม่ผ่าน เฉพาะตอนเหลือแค่ยืนยันตัวตน'],
  reuse: ['หน้าสถานะยืนยันตัวตน', 'ยศ STAR (userRank) เดิม', 'สถานะ InProgress / WaitingVerify / RejectVerify เดิม'],
  todo: ['backend ให้ยศเมื่อครบ 8 ข้อ (ตอนนี้ให้ที่ 3 ขั้นเดิม)', 'starPercent จาก server'],
}
for (const s of invite.steps) if (s.type === 'shot') need(s.img)
// สรุป: banner มี 4 สถานะ สูงเท่ากันทุกใบ (ครอปจากหน้าแรกของต้นแบบ iOS) · STAR ครบ 8 ข้อ = ไม่มี banner
// A = ยังไม่เป็น STAR (% ทางไปเป็น STAR · KYC รอผล = 7/8 = 88%) · C = STAR เก่า (มียศ) ที่ 8 ข้อยังไม่ครบ — ไม่มี % บอกจำนวนข้อที่ขาด
invite.states = [
  { img: 'ban-s0', n: 'A', t: 'ยังไม่เป็น STAR · 63%', tap: 'แตะ → ถามเฉพาะข้อที่ขาดใน 8 ข้อ แล้วเปิด Star Profile', old: 'InProgress' },
  { img: 'ban-s0-wait', n: 'A', t: 'เหลือแค่ยืนยันตัวตน รอตรวจ · 88%', tap: 'แตะ → หน้าสถานะ "ทีมงานกำลังตรวจเอกสาร"', old: 'WaitingVerify' },
  { img: 'ban-s0-reject', n: 'A', t: 'เหลือแค่ยืนยันตัวตน ไม่ผ่าน · 88%', tap: 'แตะ → หน้าสถานะ บอกเหตุผล ส่งใหม่', old: 'RejectVerify' },
  { img: 'ban-c', n: 'C', t: 'STAR เก่า ข้อมูลยังไม่ครบ · ขาด 5 ข้อ', tap: 'แตะ → ถามเฉพาะข้อที่ขาดใน 8 ข้อ แล้วเปิด Star Profile', old: 'ไม่มี (ใหม่)' },
]
for (const st of invite.states) need(st.img)
const orphan =readdirSync(join(here, 'shots')).filter((f) => /\.(jpg|png)$/.test(f) && !used.has(f))
if (orphan.length) console.log('· ภาพที่ไม่ได้ใช้: ' + orphan.join(', '))

// ───────── render ─────────
const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;')
const img = (name, alt, cls = '') => `<img${cls ? ` class="${cls}"` : ''} src="shots/${file(name)}" alt="${esc(alt)}">`
const plus = (keys) => keys?.length ? `<span class="plus">${keys.map((k) => `<i>+ ${T[k]}</i>`).join('')}</span>` : ''

function step(s) {
  if (s.type === 'or') return `<div class="or" aria-hidden="true"><span>${esc(s.note)}</span></div>`
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

const insightLane = (x) => `<section class="lane" id="${x.id}">
  <header class="lane-h">
    <span class="num" aria-hidden="true"><svg width="26" height="26" viewBox="0 0 256 256" fill="none" stroke="currentColor" stroke-width="22" stroke-linecap="round" stroke-linejoin="round"><polyline points="224 208 32 208 32 48"/><polyline points="224 96 160 152 96 104 32 160"/></svg></span>
    <div><h2>${esc(x.title)}</h2><p>${esc(x.line)}</p></div>
    <div class="nudge"><button type="button" data-dir="-1" aria-label="เลื่อนกลับ">‹</button><button type="button" data-dir="1" aria-label="เลื่อนไปขั้นถัดไป">›</button></div>
  </header>
  <div class="strip" tabindex="0" role="group" aria-label="${esc(x.title)} เลื่อนไปทางขวาเพื่อดูขั้นถัดไป">
    <div class="track">${x.steps.map(step).join('')}<aside class="end">
  <h4>หน้าเดียว 3 เรื่อง</h4>
  <p class="k">เจ้าของการ์ดเห็น</p>
  <div class="chips">${x.sees.map((t) => `<i class="have">${esc(t)}</i>`).join('')}</div>
  <p class="k">แจ้งเตือน</p>
  ${reqChips(x.noti)}
  <p class="k">ยังไม่ได้สร้าง</p>
  <div class="chips">${x.todo.map((t) => `<i class="miss">${esc(t)}</i>`).join('')}</div>
  <p class="k">ตัวเลขในภาพเป็นข้อมูลจำลอง</p>
</aside></div>
  </div>
</section>`

const kycLane = (x) => `<section class="lane" id="${x.id}">
  <header class="lane-h">
    <span class="num" aria-hidden="true"><svg width="26" height="26" viewBox="0 0 256 256" fill="none" stroke="currentColor" stroke-width="22" stroke-linecap="round" stroke-linejoin="round"><rect x="32" y="48" width="192" height="160" rx="12"/><circle cx="96" cy="128" r="24"/><path d="M60 180a40 40 0 0 1 72 0"/><line x1="152" y1="112" x2="192" y2="112"/><line x1="152" y1="144" x2="192" y2="144"/></svg></span>
    <div><h2>${esc(x.title)}</h2><p>${esc(x.line)}</p></div>
    <div class="nudge"><button type="button" data-dir="-1" aria-label="เลื่อนกลับ">‹</button><button type="button" data-dir="1" aria-label="เลื่อนไปขั้นถัดไป">›</button></div>
  </header>
  <div class="strip" tabindex="0" role="group" aria-label="${esc(x.title)} เลื่อนไปทางขวาเพื่อดูขั้นถัดไป">
    <div class="track">${x.steps.map(step).join('')}<aside class="end">
  <h4>กติกา</h4>
  ${reqChips(x.rules)}
  <p class="k">ใช้ของเดิม ไม่แก้ API</p>
  <div class="chips">${x.api.map((t) => `<i class="have">${esc(t)}</i>`).join('')}</div>
  <p class="k">ยังไม่ได้สร้าง / ต้องตกลง</p>
  <div class="chips">${x.todo.map((t) => `<i class="miss">${esc(t)}</i>`).join('')}</div>
  <p class="k">ภาพจากต้นแบบ iOS สลับผลด้วย Lab</p>
</aside></div>
  </div>
</section>`

const inviteLane = (x) => `<section class="lane" id="${x.id}">
  <header class="lane-h">
    <span class="num" aria-hidden="true"><svg width="26" height="26" viewBox="0 0 256 256" fill="none" stroke="currentColor" stroke-width="22" stroke-linecap="round" stroke-linejoin="round"><path d="M128 28l30 61 67 10-48 47 11 67-60-32-60 32 11-67-48-47 67-10z"/></svg></span>
    <div><h2>${esc(x.title)}</h2><p>${esc(x.line)}</p></div>
    <div class="nudge"><button type="button" data-dir="-1" aria-label="เลื่อนกลับ">‹</button><button type="button" data-dir="1" aria-label="เลื่อนไปขั้นถัดไป">›</button></div>
  </header>
  <div class="states wrap" role="list" aria-label="สถานะของ banner">
    <div class="states-h"><b>banner มี ${x.states.length} สถานะ</b><span>ใบเดียว สูงเท่ากันทุกใบ · วงทอง + ป้าย % = ทางไปเป็น STAR · STAR เก่าที่ยังไม่ครบ = "ขาด N ข้อ" แทน % · ครบ 8 ข้อ = ไม่มี banner แม้ข้อมูลอื่นยังไม่ครบ</span></div>
    <div class="states-g">${x.states.map((st) => `<figure class="state" role="listitem">${img(st.img, `${st.n} ${st.t}`)}<figcaption><b><i>${esc(st.n)}</i>${esc(st.t)}</b><span>${esc(st.tap)}</span><small>เดิม: ${esc(st.old)}</small></figcaption></figure>`).join('')}</div>
  </div>
  <div class="strip" tabindex="0" role="group" aria-label="${esc(x.title)} เลื่อนไปทางขวาเพื่อดูขั้นถัดไป">
    <div class="track">${x.steps.map(step).join('')}<aside class="end">
  <h4>กติกา</h4>
  ${reqChips(x.rules)}
  <p class="k">ใช้ของเดิม ไม่ออกแบบใหม่</p>
  <div class="chips">${x.reuse.map((t) => `<i class="have">${esc(t)}</i>`).join('')}</div>
  <p class="k">ยังไม่ได้สร้าง</p>
  <div class="chips">${x.todo.map((t) => `<i class="miss">${esc(t)}</i>`).join('')}</div>
  <p class="k">% เฉพาะก่อนเป็น STAR (เลขเดียวกับหน้า Star Profile) · STAR เก่าเห็น "ขาด N ข้อ" · ภาพจากต้นแบบ iOS</p>
</aside></div>
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
// ช่องแรกของตารางเทียบ = ชื่อ journey ตามที่ผู้ใช้เรียก (เลขตรงกับแถบ journey ด้านล่าง) + โน้ตว่าคนกลุ่มนี้เข้ามาแบบไหน
const jCell = (i) => `<td><b class="jn">${journeys[i].n}</b>${esc(journeys[i].want)}${reqChips(journeys[i].notes)}</td>`
const oldCell = `<td class="old">${OLD_STEPS + OLD_PARTS} ขั้น<small>${OLD_STEPS} ขั้น + โปรไฟล์ 100% อีก ${OLD_PARTS} ขั้น</small></td>`

const body = `<title>Star Profile Journeys</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Anuphan:wght@400;500;600;700&family=Instrument+Serif:ital@1&display=swap">
<style>
/* แถบภาพจอเรียงแนวนอนหนึ่งแถบต่อหนึ่ง journey · ตัวหนังสือเป็นแค่ป้ายกำกับ ภาพกับลูกศรเล่าเรื่อง */
:root{
  --bg:#F5F6F8; --surface:#FFFFFF; --ink:#1C1E24; --muted:#666D7A; --line:#E2E5EB; --soft:#ECEEF2;
  --red:#E11B22; --ok:#0B8F62; --on-ok:#FFFFFF; --ok-soft:#E2F5EC; --warn:#8A5200; --warn-soft:#FFEFD0;
  --shadow:0 1px 2px rgba(22,24,30,.06),0 12px 30px rgba(22,24,30,.10);
  --sans:"Anuphan","Noto Sans Thai","Thonburi",system-ui,sans-serif;
  --serif:"Instrument Serif","Didot",Georgia,serif;
}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){
  --bg:#101115; --surface:#191B21; --ink:#F0F1F3; --muted:#99A0AC; --line:#2A2D36; --soft:#20232A;
  --red:#FF5C62; --ok:#3ED6A0; --on-ok:#06231A; --ok-soft:#12301F; --warn:#F3B84C; --warn-soft:#37290E;
  --shadow:0 1px 2px rgba(0,0,0,.4),0 12px 30px rgba(0,0,0,.5); color-scheme:dark}}
:root[data-theme="dark"]{
  --bg:#101115; --surface:#191B21; --ink:#F0F1F3; --muted:#99A0AC; --line:#2A2D36; --soft:#20232A;
  --red:#FF5C62; --ok:#3ED6A0; --on-ok:#06231A; --ok-soft:#12301F; --warn:#F3B84C; --warn-soft:#37290E;
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

/* สรุปสถานะ banner (ตอน ชวนสมัครเป็น STAR) */
.states{margin-top:22px}
.states-h{display:flex;flex-wrap:wrap;align-items:baseline;gap:4px 12px;margin-bottom:12px}
.states-h b{font-size:17px;font-weight:700}
.states-h span{font-size:14px;color:var(--muted)}
.states-g{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,270px),1fr));gap:14px}
.state{background:var(--surface);border:1px solid var(--line);border-radius:18px;padding:12px;display:flex;flex-direction:column;gap:10px}
.state img{display:block;width:100%;height:auto;border-radius:12px;border:1px solid var(--line);background:#fff;cursor:zoom-in}
.state figcaption{margin:0;gap:3px}
.state figcaption b{display:flex;align-items:center;gap:8px;font-size:14.5px}
.state figcaption b i{font-size:11.5px;font-weight:700;color:var(--red);border:1.4px solid currentColor;border-radius:999px;padding:0 7px;line-height:18px}
.state figcaption span{font-size:13px;color:var(--ink)}
.state figcaption small{font-size:12px;color:var(--muted)}

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
/* "หรือ" คั่นทางเข้าสองทางที่ไปหน้าเดียวกัน — ไม่มีหัวลูกศร */
.or{flex:none;width:64px;height:454px;position:relative}
.or::before{content:"";position:absolute;left:50%;top:22%;bottom:22%;border-left:1.5px dashed var(--line)}
.or span{position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);font-size:12px;font-weight:600;color:var(--muted);background:var(--bg);border:1px solid var(--line);padding:3px 9px;border-radius:999px;white-space:nowrap}
.lane-h .num svg{display:block}

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

/* ภาพขยาย · ตารางเทียบ (อยู่ต่อจาก Flow เก่า ก่อนเข้า journey) */
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
.cmp td:first-child .chips{margin-top:7px;padding-left:calc(1ch + 8px)}
.cmp td:first-child .chips i{font-weight:500}
.cmp td .why{font-weight:400;margin-left:.3em}
.cmp .jn{color:var(--red);font-weight:700;margin-right:8px}
.cmp-note{font-size:13px;color:var(--muted);margin-top:10px}
.tablebox{overflow-x:auto}
/* ศูนย์กลาง (ตอนปิดท้าย): ทางเข้า 3 ทางอยู่ซ้าย ลูกศรทุกเส้นชี้เข้า Star Profile กล่องเดียว */
#hub{border-top:1px solid var(--line);margin-top:44px}
.hub{display:grid;grid-template-columns:minmax(230px,300px) minmax(0,1fr);gap:56px;align-items:stretch}
.doors{display:grid;gap:12px;align-content:center}
.door{position:relative;display:grid;grid-template-columns:auto minmax(0,1fr);column-gap:12px;row-gap:1px;align-content:center;text-align:left;font:inherit;color:var(--ink);background:var(--surface);border:1px solid var(--line);border-radius:18px;padding:14px 16px;cursor:pointer}
.door:hover{border-color:var(--muted)}
.door:focus-visible{outline:2px solid var(--red);outline-offset:2px}
.door .jn{grid-row:span 2;align-self:center;color:var(--red);font-size:22px;font-weight:700}
.door .dn{font-size:16px;font-weight:700}
.door .ask{font-size:14px;color:var(--muted)}
.door .ask b{color:var(--ink);font-size:17px;font-variant-numeric:tabular-nums}
.door .ask em{color:var(--ok);font-weight:600}
.door .bar{grid-column:2;height:4px;margin-top:8px;border-radius:999px;background:var(--soft);overflow:hidden}
.door .bar i{display:block;width:0;height:100%;border-radius:inherit;background:var(--ok);transition:width .35s ease}
.door::before{content:"";position:absolute;left:calc(100% + 8px);top:50%;width:38px;height:2px;background:var(--muted);border-radius:2px;opacity:.55}
.door::after{content:"";position:absolute;left:calc(100% + 37px);top:50%;width:8px;height:8px;border-top:2px solid var(--muted);border-right:2px solid var(--muted);transform:translateY(-3px) rotate(45deg);opacity:.75}
.door.lit{border-color:var(--ok)}
.door.lit::before{background:var(--ok);opacity:1}
.door.lit::after{border-color:var(--ok);opacity:1}
.door.done{cursor:default}
.core{position:relative;display:grid;grid-template-columns:auto minmax(0,1fr);gap:26px;background:var(--surface);border:1.5px solid var(--ink);border-radius:24px;padding:22px;box-shadow:var(--shadow)}
.core-main{display:flex;flex-direction:column;gap:16px;min-width:0}
.core-shot{width:200px}
.screens{position:relative;aspect-ratio:1206/2622;border-radius:24px;border:1px solid var(--line);background:var(--soft);box-shadow:var(--shadow);overflow:hidden}
.screens img{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;object-position:top;opacity:0;pointer-events:none;transition:opacity .35s ease}
.screens img.on{opacity:1;pointer-events:auto;cursor:zoom-in}
.core-shot figcaption{align-items:center;margin-top:9px;font-size:12.5px;font-weight:600;color:var(--muted)}
.core-h{display:flex;flex-wrap:wrap;align-items:baseline;justify-content:space-between;gap:6px 16px}
.core-h h3{font-size:28px;font-weight:700;line-height:1.1}
.core-h h3 span{font-family:var(--serif);font-style:italic;font-weight:400}
.count{font-size:14px;color:var(--muted)}
.count b{color:var(--ink);font-size:20px;font-variant-numeric:tabular-nums}
.core .chips{gap:8px}
.core .chips i{font-size:15px;padding:7px 15px}
.core .chips .miss{padding:6px 14px}
.chips .new{background:var(--ok);color:var(--on-ok)}
.uses{display:flex;flex-wrap:wrap;align-items:center;gap:6px;margin-top:auto;padding-top:14px;border-top:1px solid var(--line);font-size:13px;color:var(--muted)}
.uses span{margin-right:4px}
.uses i{font-size:12.5px;font-weight:600;padding:3px 10px;border-radius:999px;background:var(--soft);color:var(--ink);white-space:nowrap}
.hub-foot{display:flex;flex-wrap:wrap;align-items:center;gap:8px 14px;margin-top:16px;min-height:34px}
.hub-say{font-size:16px;font-weight:600}
.hub-reset{font:600 13px/1 var(--sans);color:var(--muted);background:none;border:1px solid var(--line);border-radius:999px;padding:7px 13px;cursor:pointer}
.hub-reset:hover{color:var(--ink);border-color:var(--muted)}
.hub-reset:focus-visible{outline:2px solid var(--red);outline-offset:2px}
@media (prefers-reduced-motion:no-preference){
  .chips .new{animation:hub-in .34s cubic-bezier(.2,.9,.3,1.3) backwards}
  @keyframes hub-in{from{transform:scale(.6);opacity:0}}
}
@media (max-width:760px){
  .hub{grid-template-columns:minmax(0,1fr);gap:38px}
  .door::before,.door::after{display:none}
  .core::before{content:"";position:absolute;left:50%;top:-30px;width:2px;height:20px;background:var(--muted);border-radius:2px;opacity:.55}
  .core::after{content:"";position:absolute;left:50%;top:-18px;width:8px;height:8px;border-bottom:2px solid var(--muted);border-right:2px solid var(--muted);transform:translateX(-3px) rotate(45deg);opacity:.75}
  .core{padding:18px;grid-template-columns:minmax(0,1fr);gap:20px}
  .core-shot{width:170px;justify-self:center}
}
footer{color:var(--muted);font-size:13px;padding-block:44px 56px}
footer .tag{margin-right:6px}

@media (max-width:640px){
  .nudge{display:none}
  .group.many .tiles{grid-template-columns:repeat(6,80px)}
  .group.many .tile,.group.many .tile img{width:80px}
  .wrap,.lane-h{padding-inline:16px}
  .track{padding-inline:16px}
  .shot{width:168px}.shot.wide{width:300px;padding-top:86px}
  .arrow,.or{height:366px}
  .group{margin-top:24px}.tile{width:96px}.tile img{width:96px}
  .stub{margin-top:110px;width:150px}
  .lane-h .num{width:42px;height:42px;font-size:21px;border-radius:13px}
  .cmp th,.cmp td{padding:11px 12px;font-size:14px}
  .cmp td:first-child{white-space:normal}
  .cmp td:first-child .chips{padding-left:0}
}
@media (prefers-reduced-motion:no-preference){html{scroll-behavior:smooth}}
</style>

<header class="top"><div class="wrap">
  <div class="eyebrow">Sale Here STAR</div>
  <h1>Star Profile <span>Journeys</span></h1>
  <p>ทุกทางถาม 8 ข้อที่แบรนด์ใช้คัดเลือกก่อน ครบ = เป็น STAR · ที่เหลือถามเมื่อถึงเวลา ไม่นับเป็น %</p>
</div></header>

<nav class="jump" aria-label="ไปยังตอน"><div class="wrap">
  <a href="#old">Flow เก่า</a>
  <a href="#cmp">เก่า vs ใหม่</a>
  ${journeys.map((j) => `<a href="#${j.id}"><b>${j.n}</b>${esc(j.nav)}</a>`).join('\n  ')}
  <a href="#${invite.id}">${esc(invite.nav)}</a>
  <a href="#hub">Star Profile ตรงกลาง</a>
  <a href="#${insight.id}">${esc(insight.nav)}</a>
  <a href="#${kyc.id}">${esc(kyc.nav)}</a>
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
  <div class="old-foot">รวม ${OLD_STEPS + OLD_PARTS} ขั้น ครบแล้วจึงเปิดฟอร์มสมัครได้ · ทางเข้าคือ banner "ทำโปรไฟล์ให้สมบูรณ์กันเถอะ" (ดูตอน ชวนสมัครเป็น STAR)</div>
</div></section>

<section id="cmp"><div class="wrap">
  <div class="sec-h"><h2>เป้าหมายเดียวกัน ต้องทำอะไรก่อน</h2></div>
  <div class="tablebox"><table class="cmp">
    <thead><tr><th>Journey</th><th>Flow เก่า</th><th>Flow ใหม่</th></tr></thead>
    <tbody>
      <tr>${jCell(0)}${oldCell}<td class="new">8 ข้อ<span class="why">ที่แบรนด์ใช้คัดเลือก Star</span><small>ที่อยู่กรอกในฟอร์มสมัครเหมือนเดิม · ยืนยันตัวตนต้องผ่านก่อนส่งใบสมัคร</small></td></tr>
      <tr>${jCell(1)}${oldCell}<td class="new">8 ข้อ → เป็น STAR → ต่ออีก 3<small>ชุดเดียวกับ Journey 1 แล้วถาม ที่อยู่ · บัญชี · สัดส่วน ต่อในรอบเดียว · ปิดกลางทางได้</small></td></tr>
      <tr>${jCell(2)}${oldCell}<td class="new">8 ข้อ<span class="why">เดียวกัน แล้วเลือก Template</span><small>ไม่มีทางลัด 3 ข้อแล้ว · widget ที่ใช้ข้อมูลไม่บังคับล็อกไว้ให้กรอกเมื่ออยากใช้</small></td></tr>
    </tbody>
  </table></div>
  <p class="cmp-note">1 ขั้น / 1 ข้อ = 1 หน้าที่ต้องเข้าไปกรอก</p>
</div></section>

${journeys.map(lane).join('\n')}

${inviteLane(invite)}

<section id="hub"><div class="wrap">
  <div class="sec-h"><h2>ทุกทางกรอกลงที่เดียว: Star Profile</h2><p>ตอบจากทางไหนก็มาอัปเดตที่นี่ · ข้อที่มีแล้วไม่ถามซ้ำ · ก่อนเป็น STAR หน้านี้โชว์แค่ 8 ข้อ ไม่มี %</p></div>
  <div class="hub">
    <div class="doors">
      ${journeys.map((j) => { const ask = firstAsk(j); return `<button type="button" class="door" data-n="${j.n}" data-pages="${ask.map((l) => PAGES.indexOf(l)).join()}"><b class="jn">${j.n}</b><span class="dn">${esc(j.nav)}</span><span class="ask">กรอกแล้ว <b>0</b> จาก ${ask.length} · เหลือ <b>${ask.length}</b> ข้อ</span><span class="bar"><i></i></span></button>` }).join('\n      ')}
    </div>
    <div class="core">
      <figure class="core-shot"><div class="screens">${HUB_COUNTS.map((n) => `<img${n === 0 ? ' class="on"' : ''} data-n="${n}" src="shots/hub-${n}.jpg" alt="หน้า Star Profile ในแอป ตอนมีข้อมูล ${n} ข้อ">`).join('')}</div><figcaption>หน้า Star Profile ในแอป</figcaption></figure>
      <div class="core-main">
      <div class="core-h"><h3>Star <span>Profile</span></h3><span class="count">มีแล้ว <b>0</b> จาก ${PAGES.length} ข้อ</span></div>
      <div class="chips">${PAGES.map((l) => `<i class="miss">${esc(l)}</i>`).join('')}</div>
      <div class="uses"><span>เติมให้เองที่</span><i>Star Card</i><i>ฟอร์มสมัครงาน</i><i>หน้าตอบรับ</i></div>
      </div>
    </div>
  </div>
  <div class="hub-foot"><p class="hub-say" aria-live="polite">กดทางเข้าทีละทาง ดูว่ากรอกไปเท่าไหร่ เหลือเท่าไหร่</p><button type="button" class="hub-reset" hidden>เริ่มใหม่</button></div>
</div></section>

${insightLane(insight)}

${kycLane(kyc)}
</main>

<dialog class="zoom" aria-label="ภาพขยาย"><img alt=""></dialog>
<footer><div class="wrap">
  <span class="tag">ยังไม่ได้สร้าง</span>= ขั้นที่ยังไม่มีในต้นแบบ · ภาพ Flow ใหม่จากต้นแบบ iOS · ภาพ Flow เก่าจากแอป Sale Here จริง · 6 ต.ค. 2569
</div></footer>
<script>
// เลื่อนแถบทีละช่วง + แตะภาพเพื่อดูใหญ่
document.querySelectorAll('.nudge button').forEach(function (b) {
  b.addEventListener('click', function () {
    var strip = b.closest('.lane').querySelector('.strip')
    strip.scrollBy({ left: Number(b.dataset.dir) * strip.clientWidth * 0.7, behavior: 'smooth' })
  })
})
// ศูนย์กลาง: กดทางเข้า → ข้อที่ยังไม่มีลง Star Profile · ทางอื่นเหลือถามน้อยลง
;(function () {
  var hub = document.querySelector('.hub')
  if (!hub) return
  var doors = [].slice.call(hub.querySelectorAll('.door'))
  var chips = [].slice.call(hub.querySelectorAll('.core .chips i'))
  var count = hub.querySelector('.count b')
  var screens = [].slice.call(hub.querySelectorAll('.screens img'))
  var say = document.querySelector('.hub-say'), reset = document.querySelector('.hub-reset')
  var idle = say.textContent, have = {}
  function pages(d) { return d.dataset.pages.split(',').map(Number) }
  function paint(fresh, from) {
    var n = 0
    chips.forEach(function (c, i) {
      var k = fresh ? fresh.indexOf(i) : -1
      c.className = have[i] ? (k >= 0 ? 'new' : 'have') : 'miss'
      c.style.animationDelay = k >= 0 ? k * 55 + 'ms' : ''
      if (have[i]) n++
    })
    count.textContent = n
    screens.forEach(function (im) { im.classList.toggle('on', Number(im.dataset.n) === n) })
    doors.forEach(function (d) {
      var all = pages(d), left = all.filter(function (i) { return !have[i] }).length
      var got = all.length - left
      d.querySelector('.ask').innerHTML = 'กรอกแล้ว <b>' + got + '</b> จาก ' + all.length + ' · ' + (left === 0 ? '<em>ไม่ถามแล้ว</em>' : 'เหลือ <b>' + left + '</b> ข้อ')
      d.querySelector('.bar i').style.width = got / all.length * 100 + '%'
      d.classList.toggle('done', left === 0)
      d.classList.toggle('lit', d === from)
      d.disabled = left === 0
    })
    reset.hidden = n === 0
  }
  doors.forEach(function (d) {
    d.addEventListener('click', function () {
      var all = pages(d), fresh = all.filter(function (i) { return !have[i] }), skip = all.length - fresh.length
      fresh.forEach(function (i) { have[i] = true })
      paint(fresh, d)
      say.textContent = 'Journey ' + d.dataset.n + ' ถาม ' + fresh.length + ' ข้อ' + (skip ? ' · ข้าม ' + skip + ' ข้อที่ตอบแล้ว' : '') + ' · ลงที่ Star Profile'
    })
  })
  reset.addEventListener('click', function () { have = {}; paint(null, null); say.textContent = idle })
})()
var zoom = document.querySelector('dialog.zoom')
document.addEventListener('click', function (e) {
  if (zoom.open) { zoom.close(); return }
  var im = e.target.closest('.shot img, .tile img, .pics img, .screens img.on, .state img')
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
