// แกนของหน้า desktop: state ของ UI · ตัววาด · ตัวนำทาง (= SaleHereShell.swift) · ชิ้นส่วนร่วม
// โครงเดียวกับ shell ของ iOS: แท็บ → กิจกรรมที่เปิด → หน้า flow → ชั้นทับ (Insight/ตารางงาน/KYC) → dialog → toast

const UI = { tab: 'home', campaignId: null, screen: null, wiz: null, insight: false, schedule: false, kyc: null, dialog: null, modal: null, push: null, cancelAsk: false,
  toast: null, lab: false, levelUp: null, cardAfter: null, campTab: 'howTo', reg: null, acceptAnswer: null, linkDraft: {}, linkTouched: {}, listOpen: null, laterOpen: null, teaseT: 0, teaseW: 0, teaseWide: false, insLoading: false, range: 'week',
  sched: { sel: SD.today, job: null, ask: null }, provinceQ: '' };
const HIDE_LAB = new URLSearchParams(location.search).get('lab') === '0';
const REDUCED = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
// จอมือถือ (≤640) = หน้าตาเดียวกับแอป iOS — ช่องกรอกบางข้อวาดคนละแบบ จึงวาดใหม่เมื่อข้ามเส้นนี้
const MOBILE = window.matchMedia('(max-width: 640px)');
const isMobile = () => MOBILE.matches;
MOBILE.addEventListener('change', () => render());

const esc = s => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const ic = (name, size = 20, w = 'r') => `<svg class="ic" width="${size}" height="${size}" viewBox="0 0 256 256" fill="currentColor" aria-hidden="true">${(PH[name] || PH.circleDashed)[w] || PH[name].r}</svg>`;
const starMark = (h = 18, cls = '') => `<svg class="starmark ${cls}" height="${h}" width="${(h * 32.4 / 10.4).toFixed(1)}" viewBox="0.8 10.7 32.4 10.4" role="img" aria-label="STAR"><path fill="currentColor" fill-rule="evenodd" d="${STAR_MARK}"/></svg>`;
// คำ STAR ในข้อความ = ตรา ST★R (ผู้ใช้ 30 ก.ย. 2569)
const starText = (t, h = 11) => esc(t).replace(/STAR/g, starMark(h, 'inline'));
const soc = (id, size = 28) => `<img class="soc" src="assets/soc-${id}.png" width="${size}" height="${size}" alt="${SOC[id].name}">`;
const campaign = () => CAMPAIGNS.find(c => c.id === UI.campaignId) || CAMPAIGNS[0];
const userName = () => ACCOUNT_NAME;
const userBio = () => (F.has('about') && F.s.about) || FALLBACK_BIO;
const avatar = (size = 40, cls = '') => `<img class="avatar ${cls}" src="${F.s.media.photos[0] || 'assets/ph01.jpg'}" width="${size}" height="${size}" alt="">`;

// [ไฟล์, เป็นแนวนอน (Portfolio 3 หน้า)] — สลับแนวนอน/แนวตั้ง · รูปอบชุดเดียวกับ Resources/DesignedTemplates ของ iOS
const TEMPLATES = [['designed.391530', 1], ['designed.3119bb', 0], ['designed.ac57a7', 1], ['designed.34534a', 0], ['designed.6da8ac', 0]];

// ---------- วาด ----------
const root = () => document.getElementById('app');
function render() {
  const a = document.activeElement, key = a && a.dataset ? (a.dataset.bind || a.id) : null, sel = a && 'selectionStart' in a ? [a.selectionStart, a.selectionEnd] : null;
  const scrolls = [...document.querySelectorAll('[data-keep]')].map(e => [e.dataset.keep, e.scrollTop]);
  root().innerHTML = view();
  scrolls.forEach(([k, y]) => { const e = document.querySelector(`[data-keep="${k}"]`); if (e) e.scrollTop = y; });
  if (key) {
    const n = document.querySelector(`[data-bind="${CSS.escape(key)}"]`) || document.getElementById(key);
    if (n) { n.focus({ preventScroll: true }); try { if (sel && n.setSelectionRange) n.setSelectionRange(sel[0], sel[1]); } catch (e) { /* number/date ไม่มี selection */ } }
  }
  tickClocks(); teaseStart();
  document.body.classList.toggle('lock', !!(UI.modal || UI.dialog || UI.kyc || SHELL_SCREENS.includes(UI.screen)));
  const h = document.querySelector('.modal h2, .shell h1, .shell .shell-t, h1'); let t = '';
  if (h) { const c = h.cloneNode(true); c.querySelectorAll('.sr').forEach(x => x.remove()); c.querySelectorAll('svg.starmark').forEach(x => x.replaceWith(' STAR ')); t = c.textContent.trim().replace(/\s+/g, ' '); }
  document.title = t && t !== 'Sale Here STAR' ? t + ' · Sale Here STAR' : 'Sale Here STAR';
  document.body.classList.toggle('dark', UI.insight && !UI.kyc);
}
// เปิด overlay ใหม่ = โฟกัสตัวแรกข้างใน (คีย์บอร์ดไม่หลุดไปอยู่หน้าข้างหลัง)
let lastFocus = null;
function focusOverlay() {
  requestAnimationFrame(() => {
    const box = document.querySelector('.modal, .shell, .wzcard, .drawer'); if (!box || box.contains(document.activeElement)) return;
    const el = box.querySelector('[autofocus], input:not([type=file]):not([type=checkbox]):not([type=radio]), textarea, select') || box.querySelector('button');
    if (el) el.focus({ preventScroll: true });
  });
}
function openOverlay(patch) { lastFocus = document.activeElement && (document.activeElement.dataset.act ? [document.activeElement.dataset.act, document.activeElement.dataset.arg] : null); Object.assign(UI, patch); render(); focusOverlay(); }
function closeOverlay(patch) {
  Object.assign(UI, patch); render();
  if (lastFocus) { const n = document.querySelector(`[data-act="${lastFocus[0]}"]${lastFocus[1] != null ? `[data-arg="${CSS.escape(lastFocus[1])}"]` : ''}`); if (n) n.focus({ preventScroll: true }); lastFocus = null; }
}

// ---------- นำทาง + ปุ่ม Back ของเบราว์เซอร์ ----------
const snap = () => JSON.parse(JSON.stringify({ tab: UI.tab, campaignId: UI.campaignId, screen: UI.screen, wiz: UI.wiz, insight: UI.insight, schedule: UI.schedule }));
function nav(patch, replace) {
  Object.assign(UI, patch, { dialog: null, modal: null });
  history[replace ? 'replaceState' : 'pushState'](snap(), '');
  render(); window.scrollTo(0, 0);
  const h = document.querySelector('.shell .shell-t, h1'); if (h) { h.setAttribute('tabindex', '-1'); h.focus({ preventScroll: true }); }
  const sb = document.querySelector('.shell-b'); if (sb) sb.scrollTop = 0;
}
window.addEventListener('popstate', e => { if (!e.state) return; Object.assign(UI, e.state, { dialog: null, modal: null, kyc: null, lab: false }); render(); window.scrollTo(0, 0); });

