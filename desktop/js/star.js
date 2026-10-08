// หน้าฝั่ง Star: Star Profile · การ์ดเกิด (reveal) · ST★R Insight · ตารางงาน · แผง Lab
// หน้า Star Card (คลัง/ห้องแต่ง/เทมเพลต) อยู่นอกขอบเขต desktop รอบนี้ — เหลือเป็นหน้าพักที่บอกว่าไปต่อในแอป

const orbs = () => `<div class="orbs" aria-hidden="true"><i></i><i></i></div>`;

// ผู้ใช้ 6 ต.ค. 2569: ก่อนเป็น STAR = 8 ข้อเท่านั้น · เป็นแล้ว = กล่องทอง "ข้อมูล STAR ของคุณ" + หมวด "ข้อมูลที่แบรนด์ใช้คัดเลือก" แยกต่างหาก (= `StarPage.fillSection`)
// 7 ต.ค. 2569: % = ทางไปเป็น STAR เท่านั้น ("Percent ไม่ต้องนับข้อมูลที่แบรนด์ใช้คัดเลือก นับแค่ตอนกรอก Star ว่าอีกกี่ Percent ได้เป็น Star")
//   ก่อนเป็น STAR = วงแหวน % ที่หัว "ข้อมูลสมัคร STAR" + ปุ่ม "สมัครเป็น STAR NN%" เลขเดียวกัน (= iOS `starPct`) · หลังเป็น STAR ไม่มี %
// 7 ต.ค. 2569: กางรายการ "ในการ์ด" ทุกขนาดจอเหมือน iOS (เลิกใช้แผง "ข้อมูลทั้งหมด" ข้างขวา)
function dataCard(mode) {
  const rows = starRows(mode), full = rows.every(r => F.done(r)), star = F.isStar, gate = gateRows(mode), gateLeft = gate.filter(r => !F.done(r)).length;
  // % ทางไปเป็น STAR = (8 − ข้อที่ขาด) ÷ 8 — banner กับหน้านี้เลขเดียวกัน (= iOS `starPct`) · โชว์เฉพาะก่อนเป็น STAR
  const starPct = F.starPct;
  // nil = ยังไม่เคยแตะ: สถานะ C (STAR เก่าที่ยังขาด) กางให้เลย · อื่น ๆ หุบ (= `listOpenChoice ?? needsStarInfo` ของ salehere-ios)
  const listOpen = UI.listOpen ?? F.needsStarInfo;
  let cta = '';
  // ยังไม่เป็น STAR = ปุ่ม "สมัครเป็น STAR" + % → 8 ข้อก่อนแล้วข้อเสริม · เป็น STAR แต่ยังไม่ครบ = "เติมข้อมูลต่อ" (ไม่มี %) → ข้อที่ขาดใน 8 ข้อก่อน (สถานะ C) แล้วข้อเสริม · ครบ = ไปการ์ด
  if (mode === 'profile') cta = !star ? `<button class="btn dark prog" data-act="applyAll">${miniRing(starPct)}${starText('สมัครเป็น STAR', 12)} <span class="pct">${Math.round(starPct * 100)}%</span></button>`
    : !full ? `<button class="btn dark" data-act="fillMissing">เติมข้อมูลต่อ ${ic('arrowRight', 16, 'b')}</button>`
    : `<button class="btn dark" data-act="openCard">ดูการ์ดของฉัน ${ic('arrowUpRight', 16, 'b')}</button>`;
  const cheer = mode === 'profile' && full && !F.s.fullCheered;
  if (mode === 'profile') { if (full && !F.s.fullCheered) { F.s.fullCheered = true; F.save(); } else if (!full && F.s.fullCheered) { F.s.fullCheered = false; F.save(); } }
  // หัวเดียวครอบทั้งหมด "ข้อมูล STAR ของคุณ" (ผู้ใช้ 7 ต.ค. 2569: "มันก็คือข้อมูล Star เหมือนกัน") · ข้างในเป็นการ์ดคู่แฝดหน้าตาเดียวกัน กาง/หุบได้เหมือนกัน (= iOS `starBlock` / `laterSection`)
  //   ทอง "ใช้สมัครเป็น STAR" (ด่าน 8 ข้อ · ครบ = "ครบ 8 ข้อแล้ว" หุบไว้ · สถานะ C = "ขาด N ข้อ · แบรนด์ขอข้อมูลเพิ่ม" กางให้เลย)
  //   เทา "ใช้ให้แบรนด์คัดเลือก" (หลังเป็น STAR · กางเองเมื่อยังขาด · ครบแล้วหุบ) · แถวในการ์ดแบบเดียวกันทั้งสองการ์ด (`cardRows` = iOS `starRow`)
  const head = `<h3 class="dsec-h">ข้อมูล ${starText('STAR', 12)} ของคุณ</h3>`;
  const extras = star && mode === 'profile' ? extraRows(mode) : [], todo = extras.filter(r => !F.done(r)), laterOpen = UI.laterOpen ?? todo.length > 0;
  const caret = `<i class="gold-caret">${ic('caretDown', 14, 'b')}</i>`;
  if (star) return `<div class="gc-sec dsec ${cheer ? 'cheer' : ''}">${head}
    <div class="gold-box"><button class="data-t gold" data-act="toggleList" aria-expanded="${listOpen}" aria-controls="data-rows"><span><b id="data-h">ใช้สมัครเป็น ${starText('STAR', 11)}</b><small>${F.needsStarInfo ? `ขาด ${F.starMissing.length} ข้อ · แบรนด์ขอข้อมูลเพิ่ม` : 'ครบ 8 ข้อแล้ว'}</small></span>${caret}</button>${listOpen ? cardRows(gate, 'data-rows', false, mode) : ''}</div>
    ${extras.length ? `<div class="gold-box grey"><button class="data-t gold" data-act="toggleLater" aria-expanded="${laterOpen}" aria-controls="later-rows"><span><b>ใช้ให้แบรนด์คัดเลือก</b><small>${todo.length ? `ยังขาด ${todo.length} ข้อ` : `ครบ ${extras.length} ข้อแล้ว`}</small></span>${caret}</button>${laterOpen ? cardRows(extras, 'later-rows', true, mode) : ''}</div>` : ''}
    ${cta ? `<div class="dock">${cta}</div>` : ''}</div>`;
  const title = `ใช้สมัครเป็น ${starText('STAR', 12)}`;
  const sub = gateLeft === gate.length ? '8 ข้อที่ต้องกรอกก่อนเป็น STAR' : `อีก ${gateLeft} ข้อได้เป็น STAR`;
  // แถวสถานะอยู่ "ในการ์ดตัวตน ใต้หมวด ST★R Card" (feedback 5 ต.ค. 2569) · กดแล้วกางรายการ 8 ข้อในการ์ด
  return `<div class="gc-sec dsec">${head}<button class="data-t" data-act="toggleList" aria-expanded="${listOpen}" aria-controls="data-rows">${ring(starPct, false)}<span><b id="data-h">${title}</b><small>${sub}</small></span>${ic('caretRight', 14, 'b')}</button>${listOpen ? cardRows(gate, 'data-rows', false, mode) : ''}${cta}</div>`;
}
// แถวในการ์ด — แบบเดียวกันทั้ง "ใช้สมัครเป็น STAR" และ "ใช้ให้แบรนด์คัดเลือก" (ผู้ใช้ 7 ต.ค. 2569 · = iOS `StarPage.starRow`)
// ยังไม่มี = ไอคอนกรอบประ + บรรทัดรอง (ใช้ตอนไหน / ทำไม / สถานะยืนยันตัวตน) + ปุ่ม "เพิ่ม" ขาว · แถวเส้นประ · มีแล้ว = ไอคอนทึบ + ชิปค่า + ติ๊กเขียว · แถวขาว · แตะ = แก้ข้อนั้นข้อเดียว
// ก่อนเป็น STAR ข้อที่ขาด: ไม่มีปุ่ม "เพิ่ม" · แตะไม่ได้ (ไปทางปุ่ม "สมัครเป็น STAR" อย่างเดียว — salehere-ios 7 ต.ค. 2569)
// หลังเป็น STAR ข้อที่ขาด: "เพิ่ม" = เริ่มที่ข้อนั้นแล้วไล่ต่อข้อที่ขาด (`missingSteps(from:)`) · หน้า "คุณเป็น STAR แล้ว" กางดูได้แต่แตะแถวไม่ได้
function cardRows(rows, id, when, mode) {
  const list = [...rows.filter(r => !F.done(r)), ...rows.filter(r => F.done(r))], canAdd = F.isStar, locked = mode === 'reveal';
  const tag = (ok, act, k) => locked || (!ok && !canAdd) ? `<div class="row ${ok ? 'ok' : 'todo'} later static"` : `<button class="row ${ok ? 'ok' : 'todo'} later" data-act="${act}" data-arg="${k}"`;
  const end = (ok) => locked || (!ok && !canAdd) ? '</div>' : '</button>';
  return `<ul class="rows later" id="${id}">${list.map(r => { const ok = F.done(r), k = r.key || 'kyc', note = !r.key && F.kycBlocked ? kycNote() : '';
    return ok ? `<li>${tag(true, 'fillOne', k)}><span class="row-ic">${ic(r.icon, 18, 'f')}</span><span class="row-tx"><b>${r.title}</b>${chipStrip(F.facts(r))}</span><span class="tick">${ic('check', 12, 'b')}</span>${end(true)}</li>`
      : `<li>${tag(false, 'fillFrom', k)}><span class="row-ic">${ic(r.icon, 18, 'b')}</span><span class="row-tx"><b>${r.title}</b><small class="${note && !when ? 'kyc-note ' + F.s.verify : ''}">${esc((when && WHEN[r.key]) || note || r.why)}</small></span>${canAdd && !locked ? '<span class="row-add lite">เพิ่ม</span>' : ''}${end(false)}</li>`; }).join('')}</ul>`;
}

