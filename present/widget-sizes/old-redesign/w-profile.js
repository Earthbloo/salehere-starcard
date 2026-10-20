/* w-profile.js — หมวดโปรไฟล์ + แนะนำตัว */

/* ---------- โปรไฟล์ ---------- */

reg({ id: 'heroMinimal', family: 'profile', title: 'ชื่อมินิมอล', sizes: ['small', 'wide', 'large'], cls: 'glass pad',
  note: 'เล็ก = รูป+ชื่อ+แฮนเดิล · แนวนอน = รูปซ้าย ชื่อ+แท็กไลน์+สายงานขวา · ใหญ่ = รูปใหญ่กลาง + ผู้ติดตามรวม + สายงาน',
  render(s) {
    if (s === 'small') return `<div class="center" style="height:100%;gap:8px">${H.avatar(66, 'ring')}<div><div class="h-kanit" style="font-size:17px">${D.first}</div><div class="dim" style="font-size:11px">${D.handle}</div></div></div>`;
    if (s === 'wide') return `<div class="row" style="height:100%;gap:14px">${H.avatar(92, 'ring')}<div class="col fill" style="gap:5px"><div class="h-kanit" style="font-size:24px">${D.name}</div><div class="muted" style="font-size:12px">${D.tagline} · ${D.handle}</div><div class="chipwrap" style="margin-top:4px">${H.chips(D.cats, '', 3)}</div></div></div>`;
    return `<div class="center" style="height:100%;gap:12px">${H.avatar(132, 'ring')}<div><div class="h-kanit" style="font-size:30px">${D.name}</div><div class="muted" style="font-size:13px;margin-top:2px">${D.tagline}</div><div class="dim" style="font-size:12px">${D.handle} · ${D.city}</div></div><div class="chipwrap" style="justify-content:center">${H.chips(D.cats, 'lg')}</div><div class="row" style="gap:16px;margin-top:4px"><span class="num" style="font-size:22px">${D.total}</span><span class="dim" style="font-size:11px;letter-spacing:.1em">ผู้ติดตามรวม 3 ช่องทาง</span></div></div>`;
  } });

reg({ id: 'artTypeOver', family: 'profile', title: 'ตัวอักษรทับภาพ', sizes: ['wide', 'large'], cls: 'slab',
  note: 'รูปเต็มกรอบ ชื่อยักษ์ทับ · แนวนอน = ชื่อบรรทัดเดียวทับล่าง · ใหญ่ = ชื่อ 2 บรรทัดยักษ์ + แท็กไลน์ + แฮนเดิล',
  render(s) {
    const fade = `<div class="fade-b"></div>`;
    if (s === 'wide') return `${H.photo(2, 'fill', 900, 500)}${fade}<div class="abs" style="left:16px;right:16px;bottom:12px"><div class="h-caps" style="font-size:64px;color:#fff;text-shadow:0 2px 14px rgba(0,0,0,.4)">${D.en} <span style="color:var(--accent)">BEAUTY</span></div><div class="row between" style="margin-top:2px"><span style="font-size:12px;color:rgba(255,255,255,.8)">${D.tagline}</span><span class="dim" style="font-size:11px;color:rgba(255,255,255,.6)">${D.handle}</span></div></div>`;
    return `${H.photo(2, 'fill', 900, 900)}${fade}<div class="abs" style="top:14px;left:16px">${H.verified()}</div><div class="abs" style="left:16px;right:16px;bottom:16px"><div class="h-caps" style="font-size:96px;color:#fff;text-shadow:0 2px 18px rgba(0,0,0,.45)">${D.en}<br><span style="color:var(--accent)">BEAUTY</span></div><div class="row between" style="margin-top:6px;border-top:1px solid rgba(255,255,255,.3);padding-top:8px"><span style="font-size:13px;color:#fff">${D.tagline}</span><span style="font-size:12px;color:rgba(255,255,255,.7)">${D.handle} · ${D.city}</span></div></div>`;
  } });

