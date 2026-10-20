/* w-channels.js — ช่องทาง / ผู้ติดตาม */

reg({ id: 'statGiant', family: 'channels', title: 'ตัวเลขยักษ์', sizes: ['small', 'wide', 'large'], cls: 'glass pad',
  note: 'เล็ก = ยอดรวมตัวเดียว · แนวนอน = ยอดรวมซ้าย + 3 ช่องเล็กขวา · ใหญ่ = ยอดรวมยักษ์ + 3 ช่องพร้อมแถบสัดส่วน + ER',
  render(s) {
    if (s === 'small') return `<div class="col" style="height:100%;justify-content:space-between">${H.label('Followers')}<div class="num" style="font-size:46px">${D.total}</div><div class="row" style="gap:4px">${['ig', 'tt', 'yt'].map(k => H.badge(k, 18)).join('')}<span class="dim" style="font-size:10.5px;margin-left:4px">3 ช่องทาง</span></div></div>`;
    if (s === 'wide') return `<div class="row" style="height:100%;gap:16px"><div class="col" style="justify-content:space-between;height:100%">${H.label('Total followers')}<div class="num" style="font-size:52px">${D.total}</div><div class="dim" style="font-size:11px">รวม 3 ช่องทาง · อัปเดต 2 ชม.</div></div><div class="vrule"></div><div class="col fill" style="gap:6px;justify-content:center">${H.socialRows(3, 'bare')}</div></div>`;
    return `<div class="col" style="height:100%;gap:10px"><div class="row between">${H.label('Total followers')}${H.verified()}</div><div class="num" style="font-size:88px;letter-spacing:-.04em">${D.total}</div><div class="dim" style="font-size:12px;margin-top:-6px">รวม 3 ช่องทาง · ยอดจากแพลตฟอร์ม</div><div class="stat-cols divided" style="margin:auto 0;padding:10px 0;border-top:1px solid var(--line);border-bottom:1px solid var(--line)">${['ig', 'tt', 'yt'].map(k => H.stat(k, 24)).join('')}</div><div class="col" style="gap:8px">${D.socials.map(x => `<div class="row" style="gap:10px">${H.badge(x.k, 24)}<span style="width:70px;font-size:12px">${x.name}</span>${H.bar(Math.round(x.raw / 3205), 'fill')}<b class="num" style="font-size:15px;width:56px;text-align:right">${x.n}</b><span class="dim" style="font-size:11px;width:40px;text-align:right">${x.er}</span></div>`).join('')}</div></div>`;
  } });

reg({ id: 'socialChips', family: 'channels', title: 'ผู้ติดตามแบบแถว', sizes: ['wide', 'large'], cls: 'glass pad',
  note: 'แถวช่องทาง: ไอคอน แฮนเดิล ยอด · แนวนอน = 3 แถวชิด · ใหญ่ = 3 แถวใหญ่ + ER/วิว ต่อแถว + ยอดรวมท้าย',
  render(s) {
    if (s === 'wide') return `<div class="col" style="height:100%;justify-content:space-between"><div class="row between">${H.label('Social')}${H.verified()}</div>${H.socialRows(3)}</div>`;
    return `<div class="col" style="height:100%;gap:10px"><div class="row between">${H.label('Social media')}${H.verified()}</div>${D.socials.map(x => `<div class="row" style="gap:12px;padding:10px 12px;border-radius:14px;background:var(--glass);flex:1">${H.badge(x.k, 34)}<div class="col fill" style="gap:1px"><b style="font-size:14px">${x.name}</b><span class="dim" style="font-size:11px">${x.handle}</span></div><div class="col" style="align-items:flex-end;gap:1px"><b class="num" style="font-size:22px">${x.n}</b><span class="dim" style="font-size:10.5px">ER ${x.er} · ${x.views} วิว</span></div></div>`).join('')}<div class="row between" style="margin-top:auto;padding-top:6px;border-top:1px solid var(--line)"><span class="dim" style="font-size:11px">รวม</span><b class="num" style="font-size:18px">${D.total}</b></div></div>`;
  } });

