// หน้าจอฝั่ง "แอป Sale Here": หน้าแรก · กิจกรรม · โปรไฟล์ · ฟอร์มสมัคร · ตอบรับ · ส่งลิงก์ · ยืนยันตัวตน · dialog
// desktop: แถบล่างติดจอของมือถือ → การ์ดสถานะติดขวา (sticky) · หน้าที่เป็น "งานเดียวให้จบ" ใช้โครง focus ไม่มีเมนูหลัก

const SHELL_SCREENS = ['wizard', 'reveal', 'register', 'accept', 'link', 'kycStatus'];
function basePage() {
  const w = UI.wiz;
  if (UI.screen === 'star' || (UI.screen === 'wizard' && w && w.kind === 'one' && (w.back || 'star') === 'star')) return withNav(starView(), 'profile');
  return UI.campaignId ? withNav(campaignView(), 'home') : UI.tab === 'profile' ? withNav(profileView(), 'profile') : withNav(homeView(), 'home');
}
function view() {
  let page, shell = '';
  const sc = wizAsModal() ? (UI.wiz.back || 'star') : UI.screen;
  if (UI.insight) page = insightView();
  else if (UI.schedule) page = withNav(scheduleView(), 'profile');
  else if (sc === 'card') page = cardStubView();
  else {
    page = basePage();
    shell = sc === 'wizard' ? wizardView() : sc === 'reveal' ? revealView() : sc === 'register' ? registerView() : sc === 'accept' ? acceptView() : sc === 'link' ? linkView() : sc === 'kycStatus' ? kycStatusView() : '';
  }
  if (UI.kyc) shell = kycView();
  return `<a class="skip" href="#main">ข้ามไปเนื้อหา</a>${page}${shell}${wizAsModal() && !UI.kyc ? wizardModal() : ''}${UI.modal ? modalView() : ''}${UI.dialog ? dialogView() : ''}
    ${UI.levelUp ? levelUpView() : ''}${UI.push ? pushView() : ''}${UI.lab ? labView() : ''}${HIDE_LAB || UI.lab ? '' : `<button class="lab-fab" data-act="openLab">${ic('flask', 16, 'b')}Lab</button>`}
    <div id="toast" class="${UI.toast ? 'on' : ''}" role="status" aria-live="polite">${esc(UI.toast || '')}</div>`;
}

function withNav(body, cur) {
  const t = (id, label) => `<button class="${cur === id ? 'on' : ''}" ${cur === id ? 'aria-current="page"' : ''} data-act="tab" data-arg="${id}">${label}</button>`;
  return `<header class="top"><div class="top-in">
    <button class="brand" data-act="tab" data-arg="home" aria-label="Sale Here หน้าแรก"><img src="assets/ic-salehere-logo-red42.png" width="30" height="30" alt=""><b>Sale Here</b></button>
    <nav aria-label="เมนูหลัก">${t('home', 'Sale Here STAR')}${t('profile', 'โปรไฟล์')}</nav>
    <div class="top-r"><button class="icon-btn" aria-label="ติดต่อทีมงาน" title="ติดต่อทีมงาน">${ic('headset', 22)}</button><button class="icon-btn" aria-label="การแจ้งเตือน" title="การแจ้งเตือน">${ic('bell', 22)}</button>
      <button class="me" data-act="tab" data-arg="profile">${avatar(32)}<span>${esc(userName())}</span></button></div></div></header>
    <main id="main" class="page">${body}</main>`;
}
// โครง "งานเดียวให้จบ" = แผงกลางจอ กว้าง 600 ทับหน้าเดิม (หัวกลาง · ปิดขวาบน · เนื้อหาเลื่อนข้างใน · ปุ่มติดล่างแผง)
// ตามของจริงใน salehere-web: `RegisterUnboxShell` (max-width 600 · สูง 600 · ปิดด้วยการแตะพื้นหลังไม่ได้)
function focusPage(o) {
  return `<div class="scrim shell-scrim"><section class="shell ${o.cls || ''}" role="dialog" aria-modal="true" aria-labelledby="shell-t">
    <header class="shell-h">${o.back ? `<button class="x back" data-act="${o.close}" ${o.arg ? `data-arg="${o.arg}"` : ''} aria-label="${o.closeLabel || 'ย้อนกลับ'}">${ic('arrowLeft', 16, 'b')}</button>` : ''}
      <div id="shell-t" class="shell-t" tabindex="-1">${o.ctx || ''}</div>${o.back || !o.close ? '' : `<button class="x" data-act="${o.close}" aria-label="${o.closeLabel || 'ปิด'}">${ic('x', 16, 'b')}</button>`}</header>
    <div class="shell-b" data-keep="shell">${o.body}</div></section></div>`;
}
const jobChip = c => `<span class="job-chip"><img src="${c.cover}" alt=""><span>${c.episode} · ${esc(c.brand)}</span></span>`;

