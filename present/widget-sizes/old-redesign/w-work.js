/* w-work.js — ผลงาน (รูป · คลิป · แกลเลอรี · ผลงานยืนยัน) */

const WK = D.works;
const cap = (w, big) => `<div class="col" style="gap:1px"><b style="font-size:${big ? 13 : 11.5}px" class="ellip">${w.brand}</b><span class="dim" style="font-size:${big ? 11 : 10}px" class="ellip">${w.camp} · ${w.views} วิว</span></div>`;
const viewTag = (w, sz = 10) => `<span class="chip" style="font-size:${sz}px;padding:3px 7px;background:rgba(0,0,0,.55);color:#fff">${ICO.eye ? '' : ''}${w.views}</span>`;

reg({ id: 'workFeatured', family: 'work', title: 'ผลงานชิ้นเด่น', sizes: ['small', 'wide', 'large'], cls: 'slab',
  note: 'รูปเต็มกรอบ + ป้ายแบรนด์/ยอดวิว · เล็ก = รูป + ยอดวิวมุม · แนวนอน = รูปซ้าย ข้อมูลผลงานขวา · ใหญ่ = รูปเต็ม + แถบข้อมูลล่าง + ER',
  render(s) {
    const w = WK[0];
    if (s === 'small') return `${H.photo(w.seed, 'fill')}<div class="fade-b"></div><div class="abs corner-tr">${viewTag(w)}</div><div class="abs" style="left:12px;right:12px;bottom:12px;color:#fff"><b style="font-size:13px" class="ellip">${w.brand}</b><div style="font-size:10.5px;opacity:.75">${w.camp}</div></div>`;
    if (s === 'wide') return `<div class="row" style="height:100%;gap:0">${H.photo(w.seed, '', 500, 500).replace('class="photo"', 'class="photo" style="width:178px;height:100%;border-radius:0"')}<div class="col fill" style="padding:16px;justify-content:space-between;height:100%"><div class="row between">${H.label('Featured')}${H.badge(w.k, 22)}</div><div><div class="h-kanit" style="font-size:18px">${w.brand}</div><div class="muted" style="font-size:12px">${w.camp} · ${w.fmt}</div></div><div class="row" style="gap:14px"><div><b class="num" style="font-size:22px">${w.views}</b><span class="dim" style="font-size:10px;display:block">วิว</span></div><div><b class="num" style="font-size:22px">${w.er}</b><span class="dim" style="font-size:10px;display:block">ER</span></div></div></div></div>`;
    return `${H.photo(w.seed, 'fill', 900, 900)}<div class="fade-b"></div><div class="abs" style="top:14px;left:14px;right:14px" class="row"><div class="row between"><span class="chip red" style="font-size:10.5px">${w.tag}</span>${H.verified()}</div></div><div class="abs" style="left:16px;right:16px;bottom:16px;color:#fff"><div class="row between" style="align-items:flex-end"><div><div class="h-serif" style="font-size:30px;line-height:1"><i>${w.camp}</i></div><div style="font-size:13px;margin-top:4px;opacity:.85">${w.brand} · ${w.ep} · ${w.fmt}</div></div><div class="row" style="gap:12px;text-align:right"><div><b class="num" style="font-size:26px">${w.views}</b><span style="font-size:10px;opacity:.7;display:block">วิว</span></div><div><b class="num" style="font-size:26px">${w.er}</b><span style="font-size:10px;opacity:.7;display:block">ER</span></div></div></div></div>`;
  } });

reg({ id: 'workReel', family: 'work', title: 'คลิปแนวตั้ง', sizes: ['small', 'large'], cls: 'slab',
  note: 'เฟรม 9:16 ในกรอบ · เล็ก = คลิปเดียว ปุ่มเล่นกลาง · ใหญ่ = คลิปใหญ่กลาง + 2 คลิปข้างซ้อน (ปัดดู)',
  render(s) {
    const reel = (w, wpx, hpx, big) => `<div style="width:${wpx}px;height:${hpx}px;border-radius:14px;overflow:hidden;position:relative;flex:none;background:#222">${H.photo(w.seed, 'fill', 400, 700)}<div class="fade-b"></div><div class="abs" style="top:8px;left:8px">${H.badge(w.k, 20)}</div><div class="abs center" style="inset:0"><span style="width:${big ? 44 : 36}px;height:${big ? 44 : 36}px;border-radius:50%;background:rgba(255,255,255,.9);color:#111;display:grid;place-items:center">${ICO.play.replace('<svg', '<svg width="55%"')}</span></div><div class="abs" style="left:10px;right:10px;bottom:10px;color:#fff;font-size:${big ? 12 : 10.5}px"><b class="ellip" style="display:block">${w.brand}</b><span style="opacity:.75">${w.views} วิว</span></div></div>`;
    if (s === 'small') return `<div class="center" style="height:100%;padding:10px">${reel(WK[0], 90, 158, false)}</div>`;
    return `<div class="row" style="height:100%;padding:16px;gap:10px;justify-content:center;align-items:center">${reel(WK[1], 96, 170, false).replace('flex:none', 'flex:none;opacity:.7;transform:scale(.92)')}${reel(WK[0], 160, 284, true)}${reel(WK[2], 96, 170, false).replace('flex:none', 'flex:none;opacity:.7;transform:scale(.92)')}</div><div class="abs corner-tr">${H.verified()}</div>`;
  } });

reg({ id: 'artFilmstrip', family: 'work', title: 'แถบภาพ', sizes: ['wide'], cls: 'slab',
  note: 'ฟิล์มแนวนอน รูเจาะบนล่าง 4 เฟรม — แนวนอนเท่านั้น',
  render() { return filmStrip(4, 160); } });
function filmStrip(n, h) {
  const holes = `<div style="height:14px;background:repeating-linear-gradient(90deg,transparent 0 8px,#fff 8px 18px,transparent 18px 26px);opacity:.9"></div>`;
  return `<div class="col" style="height:100%;justify-content:center;background:#111;padding:6px 0;gap:4px">${holes}<div class="row" style="gap:6px;padding:0 10px;height:${h - 50}px">${WK.slice(0, n).map(w => H.photo(w.seed, '', 400, 300).replace('class="photo"', 'class="photo" style="flex:1 1 0;height:100%;border-radius:2px"')).join('')}</div>${holes}</div>`;
}

