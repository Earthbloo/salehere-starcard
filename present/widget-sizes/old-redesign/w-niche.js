/* w-niche.js — สายที่ใช่ (หมวดหมู่/สายงาน) */

const NICHE_ICON = { 'บิวตี้': '💄', 'ไลฟ์สไตล์': '🌿', 'ออกกำลังกาย': '🏃', 'คาเฟ่': '☕', 'แฟชั่น': '👗', 'ท่องเที่ยว': '✈️' };

reg({ id: 'nicheTags', family: 'niche', title: 'สายงาน', sizes: ['wide'], cls: 'glass pad',
  note: 'แถวชิปสายงานแถวเดียว — แนวนอนเท่านั้น (ผังเตี้ย) ชิปใหญ่ อ่านได้จากระยะไกล',
  render() { return `<div class="col" style="height:100%;justify-content:center;gap:10px"><div class="row between">${H.label('Niche')}<span class="dim" style="font-size:11px">${D.cats.length} สาย</span></div><div class="chipwrap">${D.cats.map((c, i) => H.chip(`${NICHE_ICON[c] || ''} ${c}`, i === 0 ? 'xl acc' : 'xl')).join('')}</div></div>`; } });

reg({ id: 'stickerTags', family: 'niche', title: 'สติกเกอร์สายงาน', sizes: ['small', 'wide'], cls: 'glass pad',
  note: 'ป้ายสติกเกอร์ขาวเอียง · เล็ก = 2 ป้ายซ้อนเอียง · แนวนอน = 4 ป้ายกระจายเอียงสลับ',
  render(s) {
    const st = (t, deg, big) => `<span class="sticker" style="transform:rotate(${deg}deg);font-size:${big ? 18 : 14}px;padding:${big ? '8px 14px' : '6px 12px'}">${NICHE_ICON[t] || ''} ${t}</span>`;
    if (s === 'small') return `<div class="center" style="height:100%;gap:12px">${st(D.cats[0], -6, true)}${st(D.cats[1], 4, true)}</div>`;
    return `<div class="col" style="height:100%;justify-content:center;gap:12px">${H.label('Niche')}<div class="row" style="gap:14px;justify-content:center;flex-wrap:wrap">${D.cats.map((c, i) => st(c, i % 2 ? 5 : -5, true)).join('')}</div></div>`;
  } });

reg({ id: 'interestTags', family: 'niche', title: 'หมวดหมู่ที่สนใจ', sizes: ['wide'], cls: 'glass pad',
  note: 'ชิปขอบบาง 2 แถว (สายงาน + ความสนใจ) — แนวนอนเท่านั้น',
  render() { return `<div class="col" style="height:100%;justify-content:center;gap:10px"><div class="row" style="gap:10px">${H.label('สายงาน')}<div class="chipwrap">${D.cats.map(c => H.chip(c, 'acc')).join('')}</div></div><div class="row" style="gap:10px">${H.label('สนใจ')}<div class="chipwrap">${D.interests.slice(0, 3).map(c => H.chip(c, 'outline')).join('')}</div></div></div>`; } });

reg({ id: 'nichePoster', family: 'niche', title: 'โปสเตอร์สายงาน', sizes: ['wide'], cls: 'slab',
  note: 'พาดหัวสองฟอนต์ "What I / CREATE" ซ้าย + พิลล์สายงานขวาเรียงเป็นคอลัมน์ — แนวนอนเท่านั้น',
  render() { return `<div class="row" style="height:100%;padding:16px;gap:16px"><div class="col" style="width:140px;justify-content:center"><div class="h-serif" style="font-size:22px"><i>What I</i></div><div class="h-caps" style="font-size:54px;color:var(--accent)">CREATE</div></div><div class="col fill" style="gap:6px;justify-content:center">${D.cats.map((c, i) => `<div class="row between" style="padding:6px 12px;border-radius:999px;background:${i === 0 ? 'var(--accent)' : 'var(--glass2)'};color:${i === 0 ? '#1B0A0E' : 'var(--ink)'}"><span style="font-weight:600;font-size:12.5px">${c}</span><span style="font-size:11px;opacity:.7">0${i + 1}</span></div>`).join('')}</div></div>`; } });