reg({ id: 'socialTiles', family: 'channels', title: 'ผู้ติดตามแบบชิป', sizes: ['wide'], cls: 'glass pad',
  note: 'ชิปแนวนอน 3 ใบ ใบละช่องทาง — แนวนอนเท่านั้น (ผังเตี้ย)',
  render() { return `<div class="col" style="height:100%;justify-content:center;gap:10px">${H.label('Followers')}<div class="grid3">${D.socials.map(x => `<div class="col" style="gap:6px;padding:10px;border-radius:14px;background:var(--glass2);align-items:flex-start">${H.badge(x.k, 24)}<b class="num" style="font-size:22px">${x.n}</b><span class="dim" style="font-size:10.5px">${x.handle}</span></div>`).join('')}</div></div>`; } });

reg({ id: 'statWrapped', family: 'channels', title: 'การ์ดสรุปยอด', sizes: ['wide', 'large'], cls: 'slab',
  note: 'สไตล์ Wrapped: พื้นเข้ม ตัวเลขสีสด · แนวนอน = ยอดรวม + ช่องเด่น 1 · ใหญ่ = 3 บล็อกสี (ช่องละสี) + ยอดรวม',
  render(s) {
    if (s === 'wide') return `<div class="row" style="height:100%;padding:16px;gap:14px"><div class="col fill" style="justify-content:space-between;height:100%"><span class="h-caps" style="font-size:20px;color:var(--accent)">MY 2569 WRAPPED</span><div class="num" style="font-size:54px;background:linear-gradient(90deg,#FF6A88,#FFB86B);-webkit-background-clip:text;color:transparent">${D.total}</div><span class="dim" style="font-size:11px">ผู้ติดตามรวม 3 ช่องทาง</span></div><div class="col" style="width:130px;padding:12px;border-radius:16px;background:#111;gap:4px">${H.badge('tt', 26)}<b class="num" style="font-size:24px">${soc('tt').n}</b><span class="dim" style="font-size:10.5px">ช่องทางเติบโตสูงสุด</span></div></div>`;
    return `<div style="padding:16px;height:100%;display:flex;flex-direction:column;gap:10px"><div class="row between"><span class="h-caps" style="font-size:26px;color:var(--accent)">MY 2569 WRAPPED</span>${H.verified()}</div><div class="grid3" style="flex:1">${[['ig', '#FF6A88'], ['tt', '#5AC8F0'], ['yt', '#FFB86B']].map(([k, c]) => `<div class="col" style="justify-content:space-between;padding:12px;border-radius:16px;background:${c};color:#111">${H.badge(k, 26)}<div><b class="num" style="font-size:28px;display:block">${soc(k).n}</b><span style="font-size:10.5px;opacity:.75">ER ${soc(k).er}</span></div></div>`).join('')}</div><div class="row between" style="padding:12px 14px;border-radius:14px;background:#111"><span style="font-size:12px" class="dim">รวมทุกช่องทาง</span><b class="num" style="font-size:30px;background:linear-gradient(90deg,#FF6A88,#FFB86B);-webkit-background-clip:text;color:transparent">${D.total}</b></div></div>`;
  } });