reg({ id: 'artPortfolio', family: 'profile', title: 'โปสเตอร์พอร์ต', sizes: ['large'], cls: 'paper',
  note: 'แผ่นพิมพ์: คำยักษ์ PORTFOLIO เต็มความกว้าง คนยืนคร่อมคำ แถบชื่อใต้เท้า — มีแค่ใหญ่ (ผังตั้งเต็มแผ่น)',
  render() {
    return `<div class="abs" style="top:14px;left:16px;right:16px" class="row"><div class="row between"><span class="mono" style="color:var(--paper-ink2)">STAR CARD · 2569</span>${H.verified()}</div></div>
    <div class="abs" style="left:50%;top:60px;width:230px;height:290px;transform:translateX(-50%);border-radius:0 0 110px 110px;overflow:hidden;-webkit-mask:linear-gradient(#000 85%,transparent)"><img src="${PERSON}" style="filter:grayscale(1) contrast(1.1)" alt=""></div>
    <div class="abs h-caps" style="left:0;right:0;top:54px;text-align:center;font-size:118px;color:var(--paper-ink);letter-spacing:.02em;line-height:1;mix-blend-mode:multiply">PORT<br>FOLIO</div>
    <div class="abs" style="left:16px;right:16px;bottom:14px;background:var(--paper-ink);color:var(--paper);border-radius:12px;padding:10px 14px" class="row"><div class="row between"><div><div class="h-kanit" style="font-size:17px">${D.name}</div><div style="font-size:11px;opacity:.7">${D.tagline}</div></div><div class="h-serif" style="font-size:16px"><i>${D.handle}</i></div></div></div>`;
  } });

reg({ id: 'portfolioWindow', family: 'profile', title: 'หน้าต่างพอร์ต', sizes: ['large'], cls: 'white',
  note: 'หน้าต่าง Preview ของ macOS: แถบบน + คำเซริฟดำยักษ์ คนยืนบนฉากสตูดิโอเทา — ใหญ่เท่านั้น',
  render() {
    return `<div class="macbar"><i></i><i></i><i></i><span>${D.handle} — portfolio.png</span></div>
    <div class="abs" style="top:26px;left:0;right:0;bottom:0;background:linear-gradient(#E9E9EC,#CFCFD4)"></div>
    <div class="abs" style="left:50%;top:70px;width:220px;height:296px;transform:translateX(-50%);-webkit-mask:linear-gradient(#000 80%,transparent)"><img src="${PERSON}" alt=""></div>
    <div class="abs h-serif" style="left:0;right:0;top:44px;text-align:center;font-size:84px;font-weight:800;color:#111;line-height:.95;mix-blend-mode:multiply">${D.en}<br><i style="font-weight:400">Beauty</i></div>
    <div class="abs row between" style="left:14px;right:14px;bottom:12px;font-size:11px;color:#444"><span class="row" style="gap:4px;font-weight:600"><span style="width:8px;height:8px;border-radius:50%;background:#111;display:inline-block"></span>${D.name}</span><span class="row" style="gap:12px"><span>${D.cats.slice(0, 2).join(' · ')}</span><span style="color:#999">1 of 3</span></span></div>`;
  } });

reg({ id: 'portfolioGingham', family: 'profile', title: 'พอร์ตผ้าปิกนิก', sizes: ['large'], cls: 'paper',
  note: 'กระดาษครีม ขอบหยัก คำเซริฟแคบสีเลือดหมู คนยืนบนผ้าตารางฟ้า — ใหญ่เท่านั้น',
  render() {
    return `<div class="abs" style="inset:8px;border:2px dashed #B8392F;border-radius:16px"></div>
    <div class="abs h-serif" style="left:0;right:0;top:30px;text-align:center;font-size:70px;font-weight:800;color:#7A1B1B;line-height:.95;letter-spacing:-.02em">${D.en}<br><i style="font-weight:400;font-size:40px">portfolio</i></div>
    <div class="abs" style="left:18px;right:18px;bottom:18px;height:132px;border-radius:10px;background:repeating-linear-gradient(0deg,#BFD8EC 0 12px,#DCEBF5 12px 24px),repeating-linear-gradient(90deg,rgba(100,150,200,.35) 0 12px,transparent 12px 24px);background-blend-mode:multiply"></div>
    <div class="abs" style="left:50%;top:92px;width:214px;height:270px;transform:translateX(-50%)"><img src="${PERSON}" alt=""></div>
    <div class="abs sticker" style="left:22px;bottom:30px;transform:rotate(-5deg);background:#7A1B1B;color:#FBF6EC">${D.cats[0]}</div>
    <div class="abs sticker" style="right:22px;bottom:40px;transform:rotate(4deg)">${D.handle}</div>`;
  } });