reg({ id: 'scrapTags', family: 'niche', title: 'ป้ายห้อยสายงาน', sizes: ['small', 'wide'], cls: 'pinkp',
  note: 'ป้ายห้อยกระดาษมีรูเชือก · เล็ก = ป้ายใหญ่ใบเดียว · แนวนอน = 4 ป้ายห้อยจากเชือกเส้นเดียว',
  render(s) {
    const tag = (t, deg, big) => `<div class="scrap-paper" style="padding:${big ? '14px 12px 10px' : '10px 10px 8px'};transform:rotate(${deg}deg);position:relative;clip-path:polygon(0 0,100% 0,100% 100%,0 100%,0 0);border-radius:6px"><span style="position:absolute;top:5px;left:50%;width:7px;height:7px;border-radius:50%;background:var(--pink);transform:translateX(-50%);box-shadow:inset 0 0 0 1.5px #C2185B"></span><div class="h-kanit" style="font-size:${big ? 18 : 13}px;margin-top:${big ? 6 : 4}px;text-align:center">${t}</div><div class="doodle" style="font-size:${big ? 13 : 10}px;text-align:center;color:#C2185B">${NICHE_ICON[t] || '✦'} niche</div></div>`;
    if (s === 'small') return `<div class="center" style="height:100%"><div style="width:2px;height:22px;background:#C2185B"></div>${tag(D.cats[0], -3, true)}</div>`;
    return `<div class="abs" style="left:10px;right:10px;top:26px;height:2px;background:#C2185B;border-radius:2px"></div><div class="row" style="height:100%;padding:34px 14px 14px;gap:8px;justify-content:space-around;align-items:flex-start">${D.cats.map((c, i) => `<div class="center" style="gap:0"><div style="width:2px;height:${10 + (i % 2) * 10}px;background:#C2185B;margin-top:-8px"></div>${tag(c, i % 2 ? 4 : -4, false)}</div>`).join('')}</div>`;
  } });

reg({ id: 'popNichePaper', family: 'niche', title: 'สายงานแบบลิสต์ · กระดาษ', sizes: ['small', 'large'], cls: 'pop-box',
  note: 'สติกเกอร์ขาว ลิสต์สายงานมีไอคอน · เล็ก = 3 แถวชิด · ใหญ่ = 4 แถวใหญ่ + คำอธิบายต่อสาย + ความสนใจ',
  render(s) { return popNiche(s); } });
reg({ id: 'popNicheGlass', family: 'niche', title: 'สายงานแบบลิสต์ · กระจก', sizes: ['small', 'large'], cls: 'glass2',
  note: 'ผังเดียวกับกระดาษ บนกระจกของการ์ด', render(s) { return popNiche(s, true); } });
function popNiche(s, glass) {
  const tab = `<span class="pop-tab" ${glass ? 'style="background:var(--accent);color:#1B0A0E"' : ''}>สายงาน</span>`;
  const row = (c, big) => `<div class="row" style="gap:${big ? 12 : 8}px;padding:${big ? '10px 12px' : '6px 8px'};border-radius:12px;background:var(--glass)"><span style="font-size:${big ? 22 : 16}px;line-height:1">${NICHE_ICON[c] || '✦'}</span><div class="col fill" style="gap:0"><b style="font-size:${big ? 15 : 12.5}px">${c}</b>${big ? `<span class="dim" style="font-size:11px">${['รีวิวสกินแคร์ · เมคอัพ', 'ของใช้ · บ้าน · กิจวัตร', 'พิลาทิส · วิ่งเช้า', 'คาเฟ่ฮอป กรุงเทพฯ'][D.cats.indexOf(c)]}</span>` : ''}</div>${H.ico('arrow', 'dim')}</div>`;
  if (s === 'small') return `${tab}<div class="col" style="height:100%;padding:26px 10px 10px;gap:5px;justify-content:center">${D.cats.slice(0, 3).map(c => row(c, false)).join('')}</div>`;
  return `${tab}<div class="col" style="height:100%;padding:30px 14px 14px;gap:8px"><div class="col" style="flex:1;justify-content:space-evenly;gap:8px">${D.cats.map(c => row(c, true)).join('')}</div><div class="row" style="gap:8px;align-items:center;flex-wrap:wrap"><span class="dim" style="font-size:10.5px">สไตล์</span>${D.styles.slice(0, 3).map(c => H.chip(c)).join('')}</div><div class="row" style="gap:8px;align-items:center"><span class="dim" style="font-size:10.5px">สนใจ</span><div class="chipwrap">${D.interests.slice(0, 3).map(c => H.chip(c, 'outline')).join('')}</div></div></div>`;
}
