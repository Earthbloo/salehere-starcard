// ผูกปุ่มกับ flow — ทุก data-act ในหน้ามาลงที่นี่ · คีย์บอร์ด (Enter/Esc/Tab/ลูกศร) · ลากไฟล์มาวาง · เริ่มแอป

const bump = sel => { const n = document.querySelector(sel); if (!n) return; n.classList.remove('shake'); void n.offsetWidth; n.classList.add('shake'); };
function pickFiles(accept, multiple) {
  return new Promise(res => { const i = document.getElementById('file-pick'); i.value = ''; i.accept = accept; i.multiple = !!multiple; i.onchange = () => res([...i.files]); i.click(); });
}
async function addMediaFiles(kind, files) {
  const m = F.s.media, isVideo = kind === 'videos'; let failed = 0, big = 0;
  const room = kind === 'photos' ? m.photos.filter(x => !x).length : MAX[kind] - m[kind].length; files = files.slice(0, Math.max(0, room));
  if (UI.wiz) { UI.wiz.importing = { [kind]: files.length }; render(); }
  for (const f of files) {
    if (UI.wiz && UI.wiz.importing) { UI.wiz.importing[kind]--; }
    if (isVideo) {
      if (m.videos.length >= MAX.videos) break;
      if (!f.type.startsWith('video/')) { failed++; continue; }
      if (f.size > VIDEO_MAX_MB * 1048576) { big++; continue; }
      const v = await readVideo(f); if (v) m.videos.push({ id: 'v' + Date.now() + Math.random().toString(36).slice(2, 5), ...v }); else failed++;
    } else {
      if (!f.type.startsWith('image/')) { failed++; continue; }
      if (kind === 'photos' && !m.photos.includes(null)) break;
      if (kind === 'works' && m.works.length >= MAX.works) break;
      const src = await readImage(f); if (!src) { failed++; continue; }
      if (kind === 'photos') m.photos[m.photos.indexOf(null)] = src; else m.works.push({ id: 'w' + Date.now() + Math.random().toString(36).slice(2, 5), src });
    }
  }
  F.save(); if (UI.wiz) UI.wiz.importing = null;
  // ข้อความเดียวกับ salehere-ios
  if (UI.wiz) UI.wiz.err = big ? 'คลิปใหญ่เกินไป — ตัดให้สั้นลงแล้วลองใหม่' : failed ? 'อัปโหลดไม่สำเร็จ ลองใหม่อีกครั้ง' : null;
  render();
}
// เปลี่ยนไฟล์ในช่องเดิม (เป็น STAR แล้วลบไม่ได้) — รูปของคุณ = ช่องที่ i · ผลงาน/คลิป = id เดิม ตำแหน่งเดิม
async function swapMediaFile(kind, id, f) {
  const m = F.s.media, isVideo = kind === 'videos', w = UI.wiz;
  if (!f.type.startsWith(isVideo ? 'video/' : 'image/')) { if (w) w.err = 'อัปโหลดไม่สำเร็จ ลองใหม่อีกครั้ง'; return render(); }
  if (isVideo && f.size > VIDEO_MAX_MB * 1048576) { if (w) w.err = 'คลิปใหญ่เกินไป — ตัดให้สั้นลงแล้วลองใหม่'; return render(); }
  const got = isVideo ? await readVideo(f) : await readImage(f);
  if (!got) { if (w) w.err = 'อัปโหลดไม่สำเร็จ ลองใหม่อีกครั้ง'; return render(); }
  if (kind === 'photos') m.photos[Number(id)] = got;
  else { const i = m[kind].findIndex(x => x.id === id); if (i >= 0) m[kind][i] = { ...m[kind][i], ...(isVideo ? got : { src: got }) }; }
  F.save(); if (w) w.err = null; render();
}
function insightRead(key, file) {
  const m = UI.modal, k = m.id + '_' + key;
  if (file && !file.type.startsWith('image/')) { m.failed[k] = 'อัปโหลดไม่สำเร็จ ลองใหม่อีกครั้ง'; render(); return; }
  delete m.failed[k]; m.editing = null; m.reading.push(k); render();
  setTimeout(() => { // ของจริง: อัปโหลดแล้ว backend อ่านตัวเลขจากรูป (analyzeSocialProfileInsight) — ต้นแบบคืนค่าตัวอย่าง
    if (!UI.modal || UI.modal.type !== 'insight') return;
    F.s.insightValues[k] = SAMPLE_INSIGHT[key].map(v => [...v]); if (!F.s.insightSlots.includes(k)) F.s.insightSlots.push(k);
    F.save(); UI.modal.reading = UI.modal.reading.filter(x => x !== k); render();
  }, 1000);
}
function openStage(i) {
  const st = STAGES[i]; UI.reg = null;
  const base = { tab: 'home', campaignId: UI.campaignId || CAMPAIGNS[0].id, insight: false, schedule: false, kyc: null };
  if (st.screen && st.screen.startsWith('wizard')) {
    const kind = st.screen.split(':')[1], steps = kind === 'apply' ? (F.registerSteps.length ? ['intro', ...F.registerSteps] : []) : F.acceptSteps;
    Object.assign(UI, base); steps.length ? startWizard(kind, steps) : nav({ screen: kind === 'apply' ? 'register' : 'accept' });
  } else nav({ ...base, screen: st.screen || null });
  if (st.dialog) UI.dialog = { type: st.dialog };
  UI.lab = true; render(); if (st.note) toast(st.note);
}
// state เปลี่ยนจาก Lab ระหว่างที่ wizard เปิดอยู่ = wizard ต้องเห็นข้อมูลชุดใหม่ (ขั้นที่ติ๊กแล้วหายไป ครบแล้วก็ไปหน้าถัดไป)
function labRefresh() {
  const w = UI.wiz; UI.lab = true;
  if (UI.screen !== 'wizard' || !w) { render(); return; }
  const fresh = w.kind === 'apply' ? (F.registerSteps.length ? ['intro', ...F.registerSteps] : []) : w.kind === 'accept' ? F.acceptSteps : w.asked.filter(s => s === 'kyc' ? !F.isVerified : !F.has(s));
  if (fresh.join() === w.asked.join()) { render(); return; }
  if (!fresh.length) { nav({ screen: w.kind === 'apply' ? 'register' : w.kind === 'accept' ? 'accept' : (w.back || 'star') }, true); toast('ข้อมูลครบแล้ว'); }
  else startWizard(w.kind, fresh, w.back);
  UI.lab = true; render();
}