reg({ id: 'artDuo', family: 'work', title: 'เบนโตะ', sizes: ['small', 'wide', 'large'], cls: 'slab',
  note: 'กริดรูปแบบเบนโตะ · เล็ก = 1 ใหญ่ + 1 เล็กมุม · แนวนอน = 1 ใหญ่ซ้าย + 2 ซ้อนขวา · ใหญ่ = 1 ใหญ่ + 2 กลาง + 2 เล็ก (5 รูป)',
  render(s) {
    const p = (w, st) => H.photo(w.seed, '', 500, 500).replace('class="photo"', `class="photo" style="${st};border-radius:10px"`);
    if (s === 'small') return `<div style="padding:8px;height:100%;display:grid;grid-template-columns:1fr 1fr;grid-template-rows:1fr 1fr;gap:6px">${p(WK[0], 'grid-row:1/3')}${p(WK[1], '')}${p(WK[2], '')}</div>`;
    if (s === 'wide') return `<div style="padding:8px;height:100%;display:grid;grid-template-columns:1.4fr 1fr 1fr;grid-template-rows:1fr 1fr;gap:6px">${p(WK[0], 'grid-row:1/3')}${p(WK[1], '')}${p(WK[2], '')}${p(WK[3], 'grid-column:2/4')}</div>`;
    return `<div style="padding:10px;height:100%;display:grid;grid-template-columns:1.3fr 1fr 1fr;grid-template-rows:1fr 1fr 1fr;gap:7px">${p(WK[0], 'grid-row:1/3')}${p(WK[1], 'grid-column:2/4')}${p(WK[2], '')}${p(WK[3], '')}${p(WK[4], 'grid-column:1/3')}<div class="center" style="border-radius:10px;background:var(--glass2);gap:2px"><b class="num" style="font-size:22px">${D.track.done}</b><span class="dim" style="font-size:10px">ผลงาน</span></div></div>`;
  } });

reg({ id: 'artPair', family: 'work', title: 'คู่แนวตั้ง', sizes: ['small', 'wide', 'large'], cls: 'slab',
  note: 'รูปแนวตั้ง 2 ใบคู่กัน · เล็ก = 2 ใบแคบ · แนวนอน = 2 ใบเต็มสูง + ป้ายชื่อ · ใหญ่ = 2 ใบสูง + คำโปรยใต้รูป',
  render(s) {
    const p = (w, st = '') => `<div style="position:relative;flex:1;height:100%;border-radius:12px;overflow:hidden;${st}">${H.photo(w.seed, 'fill', 400, 600)}<div class="fade-b"></div><div class="abs" style="left:10px;bottom:10px;right:10px;color:#fff;font-size:11px"><b class="ellip" style="display:block">${w.brand}</b></div></div>`;
    if (s === 'small') return `<div class="row" style="height:100%;padding:8px;gap:6px">${p(WK[0])}${p(WK[1])}</div>`;
    if (s === 'wide') return `<div class="row" style="height:100%;padding:10px;gap:8px">${p(WK[0])}${p(WK[1])}</div>`;
    return `<div class="col" style="height:100%;padding:12px;gap:10px"><div class="row" style="flex:1;gap:10px">${p(WK[0])}${p(WK[1])}</div><div class="row between"><div><div class="h-serif" style="font-size:18px"><i>Before</i> / <i>After</i></div><div class="dim" style="font-size:11px">${WK[1].camp} · ถ่ายในแสงเดียวกัน 14 วัน</div></div>${H.verified()}</div></div>`;
  } });

reg({ id: 'artPhotobooth', family: 'work', title: 'ตู้ถ่ายรูป', sizes: ['small', 'wide', 'large'], cls: 'slab',
  note: 'แถบรูปตู้ถ่าย · เล็ก = แถบตั้ง 3 รูป · แนวนอน = แถบนอน 4 รูป + วันที่ · ใหญ่ = 2 แถบตั้งวางเอียงบนพื้น',
  render(s) {
    const strip = (seeds, vertical, w) => `<div style="background:#fff;padding:6px;display:flex;flex-direction:${vertical ? 'column' : 'row'};gap:5px;box-shadow:0 6px 16px rgba(0,0,0,.35);flex:none;${w}">${seeds.map(sd => H.photo(sd, '', 300, 300).replace('class="photo"', 'class="photo" style="border-radius:2px;aspect-ratio:1;flex:1;filter:contrast(1.05) sepia(.1)"')).join('')}<small class="mono" style="font-size:8px;color:#777;text-align:center">${D.seal.date}</small></div>`;
    if (s === 'small') return `<div class="center" style="height:100%;padding:8px">${strip([1, 2, 3], true, 'width:52px;transform:rotate(-4deg)')}</div>`;
    if (s === 'wide') return `<div class="center" style="height:100%;padding:12px">${strip([1, 2, 3, 11], false, 'height:130px;width:100%;transform:rotate(-1deg)')}</div>`;
    return `<div class="row" style="height:100%;padding:16px 16px 36px;gap:26px;justify-content:center;align-items:center">${strip([1, 2, 3], true, 'width:104px;transform:rotate(-6deg)')}${strip([12, 13, 2], true, 'width:104px;transform:rotate(5deg) translateY(10px)')}</div><div class="abs corner-bl h-script" style="font-size:24px;color:var(--accent)">photobooth ♡ ${D.seal.date}</div>`;
  } });