reg({ id: 'popHeroPaper', family: 'profile', title: 'ป้ายชื่อ · กระดาษ', sizes: ['small', 'wide', 'large'], cls: 'pop-box',
  note: 'สติกเกอร์ขาวมีป้ายหัวข้อแดง · เล็ก = รูปสี่เหลี่ยม+ชื่อ · แนวนอน = รูปซ้าย ชื่อ+3 ช่องทางขวา · ใหญ่ = รูปใหญ่ + ชื่อ + ชิป + ผู้ติดตาม',
  render(s) { return popHero(s, 'paper'); } });
reg({ id: 'popHeroGlass', family: 'profile', title: 'ป้ายชื่อ · กระจก', sizes: ['small', 'wide', 'large'], cls: 'glass2',
  note: 'ผังเดียวกับกระดาษ แต่แผ่นเป็นกระจกของการ์ด ป้ายหัวข้อเป็นสีเน้น',
  render(s) { return popHero(s, 'glass'); } });
function popHero(s, skin) {
  const tab = `<span class="pop-tab" ${skin === 'glass' ? 'style="background:var(--accent);color:#1B0A0E"' : ''}>ชื่อ</span>`;
  if (s === 'small') return `${tab}<div class="center" style="height:100%;padding:22px 12px 10px;gap:8px">${H.avatar(74, 'sq')}<div class="h-kanit" style="font-size:16px">${D.first} ${D.name.split(' ')[1]}</div><div class="dim" style="font-size:10.5px">${D.handle}</div></div>`;
  if (s === 'wide') return `${tab}<div class="row" style="height:100%;padding:26px 14px 12px;gap:14px">${H.avatar(112, 'sq')}<div class="col fill" style="gap:6px"><div class="h-kanit" style="font-size:22px">${D.name}</div><div class="muted" style="font-size:11.5px">${D.tagline}</div>${H.socialRows(3, 'bare')}</div></div>`;
  return `${tab}<div style="padding:30px 16px 14px;height:100%;display:flex;flex-direction:column;justify-content:space-between"><div class="row" style="gap:14px">${H.avatar(124, 'sq')}<div class="col fill" style="gap:6px"><div class="h-kanit" style="font-size:26px">${D.name}</div><div class="muted" style="font-size:12px">${D.tagline}</div><div class="dim" style="font-size:12px">${D.handle} · ${D.city}</div><div class="chipwrap" style="margin-top:4px">${H.chips(D.cats, '', 3)}</div></div></div><div style="font-size:12.5px;line-height:1.45;color:var(--ink2)">${D.about}</div><div class="rule"></div><div class="stat-cols divided">${['ig', 'tt', 'yt'].map(k => H.stat(k, 26)).join('')}</div><div class="row between" style="padding-top:6px;border-top:1px solid var(--line)"><span class="dim" style="font-size:11px">${D.track.done} ผลงาน · ${D.track.brands} แบรนด์</span>${H.verified()}</div></div>`;
}