// ยืนยันเสร็จระหว่างอยู่ใน wizard (= `StarWizard.startKyc`): ผ่านทันที = ไปต่อ · ส่งทีมงานตรวจ/ไม่ผ่าน = ค้างที่ขั้นนี้ให้เห็นการ์ดสถานะ
// ปิด 8 ข้อพอดี = motion ก่อน (ทางสมัครกิจกรรมได้หน้า "คุณเป็น STAR แล้ว" แทน · ข้อสุดท้าย = ฉลองตอนจบ) · ไม่ใช่ข้อสุดท้าย = toast ทุกครั้ง
function wizKycDone() {
  const wasStar = F.isStar;
  return () => {
    const w = UI.wiz; if (F.s.verify === 'none' || !w || UI.screen !== 'wizard') { render(); return; }
    if (!F.isVerified) { w.err = null; render(); return; }
    const last = w.i >= w.steps.length - 1;
    if (!wasStar && F.isStar && w.kind !== 'apply' && !last) celebrateStar();
    if (!last) toast('ยืนยันตัวตนแล้ว · ไปต่อได้เลย');
    wizAdvance();
  };
}
const A = {
  tab: a => nav({ tab: a, campaignId: null, screen: null, insight: false, schedule: false }),
  openCampaign: a => nav({ campaignId: a, campTab: 'howTo' }),
  closeCampaign: () => nav({ campaignId: null }),
  campTab: a => { UI.campTab = a; render(); const t = document.getElementById('tab-' + a); if (t) t.focus(); },
  shareCampaign: () => openOverlay({ dialog: { type: 'share', what: 'กิจกรรมนี้', url: `https://salehere.co.th/star/campaign/${campaign().id}` } }),
  tapMain, openStar: () => nav({ screen: 'star' }),
  closeScreen: () => { UI.reg = null; nav({ screen: null }); },
  // ฟอร์มสมัคร
  regRadio: a => { const [i, o] = a.split('|'); UI.reg.answers[i] = o; },
  regCheck: a => { const c = UI.reg.checks; c.includes(a) ? c.splice(c.indexOf(a), 1) : c.push(a); },
  regUpload: () => { UI.reg.uploaded = true; render(); },
  consent: () => { F.s.consent = !F.s.consent; F.save(); render(); },
  submitRegister: () => { if (regMissing().length) { bump('#reg-miss'); return; } UI.reg = null; submitRegister(); },
  // ตอบรับ
  acceptAnswer: a => { UI.acceptAnswer = a; },
  editAddress: () => startWizard('one', ['address'], 'accept'),
  // หน้าสถานะยืนยันตัวตน
  // ส่งใหม่ = ถาม Lab ก่อน · ได้ผลจาก Lab หน้านี้อยู่ต่อแล้วโหลดสถานะใหม่ (ผ่าน/ยกเลิก = ปิดเอง) · ถ่ายจริง = พาไปแอป (= iOS `KycStatusPage.onResubmit`)
  kycResubmit: () => openKyc(() => { celebrateStar(); if (F.isVerified) toast('ป้าย Verified ขึ้นการ์ดแล้ว');
    if (UI.screen === 'kycStatus' && !F.kycBlocked) nav({ screen: null }, true); else render(); }),
  // ยกเลิกคำขอ: แตะครั้งแรก = ขอยืนยัน · ครั้งที่สอง = ยกเลิกจริง (หน้าสถานะ + ขั้น KYC ใน wizard — salehere-ios)
  kycCancel: () => { if (!UI.cancelAsk) { UI.cancelAsk = true; render(); return; } UI.cancelAsk = false; Object.assign(F.s, { verify: 'none', kycSentAt: null }); F.save();
    if (UI.screen === 'kycStatus') nav({ screen: null }, true); else render(); toast('ยกเลิกการส่งข้อมูลแล้ว'); },
  // Lab ผลยืนยันตัวตน (dialog "Lab · ผลยืนยันตัวตน")
  kycLabAsk: () => openKyc(UI.screen === 'wizard' ? wizKycDone() : null),
  kycLabPick: a => labKyc(a, UI.dialog && UI.dialog.done),
  kycLabReal: () => { const d = UI.dialog && UI.dialog.done; UI.dialog = null; realKyc(d); },
  pushTap: () => { const p = UI.push; UI.push = null; if (p) p.act(); else render(); },
  pushClose: () => { UI.push = null; render(); },
  askAccept: () => openOverlay({ dialog: { type: 'acceptConfirm' } }),
  askDecline: () => openOverlay({ dialog: { type: 'declineConfirm' } }),
  doAccept: () => { F.s.phase = 'acceptedQuota'; F.s.order = 'shipping'; F.save(); nav({ screen: null }, true); toast('ตอบรับแล้ว · รอรับของจากแบรนด์'); },
  doDecline: () => { nav({ screen: null }, true); toast('สละสิทธิ์แล้ว — จำลอง'); },
  submitLinks: () => { if (!campaign().channels.every(linkValid)) { bump('#link-miss'); return; } submitLinks(); },
  // ยืนยันตัวตน
  // ชิปข้างชื่อ: รอตรวจ/ตีกลับ = ขั้น KYC ของ wizard (มีการ์ดสถานะ) ไม่เปิดกล้องซ้ำ · ยังไม่ทำ = เริ่มยืนยันตัวตนเลย
  kyc: () => { if (F.kycBlocked) startWizard('one', ['kyc'], UI.screen === 'reveal' ? 'reveal' : 'star'); else if (!F.isVerified) openKyc(null); },
  dialogKyc: () => { UI.dialog = null; openKyc(null); },
  // มือถือ: ปุ่ม "เริ่มยืนยันตัวตน" ในกล่องยืนยันตัวตน — อยู่ใน wizard = จบแล้วไปข้อถัดไปเอง
  startKyc: () => openKyc(UI.screen === 'wizard' ? wizKycDone() : null),
  kycDoc: a => { UI.kyc.doc = a; render(); },
  // จบกล้อง → "ระบบกำลังประมวลผลภาพ" → OCR ผ่าน = ยืนยันการส่ง → เสร็จสมบูรณ์ · ไม่ผ่าน (Lab) = เตือน → ฟอร์มกรอกมือ → ยืนยันการส่ง → ส่งคำขอสำเร็จ (รอตรวจ)
  kycStep: a => { UI.kyc.step = a; render(); const sb = document.querySelector('.shell-b'); if (sb) sb.scrollTop = 0; focusOverlay();
    if (a === 'checking') setTimeout(() => { const k = UI.kyc; if (k && k.step === 'checking') { if (kycOutcome.get() === 'waiting' && !k.manual) { k.manual = true; k.step = 'ocrFail'; } else k.step = 'prompt'; render(); focusOverlay(); } }, 1400); },
  kycClose: () => closeOverlay({ kyc: null }),
  kycFinish,
  closeDialog: () => closeOverlay({ dialog: null }),
  closeModal: () => closeOverlay({ modal: null }),
  copyLink: a => { (navigator.clipboard ? navigator.clipboard.writeText(a) : Promise.reject()).then(() => toast('คัดลอกลิงก์แล้ว'), () => toast('คัดลอกไม่ได้ — เลือกข้อความแล้วกด ⌘C')); },
  // wizard
  wizNext, wizBack, wizExit: exitWizard, wizSkip: () => { UI.wiz.err = null; wizAdvance(); },
  wizLeave: () => { UI.dialog = null; leaveWizard(); toast('เก็บไว้ให้แล้ว · กลับมาทำต่อได้ทุกเมื่อ'); },
  wizJump: a => { UI.wiz.i = Number(a); UI.wiz.err = null; render(); },
  // ผ่านทันที = ไปต่อ · ส่งทีมงานตรวจ = ค้างที่ขั้นนี้ให้เห็นการ์ดรอผล (ปุ่มกลายเป็น "ปิดไว้ก่อน")
  wizKyc: () => openKyc(wizKycDone()),
  setKind: a => { F.s.creatorKind = a; F.save(); render(); },
  setPay: a => { F.s.payKind = a; F.save(); render(); },
  toggleCat: a => { const c = F.s.categories; if (c.includes(a)) c.splice(c.indexOf(a), 1); else if (c.length < 5) c.push(a); else return bump('.count-line'); F.save(); render(); },
  toggleProv: a => { const c = F.s.provinces; if (c.includes(a)) c.splice(c.indexOf(a), 1); else if (c.length < 3) c.push(a); else return bump('.count-line'); F.save(); render(); },
  toggleAvail: a => { const [d, t] = a.split('|'), w = F.s.availWeek, cur = w[d] || [];
    const next = t === '*' ? (cur.length === DAY_SLOTS.length ? [] : [...DAY_SLOTS]) : cur.includes(t) ? cur.filter(x => x !== t) : DAY_SLOTS.filter(x => x === t || cur.includes(x));
    if (next.length) w[d] = next; else delete w[d]; F.save(); render(); },
  availDay: a => { UI.availDay = a; render(); },
  availPreset: a => { F.s.availWeek = a === 'weekend' ? { ...F.s.availWeek, 'ส': [...DAY_SLOTS], 'อา': [...DAY_SLOTS] } : a === 'evening' ? Object.fromEntries(WEEK.map(d => [d, DAY_SLOTS.filter(x => x === 'slot_17_late' || (F.s.availWeek[d] || []).includes(x))])) : {}; F.save(); render(); },
  bodyGuide: () => { UI.bodyGuide = !UI.bodyGuide; render(); },
  // รูปของคุณ = ทีละรูปต่อช่อง (salehere-ios)
  addMedia: a => pickFiles(a === 'videos' ? 'video/*' : 'image/*', a !== 'photos').then(f => f.length && addMediaFiles(a, f)),
  rmMedia: a => { const [kind, id] = a.split('|'), m = F.s.media, key = kind + id;
    if (UI.wiz.del !== key) { UI.wiz.del = key; render(); return; }
    UI.wiz.del = null; if (kind === 'photos') m.photos[Number(id)] = null; else m[kind] = m[kind].filter(x => x.id !== id); F.save(); render(); },
  swapMedia: a => { const [kind, id] = a.split('|'); pickFiles(kind === 'videos' ? 'video/*' : 'image/*', false).then(f => f.length && swapMediaFile(kind, id, f[0])); },
  sampleMedia: () => { F.sampleMedia(); F.save(); UI.wiz.err = null; render(); toast('ได้รับรูปและคลิปจากมือถือแล้ว'); },
  // ช่องทาง
  editChannel: a => { const isNew = !F.s.connected.includes(a), x = SOC[a], rates = {};
    if (!isNew) x.formats.forEach(f => { if (F.s.rates[a + '_' + f] != null) rates[f] = F.s.rates[a + '_' + f]; });
    openOverlay({ modal: { type: 'channel', id: a, isNew, link: isNew ? (F.s.autofill ? x.mock[0] : '') : F.link(a), followers: isNew ? (F.s.autofill ? x.mock[1] : 0) : F.followers(a), rates, touched: !isNew, err: null } }); },
  pasteLink: () => { (navigator.clipboard && navigator.clipboard.readText ? navigator.clipboard.readText() : Promise.reject()).then(t => { UI.modal.link = t.trim(); UI.modal.touched = true; render(); }, () => toast('วางไม่ได้ — คลิกช่องแล้วกด ⌘V')); },
  resetRates: () => { UI.modal.rates = {}; render(); },
  // ลิงก์ "เอาออก" ใต้การ์ดช่อง → ยืนยัน "ยกเลิกการผูกบัญชี" (salehere-ios) · ช่องสุดท้ายเอาออกได้เฉพาะตอนเป็น STAR แล้ว
  askRemoveChannel: a => openOverlay({ dialog: { type: 'unlinkChannel', id: a } }),
  // ไม่มีช่องทาง = ข้อ "ช่องทางของฉัน" กลับเป็นยังไม่มี (ลงทะเบียนครั้งหน้าถามใหม่) · ไม่มี toast (salehere-ios)
  removeChannel: () => { const s = F.s, id = UI.dialog && UI.dialog.id; s.connected = s.connected.filter(x => x !== id);
    if (!s.connected.length) ['socials', 'rate', 'insight'].forEach(k => F.remove(k));
    F.save(); closeOverlay({ dialog: null }); },
  saveChannel: () => { const m = UI.modal, chk = F.checkLink(m.id, m.link), s = F.s;
    if (!chk.ok) { m.err = chk.msg || `วางลิงก์โปรไฟล์ ${SOC[m.id].name} ก่อน`; m.touched = true; return render(); }
    if (!(m.followers > 0)) { m.err = 'ใส่ยอดผู้ติดตามก่อน'; return render(); }
    s.links[m.id] = chk.url; s.followerCounts[m.id] = m.followers; s.followerSources[m.id] = 'manual';
    SOC[m.id].formats.forEach(f => { s.rates[m.id + '_' + f] = m.rates[f] != null ? m.rates[f] : F.suggest(m.followers, f); });
    if (m.isNew) s.connected.push(m.id); F.save(); if (UI.wiz) UI.wiz.err = null;
    const fresh = m.isNew && SOC[m.id].insight, id = m.id; closeOverlay({ modal: null });
    // ผูกช่องใหม่เสร็จ → พาไปแนบข้อมูลผู้ติดตามของช่องนั้นต่อทันที
    if (fresh) setTimeout(() => A.openInsightPanel(id), 350); },
  openInsightPanel: a => openOverlay({ modal: { type: 'insight', id: a, editing: null, draft: [], err: null, reading: [], failed: {} } }),
  insightUpload: a => pickFiles('image/*', false).then(f => f.length && insightRead(a, f[0])),
  insightPhone: () => INSIGHT_SLOTS.forEach(x => { if (!F.s.insightSlots.includes(UI.modal.id + '_' + x.key)) insightRead(x.key, null); }),
  insightEdit: a => { const m = UI.modal, k = m.id + '_' + a; m.err = null; if (m.editing === k) m.editing = null; else { m.editing = k; m.draft = (F.s.insightValues[k] || []).map(v => [...v]); } render(); },
  insightSave: a => { const m = UI.modal, k = m.id + '_' + a, v = m.draft.map(x => [String(x[0]).trim(), Number(x[1]) || 0]).filter(x => x[1] > 0 && x[0]);
    if (!v.length) { m.err = 'ใส่อย่างน้อย 1 ค่า'; return render(); }
    if (v.reduce((n, x) => n + x[1], 0) > 100.5) { m.err = 'รวมกันต้องไม่เกิน 100%'; return render(); }
    F.s.insightValues[k] = v; if (!F.s.insightSlots.includes(k)) F.s.insightSlots.push(k); F.save(); m.editing = null; m.err = null; render(); },
  // Star Profile
  fillOne: a => startWizard('one', [a], UI.screen === 'reveal' ? 'reveal' : 'star'),
  // แถวที่ขาด (หลัง STAR เท่านั้น — ก่อนนั้นแตะไม่ได้) = เริ่มที่ข้อนั้นแล้วไล่ต่อข้อที่ขาดจนครบ = `missingSteps(from:)`
  fillFrom: a => startWizard('one', F.missingSteps(a), UI.screen === 'reveal' ? 'reveal' : 'star'),
  // "เติมข้อมูลต่อ" = ข้อที่ขาดใน 8 ข้อก่อน (สถานะ C) แล้วข้อเสริม = `fillMoreSteps`
  fillMissing: () => startWizard('one', F.fillMoreSteps, 'star'),
  applyAll: () => startWizard('one', F.applySteps, 'star'),
  openCard: () => { openStarCard(); if (UI.screen === 'card' && F.s.cards === 0) { F.s.cards = 1; F.save(); } },
  closeCard: () => nav({ screen: 'star' }),
  shareCard: () => openOverlay({ dialog: { type: 'share', what: 'Star Card', url: `https://salehere.co.th/star/${F.handleMain}` } }),
  openInsight: () => nav({ insight: true }),
  closeInsight: () => nav({ insight: false }),
  editCard: () => nav({ insight: false, screen: 'card' }),
  range: a => { UI.range = a; UI.insLoading = true; render(); setTimeout(() => { UI.insLoading = false; if (UI.insight) render(); }, 350); },
  refreshInsight: () => { UI.insLoading = true; render(); setTimeout(() => { UI.insLoading = false; if (UI.insight) { render(); toast('ข้อมูลล่าสุดแล้ว'); } }, 800); },
  teaseGo: a => { UI.tease = Number(a); UI.teaseStop = true; render(); const b = document.querySelector('.ts-fan .on button'); if (b) b.focus({ preventScroll: true }); },
  // การ์ด "ใช้ให้แบรนด์คัดเลือก": ยังไม่เคยแตะ (null) = กางเมื่อยังขาด · แตะแล้วจำตามที่ผู้ใช้เลือก
  toggleLater: () => { UI.laterOpen = !(UI.laterOpen ?? extraRows('profile').some(r => !F.done(r))); render(); const b = document.querySelector('[data-act=toggleLater]'); if (b) b.focus({ preventScroll: true }); },
  // banner: เหลือแค่ยืนยันตัวตนข้อเดียว + รอตรวจ/ไม่ผ่าน = หน้าสถานะ · อื่น ๆ (รวมสถานะ C) = ถามเฉพาะข้อที่ขาดใน 8 ข้อ แล้วจบที่ Star Profile (salehere-ios)
  bannerTap: () => { if (kycOnlyBlocked()) { UI.cancelAsk = false; nav({ screen: 'kycStatus' }); return; } startWizard('one', F.starMissing, 'star'); },
  // ยังไม่เคยแตะ (null) = สถานะ C กางให้เลย · อื่น ๆ หุบ (= `listOpenChoice ?? needsStarInfo`)
  toggleList: () => { UI.listOpen = !(UI.listOpen ?? F.needsStarInfo); render(); const b = document.querySelector('[data-act=toggleList]'); if (b) { b.focus({ preventScroll: true }); const d = document.getElementById('data-rows'); if (UI.listOpen && d) d.scrollIntoView({ behavior: REDUCED ? 'auto' : 'smooth', block: 'nearest' }); } },
  openSchedule: () => nav({ schedule: true }),
  closeSchedule: () => nav({ schedule: false }),
  revealNext: () => { F.s.revealSeen = true; F.save(); UI.reg = null; nav({ screen: 'register' }); },
  // ตารางงาน
  schedDay: a => { UI.sched.sel = a; UI.sched.job = null; render(); },
  schedMonth: a => { const d = SD.date(SD.first(UI.sched.sel)); d.setMonth(d.getMonth() + Number(a)); const iso = SD.iso(d); UI.sched.sel = SD.first(iso) === SD.first(SD.today) ? SD.today : iso; UI.sched.job = null; render(); },
  addJob: () => openOverlay({ modal: { type: 'addJob', step: 1, d: newDraft() } }),
  openJob: a => { UI.sched.job = a; UI.sched.del = null; render(); },
  closeJob: () => { UI.sched.job = null; render(); },
  tickStep: a => { const [j, s] = a.split('|'); UI.sched.ask = SCHED.toggle(j, s); render(); },
  askYes: () => { const k = UI.sched.ask, j = SCHED.job(k.jobId); if (j) j.showOnCard = true; F.save(); UI.sched.ask = null; render(); toast(k.doneText); },
  askNo: () => { UI.sched.ask = null; render(); },
  jobPaid: a => { const j = SCHED.job(a); j.paid = !j.paid; F.save(); render(); },
  jobShow: a => { const j = SCHED.job(a); j.showOnCard = !j.showOnCard; F.save(); },
  jobDelete: a => { if (UI.sched.del !== a) { UI.sched.del = a; return render(); } F.s.jobs = F.s.jobs.filter(j => j.id !== a); F.save(); UI.sched.job = null; UI.sched.del = null; render(); toast('ลบงานแล้ว'); },
  ajPlat: a => { const d = UI.modal.d; if (!d.plats[a]) { const dates = Object.values(d.plats).map(v => v.date).filter(Boolean).sort(); d.plats[a] = { counts: { [JOB_FORMATS[a][0]]: 1 }, date: dates[0] || '' }; } d.active = a; render(); },
  ajDrop: a => { const d = UI.modal.d; delete d.plats[a]; d.active = JOB_PLATFORMS.find(p => d.plats[p]) || null; render(); },
  ajCount: a => { const [f, dir] = a.split('|'), v = UI.modal.d.plats[UI.modal.d.active]; v.counts[f] = Math.max(0, Math.min(9, (v.counts[f] || 0) + Number(dir))); render(); },
  ajSite: a => { UI.modal.d.site = a === 'true'; render(); },
  ajBack: () => { UI.modal.step--; render(); },
  ajNext: () => { const m = UI.modal, d = m.d;
    if (SCHED.draftMissing(d, m.step)) { if (m.step === 2) { const p = JOB_PLATFORMS.find(x => d.plats[x] && (!d.plats[x].date || Object.values(d.plats[x].counts).every(n => !n))); if (p) d.active = p; } render(); return bump('.modal footer .btn.dark'); }
    if (m.step < 3) { m.step++; render(); return focusOverlay(); }
    const job = SCHED.build(d); F.s.jobs.push(job); F.save(); if (job.steps[0]) UI.sched.sel = job.steps[0].date; UI.sched.job = null;
    closeOverlay({ modal: null }); toast(`ลงงานแล้ว · ตั้งเตือน ${job.steps.length} อย่าง`); },
  // Lab
  openLab: () => { UI.lab = true; render(); },
  closeLab: () => { UI.lab = false; render(); },
  labGo: a => { F.goto(Number(a)); UI.wiz = null; openStage(Number(a)); },
  labTick: a => { const key = a || null, on = !(key ? F.has(key) : F.isVerified), cur = F.stageIndex(UI), back = F.tick(key, on, cur); if (!F.starComplete) celebrateStar();
    if (back != null && back < PROFILE_ONLY) { const st = STAGES[back]; Object.assign(F.s, { phase: st.phase, order: st.order || 'preparing', reviewed: !!st.reviewed, draftApproved: !!st.draftApproved }); F.save(); UI.wiz = null; openStage(back); } else labRefresh(); },
  labPreset: a => { F.applyPreset(PRESETS.find(p => p.id === a)); UI.listOpen = null; if (!F.starComplete) celebrateStar(); if (UI.screen === 'wizard') labRefresh(); else { UI.lab = true; render(); } },
  labAutofill: () => { F.s.autofill = !F.s.autofill; F.save(); },
  // ยศ STAR (`myProfile.userRank`) — STAR เก่าเป็น STAR ต่อแม้ 8 ข้อยังไม่ครบ = สถานะ C (salehere-ios 7 ต.ค. 2569)
  labRank: () => { F.s.starRank = !F.s.starRank; F.save(); UI.listOpen = null; labRefresh(); },
  // สถานะยืนยันตัวตน = ผลจาก staff มาถึง (แจ้งเตือนจำลองเด้งเอง) · ตีกลับต้องมีเหตุผลติดมาเสมอ
  labVerify: a => { const s = F.s, old = s.verify; if (old === a) return;
    s.verify = a; if (a === 'waiting' && !s.kycSentAt) s.kycSentAt = Date.now(); if (a === 'rejected' && !s.verifyReason) s.verifyReason = REJECT_REASONS[0]; if (a !== 'rejected') s.verifyReason = ''; if (a === 'none') s.kycSentAt = null;
    F.save(); if (!F.starComplete) celebrateStar();
    // หน้าสถานะหมดหน้าที่เมื่อผ่านแล้วหรือยกเลิก
    if (UI.screen === 'kycStatus' && (a === 'approved' || a === 'none')) { UI.screen = null; history.replaceState(snap(), ''); }
    labRefresh(); verifyChanged(old, a); },
  labReason: a => { F.s.verifyReason = REJECT_REASONS[Number(a)]; F.save(); render(); },
  labOutcome: a => { kycOutcome.set(a); render(); },
  labFill: () => { F.fillAll(); labRefresh(); },
  labReset: a => { F.reset(a === 'all'); UI.wiz = null; UI.reg = null; nav({ tab: 'home', campaignId: null, screen: null, insight: false, schedule: false }); UI.lab = true; render(); toast('ล้างข้อมูลแล้ว'); },
};