/* แกลเลอรี */
reg({ id: 'galleryStack', family: 'work', title: 'กองรูปซ้อน', sizes: ['wide', 'large'], cls: 'glass pad',
  note: 'รูปซ้อนเป็นกอง · แนวนอน = กองซ้าย + ชื่อ/จำนวนขวา · ใหญ่ = กองใหญ่กลาง + ป้ายชื่อผลงานบนสุด',
  render(s) {
    const stack = (w, h) => `<div style="position:relative;width:${w}px;height:${h}px;flex:none">${[2, 1, 0].map((i, j) => `<div style="position:absolute;inset:0;border-radius:12px;overflow:hidden;transform:rotate(${(j - 1) * 6}deg) translateY(${(j - 1) * -4}px);box-shadow:0 8px 20px rgba(0,0,0,.35)"><img src="${PH(WK[i].seed, 500, 500)}" alt=""></div>`).join('')}</div>`;
    if (s === 'wide') return `<div class="row" style="height:100%;gap:20px;padding-left:8px">${stack(130, 130)}<div class="col fill" style="gap:6px">${H.label('Portfolio')}<div class="h-kanit" style="font-size:28px">${D.track.done} ผลงาน</div><div class="muted" style="font-size:12px">${D.track.brands} แบรนด์ · ER เฉลี่ย ${D.track.er}</div><div class="chipwrap" style="margin-top:4px">${H.chips(['TikTok', 'Reel', 'Short'], 'outline')}</div></div></div>`;
    return `<div class="col" style="height:100%;gap:10px"><div class="row between">${H.label('Portfolio')}${H.verified()}</div><div class="center" style="flex:1">${stack(220, 220)}</div><div class="row between" style="align-items:flex-end"><div><div class="h-kanit" style="font-size:20px">${WK[0].camp}</div><div class="dim" style="font-size:11.5px">${WK[0].brand} · ${WK[0].views} วิว · +${D.track.done - 1} ชิ้น</div></div><span class="chip acc">ปัดดู</span></div></div>`;
  } });

reg({ id: 'galleryCarousel', family: 'work', title: 'สไลด์การ์ด', sizes: ['wide', 'large'], cls: 'glass pad',
  note: 'การ์ดเลื่อนแนวนอน ใบกลางเด่น · แนวนอน = 3 ใบ ใบกลางใหญ่ + จุดบอกหน้า · ใหญ่ = 3 ใบสูง + ชื่อผลงานใต้แต่ละใบ',
  render(s) {
    const card = (w, big, mid) => `<div class="col" style="flex:${mid ? 1.4 : 1};gap:6px;opacity:${mid ? 1 : .6}"><div style="border-radius:12px;overflow:hidden;height:${big ? (mid ? 250 : 215) : (mid ? 110 : 90)}px;margin-top:${mid ? 0 : (big ? 18 : 10)}px">${H.photo(w.seed, '', 400, 500).replace('class="photo"', 'class="photo" style="height:100%;border-radius:0"')}</div>${big ? `<b style="font-size:12px" class="ellip">${w.brand}</b><span class="dim" style="font-size:10.5px">${w.views} วิว</span>` : ''}</div>`;
    const dots = `<div class="row" style="gap:5px;justify-content:center">${[0, 1, 2, 3, 4].map(i => `<i style="width:${i === 1 ? 14 : 5}px;height:5px;border-radius:3px;background:${i === 1 ? 'var(--accent)' : 'var(--line)'};display:block"></i>`).join('')}</div>`;
    if (s === 'wide') return `<div class="col" style="height:100%;gap:8px;justify-content:space-between"><div class="row" style="gap:8px;align-items:flex-start">${card(WK[1], false, false)}${card(WK[0], false, true)}${card(WK[2], false, false)}</div>${dots}</div>`;
    return `<div class="col" style="height:100%;gap:10px"><div class="row between">${H.label('Works')}${H.verified()}</div><div class="row" style="gap:10px;align-items:flex-start;flex:1">${card(WK[1], true, false)}${card(WK[0], true, true)}${card(WK[2], true, false)}</div>${dots}</div>`;
  } });

reg({ id: 'galleryMasonry', family: 'work', title: 'บอร์ดพิน', sizes: ['wide', 'large'], cls: 'glass pad',
  note: 'คอลัมน์รูปสูงไม่เท่ากันแบบ Pinterest · แนวนอน = 4 คอลัมน์เตี้ย · ใหญ่ = 3 คอลัมน์ 5 รูป + ป้ายจำนวน',
  render(s) {
    const p = (w, h) => `<div style="position:relative;height:${h}px;border-radius:10px;overflow:hidden">${H.photo(w.seed, 'fill', 400, 600)}<div class="abs" style="left:6px;bottom:6px">${viewTag(w, 9)}</div></div>`;
    if (s === 'wide') return `<div class="row" style="height:100%;gap:6px;align-items:flex-start">${[[WK[0], 100], [WK[1], 140], [WK[2], 110], [WK[3], 146]].map(([w, h]) => `<div style="flex:1">${p(w, h)}</div>`).join('')}</div>`;
    return `<div class="col" style="height:100%;gap:8px"><div class="row between">${H.label('Pinboard')}<span class="dim" style="font-size:11px">${D.track.done} ชิ้น</span></div><div class="row" style="gap:7px;align-items:flex-start;flex:1"><div class="col" style="flex:1;gap:7px">${p(WK[0], 150)}${p(WK[3], 120)}</div><div class="col" style="flex:1;gap:7px">${p(WK[1], 100)}${p(WK[4], 170)}</div><div class="col" style="flex:1;gap:7px">${p(WK[2], 180)}<div class="center" style="height:90px;border-radius:10px;background:var(--glass2);gap:0"><b class="num" style="font-size:20px">+${D.track.done - 5}</b><span class="dim" style="font-size:10px">ชิ้น</span></div></div></div></div>`;
  } });

reg({ id: 'galleryMosaic', family: 'work', title: 'โมเสก', sizes: ['wide', 'large'], cls: 'slab',
  note: 'รูปชิดขอบไม่มีช่องว่าง · แนวนอน = 4 ช่อง 1 ใหญ่ · ใหญ่ = 3×3 ช่อง (รูปเด่นกิน 2×2)',
  render(s) {
    const p = (w, st) => H.photo(w.seed, '', 500, 500).replace('class="photo"', `class="photo" style="${st};border-radius:0"`);
    if (s === 'wide') return `<div style="height:100%;display:grid;grid-template-columns:2fr 1fr 1fr;grid-template-rows:1fr 1fr;gap:2px">${p(WK[0], 'grid-row:1/3')}${p(WK[1], '')}${p(WK[2], '')}${p(WK[3], '')}${p(WK[4], '')}</div>`;
    return `<div style="height:100%;display:grid;grid-template-columns:repeat(3,1fr);grid-template-rows:repeat(3,1fr);gap:2px">${p(WK[0], 'grid-column:1/3;grid-row:1/3')}${p(WK[1], '')}${p(WK[2], '')}${p(WK[3], '')}${p(WK[4], '')}${p({ seed: 1 }, '')}</div><div class="abs corner-tr">${H.verified().replace('class="vby"', 'class="vby" style="background:rgba(0,0,0,.65);color:#fff"')}</div>`;
  } });