reg({ id: 'statPoster', family: 'channels', title: 'โปสเตอร์ผู้ติดตาม', sizes: ['wide', 'large'], cls: 'glass pad',
  note: 'พาดหัว "MY Social / MEDIA STATS" สองฟอนต์ + เส้นคั่น + 3 คอลัมน์ · ใหญ่เพิ่มแถว ER + ยอดวิวเฉลี่ย',
  render(s) {
    const head = sz => `<div class="center" style="gap:0"><div class="h-serif" style="font-size:${sz}px"><b>MY</b> <i>Social</i></div><div class="h-kanit" style="font-size:${sz * 1.1}px;margin-top:-4px">MEDIA STATS</div></div>`;
    if (s === 'wide') return `<div class="abs corner-tr">${H.verified()}</div><div class="col" style="height:100%;justify-content:space-between;padding-top:4px">${head(18)}<div class="rule" style="background:var(--accent);opacity:.6"></div>${H.statCols(24).replace('stat-cols', 'stat-cols divided')}</div>`;
    return `<div class="abs corner-tr">${H.verified()}</div><div class="col" style="height:100%;justify-content:space-between;padding-top:10px">${head(32)}<div class="rule" style="background:var(--accent);opacity:.6"></div>${H.statCols(38).replace('stat-cols', 'stat-cols divided')}<div class="grid3" style="text-align:center">${D.socials.map(x => `<span class="dim" style="font-size:11px">${x.handle}</span>`).join('')}</div><div class="rule"></div><div class="grid3" style="text-align:center">${D.socials.map(x => `<div class="col" style="gap:2px"><span class="dim" style="font-size:10px;letter-spacing:.1em">ENGAGEMENT</span><b class="num" style="font-size:22px">${x.er}</b><span class="dim" style="font-size:10.5px">${x.views} วิวเฉลี่ย</span></div>`).join('')}</div><div class="center"><span class="dim" style="font-size:11px">ยอดจากแพลตฟอร์ม · เชื่อมบัญชีแล้ว · รวม ${D.total}</span></div></div>`;
  } });

reg({ id: 'socialWindow', family: 'channels', title: 'หน้าต่างช่องทาง', sizes: ['wide'], cls: 'white',
  note: 'หน้าต่าง Mac แนวนอน: แถบบน + 3 แท็บช่องทาง ยอดใหญ่ — แนวนอนเท่านั้น',
  render() { return `<div class="macbar"><i></i><i></i><i></i><span>${D.handle}</span></div><div class="row" style="padding:14px 16px;gap:10px;height:calc(100% - 26px)">${D.socials.map(x => `<div class="col fill" style="gap:4px;padding:10px 12px;border-radius:12px;background:#F4F4F6;height:100%;justify-content:space-between"><div class="row" style="gap:6px">${H.badge(x.k, 20)}<span style="font-size:11px;font-weight:600">${x.name}</span></div><b class="num" style="font-size:26px">${x.n}</b><span class="dim" style="font-size:10.5px">${x.handle}</span></div>`).join('')}</div>`; } });

reg({ id: 'socialGingham', family: 'channels', title: 'ช่องทางผ้าปิกนิก', sizes: ['wide'], cls: 'paper',
  note: 'ป้ายผ้าตารางแดง: ชื่อซ้าย ตัวเลข 3 ช่องขวาบนผ้า — แนวนอนเท่านั้น',
  render() { return `<div class="abs" style="inset:0;background:repeating-linear-gradient(0deg,rgba(184,57,47,.18) 0 10px,transparent 10px 20px),repeating-linear-gradient(90deg,rgba(184,57,47,.18) 0 10px,transparent 10px 20px)"></div><div class="row" style="position:relative;height:100%;padding:16px;gap:14px"><div class="col" style="width:120px;justify-content:center"><div class="h-serif" style="font-size:30px;color:#7A1B1B;line-height:1"><i>Follow</i><br><b style="font-weight:800">${D.en}</b></div></div><div class="row fill" style="gap:8px">${D.socials.map(x => `<div class="center fill scrap-paper" style="padding:10px 6px;gap:4px;box-shadow:none;border:1.5px solid #7A1B1B">${H.badge(x.k, 22)}<b class="num" style="font-size:22px;color:#7A1B1B">${x.n}</b><span style="font-size:9.5px;color:#8A6A74">${x.short}</span></div>`).join('')}</div></div>`; } });

reg({ id: 'popStatsGlass', family: 'channels', title: 'ผู้ติดตามสามช่อง · สติกเกอร์', sizes: ['wide'], cls: 'glass2',
  note: 'แผ่นกระจกมีป้ายหัวข้อ · 3 คอลัมน์ธง+ตัวเลข — แนวนอนเท่านั้น',
  render() { return `<span class="pop-tab" style="background:var(--accent);color:#1B0A0E">ผู้ติดตาม</span><div class="col" style="height:100%;padding:30px 14px 14px;justify-content:center"><div class="stat-cols divided">${['ig', 'tt', 'yt'].map(k => H.stat(k, 26)).join('')}</div></div>`; } });