function toast(t) { UI.toast = t; const n = document.getElementById('toast'); if (n) { n.textContent = t; n.classList.add('on'); } clearTimeout(toast.t); toast.t = setTimeout(() => { UI.toast = null; const m = document.getElementById('toast'); if (m) m.classList.remove('on'); }, 2600); }

// ---------- จุด hook ของ flow (= tapMain / openStarCard / startWizard / finishWizard ... ของ SaleHereShell) ----------
// แก้ข้อเดียวจาก Star Profile = dialog บนจอใหญ่ · มือถือเปิดเต็มจอแบบ iOS (หน้า wizard ข้อเดียว ปุ่ม "บันทึก")
const wizAsModal = () => UI.screen === 'wizard' && UI.wiz && UI.wiz.kind === 'one' && UI.wiz.steps.length === 1 && !isMobile();

function startWizard(kind, steps, back) {
  if (!steps.length) return;
  const before = keptFields();
  // สภาพตอนเปิด wizard (= `initialSnapshot` ของ salehere-ios): เป็น STAR อยู่แล้วไหม · ข้อไหนใน 8 ข้อที่ขาดอยู่
  const startStar = F.isStar, startMissing = F.starMissing;
  F.autofill(steps.filter(s => s !== 'intro'));
  UI.wiz = { kind, asked: steps, steps: STEP.pages(steps), i: 0, back: back || null, err: null, from: UI.screen, before, startStar, startMissing };
  UI.cardAfter = null; UI.provinceQ = '';
  if (wizAsModal()) { openOverlay({ screen: 'wizard' }); history.pushState(snap(), ''); } else nav({ screen: 'wizard' });
}
function leaveWizard() { const w = UI.wiz; nav({ screen: w.kind === 'one' ? (w.back || 'star') : null }); }
function exitWizard() {
  const w = UI.wiz, real = w.steps.filter(s => s !== 'intro'), done = real.filter(stepDone).length;
  // ✕ หน้า intro = ออกเงียบ ๆ (ยังไม่ได้ทำอะไร ไม่ถาม "เก็บไว้ทำต่อไหม") · ครบทุกข้อแล้ว = ไม่มีอะไรค้าง — salehere-ios
  if (wizAsModal() || w.steps[w.i] === 'intro' || !real.length || done >= real.length) { leaveWizard(); return; }
  openOverlay({ dialog: { type: 'wizExit', done, total: real.length } });
}
function stepDone(s) { return s === 'kyc' ? F.isVerified : s === 'socials' ? F.has('socials') && F.has('rate') : F.has(s); }

// ช่องพิมพ์ที่ต้องกันไม่ให้ล้างทิ้งหลังเป็น STAR — ค่าตอนเปิด wizard (ก่อนกรอกตัวอย่าง) เทียบกับตอนกดบันทึก
// เฉพาะแนะนำตัว + ช่องทางติดต่อ (salehere-ios) — สัดส่วนไม่บังคับ ล้างได้ · ชื่อ "LINE ID " มีวรรคท้าย = "LINE ID ลบไม่ได้"
const KEPT = { media: [['about', 'แนะนำตัว']], contact: [['lineID', 'LINE ID '], ['phone', 'เบอร์โทร'], ['website', 'เว็บไซต์']] };
const keptVal = (o, path) => String(path.split('.').reduce((v, k) => v && v[k], o) || '').trim();
function keptFields() { return Object.fromEntries(Object.values(KEPT).flat().map(([k]) => [k, keptVal(F.s, k)])); }
const clearedField = (st, before) => F.keepsData && before ? (KEPT[st] || []).find(([k]) => before[k] && !keptVal(F.s, k)) : null;