// ---------- Star Profile (= StarPage .profile) — ซ้าย: ตัวตน + Star Card + ข้อมูล STAR · ขวา: ตารางงาน ----------
function starView() {
  const n = SCHED.next, line = n ? `${SD.label(n.step.date)}${n.step.time ? ' ' + n.step.time : ''} · ${n.step.label} ${esc(n.job.brand)}` : 'ยังไม่มีงาน · ลงงานแรก';
  return `${orbs()}<nav class="crumb" aria-label="ตำแหน่ง"><button data-act="tab" data-arg="profile">โปรไฟล์</button>${ic('caretRight', 12, 'b')}<span aria-current="page">Star Profile</span></nav>
    <header class="star-head"><h1 class="glass-title">${F.isStar ? `${starMark(34)}<em>Profile</em><span class="sr">Star Profile</span>` : `สมัครเป็น ${starMark(30)}`}</h1><span class="glass-chip">${ic('eye', 15, 'b')}แบรนด์ใช้ข้อมูลนี้ตอนคัดคน</span></header>
    <div class="star-2"><div class="star-l">${glassCard({ onAvatar: F.isStar, verify: 'tap', card: true, hero: true, data: 'profile' })}</div>
      <div class="star-r"><button class="card sched-entry" data-act="openSchedule"><i>${ic('calendarDots', 20, 'b')}</i><span><b>ตารางงาน</b><small>${line}</small></span>${ic('caretRight', 14, 'b')}</button></div></div>`;
}