// ---------- หน้าแรก ----------
function homeView() {
  // banner "สมัครเป็น ST★R" อยู่บนสุดของหน้าแรก (แทนการ์ดสถานะข้างขวาเดิม) · เป็น STAR แล้วหายไปเลย
  return `<div class="home solo"><section aria-labelledby="h-star"><div class="h-row"><h1 id="h-star" class="h-star">${ic('sparkle', 18, 'f')}Sale Here STAR</h1><p>กิจกรรมที่แบรนด์เปิดรับครีเอเตอร์</p></div>
    ${starBanner()}
    <ul class="camp-grid">${CAMPAIGNS.map(c => `<li><button class="camp" data-act="openCampaign" data-arg="${c.id}">
      <span class="camp-cover"><img src="${c.cover}" alt=""><i class="tag ${c.isOpen ? 'open' : ''}">${c.isOpen ? 'เปิดรับสมัคร' : 'หมดเวลา'}</i></span>
      <span class="camp-b"><span class="camp-h"><img class="logo" src="${c.logo}" alt=""><b>${esc(c.headline)}</b></span>
      <span class="meta">${ic('calendarBlank', 15)}${c.dateRange}</span><span class="meta">${ic('gift', 15)}${esc(c.reward)}</span></span></button></li>`).join('')}</ul></section></div>`;
}
// banner ชวน "สมัครเป็น ST★R" (แคนวาส A ตราทอง 6 ต.ค. 2569 = ใบแทน "ทำโปรไฟล์ให้สมบูรณ์กันเถอะ" ของ salehere-ios) — หน้าแรก + แท็บโปรไฟล์ (= iOS `StarInviteBanner`)
// ผู้ใช้ 7 ต.ค. 2569: เช็คแค่ 8 ข้อ · % เฉพาะตอนทำ STAR (วงทองรอบรูป + ป้าย %) · สูง 88 เท่ากันทุกสถานะ · ปุ่มขวา = วงดำ + ลูกศร ไม่มีข้อความ (ข้อความปุ่มให้ screen reader)
//   STAR ครบ 8 ข้อ (สถานะ B) = ไม่มี banner · สถานะ C (STAR เก่าที่ยังขาด) = "เติมข้อมูล STAR" + "ขาด N ข้อ" + วงทองเต็ม
//   ป้ายรอตรวจ/ไม่ผ่านเฉพาะตอนเหลือแค่ยืนยันตัวตนข้อเดียว (ยังขาดข้ออื่น = ป้ายดาวปกติ · ห้ามพาไปหน้าสถานะทั้งที่ยังไม่ได้กรอก)
function starBanner() {
  const more = F.needsStarInfo;
  if (F.isStar && !more) return '';
  const left = F.starMissing.length, onlyKyc = F.starMissing.join() === 'kyc', v = F.s.verify, wait = onlyKyc && v === 'waiting', bad = onlyKyc && v === 'rejected', C = 2 * Math.PI * 30;
  const title = more ? 'เติมข้อมูล STAR' : 'สมัครเป็น STAR', pill = more ? `ขาด ${left} ข้อ` : `${Math.round(F.starPct * 100)}%`, ring = more ? 1 : F.starPct;
  const sub = more ? 'แบรนด์ขอข้อมูลเพิ่ม · กรอกครบแล้วสมัครงานได้ต่อเลย' : wait ? 'รอตรวจตัวตน · แจ้งผลภายใน 1–3 วันทำการ' : bad ? 'ตัวตนไม่ผ่าน · ถ่ายใหม่แล้วส่งได้เลย'
    : left === 8 ? 'รับงานรีวิวจากแบรนด์ · ตอบ 8 ข้อที่ต้องกรอกก่อนเป็น STAR' : `อีก ${left} ข้อได้เป็น STAR`;
  const cta = more ? 'เติมข้อมูล' : wait ? 'ดูสถานะ' : bad ? 'ส่งใหม่' : 'สมัครเลย';
  return `<button class="sban" data-act="bannerTap" aria-label="${title} ${pill} · ${sub} · ${cta}">
    <span class="sban-ava"><svg viewBox="0 0 64 64" aria-hidden="true"><circle class="t" cx="32" cy="32" r="30"/><circle class="v" cx="32" cy="32" r="30" stroke-dasharray="${C.toFixed(1)}" stroke-dashoffset="${(C * (1 - ring)).toFixed(1)}" transform="rotate(-90 32 32)"/></svg>${avatar(50)}<i class="sban-badge ${wait ? 'wait' : bad ? 'bad' : 'star'}">${wait ? ic('clock', 11, 'b') : bad ? '!' : ic('star', 11, 'f')}</i></span>
    <span class="sban-tx"><b>${starText(title, 15)}<em class="sban-pct">${pill}</em></b><small class="${bad ? 'bad' : ''}">${sub}</small></span>
    <span class="sban-go" aria-hidden="true">${ic('arrowRight', 16, 'b')}</span></button>`;
}

// ---------- หน้ากิจกรรม ----------
function campaignView() {
  const c = campaign(), tab = UI.campTab, row = (l, v) => `<div><dt>${l}</dt><dd>${v}</dd></div>`;
  const tabBtn = (id, icon, t) => `<button role="tab" id="tab-${id}" aria-selected="${tab === id}" aria-controls="panel-camp" tabindex="${tab === id ? 0 : -1}" class="${tab === id ? 'on' : ''}" data-act="campTab" data-arg="${id}">${ic(icon, 16)}${t}</button>`;
  return `<div class="detail"><nav class="crumb" aria-label="ตำแหน่ง"><button data-act="closeCampaign">Sale Here STAR</button>${ic('caretRight', 11, 'b')}<span aria-current="page">${c.episode}</span></nav>
    <section class="card hero-sec"><div class="cover16"><span style="background-image:url('${c.cover}')" aria-hidden="true"></span><img src="${c.cover}" alt="ภาพปกกิจกรรม ${esc(c.brand)}"></div>
      <div class="pad"><div class="hero-top"><span class="badge-pill ${c.isOpen ? 'open' : ''}">${c.isOpen ? 'เปิดรับสมัคร' : 'หมดเวลา'}</span><button class="btn text sm" data-act="shareCampaign">${ic('shareFat', 16)}แชร์</button></div>
        <h1>${esc(c.headline)}</h1><p class="brand-row"><img class="logo" src="${c.logo}" alt=""><b>${esc(c.brand)}</b></p>
        <dl class="meta-dl">${row('ช่วงรับสมัคร', c.dateRange)}${row('ของรางวัล', esc(c.reward))}${c.fee ? row('ค่าตัว', '฿' + c.fee.toLocaleString('en-US')) : ''}${row('รับรีวิวเวอร์', c.quota + ' สิทธิ์')}${row('ผู้สมัครแล้ว', c.registered.toLocaleString('en-US') + ' คน')}
          ${row('ช่องทางที่ต้องรีวิว', `<span class="socs">${c.channels.map(x => soc(x, 20)).join('')}</span>`)}</dl>
        <div class="cta-box" aria-label="สถานะการสมัคร">${campaignSide(c)}</div></div></section>
    <section class="card"><div class="tabs" role="tablist" aria-label="รายละเอียดกิจกรรม">${tabBtn('howTo', 'clipboardText', 'วิธีการร่วมกิจกรรม')}${tabBtn('reviews', 'notePencil', 'รีวิว')}</div>
      <div class="pad" role="tabpanel" id="panel-camp" aria-labelledby="tab-${tab}">${tab === 'howTo' ? `<p class="body">${esc(c.howTo)}</p>
        ${c.timeline.length ? `<h2 class="h-sm">Timeline แคมเปญ</h2><ol class="timeline">${c.timeline.map(t => `<li><span>${t[0]}</span><b>${t[1]}</b></li>`).join('')}</ol>` : ''}`
        : `<div class="empty">${ic('chatCircleText', 32)}<p>ยังไม่มีรีวิวจากกิจกรรมนี้</p></div>`}</div></section></div>`;
}
// = bottomBar ของ StarCampaignPage — บรรทัดสถานะ + ป้าย STAR + ปุ่มตาม phase
function campaignSide(c) {
  const s = F.s;
  const status = (icon, t, cls = '') => `<p class="st-line ${cls}">${ic(icon, 18)}${t}</p>`;
  const timer = (t, d) => `<div class="st-clock"><span>${ic('calendarBlank', 18)}${t}</span>${clock(d)}</div>`;
  if (s.phase === 'register') {
    if (!c.isOpen) return status('calendarBlank', 'หมดเวลาลงทะเบียนแล้ว', 'mute') + `<button class="btn red wide" disabled>หมดเวลาลงทะเบียน</button>`;
    // หน้ากิจกรรมไม่เปลี่ยน — ไม่มีบรรทัดป้าย STAR แบบ salehere-ios (7 ต.ค. 2569) · ด่าน STAR อยู่ที่ปุ่ม (`tapMain`)
    return timer('เหลือเวลาลงทะเบียน', c.deadline) + `<button class="btn red wide" data-act="tapMain">${ic('notePencil', 20)}ลงทะเบียนร่วมกิจกรรม</button>`;
  }
  // ลงทะเบียนแล้ว = สถานะเดิมของแอปหลักอย่างเดียว (ไม่มีบรรทัด "เติมเลย" แล้ว — salehere-ios 7 ต.ค. 2569)
  if (s.phase === 'registered') return `<p class="st-done">${ic('checkCircle', 22, 'f')}<span><b>คุณได้ลงทะเบียนแล้ว</b><small>รอประกาศชื่อผู้ได้รับคัดเลือก</small></span></p>`;
  if (s.phase === 'waitingAcceptQuota') return `<p class="st-done gold">${ic('gift', 22, 'f')}<span><b>คุณได้รับเลือก</b><small>ตอบรับภายในเวลาที่กำหนด</small></span></p>` + timer('เหลือเวลาตอบรับ', BOOT + (86400 + 23 * 3600 + 59 * 60) * 1000)
    + `<button class="btn red wide" data-act="tapMain">${ic('gift', 20)}ตอบรับกิจกรรม</button>`;
  if (s.draftApproved && !s.reviewed) return timer('เหลือเวลาส่งลิงก์รีวิว', BOOT + (23 * 3600 + 59 * 60) * 1000) + `<button class="btn red wide" data-act="tapMain">${ic('paperPlaneTilt', 20)}ส่งลิงก์รีวิว</button>`;
  return status('package', s.reviewed ? 'เสร็จสิ้นการส่งรีวิวกิจกรรม' : ORDER_LABEL[s.order], s.reviewed ? 'ok' : '')
    + `<button class="btn red wide" data-act="tapMain">${ic('clipboardText', 20)}${s.reviewed ? 'ดูโพสต์รีวิว' : 'รายละเอียดการรีวิว'}</button>`;
}

