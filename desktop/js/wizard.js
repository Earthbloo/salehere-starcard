// wizard "หนึ่งคำถามต่อหนึ่งหน้า" (= StarWizard.swift) — คำถาม ลำดับ เงื่อนไข และข้อความเท่ากับ iOS
// desktop: ซ้าย = คำถาม · ขวา = การ์ดข้อมูลที่เติมตามที่ตอบ (ช่องประ = ข้อที่ยังเหลือ) · แก้ข้อเดียวจาก Star Profile = dialog ทับหน้าเดิม

const ON_CARD = { kyc: 'ขึ้นตรา Verified ข้างชื่อ', socials: 'ขึ้นยอดผู้ติดตามรายช่อง + ป้ายราคา', categories: 'ขึ้นสายงานใต้ชื่อ', media: 'ขึ้นรูปหลัก ผลงาน และบรรทัดแนะนำตัว',
  province: 'ขึ้นป้ายพื้นที่รับงาน', availability: 'ขึ้นวันว่างในส่วนรับงาน', contact: 'ขึ้น LINE · เบอร์ · เว็บไซต์', kind: 'บอกแบรนด์ว่าคุยกับบุคคลหรือเพจ',
  address: 'แบรนด์ไม่เห็น · ใช้ส่งของตอนได้งาน', bank: 'แบรนด์ไม่เห็น · ใช้โอนค่าตัว', body: 'ขึ้นช่องสัดส่วนบนการ์ดสายแฟชั่น' };

function wizHeading(st) {
  const a = UI.wiz.asked;
  switch (st) {
    case 'kind': return 'คุณเป็นแบบไหน? 🙋';
    case 'socials': return a.includes('socials') ? 'แปะวาร์ปช่องของคุณเลย 📱' : a.includes('rate') ? 'เรทรับงานของคุณ 💸' : 'ข้อมูลผู้ติดตามของคุณ 📊';
    case 'categories': return 'คุณเป็นครีเอเตอร์สายไหน? 🎨';
    case 'media': return 'เกี่ยวกับคุณ 📸';
    case 'province': return 'อยู่จังหวัดไหน / ไปถึงไหนได้บ้าง? 📍';
    case 'availability': return 'ว่างรับงานวันไหน? 📅';
    case 'contact': return 'ให้แบรนด์ทักทางไหน? 💬';
    case 'address': return 'ส่งของไปที่ไหน? 📦';
    case 'bank': return 'รับเงินในนามใคร? 🏦';
    case 'body': return 'สัดส่วนของคุณ 📏';
    case 'kyc': return { approved: 'ยืนยันตัวตนแล้ว 🪪', waiting: 'ทีมงานกำลังตรวจเอกสาร 🪪', rejected: 'เอกสารยังไม่ผ่าน 🪪' }[F.s.verify] || 'ยืนยันตัวตนก่อนสมัคร 🪪';
  }
  return '';
}
function wizPurpose(st) {
  if (st === 'address') return 'ของรางวัลจะส่งมาที่นี่ · กรอกครั้งเดียว';
  // ไม่อ้างค่าตัวของงาน (salehere-ios)
  if (st === 'bank') return 'ใช้กับทุกงานที่มีค่าตัว';
  return '';
}
function wizLines(st) {
  const a = UI.wiz.asked;
  if (st === 'socials' && !a.includes('socials')) return STEP.line[a.includes('rate') ? 'rate' : 'insight'];
  // ขั้น KYC ตอนรอตรวจ/ตีกลับ = ชิปชุดเดียวกับหน้าสถานะ
  if (st === 'kyc') return F.s.verify === 'waiting' ? ['แจ้งผลภายใน 3 วันทำการ', 'คำตอบที่กรอกไว้ยังอยู่ครบ'] : F.s.verify === 'rejected' ? ['ส่งใหม่ได้เลย ไม่ต้องรอ', 'คำตอบที่กรอกไว้ยังอยู่ครบ'] : STEP.line.kyc;
  return STEP.line[st] || [];
}
// หน้า "เกี่ยวกับคุณ" = แนะนำตัว + รูป · ผลงาน · คลิป ครบเสมอ ไม่ว่าเข้าจากทางไหน (salehere-ios `showAbout` = true · ผู้ใช้ 7 ต.ค. 2569)
// เข้าหน้าข้อนั้น (= `.onAppear` ของ iOS): ช่องรูปที่ 1 ใช้รูปโปรไฟล์ให้ (ยังไม่มีรูปของคุณเลยเท่านั้น) · ช่องทางติดต่อเติมจากบัญชีเมื่อยังว่าง
function wizOnShow(st) {
  // ครั้งเดียวต่อการเข้าหน้า (= onAppear) — วาดซ้ำระหว่างกรอกไม่เติมทับช่องที่ผู้ใช้เพิ่งลบ
  const w = UI.wiz; if (w.shownAt === w.i) return; w.shownAt = w.i;
  const s = F.s;
  if (st === 'media' && !s.media.photos.some(Boolean)) { s.media.photos[0] = 'assets/ph01.jpg'; F.save(); }
  if (st === 'contact') {
    // เบอร์จากบัญชี → ไม่มีเอาจากที่อยู่รับของ · LINE จากบัญชี · ต้องผ่าน format ก่อน ไม่ผ่านเว้นว่าง · แค่เติมให้ ยังไม่นับว่าครบจนกว่าจะกดถัดไป
    const t = !s.phone && (F.prefillPhone(ACCOUNT_TEL) || F.prefillPhone(s.addressInfo.tel)); if (t) s.phone = t;
    if (!s.lineID && F.validLine(ACCOUNT_LINE)) s.lineID = ACCOUNT_LINE;
  }
}
function wizContext() {
  const w = UI.wiz, c = campaign();
  return w.kind === 'one' ? (F.isStar ? 'เติมข้อมูล' : 'สมัครเป็น STAR') : w.kind === 'apply' ? (F.isStar ? `ข้อมูล STAR · ก่อนสมัคร ${c.episode}` : `สมัครเป็น STAR · ${c.episode}`) : `ข้อมูล STAR · ก่อนตอบรับ ${c.episode}`;
}
function wizButton() {
  const w = UI.wiz, last = w.i === w.steps.length - 1;
  // ติดด่านยืนยันตัวตน (รอตรวจ/ตีกลับ) = ปิดเก็บคำตอบไว้ก่อน · ยังไม่เคยส่ง = ปุ่มปกติ กดแล้วบอกให้ยืนยันก่อน (= iOS)
  if (w.steps[w.i] === 'kyc' && F.kycBlocked) return 'ปิดไว้ก่อน';
  if (!last) return 'ถัดไป';
  return w.kind === 'one' ? 'บันทึก' : w.kind === 'apply' ? 'ไปฟอร์มสมัคร' : 'ไปหน้าตอบรับ';
}
function wizQuestion(st) {
  const w = UI.wiz, lines = wizLines(st), purpose = wizPurpose(st);
  return `${lines.length ? `<ul class="nudges">${lines.map((l, i) => `<li>${i === 0 ? ic('eye', 14, 'b') : ''}${l}</li>`).join('')}</ul>` : purpose ? `<p class="purpose">${purpose}</p>` : ''}
    <p id="wz-err" class="err ${w.err ? '' : 'none'}" role="alert" tabindex="-1">${w.err ? ic('warning', 16, 'f') + esc(w.err) : ''}</p>
    <div class="wz-c ${w.shake && Date.now() - w.shake < 400 ? 'shake' : ''}">${wizControl(st)}</div>`;
}