// ---------- events ----------
document.addEventListener('click', e => {
  const n = e.target.closest('[data-act]'); if (!n || n.tagName === 'INPUT') return;
  if (n.dataset.self && e.target !== n) return;
  if (n.disabled) return;
  const f = A[n.dataset.act]; if (!f) return;
  if (UI.wiz && UI.wiz.err && !['wizNext', 'addMedia'].includes(n.dataset.act)) UI.wiz.err = null;
  e.preventDefault(); f(n.dataset.arg);
});
document.addEventListener('change', e => {
  const n = e.target;
  if (n.tagName === 'INPUT' && n.dataset.act && A[n.dataset.act]) return A[n.dataset.act](n.dataset.arg);
  // เลือกตำบลแล้วอำเภอ/จังหวัดตามมา (= getDistrictProvince)
  if (n.dataset && n.dataset.bind === 's.addressInfo.sub') { const a = F.s.addressInfo; a.sub = n.value; const p = zipPlace(a.zip, a.sub); if (p) Object.assign(a, p); F.save(); render(); return; }
  if (n.dataset && n.dataset.bind) { if (n.dataset.touch && UI.modal) UI.modal.touched = true; if (n.dataset.bind.startsWith('ui.linkDraft.')) { UI.linkTouched[n.dataset.bind.split('.')[2]] = true; render(); } if (n.dataset.live || n.dataset.touch) render(); }
});
let saveT;
document.addEventListener('input', e => {
  const n = e.target; if (!n.dataset || !n.dataset.bind) return;
  let v = n.value;
  if (n.dataset.digits) { v = v.replace(/\D/g, ''); if (v !== n.value) n.value = v; }
  const path = n.dataset.bind;
  // รหัสไปรษณีย์เปลี่ยน = ล้างตำบล/อำเภอ/จังหวัด แล้วหาตำบลใหม่ (มีตำบลเดียว = เลือกให้เลย)
  if (path === 's.addressInfo.zip' && v !== F.s.addressInfo.zip) { const a = F.s.addressInfo; Object.assign(a, { sub: '', district: '', province: '' }); const subs = zipSubs(v); if (subs.length === 1) { a.sub = subs[0]; Object.assign(a, zipPlace(v, subs[0])); } }
  const numeric = /^ui\.modal\.(followers|rates\.|draft\.\d+\.1)/.test(path);
  setPath(path, numeric ? (Number(v) || 0) : v);
  if (UI.modal && UI.modal.err) UI.modal.err = null;
  if (UI.wiz && UI.wiz.err) { UI.wiz.err = null; const er = document.getElementById('wz-err'); if (er) er.classList.add('none'); }
  if (UI.wiz && UI.wiz.errs && path in UI.wiz.errs) {
    const keys = UI.wiz.errLink && UI.wiz.errLink.includes(path) ? UI.wiz.errLink : [path];
    keys.forEach(k => { delete UI.wiz.errs[k]; document.querySelectorAll(`[data-bind="${k}"]`).forEach(x => { const f = x.closest('.fld'); if (!f) return; f.classList.remove('bad'); x.removeAttribute('aria-invalid'); const m = f.querySelector('.ferr'); if (m) m.remove(); }); });
  }
  if (path.startsWith('s.')) { clearTimeout(saveT); saveT = setTimeout(() => F.save(), 300); }
  if (n.dataset.live === '1') render();
});
document.addEventListener('keydown', e => {
  const t = e.target, overlay = document.querySelector('.modal') || document.querySelector('.shell') || document.querySelector('.wzcard');
  if (e.key === 'Escape') {
    if (UI.dialog) return A[UI.dialog.type === 'wizExit' ? 'closeDialog' : 'closeDialog']();
    if (UI.modal) return A.closeModal(); if (wizAsModal()) return exitWizard(); if (UI.lab) return A.closeLab();
  }
  if (e.key === 'Tab' && overlay) { // โฟกัสวนอยู่ใน dialog
    const f = [...overlay.querySelectorAll('button:not([disabled]), input:not([type=file]), select, textarea, a[href], [tabindex="0"]')].filter(x => x.offsetParent !== null);
    if (!f.length) return; const first = f[0], last = f[f.length - 1];
    if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); } else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
    else if (!overlay.contains(document.activeElement)) { e.preventDefault(); first.focus(); }
  }
  if (e.key === 'Enter' && !e.isComposing && t.tagName !== 'TEXTAREA' && t.tagName !== 'BUTTON' && t.tagName !== 'A' && t.tagName !== 'SELECT') {
    if (UI.dialog || UI.kyc) return;
    if (UI.modal) { const b = overlay && overlay.querySelector('footer .btn.dark'); if (b && (t.tagName === 'INPUT') && t.type !== 'checkbox' && t.type !== 'radio') { e.preventDefault(); t.dispatchEvent(new Event('change', { bubbles: true })); A[b.dataset.act](b.dataset.arg); } return; }
    if (UI.screen === 'wizard' && (t.tagName === 'INPUT' ? !['checkbox', 'radio', 'search'].includes(t.type) : t === document.body || t.tagName === 'H1' || t.tagName === 'MAIN')) { e.preventDefault(); wizNext(); }
  }
  if ((e.key === 'ArrowLeft' || e.key === 'ArrowRight') && t.getAttribute && t.getAttribute('role') === 'tab') { e.preventDefault(); A.campTab(UI.campTab === 'howTo' ? 'reviews' : 'howTo'); }
  if ((e.key === 'ArrowLeft' || e.key === 'ArrowRight') && t.classList && t.classList.contains('chart')) { e.preventDefault(); const pts = JSON.parse(t.dataset.pts); scrubTo(t, Math.max(0, Math.min(pts.length - 1, (t._i == null ? pts.length - 1 : t._i) + (e.key === 'ArrowLeft' ? -1 : 1)))); }
});
// อ่านค่ารายวันบนกราฟ: เมาส์ชี้ หรือโฟกัสแล้วกดลูกศร
function scrubTo(chart, i) {
  const pts = JSON.parse(chart.dataset.pts), d = INSIGHT.get(UI.range), g = chart.querySelector('#scrub'), tip = chart.querySelector('#scrub-tip'), W = Number(chart.dataset.w);
  chart._i = i; g.style.display = ''; g.querySelector('line').setAttribute('x1', pts[i][0]); g.querySelector('line').setAttribute('x2', pts[i][0]);
  g.querySelector('circle').setAttribute('cx', pts[i][0]); g.querySelector('circle').setAttribute('cy', pts[i][1]);
  chart.classList.add('scrubbing'); tip.style.display = ''; tip.textContent = `${d.names[i]} · ${d.daily[i].toLocaleString('en-US')} วิว`;
  tip.style.left = Math.max(8, Math.min(92, pts[i][0] / W * 100)) + '%'; tip.setAttribute('role', 'status');
}
document.addEventListener('mousemove', e => {
  const c = e.target.closest && e.target.closest('.chart'); if (!c) return;
  const r = c.getBoundingClientRect(), pts = JSON.parse(c.dataset.pts), W = Number(c.dataset.w), x = (e.clientX - r.left) / r.width * W;
  let best = 0; pts.forEach((p, i) => { if (Math.abs(p[0] - x) < Math.abs(pts[best][0] - x)) best = i; }); if (c._i !== best) scrubTo(c, best);
});
document.addEventListener('mouseout', e => { const c = e.target.closest && e.target.closest('.chart'); if (c && !c.contains(e.relatedTarget)) { c.classList.remove('scrubbing'); c._i = null; c.querySelector('#scrub').style.display = 'none'; c.querySelector('#scrub-tip').style.display = 'none'; } });
// ลากไฟล์มาวาง
document.addEventListener('dragover', e => { const z = e.target.closest && e.target.closest('[data-drop]'); if (z) { e.preventDefault(); z.classList.add('drag'); } });
document.addEventListener('dragleave', e => { const z = e.target.closest && e.target.closest('[data-drop]'); if (z && !z.contains(e.relatedTarget)) z.classList.remove('drag'); });
document.addEventListener('drop', e => {
  const z = e.target.closest && e.target.closest('[data-drop]'); if (!z) return; e.preventDefault(); z.classList.remove('drag');
  const [type, arg] = z.dataset.drop.split(':'), files = [...e.dataTransfer.files]; if (!files.length) return;
  if (type === 'media') addMediaFiles(arg, files); else if (type === 'insight') insightRead(arg, files[0]);
});

// ทางลัดไว้แคปจอ (presentation): `?open=star|kycStatus|banner` เปิดหน้านั้นเลย · `?tab=profile` · `?seed=<base64 JSON>` ทับ state ก่อนวาด
const Q = new URLSearchParams(location.search);
if (Q.get('seed')) try { Object.assign(F.s, JSON.parse(decodeURIComponent(escape(atob(Q.get('seed')))))); F.save(); } catch (e) { /* seed เสีย = ใช้ state เดิม */ }
if (Q.get('tab')) UI.tab = Q.get('tab');
if (Q.get('open') === 'star' || Q.get('open') === 'kycStatus') UI.screen = Q.get('open');
history.replaceState(snap(), '');
render();
if (Q.get('open') === 'banner') A.bannerTap();