// ---------- การ์ดเกิด (= StarPage .reveal) — โชว์ครั้งแรกครั้งเดียวหลังสมัครเป็น STAR แล้วพาไปฟอร์มสมัคร ----------
function revealView() {
  const c = campaign(), quiet = F.s.revealSeen;
  if (!quiet) setTimeout(() => { F.s.revealSeen = true; F.save(); }, 3200);
  // หน้า "คุณเป็น STAR แล้ว" ไม่มีปุ่มปิด ไม่มี "แชร์การ์ดก่อน" — ไปต่อทางปุ่มเดียว (salehere-ios `WzRevealPage`) · แถวกางดูได้แต่แตะไม่ได้
  return focusPage({ cls: 'reveal noclose ' + (quiet || REDUCED ? 'quiet' : ''), close: null, ctx: '', body: `<div class="rv">
    <div class="rv-head"><span class="rv-seal">${ic('star', 30, 'f')}</span><h1 class="glass-title">${F.isStar ? `คุณเป็น ${starMark(30)} แล้ว` : `การ์ดของคุณ <em>พร้อมแล้ว</em>`}</h1>
      <div class="rv-cta"><button class="btn dark lg" data-act="revealNext" autofocus><span class="rv-t">ต่อ: ฟอร์มสมัคร ${esc(c.title)}</span>${ic('arrowRight', 18, 'b')}</button></div></div>
    <div class="star-2 rv-body"><div class="star-l">${glassCard({ verify: 'tap', hero: true, data: 'reveal' })}</div></div></div>` });
}

function cardStubView() {
  return `<div class="stub"><div><h1>${starMark(40)}<em>Card</em><span class="sr">Star Card</span></h1><p>คลังการ์ด · ห้องแต่ง · เทมเพลต อยู่นอกขอบเขต desktop รอบนี้<br>ตอนนี้แต่งการ์ดได้ในแอป Sale Here บนมือถือ</p>
    ${qrBox('เปิด Star Card ในแอป')}<button class="btn white" data-act="closeCard" autofocus>${ic('arrowLeft', 16, 'b')}กลับ Star Profile</button></div></div>`;
}