// ข้อที่ข้ามได้ (= WizStep.optional) — iOS มีลิงก์ "ข้ามไว้ก่อน" ใต้ปุ่ม
const STEP_OPTIONAL = ['body'];
function wizardView() {
  const w = UI.wiz, st = w.steps[w.i], c = campaign(), real = w.steps.filter(s => s !== 'intro'), total = real.length, n = w.steps.slice(0, w.i + 1).filter(s => s !== 'intro').length;
  wizOnShow(st);
  let main;
  if (st === 'intro') {
    // หน้าตาเดียวกันทั้งสถานะ A (ยังไม่เป็น STAR) และ C (STAR เก่าที่ยังขาด) ต่างแค่หัว + ปุ่ม — การ์ดเดียวกัน + ช่องประ 1 ช่องต่อ 1 ข้อที่ขาด (salehere-ios)
    // ป้ายบริบท "สมัคร {ชื่อกิจกรรม}" ทั้งสองสถานะ (= `STAR_INTRO_CONTEXT`)
    const card = F.isStar;
    main = `<div class="wz-intro"><p class="wz-eyebrow">สมัคร ${esc(c.title)}</p>${card ? `<h1>แบรนด์ขอข้อมูลเพิ่ม</h1><p class="lead">ใช้คัดเลือกผู้สมัคร · ส่งครบแล้วค่อยไปฟอร์มสมัคร</p>`
      : `<h1 class="glass-title">สมัครเป็น ${starMark(30)} ก่อน</h1><p class="lead">${starText('งานนี้รับเฉพาะ STAR · ทำครั้งเดียว ใช้ได้ทุกงาน', 12)}</p>`}
      </div>`;
  } else {
    // ป้ายข้อเหนือคำถาม = ลำดับ + บริบทของงาน (เดิมอยู่หัวแผง)
    const eyebrow = `<p class="wz-eyebrow" aria-live="polite">${total > 1 ? `ข้อ ${n} จาก ${total} · ` : ''}${starText(wizContext(), 9)}</p>`;
    // ไม่มีไอคอนเหนือหัวข้อแล้ว — กินที่จนต้องเลื่อนทุกข้อ (ผู้ใช้ 7 ต.ค. 2569: "ควรให้เค้ากรอกได้ โดย scroll น้อยที่สุด") · หัวข้อมีอีโมจิอยู่แล้ว เหมือน iOS
    main = `${eyebrow}<h1>${wizHeading(st)}</h1>${wizQuestion(st)}`;
  }
  // การ์ดข้อมูลอยู่เฉพาะหน้า intro (เหมือน iOS) — หน้าคำถามมีแต่คำถาม (ผู้ใช้ 5 ต.ค. 2569: "ไม่อยากให้อยู่หน้าเดียวกัน")
  const aside = st !== 'intro' ? ''
    : `<aside class="wz-side" aria-label="ตัวอย่างข้อมูลที่แบรนด์เห็น"><p class="eyebrow">${ic('eye', 15, 'b')}แบรนด์ใช้ข้อมูลนี้ตอนคัดคน</p>${glassCard({ ghosts: real, verify: false })}</aside>`;
  // โครงการ์ดเต็มจอ (ผู้ใช้ 6 ต.ค. 2569 ส่งตัวอย่าง "โครงประมาณนี้ · เต็มจอ"): พื้นเต็มจอ ไม่มีหน้าเว็บข้างหลัง
  // การ์ดสูงคงที่ · หัว = แถบความคืบหน้าเส้นเดียว + ✕ · ปุ่มติดมุมขวาล่าง (ย้อนกลับ = ตัวหนังสือ · ถัดไป = ปุ่มทึบ) · เนื้อหายาวเลื่อนในการ์ด
  // กระดาษซ้อนข้างหลัง = ข้อที่ยังเหลือหลังข้อนี้ (เห็นสูงสุด 2 แผ่น) — หมดสำรับ = ข้อสุดท้าย
  const sheets = Math.min(2, Math.max(0, total - n));
  const pct = st === 'intro' ? 0 : n / total;
  const back = st !== 'intro' && w.i > 0 && w.steps[w.i - 1] !== 'intro';
  const foot = st === 'intro' ? `<button class="btn dark lg" data-act="wizNext" autofocus>${F.isStar ? `เติมข้อมูล · ${total} ข้อ` : `${starText(`สมัครเป็น STAR · ${total} ข้อ`, 13)}`} ${ic('arrowRight', 18, 'b')}</button>`
    : `${back ? `<button class="btn text" data-act="wizBack">ย้อนกลับ</button>` : ''}<button class="btn dark lg" data-act="wizNext">${wizButton()} ${ic('arrowRight', 18, 'b')}</button>`;
  // จอมือถือ (≤640) = หัวของ StarWizard บน iOS: ปุ่มกลมซ้าย (✕ ข้อแรก · ‹ ข้อถัดไป) · ชื่อเทากลาง · n/N + ✕ ขวา — ซ่อนบน desktop
  const ctxM = st === 'intro' ? `สมัคร ${esc(c.title)}` : starText(wizContext(), 9);
  const mTop = `<div class="wzm-top"><button class="wzm-btn" data-act="${w.i > 0 ? 'wizBack' : 'wizExit'}" aria-label="${w.i > 0 ? 'ย้อนกลับ' : 'ปิด'}">${ic(w.i > 0 ? 'caretLeft' : 'x', 16, 'b')}</button>
    <span class="wzm-ctx">${ctxM}</span><span class="wzm-r">${st !== 'intro' && total > 1 ? `<b>${n}/${total}</b>` : ''}${w.i > 0 ? `<button class="wzm-btn" data-act="wizExit" aria-label="ปิด">${ic('x', 16, 'b')}</button>` : ''}</span></div>`;
  // ตรา ST★R Profile มุมซ้ายบนของพื้น (เหมือนโลโก้ของฟอร์ม) + ตราจาง ๆ มุมล่างของการ์ด
  return `<div class="wzstage" role="dialog" aria-modal="true" aria-labelledby="wz-h"><span class="wz-brand" aria-hidden="true">${starMark(22)}<em>Profile</em></span><div class="wzdeck" data-sheets="${sheets}">${sheets > 1 ? '<i class="sheet s2"></i>' : ''}${sheets > 0 ? '<i class="sheet s1"></i>' : ''}
    <section class="wzcard ${st === 'intro' ? 'is-intro' : ''}">
      <header class="wzcard-h">${mTop}<span class="wzbar" role="progressbar" aria-label="ความคืบหน้า" aria-valuemin="0" aria-valuemax="${total}" aria-valuenow="${st === 'intro' ? 0 : n}"><i style="width:${(pct * 100).toFixed(1)}%"></i></span>
        <button class="x" data-act="wizExit" aria-label="ออกจากการกรอกข้อมูล">${ic('x', 16, 'b')}</button></header>
      <div class="wzcard-b shell-b" data-keep="shell" id="wz-h-wrap"><div class="wz ${aside ? '' : 'solo'}"><section class="wz-q" aria-label="คำถาม" id="wz-h">${main}</section>${aside}</div></div>
      <footer class="wzcard-f"><span class="wz-stamp" aria-hidden="true">${starMark(18)}</span>${foot}${STEP_OPTIONAL.includes(st) ? `<button class="wzm-skip" data-act="wizSkip">ข้ามไว้ก่อน</button>` : ''}</footer></section></div></div>`;
}
// แก้ข้อเดียวจาก Star Profile — dialog ทับหน้าเดิม ไม่พาออกจากหน้า
function wizardModal() {
  const st = UI.wiz.steps[0];
  wizOnShow(st);
  return modal(wizHeading(st), wizQuestion(st), { cls: st === 'socials' || st === 'media' || st === 'bank' || st === 'province' ? 'wide' : '', close: 'wizExit',
    // ติดด่านยืนยันตัวตน = ไม่มีอะไรให้ทำต่อ เหลือปุ่มปิดปุ่มเดียว
    foot: st === 'kyc' && !F.isVerified ? `<button class="btn dark" data-act="wizExit">ปิด</button>` : `<button class="btn quiet" data-act="wizExit">ปิด</button><button class="btn dark" data-act="wizNext">${wizButton()}</button>` });
}