// error อยู่ที่ช่องที่ขาด ไม่ใช่หัวหน้า (ผู้ใช้ 7 ต.ค. 2569) — `errs` = { คีย์ช่อง: ข้อความ } (คีย์ = data-bind ของช่อง หรือ 'media:works') · ข้อความว่าง = ขอบแดงอย่างเดียว
// `link` = ช่องที่ผิดด้วยกัน (LINE ID หรือเบอร์) พิมพ์ช่องไหนก็หายทั้งคู่ · error ระดับทั้งข้อ (เลือกอย่างน้อย 1 …) ยังอยู่เหนือตัวเลือกของข้อนั้น
function wizFail(msg, errs, link) {
  const w = UI.wiz; w.err = errs ? null : msg; w.errs = errs || null; w.errLink = link || null; w.shake = Date.now(); render();
  const first = errs && document.querySelector('.fld.bad input, .fld.bad textarea, .fld.bad select, .sec.bad');
  if (first) { first.scrollIntoView({ block: 'center', behavior: REDUCED ? 'auto' : 'smooth' }); if (first.focus) first.focus({ preventScroll: true }); return; }
  const e = document.getElementById('wz-err'); if (e) e.focus({ preventScroll: true });
}
const wizErr = key => UI.screen === 'wizard' && UI.wiz && UI.wiz.errs ? UI.wiz.errs[key] : undefined;
// ข้อความแดงล้วน ไม่มีไอคอน (= iOS `WzFieldError` / salehere-ios)
const ferr = msg => msg ? `<small class="ferr" role="alert">${esc(msg)}</small>` : '';
const EMPTY = 'ยังไม่ได้กรอก';
// ช่องที่ยังว่างของที่อยู่ / บัญชี → { data-bind: ข้อความ }
function emptyFields(paths) { return Object.fromEntries(paths.filter(p => !String(getPath(p) || '').trim()).map(p => [p, EMPTY])); }
function wizNext() {
  const w = UI.wiz, st = w.steps[w.i], s = F.s, wasStar = F.isStar, isLast = w.i === w.steps.length - 1;
  if (st === 'socials' && !s.connected.length) {
    // เป็น STAR แล้วเอาช่องทางออกได้หมด (ผู้ใช้ 7 ต.ค. 2569) — บันทึกได้เลย ลงทะเบียนงานถัดไปค่อยถามใหม่
    // เอาออกจนหมดได้เฉพาะตอนแก้ · เข้ามาเพราะข้อนี้ขาด (รวม STAR เก่าที่ถูกบังคับเติม) = ต้องเชื่อมก่อน (salehere-ios)
    if (!F.keepsData || (w.startMissing || []).includes('socials')) return wizFail('เชื่อมอย่างน้อย 1 ช่อง');
    ['socials', 'rate', 'insight'].forEach(k => F.remove(k)); F.save(); w.err = null; wizAdvance(); return;
  }
  const cleared = clearedField(st, w.before);
  if (cleared) return wizFail('', { ['s.' + cleared[0]]: `${cleared[1]}ลบไม่ได้ · แก้เป็นข้อมูลใหม่ได้` });
  // ด่านแข็ง (ผู้ใช้ 6 ต.ค. 2569): ต้อง "ผ่าน" ก่อนถึงไปฟอร์มได้ · รอตรวจ/ตีกลับ = ปุ่ม "ปิดไว้ก่อน" ปิดเงียบ ๆ (= iOS onExit(n, n))
  // ยังไม่เคยส่ง (เว็บ: ยืนยันในแอปเท่านั้น) = เป็นข้อสุดท้าย (ก่อนฟอร์มสมัคร) ปิดเก็บคำตอบไว้ · ยังมีข้อถัดไป = ข้ามไปทำข้ออื่นก่อน
  // ยังไม่เคยส่ง = ไปต่อไม่ได้ ต้องยืนยันตัวตนก่อน (= iOS / salehere-ios `STAR_WZ_ERR_KYC`)
  if (st === 'kyc' && !F.isVerified) {
    if (F.kycBlocked) { leaveWizard(); return; }
    return wizFail('ยืนยันตัวตนก่อน แล้วไปต่อได้เลย');
  }
  if (st === 'media' && F.mediaMissing()) return wizFail('', Object.fromEntries(Object.entries(F.mediaLack()).map(([k, t]) => ['media:' + k, 'ยังขาด ' + t])));
  // ขั้นต่ำ 3 = กติกา welcome step ของ salehere-ios
  if (st === 'categories' && s.categories.length < 3) return wizFail('เลือกอย่างน้อย 3 สาย');
  if (st === 'province' && !s.provinces.length) return wizFail('เลือกอย่างน้อย 1 จังหวัด');
  if (st === 'availability' && !F.availDays.length) return wizFail('เลือกช่วงที่ว่างอย่างน้อย 1 ช่อง');
  if (st === 'contact') {
    // ตรวจทั้ง 3 ช่องรอบเดียว error ขึ้นใต้ช่อง · ว่างทั้งคู่ = LINE ขอบแดง + ข้อความใต้ช่องเบอร์ · แก้ช่องไหนหายเฉพาะช่องนั้น (salehere-ios)
    const line = s.lineID.trim(), tel = s.phone.trim(), web = F.normalizedWebsite(s.website), bad = {};
    if (!line && !tel) return wizFail('', { 's.lineID': '', 's.phone': 'ใส่ LINE ID หรือเบอร์อย่างน้อย 1 ช่อง' });
    if (line && !F.validLine(line)) bad['s.lineID'] = 'LINE ID ไม่ถูกต้อง';
    if (tel && !F.validPhone(tel)) bad['s.phone'] = 'เบอร์โทรศัพท์ไม่ถูกต้อง';
    if (web && !F.validURL(web)) bad['s.website'] = 'เว็บไซต์ไม่ถูกต้อง';
    if (Object.keys(bad).length) return wizFail('', bad);
    s.website = web;
  }
  if (st === 'address') {
    // ครบ 7 ช่องแบบที่ `createUserAddress` บังคับ · รหัสไปรษณีย์ต้อง 5 หลัก (salehere-ios)
    const a = s.addressInfo, bad = emptyFields(['name', 'tel', 'address'].map(k => 's.addressInfo.' + k));
    if (a.zip.length !== 5) bad['s.addressInfo.zip'] = a.zip ? 'รหัสไปรษณีย์ต้องมี 5 หลัก' : EMPTY;
    Object.assign(bad, emptyFields(['sub', 'district', 'province'].map(k => 's.addressInfo.' + k)));
    if (Object.keys(bad).length) return wizFail('', bad);
  }
  if (st === 'bank' && !F.bankComplete()) return wizFail('', emptyFields([...(s.payKind === 'company' ? ['coName', 'taxID'] : []), 'bank', 'no', 'name'].map(k => 's.bankInfo.' + k)));
  w.err = null; w.errs = null;
  if (st === 'intro') { w.i++; history.replaceState(snap(), ''); render(); shellTop(); return; }
  // สัดส่วนไม่บังคับ: กรอกอย่างน้อย 1 ช่อง = มีแล้ว · ล้างหมดแล้วบันทึก = กลับเป็นยังไม่มี
  if (st === 'body') { if (F.bodyFilled()) F.add('body'); else F.remove('body'); F.save(); wizAdvance(); return; }
  if (st === 'media') { F.add('media'); if (s.about.trim()) F.add('about'); }
  else if (st === 'socials') { F.add('socials', 'rate'); if (s.insightSlots.length) F.add('insight'); }
  else if (KEY_LABEL[st]) F.add(st);
  F.save();
  // ข้อนี้ปิด 8 ข้อพอดี = เพิ่งเป็น STAR → motion ทับ wizard แล้วข้อถัดไปโผล่ใต้ motion (salehere-ios `celebrateIfJustBecameStar`)
  // ทางสมัครกิจกรรมได้หน้า "คุณเป็น STAR แล้ว" แทน · เป็นข้อสุดท้าย = หน้า Star Profile ฉลองตอนกลับไป
  if (!wasStar && F.isStar && w.kind !== 'apply' && !isLast) celebrateStar();
  wizAdvance();
}
function wizAdvance() {
  const w = UI.wiz;
  if (w.i < w.steps.length - 1) { w.i++; w.err = null; w.errs = null; history.replaceState(snap(), ''); render(); shellTop(); const h = document.querySelector('.wz-q h1'); if (h) { h.setAttribute('tabindex', '-1'); h.focus({ preventScroll: true }); } }
  else finishWizard();
}
function shellTop() { const sb = document.querySelector('.shell-b'); if (sb) sb.scrollTop = 0; }
function wizBack() { const w = UI.wiz; if (w.i > 0) { w.i--; w.err = null; w.errs = null; render(); } }
function finishWizard() {
  const w = UI.wiz, kind = w.kind;
  // หน้า "คุณเป็น STAR แล้ว" เฉพาะคนที่เพิ่งเป็น STAR ใน wizard รอบนี้ (ทางสมัครกิจกรรม) — STAR เก่าที่เติมครบไม่มีหน้านี้
  const madeCard = kind === 'apply' && !w.startStar && F.isStar;
  celebrateStar();
  // ตรวจซ้ำหลังจบ wizard: เพิ่งเป็น STAR = หน้า "คุณเป็น STAR แล้ว" · ครบ = ฟอร์มสมัคร · ยังไม่ครบ = หน้า Star Profile ให้เห็นว่าขาดอะไร
  if (kind === 'apply') nav({ screen: madeCard ? 'reveal' : !F.registerSteps.length ? 'register' : 'star' }, true);
  else if (kind === 'accept') { nav({ screen: 'accept' }, true); toast('ที่อยู่เติมให้แล้ว · ต่อที่หน้าตอบรับ'); }
  else {
    if (UI.cardAfter) { UI.cardAfter = null; nav({ screen: 'star' }, true); if (F.isStar) openStarCard(); return; }
    // ไม่มี toast ตอนจบ (salehere-ios) — หน้า Star Profile อัปเดตแถวให้เห็นเอง
    nav({ screen: w.back || 'star' }, true);
  }
}
// ได้เป็น STAR = ฉลองครั้งเดียว ตอนกรอกเสร็จเท่านั้น (จบ wizard / จบยืนยันตัวตน)
// ดูที่ "ครบ 8 ข้อจริง" ไม่ใช่แค่มียศ — STAR เก่าที่ยังไม่ครบไม่เล่น ได้เล่นตอนกรอกครบ (salehere-ios)
function celebrateStar() {
  if (!F.starComplete) { F.s.starLevelSeen = false; F.save(); return; }
  if (F.s.starLevelSeen) return;
  F.s.starLevelSeen = true; F.save();
  UI.levelUp = 'star'; setTimeout(() => { UI.levelUp = null; render(); }, REDUCED ? 1400 : 2700);
}
function tapMain() {
  const s = F.s;
  if (s.phase === 'register') {
    // จำงานที่กำลังสมัครไว้ — ติดด่านยืนยันตัวตนแล้วผ่านทีหลัง แจ้งเตือนจะพากลับมาฟอร์มใบนี้
    s.pendingCampaign = campaign().id; F.save();
    // รอตรวจ/ตีกลับ = ไปหน้าสถานะ ไม่พาเข้า wizard ให้ไปตันทีหลัง (ผู้ใช้ 6 ต.ค. 2569) — หน้ากิจกรรมเองไม่เปลี่ยน
    // ด่าน (salehere-ios ข้อ 5): ครบ 8 ข้อ → ฟอร์มเดิม · เหลือแค่ยืนยันตัวตน + รอตรวจ/ไม่ผ่าน → หน้าสถานะ ·
    // ยังขาดข้ออื่น (ทั้งยังไม่เป็น STAR และ STAR เก่าที่ยังไม่ครบ — บังคับเหมือนกัน) → intro + wizard
    const st = F.registerSteps;
    if (!st.length) nav({ screen: 'register' });
    else if (kycOnlyBlocked()) { UI.cancelAsk = false; nav({ screen: 'kycStatus' }); }
    else startWizard('apply', ['intro', ...st]);
  }
  else if (s.phase === 'waitingAcceptQuota') { const st = F.acceptSteps; st.length ? startWizard('accept', st) : nav({ screen: 'accept' }); }
  else if (s.phase === 'acceptedQuota') { if (s.draftApproved && !s.reviewed) nav({ screen: 'link' }); else toast('หน้ารายละเอียดการรีวิว = หน้าเดิมของแอปหลัก (ไม่ได้จำลอง)'); }
}
// เหลือแค่ยืนยันตัวตน และรอตรวจ/ไม่ผ่าน — ไปหน้าสถานะได้ (ยังขาดข้ออื่น = ห้ามพาไปหน้าสถานะ) = iOS `kycOnlyBlocked`
const kycOnlyBlocked = () => F.starMissing.join() === 'kyc' && F.kycBlocked;
// เข้า Star Card — ยังไม่เป็น STAR = บังคับกรอก 8 ข้อที่แบรนด์ใช้คัดเลือกก่อนเสมอ (ผู้ใช้ 6 ต.ค. 2569) แล้วค่อยเปิด
function openStarCard() {
  if (F.isStar) { nav({ screen: 'card' }); return; }
  startWizard('one', F.starMissing, 'star'); UI.cardAfter = true;
}
// ตีกลับแล้วเข้ามาใหม่ = เปิดฟอร์มที่กรอกไว้ให้เลย พร้อมการ์ดสถานะแดง + เหตุผล (= CheckTypeUser → VerifyUserStatusForm สถานะ reject)
// เว็บไม่ทำยืนยันตัวตนเอง — พาไปโหลด/เปิดแอป Sale Here (ผู้ใช้ 6 ต.ค. 2569: "ถึงขั้นตอนยืนยันตัวตนให้ user ไปโหลดแอปเลย")
// = DownloadAppModal ของ salehere-web (QR + ปุ่มดาวน์โหลด/เปิดแอปพลิเคชั่น) · หน้ากล้องจำลองเดิม (`kycView`) ไม่มีทางเข้าแล้ว
// มือถือ (ผู้ใช้ 7 ต.ค. 2569: "Web Mobile ให้ยืนยันตัวตนได้หน่อย จะได้ลองเล่นแบบจบ flow") = เปิดหน้ากล้องจำลองเดิม (`kycView`) ทำจบในเว็บ
//   ตีกลับ = เปิดฟอร์มที่กรอกไว้พร้อมเหตุผล · จอกว้างยังพาไปแอปเหมือนเดิม
// Lab ผลยืนยันตัวตน (= `StarKycLab.ask` ของ salehere-ios · iOS `kycAsk`): กดเริ่ม/ส่งใหม่ → ถามก่อนว่าจะจำลองผลไหน · `?lab=0` = ไปทางจริงเลย
function openKyc(done) {
  if (HIDE_LAB) { realKyc(done); return; }
  openOverlay({ dialog: { type: 'kycLab', done: done || null } });
}
// ผลจาก Lab — ทับสถานะในเครื่อง แล้วทำต่อเหมือนกลับจากหน้ายืนยันตัวตน · ไม่เด้งแจ้งเตือนจำลอง (ไม่ใช่ผลจาก staff)
function labKyc(v, done) {
  const s = F.s; UI.dialog = null;
  s.verify = v; if (v === 'waiting') s.kycSentAt = Date.now(); if (v === 'rejected' && !s.verifyReason) s.verifyReason = REJECT_REASONS[0];
  F.save();
  if (done) done(); else { celebrateStar(); if (F.isVerified) toast('ป้าย Verified ขึ้นการ์ดแล้ว'); render(); }
}
// ทางจริง ("ถ่ายบัตรจริง (flow เดิม)"): มือถือ = หน้ากล้องจำลอง · จอกว้าง = พาไปแอป (QR)
function realKyc(done) {
  if (isMobile()) { const rej = F.s.verify === 'rejected'; openOverlay({ dialog: null, kyc: { step: rej ? 'form' : 'type', doc: 'บัตรประชาชน', manual: rej, done: done || null } }); return; }
  openOverlay({ dialog: { type: 'getApp', done: done || null } });
}
const KYC_LAB = [['none', 'ยังไม่เคยส่งยืนยันตัวตน'], ['waiting', 'รอตรวจ (Waiting)'], ['rejected', 'ไม่ผ่าน (Reject)'], ['approved', 'ผ่าน (Approve)']];
const APP_URL = 'https://salehere.co.th/download';
// inline = อยู่ในขั้น KYC ของ wizard (มีลิงก์ Lab แทนปุ่ม "เริ่มยืนยันตัวตน" ของ iOS) · ใน dialog "ถ่ายบัตรจริง" = QR อย่างเดียว
function getAppBox(inline) {
  // มือถือ: ยืนยันในเว็บได้เลย (ถ่ายบัตร + ใบหน้า) แทนการพาไปโหลดแอป — ปุ่ม = iOS "เริ่มยืนยันตัวตน" (ถาม Lab ก่อน)
  if (isMobile()) return `<div class="getapp mob-kyc"><div class="ga-tx"><b>ยืนยันตัวตน</b><p>ถ่ายบัตรประชาชนและใบหน้า ใช้เวลาไม่ถึง 2 นาที</p>
      <button class="btn dark wide" data-act="startKyc">${ic('identificationCard', 18, 'b')}เริ่มยืนยันตัวตน</button><small>คำตอบที่กรอกไว้ยังอยู่ครบ · ผ่านแล้วไปต่อได้เลย</small></div></div>`;
  return `<div class="getapp"><span class="ga-qr"><img src="assets/qrcode-download-app.png" width="148" height="148" alt="QR ดาวน์โหลดแอป Sale Here"></span>
    <div class="ga-tx"><b>ยืนยันตัวตนในแอป Sale Here</b><p class="ga-desk">สแกน QR ด้วยกล้องมือถือ เพื่อดาวน์โหลดหรือเปิดแอป</p><p class="ga-mob">ถ่ายบัตรและใบหน้าในแอป ใช้เวลาไม่ถึง 2 นาที</p>
      <a class="ga-btn" href="${APP_URL}" target="_blank" rel="noopener noreferrer"><img src="assets/ico-logo-app-btn.png" width="32" height="32" alt=""><span>ดาวน์โหลด/เปิดแอปพลิเคชั่น</span>${ic('caretRight', 14, 'b')}</a>
      <small>คำตอบที่กรอกไว้ยังอยู่ครบ · ผ่านแล้วกลับมาสมัครต่อได้เลย</small>
      ${HIDE_LAB || !inline ? '' : `<button class="link" data-act="kycLabAsk">Lab · เลือกผลยืนยันตัวตน</button>`}</div></div>`;
}
// จบยืนยันตัวตน: approved = OCR ผ่าน อนุมัติทันที · waiting = กรอกมือ ส่งทีมงานตรวจ
function kycFinish() {
  const k = UI.kyc, cb = k.done, s = F.s;
  if (k.manual) { s.verify = 'waiting'; s.kycSentAt = Date.now(); } else s.verify = 'approved';
  s.verifyReason = ''; F.save(); UI.kyc = null;
  if (cb) cb(); else { celebrateStar(); if (F.isVerified) toast('ป้าย Verified ขึ้นการ์ดแล้ว'); render(); }
}
// ผลจาก staff มาถึง (= push userVerifyApprove / userVerifyReject) — lab สลับสถานะ = ผลมาถึง
function verifyChanged(old, cur) {
  if (!(old === 'waiting' || cur === 'rejected')) return;
  if (cur === 'approved') {
    const c = CAMPAIGNS.find(x => x.id === F.s.pendingCampaign);
    pushNote('ยืนยันตัวตนผ่านแล้ว ✓', c ? `กลับมาสมัคร ${c.episode} ต่อได้เลย${c.deadline ? ' · ปิดรับ ' + SD.short(SD.iso(new Date(c.deadline))) : ''}` : 'ป้าย Verified ขึ้นการ์ดของคุณแล้ว', false, () => {
      UI.dialog = null;
      if (!c || !c.isOpen) { nav({ screen: 'star', campaignId: null }); return; }
      // KYC เป็นด่านสุดท้ายก่อนฟอร์ม — ขั้นที่ขาดกรอกครบแล้ว = เปิดฟอร์มสมัครให้เลย
      Object.assign(UI, { tab: 'home', campaignId: c.id, insight: false, schedule: false });
      const st = F.registerSteps; st.length ? startWizard('apply', ['intro', ...st]) : (UI.reg = null, nav({ screen: 'register' }));
    });
  } else if (cur === 'rejected') pushNote('ยืนยันตัวตนไม่ผ่าน', F.s.verifyReason || 'กรุณาทำรายการใหม่อีกครั้ง', true, () => { UI.cancelAsk = false; nav({ screen: 'kycStatus' }); });
}
// แจ้งเตือนจำลอง — แถบมุมขวาบน หายเองใน 6 วิ คลิกแล้วพาไปต่อ
function pushNote(title, body, warn, act) {
  UI.push = { title, body, warn, act, id: Date.now() }; render();
  const id = UI.push.id; setTimeout(() => { if (UI.push && UI.push.id === id) { UI.push = null; render(); } }, 6000);
}
function submitRegister() {
  // ที่อยู่กรอกในฟอร์มสมัครเดิมแล้ว — นับเป็นข้อที่มีใน Star Profile ทันที ตอบรับไม่ถามซ้ำ
  if (F.addressFull()) F.add('address');
  F.s.pendingCampaign = null; F.s.phase = 'registered'; F.save(); nav({ screen: null }, true); setTimeout(() => openOverlay({ dialog: { type: 'registerSuccess' } }), 350); }