reg({ id: 'scrapFolder', family: 'profile', title: 'แฟ้มสแครปบุ๊ก', sizes: ['wide', 'large'], cls: 'pinkp',
  note: 'กระดาษชมพูตาราง + รูปโพลารอยด์ + เทป · แนวนอน = โพลารอยด์ซ้าย ชื่อ/ลายมือขวา · ใหญ่ = โพลารอยด์ใหญ่ + ชิป + ลายมือ 2 บรรทัด',
  render(s) {
    if (s === 'wide') return `<div class="row" style="height:100%;padding:14px;gap:16px"><div class="polaroid" style="width:120px;transform:rotate(-4deg)">${H.photo(1, '', 400, 400)}<small>me ♡</small><span class="tape" style="top:-8px;left:30px"></span></div><div class="col fill" style="gap:4px"><div class="doodle" style="font-size:30px">${D.first}'s file</div><div class="h-kanit" style="font-size:18px">${D.name}</div><div style="font-size:11.5px;color:var(--ink2)">${D.tagline}</div><div class="chipwrap" style="margin-top:6px">${H.chips(D.cats, 'outline', 3)}</div></div></div>`;
    return `<div style="padding:16px;height:100%;display:flex;flex-direction:column;gap:10px"><div class="row between"><div class="doodle" style="font-size:34px">${D.first}'s file</div><span class="sticker" style="font-size:11px">STAR</span></div><div class="row" style="gap:14px;align-items:flex-start"><div class="polaroid" style="width:170px;transform:rotate(-3deg)">${H.photo(1, '', 500, 500)}<small>me ♡ 2569</small><span class="tape" style="top:-8px;left:50px"></span></div><div class="col fill" style="gap:6px;padding-top:8px"><div class="h-kanit" style="font-size:22px;line-height:1.1">${D.name}</div><div style="font-size:12px;color:var(--ink2)">${D.tagline}</div><div class="doodle" style="font-size:18px;margin-top:4px">"${D.styles[4]}"</div><div class="chipwrap">${H.chips(D.cats, 'outline')}</div></div></div><div class="row between" style="margin-top:auto;font-size:11px;color:var(--ink2)"><span>${D.handle}</span><span>${D.city}</span>${H.verified()}</div></div>`;
  } });

reg({ id: 'scrapBadge', family: 'profile', title: 'บัตรครีเอเตอร์', sizes: ['small', 'large'], cls: 'pinkp',
  note: 'บัตรพนักงานห้อยสาย · เล็ก = บัตรเต็มใบ (รูป ชื่อ แฮนเดิล) · ใหญ่ = บัตรใหญ่ + สายคล้อง + ช่องข้อมูลหลัง',
  render(s) {
    const card = (w, big) => `<div class="scrap-paper center" style="width:${w}px;padding:${big ? 16 : 10}px 10px ${big ? 14 : 10}px;gap:${big ? 8 : 5}px;border-radius:12px"><div style="width:${big ? 50 : 28}px;height:6px;border-radius:999px;background:#E6C5CF"></div>${H.avatar(big ? 96 : 60, 'sq')}<div class="h-kanit" style="font-size:${big ? 20 : 14}px">${D.name}</div><div class="mono" style="font-size:${big ? 11 : 9}px;color:#8A6A74">CREATOR · ${D.seal.no}</div>${big ? `<div class="chipwrap" style="justify-content:center">${H.chips(D.cats, 'outline', 3)}</div>` : ''}</div>`;
    if (s === 'small') return `<div class="center" style="height:100%;padding:10px"><div style="width:4px;height:14px;background:#C2185B;margin-bottom:-4px"></div>${card(140, false)}</div>`;
    return `<div class="abs" style="left:50%;top:0;width:30px;height:70px;background:repeating-linear-gradient(0deg,#C2185B 0 6px,#E57B9E 6px 12px);transform:translateX(-50%)"></div><div class="center" style="height:100%;padding-top:50px;gap:14px">${card(250, true)}<div class="row" style="gap:16px;font-size:12px;color:var(--ink2)"><span>${D.handle}</span><span>·</span><span>${D.contact.line}</span></div></div><div class="doodle abs" style="right:18px;top:28px;font-size:22px;transform:rotate(8deg)">hi!</div>`;
  } });

/* ---------- แนะนำตัว ---------- */

reg({ id: 'aboutText', family: 'intro', title: 'แนะนำตัว', sizes: ['small', 'wide', 'large'], cls: 'glass pad',
  note: 'เล็ก = คำโปรย 3 บรรทัดใหญ่ · แนวนอน = ป้าย + ย่อหน้าเต็ม + สายงาน · ใหญ่ = พาดหัวเซริฟ + ย่อหน้า + 3 จุดเด่น (สไตล์งาน)',
  render(s) {
    if (s === 'small') return `<div class="col" style="height:100%;justify-content:space-between">${H.label('About')}<div class="h-serif clamp3" style="font-size:17px;line-height:1.3"><i>${D.about}</i></div><div class="dim" style="font-size:10.5px">— ${D.first}</div></div>`;
    if (s === 'wide') return `<div class="col" style="height:100%;justify-content:space-between"><div class="row between">${H.label('About me')}${H.verified()}</div><div style="font-size:15px;line-height:1.45">${D.about}</div><div class="chipwrap">${H.chips(D.cats, '', 4)}</div></div>`;
    return `<div class="col" style="height:100%;justify-content:space-between"><div class="row between">${H.label('About me')}${H.verified()}</div><div class="h-serif" style="font-size:40px;line-height:1.02"><i>Honest</i> skincare,<br>real skin.</div><div style="font-size:14.5px;line-height:1.5;color:var(--ink2)">${D.about}</div><div class="rule"></div><div class="grid3">${D.styles.slice(0, 3).map((t, i) => `<div class="col" style="gap:2px"><span class="num" style="font-size:20px;color:var(--accent)">0${i + 1}</span><span style="font-size:12.5px">${t}</span></div>`).join('')}</div><div class="chipwrap">${H.chips(D.cats, 'outline')}</div></div>`;
  } });