// ---------- ช่องกรอกของแต่ละขั้น ----------
function wizControl(st) {
  const s = F.s, w = UI.wiz;
  switch (st) {
    case 'kind': return `<div class="picks two-up" role="radiogroup" aria-label="ประเภทครีเอเตอร์">${[['creator', 'user', 'Creator (บุคคล)', 'ตัวคุณเองเป็นคนสร้างคอนเทนต์'], ['page', 'browsers', 'Page (เพจ)', 'บริหารเพจ/สื่อในนามทีมหรือแบรนด์']]
      .map(([k, icn, t, sub]) => `<label class="pick tall ${s.creatorKind === k ? 'on' : ''}"><input type="radio" name="kind" ${s.creatorKind === k ? 'checked' : ''} data-act="setKind" data-arg="${k}"><i class="red">${ic(icn, 22)}</i><span><b>${t}</b><small>${sub}</small></span></label>`).join('')}</div>`;
    case 'socials': return channelsControl(w.asked.includes('socials'));
    case 'categories': return `<p class="count-line cat" aria-live="polite">เลือกแล้ว ${s.categories.length}/5</p><div class="chips" role="group" aria-label="สายที่ใช่">${CATEGORIES.map(c => chip(c, s.categories.includes(c), 'toggleCat', !s.categories.includes(c) && s.categories.length >= 5)).join('')}</div>`;
    case 'media': return `<div class="sec"><label class="sec-h" for="about"><b>แนะนำตัว</b><i class="opt-tag">ไม่บังคับ</i></label>
        <span class="fld ${wizErr('s.about') != null ? 'bad' : ''}"><textarea id="about" rows="3" data-bind="s.about" placeholder="เช่น ชอบพาไปเที่ยว ทานอาหารอร่อยๆ แวะจิบกาแฟที่คาเฟ่น่ารักๆ">${esc(s.about)}</textarea>${ferr(wizErr('s.about'))}</span></div>${mediaControl()}`;
    // UI เดียวกับหน้าสถานะ: ตีกลับ = ปุ่ม "ส่งยืนยันตัวตนใหม่" (ถาม Lab ก่อน) · รอตรวจ = ยกเลิกคำขอ (แตะ 2 ครั้ง) + ลิงก์ Lab (salehere-ios Dev/SIT)
    case 'kyc': return F.kycBlocked ? `<div class="wz-kyc">${kycHero()}${F.s.verify === 'rejected' ? `<button class="btn dark wide" data-act="wizKyc">ส่งยืนยันตัวตนใหม่</button>`
        : `<button class="btn text wide ${UI.cancelAsk ? 'danger' : ''}" data-act="kycCancel">${UI.cancelAsk ? 'แตะอีกครั้งเพื่อยกเลิกคำขอ · ต้องถ่ายใหม่ทั้งหมด' : 'ยกเลิกคำขอยืนยันตัวตน'}</button>
          ${HIDE_LAB ? '' : `<button class="link mute u wide" data-act="wizKyc">Lab · เลือกผลยืนยันตัวตน</button>`}`}</div>`
      : F.isVerified ? `<div class="pick on static"><i class="dark">${ic('check', 16, 'b')}</i><span><b>Verified by Sale Here</b><small>ขึ้นป้ายบนการ์ดแล้ว</small></span></div>`
      : getAppBox(true);
    case 'province': return provinceControl();
    case 'availability': return availabilityControl();
    case 'contact': return `<div class="stack-f">${field('LINE ID', 's.lineID', { ph: '@yourlineid' })}${field('เบอร์โทร', 's.phone', { ph: '08x-xxx-xxxx', mode: 'tel', max: 10, digits: 1, auto: 'tel' })}${field('เว็บไซต์ · ไม่บังคับ', 's.website', { ph: 'yourname.com', mode: 'url' })}</div>`;
    case 'address': return addressFields();
    case 'bank': return bankControl();
    case 'body': return bodyControl();
  }
  return '';
}
// สัดส่วน = หน้า "สัดส่วน" ของ salehere-ios ตัวต่อตัว: 6 ช่อง 2 คอลัมน์ · แต่ละช่องมีหน่วยของตัวเอง — รอบอก/เอว/สะโพก เลือก นิ้ว/ซม. ด้วย select ท้ายช่อง (เว็บ = control มาตรฐานแทน wheel ของมือถือ) · "วิธีการวัดขนาด" กางภาพเดียวกับแอปหลัก
function bodyControl() {
  const b = F.s.bodyInfo;
  const unitSel = k => `<select class="unit-sel" data-bind="s.bodyInfo.${k}" data-live="1" aria-label="หน่วย">${['นิ้ว', 'ซม.'].map(x => `<option ${b[k] === x ? 'selected' : ''}>${x}</option>`).join('')}</select>`;
  return `<div class="grid2">${field('น้ำหนัก', 's.bodyInfo.weight', { ph: '50', unit: 'กก.', mode: 'numeric', digits: 1, max: 3 })}${field('ส่วนสูง', 's.bodyInfo.height', { ph: '165', unit: 'ซม.', mode: 'numeric', digits: 1, max: 3 })}
    ${field('รอบอก', 's.bodyInfo.chest', { ph: '32', unit: unitSel('chestUnit'), mode: 'numeric', digits: 1, max: 3 })}${field('รอบเอว', 's.bodyInfo.waist', { ph: '25', unit: unitSel('waistUnit'), mode: 'numeric', digits: 1, max: 3 })}
    ${field('สะโพก', 's.bodyInfo.hip', { ph: '35', unit: unitSel('hipUnit'), mode: 'numeric', digits: 1, max: 3 })}${field('ขนาดรองเท้า', 's.bodyInfo.shoe', { ph: '38', unit: 'EU', mode: 'decimal', max: 4 })}</div>
    <button type="button" class="link guide-link" data-act="bodyGuide" aria-expanded="${!!UI.bodyGuide}">วิธีการวัดขนาด ${ic('info', 15, 'b')}</button>
    ${UI.bodyGuide ? `<figure class="body-guide"><img src="assets/body-info.png" alt="ภาพประกอบวิธีวัดรอบอก รอบเอว สะโพก"></figure>` : ''}`;
}
// ชิปเลือกหลายข้อ = มีกล่องติ๊กให้เห็น (ชิปเปล่าอ่านเป็นเลือกได้ข้อเดียว)
const chip = (t, on, act, off) => `<button class="chip ${on ? 'on' : ''}" role="checkbox" aria-checked="${on}" ${off ? 'aria-disabled="true"' : ''} data-act="${act}" data-arg="${esc(t)}"><i class="box">${on ? ic('check', 11, 'b') : ''}</i>${esc(t)}</button>`;