function submitLinks() { F.s.reviewed = true; F.save(); UI.linkDraft = {}; UI.linkTouched = {}; nav({ screen: null }, true); toast('ส่งรีวิวสำเร็จ'); }
// แถวของหน้า: Star Profile = ข้อมูลทุกข้อ + ยืนยันตัวตนท้ายสุด · หน้าการ์ดเกิด = ไม่มีแถวยืนยันตัวตน และไม่ชวนเติมข้อที่ถามแค่ใน Star Profile (สัดส่วน)
function starRows(mode) { const data = ROWS.filter(r => r.key && (mode === 'profile' || r.key !== 'body')); return mode === 'profile' ? [...data, KYC_ROW] : data; }
// 8 ข้อที่แบรนด์ใช้คัดเลือก (= หน้าของ `starMissing` ไม่นับข้อไม่บังคับ) + ยืนยันตัวตน — ด่านเดียวก่อนเป็น STAR (= `StarPage.starRows`)
const GATE_KEYS = ['kind', 'socials', 'categories', 'media', 'province', 'availability', 'contact'].flatMap(s => STEP.keys(s)).filter(k => !['insight', 'about', 'body'].includes(k));
function gateRows(mode) { return starRows(mode).filter(r => !r.key || GATE_KEYS.includes(r.key)); }
// ข้อที่ไม่ใช่ด่าน (แนะนำตัว · ข้อมูลผู้ติดตาม · บัญชี · ที่อยู่ · สัดส่วน) — แถวบอกเองว่าใช้ตอนไหน (= `StarPage.extraRows`)
function extraRows(mode) { return starRows(mode).filter(r => r.key && !GATE_KEYS.includes(r.key)); }

