/* w-contact.js — ติดต่อ */

const C = D.contact;
const crow = (k, v, big) => `<div class="row" style="gap:${big ? 10 : 8}px"><span class="sbadge" style="--s:${big ? 30 : 24}px;background:var(--glass2);color:var(--ink)">${ICO[k]}</span><span style="font-size:${big ? 14 : 12.5}px;font-weight:600" class="ellip">${v}</span></div>`;

reg({ id: 'contactCard', family: 'contact', title: 'นามบัตร', sizes: ['small', 'wide', 'large'], cls: 'glass pad',
  note: 'เล็ก = ชื่อ + ไลน์ + โทร (2 บรรทัด) · แนวนอน = ชื่อ/บทบาทซ้าย 3 ช่องทางขวา · ใหญ่ = นามบัตรเต็ม + QR + เวลาตอบกลับ',
  render(s) {
    if (s === 'small') return `<div class="col" style="height:100%;justify-content:space-between">${H.label('Contact')}<div><div class="h-kanit" style="font-size:17px">${D.name}</div><div class="dim" style="font-size:10.5px">ติดต่อโดยตรง</div></div><div class="col" style="gap:6px">${crow('line', C.line)}${crow('phone', C.phone)}</div></div>`;
    if (s === 'wide') return `<div class="row" style="height:100%;gap:16px"><div class="col" style="width:150px;justify-content:space-between;height:100%">${H.label('Contact')}<div><div class="h-kanit" style="font-size:20px;line-height:1.1">${D.name}</div><div class="dim" style="font-size:11px;margin-top:3px">ติดต่อโดยตรง · ไม่ผ่านผู้จัดการ</div></div><span class="chip outline" style="font-size:10px">${C.reply}</span></div><div class="vrule"></div><div class="col fill" style="justify-content:center;gap:9px">${crow('phone', C.phone)}${crow('mail', C.email)}${crow('line', C.line)}</div></div>`;
    return `<div class="col" style="height:100%;gap:12px"><div class="row between">${H.label('Contact')}${H.verified()}</div><div class="row" style="gap:14px">${H.avatar(70, 'ring')}<div class="col fill" style="gap:3px"><div class="h-kanit" style="font-size:24px;line-height:1.05">${D.name}</div><div class="muted" style="font-size:12px">${D.tagline}</div><div class="dim" style="font-size:11px">ติดต่อโดยตรง · ไม่ผ่านผู้จัดการ</div></div></div><div class="rule"></div><div class="row" style="gap:14px;flex:1"><div class="col fill" style="gap:10px;justify-content:center">${crow('phone', C.phone, true)}${crow('mail', C.email, true)}${crow('line', C.line, true)}${crow('web', C.web, true)}</div>${H.qr(11, 'lg')}</div><div class="row between dim" style="font-size:11px"><span>${C.reply}</span><span>สแกนเพื่อบันทึกรายชื่อ</span></div></div>`;
  } });

reg({ id: 'contactQR', family: 'contact', title: 'คิวอาร์การ์ด', sizes: ['small', 'large'], cls: 'white',
  note: 'QR เป็นพระเอก · เล็ก = QR เต็ม + ไลน์ · ใหญ่ = QR ใหญ่ + ชื่อ + 3 ช่องทาง + คำชวนสแกน',
  render(s) {
    if (s === 'small') return `<div class="center" style="height:100%;gap:8px">${H.qr(11, 'lg').replace('class="qr lg"', 'class="qr lg" style="width:108px;box-shadow:inset 0 0 0 1px #E6E6E6"')}<div class="row" style="gap:5px;font-size:11px;font-weight:600">${H.ico('line')}${C.line}</div></div>`;
    return `<div class="col" style="height:100%;padding:18px;gap:12px;align-items:center"><div class="row between" style="width:100%">${H.label('Scan to contact')}${H.verified()}</div>${H.qr(13, 'lg').replace('class="qr lg"', 'class="qr lg" style="width:170px;box-shadow:inset 0 0 0 1px #E6E6E6"')}<div class="center" style="gap:2px"><div class="h-kanit" style="font-size:20px">${D.name}</div><div class="dim" style="font-size:11.5px">${D.tagline}</div></div><div class="row" style="gap:8px;margin-top:auto;width:100%">${[['line', C.line], ['phone', C.phone], ['mail', 'อีเมล']].map(([k, v]) => `<span class="chip outline fill" style="justify-content:center;gap:5px;font-size:11px">${H.ico(k)}${v}</span>`).join('')}</div></div>`;
  } });