reg({ id: 'galleryPost', family: 'work', title: 'โพสต์โซเชียล', sizes: ['wide', 'large'], cls: 'white',
  note: 'หน้าตาโพสต์ IG: หัวโปรไฟล์ + รูป + แถบไลก์/แคปชั่น · แนวนอน = รูปซ้ายจัตุรัส ข้อมูลขวา · ใหญ่ = โพสต์เต็ม',
  render(s) {
    const head = `<div class="row" style="gap:8px">${H.avatar(28)}<b style="font-size:12px">${D.handle.slice(1)}</b><span class="dim" style="font-size:11px;margin-left:auto">···</span></div>`;
    const acts = `<div class="row" style="gap:10px;font-size:12px"><span class="row" style="gap:4px;color:#E1306C">${H.ico('heart')}<b>84.2K</b></span><span class="dim">💬 1,930</span><span class="dim" style="margin-left:auto">🔖 42.6K</span></div>`;
    if (s === 'wide') return `<div class="row" style="height:100%;gap:0">${H.photo(WK[0].seed, '', 500, 500).replace('class="photo"', 'class="photo" style="width:178px;height:100%;border-radius:0"')}<div class="col fill" style="padding:12px 14px;justify-content:space-between;height:100%">${head}<div style="font-size:11.5px;line-height:1.4" class="clamp3"><b>${D.handle.slice(1)}</b> ${WK[0].camp} กับ ${WK[0].brand} — เปิดด้วยผิวจริงวันแพ้ ไม่รีทัช</div>${acts}</div></div>`;
    return `<div class="col" style="height:100%"><div style="padding:10px 12px">${head}</div>${H.photo(WK[0].seed, '', 700, 700).replace('class="photo"', 'class="photo" style="height:190px;border-radius:0"')}<div class="col" style="padding:10px 12px;gap:6px">${acts}<div style="font-size:11.5px;line-height:1.4" class="clamp2"><b>${D.handle.slice(1)}</b> ${WK[0].camp} กับ ${WK[0].brand} — เปิดด้วยผิวจริงวันแพ้ ไม่รีทัช แล้วค่อยเข้าสินค้าในวินาทีที่ 8</div><div class="row between"><span class="dim" style="font-size:10px">${WK[0].views} VIEWS · ${WK[0].ep}</span>${H.verified()}</div></div></div>`;
  } });

reg({ id: 'galleryStory', family: 'work', title: 'สตอรี่', sizes: ['small', 'large'], cls: 'slab',
  note: 'เฟรมสตอรี่ 9:16 มีแถบเวลา · เล็ก = เฟรมเดียว · ใหญ่ = เฟรมใหญ่กลาง + แถบเวลา 3 ช่อง + โปรไฟล์บน',
  render(s) {
    const frame = (w, wpx, hpx, big) => `<div style="width:${wpx}px;height:${hpx}px;border-radius:16px;overflow:hidden;position:relative;flex:none">${H.photo(w.seed, 'fill', 400, 700)}<div class="fade-t"></div><div class="abs row" style="top:8px;left:8px;right:8px;gap:3px">${[1, 0, 0].map(on => `<i style="flex:1;height:2px;border-radius:2px;background:rgba(255,255,255,${on ? 1 : .4})"></i>`).join('')}</div><div class="abs row" style="top:16px;left:8px;gap:6px;color:#fff">${H.avatar(big ? 26 : 20)}<b style="font-size:${big ? 11 : 9.5}px">${D.handle.slice(1)}</b><span style="font-size:9px;opacity:.7">2h</span></div><div class="abs" style="left:10px;right:10px;bottom:10px;color:#fff"><span class="sticker" style="font-size:${big ? 13 : 10}px;transform:rotate(-3deg)">${w.brand}</span></div></div>`;
    if (s === 'small') return `<div class="center" style="height:100%;padding:8px">${frame(WK[1], 92, 162, false)}</div>`;
    return `<div class="center" style="height:100%;padding:14px;gap:10px">${frame(WK[1], 186, 300, true)}<div class="row" style="gap:6px">${[WK[0], WK[1], WK[2]].map((w, i) => `<span class="chip ${i === 1 ? 'acc' : 'outline'}" style="font-size:10px">${w.brand}</span>`).join('')}</div></div>`;
  } });

reg({ id: 'galleryFilm', family: 'work', title: 'ฟิล์ม 35 มม.', sizes: ['wide'], cls: 'slab',
  note: 'ฟิล์มเนกาทีฟ 35 มม. มีเลขเฟรม — แนวนอนเท่านั้น',
  render() { return `<div class="col" style="height:100%;justify-content:center;background:#141414;padding:8px 0;gap:3px"><div class="row mono" style="justify-content:space-between;padding:0 14px;font-size:8px;color:#C9A227">${['▸ 12', '▸ 13', '▸ 14', '▸ 15'].map(t => `<span>${t}</span>`).join('')}</div><div style="height:10px;background:repeating-linear-gradient(90deg,transparent 0 8px,#fff 8px 16px,transparent 16px 24px)"></div><div class="row" style="gap:5px;padding:0 10px;height:96px">${WK.slice(0, 4).map(w => H.photo(w.seed, '', 400, 300).replace('class="photo"', 'class="photo" style="flex:1 1 0;height:100%;border-radius:1px;filter:saturate(1.15) contrast(1.05)"')).join('')}</div><div style="height:10px;background:repeating-linear-gradient(90deg,transparent 0 8px,#fff 8px 16px,transparent 16px 24px)"></div><div class="mono" style="padding:0 14px;font-size:8px;color:#C9A227">KODAK 400 · ${D.en} · ${D.seal.date}</div></div>`; } });