// ---------- ชิ้นส่วนร่วม ----------
function clock(deadline) { return `<span class="clock" data-deadline="${deadline}" role="timer" aria-live="off"></span>`; }
function tickClocks() {
  document.querySelectorAll('[data-deadline]').forEach(n => {
    const sec = Math.max(0, Math.floor((Number(n.dataset.deadline) - Date.now()) / 1000)), d = Math.floor(sec / 86400), p = v => String(v).padStart(2, '0');
    const parts = [...(d ? [String(d)] : []), p(Math.floor(sec % 86400 / 3600)), p(Math.floor(sec % 3600 / 60)), p(sec % 60)];
    const html = parts.map(x => `<b>${x}</b>`).join('<i>:</i>'); if (n.innerHTML !== html) n.innerHTML = html;
    n.setAttribute('aria-label', `${d ? d + ' วัน ' : ''}${parts.slice(-3).join(':')}`);
  });
}
setInterval(tickClocks, 1000);

function verifyChip(clickable) {
  const v = F.s.verify;
  if (v === 'approved') return `<span class="seal on" title="ยืนยันตัวตนแล้ว">${ic('sealCheck', 22, 'f')}<span class="sr">ยืนยันตัวตนแล้ว</span></span>`;
  const inner = v === 'waiting' ? `${ic('clock', 16, 'b')}รอตรวจ` : v === 'rejected' ? `${ic('warning', 16, 'b')}ยืนยันตัวตนไม่ผ่าน` : `${ic('sealCheck', 16, 'b')}ยังไม่ได้ยืนยันตัวตน`;
  // สีตามสถานะ (ผู้ใช้ 6 ต.ค. 2569): รอตรวจ = เหลือง · ไม่ผ่าน = แดง · ยังไม่ทำ = เทาเส้นประเหมือนเดิม
  const cls = `seal off ${v === 'waiting' ? 'wait' : v === 'rejected' ? 'rej' : ''}`;
  return clickable ? `<button class="${cls}" data-act="kyc">${inner}</button>` : `<span class="${cls}">${inner}</span>`;
}
// การ์ดกระจกสรุปตัวตน (= StarGlassCard) — ghosts = ช่องประของข้อที่ยังว่าง (หน้าต่าง wizard)
// ช่องประ 1 ช่องต่อ 1 ข้อที่ยังขาด — จำนวนตรงกับ "สมัครเป็น STAR · N ข้อ" · ชื่อช่อง = ชื่อข้อ = ชื่อแถวในหน้า Star Profile (= salehere-ios)
// แถวใต้ชื่อ = สาย · พื้นที่ · วันว่าง (โชว์แม้มีสายแล้ว) · แถวล่าง = ที่เหลือตามลำดับ wizard (ยืนยันตัวตนท้ายสุด)
const NAME_GHOSTS = ['categories', 'province', 'availability'];
function glassCard(o = {}) {
  const s = F.s, ghosts = o.ghosts || [], text = st => ghosts.includes(st) && F.needs(st) ? STEP.rowName(st) : null;
  const slot = t => `<span class="ghost">${esc(t)}</span>`;
  const nameGhosts = NAME_GHOSTS.map(text).filter(Boolean), cardGhosts = ghosts.filter(st => !NAME_GHOSTS.includes(st)).map(text).filter(Boolean);
  const cats = F.facts({ key: 'categories' }).join(' · ');
  let sub = '';
  if (F.has('categories')) sub = `<p class="gc-sub">${esc(cats)}</p>`;
  else if (!ghosts.length) sub = `<p class="gc-sub blank">สายที่ใช่จะขึ้นตรงนี้</p>`;
  if (nameGhosts.length) sub += `<div class="ghosts">${nameGhosts.map(slot).join('')}</div>`;
  const star = F.isStar;
  const av = `<span class="gc-av ${star ? 'star' : ''}">${avatar(o.hero ? 96 : 64)}${star ? `<i class="badge">${ic('star', 13, 'f')}</i>` : ''}${o.onAvatar ? `<i class="camb">${ic('camera', 12, 'f')}</i>` : ''}</span>`;
  let h = `<div class="glass-card ${star ? 'is-star' : ''} ${o.hero ? 'hero-card' : ''}">${star || ghosts.length ? `<span class="star-pill ${star ? '' : 'wait'}">${starMark(10)}</span>` : ''}
    <div class="gc-id">${o.onAvatar ? `<button class="plain" data-act="fillOne" data-arg="media" aria-label="เปลี่ยนรูปและผลงาน">${av}</button>` : av}
      <div class="gc-name"><div class="gc-nrow"><strong>${esc(userName())}</strong>${o.verify === false ? (F.isVerified ? verifyChip(false) : '') : verifyChip(o.verify === 'tap')}</div>${sub}</div></div>`;
  if (cardGhosts.length) h += `<div class="ghosts">${cardGhosts.map(slot).join('')}</div>`;
// หมวด "ช่องทาง" · บรรทัดแนะนำตัว · @ชื่อผู้ใช้ เอาออกจากการ์ดนี้ทั้ง iOS และเว็บ (ผู้ใช้ 5 ต.ค. 2569) — ยังอยู่ในรายการข้อมูลและบน Star Card
  if (!o.compact && s.reviewed) h += `<div class="gc-works"><img src="assets/ph01.jpg" alt="ผลงานรีวิว"><img src="assets/ph04.jpg" alt="ผลงานรีวิว"></div>`;
  if (o.card) h += starCardSection();
  if (o.data) h += dataCard(o.data);
  return h + `</div>`;
}
// หมวด "ST★R Card" ท้ายการ์ดข้อมูล: รูปย่อ + ดูการ์ด + แชร์ + ยอดวิว (หน้า Star Card เองอยู่นอกขอบเขต desktop รอบนี้)
function starCardSection() {
  const isDefault = F.s.cards === 0, published = F.hasCard;
  const badge = isDefault ? `<i class="live wait"><u></u>รอคุณเปิด</i>` : published ? `<i class="live"><u></u>กำลังแสดงอยู่</i>` : '';
  // ยังไม่เคยเปิดการ์ด = แถบตัวอย่างเทมเพลต เลื่อนเอง แตะใบไหนก็เริ่มจากใบนั้น (feedback 5 ต.ค. 2569 · เหมือน `TemplateTease` ของ iOS) — เคยเปิดแล้ว = แถวเดิม
  // ยังไม่เปิดใช้งาน = การ์ดลอย หน้าการ์ดละลายเปลี่ยนแบบ + แสงกวาด + ปุ่ม "เปิดใช้งาน" (= `ActivateTease` ของ iOS) — งานของก้อนนี้คือทำให้อยากกดเปิด
  // ยังไม่เปิดใช้งาน = พัด 3 ใบ โชว์ทีละชุด (แนวตั้ง ↔ แนวนอน) จางสลับช้า ๆ ทั้งพัด · ปุ่ม "เปิดใช้งาน" ขาว นิ่ง (= `ActivateTease` ของ iOS)
  if (isDefault) { const fan = land => { const list = TEMPLATES.filter(t => !!t[1] === land), k = (land ? UI.teaseW : UI.teaseT) % list.length;
      return `<span class="fan3 ${land ? 'land' : 'tall'} ${UI.teaseWide === land ? 'on' : ''}" data-fan="${land ? 'W' : 'T'}">${[2, 1, 0].map(d => `<img class="f${d}" src="assets/tpl/${list[(k + d) % list.length][0]}.png" alt="">`).join('')}<i class="sh"></i></span>`; };
    return `<div class="gc-sec sc"><div class="sc-head"><span class="sc-title">${starMark(13)}<em>Card</em></span><span class="sc-note">รอคุณเปิดใช้งาน</span></div>
    <button class="fans" data-act="openCard" data-tease aria-label="Star Card ยังไม่ได้เปิดใช้งาน ตัวอย่างแบบการ์ดแนวตั้งและแนวนอน"><span>${fan(false)}${fan(true)}</span></button>
    <button class="pill act-plain" data-act="openCard">${ic('sparkle', 15, 'b')}เปิดใช้งาน</button></div>`; }
  return `<div class="gc-sec sc"><div class="sc-head"><span class="sc-title">${starMark(13)}<em>Card</em></span>${isDefault ? `<span class="sc-note">${F.isStar ? 'ของคุณพร้อมแล้ว · เปิดดูได้เลย' : 'ของคุณพร้อมแล้ว · สมัครเป็น STAR แล้วเปิดดูได้เลย'}</span>` : ''}</div>
    <div class="sc-row"><button class="sc-thumb" data-act="openCard" aria-label="เปิด Star Card">${cardThumb()}${badge}</button>
      <div class="sc-acts"><div class="sc-line"><button class="pill ${isDefault ? 'dark' : ''}" data-act="openCard">${ic(isDefault ? 'sparkle' : 'eye', 15, 'b')}${isDefault ? 'เปิดการ์ดของฉัน' : 'ดูการ์ด'}</button>
        ${!isDefault && published ? `<button class="round" data-act="shareCard" aria-label="แชร์การ์ด" title="แชร์การ์ด">${ic('shareNetwork', 16, 'b')}</button>` : ''}</div>
        ${!isDefault && published ? `<button class="pill ghost" data-act="openInsight">${ic('chartLineUp', 15, 'b')}${INSIGHT.neverSeen ? 'ยอดวิว' : INSIGHT.get('week').views.toLocaleString('en-US') + ' วิว'}${ic('caretRight', 11, 'b')}</button>` : ''}</div></div></div>`;
}
const cardThumb = () => `<span class="mini-card"><img src="${F.s.media.photos[0] || 'assets/ph01.jpg'}" alt=""><b>${esc(userName())}</b><small>${starMark(6)}</small></span>`;