reg({ id: 'aboutEditorial', family: 'intro', title: 'หน้าแนะนำตัว', sizes: ['wide', 'large'], cls: 'paper',
  note: 'หน้านิตยสาร: เลขหน้า + พาดหัวเซริฟ + คอลัมน์ · แนวนอน = พาดหัวซ้าย คอลัมน์ขวา · ใหญ่ = พาดหัวเต็ม + 2 คอลัมน์ + รูปเล็ก',
  render(s) {
    if (s === 'wide') return `<div class="row" style="height:100%;padding:16px;gap:16px"><div class="col" style="width:150px;justify-content:space-between"><span class="mono">No. 01 — ABOUT</span><div class="h-serif" style="font-size:30px;line-height:1"><i>Meet</i><br><b style="font-weight:800">${D.en}</b></div></div><div class="vrule"></div><div class="col fill" style="font-size:12px;line-height:1.5;justify-content:center"><p>${D.about}</p><p class="dim" style="margin-top:6px">${D.cats.join(' · ')}</p></div></div>`;
    return `<div style="padding:18px;height:100%;display:flex;flex-direction:column;gap:12px"><div class="row between mono"><span>No. 01 — ABOUT</span><span>${D.city.toUpperCase()}</span></div><div class="h-serif" style="font-size:52px;line-height:.95"><i>Meet</i> <b style="font-weight:800">${D.en}</b><br><span style="font-size:22px">${D.tagline}</span></div><div class="rule" style="background:var(--paper-ink)"></div><div class="row" style="gap:14px;align-items:flex-start;flex:1"><div class="col fill" style="font-size:12.5px;line-height:1.5"><p><b style="font-family:var(--f-serif);font-size:30px;float:left;line-height:.8;margin:4px 6px 0 0">ร</b>${D.about.slice(1)}</p><p class="dim" style="margin-top:8px">${D.styles.slice(0, 3).join(' · ')}</p></div><div class="photo" style="width:96px;height:124px;border-radius:4px"><img src="${PH(1, 300, 400)}" alt=""></div></div><div class="row between" style="font-size:11px;color:var(--paper-ink2)"><span>${D.handle}</span>${H.verified()}</div></div>`;
  } });

reg({ id: 'aboutBehind', family: 'intro', title: 'ชื่อหลังภาพ', sizes: ['wide', 'large'], cls: 'slab',
  note: 'ชื่อยักษ์อยู่หลังตัวคน (คนคร่อมตัวอักษร) · แนวนอน = ชื่อบรรทัดเดียวขวา คนซ้าย · ใหญ่ = ชื่อยักษ์ 2 บรรทัดกลาง + คำโปรยล่าง',
  render(s) {
    if (s === 'wide') return `<div class="abs" style="left:16px;top:0;width:130px;height:100%;-webkit-mask:linear-gradient(#000 85%,transparent)"><img src="${PERSON}" alt=""></div><div class="abs h-caps" style="right:14px;top:50%;transform:translateY(-50%);font-size:110px;color:rgba(255,255,255,.14);letter-spacing:.02em;mix-blend-mode:overlay">${D.en}</div><div class="abs" style="left:160px;right:16px;top:50%;transform:translateY(-50%)" class="col"><div class="h-serif" style="font-size:24px;line-height:1.05"><i>${D.tagline}</i></div><div class="muted" style="font-size:12px;margin-top:8px;line-height:1.45">${D.about}</div></div>`;
    return `<div class="abs" style="left:50%;top:40px;width:250px;height:300px;transform:translateX(-50%);-webkit-mask:linear-gradient(#000 80%,transparent)"><img src="${PERSON}" alt=""></div><div class="abs h-caps" style="left:0;right:0;top:30px;text-align:center;font-size:118px;line-height:.9;color:rgba(255,255,255,.55);mix-blend-mode:overlay;letter-spacing:.02em">${D.en}<br>BEAUTY</div><div class="abs" style="left:18px;right:18px;bottom:16px" class="col"><div class="row between" style="align-items:flex-end"><div><div class="h-serif" style="font-size:26px"><i>${D.name}</i></div><div class="muted" style="font-size:12px;margin-top:4px;max-width:230px;line-height:1.4">${D.about}</div></div>${H.verified()}</div></div>`;
  } });