function channelsControl(connectable) {
  return `<ul class="chans">${SOCIALS.map(x => {
    const on = F.s.connected.includes(x.id);
    if (!on) return connectable ? `<li><button class="chan off" data-act="editChannel" data-arg="${x.id}">${soc(x.id, 32)}<b>${x.name}</b><span class="chan-add">${ic('plus', 13, 'b')}เชื่อม</span></button></li>` : '';
    const n = F.insightCount(x.id), sum = x.formats.slice(0, 2).map(f => `${FORMATS[f][0]} ฿${F.rate(x.id, f).toLocaleString('en-US')}`).join(' · ');
    const badge = n === 3 ? `<i class="ibadge ok">${ic('check', 11, 'b')}</i>` : `<i class="ibadge ${n ? 'part' : ''}">${n}/3</i>`;
    // บน = ยอด + เรท + ยกเลิกผูกบัญชี (แทนปุ่มแก้) · ล่าง = ปรับราคา (ผู้ใช้ 8 ต.ค. 2569) · ก่อนเป็น STAR ต้องเหลืออย่างน้อย 1 ช่อง — salehere-ios
    const canRemove = F.s.connected.length > 1 || F.keepsData;
    return `<li class="chan on"><div class="chan-head"><button class="chan-top" data-act="editChannel" data-arg="${x.id}" aria-label="ปรับราคา ${x.name}">${soc(x.id, 36)}<span><b>${x.name} · ${F.fmt(F.followers(x.id))}</b><small>${sum}</small></span></button>${canRemove ? `<button class="chan-rm" data-act="askRemoveChannel" data-arg="${x.id}">ยกเลิกผูกบัญชี</button>` : ''}</div>
      <div class="chan-foot"><button class="chan-price" data-act="editChannel" data-arg="${x.id}">ปรับราคา</button></div>
      ${x.insight ? `<button class="chan-ins" data-act="openInsightPanel" data-arg="${x.id}"><span><b>ข้อมูลผู้ติดตาม ${badge}</b><small class="${n > 0 && n < 3 ? 'warn' : ''}">${n === 3 ? 'ครบ 3 หัวข้อแล้ว' : 'ไม่บังคับ · แบรนด์เห็นกลุ่มคนดูของคุณ'}</small></span><span class="mini-pill">${n === 3 ? 'อัปเดต' : n > 0 ? 'แนบต่อ' : '+ เพิ่ม'}</span></button>` : ''}</li>`;
  }).join('')}</ul>`;
}
function mediaControl() {
  // โชว์ครบ 3 หมวดเสมอ — หมวดที่ครบมีติ๊กเขียว ห้ามซ่อน (salehere-ios STAR-FLOW-RULES ข้อ 4)
  const m = F.s.media, shown = ['photos', 'works', 'videos'], del = UI.wiz.del;
  // error ของหมวด = ใต้หมวดนั้นเอง · หายเองเมื่อใส่ครบ (เช็คสดทุกครั้งที่วาด)
  const lack = F.mediaLack(), bad = kind => wizErr('media:' + kind) != null && lack[kind];
  const errLine = kind => bad(kind) ? ferr('ยังขาด ' + lack[kind]) : '';
  const head = (t, have, min, note) => `<div class="sec-h"><b>${t}</b>${note ? `<small>${note}</small>` : ''}<span class="grow"></span>${have >= min ? `<i class="okc" title="ครบแล้ว">${ic('checkCircle', 18, 'f')}</i>` : `<i class="n">${have}/${min}</i>`}</div>`;
  // เป็น STAR แล้ว = ลบไม่ได้ ปุ่มมุมกลายเป็น "เปลี่ยน" (เลือกไฟล์ใหม่มาแทนที่ช่องเดิม)
  const keep = F.keepsData, what = kind => kind === 'videos' ? 'คลิป' : 'รูป';
  const tile = (kind, src, id, dur) => `<li class="tile-m"><img src="${src}" alt="${kind === 'videos' ? 'คลิปผลงาน' : 'รูป'}">${dur ? `<i class="dur">${ic('play', 10, 'f')}${dur}</i>` : ''}
    ${keep ? `<button class="rm swap" data-act="swapMedia" data-arg="${kind}|${id}" aria-label="เปลี่ยน${what(kind)}นี้" title="เปลี่ยน${what(kind)}">${ic('arrowsClockwise', 13, 'b')}</button>`
      : `<button class="rm ${del === kind + id ? 'ask' : ''}" data-act="rmMedia" data-arg="${kind}|${id}" aria-label="${del === kind + id ? 'กดอีกครั้งเพื่อลบ' : 'ลบ'}">${del === kind + id ? 'ลบ?' : ic('x', 12, 'b')}</button>`}</li>`;
  const imp = UI.wiz.importing || {}, pend = kind => Array.from({ length: imp[kind] || 0 }, () => `<li class="tile-m pending" role="status" aria-label="กำลังโหลดไฟล์"><i class="spin sm"></i></li>`).join('');
  const add = (kind, label) => `<li><button class="add-tile" data-act="addMedia" data-arg="${kind}" data-drop="media:${kind}">${ic(kind === 'videos' ? 'videoCamera' : 'plus', 20)}<span>${label}</span></button></li>`;
  let h = '';
  // รูปของคุณ: แตะช่อง = เลือกรูปใหม่มาแทน · ไม่มีปุ่มมุม (salehere-ios)
  const photoTile = (src, i) => `<li class="tile-m"><button class="tile-swap" data-act="swapMedia" data-arg="photos|${i}" aria-label="เปลี่ยนรูปที่ ${i + 1}"><img src="${src}" alt="รูปที่ ${i + 1}"></button></li>`;
  if (shown.includes('photos')) h += `<div class="sec ${bad('photos') ? 'bad' : ''}" data-drop="media:photos">${head('รูปของคุณ', m.photos.filter(Boolean).length, MIN.photos, `${MIN.photos}–${MAX.photos} รูป`)}<ul class="mgrid">${(() => { let left = imp.photos || 0; return m.photos.map((p, i) => p ? photoTile(p, i) : left-- > 0 ? `<li class="tile-m pending" role="status" aria-label="กำลังโหลดไฟล์"><i class="spin sm"></i></li>` : add('photos', `รูปที่ ${i + 1}`)).join(''); })()}</ul>${errLine('photos')}</div>`;
  if (shown.includes('works')) h += `<div class="sec ${bad('works') ? 'bad' : ''}" data-drop="media:works">${head('รูปผลงาน', m.works.length, MIN.works, `${MIN.works}–${MAX.works} รูป`)}<ul class="mgrid">${m.works.map(x => tile('works', x.src, x.id)).join('')}${pend('works')}${m.works.length + (imp.works || 0) < MAX.works ? add('works', 'เพิ่มรูป') : ''}</ul>${errLine('works')}</div>`;
  if (shown.includes('videos')) h += `<div class="sec ${bad('videos') ? 'bad' : ''}" data-drop="media:videos">${head('วิดีโอผลงาน', m.videos.length, MIN.videos, `${MIN.videos}–${MAX.videos} คลิป`)}<ul class="mgrid">${m.videos.map(x => tile('videos', x.src, x.id, x.dur)).join('')}${pend('videos')}${m.videos.length + (imp.videos || 0) < MAX.videos ? add('videos', 'เพิ่มคลิป') : ''}</ul>${errLine('videos')}</div>`;
  // ขนาดไฟล์วิดีโอย้ายมาบรรทัดนี้ — หัวหมวดสั้นพอให้ 3 หมวดเรียงแถวเดียวบนจอกว้าง (7 ต.ค. 2569)
  return h + `<p class="drop-hint">${ic('uploadSimple', 15, 'b')}ลากไฟล์มาวางในแต่ละหมวดได้เลย${shown.includes('videos') ? ` · วิดีโอไฟล์ละไม่เกิน ${VIDEO_MAX_MB} MB` : ''}${keep ? ' · เป็น STAR แล้ว เปลี่ยนได้ ลบไม่ได้' : ''}</p>`;
}
// จังหวัด = หน้า CreatorProfileAvailabilityProvince ของ salehere-ios: ค้นหา · "เลือกแล้ว N จังหวัด" · ชิป ⊕/✓แดง รายการเดียว ไม่มียอดนิยม (ผู้ใช้ 6 ต.ค. 2569)
function provinceControl() {
  const s = F.s, q = UI.provinceQ.trim().toLowerCase(), hit = p => !q || (p + ' ' + (PROVINCE_ALIAS[p] || '')).toLowerCase().includes(q);
  const found = PROVINCES.filter(hit), full = s.provinces.length >= 3;
  const pchip = p => { const on = s.provinces.includes(p), off = !on && full;
    return `<button class="pchip ${on ? 'on' : off ? 'off' : ''}" role="checkbox" aria-checked="${on}" ${off ? 'aria-disabled="true"' : ''} data-act="toggleProv" data-arg="${esc(p)}">${ic(on ? 'checkCircle' : 'plusCircle', 20, on ? 'f' : 'r')}${esc(p)}</button>`; };
  return `<label class="search"><span class="sr">ค้นหาจังหวัด</span>${ic('magnifyingGlass', 18, 'b')}<input type="search" data-bind="ui.provinceQ" data-live="1" value="${esc(UI.provinceQ)}" placeholder="ค้นหาจังหวัด"></label>
    <p class="count-line" aria-live="polite">เลือกแล้ว ${s.provinces.length} จังหวัด</p>
    ${found.length ? `<div class="chips prov-all" data-keep="prov">${found.map(pchip).join('')}</div>` : `<p class="none-found">ไม่พบข้อมูลการค้นหา "${esc(UI.provinceQ)}"</p>`}`;
}
// วันว่าง = WzAvailability ของ iOS ทุกขนาดจอ (ผู้ใช้ 7 ต.ค. 2569: "ต้องเหมือนของ ios ไม่เอา ui นี้" — เลิกตาราง 7×5 บน desktop)
// วงกลม 7 วัน (จุดใต้วง = ช่วงที่เลือกของวันนั้น) → ชิปช่วงเวลาของวันที่เลือก + ตลอดวัน · ข้อมูลชุดเดียวกัน availWeek[วัน] = [ช่วง]
function availabilityControl() {
  const w = F.s.availWeek, day = UI.availDay || 'จ', cur = w[day] || [];
  const chipT = (label, on, arg) => `<button class="wchip ${on ? 'on' : ''}" role="checkbox" aria-checked="${on}" data-act="toggleAvail" data-arg="${day}|${arg}">${label}</button>`;
  return `<div class="days" role="tablist" aria-label="เลือกวัน">${WEEK.map(d => { const have = w[d] || [];
      return `<button role="tab" aria-selected="${d === day}" class="day ${d === day ? 'cur' : have.length ? 'has' : ''}" data-act="availDay" data-arg="${d}" aria-label="${WEEK_FULL[d]}"><b>${d}</b><span>${DAY_SLOTS.map(s => `<i class="${have.includes(s) ? 'on' : ''}"></i>`).join('')}</span></button>`; }).join('')}</div>
    <p class="days-t">ช่วงเวลา · <b>${WEEK_FULL[day]}</b></p>
    <div class="wchips">${DAY_SLOTS.map(t => chipT(SLOT_LABEL[t], cur.includes(t), t)).join('')}${chipT('ตลอดวัน', cur.length === DAY_SLOTS.length, '*')}</div>`;
}
// ไม่มีบรรทัด "ชื่อตรงกับบัตร" และปุ่มถ่ายสมุดบัญชี (salehere-ios ไม่มี — ฟอร์ม payout เดิมขอเอกสารตอนจ่ายจริง)
function bankControl() {
  const s = F.s, co = s.payKind === 'company';
  return `<div class="picks two-up" role="radiogroup" aria-label="รับเงินในนาม">${[['person', 'user', 'นามบุคคล', 'หัก ณ ที่จ่าย 3%'], ['company', 'buildings', 'นามบริษัท', 'หัก ณ ที่จ่าย 7%']]
      .map(([k, icn, t, sub]) => `<label class="pick ${s.payKind === k ? 'on' : ''}"><input type="radio" name="pay" ${s.payKind === k ? 'checked' : ''} data-act="setPay" data-arg="${k}"><i>${ic(icn, 22)}</i><span><b>${t}</b><small>${sub}</small></span></label>`).join('')}</div>
    <p class="note">${co ? 'ชื่อบัญชีต้องตรงกับชื่อนิติบุคคลเป๊ะ ๆ รวมคำว่า "บริษัท" และ "จำกัด"' : 'ชื่อบัญชีต้องตรงกับชื่อ–นามสกุลจริงของคุณ ไม่งั้นเงินจะโอนไม่เข้า'}</p>
    <div class="grid2">${co ? field('ชื่อนิติบุคคล', 's.bankInfo.coName', { ph: 'บริษัท ... จำกัด', cls: 'span2' }) + field('เลขประจำตัวผู้เสียภาษี (13 หลัก)', 's.bankInfo.taxID', { ph: '0xxxxxxxxxxxx', mode: 'numeric', max: 13, digits: 1 })
      + selectField('สำนักงานใหญ่ / สาขา', 's.bankInfo.branch', ['สำนักงานใหญ่', 'สาขา']) + field('ที่อยู่ตามหนังสือรับรอง', 's.bankInfo.address', { ph: 'เลขที่ ถนน แขวง เขต จังหวัด รหัสไปรษณีย์', cls: 'span2' })
      + selectField('จดทะเบียน VAT หรือไม่', 's.bankInfo.vat', ['จดทะเบียน VAT', 'ไม่ได้จดทะเบียน VAT']) : ''}
      ${selectField('ธนาคาร', 's.bankInfo.bank', BANKS, 'เลือกธนาคาร')}${field('เลขที่บัญชี', 's.bankInfo.no', { ph: 'xxxxxxxxxx', mode: 'numeric', max: 15, digits: 1 })}${field('ชื่อบัญชี', 's.bankInfo.name', { ph: co ? 'ตามชื่อนิติบุคคล' : 'ตามหน้าสมุดบัญชี', cls: 'span2' })}</div>
    <p class="note sm">${co ? 'ขอทีหลัง: หนังสือรับรองบริษัท (ไม่เกิน 6 เดือน) · ภ.พ.20 ถ้าจด VAT' : 'ขอทีหลัง: สำเนาบัตรประชาชน เซ็นรับรองสำเนาถูกต้อง'}</p>`;
}