reg({ id: 'galleryTape', family: 'work', title: 'เทปกาว', sizes: ['wide', 'large'], cls: 'glass pad',
  note: 'รูปแปะเทปกาวเอียง · แนวนอน = 3 รูปเอียงสลับ · ใหญ่ = 5 รูปแปะทับกันเล็กน้อย + ลายมือ',
  render(s) {
    const p = (w, st, tapeSt) => `<div style="position:absolute;${st}"><div style="border-radius:3px;overflow:hidden;box-shadow:0 6px 14px rgba(0,0,0,.35)">${H.photo(w.seed, '', 400, 400).replace('class="photo"', 'class="photo" style="width:100%;height:100%;border-radius:0"')}</div><span class="tape" style="${tapeSt}"></span></div>`;
    if (s === 'wide') return `<div style="position:relative;height:100%">${p(WK[0], 'left:4px;top:10px;width:108px;height:120px;transform:rotate(-5deg)', 'top:-8px;left:28px')}${p(WK[1], 'left:118px;top:6px;width:108px;height:120px;transform:rotate(3deg)', 'top:-8px;left:26px;transform:rotate(4deg)')}${p(WK[2], 'left:232px;top:12px;width:108px;height:120px;transform:rotate(-2deg)', 'top:-8px;left:30px;transform:rotate(-8deg)')}</div>`;
    return `<div style="position:relative;height:100%">${p(WK[0], 'left:0;top:6px;width:150px;height:150px;transform:rotate(-5deg)', 'top:-8px;left:46px')}${p(WK[1], 'left:166px;top:0;width:150px;height:150px;transform:rotate(3deg)', 'top:-8px;left:48px;transform:rotate(5deg)')}${p(WK[2], 'left:20px;top:176px;width:140px;height:140px;transform:rotate(2deg)', 'top:-8px;left:40px;transform:rotate(-8deg)')}${p(WK[3], 'left:180px;top:170px;width:140px;height:140px;transform:rotate(-4deg)', 'top:-8px;left:42px')}<div class="abs h-script" style="right:6px;bottom:4px;font-size:24px;color:var(--accent);transform:rotate(-6deg)">my works ♡</div></div>`;
  } });

reg({ id: 'wallPolaroid', family: 'work', title: 'กำแพงโพลารอยด์', sizes: ['large'], cls: 'glass pad',
  note: 'โพลารอยด์ 5 ใบแปะกำแพงเอียง + คำบรรยายลายมือ — ใหญ่เท่านั้น',
  render() {
    const pol = (w, st) => `<div class="polaroid" style="position:absolute;width:118px;${st}">${H.photo(w.seed, '', 400, 400)}<small>${w.camp.split(' ')[0]}</small></div>`;
    return `<div style="position:relative;height:100%">${pol(WK[0], 'left:0;top:0;transform:rotate(-6deg)')}${pol(WK[1], 'left:118px;top:10px;transform:rotate(3deg)')}${pol(WK[2], 'left:226px;top:0;transform:rotate(-2deg)')}${pol(WK[3], 'left:40px;top:164px;transform:rotate(4deg)')}${pol(WK[4], 'left:190px;top:170px;transform:rotate(-5deg)')}<div class="abs h-script" style="left:6px;bottom:0;font-size:26px;color:var(--accent)">${D.track.done} works · 2569</div></div>`;
  } });

reg({ id: 'wallMemory', family: 'work', title: 'บอร์ดรูปติดหมุด', sizes: ['wide', 'large'], cls: 'paper',
  note: 'บอร์ดไม้ก๊อกติดหมุดสี · แนวนอน = 3 รูป + โน้ต 1 · ใหญ่ = 4 รูป + โน้ต 2 + เชือกโยง',
  render(s) {
    const pin = c => `<span style="position:absolute;top:-6px;left:50%;width:12px;height:12px;border-radius:50%;background:${c};box-shadow:0 1px 2px rgba(0,0,0,.4);transform:translateX(-50%)"></span>`;
    const p = (w, st, c) => `<div style="position:absolute;${st};background:#fff;padding:4px;box-shadow:0 4px 10px rgba(0,0,0,.25)">${H.photo(w.seed, '', 400, 400).replace('class="photo"', 'class="photo" style="width:100%;height:100%;border-radius:0"')}${pin(c)}</div>`;
    const note = (t, st, c) => `<div style="position:absolute;${st};background:#FFF3A8;padding:8px 10px;font-family:var(--f-script);font-size:14px;color:#5A4A1E;box-shadow:0 3px 8px rgba(0,0,0,.2);line-height:1.1">${t}${pin(c)}</div>`;
    const cork = `<div class="abs" style="inset:0;background:#D9B98A;background-image:radial-gradient(rgba(0,0,0,.08) 1px,transparent 1px);background-size:5px 5px"></div>`;
    if (s === 'wide') return `${cork}${p(WK[0], 'left:14px;top:22px;width:96px;height:96px;transform:rotate(-4deg)', '#E5322D')}${p(WK[1], 'left:118px;top:30px;width:96px;height:96px;transform:rotate(3deg)', '#2B6FD6')}${p(WK[2], 'left:222px;top:18px;width:96px;height:96px;transform:rotate(-2deg)', '#2BA84A')}${note('${D.track.brands} brands ♡', 'right:8px;bottom:12px;transform:rotate(5deg)', '#E5322D').replace('${D.track.brands}', D.track.brands)}`;
    return `${cork}${p(WK[0], 'left:14px;top:22px;width:130px;height:130px;transform:rotate(-4deg)', '#E5322D')}${p(WK[1], 'left:196px;top:32px;width:130px;height:130px;transform:rotate(3deg)', '#2B6FD6')}${p(WK[2], 'left:30px;top:200px;width:120px;height:120px;transform:rotate(2deg)', '#2BA84A')}${p(WK[3], 'left:170px;top:206px;width:120px;height:120px;transform:rotate(-5deg)', '#F2B705')}${note(`${D.track.done} works<br>${D.track.brands} brands`, 'right:10px;top:176px;transform:rotate(6deg)', '#E5322D')}${note(D.first + ' ♡', 'right:14px;bottom:14px;transform:rotate(-4deg)', '#2B6FD6')}`;
  } });