// ---------- โปรไฟล์ Sale Here ----------
function profileView() {
  const stat = (n, l) => `<div><b>${n}</b><span>${l}</span></div>`;
  return `<div class="two prof"><section class="card" aria-label="โปรไฟล์"><div class="cover">${ic('imageSquare', 40)}</div>
    <div class="pad prof-id"><span class="gc-av star big">${avatar(104)}<i class="badge">${ic('star', 16, 'f')}</i></span>
      <div class="prof-name"><h1>${F.isVerified ? `<span class="seal on">${ic('sealCheck', 20, 'f')}</span>` : ''}${esc(userName())}</h1><p>${esc(userBio())}</p></div>
      <div class="stats">${stat(0, 'ผู้ติดตาม')}${stat(0, 'กำลังติดตาม')}${stat(5, 'โพสต์')}${stat(7, 'Engagement')}</div>
      <div class="btn-row"><button class="btn red-line">${ic('pencilSimple', 18)}แก้ไขโปรไฟล์</button><button class="btn red-line" data-act="openStar">${ic('identificationCard', 18)}โปรไฟล์ครีเอเตอร์</button></div>
      <div class="tiles"><div class="tile blue"><i>${ic('ticket', 20, 'f')}</i><span><b>Coupon</b><small>เก็บคูปอง</small></span></div>
        <button class="tile red" data-act="tab" data-arg="home"><i>${ic('star', 20, 'f')}</i><span><b>Sale Here STAR</b><small>15 กิจกรรม</small></span></button></div></div></section>
    <section aria-label="โพสต์">${starBanner()}<div class="card pad composer">${avatar(40)}<p>สวัสดีค่ะ คุณ ${esc(userName())}, โพสต์บอกเล่าประสบการณ์ หรือรีวิวกิจกรรมของคุณ</p>${ic('imageSquare', 22)}</div>
      <div class="draft-banner"><i>${ic('notePencil', 20, 'f')}</i><b>สถานะดราฟต์รีวิว</b></div>
      <div class="photo-grid">${['ph01', 'ph02', 'ph03', 'ph04'].map(n => `<img src="assets/${n}.jpg" alt="โพสต์ของ ${esc(userName())}">`).join('')}<img src="assets/cover-thymora.png" alt="โพสต์ของ ${esc(userName())}"></div></section></div>`;
}