reg({ id: 'contactBar', family: 'contact', title: 'แถบติดต่อ', sizes: ['wide'], cls: 'glass',
  note: 'แถบแนวนอน 3 ช่องทางเรียงเป็นปุ่ม — แนวนอนเท่านั้น (ลอยกลางกรอบ)',
  render() { return `<div class="col" style="height:100%;justify-content:center;padding:0 16px;gap:10px"><div class="row between">${H.label('Contact')}<span class="dim" style="font-size:11px">${C.reply}</span></div><div class="grid2" style="gap:8px">${[['line', C.line], ['phone', C.phone]].map(([k, v]) => `<div class="row" style="gap:8px;padding:10px 12px;border-radius:12px;background:var(--glass2);min-width:0">${H.ico(k)}<b style="font-size:13px" class="ellip">${v}</b></div>`).join('')}<div class="row" style="gap:8px;padding:10px 12px;border-radius:12px;background:var(--glass2);grid-column:1/3;min-width:0">${H.ico('mail')}<b style="font-size:13px" class="ellip">${C.email}</b><span class="dim" style="margin-left:auto;font-size:11px">${C.web}</span></div></div></div>`; } });

reg({ id: 'contactStack', family: 'contact', title: 'สามบรรทัด', sizes: ['small', 'wide', 'large'], cls: 'glass pad',
  note: 'ช่องทางเรียงเป็นบรรทัดใหญ่ · เล็ก = 3 บรรทัดชิด · แนวนอน = 3 บรรทัดใหญ่ + หัวซ้าย · ใหญ่ = 4 บรรทัดยักษ์ ตัวหนังสือใหญ่อ่านจากไกล',
  render(s) {
    const line = (k, v, sz) => `<div class="row" style="gap:10px;padding:${sz > 16 ? 10 : 4}px 0;border-bottom:1px solid var(--line)">${H.ico(k, 'dim')}<b style="font-size:${sz}px;font-family:var(--f-head);font-weight:600" class="ellip">${v}</b></div>`;
    if (s === 'small') return `<div class="col" style="height:100%;justify-content:center;gap:2px">${line('line', C.line, 13)}${line('phone', C.phone, 13)}${line('mail', C.email, 11)}</div>`;
    if (s === 'wide') return `<div class="row" style="height:100%;gap:18px"><div class="col" style="width:90px;justify-content:center"><div class="h-serif" style="font-size:24px;line-height:1"><i>Say</i><br><b style="font-weight:800">hello</b></div></div><div class="col fill" style="justify-content:center">${line('line', C.line, 16)}${line('phone', C.phone, 16)}${line('mail', C.email, 14)}</div></div>`;
    return `<div class="col" style="height:100%;gap:8px"><div class="row between"><div class="h-serif" style="font-size:36px;line-height:1"><i>Say</i> <b style="font-weight:800">hello</b></div>${H.verified()}</div><div class="col" style="flex:1;justify-content:center">${line('line', C.line, 24)}${line('phone', C.phone, 24)}${line('mail', C.email, 18)}${line('web', C.web, 18)}</div><div class="dim" style="font-size:11px">${C.reply} · ติดต่อโดยตรง</div></div>`;
  } });

reg({ id: 'contactLine', family: 'contact', title: 'ไลน์ตัวใหญ่', sizes: ['wide'], cls: 'glass pad',
  note: 'ไอดีไลน์ตัวยักษ์ตัวเดียว + ปุ่มเขียว — แนวนอนเท่านั้น',
  render() { return `<div class="row" style="height:100%;gap:16px"><span class="sbadge" style="--s:64px;background:#06C755">${ICO.line}</span><div class="col fill" style="gap:2px">${H.label('LINE')}<b class="h-kanit" style="font-size:34px;line-height:1">${C.line}</b><span class="dim" style="font-size:11.5px">แอดแล้วทักได้เลย · ${C.reply}</span></div><span class="chip" style="background:#06C755;color:#fff;font-size:12px">เพิ่มเพื่อน</span></div>`; } });

reg({ id: 'contactChips', family: 'contact', title: 'ชิปช่องทาง', sizes: ['wide'], cls: 'glass pad',
  note: 'ชิปใหญ่ 4 ใบ 2 แถว — แนวนอนเท่านั้น',
  render() { return `<div class="col" style="height:100%;justify-content:center;gap:10px">${H.label('Contact')}<div class="chipwrap" style="gap:8px">${[['line', C.line], ['phone', C.phone], ['mail', C.email], ['web', C.web]].map(([k, v]) => `<span class="chip lg" style="gap:7px">${H.ico(k)}${v}</span>`).join('')}</div></div>`; } });