// ---------- ST★R Insight (= StarInsightPage) — ดำล้วน ตัวเลขขาว กราฟสีเดียว · 3 ก้อนเรียงเป็นกรวย: ยอดวิว → กดเข้ามาดู → แบรนด์สายไหน ----------
function monotone(pts) {
  const n = pts.length, d = [], m = []; if (n < 2) return '';
  for (let i = 0; i < n - 1; i++) d.push((pts[i + 1][1] - pts[i][1]) / (pts[i + 1][0] - pts[i][0]));
  m[0] = d[0]; m[n - 1] = d[n - 2];
  for (let i = 1; i < n - 1; i++) m[i] = d[i - 1] * d[i] <= 0 ? 0 : (d[i - 1] + d[i]) / 2;
  for (let i = 0; i < n - 1; i++) { if (d[i] === 0) { m[i] = m[i + 1] = 0; continue; } const a = m[i] / d[i], b = m[i + 1] / d[i], h = Math.hypot(a, b); if (h > 3) { m[i] = 3 * a / h * d[i]; m[i + 1] = 3 * b / h * d[i]; } }
  let p = `M${pts[0][0]} ${pts[0][1]}`;
  for (let i = 0; i < n - 1; i++) { const dx = (pts[i + 1][0] - pts[i][0]) / 3; p += `C${pts[i][0] + dx} ${pts[i][1] + m[i] * dx} ${pts[i + 1][0] - dx} ${pts[i + 1][1] - m[i + 1] * dx} ${pts[i + 1][0]} ${pts[i + 1][1]}`; }
  return p;
}
function insightChart(d) {
  const W = 760, H = 250, padL = 8, padR = 8, top = 34, bot = 28, max = Math.max(...d.daily), n = d.daily.length;
  const x = i => padL + (W - padL - padR) * i / (n - 1), y = v => top + (H - top - bot) * (1 - v / max), pts = d.daily.map((v, i) => [x(i), y(v)]);
  const line = monotone(pts), peak = d.daily.indexOf(max), last = n - 1, anchor = i => i < 2 ? 'start' : i > n - 3 ? 'end' : 'middle';
  const axis = d.axis.map((t, i) => `<text x="${x(d.axis.length === n ? i : Math.round(i * (n - 1) / (d.axis.length - 1)))}" y="${H - 6}" text-anchor="${i === 0 ? 'start' : i === d.axis.length - 1 ? 'end' : 'middle'}" class="ax">${t}</text>`).join('');
  return `<div class="chart" tabindex="0" role="img" aria-label="กราฟยอดวิวรายวัน สูงสุด ${max} ครั้ง${d.peakNote ? ' ' + d.peakNote : ''} วันนี้ ${d.daily[last]} ครั้ง ใช้ปุ่มลูกศรซ้ายขวาเพื่ออ่านรายวัน" data-pts='${JSON.stringify(pts.map(p => [Math.round(p[0]), Math.round(p[1])]))}' data-w="${W}">
    <svg viewBox="0 0 ${W} ${H}" aria-hidden="true"><defs><linearGradient id="ar" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="var(--mark)" stop-opacity=".34"/><stop offset="1" stop-color="var(--mark)" stop-opacity="0"/></linearGradient></defs>
      <line x1="0" x2="${W}" y1="${H - bot}" y2="${H - bot}" class="base"/><g class="plot"><path d="${line}L${x(last)} ${H - bot}L${x(0)} ${H - bot}Z" fill="url(#ar)"/><path d="${line}" class="ln"/></g>
      <g class="marks"><circle cx="${x(peak)}" cy="${y(max)}" r="4.5" class="dot"/><text x="${x(peak)}" y="${y(max) - 12}" text-anchor="${anchor(peak)}" class="lb">${max.toLocaleString('en-US')} · ${d.peakNote}</text>
        ${peak !== last ? `<circle cx="${x(last)}" cy="${y(d.daily[last])}" r="4.5" class="dot"/><text x="${x(last)}" y="${y(d.daily[last]) - 12}" text-anchor="end" class="lb">วันนี้ ${d.daily[last].toLocaleString('en-US')}</text>` : ''}</g>
      <g id="scrub" style="display:none"><line y1="${top - 14}" y2="${H - bot}" class="sl"/><circle r="5.5" class="sd"/></g>${axis}</svg>
    <div id="scrub-tip" class="tip" style="display:none"></div>
    <table class="sr"><caption>ยอดวิวรายวัน</caption><tbody>${d.daily.map((v, i) => `<tr><th scope="row">${d.names[i]}</th><td>${v}</td></tr>`).join('')}</tbody></table></div>`;
}
function insightView() {
  const d = INSIGHT.get(UI.range), never = INSIGHT.neverSeen, rname = UI.range === 'week' ? '7 วัน' : '28 วัน';
  const toggle = never ? '' : `<div class="seg dark" role="radiogroup" aria-label="ช่วงเวลา">${[['week', '7 วัน'], ['month', '28 วัน']].map(([k, t]) => `<button role="radio" aria-checked="${UI.range === k}" class="${UI.range === k ? 'on' : ''}" data-act="range" data-arg="${k}">${t}</button>`).join('')}</div>`;
  let body;
  if (never) body = `<div class="ins-empty"><i>${ic('chartLineUp', 30, 'b')}</i><h2>ยังไม่มีคนเห็นการ์ด</h2><p>แชร์ลิงก์การ์ดของคุณ<br>ยอดวิวและแบรนด์ที่เข้ามาดูจะขึ้นที่นี่</p><button class="btn white" data-act="shareCard">${ic('shareNetwork', 16, 'b')}แชร์การ์ด</button></div>`;
  else if (d.empty) body = `<div class="ins-empty"><h2>${rname}ล่าสุดยังไม่มีคนเห็นการ์ด</h2><p>แชร์การ์ดอีกรอบ ยอดวิวจะกลับมาขึ้นที่นี่</p><button class="btn glass" data-act="range" data-arg="${UI.range === 'week' ? 'month' : 'week'}">ดู ${UI.range === 'week' ? '28 วัน' : '7 วัน'}</button></div>`;
  else {
    const up = d.change >= 0, pct = Math.round(d.openRate * 100), most = d.styles[0][1];
    body = `<div class="ins-grid ${UI.insLoading ? 'loading' : ''}" aria-busy="${UI.insLoading}"><section class="ins-main" aria-labelledby="iv-h">
        <p class="today-line"><i></i>วันนี้ แบรนด์สาย${d.today[0]}เข้ามาดู ${d.today[1]} ราย</p>
        <div class="iv-row"><h2 id="iv-h">ยอดวิว</h2><span class="fresh"><span id="fresh">${UI.insLoading ? 'กำลังโหลด…' : 'อัปเดตเมื่อสักครู่'}</span><button class="icon-btn dark" data-act="refreshInsight" aria-label="โหลดข้อมูลใหม่" title="โหลดข้อมูลใหม่">${ic('arrowsClockwise', 16, 'b')}</button></span></div>
        <p class="iv-num"><strong>${d.views.toLocaleString('en-US')}</strong><span class="delta ${up ? 'up' : ''}">${ic(up ? 'trendUp' : 'trendDown', 16, 'b')}${Math.abs(Math.round(d.change * 100))}% จาก ${rname}ก่อน <small>(${d.prev.toLocaleString('en-US')})</small></span></p>
        ${insightChart(d)}</section>
      <aside class="ins-side"><section aria-labelledby="io-h"><div class="rowhead"><h2 id="io-h">กดเข้ามาดูการ์ด</h2><b>${d.opened.toLocaleString('en-US')}</b><span>ครั้ง</span></div>
          <div class="meter" role="img" aria-label="${pct}% ของยอดวิว"><i style="width:${pct}%"></i></div><p class="soft">${pct}% ของยอดวิว</p></section>
        <section aria-labelledby="ib-h"><div class="rowhead"><h2 id="ib-h">แบรนด์สาย${d.styles[0][0]}ดูคุณมากที่สุด</h2><b>${d.brands}</b><span>แบรนด์</span></div>
          <table class="bars"><caption class="sr">จำนวนแบรนด์ที่เข้ามาดู แยกตามสาย</caption><tbody>${d.styles.map((s, i) => `<tr class="${i === 0 ? 'lead-row' : ''}"><th scope="row">${s[0]}</th><td class="bar"><i style="width:${Math.max(3, s[1] / most * 100)}%"></i></td><td>${s[1]}</td></tr>`).join('')}</tbody></table>
          <p class="faint">ลองวางผลงาน${d.styles[0][0]}ไว้หน้าแรกของการ์ด</p></section></aside></div>`;
  }
  return `<div class="ins"><header class="ins-top"><button class="x dark" data-act="closeInsight" aria-label="กลับ Star Profile">${ic('arrowLeft', 18, 'b')}</button>
      <h1 class="glass-title">${starMark(30)}<em>Insight</em><span class="sr">Star Insight</span></h1><span class="grow"></span>${toggle}
      ${never || d.empty ? '' : `<button class="btn white" data-act="editCard">${ic('pencilSimple', 16, 'b')}แต่งการ์ด</button><button class="btn glass" data-act="shareCard">${ic('shareNetwork', 16, 'b')}แชร์</button>`}</header>
    <main id="main" class="ins-body">${body}</main></div>`;
}