// ค่าของแถว = ข้อความบรรทัดเดียวคั่นด้วย · ไม่ใช่กล่อง chip (ผู้ใช้ 6 ต.ค. 2569: chips ทำให้รายการ "ยั่วเยี้ย scan อ่านยาก")
// แถว "เติมเมื่อถึงเวลา" ที่มีแล้ว = ชิปเทาเล็ก ไม่เกิน 3 + "+N" (= iOS `PKFactStrip`)
function chipStrip(list) { const l = list.filter(Boolean), shown = l.slice(0, 3); return `<small class="fchips">${shown.map(f => `<span>${esc(f)}</span>`).join('')}${l.length > 3 ? `<em>+${l.length - 3}</em>` : ''}</small>`; }
function factStrip(list) { const l = list.filter(Boolean); return `<small class="facts">${l.map((f, i) => `<span>${esc(f)}${i < l.length - 1 ? '<i aria-hidden="true">·</i>' : ''}</span>`).join(' ')}</small>`; }
// วงแหวนเล็กสีขาวในปุ่มดำ "เติมข้อมูลต่อ NN%" (= iOS `GlassPrimaryButton(progress:)`)
function miniRing(pct) {
  const c = 2 * Math.PI * 9.5;
  return `<span class="mring" aria-hidden="true"><svg viewBox="0 0 22 22" width="20" height="20"><circle cx="11" cy="11" r="9.5" class="t"/><circle cx="11" cy="11" r="9.5" class="v" stroke-dasharray="${c}" stroke-dashoffset="${c * (1 - pct)}" transform="rotate(-90 11 11)"/></svg></span>`;
}
function ring(pct, full) {
  const c = 2 * Math.PI * 19;
  return `<span class="ring ${full ? 'full' : ''}" role="img" aria-label="ข้อมูลครบ ${Math.round(pct * 100)}%"><svg viewBox="0 0 44 44" width="52" height="52"><circle cx="22" cy="22" r="19" class="t"/><circle cx="22" cy="22" r="19" class="v" stroke-dasharray="${c}" stroke-dashoffset="${c * (1 - pct)}" transform="rotate(-90 22 22)"/></svg><b>${full ? ic('check', 20, 'b') : Math.round(pct * 100) + '%'}</b></span>`;
}
// บรรทัดรองของแถว "ใช้ให้แบรนด์คัดเลือก" = ใช้ตอนไหน (= iOS `StarPage.whenNeeded`)
const WHEN = { bank: 'ใช้ตอนได้ค่าตัว', address: 'ใช้ตอนลงทะเบียนกิจกรรม', body: 'ใช้ตอนรับงานสายแฟชั่น', about: 'ขึ้นใต้ชื่อบนการ์ด · ไม่บังคับ', insight: 'แบรนด์ดูกลุ่มคนดู · ไม่บังคับ' };
function kycNote() {
  const s = F.s;
  if (s.verify === 'waiting') return 'ทีมงานกำลังตรวจ · แจ้งผลภายใน 3 วันทำการ' + (s.kycSentAt ? ' · ส่งเมื่อ ' + SD.short(SD.iso(new Date(s.kycSentAt))) : '');
  if (s.verify === 'rejected') return `ไม่ผ่าน: ${s.verifyReason || 'กรุณาทำรายการใหม่'} · แตะเพื่อส่งใหม่`;
  return '';
}
// การ์ดภาพสถานะ (= KycHeroCard) — ใช้ทั้งหน้าสถานะและขั้น KYC ใน wizard · รอ: ส้มอ่อน + นาฬิกา · ตีกลับ: แดงอ่อน + เตือน + เหตุผลจาก staff
function kycHero() {
  const waiting = F.s.verify === 'waiting', card = `<span class="idc"><i class="ph">${ic('user', 18, 'f')}</i><span><u></u><u></u><u></u><u></u></span><b></b></span>`;
  return `<div class="kyc-hero ${waiting ? 'wait' : 'rej'}"><span class="idc-art">${card.replace('idc', 'idc back')}${card}<i class="idc-badge">${ic(waiting ? 'clock' : 'warning', 18, 'f')}</i></span>
    <p>${esc(waiting ? 'ระหว่างนี้ไม่ต้องทำอะไรเพิ่ม · มีผลเมื่อไหร่เราจะแจ้งเตือน' : F.rejectReason)}</p></div>`;
}
// ช่องที่อยู่ 7 ช่อง (= ฟอร์มสมัครเดิม UnboxRegister / myAddress) — รหัสไปรษณีย์ → ตำบล (เลือก) → อำเภอ/จังหวัดเติมให้
function addressFields() {
  const a = F.s.addressInfo, subs = zipSubs(a.zip);
  return `<div class="grid2">${field('ชื่อ - นามสกุล', 's.addressInfo.name', { req: 1, ph: 'กรอกชื่อ - นามสกุล', auto: 'name' })}${field('เบอร์โทรศัพท์', 's.addressInfo.tel', { req: 1, ph: 'กรอกเบอร์โทรศัพท์', mode: 'tel', auto: 'tel', digits: 1, max: 10, live: 1 })}
    <label class="fld span2 ${wizErr('s.addressInfo.address') != null ? 'bad' : ''}"><span>รายละเอียดที่อยู่ <em>*</em></span><textarea rows="2" data-bind="s.addressInfo.address" data-live="1" placeholder="บ้านเลขที่, ชื่อหมู่บ้าน, ห้อง, ชั้น, ถนน, ซอย" autocomplete="street-address">${esc(a.address)}</textarea>${ferr(wizErr('s.addressInfo.address'))}</label>
    ${field('รหัสไปรษณีย์', 's.addressInfo.zip', { req: 1, ph: 'ระบุรหัสไปรษณีย์', mode: 'numeric', max: 5, digits: 1, auto: 'postal-code', live: 1 })}
    ${subs.length ? `<label class="fld ${wizErr('s.addressInfo.sub') != null && !a.sub ? 'bad' : ''}"><span>ตำบล/แขวง <em>*</em></span><span class="in"><select data-bind="s.addressInfo.sub" data-live="1"><option value="">ตำบล/แขวง</option>${subs.map(x => `<option ${a.sub === x ? 'selected' : ''}>${esc(x)}</option>`).join('')}</select></span>${a.sub ? '' : ferr(wizErr('s.addressInfo.sub'))}</label>`
      : field('ตำบล/แขวง', 's.addressInfo.sub', { req: 1, ph: a.zip.length === 5 ? 'ตำบล/แขวง' : 'ใส่รหัสไปรษณีย์ก่อน', live: 1 })}
    ${field('อำเภอ/เขต', 's.addressInfo.district', { req: 1, ph: 'อำเภอ/เขต', live: 1 })}${field('จังหวัด', 's.addressInfo.province', { req: 1, ph: 'จังหวัด', live: 1 })}</div>`;
}
function modal(title, body, o = {}) {
  return `<div class="scrim" data-act="${o.close || 'closeModal'}" data-self="1"><div class="modal ${o.cls || ''}" role="dialog" aria-modal="true" aria-labelledby="m-title">
    <header><h2 id="m-title">${title}</h2><button class="x" data-act="${o.close || 'closeModal'}" aria-label="ปิด">${ic('x', 18, 'b')}</button></header>
    <div class="m-body" data-keep="modal">${body}</div>${o.foot ? `<footer>${o.foot}</footer>` : ''}</div></div>`;
}
// ปุ่ม = [ข้อความ, action, primary, arg] · detail ว่าง = หัวอย่างเดียว (= confirmationDialog ของ iOS)
function confirmBox(title, detail, buttons) {
  return `<div class="scrim"><div class="modal small" role="alertdialog" aria-modal="true" aria-labelledby="m-title" ${detail ? 'aria-describedby="m-desc"' : ''}><div class="m-body center"><h2 id="m-title">${title}</h2>${detail ? `<p id="m-desc">${detail}</p>` : ''}</div>
    <footer class="stack">${buttons.map(([t, act, primary, arg]) => `<button class="btn ${primary ? 'dark' : 'quiet'}" data-act="${act}" ${arg != null ? `data-arg="${esc(arg)}"` : ''}>${t}</button>`).join('')}</footer></div></div>`;
}
// ส่งต่อไปทำบนมือถือ — ของของครีเอเตอร์ (บัตร รูปแคป Insight รูป/คลิป) อยู่ในมือถือ ไม่ได้อยู่ในคอม
function qrBox(what, act) {
  const cells = Array.from({ length: 121 }, (_, i) => ((i * 7 + (i % 11) * 3 + Math.floor(i / 11) * 5) % 3 === 0 || [0, 1, 2, 11, 22, 8, 9, 10, 21, 32, 88, 99, 110, 111, 112].includes(i)) ? '<i></i>' : '<u></u>').join('');
  return `<div class="qr-box"><span class="qr" role="img" aria-label="QR สำหรับเปิดบนมือถือ">${cells}</span><div><b>${ic('deviceMobile', 16, 'b')}ทำต่อบนมือถือ</b><p>สแกนด้วยกล้องมือถือ ${what} หน้านี้จะอัปเดตเอง</p>
    ${act ? `<button class="link" data-act="${act[0]}" data-arg="${act[1] || ''}">จำลอง: ส่งจากมือถือแล้ว</button>` : ''}</div></div>`;
}
const field = (label, bind, o = {}) => { const er = wizErr(bind); return `<label class="fld ${o.cls || ''} ${er != null ? 'bad' : ''}"><span>${label}${o.req ? ' <em>*</em>' : ''}</span><span class="in ${o.unit ? 'has-unit' : ''}">
  <input type="${o.type || 'text'}" data-bind="${bind}" value="${esc(getPath(bind))}" placeholder="${esc(o.ph || '')}" ${o.max ? `maxlength="${o.max}"` : ''} ${o.mode ? `inputmode="${o.mode}"` : ''} ${o.auto ? `autocomplete="${o.auto}"` : ''} ${o.live ? 'data-live="1"' : ''} ${o.digits ? 'data-digits="1"' : ''} ${er != null ? 'aria-invalid="true"' : ''}>${o.unit ? `<i>${o.unit}</i>` : ''}</span>${ferr(er)}</label>`; };