// ---------- ฟอร์มสมัครเดิม (= RegisterFormPage) — ที่อยู่ 7 ช่องเหมือนแอปหลัก · ปุ่มกดได้เมื่อยอมรับเงื่อนไข + Line ID + ที่อยู่ครบ ----------
function initReg() {
  const c = campaign(), r = UI.reg = { answers: {}, checks: [], uploaded: false }, a = F.s.addressInfo;
  // ชื่อ+เบอร์ แอปหลักเติมจากโปรไฟล์ให้เสมอ (ไม่ขึ้นกับสวิตช์กรอกตัวอย่าง) · ที่อยู่ชุดเดียวกับ myAddress งานถัดไปเติมให้เอง
  if (!a.name) a.name = 'มณีรัตน์ ใจดี'; if (!a.tel) a.tel = '0891234567';
  if (!F.s.autofill) { F.save(); return; }
  if (!a.address) Object.assign(a, SAMPLE_ADDRESS(a.name), { tel: a.tel });
  F.save();
  if (!F.s.lineID) F.s.lineID = '@maneerat.review';
  c.questions.forEach((q, i) => { if (q.kind === 'text') r.answers[i] = 'เคยรีวิวสกินแคร์ให้หลายแบรนด์ ผิวแพ้ง่าย ใช้จริงก่อนรีวิวทุกครั้ง'; if (q.kind === 'radio') r.answers[i] = q.options[0]; if (q.kind === 'checkbox') r.checks = [q.options[0]]; if (q.kind === 'upload') r.uploaded = true; });
}
function regMissing() { const m = []; if (!F.addressFull()) m.push('ที่อยู่'); if (!F.s.lineID.trim()) m.push('Line ID'); if (!F.s.consent) m.push('ยอมรับเงื่อนไข'); return m; }
function registerView() {
  if (!UI.reg) initReg();
  const c = campaign(), r = UI.reg, miss = regMissing();
  const q = (x, i) => {
    const id = 'q' + i, lab = `<span class="q-lab" id="${id}"><em>*</em> ${esc(x.q)}</span>`;
    if (x.kind === 'text') return `<div class="q">${lab}<textarea rows="3" aria-labelledby="${id}" data-bind="ui.reg.answers.${i}" placeholder="กรอกคำตอบ">${esc(r.answers[i] || '')}</textarea></div>`;
    if (x.kind === 'radio') return `<div class="q" role="radiogroup" aria-labelledby="${id}">${lab}<div class="opts">${x.options.map(o => `<label class="opt"><input type="radio" name="${id}" ${r.answers[i] === o ? 'checked' : ''} data-act="regRadio" data-arg="${i}|${esc(o)}"><span>${esc(o)}</span></label>`).join('')}</div></div>`;
    if (x.kind === 'checkbox') return `<div class="q" role="group" aria-labelledby="${id}">${lab}<small>เลือกได้มากกว่า 1 ตัวเลือก</small><div class="opts">${x.options.map(o => `<label class="opt"><input type="checkbox" ${r.checks.includes(o) ? 'checked' : ''} data-act="regCheck" data-arg="${esc(o)}"><span>${esc(o)}</span></label>`).join('')}</div></div>`;
    return `<div class="q">${lab}<div class="up-row">${r.uploaded ? `<img src="assets/ph03.jpg" alt="ไฟล์ที่แนบ">` : ''}<button class="add-tile" data-act="regUpload" aria-labelledby="${id}">${ic('plus', 20)}เพิ่มรูป</button></div></div>`;
  };
  const sc = x => {
    const on = F.s.connected.includes(x.id), n = F.insightCount(x.id);
    return `<li class="reg-soc ${on ? 'on' : ''}">${on ? avatar(40) : soc(x.id, 40)}<div><b>${on ? esc(F.handle(x.id)) : x.name.toUpperCase()}</b>${on ? `<small>${esc(F.link(x.id))}</small><small>${ic('usersThree', 14)}${F.fmt(F.followers(x.id))} ผู้ติดตาม${x.insight ? ` · ข้อมูลผู้ติดตาม ${n >= 3 ? 'ครบ' : n + '/3'}` : ''}</small>` : ''}</div>
      <span class="state ${on ? 'ok' : ''}">${on ? 'ผูกบัญชีแล้ว' : 'ยังไม่ได้ผูกบัญชี'}</span></li>`;
  };
  return focusPage({ close: 'closeScreen', ctx: `<b>ลงทะเบียนร่วมกิจกรรม</b>`, body: `<div class="two form">
    <form class="stack" onsubmit="return false" novalidate><h1 class="sr">ลงทะเบียนร่วมกิจกรรม ${c.episode}</h1>
      <fieldset class="card pad"><legend>ข้อมูลที่อยู่</legend>${addressFields()}<div class="grid2">${field('Line ID', 's.lineID', { req: 1, ph: '@yourlineid', live: 1 })}</div></fieldset>
      ${c.questions.length ? `<fieldset class="card pad"><legend>คำถามจาก ${esc(c.brand)}</legend>${c.questions.map(q).join('')}</fieldset>` : ''}
      <fieldset class="card pad"><legend>โซเชียลมีเดีย</legend><p class="hint"><em>*</em> ลิงก์โซเชียลมีเดียที่ต้องการลงทะเบียน (ผูกบัญชีอย่างน้อย 1 ช่องทางเพื่อส่งรีวิว)</p><ul class="reg-socs">${SOCIALS.map(sc).join('')}</ul></fieldset>
      <label class="consent"><input type="checkbox" ${F.s.consent ? 'checked' : ''} data-act="consent"><span><b>ฉันยอมรับข้อกำหนดและเงื่อนไข</b><small>ฉันยินยอมที่จะโพสต์รีวิวสินค้า และเปิดเป็นสาธารณะ ตามช่องทางโซเชียลมีเดียที่ลงทะเบียนไว้ภายหลังจากได้รับกล่อง Unbox หากไม่ได้รีวิวตามเวลาที่กำหนด ฉันจะถูกตัดสิทธิ์และไม่สามารถลงทะเบียนเข้าร่วมกิจกรรม ‘Sale Here UNBOX’ ได้อีกในครั้งต่อไป</small></span></label>
    </form>
    <aside class="side"><div class="card pad">
      <button class="btn red wide" data-act="submitRegister" ${miss.length ? 'aria-disabled="true"' : ''} aria-describedby="reg-miss">${ic('notePencil', 20)}ลงทะเบียนร่วมกิจกรรม</button>
      <p id="reg-miss" class="miss" aria-live="polite">${miss.length ? 'ยังขาด: ' + miss.join(' · ') : ''}</p></div></aside></div>` });
}

