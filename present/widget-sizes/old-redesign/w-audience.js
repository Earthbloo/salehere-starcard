/* w-audience.js — ข้อมูลผู้ติดตาม (อินไซต์) */

const A = D.audience;
const ageBars = big => A.ages.map(([l, p]) => `<div class="row" style="gap:8px"><span style="width:${big ? 44 : 36}px;font-size:${big ? 12 : 10.5}px" class="dim">${l}</span>${H.bar(p * 2.2, 'fill' + (big ? ' thick' : ''))}<b class="num" style="font-size:${big ? 14 : 12}px;width:34px;text-align:right">${p}%</b></div>`).join('');
const placeRows = (n, big) => A.places.slice(0, n).map(([l, p]) => `<div class="row between" style="font-size:${big ? 13 : 11.5}px;border-bottom:1px solid var(--line);padding:${big ? 5 : 3}px 0"><span class="row" style="gap:5px">${H.ico('pin', 'dim')}${l}</span><b class="num">${p}%</b></div>`).join('');

reg({ id: 'audienceLine', family: 'audience', title: 'ประโยคเดียว', sizes: ['wide', 'large'], cls: 'glass pad',
  note: 'สรุปผู้ชมเป็นประโยค · แนวนอน = ประโยคเซริฟ 2 บรรทัด + 3 ตัวเลขเล็ก · ใหญ่ = ประโยคยักษ์ + โดนัท + แถบอายุ',
  render(s) {
    const sentence = sz => `<div class="h-serif" style="font-size:${sz}px;line-height:1.15">ผู้ชมของฉัน <b>${A.female}%</b> เป็นผู้หญิง <i>อายุ 25–34</i> อยู่ใน<b>กรุงเทพฯ</b></div>`;
    if (s === 'wide') return `<div class="col" style="height:100%;justify-content:space-between"><div class="row between">${H.label('Audience')}${H.verified()}</div>${sentence(19)}<div class="row" style="gap:18px">${[[A.female + '%', 'ผู้หญิง'], ['41%', 'อายุ 25–34'], ['34%', 'กรุงเทพฯ']].map(([n, l]) => `<div class="row" style="gap:6px;align-items:baseline"><b class="num" style="font-size:16px">${n}</b><span class="dim" style="font-size:10.5px">${l}</span></div>`).join('')}</div></div>`;
    return `<div class="col" style="height:100%;gap:12px"><div class="row between">${H.label('Audience')}${H.verified()}</div>${sentence(28)}<div class="row" style="gap:16px;margin-top:4px">${H.donut(A.female, 86)}<div class="col fill" style="gap:7px">${ageBars(false)}</div></div><div class="row" style="gap:6px;margin-top:auto;flex-wrap:wrap">${A.places.map(([l, p]) => `<span class="chip outline" style="gap:4px;font-size:10.5px">${H.ico('pin')}${l} <b>${p}%</b></span>`).join('')}</div><div class="row between" style="padding-top:8px;border-top:1px solid var(--line);font-size:11px" class="dim"><span class="dim">การเข้าถึง ${A.reach.window}</span><b class="num" style="font-size:16px">${A.reach.n} <span style="font-size:11px;color:#6BD38B">${A.reach.delta}</span></b></div></div>`;
  } });

reg({ id: 'audienceSplit', family: 'audience', title: 'สัดส่วนผู้ชม', sizes: ['wide', 'large'], cls: 'glass pad',
  note: 'เพศเป็นโดนัท · แนวนอน = โดนัทซ้าย + ตัวเลข 3 เพศขวา · ใหญ่ = โดนัทใหญ่ + เพศ + ช่วงอายุ + เมือง',
  render(s) {
    const legend = big => [['ผู้หญิง', A.female, 'var(--accent)'], ['ผู้ชาย', A.male, 'var(--glass2)'], ['อื่น ๆ', A.other, 'var(--line)']].map(([l, p, c]) => `<div class="row between" style="font-size:${big ? 13 : 12}px"><span class="row" style="gap:6px"><i style="width:9px;height:9px;border-radius:50%;background:${c};display:inline-block"></i>${l}</span><b class="num" style="font-size:${big ? 18 : 15}px">${p}%</b></div>`).join('');
    if (s === 'wide') return `<div class="row" style="height:100%;gap:18px">${H.donut(A.female, 118)}<div class="col fill" style="gap:8px;justify-content:center">${H.label('Gender')}${legend(false)}</div></div>`;
    return `<div class="col" style="height:100%;gap:12px"><div class="row between">${H.label('Audience split')}${H.verified()}</div><div class="row" style="gap:18px">${H.donut(A.female, 120)}<div class="col fill" style="gap:8px;justify-content:center">${legend(true)}</div></div><div class="rule"></div><div class="row" style="gap:16px;flex:1"><div class="col fill" style="gap:6px"><span class="dim" style="font-size:10px;letter-spacing:.1em">ช่วงอายุ</span>${ageBars(false)}</div><div class="col" style="width:120px;gap:2px"><span class="dim" style="font-size:10px;letter-spacing:.1em">เมืองหลัก</span>${placeRows(3, false)}</div></div></div>`;
  } });