reg({ id: 'contactPoster', family: 'contact', title: 'โปสเตอร์ติดต่อ', sizes: ['wide', 'large'], cls: 'glass pad',
  note: 'พาดหัว "Contact / ME" + พิลล์ช่องทาง + รูปคน · แนวนอน = ข้อความซ้าย รูปขวา · ใหญ่ = รูปใหญ่เต็มขวา + 4 พิลล์ + QR',
  render(s) {
    const pill = (k, v) => `<span class="chip" style="gap:7px;font-size:11.5px;align-self:flex-start">${H.ico(k)}${v}</span>`;
    if (s === 'wide') return `<div class="row" style="height:100%;gap:12px"><div class="col fill" style="gap:6px;justify-content:center"><div><div class="h-serif" style="font-size:18px"><i>Contact</i></div><div class="h-kanit" style="font-size:28px;line-height:.95">ME</div></div>${pill('line', C.line)}${pill('phone', C.phone)}${pill('web', C.web)}</div><div style="width:130px;height:100%;border-radius:14px;overflow:hidden;position:relative;flex:none">${H.photo(1, 'fill', 400, 500)}</div></div>`;
    return `<div class="abs" style="right:0;top:0;bottom:0;width:170px;-webkit-mask:linear-gradient(90deg,transparent,#000 30%)"><img src="${PERSON}" alt=""></div><div class="col" style="height:100%;gap:8px;position:relative;width:190px"><div><div class="h-serif" style="font-size:26px"><i>Contact</i></div><div class="h-kanit" style="font-size:56px;line-height:.9">ME</div></div><div class="col" style="gap:7px;margin-top:6px">${pill('line', C.line)}${pill('phone', C.phone)}${pill('mail', C.email)}${pill('web', C.web)}</div><div class="row" style="gap:10px;margin-top:auto;align-items:flex-end">${H.qr(9)}<span class="dim" style="font-size:10.5px;line-height:1.3">${C.reply}<br>ติดต่อโดยตรง</span></div></div><div class="abs corner-tr">${H.verified()}</div>`;
  } });

reg({ id: 'scrapNote', family: 'contact', title: 'โน้ตติดต่อ', sizes: ['small', 'wide'], cls: 'pinkp',
  note: 'โน้ตกระดาษเหลืองลายมือ · เล็ก = ไลน์ + โทร ลายมือ · แนวนอน = โน้ต 2 แผ่นเอียง (ไลน์/โทร · อีเมล/เว็บ)',
  render(s) {
    const note = (lines, st) => `<div style="${st};background:#FFF3A8;padding:12px 14px;box-shadow:0 4px 10px rgba(0,0,0,.18);color:#5A4A1E;font-family:var(--f-script);line-height:1.15">${lines.map(([k, v], i) => `<div style="font-size:${i ? 15 : 20}px"><span style="font-family:var(--f-ui);font-size:10px;letter-spacing:.1em;opacity:.6">${k}</span><br>${v}</div>`).join('')}<span class="tape" style="top:-8px;left:30px"></span></div>`;
    if (s === 'small') return `<div class="center" style="height:100%;padding:12px">${note([['LINE', C.line], ['CALL', C.phone]], 'width:148px;transform:rotate(-3deg)')}</div>`;
    return `<div class="row" style="height:100%;padding:16px 22px;gap:14px;justify-content:center;align-items:center">${note([['LINE', C.line], ['CALL', C.phone]], 'width:148px;transform:rotate(-2deg)')}${note([['MAIL', C.email.replace('@', '@\u200b')], ['WEB', C.web]], 'width:148px;transform:rotate(1.5deg);word-break:break-all')}</div>`;
  } });

reg({ id: 'popContactPaper', family: 'contact', title: 'ช่องทางติดต่อสามแถว · กระดาษ', sizes: ['small', 'large'], cls: 'pop-box',
  note: 'สติกเกอร์ขาว 3 แถวช่องทาง · เล็ก = 3 แถวชิด · ใหญ่ = 4 แถวใหญ่ + QR + เวลาตอบ',
  render(s) { return popContact(s); } });
reg({ id: 'popContactGlass', family: 'contact', title: 'ช่องทางติดต่อสามแถว · กระจก', sizes: ['small', 'large'], cls: 'glass2',
  note: 'ผังเดียวกับกระดาษ บนกระจก', render(s) { return popContact(s, true); } });
function popContact(s, glass) {
  const tab = `<span class="pop-tab" ${glass ? 'style="background:var(--accent);color:#1B0A0E"' : ''}>ติดต่อ</span>`;
  const row = (k, v, big) => `<div class="row" style="gap:${big ? 10 : 8}px;padding:${big ? '9px 12px' : '6px 8px'};border-radius:12px;background:var(--glass)"><span class="sbadge" style="--s:${big ? 28 : 22}px;background:${SOC_COLOR[k] || 'var(--glass2)'};color:#fff">${ICO[k]}</span><b style="font-size:${big ? 13.5 : 11.5}px" class="ellip">${v}</b></div>`;
  if (s === 'small') return `${tab}<div class="col" style="height:100%;padding:26px 10px 10px;gap:5px;justify-content:center">${row('line', C.line)}${row('phone', C.phone)}${row('mail', 'อีเมล')}</div>`;
  return `${tab}<div class="col" style="height:100%;padding:30px 14px 14px;gap:8px"><div class="row" style="gap:12px;margin-bottom:4px">${H.avatar(48)}<div class="col" style="gap:1px"><b class="h-kanit" style="font-size:16px">${D.name}</b><span class="dim" style="font-size:11px">${C.reply}</span></div></div>${row('line', C.line, true)}${row('phone', C.phone, true)}${row('mail', C.email, true)}<div class="row between" style="margin-top:auto;align-items:flex-end">${H.qr(9)}<div class="col" style="align-items:flex-end;gap:4px"><span class="dim" style="font-size:10.5px">${C.web}</span>${H.verified()}</div></div></div>`;
}
