// ตัวเลือกแทนแถว VERIFIED สีฟ้า (`id: verified` ในคอลัมน์ info ของ popHeroPaper / popHeroGlass)
// แต่ละแบบ = node ที่ใส่แทนแถวเดิม (null = ลบทิ้ง) · ink = สีตัวอักษรของสกินนั้น (paper ใช้ถ่านคงที่ · glass ใช้ token ink)
const T = (o) => ({ type: 'text', face: 'noto', maxLines: 1, ...o })

export const VARIANTS = [
  {
    id: 'now', name: 'ปัจจุบัน', data: '—', note: 'ปุ่ม VERIFIED BY SALE HERE สีฟ้า (ที่ต้องเอาออก)', node: 'keep',
  },
  {
    id: 'A', name: 'โล่ง ไม่ใส่อะไร', data: 'ไม่ใช้ข้อมูลเพิ่ม',
    note: 'ตัดแถวทิ้ง พื้นที่รับงานลงไปชิดล่างให้เส้นตรงกับขอบรูป · เรียบสุด ไม่มีอะไรแย่งชื่อ',
    node: null, dropSpacer: true,
  },
  {
    id: 'B', name: 'สายงาน 2 ป้าย', data: 'categories (ถามตอนเปิด Star Card อยู่แล้ว)',
    note: 'ป้ายเม็ดยาสีตามการ์ด 2 อัน · บอกว่ารับงานสายไหนในแวบเดียว',
    node: (ink) => ({ type: 'chips', id: 'cats', list: 'categories', where: '$i<2', wrap: true, gap: 4, w: 'fill',
      each: { type: 'row', pad: [3, 8], circle: true, fill: 'accent@0.16', stroke: { color: 'accent@0.55', width: 1 },
        children: [T({ slot: '$text', weight: 700, size: 10, color: ink, shrink: 0 })] } }),
  },
  {
    id: 'C', name: 'ผู้ติดตามรวม ตัวใหญ่', data: 'stat:totalFollowers (social ผูกตอนเปิด Star Card)',
    note: 'ตัวเลขหนาเป็นจุดเด่นที่สอง ต่อจากชื่อ · แบรนด์อยากรู้ข้อนี้ก่อนเสมอ',
    node: (ink) => ({ type: 'row', id: 'total', gap: 5, align: 'end', children: [
      T({ slot: 'stat:totalFollowers', weight: 900, size: 30, kerning: -0.6, color: ink, shrink: 0 }),
      { type: 'col', gap: -3, align: 'start', pad: [0, 0, 5, 0], children: [
        T({ text: 'ผู้ติดตาม', weight: 700, size: 10, color: ink }),
        T({ text: 'รวมทุกช่อง', weight: 400, size: 8.5, color: ink + '@0.6' }),
      ] },
    ] }),
  },
  {
    id: 'D', name: 'โลโก้ช่อง + ยอด', data: 'socials + stat:totalFollowers',
    note: 'แถวโลโก้ช่องที่ผูกไว้ ตามด้วยยอดรวม · บอกทั้ง "อยู่ที่ไหน" และ "ใหญ่แค่ไหน"',
    node: (ink) => ({ type: 'row', id: 'socialStrip', gap: 6, align: 'center', w: 'fill', pad: [6, 8], radius: 8,
      fill: ink + '@0.06', children: [
        { type: 'chips', list: 'socials', where: '$i<4', wrap: false, gap: 3,
          each: { type: 'icon', icon: '$icon', size: 16 } },
        { type: 'spacer', grow: 1 },
        T({ slot: 'stat:totalFollowers', weight: 900, size: 14, color: ink, shrink: 0 }),
      ] }),
  },
  {
    id: 'E', name: 'คำโปรยจากเกี่ยวกับฉัน', data: 'about (วิดเจ็ตนี้ขออยู่แล้ว)',
    note: 'เส้นสีการ์ด + 2 บรรทัดแรกของเกี่ยวกับฉัน · ให้ป้ายชื่อมีเสียงของเจ้าของ',
    node: (ink) => ({ type: 'row', id: 'quote', gap: 7, align: 'stretch', w: 'fill', children: [
      { type: 'rect', w: 3, radius: 1.5, fill: 'accent' },
      T({ slot: 'about', weight: 500, size: 10, color: ink + '@0.85', maxLines: 2, grow: 1 }),
    ] }),
  },
  {
    id: 'F', name: 'เทปสายงาน', data: 'categories ตัวแรก',
    note: 'สายงานหลักเขียนบนเทปกาวเฉียง สีเดียวกับเทปที่แปะรูป · เข้าชุดกระดาษ/สติกเกอร์',
    node: (ink) => ({ type: 'chips', id: 'tapeCat', list: 'categories', where: '$i<1', wrap: false,
      each: { type: 'row', pad: [4, 12], fill: 'accent@0.62', rotate: -3, stroke: { color: 'white@0.35', width: 0.5 },
        shadow: { x: 0, sigma: 1.5, y: 1.5, color: 'black@0.12' },
        children: [T({ text: '#', weight: 900, size: 14, color: '#1C1A21', shrink: 0 }), T({ slot: '$text', weight: 900, size: 14, color: '#1C1A21', shrink: 0 })] } }),
  },
  {
    id: 'G', name: 'แสตมป์ ST★R', data: 'stat:starNumber (มีเมื่อเป็น STAR · ไม่มี = ซ่อน)',
    note: 'กรอบตรายางเอียงสีการ์ด "ST★R" + เลขสมาชิก · ภูมิใจแบบบัตรสมาชิก ไม่ใช่ปุ่ม',
    node: () => ({ type: 'col', id: 'starStamp', if: 'has:stat:starNumber', gap: -2, align: 'start', pad: [4, 9], radius: 5,
      stroke: { color: 'accent', width: 1.6 }, rotate: -4, children: [
        { type: 'row', gap: 1, align: 'center', children: [
          T({ text: 'ST', weight: 900, size: 15, kerning: 1, color: 'accent', shrink: 0 }),
          { type: 'icon', icon: 'ph:star-fill', size: 12, tint: 'accent' },
          T({ text: 'R', weight: 900, size: 15, kerning: 1, color: 'accent', shrink: 0 }),
        ] },
        T({ slot: 'stat:starNumber', weight: 700, size: 8.5, kerning: 0.6, color: 'accent', shrink: 0 }),
      ] }),
  },
  {
    id: 'H', name: 'บาร์โค้ดตั๋ว', data: 'stat:starNumber',
    note: 'บาร์โค้ดลายเส้น + เลข STAR ใต้แท่ง · ป้ายชื่อกลายเป็นบัตร/ตั๋ว ดูมีราคา',
    node: (ink) => ({ type: 'col', id: 'barcode', if: 'has:stat:starNumber', gap: 2, align: 'stretch', w: 'fill', children: [
      { type: 'row', gap: 1.4, align: 'stretch', h: 20, children:
        [2, 1, 1, 3, 1, 2, 1, 1, 3, 2, 1, 1, 2, 3, 1, 2, 1, 1, 2, 1, 3, 1, 1, 2, 1, 2, 3, 1, 1, 2, 1].map((w) => ({ type: 'rect', w, h: 20, fill: ink })) },
      T({ slot: 'stat:starNumber', weight: 500, size: 8, kerning: 1.4, color: ink }),
    ] }),
  },
]

/** คืน JSON ใหม่ที่แถว verified ถูกแทนด้วยแบบ v */
export function apply(json, v) {
  const out = structuredClone(json)
  if (v.node === 'keep') return out
  const ink = out.kind === 'popHeroPaper' ? '#1C1A21' : 'ink'
  const walk = (n) => {
    const i = (n.children || []).findIndex((c) => c.id === 'verified')
    if (i >= 0) {
      if (v.node === null) {
        n.children.splice(i, 1)
        if (v.dropSpacer && n.children[i - 1]?.type === 'spacer') n.children.splice(i - 1, 1)
      } else n.children[i] = v.node(ink)
      return true
    }
    return (n.children || []).some(walk)
  }
  walk(out.root)
  // แถวรูป+ข้อมูลกว้างเต็มใบ — เดิมแถว VERIFIED เป็นตัวดันให้กว้าง พอเอาออกกล่องข้อมูลหดตามเนื้อหา
  const body = (n) => (n.children || []).find((c) => c.type === 'row' && (c.children || []).some((x) => x.id === 'info')) || (n.children || []).map(body).find(Boolean)
  const r = body(out.root); if (r) r.w = 'fill'
  return out
}