reg({ id: 'scrapKeyTab', family: 'channels', title: 'พวงกุญแจโซเชียล', sizes: ['small', 'large'], cls: 'pinkp',
  note: 'ป้ายพวงกุญแจห้อย · เล็ก = ป้ายเดียว (ช่องทางเด่น) · ใหญ่ = พวง 3 ป้ายห้อยจากห่วงเดียว',
  render(s) {
    const tag = (k, big) => `<div class="scrap-paper col" style="width:${big ? 100 : 118}px;padding:${big ? 14 : 12}px 10px 10px;align-items:center;gap:6px;border-radius:14px 14px 10px 10px;position:relative"><span style="position:absolute;top:5px;width:8px;height:8px;border-radius:50%;background:var(--pink)"></span>${H.badge(k, big ? 30 : 34)}<b class="num" style="font-size:${big ? 20 : 24}px">${soc(k).n}</b><span style="font-size:9.5px;color:#8A6A74">${soc(k).handle}</span></div>`;
    if (s === 'small') return `<div class="center" style="height:100%;padding-top:14px;gap:0"><div style="width:22px;height:22px;border:3px solid #C2185B;border-radius:50%"></div><div style="width:2px;height:12px;background:#C2185B"></div>${tag('tt', false)}</div>`;
    return `<div class="center" style="height:100%;gap:0;padding-top:20px"><div style="width:34px;height:34px;border:4px solid #C2185B;border-radius:50%"></div><div class="row" style="align-items:flex-start;gap:14px;margin-top:-4px">${['ig', 'tt', 'yt'].map((k, i) => `<div class="center" style="gap:0;transform:rotate(${(i - 1) * 7}deg);transform-origin:top center"><div style="width:2px;height:${30 + Math.abs(i - 1) * 14}px;background:#C2185B"></div>${tag(k, true)}</div>`).join('')}</div><div class="doodle" style="font-size:22px;margin-top:auto;padding-bottom:16px">follow me ♡ ${D.total}</div></div>`;
  } });

reg({ id: 'scrapFeed', family: 'channels', title: 'ฟีดของฉัน', sizes: ['wide', 'large'], cls: 'pinkp',
  note: 'หน้าจอโปรไฟล์ IG จำลองบนกระดาษ · แนวนอน = หัวโปรไฟล์ + 3 ตัวเลข · ใหญ่ = หัว + ตัวเลข + กริดรูป 6',
  render(s) {
    const head = `<div class="row" style="gap:12px">${H.avatar(52, 'ring')}<div class="col fill" style="gap:2px"><b class="h-kanit" style="font-size:16px">${D.handle.slice(1)}</b><span style="font-size:11px;color:var(--ink2)">${D.tagline}</span></div></div>`;
    const nums = `<div class="grid3" style="text-align:center">${[[soc('ig').n, 'followers'], ['248', 'posts'], [soc('ig').er, 'engagement']].map(([n, l]) => `<div><b class="num" style="font-size:18px;display:block">${n}</b><span style="font-size:10px;color:#8A6A74">${l}</span></div>`).join('')}</div>`;
    if (s === 'wide') return `<div class="scrap-paper col" style="margin:12px;height:calc(100% - 24px);padding:12px 14px;gap:10px;justify-content:center;transform:rotate(-.5deg)">${head}${nums}</div>`;
    return `<div class="scrap-paper col" style="margin:14px;height:calc(100% - 28px);padding:14px;gap:10px;transform:rotate(-.5deg)">${head}${nums}<div class="grid3" style="gap:4px;flex:1">${[11, 12, 13, 14, 15, 1].map(sd => H.photo(sd, '', 300, 300).replace('class="photo"', 'class="photo" style="border-radius:3px;aspect-ratio:1"')).join('')}</div><span class="tape" style="top:-6px;left:40%"></span></div>`;
  } });