reg({ id: 'zineCover', family: 'work', title: 'ปกผลงาน', sizes: ['large'], cls: 'paper',
  note: 'ปกซีน: ชื่อเล่มยักษ์ + รูปปก + สารบัญผลงาน — ใหญ่เท่านั้น',
  render() { return `<div style="padding:16px 18px;height:100%;display:flex;flex-direction:column;gap:8px"><div class="row between mono"><span>VOL. 01 · 2569</span><span>${D.city.toUpperCase()}</span></div><div class="h-caps" style="font-size:54px;line-height:.9;color:var(--paper-ink)">WORKS<br><span style="color:#B8392F">BY ${D.en}</span></div><div class="row" style="gap:12px;flex:1;min-height:0;align-items:stretch"><div style="flex:1.1;border-radius:4px;overflow:hidden">${H.photo(WK[0].seed, '', 500, 600).replace('class="photo"', 'class="photo" style="height:100%;border-radius:0"')}</div><div class="col fill" style="gap:3px;font-size:11px;justify-content:flex-end">${WK.slice(0, 3).map((w, i) => `<div class="row between" style="border-bottom:1px solid rgba(0,0,0,.15);padding-bottom:3px"><span><b class="mono">0${i + 1}</b> ${w.brand}</span><span class="dim">${w.views}</span></div>`).join('')}</div></div><div class="row between" style="font-size:11px;color:var(--paper-ink2)"><span>${D.track.done} ผลงาน · ${D.track.brands} แบรนด์</span>${H.verified()}</div></div>`; } });

reg({ id: 'scrapPhones', family: 'work', title: 'กำแพงมือถือ', sizes: ['wide', 'large'], cls: 'pinkp',
  note: 'มือถือ 3–4 เครื่องโชว์คลิป · แนวนอน = 3 เครื่องเรียง · ใหญ่ = 4 เครื่อง 2 แถว + หัวลายมือ',
  render(s) {
    const phone = (w, wpx) => `<div style="width:${wpx}px;aspect-ratio:9/18;border-radius:${wpx * .18}px;background:#111;padding:${wpx * .05}px;flex:none;box-shadow:0 6px 14px rgba(0,0,0,.25);position:relative"><div style="position:absolute;top:${wpx * .07}px;left:50%;transform:translateX(-50%);width:30%;height:${wpx * .06}px;border-radius:999px;background:#111;z-index:1"></div><div style="border-radius:${wpx * .14}px;overflow:hidden;height:100%;position:relative">${H.photo(w.seed, 'fill', 300, 600)}<div class="fade-b"></div><div class="abs" style="left:6px;right:6px;bottom:6px;color:#fff;font-size:${wpx * .1}px"><b>${w.brand.split(' ')[0]}</b><div style="opacity:.75">${w.views}</div></div></div></div>`;
    if (s === 'wide') return `<div class="row" style="height:100%;padding:12px;gap:14px;justify-content:center;align-items:center">${phone(WK[0], 72)}${phone(WK[1], 72)}${phone(WK[2], 72)}<div class="doodle" style="font-size:22px;line-height:1;width:70px">my<br>clips ▶</div></div>`;
    return `<div class="col" style="height:100%;padding:14px;gap:10px"><div class="row between"><div class="doodle" style="font-size:30px">my clips ▶</div><span class="sticker" style="font-size:11px">${D.track.done} works</span></div><div class="row" style="gap:12px;justify-content:center;flex:1;align-items:center">${WK.slice(0, 3).map(w => phone(w, 96)).join('')}</div><div class="row" style="gap:6px;justify-content:center;flex-wrap:wrap">${WK.slice(0, 4).map(w => `<span class="chip" style="background:#fff;color:#4A1F2C;font-size:10.5px">${w.brand.split(' ')[0]} · ${w.views}</span>`).join('')}</div></div>`;
  } });

reg({ id: 'reelShowcase', family: 'work', title: 'คลิปล่าสุด', sizes: ['wide'], cls: 'slab',
  note: 'พาดหัว "Recent / VIDEOGRAPHY" + มือถือ 4 เครื่องเรียง — แนวนอนเท่านั้น',
  render() { return `<div class="col" style="height:100%;padding:12px 14px;gap:8px;align-items:center"><div class="center" style="gap:0"><span class="h-serif" style="font-size:14px"><i>Recent</i></span><span class="h-kanit" style="font-size:20px;margin-top:-3px">VIDEOGRAPHY</span></div><div class="row" style="gap:10px;align-items:flex-end">${WK.slice(0, 4).map(w => `<div class="col" style="align-items:center;gap:3px"><div style="width:56px;height:98px;border-radius:10px;background:#111;padding:3px;position:relative"><div style="border-radius:8px;overflow:hidden;height:100%">${H.photo(w.seed, '', 300, 500).replace('class="photo"', 'class="photo" style="height:100%;border-radius:0"')}</div></div><span class="dim" style="font-size:9px">${w.brand.split(' ')[0]}</span></div>`).join('')}</div></div>`; } });