// ---------- หน้าตอบรับเดิม (= AcceptPage) ----------
function acceptView() {
  const c = campaign(), a = F.s.addressInfo, sec = (t, b) => `<section><h2 class="h-sm">${t}</h2>${b}</section>`;
  return focusPage({ close: 'closeScreen', back: 1, closeLabel: 'กลับหน้ากิจกรรม', ctx: `<b>รายละเอียดตอบรับกิจกรรม</b>`, body: `<div class="two form"><div class="stack"><h1 class="sr">รายละเอียดตอบรับกิจกรรม ${c.episode}</h1>
    <div class="card pad acc">${sec('โซเชียลที่คุณต้องรีวิว', `<div class="socs">${c.channels.map(x => soc(x, 32)).join('')}</div>`)}
      ${sec('ประเภทคอนเทนต์ที่ต้องรีวิว', `<ul class="plain-list">${c.contentTypes.map(t => `<li>${t}</li>`).join('')}</ul>`)}
      ${c.timeline.length ? sec('Timeline แคมเปญ', `<ol class="timeline dots">${c.timeline.slice(3).map(t => `<li><span>${t[0]}</span><b>${t[1]}</b></li>`).join('')}</ol>`) : ''}
      ${sec('ที่อยู่ในการจัดส่ง', `<div class="addr"><p><b>${esc(a.name)}</b><span>${esc(a.tel)}</span><span>${esc([a.address, a.sub, a.district, a.province, a.zip].filter(Boolean).join(' '))}</span></p><button class="link red" data-act="editAddress">${ic('pencilSimple', 14)}แก้ไขที่อยู่</button></div>`)}
      ${sec('ข้อมูลที่ควรรู้ก่อนตอบรับ', `<ul class="bullets"><li>ต้องส่งดราฟต์รีวิวภายในเวลาที่กำหนด และโพสต์จริงหลังดราฟต์ผ่านเท่านั้น</li><li>หากไม่ส่งรีวิวตามกำหนด จะถูกตัดสิทธิ์และไม่สามารถลงทะเบียนกิจกรรมอื่นได้</li><li>ของรางวัลจะจัดส่งตามที่อยู่ข้างต้น กรุณาตรวจสอบให้ถูกต้อง</li></ul>`)}</div>
    ${c.acceptQuestions.map((x, i) => `<div class="card pad q" role="radiogroup" aria-labelledby="aq${i}"><span class="q-lab" id="aq${i}"><em>*</em> ${esc(x.q)}</span><div class="opts">${x.options.map(o => `<label class="opt"><input type="radio" name="aq${i}" ${UI.acceptAnswer === o ? 'checked' : ''} data-act="acceptAnswer" data-arg="${esc(o)}"><span>${esc(o)}</span></label>`).join('')}</div></div>`).join('')}</div>
    <aside class="side"><div class="card pad"><div class="sum">${jobChip(c)}<b>${esc(c.title)}</b></div>
      <div class="st-clock"><span>${ic('calendarBlank', 18)}เหลือเวลาตอบรับ</span>${clock(BOOT + (86400 + 23 * 3600 + 59 * 60) * 1000)}</div>
      <button class="btn red wide" data-act="askAccept">${ic('gift', 20)}ตอบรับกิจกรรม</button><button class="btn quiet wide" data-act="askDecline">${ic('xCircle', 18)}สละสิทธิ์</button></div></aside></div>` });
}

