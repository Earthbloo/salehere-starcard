// ผังแนวนอนของ scrapKeyTab (box สูง 310 เสมอ · กว้าง ~465–1000+ ตามสัดส่วนกรอบ)
// ทุกแบบใช้ห่วงกุญแจซ้าย + ป้ายกินที่ที่เหลือ (row) แทน "84%" ของเดิม — ป้ายจึงไม่เหลือขอบขวาเพี้ยนเมื่อกรอบยาวขึ้น

const ring = { type: 'rect', id: 'ring', w: 41, h: 41, circle: true, stroke: { color: '#C3C7CF', width: 2.6 }, place: 'center-left' }
const stem = { type: 'rect', id: 'stem', w: 26, h: 10, radius: 5, stroke: { color: '#AEB3BC', width: 2.2 }, place: 'center-left', dx: 39.5 }
const keyring = { type: 'stack', id: 'keyring', w: 66, h: 44, children: [ring, stem] }
const hole = { type: 'rect', id: 'hole', w: 22, h: 22, circle: true, fill: 'black@0.14', shadow: { sigma: 0.5, y: 1.7, color: 'black@0.3' }, place: 'center-left', dx: 14 }
const tabShadow = { sigma: 7, y: 14, color: 'black@0.24' }
const label = (extra = {}) => ({ type: 'text', text: 'ผู้ติดตาม', face: 'mitr', weight: 400, size: 15.5, color: '#141414@0.5', maxLines: 1, readonly: true, ...extra })
const tile = (sz, r, icon) => ({ type: 'stack', w: sz, h: sz, fill: 'white', radius: r, shadow: { sigma: 0, y: 3.4, color: 'black@0.18' }, children: [{ type: 'icon', icon: '$icon', size: icon, place: 'center' }] })
const num = (size, extra = {}) => ({ type: 'text', slot: '$followers', face: 'noto', weight: 800, size, color: '#141414', maxLines: 1, shrinkTo: Math.round(size * 0.55), ...extra })

/** ห่วงซ้าย + ป้าย (stack) ที่กินที่ที่เหลือ */
const keyTab = (tabExtra, children) => ({
  type: 'row', align: 'center', pad: [0, 22, 14, 19],
  children: [keyring, { type: 'stack', id: 'tab', grow: 1, h: '78%', fill: 'bg2', radius: 24, shadow: tabShadow, ...tabExtra, children }],
})