reg({ id: 'audienceAge', family: 'audience', title: 'ช่วงอายุผู้ชม', sizes: ['wide', 'large'], cls: 'glass pad',
  note: 'กราฟแท่งอายุ · แนวนอน = 4 แท่งตั้ง + ไฮไลต์ช่วงหลัก · ใหญ่ = แท่งใหญ่ + ตัวเลขทุกแท่ง + สรุป',
  render(s) {
    const bars = h => `<div class="row" style="align-items:flex-end;gap:10px;height:${h}px">${A.ages.map(([l, p], i) => `<div class="col fill" style="align-items:center;gap:4px;height:100%;justify-content:flex-end"><b class="num" style="font-size:12px;${i === 1 ? '' : 'opacity:.6'}">${p}%</b><div style="width:100%;height:${p / 41 * (h - 40)}px;border-radius:8px 8px 3px 3px;background:${i === 1 ? 'var(--accent)' : 'var(--glass2)'}"></div><span class="dim" style="font-size:10.5px">${l}</span></div>`).join('')}</div>`;
    if (s === 'wide') return `<div class="row" style="height:100%;gap:16px"><div class="col" style="width:110px;justify-content:center;gap:2px">${H.label('Age')}<b class="num" style="font-size:34px;line-height:1">25–34</b><span class="dim" style="font-size:11px">ช่วงอายุหลัก 41%</span></div><div class="fill">${bars(146)}</div></div>`;
    return `<div class="col" style="height:100%;gap:10px"><div class="row between">${H.label('Audience age')}${H.verified()}</div><div class="row between" style="align-items:flex-end"><b class="num" style="font-size:52px;line-height:1">25–34</b><span class="dim" style="font-size:12px;text-align:right">ช่วงอายุหลัก<br><b style="color:var(--ink)">41%</b> ของผู้ติดตาม</span></div><div class="fill">${bars(190)}</div><div class="dim" style="font-size:11px">เหมาะกับสินค้าวัยทำงาน · สกินแคร์ · ไลฟ์สไตล์</div></div>`;
  } });

reg({ id: 'audienceMap', family: 'audience', title: 'ผู้ชมในประเทศ', sizes: ['wide', 'large'], cls: 'glass pad',
  note: 'เมืองหลักของผู้ชม · แนวนอน = จุดแผนที่ + 3 เมือง · ใหญ่ = แผนที่ไทยใหญ่ + 4 เมืองพร้อมแถบ',
  render(s) {
    const map = (w, h) => `<div style="width:${w}px;height:${h}px;position:relative;flex:none"><svg viewBox="0 0 100 160" style="width:100%;height:100%"><path d="M38 6l14 4 10 10 6 18-6 10 4 14-8 12 2 26 8 18 6 22-10 14-8-10-6-20-8-18-4-26-10-14-6-18 2-20 8-14z" fill="var(--glass2)" stroke="var(--line)"/><circle cx="52" cy="78" r="9" fill="var(--accent)" opacity=".9"/><circle cx="60" cy="90" r="4" fill="var(--accent)" opacity=".6"/><circle cx="40" cy="34" r="4" fill="var(--accent)" opacity=".6"/><circle cx="66" cy="60" r="3" fill="var(--accent)" opacity=".5"/></svg></div>`;
    if (s === 'wide') return `<div class="row" style="height:100%;gap:14px">${map(84, 146)}<div class="col fill" style="justify-content:center;gap:4px">${H.label('Where they are')}${placeRows(3, false)}</div></div>`;
    return `<div class="col" style="height:100%;gap:10px"><div class="row between">${H.label('Where they are')}${H.verified()}</div><div class="row" style="gap:16px;flex:1">${map(150, 250)}<div class="col fill" style="justify-content:center;gap:10px"><div><b class="num" style="font-size:36px;line-height:1">${A.places[0][1]}%</b><div class="dim" style="font-size:11.5px">อยู่ในกรุงเทพฯ</div></div>${A.places.map(([l, p]) => `<div class="col" style="gap:3px"><div class="row between" style="font-size:12px"><span>${l}</span><b class="num">${p}%</b></div>${H.bar(p * 2.9)}</div>`).join('')}</div></div></div>`;
  } });