// ---------- ตารางงาน (= StarSchedulePage) — desktop: ปฏิทินเดือน + รายการของวันที่เลือก เห็นพร้อมกัน ไม่ต้องสลับโหมด ----------
function jobMark(job, size = 38) { return `<span class="jmark" style="width:${size}px;height:${size}px;font-size:${Math.round(size * 0.4)}px">${esc(job.brand.slice(0, 1).toUpperCase())}</span>`; }
function tickBtn(job, st) { return `<button class="tickb ${st.done ? 'on' : ''}" role="checkbox" aria-checked="${st.done}" aria-label="${st.done ? 'เสร็จแล้ว' : 'ติ๊กเสร็จ'} ${st.label} ${esc(job.brand)}" data-act="tickStep" data-arg="${job.id}|${st.id}">${st.done ? ic('check', 14, 'b') : ''}</button>`; }
function scheduleView() {
  const sel = UI.sched.sel, first = SD.first(sel), fd = SD.date(first), lead = (fd.getDay() + 6) % 7, count = new Date(fd.getFullYear(), fd.getMonth() + 1, 0).getDate(), weeks = Math.ceil((lead + count) / 7);
  let grid = '';
  for (let w = 0; w < weeks; w++) {
    grid += '<tr>';
    for (let c = 0; c < 7; c++) {
      const i = w * 7 + c - lead; if (i < 0 || i >= count) { grid += '<td class="out"></td>'; continue; }
      const iso = SD.day(i, first), all = SCHED.on(iso).sort((a, b) => a.step.done - b.step.done), today = iso === SD.today, on = iso === sel;
      grid += `<td><button class="day ${on ? 'on' : ''} ${today ? 'today' : ''}" data-act="schedDay" data-arg="${iso}" aria-pressed="${on}" aria-label="${SD.label(iso)} ${all.length ? all.length + ' อย่าง' : 'ไม่มีงาน'}"><b>${i + 1}</b>
        ${all.slice(0, 3).map(e => `<i class="${e.step.done ? 'done' : ''}">${esc(e.job.brand)}</i>`).join('')}${all.length > 3 ? `<small>+${all.length - 3}</small>` : ''}</button></td>`;
    }
    grid += '</tr>';
  }
  const money = SCHED.pendingMoney;
  return `<nav class="crumb" aria-label="ตำแหน่ง"><button data-act="tab" data-arg="profile">โปรไฟล์</button>${ic('caretRight', 12, 'b')}<button data-act="closeSchedule">Star Profile</button>${ic('caretRight', 12, 'b')}<span aria-current="page">ตารางงาน</span></nav>
    <div class="sch"><section class="card sch-cal" aria-labelledby="sch-h"><header><div><p class="eyebrow">${money > 0 ? `ตารางงาน · รอรับ ${SD.baht(money)}` : 'ตารางงาน'}</p><h1 id="sch-h">${SD.monthTitle(sel)}</h1></div><span class="grow"></span>
        ${sel !== SD.today ? `<button class="btn quiet sm" data-act="schedDay" data-arg="${SD.today}">วันนี้</button>` : ''}<button class="round" data-act="schedMonth" data-arg="-1" aria-label="เดือนก่อน">${ic('caretLeft', 15, 'b')}</button><button class="round" data-act="schedMonth" data-arg="1" aria-label="เดือนถัดไป">${ic('caretRight', 15, 'b')}</button>
        <button class="btn dark" data-act="addJob">${ic('plus', 16, 'b')}ลงงาน</button></header>
      <table class="cal"><thead><tr>${['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'].map(d => `<th scope="col">${d}</th>`).join('')}</tr></thead><tbody>${grid}</tbody></table></section>
    <aside class="sch-day" aria-label="งานของวันที่เลือก" aria-live="polite">${UI.sched.job && SCHED.job(UI.sched.job) ? jobDetail(SCHED.job(UI.sched.job)) : agenda()}
      ${UI.sched.ask ? `<div class="ask-card" role="alertdialog" aria-labelledby="ask-t"><b id="ask-t">${esc(UI.sched.ask.title)}</b><small>${UI.sched.ask.sub}</small><div><button class="btn glass" data-act="askNo">${UI.sched.ask.no}</button><button class="btn white" data-act="askYes">${UI.sched.ask.yes}</button></div></div>` : ''}</aside></div>`;
}
function agenda() {
  const sel = UI.sched.sel, rows = SCHED.on(sel), overdue = sel === SD.today ? SCHED.overdue : [];
  if (!SCHED.jobs.length) return `<div class="card pad sch-empty"><h2>ยังไม่มีงานในตาราง</h2><p>ลงงานที่รับไว้ แอปจำเดดไลน์ให้<br>งาน Sale Here ขึ้นเอง</p><button class="btn dark" data-act="addJob">${ic('plus', 16, 'b')}ลงงานแรก</button></div>`;
  const cards = list => { const ids = [...new Set(list.map(e => e.job.id))]; return ids.map(id => jobCard(SCHED.job(id), list.filter(e => e.job.id === id).map(e => e.step))).join(''); };
  const next = SCHED.nextDay(sel);
  return `${overdue.length ? `<h2 class="slab red">ค้างอยู่</h2>${cards(overdue)}` : ''}<h2 class="slab">${SD.title(sel)}</h2>
    ${rows.length ? cards(rows) : `<p class="card pad no-job">ไม่มีงาน</p>${next ? `<button class="link" data-act="schedDay" data-arg="${next}">งานถัดไป ${SD.label(next)} ${ic('caretRight', 11, 'b')}</button>` : ''}`}`;
}
function jobCard(job, steps) {
  return `<div class="card job"><button class="job-h" data-act="openJob" data-arg="${job.id}">${jobMark(job)}<span><b>${esc(job.brand)}</b><small>${esc(job.title)}</small></span>${ic('caretRight', 13, 'b')}</button>
    ${steps.map(st => { const late = st.date < SD.today && !st.done;
      return `<div class="job-s ${st.done ? 'done' : ''}"><div><p><b>${st.label}</b>${st.time ? `<span>${st.time}</span>` : ''}${late ? `<em>เกิน ${SD.gap(SD.today, st.date)} วัน</em>` : ''}</p>${st.kind === 'event' && st.sub ? `<p class="sub">${esc(st.sub)}</p>` : ''}
        ${st.kind === 'post' ? job.posts.filter(p => p.date === st.date).map(p => `<p class="sub">${soc(p.platform, 20)}${p.items.map(i => `${i.name} ${i.count}`).join(' · ')}</p>`).join('') : ''}</div>${tickBtn(job, st)}</div>`; }).join('')}</div>`;
}
function jobDetail(job) {
  const del = UI.sched.del === job.id, paid = !!job.paid;
  return `<div class="jd"><button class="link" data-act="closeJob">${ic('arrowLeft', 14, 'b')}กลับรายการ</button>
    <div class="jd-h">${jobMark(job, 52)}<div><span class="tagc">งานทั่วไป · เห็นคนเดียว</span><h2>${esc(job.brand)}</h2><p>${esc(job.title)}</p></div></div>
    <h3 class="slab">ลงอะไร ที่ไหน วันไหน</h3><ul class="card sbox">${job.posts.map(p => `<li>${soc(p.platform, 28)}<span><b>${SOC[p.platform].name}</b><small>${p.items.map(i => `${i.name} ${i.count}`).join(' · ')}</small></span><time>${SD.label(p.date)}</time></li>`).join('')}</ul>
    <h3 class="slab">ขั้นตอน</h3><ul class="card sbox">${job.steps.map(st => `<li class="${st.done ? 'done' : ''}">${tickBtn(job, st)}<span><b>${st.label}</b><small>${st.kind === 'post' ? job.posts.filter(p => p.date === st.date).map(p => SOC[p.platform].short).join(' · ') : esc(st.sub || '')}</small></span><time>${SD.label(st.date)}${st.time ? ' ' + st.time : ''}</time></li>`).join('')}</ul>
    ${job.fee > 0 ? `<div class="card sbox jmoney"><span><b>${SD.baht(job.fee)}</b><small>${paid ? 'ได้รับแล้ว' : 'ยังไม่ได้รับ · เห็นคนเดียว'}</small></span><button class="pill ${paid ? 'okp' : 'dark'}" aria-pressed="${paid}" data-act="jobPaid" data-arg="${job.id}">${paid ? 'รับแล้ว ✓' : 'รับแล้ว'}</button></div>` : ''}
    <label class="card sbox switch-row"><span><b>โชว์บน Star Card</b><small>แบรนด์ไม่เห็นค่าตัว</small></span><input type="checkbox" role="switch" ${job.showOnCard ? 'checked' : ''} data-act="jobShow" data-arg="${job.id}"><i class="sw"></i></label>
    <button class="btn danger wide ${del ? 'ask' : ''}" data-act="jobDelete" data-arg="${job.id}">${del ? 'กดอีกครั้งเพื่อลบ' : 'ลบงานนี้'}</button></div>`;
}
const newDraft = () => ({ brand: '', title: '', plats: {}, active: null, site: null, siteDate: '', siteTime: '', sitePlace: '', fee: '' });
function addJobModal(m) {
  const d = m.d, miss = SCHED.draftMissing(d, m.step), titles = ['แบรนด์และงาน', 'ลงอะไรบ้าง', 'ไปหน้างาน และเงิน'];
  let body = `<ol class="bars3" aria-label="ขั้นที่ ${m.step} จาก 3">${[1, 2, 3].map(n => `<li class="${n <= m.step ? 'on' : ''}"></li>`).join('')}</ol><h3 class="aj-t">${titles[m.step - 1]}</h3>`;
  if (m.step === 1) body += `<div class="stack-f">${field('แบรนด์อะไร', 'ui.modal.d.brand', { ph: 'ชื่อแบรนด์', live: 1 })}${field('งานอะไร', 'ui.modal.d.title', { ph: 'เช่น รีวิวเซรั่ม', live: 1 })}</div><p class="note sm">งาน Sale Here ขึ้นในตารางเอง ไม่ต้องลง</p>`;
  else if (m.step === 2) {
    const p = d.active, v = p && d.plats[p];
    body += `<p class="note sm">เลือกได้หลายที่</p><div class="ptiles" role="group" aria-label="ลงที่ไหน">${JOB_PLATFORMS.map(x => { const picked = !!d.plats[x], act = d.active === x;
      return `<button class="ptile ${picked ? 'picked' : ''} ${act ? 'act' : ''}" aria-pressed="${picked}" data-act="ajPlat" data-arg="${x}"><i class="box">${picked ? ic('check', 11, 'b') : ''}</i>${soc(x, 26)}<b>${SOC[x].short}</b><small>${picked ? (d.plats[x].date ? SD.short(d.plats[x].date) : 'ยังไม่มีวัน') : '&nbsp;'}</small></button>`; }).join('')}</div>
      ${v ? `<div class="card sbox pform"><div class="pf-h"><b>${SOC[p].name}</b><button class="link mute" data-act="ajDrop" data-arg="${p}">ไม่ลง ${SOC[p].short}</button></div>
        ${JOB_FORMATS[p].map(f => { const n = v.counts[f] || 0; return `<div class="stepper ${n ? 'on' : ''}"><span id="st-${f}">${f}</span><button data-act="ajCount" data-arg="${f}|-1" aria-label="ลด ${f}" ${n ? '' : 'disabled'}>−</button><output aria-labelledby="st-${f}">${n}</output><button data-act="ajCount" data-arg="${f}|1" aria-label="เพิ่ม ${f}" ${n < 9 ? '' : 'disabled'}>+</button></div>`; }).join('')}
        <label class="fld inline"><span>วันลง</span><span class="in"><input type="date" min="${SD.today}" data-bind="ui.modal.d.plats.${p}.date" data-live="change" value="${v.date || ''}"></span></label></div>` : ''}`;
  } else {
    const times = Array.from({ length: 36 }, (_, i) => `${String(Math.floor((i + 12) / 2)).padStart(2, '0')}:${i % 2 ? '30' : '00'}`);
    body += `<div role="radiogroup" aria-labelledby="aj-site"><p class="cap" id="aj-site"><b>ต้องไปหน้างานไหม</b> ถ่ายนอกสถานที่ ออกงาน ไปร้าน</p><div class="picks two-up">${[[false, 'ไม่ต้องไป'], [true, 'ต้องไป']].map(([val, t]) => `<label class="pick slim ${d.site === val ? 'on' : ''}"><input type="radio" name="site" ${d.site === val ? 'checked' : ''} data-act="ajSite" data-arg="${val}"><b>${t}</b></label>`).join('')}</div></div>
      ${d.site ? `<div class="grid2">${field('ที่ไหน', 'ui.modal.d.sitePlace', { ph: 'เช่น สยามพารากอน', cls: 'span2' })}<label class="fld"><span>วันไหน</span><span class="in"><input type="date" min="${SD.today}" data-bind="ui.modal.d.siteDate" data-live="change" value="${d.siteDate}"></span></label>${selectField('เวลา', 'ui.modal.d.siteTime', times, 'ยังไม่เลือก')}</div>` : ''}
      <p class="cap"><b>ได้เงินเท่าไหร่</b> เห็นคนเดียว · ไม่ใส่ก็ได้</p>${field('ค่าตัว', 'ui.modal.d.fee', { ph: '0', unit: 'บาท', mode: 'numeric', digits: 1 })}`;
  }
  const label = miss ? 'ยังขาด: ' + miss : m.step < 3 ? 'ถัดไป' : `บันทึก · ตั้งเตือน ${SCHED.build(d).steps.length} อย่าง`;
  return modal('ลงงาน', body, { foot: `${m.step > 1 ? `<button class="btn quiet" data-act="ajBack">${ic('arrowLeft', 16, 'b')}ย้อนกลับ</button>` : ''}<span class="grow"></span><button class="btn dark" data-act="ajNext" ${miss ? 'aria-disabled="true"' : ''}>${label}</button>` });
}