export const VARIANTS = [
  { id: 'current', name: 'ปัจจุบัน', from: 'ผังเดิม (แถวเดียว ไอคอน+ตัวเลขข้างกัน)' },

  // A — คอลัมน์เท่ากัน: ไอคอนบน ตัวเลขล่าง · ทุกช่องกว้างเท่ากัน (grow) → 1–6 ช่องทางเต็มป้ายพอดี
  {
    id: 'A', name: 'คอลัมน์เท่ากัน', from: 'iOS Batteries widget · ไอคอนบน ตัวเลขล่าง แบ่งเท่ากัน',
    root: keyTab({}, [
      hole,
      { type: 'col', pad: [20, 18, 34, 46], justify: 'center', children: [
        { type: 'chips', id: 'socials', list: 'socials', wrap: false, align: 'center', gap: 6,
          each: { type: 'col', grow: 1, gap: 10, align: 'center', children: [tile(80, 23, 50), num(33, { textAlign: 'center' })] } },
      ] },
      label({ textAlign: 'right', w: 120, place: 'bottom-right', dx: -18, dy: -12 }),
    ]),
  },

  // B — ยอดรวมเด่น: ตัวเลขรวมใหญ่ซ้าย + ไอคอนเล็กพร้อมยอดเรียงขวา
  {
    id: 'B', name: 'ยอดรวม + 3 อันดับ', from: 'Instagram Professional dashboard · ตัวเลขใหญ่หนึ่งตัวก่อน แล้ว 3 ช่องทางที่ยอดสูงสุด',
    root: keyTab({}, [
      hole,
      { type: 'row', pad: [22, 24, 22, 48], gap: 22, align: 'center', children: [
        { type: 'col', gap: 2, align: 'start', children: [
          { type: 'text', slot: 'stat:totalFollowers', face: 'noto', weight: 900, size: 72, color: '#141414', maxLines: 1, shrinkTo: 40, readonly: true },
          label({ size: 20 }),
        ] },
        { type: 'rect', w: 2.5, h: '70%', fill: 'white@0.6', radius: 2 },
        { type: 'chips', id: 'socials', list: 'socials', sort: 'followersRaw desc', limit: 3, wrap: false, grow: 1, gap: 8, align: 'center', justify: 'center',
          each: { type: 'col', grow: 1, maxW: 130, gap: 8, align: 'center', children: [tile(66, 19, 41), num(28, { textAlign: 'center', shrinkTo: 18 })] } },
      ] },
    ]),
  },

  // C — พวงหลายป้าย: ห่วงเดียว ราวโซ่ด้านบน แต่ละช่องทางเป็นป้ายห้อยของตัวเอง เอียงคนละนิด
  {
    id: 'C', name: 'พวงหลายป้าย', from: 'พวงกุญแจห้อยชาร์มหลายอัน · สแครปบุ๊ก',
    root: { type: 'stack', children: [
      { type: 'rect', id: 'chain', h: 5, radius: 3, fill: 'white@0.0', stroke: { color: '#AEB3BC', width: 2.4 }, place: 'top-left', dx: 52, dy: 50, w: 'fill' },
      { type: 'rect', id: 'ring', w: 46, h: 46, circle: true, stroke: { color: '#C3C7CF', width: 2.8 }, place: 'top-left', dx: 10, dy: 30 },
      { type: 'col', pad: [46, 20, 10, 64], children: [
        { type: 'chips', id: 'socials', list: 'socials', wrap: false, gap: 10, align: 'start', justify: 'around',
          each: { type: 'col', align: 'center', rotateCycle: [-5, 3.5, -2, 4.5, -3.5, 2], children: [
            { type: 'rect', w: 7, h: 22, radius: 3.5, stroke: { color: '#AEB3BC', width: 2 } },
            { type: 'stack', w: 118, h: 214, fill: 'bg2', radius: 20, shadow: { sigma: 5, y: 10, color: 'black@0.24' }, children: [
              { type: 'rect', w: 16, h: 16, circle: true, fill: 'black@0.14', shadow: { sigma: 0.5, y: 1.2, color: 'black@0.3' }, place: 'top-center', dy: 10 },
              { type: 'col', pad: [38, 6, 16, 6], gap: 12, align: 'center', justify: 'center', children: [tile(70, 20, 44), num(28, { textAlign: 'center' })] },
            ] },
          ] } },
      ] },
      label({ textAlign: 'right', w: 160, place: 'top-right', dx: -16, dy: 4, color: 'bg2', size: 19 }),
    ] },
  },

  // D — แป้นคีย์บอร์ด: แต่ละช่องทางเป็นปุ่มขาวมีเงาแข็ง ตัวเลขอยู่ในปุ่ม
  {
    id: 'D', name: 'แป้นปุ่มกด', from: 'Keycap keychain · ปุ่มคีย์บอร์ดห้อยพวง',
    root: keyTab({}, [
      hole,
      { type: 'col', pad: [24, 22, 40, 48], justify: 'center', children: [
        { type: 'chips', id: 'socials', list: 'socials', wrap: false, gap: 9, align: 'center', justify: 'center',
          each: { type: 'stack', grow: 1, maxW: 150, h: 150, fill: 'white', radius: 20, shadow: { sigma: 0, y: 6, color: 'black@0.22' }, children: [
            { type: 'col', pad: [16, 4, 14, 4], gap: 10, align: 'center', justify: 'center', children: [
              { type: 'icon', icon: '$icon', size: 52 }, num(28, { textAlign: 'center', shrinkTo: 13 }),
            ] },
          ] } },
      ] },
      label({ textAlign: 'right', w: 120, place: 'bottom-right', dx: -18, dy: -10 }),
    ]),
  },

  // E — ป้ายกระเป๋าเดินทาง: ปลายตัด (tag) หัวเรื่อง + ตารางสองคอลัมน์ ไอคอน · ชื่อ · ยอด
  {
    id: 'E', name: 'ป้ายกระเป๋า', from: 'Luggage tag · ป้ายปลายตัดมีรูร้อยเชือก · เม็ดยาสามต่อแถว',
    root: keyTab({ shape: 'tag:46', radius: 18, h: '90%' }, [
      { type: 'rect', id: 'hole', w: 22, h: 22, circle: true, fill: 'black@0.14', shadow: { sigma: 0.5, y: 1.7, color: 'black@0.3' }, place: 'center-left', dx: 18 },
      { type: 'col', pad: [16, 24, 16, 62], gap: 8, justify: 'center', children: [
        label({ size: 16 }),
        { type: 'chips', id: 'socials', list: 'socials', gap: 9, align: 'center',
          each: { type: 'row', w: '31.5%', h: 64, gap: 10, align: 'center', pad: [0, 14, 0, 8], fill: 'white@0.6', radius: 32, children: [
            tile(48, 24, 30),
            num(30, { grow: 1, textAlign: 'center', shrinkTo: 15 }),
          ] } },
      ] },
    ]),
  },

  // F — ป้ายแถบสี: แต่ละช่องทางเป็นแถบสีของแบรนด์เรียงกัน กว้างตามส่วนแบ่งยอดผู้ติดตาม
  {
    id: 'F', name: 'แถบส่วนแบ่ง', from: 'Spotify Wrapped / Screen Time · กว้างตามสัดส่วนยอด',
    root: keyTab({}, [
      hole,
      { type: 'col', pad: [16, 24, 16, 48], gap: 11, justify: 'center', children: [
        { type: 'row', align: 'end', children: [
          { type: 'text', slot: 'stat:totalFollowers', face: 'noto', weight: 900, size: 56, color: '#141414', maxLines: 1, readonly: true },
          { type: 'spacer', grow: 1 },
          label({ size: 17 }),
        ] },
        { type: 'chips', id: 'bar', list: 'socials', wrap: false, gap: 4, sort: 'followersRaw desc',
          each: { type: 'rect', pct: '$followersRaw/sum', h: 20, fill: '$tint', radius: 5 } },
        { type: 'chips', id: 'socials', list: 'socials', gap: 8, sort: 'followersRaw desc',
          each: { type: 'row', w: '32%', gap: 8, align: 'center', children: [
            { type: 'stack', w: 40, h: 40, fill: '$tint', radius: 12, children: [{ type: 'stack', w: 32, h: 32, fill: 'white', radius: 9, place: 'center', children: [{ type: 'icon', icon: '$icon', size: 22, place: 'center' }] }] },
            num(26, { shrinkTo: 16 }),
          ] } },
      ] },
    ]),
  },
]
