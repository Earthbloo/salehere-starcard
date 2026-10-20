/* w-brand.js — แบรนด์ที่เคยร่วมงาน */

reg({ id: 'proofBrandGrid', family: 'brand', title: 'แผงโลโก้ครบ', sizes: ['wide', 'large'], cls: 'glass pad',
  note: 'Trusted by N แบรนด์ + เหรียญโลโก้ · แนวนอน = หัว + 6 เหรียญแถวเดียว · ใหญ่ = หัวเซริฟ + 6 เหรียญใหญ่ 2 แถว + อุตสาหกรรม',
  render(s) {
    if (s === 'wide') return `<div class="col" style="height:100%;justify-content:space-between"><div class="row between"><span class="h-serif" style="font-size:17px"><i>Trusted by</i> <b class="num" style="font-size:22px">${D.track.brands}</b> แบรนด์</span>${H.verified()}</div><div class="row" style="justify-content:space-between;align-items:flex-start">${D.brands.map((b, i) => `<div class="center" style="gap:5px;width:52px">${H.coin(b, i, 46)}<span class="dim ellip" style="font-size:9.5px;max-width:52px">${b}</span></div>`).join('')}</div><div class="dim" style="font-size:11px">ทำงานจบ ${D.track.done} งาน · ER เฉลี่ย ${D.track.er} · ผ่านแคมเปญ Sale Here</div></div>`;
    return `<div class="col" style="height:100%;gap:14px"><div class="row between"><div><div class="h-serif" style="font-size:24px"><i>Trusted by</i></div><div class="h-kanit" style="font-size:36px;line-height:1">${D.track.brands} แบรนด์</div></div>${H.verified()}</div><div class="grid3" style="gap:10px;flex:1;align-content:center">${D.brands.map((b, i) => `<div class="center" style="gap:6px;padding:10px 6px;border-radius:14px;background:var(--glass)">${H.coin(b, i, 50)}<b style="font-size:11px" class="ellip">${b}</b><span class="dim" style="font-size:9.5px">${['Cosmetics', 'Supplement', 'Supplement', 'Skincare', 'Cosmetics', 'Cosmetics'][i]}</span></div>`).join('')}</div><div class="row between dim" style="font-size:11px"><span>ทำงานจบ ${D.track.done} งาน · ER เฉลี่ย ${D.track.er}</span><span>ผ่านแคมเปญ Sale Here</span></div></div>`;
  } });

reg({ id: 'proofBrandRail', family: 'brand', title: 'โลโก้เลื่อน', sizes: ['wide'], cls: 'glass',
  note: 'รางโลโก้วิ่งแนวนอน จางที่ขอบ — แนวนอนเท่านั้น',
  render() { return `<div class="col" style="height:100%;justify-content:center;gap:12px"><div class="row between" style="padding:0 16px">${H.label('Worked with')}<span class="dim" style="font-size:11px">${D.track.brands} แบรนด์ · ${D.track.done} งาน</span></div><div style="overflow:hidden;-webkit-mask:linear-gradient(90deg,transparent,#000 12%,#000 88%,transparent)"><div class="row" style="gap:14px;padding:0 16px;width:max-content">${[...D.brands, ...D.brands].map((b, i) => `<div class="row" style="gap:8px;padding:8px 14px 8px 8px;border-radius:999px;background:var(--glass2)">${H.coin(b, i % 6, 30)}<b style="font-size:12px;white-space:nowrap">${b}</b></div>`).join('')}</div></div></div>`; } });

reg({ id: 'proofBrandCoins', family: 'brand', title: 'เหรียญโลโก้', sizes: ['wide'], cls: 'glass pad',
  note: 'เหรียญซ้อนกันแบบ avatar stack + ข้อความ — แนวนอนเท่านั้น',
  render() { return `<div class="col" style="height:100%;justify-content:center;gap:12px"><div class="row" style="flex:none;justify-content:center">${D.brands.map((b, i) => `<div style="margin-left:${i ? -14 : 0}px;border-radius:50%;box-shadow:0 0 0 3px #2A0B12">${H.coin(b, i, 50)}</div>`).join('')}</div><div class="center" style="gap:2px"><b class="h-kanit" style="font-size:22px;white-space:nowrap">${D.track.brands} แบรนด์ไว้ใจ · ${D.track.done} งาน</b><span class="dim" style="font-size:11.5px">${D.brands.slice(0, 3).join(' · ')} และอีก ${D.track.brands - 3}</span></div></div>`; } });

reg({ id: 'typeMarquee', family: 'brand', title: 'แถบวิ่ง', sizes: ['wide'], cls: 'slab',
  note: 'แถบตัวอักษรวิ่ง ชื่อแบรนด์คั่นด้วยดาว 2 แถวสวนทาง — แนวนอนเท่านั้น',
  render() {
    const line = (sz, c) => `<div class="h-caps" style="font-size:${sz}px;white-space:nowrap;color:${c};letter-spacing:.08em">${[...D.brands, ...D.brands].map(b => b.toUpperCase()).join(' ★ ')}</div>`;
    return `<div class="col" style="height:100%;justify-content:center;gap:4px;overflow:hidden">${line(42, 'var(--ink)')}${line(42, 'transparent').replace('color:transparent', 'color:transparent;-webkit-text-stroke:1px var(--ink3)')}${line(42, 'var(--accent)')}</div><div class="abs corner-tr">${H.verified()}</div>`;
  } });