// ---------- แผง Lab (= FlowLab) — เครื่องมือทดสอบ ไม่ใช่ UI จริง · เปิดค้างไว้ข้างจอแล้วเล่นหน้าไปด้วยได้ ----------
function labView() {
  const cur = F.stageIndex(UI), s = F.s;
  return `<aside class="drawer lab" aria-label="Lab"><header><h2>${ic('flask', 18, 'b')}Lab</h2><button class="x" data-act="closeLab" aria-label="ปิด Lab">${ic('x', 18, 'b')}</button></header><div class="lab-b" data-keep="lab">
    <h3>State ของ Unbox</h3><ol class="stages">${STAGES.map((st, i) => `<li><button class="${i === cur ? 'on' : ''}" ${i === cur ? 'aria-current="step"' : ''} data-act="labGo" data-arg="${i}"><b>${i}</b>${st.t.replace('แทรก: ', '')}${st.ins ? '<i>แทรก</i>' : ''}</button></li>`).join('')}</ol>
    <h3>ข้อมูลใน Star Profile</h3><ul class="ticks">${RULES.map(([k, ask]) => `<li><label><input type="checkbox" ${(k ? F.has(k) : F.isVerified) ? 'checked' : ''} data-act="labTick" data-arg="${k || ''}"><span>${k ? KEY_LABEL[k] : 'ยืนยันตัวตน'}</span><small>${ask === PROFILE_ONLY ? 'ถามที่ Star Profile' : 'ขอที่ขั้น ' + ask}</small></label></li>`).join('')}</ul>
    <h3>ยืนยันตัวตน</h3><div class="seg" role="radiogroup" aria-label="สถานะยืนยันตัวตน">${[['none', 'ยังไม่ทำ'], ['waiting', 'รอตรวจ'], ['rejected', 'ตีกลับ'], ['approved', 'ผ่าน']].map(([v, t]) => `<button role="radio" aria-checked="${s.verify === v}" class="${s.verify === v ? 'on' : ''}" data-act="labVerify" data-arg="${v}">${t}</button>`).join('')}</div>
    <p class="lab-note">สลับ = ผลจากทีมงานมาถึง · แจ้งเตือนเด้งมุมขวาบน</p>
    ${s.verify === 'rejected' ? `<div class="seg" role="radiogroup" aria-label="เหตุผลที่ตีกลับ">${['บัตรไม่ชัด', 'หน้าไม่ตรง'].map((t, i) => `<button role="radio" aria-checked="${s.verifyReason === REJECT_REASONS[i]}" class="${s.verifyReason === REJECT_REASONS[i] ? 'on' : ''}" data-act="labReason" data-arg="${i}">${t}</button>`).join('')}</div>` : ''}
    <p class="lab-sub">ผลตอนจบกล้อง</p><div class="seg" role="radiogroup" aria-label="ผลตอนจบกล้อง">${[['approved', 'OCR ผ่าน · อนุมัติทันที'], ['waiting', 'AI ไม่ผ่าน · ส่งทีมงาน']].map(([v, t]) => `<button role="radio" aria-checked="${kycOutcome.get() === v}" class="${kycOutcome.get() === v ? 'on' : ''}" data-act="labOutcome" data-arg="${v}">${t}</button>`).join('')}</div>
    <h3>ฉากสำเร็จรูป</h3><div class="presets">${PRESETS.map(p => `<button data-act="labPreset" data-arg="${p.id}">${p.t}</button>`).join('')}</div>
    <h3>เครื่องมือ</h3><label class="switch-row"><span><b>กรอกตัวอย่างให้</b><small>wizard เปิดมาช่องว่างมีค่าแล้ว</small></span><input type="checkbox" role="switch" ${s.autofill ? 'checked' : ''} data-act="labAutofill"><i class="sw"></i></label>
    <label class="switch-row"><span><b>STAR เก่า (มียศ STAR)</b><small>${F.needsStarInfo ? `สถานะ C · เป็น STAR แต่ขาด ${F.starMissing.length} ข้อ` : 'เปิด = เป็น STAR ทันที ไม่ต้องครบ 8 ข้อ'}</small></span><input type="checkbox" role="switch" ${s.starRank ? 'checked' : ''} data-act="labRank"><i class="sw"></i></label>
    <div class="presets"><button data-act="labFill">กรอกให้ครบทุกช่อง</button><button data-act="labReset" data-arg="">ล้างข้อมูล flow</button><button data-act="labReset" data-arg="all">ล้างทุกอย่าง (รวมตารางงาน)</button></div></div></aside>`;
}