reg({ id: 'scrapAbout', family: 'intro', title: 'รู้จักตัวฉัน', sizes: ['small', 'wide'], cls: 'pinkp',
  note: 'โน้ตลายมือบนกระดาษชมพู · เล็ก = คำโปรยลายมือ 2 บรรทัด · แนวนอน = หัว "about me" + ย่อหน้า + สติกเกอร์',
  render(s) {
    if (s === 'small') return `<div style="padding:16px;height:100%" class="col"><div class="doodle" style="font-size:22px">about me ✎</div><div class="h-kanit clamp3" style="font-size:14px;line-height:1.35;margin-top:6px;font-weight:600">${D.about}</div><span class="tape" style="top:-6px;right:20px;left:auto;transform:rotate(8deg)"></span></div>`;
    return `<div class="row" style="padding:16px;height:100%;gap:16px"><div class="col" style="width:110px;justify-content:center;gap:8px"><div class="doodle" style="font-size:30px;line-height:1">about<br>me ✎</div><span class="sticker" style="font-size:11px;align-self:flex-start">${D.cats[0]}</span></div><div class="scrap-paper fill" style="padding:12px 14px;font-size:13px;line-height:1.5;transform:rotate(1deg)">${D.about}<div class="doodle" style="font-size:16px;margin-top:6px;text-align:right">— ${D.first}</div></div></div>`;
  } });

reg({ id: 'scrapInfo', family: 'intro', title: 'บัตรข้อมูลของฉัน', sizes: ['small', 'large'], cls: 'pinkp',
  note: 'บัตรแนวตั้งมีช่องกรอก · เล็ก = 3 ช่อง (ชื่อ·สายงาน·เมือง) · ใหญ่ = 6 ช่อง + รูป + ลายเซ็น',
  render(s) {
    const field = (k, v) => `<div class="col" style="gap:1px;border-bottom:1px dashed #D9B7C2;padding-bottom:4px"><span class="mono" style="font-size:9px;color:#A7808C">${k}</span><b style="font-size:12.5px">${v}</b></div>`;
    if (s === 'small') return `<div class="scrap-paper col" style="margin:12px;height:calc(100% - 24px);padding:12px;gap:8px"><div class="doodle" style="font-size:16px">my info</div>${field('NAME', D.name)}${field('NICHE', D.cats.slice(0, 2).join(' · '))}${field('CITY', D.city)}</div>`;
    return `<div class="scrap-paper" style="margin:16px;height:calc(100% - 32px);padding:16px;display:flex;flex-direction:column;gap:10px;transform:rotate(-1deg)"><div class="row between"><div class="doodle" style="font-size:26px">my info card</div>${H.avatar(54, 'sq')}</div><div class="grid2" style="gap:10px 16px;flex:1;align-content:space-evenly">${field('NAME', D.name)}${field('HANDLE', D.handle)}${field('NICHE', D.cats.slice(0, 2).join(' · '))}${field('CITY', D.city)}${field('STYLE', D.styles[4])}${field('REPLY', D.contact.reply)}${field('LINE', D.contact.line)}${field('PHONE', D.contact.phone)}</div><div class="row between" style="margin-top:auto"><span class="doodle" style="font-size:22px">${D.first} ♡</span>${H.verified()}</div></div>`;
  } });