reg({ id: 'audiencePoster', family: 'audience', title: 'โปสเตอร์อินไซต์', sizes: ['large'], cls: 'glass pad',
  note: 'แผ่นอินไซต์ตั้ง: หัว "Audience" เซริฟ + รูปคนกลาง + กล่องข้อมูล 4 กล่องลอยรอบ — ใหญ่เท่านั้น',
  render() {
    const box = (st, inner) => `<div class="abs col" style="${st};padding:9px 10px;border-radius:12px;background:rgba(255,255,255,.9);color:#222;gap:4px;box-shadow:0 6px 16px rgba(0,0,0,.25)">${inner}</div>`;
    return `<div class="abs h-serif" style="left:16px;top:10px;font-size:46px;color:var(--accent);line-height:1"><i>Audience</i></div><div class="abs corner-tr">${H.verified()}</div><div class="abs" style="left:50%;top:48px;width:150px;height:300px;transform:translateX(-50%);border-radius:14px;overflow:hidden;-webkit-mask:linear-gradient(#000 85%,transparent)"><img src="${PH(2, 400, 800)}" alt=""></div>
    ${box('left:12px;top:92px;width:120px', `<span style="font-size:10px;font-weight:700">เมืองหลัก</span>${A.places.slice(0, 3).map(([l, p]) => `<div class="row between" style="font-size:10.5px"><span>${l}</span><b>${p}%</b></div>`).join('')}`)}
    ${box('right:12px;top:120px;width:118px', `<span style="font-size:10px;font-weight:700">ช่วงอายุ</span>${A.ages.slice(0, 3).map(([l, p]) => `<div class="row between" style="font-size:10.5px"><span>${l}</span><b>${p}%</b></div>`).join('')}`)}
    ${box('left:14px;bottom:16px;width:122px', `<span style="font-size:10px;font-weight:700">เพศ</span><div class="row" style="gap:8px;align-items:center">${H.donut(A.female, 40).replace('class="donut', 'style="--hole:#fff" class="donut')}<div style="font-size:10.5px;line-height:1.3"><b>${A.female}%</b> หญิง<br><b>${A.male}%</b> ชาย</div></div>`)}
    ${box('right:14px;bottom:28px;width:130px', `<div class="row between"><span style="font-size:10px;font-weight:700">การเข้าถึง · ${A.reach.window}</span>${H.badge('ig', 14)}</div><b class="num" style="font-size:24px">${A.reach.n}</b><span style="font-size:10px"><b style="color:#1B8A3A">${A.reach.delta}</b> · ใหม่ ${A.reach.fresh}</span>`)}`;
  } });

reg({ id: 'scrapStats', family: 'audience', title: 'สถิติผู้ชม', sizes: ['wide', 'large'], cls: 'pinkp',
  note: 'สถิติบนกระดาษสแครปบุ๊ก ลายมือ · แนวนอน = 3 ตัวเลขใหญ่ลายมือ · ใหญ่ = กราฟวาดมือ + ตัวเลข + โน้ต',
  render(s) {
    const big = (n, l) => `<div class="center" style="gap:0"><b class="h-kanit" style="font-size:30px;color:#C2185B;line-height:1">${n}</b><span class="doodle" style="font-size:14px">${l}</span></div>`;
    if (s === 'wide') return `<div class="col" style="height:100%;padding:14px 16px;justify-content:center;gap:8px"><div class="doodle" style="font-size:22px">my audience ✎</div><div class="scrap-paper row" style="padding:12px;justify-content:space-around;transform:rotate(-.5deg)">${big(A.female + '%', 'girls')}${big('25–34', 'age')}${big('BKK', 'city')}</div></div>`;
    return `<div class="col" style="height:100%;padding:16px;gap:10px"><div class="row between"><div class="doodle" style="font-size:30px">my audience ✎</div><span class="sticker" style="font-size:10.5px">${A.reach.n} reach</span></div><div class="scrap-paper" style="padding:14px;transform:rotate(-1deg);flex:1;display:flex;flex-direction:column;gap:10px"><div class="row" style="justify-content:space-around">${big(A.female + '%', 'girls')}${big('25–34', 'age')}${big('34%', 'bangkok')}</div><div class="row" style="align-items:flex-end;gap:10px;flex:1;min-height:120px;border-bottom:2px solid #4A1F2C;padding:0 10px">${A.ages.map(([l, p]) => `<div class="col fill" style="align-items:center;gap:3px;height:100%;justify-content:flex-end"><div style="width:70%;height:${p * 2.6}px;background:repeating-linear-gradient(45deg,#C2185B 0 3px,transparent 3px 6px);border:1.5px solid #C2185B;border-radius:3px 3px 0 0"></div><span class="doodle" style="font-size:11px">${l}</span></div>`).join('')}</div><div class="doodle" style="font-size:14px;text-align:right">mostly 25–34, bangkok girls ♡</div></div></div>`;
  } });