// ---------- dialog ของหน้าช่องทาง: เชื่อม/แก้ช่อง · ข้อมูลผู้ติดตาม ----------
function modalView() {
  const m = UI.modal;
  if (m.type === 'channel') return channelModal(m);
  if (m.type === 'insight') return insightModal(m);
  if (m.type === 'addJob') return addJobModal(m);
  return '';
}
function channelDeviation(v, reco) {
  if (!(reco > 0 && v > 0)) return ''; const d = (v - reco) / reco; if (Math.abs(d) <= 0.3) return '';
  return d < 0 ? `ต่ำกว่าเรทแนะนำ ${Math.round(-d * 100)}% · แบรนด์อาจมองว่างานไม่เต็มที่` : `สูงกว่าเรทแนะนำ ${Math.round(d * 100)}% · อาจถูกเลือกน้อยลง`;
}
function channelModal(m) {
  const x = SOC[m.id], chk = F.checkLink(m.id, m.link), showErr = !chk.ok && chk.msg && m.touched;
  let body = `<label class="fld"><span>ลิงก์โปรไฟล์</span><span class="in ${showErr ? 'bad' : ''}"><input type="url" autofocus data-bind="ui.modal.link" data-live="1" data-touch="1" value="${esc(m.link)}" placeholder="${x.ph}" ${showErr ? 'aria-invalid="true" aria-describedby="ch-err"' : ''}>
      ${chk.ok ? `<i class="okc">${ic('check', 16, 'b')}</i>` : `<button class="mini-pill" data-act="pasteLink">วาง</button>`}</span></label>${showErr ? `<p id="ch-err" class="err">${esc(chk.msg)}</p>` : ''}`;
  if (chk.ok) body += `<label class="fld"><span>ยอดผู้ติดตาม</span><span class="in"><input inputmode="numeric" data-bind="ui.modal.followers" data-live="1" data-digits="1" value="${m.followers || ''}" placeholder="เช่น 24800"></span></label>
      ${m.followers > 0 ? `<p class="note sm">${ic('info', 13)}กรอกเอง — ทีมงานตรวจสอบก่อนขึ้นการ์ด</p>` : ''}`;
  if (chk.ok && m.followers > 0) body += `<h3 class="h-xs">เรทต่อโพสต์</h3><ul class="rates">${x.formats.map(f => { const reco = F.suggest(m.followers, f), v = m.rates[f] != null ? m.rates[f] : reco, warn = channelDeviation(v, reco);
      return `<li><label for="rate-${f}"><b>${FORMATS[f][0]}</b><small>แนะนำ ฿${reco.toLocaleString('en-US')}</small></label><span class="in has-unit money"><u>฿</u><input id="rate-${f}" inputmode="numeric" data-bind="ui.modal.rates.${f}" data-digits="1" data-live="change" value="${v}"><i>/โพสต์</i></span>${warn ? `<p class="warn">${warn}</p>` : ''}</li>`; }).join('')}</ul>
      <div class="split"><button class="link" data-act="resetRates">${ic('arrowsClockwise', 14, 'b')}ใช้เรทแนะนำ</button></div>`;
  if (m.err) body += `<p class="err" role="alert">${esc(m.err)}</p>`;
  return modal(`${soc(m.id, 28)} ${m.isNew ? 'เชื่อม ' + x.name : x.name}`, body, { foot: `<button class="btn quiet" data-act="closeModal">ยกเลิก</button><button class="btn dark" data-act="saveChannel">${m.isNew ? 'เชื่อมช่องนี้' : 'บันทึก'}</button>` });
}
// รูปแคปหน้า Insights อยู่ในมือถือ — ลากไฟล์มาวาง หรือส่งจากมือถือด้วย QR · ตัวเลขอ่านจากรูป (ของจริง = analyzeSocialProfileInsight)
function insightModal(m) {
  const id = m.id, n = F.insightCount(id), s = F.s;
  const slot = x => {
    const k = id + '_' + x.key, saved = s.insightValues[k] || [], has = saved.length > 0, busy = m.reading.includes(k), open = m.editing === k, top = has && saved.slice().sort((a, b) => b[1] - a[1])[0];
    const txt = busy ? `<small>กำลังอ่านตัวเลขจากรูป…</small>` : has ? `<strong>${esc(top[0])} <em>${top[1]}%</em></strong><small>${saved.filter(v => v !== top).map(v => `${esc(v[0])} ${v[1]}%`).join(' · ')}</small>`
      : m.failed[k] ? `<small class="err">${esc(m.failed[k])}</small>` : `<small>แคปหน้า "${x.title}" จาก ${INSIGHT_APP(id)} แล้วลากมาวาง หรือกดเพื่อเลือกไฟล์</small>`;
    return `<li class="islot ${has ? 'has' : ''} ${open ? 'open' : ''}"><button class="islot-b" data-act="insightUpload" data-arg="${x.key}" data-drop="insight:${x.key}" ${busy ? 'disabled' : ''}>
        <span><i class="tagc">${ic(x.icon, 14)}${x.title}</i>${txt}</span><span class="shot ${has ? 'ok' : ''}">${busy ? '<i class="spin sm"></i>' : has ? ic('check', 16, 'b') : ic('uploadSimple', 20)}</span></button>
      ${has && !busy ? `<button class="link mute edit" data-act="insightEdit" data-arg="${x.key}">${open ? 'ปิด' : 'แก้ตัวเลข'}</button>` : ''}
      ${open ? `<div class="iedit">${m.draft.map((v, i) => `<div class="irow">${x.key === 'location' ? `<label class="fld"><span>เมือง/จังหวัด อันดับ ${i + 1}</span><span class="in"><input data-bind="ui.modal.draft.${i}.0" value="${esc(v[0])}" placeholder="เช่น กรุงเทพ"></span></label>` : `<b>${esc(v[0])}</b>`}
        <label class="fld pct"><span class="${x.key === 'location' ? '' : 'sr'}">% ${esc(v[0])}</span><span class="in has-unit"><input inputmode="numeric" data-digits="1" data-bind="ui.modal.draft.${i}.1" value="${v[1] || ''}" placeholder="0"><i>%</i></span></label></div>`).join('')}
        ${m.err ? `<p class="err" role="alert">${esc(m.err)}</p>` : ''}<button class="btn dark sm" data-act="insightSave" data-arg="${x.key}">บันทึก</button></div>` : ''}</li>`;
  };
  return modal(`${soc(id, 28)} ข้อมูลผู้ติดตาม <i class="ibadge ${n === 3 ? 'ok' : n ? 'part' : ''}">${n === 3 ? ic('check', 11, 'b') : n + '/3'}</i>`,
    `<div class="ins-2"><div><ol class="howto"><li><a href="${INSIGHT_WEB[id]}" target="_blank" rel="noopener">เปิดแอป ${INSIGHT_APP(id)} ${ic('arrowUpRight', 13, 'b')}</a></li><li>${INSIGHT_PATH[id]}</li><li>แคปหน้าจอแต่ละหัวข้อ แล้วอัปโหลดที่นี่</li></ol>
      ${qrBox('แล้วเลือกรูปแคป 3 รูป', ['insightPhone'])}</div><ul class="islots">${INSIGHT_SLOTS.map(slot).join('')}</ul></div>`,
    { cls: 'wide', foot: `<button class="btn dark" data-act="closeModal">${n === 3 ? 'เสร็จ' : 'ไว้ทำต่อทีหลัง'}</button>` });
}