/* ผลงานยืนยัน */
reg({ id: 'proofWork', family: 'work', title: 'ผลงานที่ยืนยันแล้ว', sizes: ['wide', 'large'], cls: 'glass pad',
  note: 'ผลงานจากแคมเปญ Sale Here มีเครื่องหมายยืนยัน · แนวนอน = รูป + 3 ตัวเลข · ใหญ่ = รูปใหญ่ + ตัวเลข 4 ช่อง + คอนเซปต์',
  render(s) {
    const w = WK[0];
    const nums = (big) => `<div class="grid3" style="text-align:center">${[[w.views, 'วิว'], [w.er, 'ER'], ['42.6K', 'เซฟ']].map(([n, l]) => `<div><b class="num" style="font-size:${big ? 22 : 18}px;display:block">${n}</b><span class="dim" style="font-size:10px">${l}</span></div>`).join('')}</div>`;
    if (s === 'wide') return `<div class="row" style="height:100%;gap:14px"><div style="width:120px;height:100%;border-radius:12px;overflow:hidden;position:relative;flex:none">${H.photo(w.seed, 'fill', 400, 500)}<div class="abs" style="top:6px;left:6px">${H.badge(w.k, 20)}</div></div><div class="col fill" style="justify-content:space-between;height:100%"><div class="row between"><span class="chip red" style="font-size:10px">${ICO.check.replace('<svg', '<svg width="10"')} ยืนยันแล้ว</span><span class="dim mono">${w.ep}</span></div><div><b class="h-kanit" style="font-size:16px">${w.brand}</b><div class="dim" style="font-size:11.5px">${w.camp} · ${w.fmt}</div></div>${nums(false)}</div></div>`;
    return `<div class="col" style="height:100%;gap:10px"><div class="row between"><span class="chip red" style="font-size:10.5px">${ICO.check.replace('<svg', '<svg width="10"')} ผลงานยืนยันโดย Sale Here</span><span class="dim mono">${w.ep}</span></div><div style="height:150px;border-radius:14px;overflow:hidden;position:relative">${H.photo(w.seed, 'fill', 800, 500)}<div class="fade-b"></div><div class="abs" style="left:12px;bottom:10px;color:#fff"><b class="h-kanit" style="font-size:20px">${w.brand}</b><div style="font-size:12px;opacity:.85">${w.camp} · ${w.fmt}</div></div><div class="abs corner-tr">${H.badge(w.k, 24)}</div></div><div class="grid2" style="gap:6px">${[[w.views, 'วิว'], [w.er, 'ER'], ['84.2K', 'ไลก์'], ['42.6K', 'เซฟ']].map(([n, l]) => `<div class="row between" style="padding:8px 10px;border-radius:10px;background:var(--glass)"><span class="dim" style="font-size:11px">${l}</span><b class="num" style="font-size:18px">${n}</b></div>`).join('')}</div><div class="dim" style="font-size:11px;line-height:1.4;margin-top:auto">"เปิดด้วยผิวจริงวันแพ้ ไม่รีทัช แล้วค่อยเข้าสินค้าในวินาทีที่ 8"</div></div>`;
  } });

reg({ id: 'proofTicket', family: 'work', title: 'ตั๋วผลงาน', sizes: ['wide', 'large'], cls: 'paper',
  note: 'ตั๋วคอนเสิร์ตฉีกได้ ฟอนต์โมโน · แนวนอน = ตั๋วแนวนอน ต้นขั้วขวา · ใหญ่ = ตั๋ว 3 ใบซ้อน (3 ผลงาน)',
  render(s) {
    const tk = (w, big, st = '') => `<div class="row" style="${st};background:#fff;color:#111;border-radius:8px;box-shadow:0 3px 10px rgba(0,0,0,.15);overflow:hidden;height:${big ? 100 : 130}px"><div class="col fill" style="padding:${big ? 10 : 14}px 14px;justify-content:space-between;border-right:2px dashed #ccc"><div class="row between mono" style="font-size:9.5px;color:#777"><span>ADMIT ONE · ${w.ep}</span>${H.badge(w.k, 16)}</div><div><b class="h-caps" style="font-size:${big ? 22 : 30}px;letter-spacing:.06em">${w.brand.toUpperCase()}</b><div class="mono" style="font-size:10px;color:#555">${w.camp} · ${w.fmt}</div></div><div class="row mono" style="gap:12px;font-size:10.5px"><span>${w.views} VIEWS</span><span>ER ${w.er}</span><span style="color:#B8392F">✓ VERIFIED</span></div></div><div class="center mono" style="width:${big ? 64 : 80}px;background:#F2EFE6;font-size:9px;gap:4px;padding:6px"><span style="writing-mode:vertical-rl;letter-spacing:.2em;color:#777">SALE HERE</span>${big ? '' : `<b style="font-size:16px;writing-mode:horizontal-tb">${w.views}</b>`}</div></div>`;
    if (s === 'wide') return `<div style="padding:14px;height:100%" class="center">${tk(WK[0], false, 'width:100%')}</div>`;
    return `<div class="col" style="padding:16px;height:100%;gap:10px"><div class="row between"><span class="h-serif" style="font-size:18px"><i>Verified works</i></span>${H.verified()}</div>${WK.slice(0, 3).map((w, i) => tk(w, true, `transform:rotate(${(i - 1) * 1.2}deg)`)).join('')}</div>`;
  } });

reg({ id: 'scrapChat', family: 'work', title: 'แชทจากแบรนด์', sizes: ['wide', 'large'], cls: 'pinkp',
  note: 'บับเบิลแชทรีวิวจากแบรนด์ · แนวนอน = 2 บับเบิล · ใหญ่ = บทสนทนา 4 บับเบิล + รูปผลงานแนบ',
  render(s) {
    const b = (t, me, who) => `<div class="col" style="align-items:${me ? 'flex-end' : 'flex-start'};gap:2px"><span style="font-size:9.5px;color:#8A6A74">${who}</span><div style="max-width:78%;padding:8px 12px;border-radius:14px;font-size:12px;line-height:1.4;background:${me ? '#C2185B' : '#fff'};color:${me ? '#fff' : '#333'};box-shadow:0 2px 6px rgba(0,0,0,.1)">${t}</div></div>`;
    if (s === 'wide') return `<div class="col" style="height:100%;padding:14px 16px;gap:8px;justify-content:center">${b('คลิป Ballet Dream วิวทะลุ 1.2M แล้วค่ะ ขอบคุณมากนะคะ 🙏', false, 'Sivanna Colors')}${b('ยินดีค่ะ รอบหน้าถ่าย before/after ให้นะคะ ✨', true, D.first)}</div>`;
    return `<div class="col" style="height:100%;padding:14px 16px;gap:8px"><div class="row between"><div class="doodle" style="font-size:24px">brand says ♡</div><span class="chip red" style="font-size:10px">${D.track.brands} แบรนด์</span></div>${b('คลิป Ballet Dream วิวทะลุ 1.2M แล้วค่ะ ขอบคุณมากนะคะ 🙏', false, 'Sivanna Colors')}${b('ยินดีค่ะ รอบหน้าถ่าย before/after ให้นะคะ ✨', true, D.first)}<div class="col" style="align-items:flex-start;gap:2px"><span style="font-size:9.5px;color:#8A6A74">Cathy Doll</span><div style="width:120px;border-radius:12px;overflow:hidden;box-shadow:0 2px 6px rgba(0,0,0,.15)">${H.photo(WK[1].seed, '', 300, 220).replace('class="photo"', 'class="photo" style="height:80px;border-radius:0"')}</div></div>${b('Conversion ดีมาก จองคิวเดือนหน้าเลยนะคะ', false, 'Cathy Doll')}<div class="row between" style="margin-top:auto;font-size:10.5px;color:#8A6A74"><span>ทำงานจบ ${D.track.done} งาน</span>${H.verified()}</div></div>`;
  } });