// ---------- หน้าส่งลิงก์รีวิวเดิม (= LinkPage) — ช่องบังคับ = ช่องทางที่กิจกรรมกำหนด ----------
const linkValid = id => /^https?:\/\/\S+$/.test(UI.linkDraft[id] || '');
function linkView() {
  const c = campaign(), ready = c.channels.every(linkValid), names = ['สร้างดราฟต์รีวิว', 'ส่งดราฟต์รีวิว', 'ส่งลิงก์'];
  const fld = id => { const v = UI.linkDraft[id] || '', bad = v && !linkValid(id) && UI.linkTouched[id];
    return `<label class="link-f ${bad ? 'bad' : ''}"><span class="sr">ลิงก์โพสต์รีวิวบน ${SOC[id].name}</span><span class="in">${soc(id, 26)}<input type="url" data-bind="ui.linkDraft.${id}" data-live="1" value="${esc(v)}" placeholder="วางลิงก์โพสต์รีวิวบน ${SOC[id].name} ของคุณ" ${bad ? `aria-invalid="true" aria-describedby="le-${id}"` : ''}></span>
      ${bad ? `<small id="le-${id}" class="err">ลิงก์ไม่ถูกต้อง — ต้องขึ้นต้นด้วย https://</small>` : `<small>${ic('info', 14)}ตรวจสอบบัญชี ${SOC[id].name} ที่ลงทะเบียน</small>`}</label>`; };
  return focusPage({ close: 'closeScreen', ctx: `<b>ส่งลิงก์รีวิว</b>`, body: `<div class="two form"><div class="card pad stack"><h1 class="sr">ส่งลิงก์รีวิว ${c.episode}</h1>
    <ol class="steps3" aria-label="ขั้นตอนงานรีวิว">${names.map((n, i) => `<li class="${i < 2 ? 'done' : 'cur'}" ${i === 2 ? 'aria-current="step"' : ''}><i>${i < 2 ? ic('check', 13, 'b') : i + 1}</i>${n}</li>`).join('')}</ol>
    <fieldset><legend><em>*</em> ลิงก์โพสต์รีวิวบนโซเชียลมีเดีย ที่เราอยากให้คุณส่งรีวิว <small>(วางลิงก์รีวิวให้ครบทุกช่องทาง)</small></legend>${c.channels.map(fld).join('')}</fieldset>
    <fieldset><legend>ลิงก์โพสต์รีวิวบนโซเชียลมีเดีย ที่สามารถส่งรีวิวเพิ่มเติม</legend>${SOCIALS.filter(x => !c.channels.includes(x.id)).map(x => fld(x.id)).join('')}</fieldset></div>
    <aside class="side"><div class="card pad"><div class="sum">${jobChip(c)}<b>${esc(c.title)}</b></div>
      <div class="st-clock"><span>${ic('calendarBlank', 18)}เหลือเวลาส่งลิงก์รีวิว</span>${clock(BOOT + (23 * 3600 + 59 * 60) * 1000)}</div>
      <button class="btn red wide" data-act="submitLinks" ${ready ? '' : 'aria-disabled="true"'} aria-describedby="link-miss">${ic('paperPlaneTilt', 20)}ส่งลิงก์รีวิว</button>
      <p id="link-miss" class="miss" aria-live="polite">${ready ? '' : 'ยังขาด: ลิงก์ ' + c.channels.filter(x => !linkValid(x)).map(x => SOC[x].name).join(' · ')}</p></div></aside></div>` });
}

// ---------- ยืนยันตัวตน (= KycMockPage) — desktop: กล้องคอมถ่ายบัตรไม่ชัด → มือถือเป็นทางหลัก · อัปโหลดไฟล์เป็นทางรอง ----------
function kycView() {
  const k = UI.kyc, order = ['type', 'card', 'face'], at = order.indexOf(k.step);
  const dots = `<ol class="steps3" aria-label="ขั้นตอนยืนยันตัวตน">${['เลือกเอกสาร', 'ถ่าย' + k.doc, 'ถ่ายใบหน้า'].map((n, i) => `<li class="${at > i || at < 0 ? 'done' : at === i ? 'cur' : ''}" ${at === i ? 'aria-current="step"' : ''}><i>${at > i || at < 0 ? ic('check', 13, 'b') : i + 1}</i>${n}</li>`).join('')}</ol>`;
  let body;
  if (k.step === 'type') body = `<div class="kyc-2"><div role="radiogroup" aria-labelledby="kyc-h"><h1 id="kyc-h">เลือกเอกสารที่ใช้ยืนยันตัวตน</h1>
      ${['บัตรประชาชน', 'หนังสือเดินทาง'].map(d => `<label class="pick ${k.doc === d ? 'on' : ''}"><input type="radio" name="doc" ${k.doc === d ? 'checked' : ''} data-act="kycDoc" data-arg="${d}"><i>${ic('identificationCard', 24)}</i><b>${d}</b></label>`).join('')}
      <button class="btn red" data-act="kycStep" data-arg="card">ถัดไป ${ic('arrowRight', 16, 'b')}</button></div>
    <div class="tips"><h2 class="h-sm">วิธีถ่าย${k.doc}</h2><ul>${['วางบัตรบนพื้นเรียบ ไม่มีแสงสะท้อน', 'ให้บัตรอยู่ในกรอบ เห็นครบทั้ง 4 มุม', 'ถ่ายใบหน้าตรง ไม่ใส่หมวก/แว่นดำ', 'ข้อมูลใช้เพื่อยืนยันตัวตนเท่านั้น'].map(t => `<li>${ic('checkCircle', 18, 'f')}${t}</li>`).join('')}</ul></div></div>`;
  else if (k.step === 'card' || k.step === 'face') {
    const face = k.step === 'face', next = face ? 'checking' : 'face';
    body = `<h1>${face ? 'ถ่ายใบหน้าของคุณ' : 'ถ่ายด้านหน้า' + k.doc}</h1><p class="lead">${face ? 'ให้ใบหน้าอยู่ในกรอบ' : 'ให้บัตรอยู่ในกรอบ เห็นครบ 4 มุม'}</p>
      <div class="kyc-2"><div class="cam ${face ? 'face' : ''}"><span class="frame"></span>${isMobile() ? `<button class="btn white" data-act="kycStep" data-arg="${next}">${ic('camera', 18, 'b')}${face ? 'ถ่ายใบหน้า' : 'ถ่ายรูปบัตร'}</button>` : `<button class="btn white" data-act="kycStep" data-arg="${next}">${ic(face ? 'webcam' : 'uploadSimple', 18, 'b')}${face ? 'ถ่ายด้วยกล้องเครื่องนี้' : 'อัปโหลดรูปบัตร'}</button>${face ? '' : `<button class="link white" data-act="kycStep" data-arg="${next}">หรือถ่ายด้วยกล้องเครื่องนี้</button>`}`}</div>
      ${isMobile() ? '' : `<div>${qrBox(face ? 'ถ่ายใบหน้าด้วยกล้องหน้า' : 'ถ่ายบัตรให้คมชัดกว่ากล้องคอม', ['kycStep', next])}</div>`}</div>`;
  } else if (k.step === 'checking') body = `<div class="kyc-mid" role="status"><span class="spin"></span><h1>ระบบกำลังประมวลผลภาพ</h1><p class="lead">ขั้นตอนนี้อาจใช้เวลาประมาณ 1–2 นาที<br>กรุณาอย่าปิดหรือออกจากหน้านี้จนกว่าระบบจะดำเนินการเสร็จสิ้น</p></div>`;
  // OCR อ่านไม่ผ่าน (Lab "AI ไม่ผ่าน") — แอปหลักให้ลองใหม่ แล้วตกไปฟอร์มที่เติมค่าจาก OCR ให้กรอกส่งเอง
  else if (k.step === 'ocrFail') body = `<div class="kyc-mid" role="alert"><span class="big-ok warn">${ic('warning', 48, 'f')}</span><h1>ภาพบัตรประชาชนไม่ชัดเจน</h1><p class="lead">กรุณาถ่ายภาพใหม่ให้บัตรอยู่ในกรอบ ภาพคมชัดและเห็นข้อมูลทุกส่วนอย่างชัดเจน ไม่มีเงาสะท้อนทับตัวอักษร</p><button class="btn red" data-act="kycStep" data-arg="form" autofocus>ลองใหม่อีกครั้ง</button></div>`;
  else if (k.step === 'form') body = kycForm(k);
  else if (k.step === 'prompt') body = `<div class="kyc-prompt"><h1>กรุณายืนยันการส่งข้อมูลเพื่อยืนยันตัวตน</h1><p class="lead">โปรดตรวจสอบข้อมูลของคุณอีกครั้งก่อนส่ง!</p>
      ${k.manual ? `<p class="warn-red">หากข้อมูลไม่ตรงกับบัตรประชาชน คุณจะไม่ผ่านการอนุมัติ</p>` : ''}
      <dl class="kyc-dl">${KYC_OCR_ROWS.map(([l, v]) => `<div><dt>${l}</dt><dd>${esc(v)}</dd></div>`).join('')}</dl>
      <div class="btn-row"><button class="btn red" data-act="kycStep" data-arg="${k.manual ? 'sent' : 'done'}" autofocus>ยืนยัน</button><button class="btn red-line" data-act="kycStep" data-arg="form">แก้ไข</button></div></div>`;
  else if (k.step === 'sent') body = `<div class="kyc-mid"><span class="big-ok">${ic('sealCheck', 56, 'f')}</span><h1>ส่งคำขอยืนยันตัวตนสำเร็จ</h1><p class="lead">รอการอนุมัติภายใน 7 วันทำการ</p><button class="btn red" data-act="kycFinish" autofocus>ปิด</button></div>`;
  else body = `<div class="kyc-mid"><span class="big-ok">${ic('sealCheck', 56, 'f')}</span><h1>ยืนยันตัวตนเสร็จสมบูรณ์</h1><p class="lead">ยินดีต้อนรับสู่ประสบการณ์ใหม่ที่ครบครันกว่าเดิม<br>สิทธิพิเศษของคุณพร้อมใช้งานแล้ว</p><button class="btn red" data-act="kycFinish" autofocus>ตกลง</button></div>`;
  // ฟอร์มของคนที่โดนตีกลับไม่มีปุ่มย้อน (แอปหลักเปิดฟอร์มเป็นหน้าแรก)
  const back = { type: null, card: 'type', face: 'card', form: F.s.verify === 'rejected' ? null : 'face', prompt: 'form' }[k.step];
  return focusPage({ cls: 'kyc', close: back ? 'kycStep' : 'kycClose', back: !!back, closeLabel: back ? 'ย้อนกลับ' : 'ปิด', ctx: '<b>ยืนยันตัวตน</b>', arg: back, body: `<div class="kyc-in">${dots}${body}</div>` });
}

// ค่าที่ OCR อ่านได้ (จำลอง = KycOCR)
const KYC_OCR_ROWS = [['เลขบัตรประชาชน', '1-1037-00123-45-6'], ['วันที่บัตรหมดอายุ', '12 ก.ย. 2574'], ['ชื่อ', 'นางสาว มณีรัตน์ ใจดี'], ['วันเกิด', '5 มี.ค. 2541'],
  ['ที่อยู่', '99/12 คอนโดลุมพินี ซ.สุขุมวิท 77 สวนหลวง สวนหลวง กรุงเทพมหานคร 10250']];
// ฟอร์มยืนยันตัวตน (= VerifyUserStatusForm) — Step 1 รูป · Step 2 ข้อมูลที่ OCR เติมให้ · ตีกลับ = การ์ดสถานะแดง + เหตุผลอยู่บนสุด
function kycForm(k) {
  const tile = (cap, face, note, cls) => `<div class="kyc-tile"><span class="ph ${face ? 'face' : ''}">${ic(face ? 'user' : 'identificationCard', 30)}</span><b>${cap}</b><small class="${cls}">${note}</small></div>`;
  const ro = (l, v, o = {}) => `<label class="fld ${o.cls || ''}"><span>${l} <em>*</em></span><span class="in"><input value="${esc(v)}" ${o.dim ? 'readonly' : ''}></span></label>`;
  return `<div class="kyc-form">${F.s.verify === 'rejected' ? `<div class="kyc-rej"><span class="ph">${ic('identificationCard', 28)}</span><div><b>เราได้รับข้อมูลการยืนยันตัวตนแล้ว</b><p>สถานะ : <em>ไม่ผ่านการอนุมัติ</em></p></div>
      <p class="why">${ic('xCircle', 16, 'b')}${esc(F.rejectReason)}</p></div>` : ''}
    <h1 class="sr">ยืนยันตัวตน</h1>
    <section><h2 class="h-sm">Step 1 : ถ่ายรูป</h2><div class="kyc-tiles">${tile('หน้าบัตรประชาชน', false, 'รูปบัตรประชาชนสำหรับยืนยันตัวตน โปรดมั่นใจว่าชัดเจนและถูกต้อง', 'blue')}${tile('รูปคู่บัตรประชาชน', true, 'ภาพไม่ถูกต้องหรือไม่ชัดเจน กรุณาตรวจสอบอีกครั้งก่อนส่ง', 'red')}</div>
      <button class="btn red-line sm" data-act="kycStep" data-arg="card">${ic('camera', 16)}ถ่ายรูปบัตรประชาชนและรูปคู่ใหม่</button></section>
    <section><h2 class="h-sm">Step 2 : กรอกข้อมูลส่วนตัว</h2><p class="kyc-sub">ข้อมูลบัตรประชาชน</p>
      <div class="grid2">${ro('เลขบัตรประชาชน', '1103700123456')}${ro('วันที่บัตรหมดอายุ', '12 ก.ย. 2574')}${ro('คำนำหน้าชื่อ', 'นางสาว')}${ro('วันเกิด', '5 มี.ค. 2541')}${ro('ชื่อ (ภาษาไทย)', 'มณีรัตน์')}${ro('นามสกุล (ภาษาไทย)', 'ใจดี')}</div>
      <p class="kyc-sub">ข้อมูลที่อยู่</p>
      <div class="grid2">${ro('รายละเอียดที่อยู่ (ตามบัตรประชาชน)', '99/12 คอนโดลุมพินี ซ.สุขุมวิท 77', { cls: 'span2' })}${ro('รหัสไปรษณีย์', '10250')}${ro('ตำบล/แขวง', 'สวนหลวง')}${ro('อำเภอ/เขต', 'สวนหลวง', { dim: 1 })}${ro('จังหวัด', 'กรุงเทพมหานคร', { dim: 1 })}</div></section>
    <button class="btn red wide" data-act="kycStep" data-arg="prompt">ยืนยันตัวตน</button></div>`;
}

// ---------- หน้าสถานะยืนยันตัวตน (= KycStatusPage) — กดลงทะเบียนตอนติดด่าน (รอตรวจ/ตีกลับ) · แจ้งเตือนตีกลับ ----------
// โครงขาวแบบ wizard (ผู้ใช้ 6 ต.ค. 2569: "ต้องโครงสีขาว ไม่ใช่สีแดง") · minimal: หัวข้อ + ชิป + การ์ดภาพ + ปุ่ม (ไม่มีไทม์ไลน์/การ์ดงานค้าง)
function kycStatusView() {
  const waiting = F.s.verify === 'waiting', c = campaign();
  const lines = waiting ? ['แจ้งผลภายใน 3 วันทำการ', 'คำตอบที่กรอกไว้ยังอยู่ครบ'] : ['ส่งใหม่ได้เลย ไม่ต้องรอ', 'คำตอบที่กรอกไว้ยังอยู่ครบ'];
  const foot = waiting ? `<button class="btn dark wide" data-act="closeScreen" autofocus>กลับไปหน้ากิจกรรม ${ic('arrowRight', 16, 'b')}</button>
      <button class="btn text wide ${UI.cancelAsk ? 'danger' : ''}" data-act="kycCancel">${UI.cancelAsk ? 'แตะอีกครั้งเพื่อยกเลิกคำขอ · ต้องถ่ายใหม่ทั้งหมด' : 'ยกเลิกคำขอยืนยันตัวตน'}</button>`
    : `<button class="btn dark wide" data-act="kycResubmit" autofocus>${ic('identificationCard', 18)}ส่งยืนยันตัวตนใหม่</button><p class="kyc-help">ติดปัญหาเอกสาร? ติดต่อทีม Sale Here</p>`;
  return focusPage({ cls: 'kyc-st', close: 'closeScreen', ctx: `<b>ยืนยันตัวตน</b> · ${esc(c.title)}`, body: `<div class="kst">
    <div class="wz-q"><h1>${waiting ? 'ทีมงานกำลังตรวจเอกสาร 🪪' : 'เอกสารยังไม่ผ่าน 🪪'}</h1><ul class="nudges">${lines.map((l, i) => `<li>${i === 0 ? ic('eye', 14, 'b') : ''}${l}</li>`).join('')}</ul></div>
    ${kycHero()}<div class="kst-foot">${foot}</div></div>` });
}
// แจ้งเตือนจำลอง (= push userVerifyApprove / userVerifyReject) — มุมขวาบน คลิกแล้วพาไปต่อ
function pushView() {
  const p = UI.push;
  return `<div class="push" role="status" aria-live="polite"><button class="push-b" data-act="pushTap"><i class="${p.warn ? 'warn' : ''}">${ic(p.warn ? 'warning' : 'sealCheck', 20, 'f')}</i>
    <span><small>Sale Here · ตอนนี้</small><b>${esc(p.title)}</b><span>${esc(p.body)}</span></span></button><button class="x" data-act="pushClose" aria-label="ปิดแจ้งเตือน">${ic('x', 14, 'b')}</button></div>`;
}

// ---------- dialog ----------
function dialogView() {
  const d = UI.dialog, w = UI.wiz;
  if (d.type === 'registerSuccess') {
    const done = F.isMember;   // ตีกลับ = ชวนทำใหม่
    return `<div class="scrim"><div class="modal small" role="dialog" aria-modal="true" aria-labelledby="m-title"><button class="x abs" data-act="closeDialog" aria-label="ปิด">${ic('x', 18, 'b')}</button>
      <div class="m-body center"><span class="big-ok pop">${ic('checkCircle', 64, 'f')}</span><h2 id="m-title">ลงทะเบียนสำเร็จ</h2><p>ผู้ที่ผ่านการคัดเลือกจะได้รับการแจ้งเตือน<br>ให้ยืนยันสิทธิ์ผ่านแอปฯ Sale Here</p>
        ${done ? (F.s.verify === 'waiting' ? `<p class="muted-c">ส่งยืนยันตัวตนแล้ว · ทีมงานตรวจภายใน 1–3 วันทำการ</p>` : '') : `<p class="warn-red">กรุณายืนยันตัวตน เพื่อความรวดเร็วในการผ่านการคัดเลือก</p>`}</div>
      <footer class="stack">${done ? `<button class="btn red" data-act="closeDialog">${ic('shareFat', 18)}แชร์กิจกรรมนี้</button>`
        : `<button class="btn red" data-act="dialogKyc">${ic('identificationCard', 18)}ยืนยันตัวตน</button><button class="btn quiet" data-act="closeDialog">${ic('shareFat', 18)}แชร์กิจกรรมนี้</button>`}</footer></div></div>`;
  }
  if (d.type === 'getApp') return `<div class="scrim" data-act="closeDialog" data-self="1"><div class="modal small getapp-m" role="dialog" aria-modal="true" aria-labelledby="m-title"><header><h2 id="m-title">ยืนยันตัวตน</h2><button class="x" data-act="closeDialog" aria-label="ปิด">${ic('x', 18, 'b')}</button></header>
    <div class="m-body">${getAppBox()}</div></div></div>`;
  if (d.type === 'wizExit') {
    // = `STAR_WZ_EXIT_*` ของ salehere-ios ตรงตัว ("ทำไปแล้ว 0/N" ก็โชว์)
    const left = d.total - d.done;
    return confirmBox(left <= 2 ? `เหลืออีก ${left} ข้อ จะออกเลยเหรอ` : 'เก็บไว้ทำต่อทีหลังไหม',
      `ทำไปแล้ว ${d.done}/${d.total} · ข้อมูลที่กรอกไว้ยังอยู่<br>กลับมากดสมัครอีกครั้งจะได้ทำต่อจากตรงนี้`, [['ทำต่อเลย', 'closeDialog', 1], ['เก็บไว้แล้วออก', 'wizLeave']]);
  }
  // Lab ผลยืนยันตัวตน (= iOS confirmationDialog "Lab · ผลยืนยันตัวตน") — กดเริ่ม/ส่งใหม่ → เลือกผลที่จะจำลอง (เครื่องนี้เท่านั้น)
  if (d.type === 'kycLab') return confirmBox('Lab · ผลยืนยันตัวตน', `ตอนนี้ใช้ Lab: ${esc(VERIFY_LABEL[F.s.verify])}<br>เลือกผลที่จะจำลอง (เครื่องนี้เท่านั้น)`,
    [...KYC_LAB.map(([v, t]) => [t, 'kycLabPick', 0, v]), ['ถ่ายบัตรจริง (flow เดิม)', 'kycLabReal'], ['ยกเลิก', 'closeDialog']]);
  // เอาช่องออก = ยืนยันก่อน (salehere-ios)
  if (d.type === 'unlinkChannel') return confirmBox('ยกเลิกการผูกบัญชี', '', [['ยืนยัน', 'removeChannel', 1], ['ยกเลิก', 'closeDialog']]);
  if (d.type === 'acceptConfirm') return confirmBox('ยืนยันตอบรับกิจกรรม', 'เมื่อตอบรับแล้ว ต้องส่งดราฟต์และโพสต์รีวิวตามกำหนดของกิจกรรม', [['ตอบรับกิจกรรม', 'doAccept', 1], ['ยกเลิก', 'closeDialog']]);
  if (d.type === 'declineConfirm') return confirmBox('สละสิทธิ์กิจกรรมนี้?', 'สิทธิ์จะถูกส่งต่อให้ผู้รับรางวัลสำรอง', [['ยกเลิก', 'closeDialog', 1], ['สละสิทธิ์', 'doDecline']]);
  if (d.type === 'share') return `<div class="scrim" data-act="closeDialog" data-self="1"><div class="modal small" role="dialog" aria-modal="true" aria-labelledby="m-title"><header><h2 id="m-title">แชร์ ${esc(d.what)}</h2><button class="x" data-act="closeDialog" aria-label="ปิด">${ic('x', 18, 'b')}</button></header>
    <div class="m-body"><div class="copy-row"><input readonly value="${esc(d.url)}" aria-label="ลิงก์" onfocus="this.select()"><button class="btn dark sm" data-act="copyLink" data-arg="${esc(d.url)}">${ic('copy', 16, 'b')}คัดลอก</button></div></div></div></div>`;
  return '';
}
// ได้เป็น STAR — ปิดจอทึบตั้งแต่เฟรมแรก ตรา ST★R ทองขึ้นกลางจอ แล้วหน้าถัดไปค่อยโผล่ (ย่อจาก LevelUpOverlay)
function levelUpView() { return `<div class="levelup" role="status" aria-live="polite"><div class="lu-in">${starMark(64, 'gold')}<p>${starText('คุณเป็น STAR แล้ว', 17)}</p><small>ยืนยันตัวตนผ่าน · แบรนด์เลือกคุณได้แล้ว</small></div></div>`; }