const selectField = (label, bind, options, ph) => { const er = wizErr(bind); return `<label class="fld ${er != null ? 'bad' : ''}"><span>${label}</span><span class="in"><select data-bind="${bind}" data-live="1" ${er != null ? 'aria-invalid="true"' : ''}><option value="">${ph || 'เลือก'}</option>${options.map(x => `<option ${getPath(bind) === x ? 'selected' : ''}>${esc(x)}</option>`).join('')}</select></span>${ferr(er)}</label>`; };
function getPath(p) { return p.split('.').reduce((o, k) => (o == null ? o : o[k]), { s: F.s, ui: UI }) ?? ''; }
function setPath(p, v) { const ks = p.split('.'), last = ks.pop(); const o = ks.reduce((x, k) => x[k], { s: F.s, ui: UI }); o[last] = v; }
// ย่อรูปที่อัปโหลดให้เก็บลง localStorage ได้ (ของจริง = อัปขึ้น S3 ผ่าน presign)
function readImage(file, max = 420) {
  return new Promise(res => { const img = new Image(), url = URL.createObjectURL(file);
    img.onload = () => { const k = Math.min(1, max / Math.max(img.width, img.height)), c = document.createElement('canvas'); c.width = img.width * k; c.height = img.height * k;
      c.getContext('2d').drawImage(img, 0, 0, c.width, c.height); URL.revokeObjectURL(url); res(c.toDataURL('image/jpeg', 0.72)); };
    img.onerror = () => { URL.revokeObjectURL(url); res(null); }; img.src = url; });
}
function readVideo(file) {
  return new Promise(res => { const v = document.createElement('video'), url = URL.createObjectURL(file); v.muted = true; v.preload = 'metadata';
    const fail = () => { URL.revokeObjectURL(url); res(null); };
    v.onloadeddata = () => { v.currentTime = Math.min(0.5, v.duration / 2 || 0); };
    v.onseeked = () => { const k = Math.min(1, 420 / Math.max(v.videoWidth, v.videoHeight)), c = document.createElement('canvas'); c.width = v.videoWidth * k; c.height = v.videoHeight * k;
      c.getContext('2d').drawImage(v, 0, 0, c.width, c.height); const d = Math.round(v.duration || 0); URL.revokeObjectURL(url);
      res({ src: c.toDataURL('image/jpeg', 0.7), dur: `${Math.floor(d / 60)}:${String(d % 60).padStart(2, '0')}` }); };
    v.onerror = fail; setTimeout(fail, 6000); v.src = url; });
}

// พัดสองชุดจางสลับกันทุก 3.6 วิ (CSS จาง 1.8 วิ) — ชุดที่ซ่อนอยู่เลื่อนแบบของตัวเองหนึ่งใบตอนมองไม่เห็น · ปิด motion = นิ่ง
let teaseT = null;
function teaseStart() {
  clearInterval(teaseT); if (REDUCED || !document.querySelector('[data-tease]')) return;
  teaseT = setInterval(() => { const el = document.querySelector('[data-tease]'); if (!el) return clearInterval(teaseT);
    UI.teaseWide = !UI.teaseWide; el.querySelectorAll('.fan3').forEach(f => f.classList.toggle('on', (f.dataset.fan === 'W') === UI.teaseWide));
    setTimeout(() => { const hid = UI.teaseWide ? 'T' : 'W', f = document.querySelector(`[data-fan="${hid}"]`); if (!f) return; const list = TEMPLATES.filter(t => !!t[1] === (hid === 'W'));
      const k = UI['tease' + hid] = (UI['tease' + hid] + 1) % list.length; [2, 1, 0].forEach(d => { f.querySelector('.f' + d).src = `assets/tpl/${list[(k + d) % list.length][0]}.png`; }); }, 850); }, 3450);
}