/* สำรับสติกเกอร์ (pop) วิดีโอ/ผลงาน */
reg({ id: 'popVideoPaper', family: 'work', title: 'หน้าต่างวิดีโอ · กระดาษ', sizes: ['small', 'wide', 'large'], cls: 'pop-box',
  note: 'สติกเกอร์ขาว กรอบวิดีโอ + ปุ่มเล่น · เล็ก = 1 คลิป · แนวนอน = 1 คลิปซ้าย + รายการ 2 ขวา · ใหญ่ = คลิปใหญ่ 16:9 + รายการ 3',
  render(s) { return popVideo(s); } });
reg({ id: 'popVideoGlass', family: 'work', title: 'หน้าต่างวิดีโอ · กระจก', sizes: ['small', 'wide', 'large'], cls: 'glass2',
  note: 'ผังเดียวกับกระดาษ บนกระจก', render(s) { return popVideo(s, true); } });
function popVideo(s, glass) {
  const tab = `<span class="pop-tab" ${glass ? 'style="background:var(--accent);color:#1B0A0E"' : ''}>วิดีโอ</span>`;
  const vid = (w, st) => `<div style="${st};border-radius:10px;overflow:hidden;position:relative;background:#222">${H.photo(w.seed, 'fill', 500, 300)}<div class="abs center" style="inset:0"><span style="width:34px;height:34px;border-radius:50%;background:rgba(255,255,255,.92);color:#111;display:grid;place-items:center">${ICO.play.replace('<svg', '<svg width="55%"')}</span></div><div class="abs" style="left:6px;bottom:6px">${viewTag(w, 9)}</div></div>`;
  const li = w => `<div class="row" style="gap:8px"><div style="width:44px;height:30px;border-radius:5px;overflow:hidden;flex:none">${H.photo(w.seed, '', 200, 140).replace('class="photo"', 'class="photo" style="height:100%;border-radius:0"')}</div><div class="col fill" style="gap:0"><b style="font-size:11px" class="ellip">${w.brand}</b><span class="dim" style="font-size:10px">${w.views} วิว</span></div></div>`;
  if (s === 'small') return `${tab}<div style="padding:26px 10px 10px;height:100%">${vid(WK[0], 'height:100%')}</div>`;
  if (s === 'wide') return `${tab}<div class="row" style="padding:26px 12px 12px;height:100%;gap:12px">${vid(WK[0], 'width:170px;height:100%')}<div class="col fill" style="gap:8px;justify-content:center">${li(WK[1])}${li(WK[2])}</div></div>`;
  return `${tab}<div class="col" style="padding:30px 14px 14px;height:100%;gap:10px">${vid(WK[0], 'height:186px')}<div class="col" style="gap:8px">${li(WK[1])}${li(WK[2])}${li(WK[3])}</div></div>`;
}

reg({ id: 'popWorkPaper', family: 'work', title: 'ผลงานสามใบ · กระดาษ', sizes: ['small', 'wide', 'large'], cls: 'pop-box',
  note: 'สติกเกอร์ขาว รูปผลงาน · เล็ก = 1 รูปใหญ่ · แนวนอน = 3 รูปเรียง · ใหญ่ = 3 รูป + ชื่อแบรนด์/ยอดใต้รูป + สรุป',
  render(s) { return popWork(s); } });
reg({ id: 'popWorkGlass', family: 'work', title: 'ผลงานสามใบ · กระจก', sizes: ['small', 'wide', 'large'], cls: 'glass2',
  note: 'ผังเดียวกับกระดาษ บนกระจก', render(s) { return popWork(s, true); } });
function popWork(s, glass) {
  const tab = `<span class="pop-tab" ${glass ? 'style="background:var(--accent);color:#1B0A0E"' : ''}>ผลงาน</span>`;
  const p = (w, big) => `<div class="col" style="flex:1;gap:4px;min-height:0">${big ? `<div style="border-radius:10px;overflow:hidden;flex:1;min-height:0;position:relative">${H.photo(w.seed, 'fill', 400, 500)}<div class="abs" style="top:6px;left:6px">${H.badge(w.k, 18)}</div></div>` : `<div style="border-radius:10px;overflow:hidden;aspect-ratio:1;position:relative">${H.photo(w.seed, 'fill', 400, 500)}<div class="abs" style="top:6px;left:6px">${H.badge(w.k, 18)}</div></div>`}${big ? cap(w, false) : ''}</div>`;
  if (s === 'small') return `${tab}<div style="padding:26px 10px 10px;height:100%"><div style="height:100%;border-radius:10px;overflow:hidden;position:relative">${H.photo(WK[0].seed, 'fill')}<div class="fade-b"></div><div class="abs" style="left:8px;bottom:8px;color:#fff;font-size:11px"><b>${WK[0].brand}</b></div></div></div>`;
  if (s === 'wide') return `${tab}<div class="row" style="padding:26px 12px 12px;height:100%;gap:8px">${WK.slice(0, 3).map(w => p(w, false)).join('')}</div>`;
  return `${tab}<div class="col" style="padding:30px 14px 14px;height:100%;gap:10px"><div class="row" style="gap:10px;flex:1;min-height:0;align-items:stretch">${WK.slice(0, 3).map(w => p(w, true)).join('')}</div><div class="row between" style="padding-top:8px;border-top:1px solid var(--line)"><span class="dim" style="font-size:11px">${D.track.done} ผลงาน · ${D.track.brands} แบรนด์</span>${H.verified()}</div></div>`;
}
