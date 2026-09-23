// flow ใหม่ — ไม่แก้หน้าเดิมของ Unbox เลย แค่ "แทรกหน้ากรอกข้อมูล Star Profile" ก่อนถึงหน้าเดิม
// หน้าแทรกใช้ภาษา UI ของ StarCard iOS (ProfileKit) และออกแบบให้ผู้ใช้รู้ตลอดว่า "ยังอยู่ในงานเดิม":
//   breadcrumb งานที่กำลังทำ · stepper ระดับ journey (ข้อมูลของคุณ → ฟอร์มสมัคร → ส่ง) · ปุ่มบอกปลายทาง · ช่องที่ขาดขึ้นก่อน ช่องที่มีพับไว้ท้าย
// ทุกช่องดู `s.profile.*`: มี = พับ "มีแล้ว" · ไม่มี = กาง ให้กรอกตรงนั้น · กรอกแล้วกลายเป็น "มี" งานถัดไปเติมให้เอง

(function () {
  const D = window.UNBOX, U = window.UI, I = window.icon, A = U.A, S = window.SCREENS, Ac = window.ACTIONS;
  const cur = s => D.CAMPAIGNS.find(c => c.slug === s.campaignSlug) || D.CAMPAIGNS[0];
  const isVerified = s => s.user.verify === 'approved';
  const P = s => s.profile;
  // การ์ดเกิดจากสิ่งที่มีอยู่แล้ว (ช่องโซเชียล + สายที่ใช่) · "STAR" เต็มตัว = การ์ด + ยืนยันตัวตนผ่าน
  const hasCard = s => P(s).socials && P(s).categories;
  const isStar = s => hasCard(s) && isVerified(s);
  // ตัวเลขการแข่งขันของงานนี้ — ใช้เฉพาะสิ่งที่ระบบมีจริง: สิทธิ์ · คนสมัครแล้ว · ผู้สมัครล่าสุดที่เป็น STAR แล้ว
  const rival = s => { const c = cur(s), apps = (c.applications || []).filter(a => !a.me), stars = apps.filter(a => a.star).length; return { quota: c.quota, n: c.registered, ratio: Math.max(1, Math.round(c.registered / c.quota)), stars, apps: apps.length }; };

  window.hasStarCard = hasCard; // ไม่มี "ระดับ" — มีการ์ด = เป็น STAR แล้ว แค่นั้น

  // ---------- PK components ----------
  const pkHeader = (title, { go = 'campaign', sub = '' } = {}) => `<div class="pk-head"><button class="pk-circle" data-go="${go}">${I('x', 18, 'bold')}</button><div><div class="t">${title}</div>${sub ? `<span class="sub">${sub}</span>` : ''}</div><span></span></div>`;
  /// breadcrumb งานที่กำลังทำ — ปกกิจกรรม + "กำลังสมัคร EP.xxxx" ให้รู้ว่าหน้านี้เป็นส่วนหนึ่งของงานเดิม
  const pkCrumb = (c, verb) => `<div class="pk-crumb"><img src="${c.cover}"><div><small>${verb}</small><b>${c.ep} ${c.brand}</b></div></div>`;
  /// stepper ระดับ journey (ไม่ใช่ระดับช่อง): บอกว่าหน้านี้คือขั้นไหน และหน้าถัดไปคืออะไร
  const pkSteps = (items, here) => `<div class="pk-steps">${items.map((t, i) => `<div class="pk-step ${i < here ? 'done' : i === here ? 'here' : ''}"><i>${i < here ? '✓' : i + 1}</i><span>${t}</span></div>${i < items.length - 1 ? '<em></em>' : ''}`).join('')}</div>`;
  const pkPanel = (title, subtitle, body, n = null) => `<div class="pk-panel">${n ? `<span class="pk-n">${n}</span>` : ''}<div class="ph-t"><div><b>${title}</b>${subtitle ? `<span>${subtitle}</span>` : ''}</div></div>${body}</div>`;
  const pkDone = (title, value, editAct = null) => `<div class="pk-panel done"><div class="ph-t"><span class="pk-ok">${I('check-circle', 20, 'fill')}</span><div><b>${title}</b><span class="pk-val">${value}</span></div>${editAct ? `<a class="pk-edit" data-do="${editAct}">แก้ไข</a>` : ''}</div></div>`;
  const pkField = ({ label = '', value = '', placeholder = '', bind = null, type = 'text', multiline = false, lead = '', tail = '', req = false, sel = false, hint = '' }) => `<div class="pk-fld">${label ? `<div class="pk-lb">${label}${req ? '<em>*</em>' : ''}</div>` : ''}<div class="pk-in ${sel ? 'sel' : ''}">${lead ? `<span class="lead">${lead}</span>` : ''}${multiline ? `<textarea ${bind ? `data-bind="${bind}"` : ''} placeholder="${placeholder}">${value}</textarea>` : `<input type="${type}" value="${value}" ${bind ? `data-bind="${bind}"` : ''} placeholder="${placeholder}">`}${tail ? `<span class="tail">${tail}</span>` : ''}</div>${hint ? `<div class="pk-hint">${hint}</div>` : ''}</div>`;
  const pkChips = (opts, on, act = 'pkToggle') => `<div class="pk-chips">${opts.map(o => `<span class="pk-chip ${on.includes(o) ? 'on' : ''}" data-do="${act}">${o}</span>`).join('')}</div>`;
  const pkBtn = (title, { act = null, go = null, enabled = true, sec = false, icon = 'arrow-right' } = {}) => `<button class="pk-btn ${sec ? 'sec' : ''}" ${act ? `data-do="${act}"` : ''} ${go ? `data-go="${go}"` : ''} ${enabled ? '' : 'disabled'}><span>${title}</span>${icon ? I(icon, 18, 'bold') : ''}</button>`;
  const pkCheck = (id, bind, on, label, sub, err) => `<label class="pk-check ${on ? 'on' : ''} ${err ? 'err' : ''}" id="${id}"><input type="checkbox" data-bind="${bind}" ${on ? 'checked' : ''} hidden><i>✓</i><div><b>${label}</b>${sub ? `<span>${sub}</span>` : ''}${err ? `<span class="pk-err">${err}</span>` : ''}</div></label>`;
  Ac.pkToggle = (d, b) => b.classList.toggle('on');

  // ---------- StarCard (ใบจริงประกอบจากโปรไฟล์ · อัปเดตตามที่กรอก) ----------
  window.cardView = function (s, { newWork = false, compact = false } = {}) {
    const p = P(s);
    const socs = D.USER.socials.filter(x => x.connected);
    const works = newWork ? [cur(s).cover, 'assets/ph01.jpg', 'assets/ph04.jpg'] : (s.review === 'reviewed' ? ['assets/ph01.jpg', 'assets/ph04.jpg'] : []);
    return `<div class="sc-card">
      ${isStar(s) ? `<span class="sc-level">★ STAR</span>` : ''}
      <div class="sc-top"><img class="sc-ava" src="${D.USER.avatar}"><div><div class="sc-name">${D.USER.name}${isVerified(s) ? `<span class="sc-verified">${I('seal-check', 11, 'fill')} Verified</span>` : ''}</div><div class="sc-handle">@${D.USER.username.toLowerCase()} · ${p.categories ? D.USER.categories.join(' · ') : '<i style="opacity:.6">สายที่ใช่จะขึ้นตรงนี้</i>'}</div></div></div>
      ${socs.length && p.socials ? `<div class="sc-socials">${socs.map(so => `<span class="sc-soc">${U.socialIcon(so.type, 20)}${U.fmtNum(so.followers)}</span>`).join('')}</div>` : `<div class="sc-empty">ยอดผู้ติดตามจะขึ้นตรงนี้เมื่อผูกโซเชียล</div>`}
      ${!compact && p.about ? `<div class="sc-about">ชอบพาไปเที่ยว ทานอาหารอร่อยๆ แวะจิบกาแฟที่ร้านคาเฟ่น่ารักๆ</div>` : ''}
      ${!compact && works.length ? `<div class="sc-works">${works.map((w, i) => `<span class="${newWork && i === 0 ? 'new' : ''}"><img src="${w}"></span>`).join('')}</div>` : ''}
      <div class="sc-foot"><span>ทำงานผ่าน Sale Here <b>${(newWork || s.review === 'reviewed') ? 1 : 0} งาน</b></span>${p.rate ? `<span>เรทเริ่ม <b>฿1,500</b>/โพสต์</span>` : ''}${isVerified(s) ? `<span><b>ยืนยันตัวตนแล้ว</b></span>` : ''}</div>
    </div>`;
  };

  // ---------- หน้ากิจกรรม (เดิมทั้งหมด) + บรรทัดบอกว่ามี Star Card หรือยัง ใต้นาฬิกา ----------
  const oldCampaign = S.campaign;
  S.campaign = s => {
    let html = oldCampaign(s);
    if (s.flow === 'new' && s.campaign === 'registered' && !s.reviewTab) {
      const left = REVEAL_ROWS.filter(r => ['kyc', 'rate', 'about', 'insight', 'province', 'availability'].includes(r.key) && !rowDone(s, r));
      const rv = rival(s);
      const line = left.length ? `<span>แบรนด์เปิดดูการ์ดคุณได้แล้ว · ยังขาด${left[0].key === 'kyc' ? 'ยืนยันตัวตน' : left[0].t}ที่แบรนด์มักถาม</span><button class="btn btn-xs" data-do="creatorProfile">เติมเลย</button>` : '<span>แบรนด์เปิดดูการ์ดคุณได้แล้ว · มีครบทุกอย่างที่แบรนด์ขอดู</span>';
      // สถานะ registered ใช้ bar-desc (ไม่มีนาฬิกา) → แทรกต่อท้ายบรรทัดนั้น
      return html.replace(/(<div class="bar-desc[^"]*"[^>]*>[\s\S]*?<\/div>)/, `$1<div class="bar-desc ink" style="height:auto;padding:6px 0 4px;font-size:12px;gap:6px"><span class="lvl-chip">${isStar(s) ? '★ STAR' : '⏳ รอยืนยันตัวตน'}</span>${line}</div>`);
    }
    if (s.flow !== 'new' || s.campaign !== 'register' || s.reviewTab) return html;
    const missing = applyMissing(s).length;
    const c = cur(s);
    const rv = rival(s);
    const hint = missing ? `แบรนด์ขอดูการ์ดก่อนคัด · ตอบ ${missing} ข้อที่แบรนด์อยากรู้ แล้วส่งใบสมัครได้เลย` : (isStar(s) ? 'การ์ดคุณมีครบที่แบรนด์ขอดู · ส่งใบสมัครได้เลย' : 'การ์ดพร้อม · แบรนด์ขอให้ยืนยันตัวตนด้วย');
    return html.replace(/(<div class="bar-clock">[\s\S]*?<\/div>)(\s*<button)/, `$1<div class="bar-desc ink" style="height:auto;padding-bottom:4px;font-size:12px;gap:6px"><span class="lvl-chip">${isStar(s) ? '★ STAR แล้ว' : hasCard(s) ? '☆ มีการ์ดแล้ว · ยังไม่ยืนยันตัวตน' : '☆ ยังไม่มี Star Card'}</span><span>${hint}</span></div>$2`);
  };

  function applyMissing(s) { return applySteps(s); }

  // ---------- หน้าแทรก = wizard "หนึ่งคำถามต่อหนึ่งหน้า" (minimal) ----------
  // เข้าหน้าแทรก → คำนวณรายการขั้นที่ยังขาด (wizSteps) → แสดงทีละหน้า: หัวข้อ 1 บรรทัด · ช่องกรอก · ปุ่มถัดไป
  // ขั้นที่มีข้อมูลแล้วไม่โผล่เลย · หน้าสุดท้ายปุ่มบอกปลายทาง (ฟอร์มสมัคร / หน้าตอบรับ)
  const chip = (t, on, extra = '') => `<span class="wz-chip ${on ? 'on' : ''}" data-do="pkToggle" ${extra}>${t}</span>`;
  const FORMAT_NAME = { shortVideo: 'Short Video', photo: 'Photo', longVideo: 'Long Video', seeding: 'Seeding' };
  const FORMATS = { instagram: ['shortVideo', 'photo'], facebook: ['shortVideo', 'photo'], tiktok: ['shortVideo'], youtube: ['shortVideo', 'longVideo'], x: ['shortVideo', 'seeding'], lemon8: ['photo', 'shortVideo'] };
  const FORMAT_MULT = { shortVideo: 1, photo: .8, longVideo: 1.4, seeding: .5 };
  const suggestPrice = (so, f) => Math.max(500, Math.round(so.followers / 1000 * 120 * FORMAT_MULT[f] / 100) * 100);
  const INSIGHT_OK = ['facebook', 'instagram', 'youtube', 'tiktok'];
  const SLOTS = [{ k: 'gender', t: 'เพศ', v: 'หญิง 68%' }, { k: 'age', t: 'ช่วงอายุ', v: '25–34 ปี 42%' }, { k: 'location', t: 'พื้นที่ยอดนิยม', v: 'กรุงเทพฯ 35%' }];
  const WZ = {
    socials: s => ({ h: 'แปะวาร์ปช่องของคุณเลย 📱', p: 'ผูก 1 ช่องพอ · ระบบดึงยอดผู้ติดตามให้', body: D.USER.socials.slice(0, 4).map(so => `<div class="wz-row ${so.connected ? 'on' : ''}" ${so.connected ? '' : `data-do="connectSocial" data-t="${so.type}"`}>${U.socialIcon(so.type, 36, 'social')}<div><b>${D.SOCIAL_META[so.type].name}</b>${so.connected ? `<span>${U.fmtNum(so.followers)} ผู้ติดตาม</span>` : ''}</div><i>${so.connected ? I('check', 16, 'bold') : 'เชื่อม'}</i></div>`).join(''), ok: () => D.USER.socials.some(x => x.connected), err: 'เชื่อมอย่างน้อย 1 ช่อง' }),
    categories: s => ({ h: 'คุณเป็นครีเอเตอร์สายไหน? 🎨', p: 'เลือกได้ถึง 5', body: `<div class="wz-chips">${['💄 บิวตี้', '👗 แฟชั่น', '🍜 อาหาร', '☕️ คาเฟ่', '✨ ไลฟ์สไตล์', '✈️ ท่องเที่ยว', '💪 สุขภาพ', '👶 แม่และเด็ก', '🐶 สัตว์เลี้ยง', '📱 เทค', '🎮 เกม', '🎬 บันเทิง', '🎪 อีเวนต์'].map((t, i) => chip(t, [1, 3, 5].includes(i))).join('')}</div>` }),
    about: s => ({ h: 'แนะนำตัวสั้น ๆ ✍️', p: '1 บรรทัด ขึ้นใต้ชื่อคุณบนการ์ด', body: `<textarea class="wz-ta" data-bind="form.about" placeholder="เช่น สายคาเฟ่ พาเที่ยวกรุงเทพทุกสุดสัปดาห์">${(s.form && s.form.about) || 'ชอบพาไปเที่ยว ทานอาหารอร่อยๆ แวะจิบกาแฟที่ร้านคาเฟ่น่ารักๆ'}</textarea>` }),
    rate: s => {
      // รูปแบบคอนเทนต์ต่อช่อง = ตาม SocialPriceProfileView ของ salehere-ios · ราคาแนะนำคิดจากยอดผู้ติดตาม (suggested*Price)
      const socs = D.USER.socials.filter(x => x.connected);
      return {
        h: 'เรทรับงานของคุณ 💸', p: 'ใส่ราคามาตรฐานให้แล้ว กดถัดไปได้เลย · อยากแก้ก็แก้ได้',
        body: socs.map(so => `<div class="wz-grp">
          <div class="wz-grp-h">${U.socialIcon(so.type, 24)}<b>${D.SOCIAL_META[so.type].name}</b><span>${U.fmtNum(so.followers)} ผู้ติดตาม</span></div>
          ${FORMATS[so.type].map(f => `<div class="wz-rate"><div class="lb">${FORMAT_NAME[f]}</div><label class="wz-in"><em>฿</em><input type="tel" value="${(s.form && s.form['rate_' + so.type + '_' + f]) ?? suggestPrice(so, f)}" data-bind="form.rate_${so.type}_${f}"><span class="unit">/โพสต์</span></label></div><div class="wz-sug">${I('check-circle', 13, 'bold')}ราคามาตรฐานจากยอดผู้ติดตาม · ปรับได้</div>`).join('')}
        </div>`).join('') + `<div class="wz-why"><span>${I('info', 15, 'bold')}ราคามาตรฐานคิดจากยอดผู้ติดตาม ปรับขึ้นลงได้ตลอด</span></div>`,
      };
    },
    measurements: s => ({ h: 'ขอไซซ์เสื้อผ้าหน่อยน้า 👗', p: 'งานนี้ส่งชุดให้ ต้องตรงไซซ์', body: `<div class="wz-grid">${[['ส่วนสูง', '165', 'ซม.'], ['น้ำหนัก', '50', 'กก.'], ['รอบอก', '32', 'นิ้ว'], ['รอบเอว', '25', 'นิ้ว'], ['สะโพก', '35', 'นิ้ว'], ['รองเท้า', '23', 'ซม.']].map(([l, v, u]) => `<label class="wz-in col"><small>${l}</small><span><input type="tel" placeholder="${v}"><em>${u}</em></span></label>`).join('')}</div>` }),
    area: s => ({
      h: 'รับงานที่ไหน ว่างวันไหน? 📍', p: 'แบรนด์ใช้คัดคนให้ตรงพื้นที่และช่วงเวลา',
      body: `<div class="wz-lbl">จังหวัดที่รับงาน</div><div class="wz-chips">${['กรุงเทพมหานคร', 'นนทบุรี', 'ปทุมธานี', 'สมุทรปราการ', 'ชลบุรี', 'เชียงใหม่', 'ทุกจังหวัด (ออนไลน์)'].map((t, i) => chip(t, i === 0)).join('')}</div>
        <div class="wz-lbl" style="margin-top:18px">ว่างรับงาน</div><div class="wz-tiles"><span class="wz-tile on" data-do="pickOne"><b>ทุกวัน</b><small>จ.–อา.</small></span><span class="wz-tile" data-do="pickOne"><b>ส.–อา.</b><small>วันหยุด</small></span><span class="wz-tile" data-do="pickOne"><b>จ.–ศ.</b><small>วันธรรมดา</small></span></div>
        <div class="wz-chips" style="margin-top:10px">${['เช้า', 'บ่าย', 'เย็น', 'ตลอดวัน'].map((t, i) => chip(t, i === 3)).join('')}</div>`,
    }),
    province: s => ({ h: 'อยู่จังหวัดไหน / ไปถึงไหนได้บ้าง? 📍', p: 'สำหรับงานหน้าร้าน · เลือกได้ถึง 3', body: `<div class="wz-chips">${['กรุงเทพมหานคร', 'นนทบุรี', 'ปทุมธานี', 'สมุทรปราการ', 'ชลบุรี', 'เชียงใหม่', 'ทุกจังหวัด (ออนไลน์)'].map((t, i) => chip(t, i === 0)).join('')}</div>` }),
    address: s => { const a = D.USER.address; return { h: 'ส่งของไปที่ไหน? 📦', p: 'ของรางวัลจะส่งมาที่นี่ · กรอกครั้งเดียว', body: `<label class="wz-in col"><small>ชื่อ–นามสกุล</small><span><input value="${a.name}"></span></label><label class="wz-in col"><small>เบอร์โทรศัพท์</small><span><input type="tel" value="${a.tel}"></span></label><label class="wz-in col"><small>ที่อยู่</small><span><input value="${a.address}"></span></label><div class="wz-grid"><label class="wz-in col"><small>รหัสไปรษณีย์</small><span><input type="tel" value="${a.zipcode}"></span></label><label class="wz-in col sel"><small>ตำบล/แขวง</small><span><input value="${a.subDistrict}"></span></label></div>` }; },
    bank: s => { const fee = cur(s).fee; return { h: 'รับเงินเข้าบัญชีไหน? 🏦', p: fee ? `ค่าตัวงานนี้ ฿${fee.toLocaleString()} จะโอนเข้าบัญชีนี้ · ใช้กับทุกงาน` : 'ใช้กับทุกงานที่มีค่าตัว · หัก ณ ที่จ่าย 3% ตามกฎหมาย', body: `<label class="wz-in col sel"><small>ธนาคาร</small><span><input value="กสิกรไทย"></span></label><label class="wz-in col"><small>เลขที่บัญชี</small><span><input type="tel" placeholder="xxx-x-xxxxx-x"></span></label><label class="wz-in col"><small>ชื่อบัญชี</small><span><input value="${D.USER.name}"></span></label><div class="wz-hint">${I('check-circle', 14, 'fill')} ชื่อตรงกับบัตรที่ยืนยันแล้ว</div><div class="wz-drop small" data-do="pkToggle">${I('camera', 22, 'bold')}<b>ถ่ายหน้าสมุดบัญชี</b></div>` }; },
    draftRounds: s => ({ h: 'แก้งานให้ได้กี่รอบ?', p: 'ถ้าแบรนด์ขอแก้ · ไม่นับกรณีงานไม่ตรงบรีฟ', body: `<div class="wz-tiles">${[1, 2, 3].map(n => `<span class="wz-tile ${n === 2 ? 'on' : ''}" data-do="pickOne"><b>${n}</b><small>ครั้ง</small></span>`).join('')}</div>` }),
    insight: s => {
      // ข้อมูลผู้ติดตาม = แนบภาพ 3 หมวด (เพศ · ช่วงอายุ · พื้นที่ยอดนิยม) ต่อช่อง แล้วระบบอ่านตัวเลขให้ — ตาม SocialInsight ของ salehere-ios · ไม่บังคับ
      const socs = D.USER.socials.filter(x => x.connected && INSIGHT_OK.includes(x.type));
      const g = (s.form || {}).insight || {};
      return {
        h: 'ข้อมูลผู้ติดตามของคุณ 📊', p: 'แบรนด์ชอบคนที่รู้จักผู้ติดตามตัวเอง · ทำช่องเดียวก็ช่วยแล้ว',
        body: socs.map(so => `<div class="wz-grp">
          <div class="wz-grp-h">${U.socialIcon(so.type, 24)}<b>${D.SOCIAL_META[so.type].name}</b><span>${SLOTS.filter(x => g[so.type + '_' + x.k]).length}/3</span></div>
          <div class="wz-slots">${SLOTS.map(x => { const on = g[so.type + '_' + x.k]; return `<button class="wz-slot ${on ? 'on' : ''}" data-do="pickInsight" data-t="${so.type}" data-k="${x.k}">${on ? `${I('check', 14, 'bold')}<b>${x.t}</b><span>${x.v}</span>` : `${I('plus', 16, 'bold')}<b>${x.t}</b><span>แตะเพื่อแนบ</span>`}</button>`; }).join('')}</div>
        </div>`).join('') + `<div class="wz-nudge">${I('star', 16, 'fill')}<div><b>มีข้อมูลนี้ โอกาสได้รับเลือกมากขึ้น</b><span>แบรนด์กรองคนจากกลุ่มผู้ติดตามก่อนเสมอ · แคปจากแอปโซเชียลได้เลย</span></div></div>`,
      };
    },
    kyc: s => {
      // รอทีมตรวจ (waiting_approve) = ไปต่อได้เลย ไม่ต้องรอ 1–3 วัน · ได้เป็น STAR เมื่อผ่าน
      const st = s.user.verify, done = st === 'approved', pending = st && st !== 'none' && !done;
      return {
        h: done ? 'ยืนยันตัวตนแล้ว 🪪' : pending ? 'ส่งยืนยันตัวตนแล้ว 🪪' : 'ยืนยันตัวตนก่อนเป็น STAR 🪪',
        p: done ? 'ป้าย Verified จะขึ้นบนการ์ดของคุณ' : pending ? 'ทีมงานตรวจภายใน 1–3 วันทำการ · สมัครงานต่อได้เลย' : 'ถ่ายบัตรประชาชน + ใบหน้า · ทำครั้งเดียว ใช้ได้ทุกงาน',
        body: done
          ? `<div class="wz-row on"><i>${I('check', 16, 'bold')}</i><div><b>Verified by Sale Here</b><span>ขึ้นป้ายบนการ์ดแล้ว</span></div></div>`
          : pending
            ? `<div class="wz-row wait"><i>${I('clock', 16, 'bold')}</i><div><b>กำลังตรวจข้อมูล</b><span>เราจะแจ้งเตือนเมื่อผ่าน · ระหว่างนี้สมัครงานได้ตามปกติ</span></div></div><div class="wz-why"><span>${I('info', 15, 'bold')}การ์ดจะขึ้นป้าย Verified และเป็น STAR เต็มตัวเมื่อตรวจผ่าน</span></div>`
            : `<div class="wz-drop" data-do="wizKyc">${I('identification-card', 28, 'bold')}<b>เริ่มยืนยันตัวตน</b></div><div class="wz-why"><span>${I('seal-check', 15, 'bold')}แบรนด์เลือกเฉพาะคนที่ยืนยันตัวตนแล้ว</span><span>${I('shield-check', 15, 'bold')}ข้อมูลบัตรใช้ยืนยันตัวตนเท่านั้น</span></div>`,
        ok: () => { const v = Store.get().user.verify; return !!v && v !== 'none'; }, err: 'ยืนยันตัวตนก่อน แล้วไปต่อได้เลย',
      };
    },
    availability: s => ({ h: 'ว่างรับงานวันไหน? 📅', p: 'แบรนด์ดูวันว่างของคุณตอนคัดคน · ปรับทีหลังได้', body: `<div class="wz-tiles"><span class="wz-tile on" data-do="pickOne"><b>ทุกวัน</b><small>จันทร์–อาทิตย์</small></span><span class="wz-tile" data-do="pickOne"><b>ส.–อา.</b><small>วันหยุด</small></span><span class="wz-tile" data-do="pickOne"><b>จ.–ศ.</b><small>วันธรรมดา</small></span></div><div class="wz-chips" style="margin-top:14px">${['เช้า', 'บ่าย', 'เย็น', 'ตลอดวัน'].map((t, i) => chip(t, i === 3)).join('')}</div>` }),
  };
  // หน้าแรกของ wizard ก่อนสมัคร: บอกเหตุผลที่อยู่ดีๆ เด้งมา (user: "กดลงทะเบียนแล้วอยู่ดีๆ มันขึ้นอันนี้ งง") · กี่อย่าง · กี่นาที · ทำครั้งเดียว
  const STEP_NAME = { socials: 'ช่องทางโซเชียล', categories: 'สายที่ใช่', about: 'แนะนำตัว', kyc: 'ยืนยันตัวตน', rate: 'เรทรับงาน', insight: 'ข้อมูลผู้ติดตาม', province: 'พื้นที่รับงาน', availability: 'วันเวลาว่างรับงาน' };
  WZ.intro = s => {
    const rest = (s.wizSteps || []).filter(k => k !== 'intro'), n = rest.length, card = hasCard(s);
    return {
      h: card ? `ก่อนสมัคร ขอข้อมูลเพิ่มอีก ${n} อย่าง` : 'ก่อนสมัครงานแรก สมัครเป็น STAR ก่อน',
      p: `ทำครั้งเดียว ใช้สมัครได้ทุกงาน · ประมาณ ${Math.max(1, Math.ceil(n * 0.4))} นาที`,
      body: `<ol class="wz-intro">${rest.map(k => `<li>${STEP_NAME[k] || k}</li>`).join('')}</ol><div class="wz-intro-note">${I('eye', 15, 'bold')}แบรนด์เห็นการ์ดใบนี้ตอนคัดคน · ครั้งหน้ากดสมัครได้ทันที</div>`,
    };
  };
  const OPTIONAL_STEPS = ['insight'];
  const withIntro = st => st.length ? ['intro', ...st] : [];
  const applySteps = s => ['socials', 'categories', 'about', 'kyc', 'rate', 'insight', 'province', 'availability'].filter(k => k === 'kyc' ? (!s.user.verify || s.user.verify === 'none') : !P(s)[k]);
  const acceptSteps = s => ['bank', 'draftRounds'].filter(k => !P(s)[k]);
  Ac.pickOne = (d, b) => { b.parentElement.querySelectorAll('.wz-tile').forEach(x => x.classList.remove('on')); b.classList.add('on'); };
  Ac.setAvail = d => { window.__keepScroll = true; Store.set({ form: Object.assign({}, Store.get().form || {}, { avail: d.v === '1' }) }); };

  // แถบการ์ดย่อบนหัว wizard: ช่องที่เติมแล้ว = ทึบ · ช่องที่กำลังตอบ = กะพริบ · ที่เหลือ = ประ → ทุกคำตอบ "ขึ้นการ์ดทันที"
  const STRIP = { socials: 'โซเชียล', categories: 'สาย', about: 'แนะนำตัว', rate: 'เรท', insight: 'ผู้ติดตาม', province: 'พื้นที่', availability: 'วันว่าง', kyc: 'Verified', bank: 'บัญชี', draftRounds: 'รอบแก้', address: 'ที่อยู่' };
  const stripDone = (s, k) => k === 'kyc' ? isVerified(s) : !!P(s)[k];
  function wizStrip(s, key, steps) {
    const keys = [...new Set(['socials', 'categories', ...steps.filter(k => k !== 'intro')])].filter(k => STRIP[k]);
    const done = keys.filter(k => stripDone(s, k)).length;
    return `<div class="wz-strip"><img src="${D.USER.avatar}" alt=""><div class="wz-strip-slots">${keys.map(k => `<span class="${stripDone(s, k) ? 'on' : k === key ? 'now' : ''}">${stripDone(s, k) ? I('check', 10, 'bold') : ''}${STRIP[k]}</span>`).join('')}</div><em>${done}/${keys.length}</em></div>`;
  }
  // nudge ใต้ปุ่ม: บอกผลทันทีของข้อนี้ (ไม่ใช่กติกา แต่คือสิ่งที่ได้)
  const STEP_GAIN = {
    socials: 'สิ่งแรกที่แบรนด์ดู: คุณอยู่ช่องไหน ยอดเท่าไหร่', categories: 'แบรนด์ใช้ข้อนี้จับคู่ว่างานไหนเหมาะกับคุณ', about: 'แบรนด์อ่านบรรทัดนี้เพื่อรู้จักคุณก่อนทัก',
    rate: 'แบรนด์อยากรู้ราคาก่อนทัก จะได้เสนองานที่จ่ายไหว', province: 'แบรนด์ที่มีงานหน้าร้านถามข้อนี้ทุกครั้ง', availability: 'แบรนด์ดูวันว่างของคุณตอนคัดคน', insight: 'แบรนด์ถามเสมอว่าคนดูคุณเป็นใคร อายุเท่าไหร่ อยู่ไหน',
    kyc: 'แบรนด์ขอให้ยืนยันตัวตนก่อนจ่ายค่าตัว', bank: 'ค่าตัวโอนเข้าบัญชีนี้ทันทีที่งานจบ', draftRounds: 'ตกลงไว้ก่อน ไม่ต้องเถียงหน้างาน',
  };
  function wizard(s, kind) {
    const steps = s.wizSteps || [], i = Math.min(s.wizI || 0, Math.max(0, steps.length - 1)), key = steps[i];
    if (!key) return `<div class="wz pk"><div class="wz-top"><button class="pk-circle" data-go="campaign">${I('x', 18, 'bold')}</button></div><div class="wz-body"><h2 class="wz-h">ข้อมูลครบแล้ว</h2></div><div class="wz-foot">${pkBtn(kind === 'apply' ? 'ไปฟอร์มสมัคร' : kind === 'one' ? 'กลับไปการ์ด' : 'ไปหน้าตอบรับ', { act: kind === 'apply' ? 'wizFinishApply' : kind === 'one' ? 'wizFinishOne' : 'wizFinishAccept' })}</div></div>`;
    if (key === 'intro') return wizIntro(s, steps.filter(k => k !== 'intro'));
    const st = WZ[key](s), c = cur(s), last = i === steps.length - 1;
    const dest = kind === 'apply' ? `ฟอร์มสมัคร ${c.ep}` : kind === 'accept' ? 'หน้าตอบรับ' : 'การ์ดของคุณ';
    const intro = key === 'intro', total = steps.filter(k => k !== 'intro').length, n = steps.slice(0, i + 1).filter(k => k !== 'intro').length;
    const label = intro ? 'เริ่มเลย' : kind === 'one' && last ? 'บันทึกลงการ์ด' : last ? `ไป${dest}` : 'ถัดไป';
    const exitGo = kind === 'one' ? (s.wizReturn || 'cardReveal') : 'campaign';
    const exitBtn = `<button class="pk-circle" data-do="${i ? 'wizBack' : 'wizExit'}">${I(i ? 'caret-left' : 'x', 18, 'bold')}</button>`;
    return `<div class="wz pk">
      <div class="wz-top">${exitBtn}<span class="wz-ctx">${kind === 'one' ? 'เติม Star Card' : kind === 'apply' ? (hasCard(s) ? `ข้อมูล STAR · ก่อนสมัคร ${c.ep}` : `สมัครเป็น STAR · ${c.ep}`) : `ข้อมูล STAR · ก่อนตอบรับ ${c.ep}`}</span><span class="wz-n">${!intro && total > 1 ? `${n}/${total}` : ''}</span></div>
      ${intro || (kind === 'one' && total < 2) ? '' : `<div class="wz-bar"><i style="width:${(n / total) * 100}%"></i></div>`}
      ${kind === 'one' ? '' : wizStrip(s, key, steps)}
      <div class="wz-body"><h2 class="wz-h">${st.h}</h2><p class="wz-p">${st.p}</p>${s.err ? `<div class="wz-err">${s.err}</div>` : ''}<div class="wz-ctl">${st.body}</div></div>
      <div class="wz-foot">${last && kind !== 'one' ? `<div class="wz-next">${kind === 'apply' ? 'ข้อสุดท้าย · จบแล้วแบรนด์เห็นการ์ดคุณได้ทันที' : `ข้อสุดท้าย · ต่อไป: ${dest}`}</div>` : STEP_GAIN[key] ? `<div class="wz-next gain">${I('sparkle', 12, 'fill')}${STEP_GAIN[key]}</div>` : ''}${pkBtn(label, { act: 'wizNext' })}${OPTIONAL_STEPS.includes(key) ? `<a class="pk-link" data-do="wizSkip">ข้ามไว้ก่อน · เติมทีหลังได้</a>` : ''}</div>
    </div>`;
  }
  // หน้าแรกก่อนสมัคร = "สมัครเป็น STAR" (ไม่ใช่ "สร้าง Star Card" — user: มันคือการสมัครเป็น Star) · การ์ดที่ยังว่าง: การ์ดกระจกใบจริง (รูป+ชื่อจากบัญชี) + ช่องประตรงที่ข้อมูลจะไปขึ้น → เห็นทันทีว่ากรอกแล้วได้อะไร
  const SLOT = { socials: 'ช่องทางโซเชียล', categories: 'สายที่ใช่', about: 'แนะนำตัว 1 บรรทัด', kyc: 'Verified', rate: 'เรทรับงาน', insight: 'ข้อมูลผู้ติดตาม', province: 'พื้นที่รับงาน', availability: 'วันเวลาว่างรับงาน' };
  function wizIntro(s, rest) {
    const c = cur(s), card = hasCard(s), n = rest.length, has = k => rest.includes(k);
    const slot = (k, cls = '') => has(k) ? `<span class="wzi-slot ${cls}">${I('plus', 12, 'bold')}${SLOT[k]}</span>` : '';
    return `<div class="wz wzi pk">
      <div class="gl-orbs"><i></i><i></i><i></i><i></i><i></i></div>
      <div class="wz-top"><button class="pk-circle" data-do="wizExit">${I('x', 18, 'bold')}</button><span class="wz-ctx">สมัคร ${c.ep}</span><span></span></div>
      <div class="wz-body">
        <h2 class="glass-title sm">${card ? `<span class="a">ข้อมูล</span><span class="b">STAR</span>` : `<span class="a">สมัครเป็น</span><span class="b">STAR</span>`}</h2>
        <p class="wzi-p">${card ? `แบรนด์งานนี้ขอดูเพิ่มอีก ${n} อย่าง` : `${n} ข้อนี้คือสิ่งที่แบรนด์ขอดูตอนคัดคน · กรอกครั้งเดียว ใช้ทุกงาน`}</p>
        <div class="wzi-card">
          <span class="wzi-star">★ STAR</span>
          <div class="wzi-top"><img src="${D.USER.avatar}" alt=""><div><b>${D.USER.name}</b><span class="wzi-inline">${slot('categories', 'sm')}${slot('kyc', 'sm')}</span></div></div>
          ${has('socials') ? `<div class="wzi-row">${slot('socials')}</div>` : ''}
          ${slot('about', 'wide')}
          ${has('rate') || has('province') ? `<div class="wzi-row">${slot('rate')}${slot('province')}</div>` : ''}
          ${has('availability') || has('insight') ? `<div class="wzi-row">${slot('availability')}${slot('insight')}</div>` : ''}
        </div>
        <div class="wzi-meta"><span>${I('eye', 14, 'bold')}แบรนด์เห็นการ์ดใบนี้ตอนคัด</span><span>${n} ขั้น</span></div>
      </div>
      <div class="wz-foot">${pkBtn(card ? 'เติมข้อมูล' : 'เริ่มสมัครเป็น STAR', { act: 'wizNext' })}</div>
    </div>`;
  }
  S.fillProfile = s => wizard(s, 'apply');
  S.fillAccept = s => wizard(s, 'accept');

  Ac.wizExit = () => Store.set({ dialog: 'wizExit' });
  Ac.wizExitKeep = () => { const s = Store.get(); Store.set({ dialog: null, screen: s.wizKind === 'one' ? (s.wizReturn || 'cardReveal') : 'campaign' }); Store.toast('เก็บไว้ให้แล้ว · กลับมาทำต่อได้ทุกเมื่อ'); };
  const oldOverlay = window.renderOverlay;
  window.renderOverlay = function (s) {
    if (s.dialog === 'wizExit') { const st = (s.wizSteps || []).filter(k => k !== 'intro'), doneN = st.filter(k => stripDone(s, k)).length; return U.dialog({ kind: 'modal', title: st.length && st.length - doneN <= 2 ? `เหลืออีก ${st.length - doneN} ข้อ จะออกเลยเหรอ` : 'เก็บไว้ทำต่อทีหลังไหม', detail: `${doneN ? `ทำไปแล้ว ${doneN}/${st.length} · ` : ''}ข้อมูลที่กรอกไว้ยังอยู่<br>กลับมากดสมัครอีกครั้งจะได้ทำต่อจากตรงนี้`, buttons: [{ t: 'เก็บไว้แล้วออก', style: 'gray', act: 'wizExitKeep' }, { t: 'ทำต่อเลย', act: 'closeDialog' }] }); }
    return oldOverlay(s);
  };
  Ac.wizSkip = () => { const s = Store.get(), steps = s.wizSteps || [], i = s.wizI || 0; if (i < steps.length - 1) return Store.set({ wizI: i + 1, err: null }); (s.wizKind === 'accept' ? Ac.wizFinishAccept : s.wizKind === 'one' ? Ac.wizFinishOne : Ac.wizFinishApply)(); };
  Ac.wizBack = () => Store.set({ wizI: Math.max(0, (Store.get().wizI || 0) - 1), err: null });
  // ออกไปทำ KYC จริงแล้วกลับมาที่ขั้นเดิมของ wizard
  Ac.pickInsight = d => { const s = Store.get(), f = Object.assign({}, s.form || {}), g = Object.assign({}, f.insight || {}); g[d.t + '_' + d.k] = !g[d.t + '_' + d.k]; f.insight = g; window.__keepScroll = true; Store.set({ form: f }); };
  Ac.wizKyc = () => { const s = Store.get(); Store.set({ kycBack: { screen: s.screen, wizI: s.wizI || 0 }, err: null }); Ac.openKyc(); };
  Ac.wizNext = () => {
    const s = Store.get(), steps = s.wizSteps || [], i = s.wizI || 0, key = steps[i], st = WZ[key] && WZ[key](s);
    if (st && st.ok && !st.ok()) { window.__keepScroll = true; Store.set({ err: st.err }); document.querySelector('.wz-ctl')?.classList.add('shake'); return; }
    if (key === 'intro') { Store.set({ wizI: i + 1, err: null }); return; }
    const patch = { err: null };
    if (s.wizKind !== 'one' && key !== 'kyc') Store.toast(`✓ ${STRIP[key] || 'ข้อมูล'} ขึ้นการ์ดแล้ว`);
    if (key === 'socials') D.USER.socials.forEach(so => { if (so.type === 'instagram') so.connected = true; });
    if (key === 'area') patch.profile = { province: true, availability: true };
    else if (key === 'insight') { const g = ((s.form || {}).insight) || {}; patch.profile = { insight: Object.keys(g).some(k2 => g[k2]) }; }
    else if (key !== 'kyc') patch.profile = { [key]: true };
    if (i < steps.length - 1) { patch.wizI = i + 1; Store.set(patch); return; }
    Store.set(patch);
    (s.wizKind === 'accept' ? Ac.wizFinishAccept : s.wizKind === 'one' ? Ac.wizFinishOne : Ac.wizFinishApply)();
  };
  Ac.wizFinishApply = () => {
    const s = Store.get(), madeCard = (s.wizSteps || []).some(k => ['socials', 'categories', 'about', 'kyc'].includes(k)) && hasCard(s);
    Store.set({ screen: madeCard ? 'cardReveal' : 'register', dialog: null, sheet: null, wizSteps: [], wizI: 0 });
    if (!madeCard) Store.toast('ข้อมูลเติมให้แล้ว · ต่อที่ฟอร์มสมัคร');

  };
  Ac.wizFinishAccept = () => { Store.set({ screen: 'accept', dialog: null, sheet: null, wizSteps: [], wizI: 0 }); Store.toast('ที่อยู่เติมให้แล้ว · ต่อที่หน้าตอบรับ'); };
  Ac.editRate = () => Store.set({ profile: { rate: false } });
  Ac.editAddress = () => Store.set({ profile: { address: false } });

  // ---------- การ์ดเกิด = "คุณเป็น STAR แล้ว" → ฟอร์มสมัครเดิม ----------
  // โทนสว่าง (พื้น PK #F9FAFB) · ไม่มีคำว่าระดับ/Level · บอกสิทธิ์ที่ได้ทันที
  // การ์ด 3D ลอยขึ้นมาวางตัว (expo ease) · แสงสะท้อนตามมุมเอียง · เงาจริง · ฝุ่นแสงทองลอยช้า · ตราวงแหวนวาดตัวเอง · ไม่มี confetti
  // หน้าเดียวกัน 2 โหมด: reveal = การ์ดเพิ่งเกิด (มี intro + ปุ่มต่อไปฟอร์มสมัคร) · profile = Star Profile ถาวรจากปุ่ม "โปรไฟล์ครีเอเตอร์" (ไม่มี intro · ปุ่มแชร์)
  function starPage(s, mode) {
    const profile = mode === 'profile', boost = mode === 'boost', card = hasCard(s);
    const head = boost
      ? `<h2 class="ach2-h glass-title sm"><span class="a">เพิ่มโอกาส</span><span class="b">ถูกเลือก</span></h2><p class="ach2-p glass-chip">${I('clock', 15, 'bold')}ส่งใบสมัครแล้ว · ระหว่างรอแบรนด์เลือก เติมได้เลย</p>`
      : profile
      ? (card ? `<h2 class="ach2-h glass-title"><span class="a">Star</span><span class="b">Profile</span></h2><p class="ach2-p glass-chip">${I('eye', 15, 'bold')}แบรนด์เห็นการ์ดใบนี้ตอนคัดคน</p>` : `<h2 class="ach2-h glass-title sm"><span class="a">สมัครเป็น</span><span class="b">STAR</span></h2><p class="ach2-p glass-chip">${I('clock', 15, 'bold')}กรอก 3 อย่าง · ประมาณ 1 นาที</p>`)
      : `<div class="ach2-seal"><svg viewBox="0 0 120 120"><defs><linearGradient id="gold" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E8C766"/><stop offset=".5" stop-color="#C9A227"/><stop offset="1" stop-color="#8A6A1A"/></linearGradient></defs><circle class="ring" cx="60" cy="60" r="54" fill="none" stroke="url(#gold)" stroke-width="1.2"/><circle class="ring2" cx="60" cy="60" r="47" fill="none" stroke="url(#gold)" stroke-width=".6" opacity=".6"/><path class="star" d="M60 34l6.9 14.3 15.6 2-11.4 10.9 2.9 15.5L60 69.2l-14 7.5 2.9-15.5-11.4-10.9 15.6-2z" fill="url(#gold)"/></svg></div>
        ${isStar(s)
          ? `<h2 class="ach2-h glass-title sm reveal-words"><span class="a w1">คุณเป็น</span><span class="b w2" data-t="STAR">STAR</span><span class="a w3">แล้ว</span></h2>`
          : `<h2 class="ach2-h glass-title sm reveal-words"><span class="a w1">การ์ดของคุณ</span><span class="b w2" data-t="พร้อมแล้ว">พร้อมแล้ว</span></h2>`}
`;
    // ยังไม่ครบ = ปุ่มหลักคือ "เติมอีก N อย่าง" (wizard ต่อเนื่องเฉพาะข้อที่ขาด) · ครบแล้วค่อยเป็นปุ่มไปต่อ/แชร์
    const list = rowsFor(s), all = list.length, nDone = list.filter(r => rowDone(s, r)).length, left = all - nDone;
    const mins = Math.max(1, Math.ceil(missingSteps(s).length * 0.5) + (isVerified(s) ? 0 : 1));
    const fillBtn = `<button class="ach2-btn" data-do="fillAllMissing"><span>เติมอีก ${left} อย่าง · ประมาณ ${mins} นาที</span>${I('arrow-right', 18, 'bold')}</button>`;
    const foot = boost
      ? (left ? `${fillBtn}<a class="pk-link" data-go="campaign">ไว้ทีหลัง · กลับไปหน้ากิจกรรม</a>` : `<button class="ach2-btn" data-go="campaign"><span>กลับไปหน้ากิจกรรม</span>${I('arrow-right', 18, 'bold')}</button>`)
      : profile
      ? (card ? (left ? `${fillBtn}<a class="pk-link" data-do="share">แชร์การ์ด</a>` : `<button class="ach2-btn" data-do="share"><span>แชร์การ์ด</span>${I('share-network', 18, 'bold')}</button>`) : `<button class="ach2-btn" data-do="profileMakeCard"><span>สมัครเป็น STAR</span>${I('arrow-right', 18, 'bold')}</button>`)
      : `<button class="ach2-btn" data-do="revealNext"><span>ต่อ: ฟอร์มสมัคร ${cur(s).ep}</span>${I('arrow-right', 18, 'bold')}</button><a class="pk-link" data-do="share">แชร์การ์ดก่อน</a>`;
    // ทั้ง 2 โหมด (การ์ดเกิด + Star Profile ถาวร) = พื้นสว่าง + แสงเบลอโทนเดียว (champagne) + การ์ด/แถวเป็นกระจก · การ์ดขอบเหลืองนิดๆ ใบเดียว · ไม่มีดาว/ฝุ่น/การ์ดลอย (canvas "Star Profile 2026 Directions" แบบ C)
    return `<div class="ach2 pk ${profile || boost || s.revealSeen ? 'quiet' : ''} glass ${profile || boost ? 'profile' : ''}" id="ach2">
      <div class="gl-orbs"><i></i><i></i><i></i><i></i><i></i></div><div class="ach2-dust" id="ach2-dust"></div>
      <button class="ach2-x pk-circle" data-go="${profile ? 'profile' : 'campaign'}">${I(profile || boost ? 'caret-left' : 'x', 18, 'bold')}</button>
      <div class="ach2-body">
        ${head}
        <div class="ach2-stage"><div class="ach2-halo"></div><div class="ach2-shadow"></div><div class="ach2-float"><div class="ach2-card" id="ach2-card">${window.cardView(s)}<span class="spec"></span><span class="edge"></span></div></div></div>
        <div class="ach2-bt">${boost ? `<div class="bt-row"><b>${left ? `เติมอีก ${left} อย่าง` : 'ข้อมูลครบแล้ว'}</b><em>${nDone}/${all}</em></div><div class="bt-bar ${left ? '' : 'full'}"><i data-to="${(nDone / all) * 100}" style="width:${s.lastPct ?? (nDone / all) * 100}%"></i></div><span>${left ? 'แบรนด์เริ่มคัดคนเร็ว ๆ นี้ · ครบก่อนได้เปรียบ' : 'พร้อมให้แบรนด์เลือกแล้ว'}</span>` : card
          ? `<div class="bt-row"><b>${left ? 'เติมการ์ดให้เต็ม' : 'การ์ดเต็มแล้ว'}</b><em class="${left ? '' : 'ok'}">${left ? `${nDone}/${all}` : `${I('check', 13, 'bold')} ${all}/${all}`}</em></div><div class="bt-bar ${left ? '' : 'full'}"><i data-to="${(nDone / all) * 100}" style="width:${s.lastPct ?? (nDone / all) * 100}%"></i></div><span>${left ? (mode === 'reveal' ? 'ส่งใบสมัครก่อนได้ · ค่อยกลับมาเติมระหว่างรอผล' : 'แบรนด์เห็นราคาและสไตล์คุณก่อนเลือก') : 'แบรนด์เห็นข้อมูลคุณครบแล้ว'}</span>`
          : `<b>ข้อมูลบนการ์ด</b><span>ข้อมูลเหล่านี้จะขึ้นบนการ์ดของคุณ</span>`}</div>
        <div class="ach2-rows">${revealRows(s)}</div>
      </div>
      <div class="ach2-foot">${foot}</div>
    </div>`;
  }
  S.cardReveal = s => starPage(s, 'reveal');
  // ส่งใบสมัครแล้ว → ที่อยู่มาจากฟอร์มสมัครเดิม (ไม่ต้องถามซ้ำตอนตอบรับ) → หน้าเพิ่มโอกาสถูกเลือก
  const oldSubmit = Ac.submitRegister;
  Ac.submitRegister = () => {
    const s = Store.get();
    oldSubmit();
    const ns = Store.get();
    if (s.flow === 'new' && ns.campaign === 'registered') Store.set({ profile: { address: true } });
  };
  // ปุ่ม "โปรไฟล์ครีเอเตอร์" (และทุกทางเข้า profileHub เดิม) ใน flow ใหม่ → Star Profile
  const oldHub = S.profileHub;
  S.profileHub = s => s.flow === 'new' ? starPage(s, 'profile') : oldHub(s);
  const oldCreatorProfile = Ac.creatorProfile;
  Ac.creatorProfile = () => { const s = Store.get(); if (s.flow !== 'new') return oldCreatorProfile(); Store.set({ screen: 'profileHub', dialog: null, sheet: null }); };
  Ac.profileMakeCard = () => { const steps = ['socials', 'categories', 'about'].filter(k => !P(Store.get())[k]); Store.set({ screen: 'fillOne', wizSteps: steps, wizI: 0, wizKind: 'one', wizReturn: 'profileHub', err: null, dialog: null, sheet: null }); };

  // แถว "ข้อมูลของฉัน" แบบ iOS hub: มี = ติ๊กเขียว + ชิปสรุป · ยังไม่มี = บอกประโยชน์ 1 บรรทัด + ปุ่ม "+ เพิ่ม" · แตะแล้วเปิด wizard เฉพาะข้อนั้น แล้วกลับมาหน้านี้
  const REVEAL_ROWS = [
    { key: 'kyc', icon: 'seal-check', t: 'ยืนยันตัวตน', done: s => ['Verified'], why: 'ต้องผ่านก่อนแบรนด์เลือก · ขึ้นป้าย Verified' },
    { key: 'rate', icon: 'coins', t: 'เรทรับงาน', done: s => ['IG ฿3,000', 'TikTok ฿10,300', '+3 รูปแบบ'], why: 'แบรนด์เห็นราคาก่อนทัก ไม่ต้องต่อรอง' },
    { key: 'about', icon: 'text-align-left', t: 'แนะนำตัว', done: s => ['ชอบพาไปเที่ยว ทานอาหารอร่อยๆ…'], why: '1 บรรทัดใต้ชื่อบนการ์ด' },
    { key: 'insight', icon: 'users-three', t: 'ข้อมูลผู้ติดตาม', done: s => ['หญิง 68%', '25–34 ปี', 'กรุงเทพฯ'], why: 'แบรนด์เห็นว่าคนดูคุณเป็นใคร' },
    { key: 'province', icon: 'map-pin', t: 'พื้นที่รับงาน', done: s => ['กรุงเทพฯ', 'นนทบุรี', '+1'], why: 'งานหน้าร้านใกล้คุณขึ้นก่อน' },
    { key: 'availability', icon: 'calendar-dots', t: 'วันเวลาว่างรับงาน', done: s => ['เสาร์–อาทิตย์', 'เย็น'], why: 'แบรนด์ดูวันว่างของคุณตอนคัดคน' },
    { key: 'socials', icon: 'broadcast', t: 'ช่องทางของฉัน', done: s => D.USER.socials.filter(x => x.connected).map(so => `${({ instagram: 'IG', tiktok: 'TikTok', youtube: 'YouTube', facebook: 'FB', x: 'X', lemon8: 'Lemon8' })[so.type] || so.type} ${U.fmtNum(so.followers)}`), why: 'ยอดผู้ติดตามขึ้นการ์ดอัตโนมัติ' },
    { key: 'categories', icon: 'sparkle', t: 'สายที่ใช่', done: s => D.USER.categories, why: 'งานตรงสายขึ้นหน้าแรกให้' },
    { key: 'bank', icon: 'bank', t: 'การรับเงิน', done: s => ['กสิกรไทย', '···7890'], why: 'ค่าตัวเข้าบัญชีทันทีเมื่องานจบ' },
    { key: 'draftRounds', icon: 'arrows-clockwise', t: 'รอบแก้งาน', done: s => ['แก้ 2 รอบ'], why: 'ตกลงไว้ก่อน ไม่ต้องเถียงหน้างาน' },
    { key: 'address', icon: 'package', t: 'ที่อยู่รับของ', done: s => ['กรุงเทพฯ 10110'], why: 'ใช้ที่อยู่จากใบสมัคร · แก้ได้' },
  ];
  const rowsFor = s => REVEAL_ROWS;
  const rowDone = (s, r) => r.key === 'kyc' ? isVerified(s) : (r.keys || [r.key]).every(k => P(s)[k]);
  // ข้อที่ยังขาดขึ้นก่อนเสมอ · ข้อที่ครบรวมเป็นบรรทัดเดียว "ครบแล้ว N อย่าง" กดขยายดูได้
  const missingSteps = s => rowsFor(s).filter(r => r.key !== 'kyc' && !rowDone(s, r)).flatMap(r => (r.keys || [r.key]).filter(k => WZ[k] && !P(s)[k]));
  function revealRows(s) {
    const list = rowsFor(s), done = list.filter(r => rowDone(s, r)), todo = list.filter(r => !rowDone(s, r));
    const doneBar = done.length ? `<div class="ach2-done ${s.doneOpen || !todo.length ? 'open' : ''}" data-do="toggleDone"><i class="tick">${I('check', 12, 'bold')}</i><div class="tx"><b>ครบแล้ว ${done.length} อย่าง</b><span class="sum">${done.map(r => r.t).join(' · ')}</span></div>${I('caret-down', 16, 'bold')}</div>` : '';
    return rowsHtml(s, todo) + doneBar + (s.doneOpen || !todo.length ? rowsHtml(s, done) : '');
  }
  Ac.toggleDone = () => { window.__keepScroll = true; Store.set({ doneOpen: !Store.get().doneOpen }); };
  Ac.fillAllMissing = () => {
    Store.set({ lastPct: pctDone(Store.get()) });
    const s = Store.get(), back = s.screen === 'profileHub' ? 'profileHub' : 'cardReveal', steps = missingSteps(s);
    if (!steps.length) { Store.set({ revealKyc: back, revealSeen: true }); return Ac.openKyc(); }
    Store.set({ screen: 'fillOne', wizSteps: steps, wizI: 0, wizKind: 'one', wizReturn: back, err: null, revealSeen: true, dialog: null, sheet: null });
  };
  function rowsHtml(s, list) {
    return list.map(r => {
      const ok = rowDone(s, r);
      return `<div class="ach2-row ${ok ? 'ok' : 'todo'}" data-do="revealFill" data-k="${r.key}">
        <i class="ic">${I(r.icon, 18, ok ? 'fill' : 'bold')}</i>
        <div class="tx"><b>${r.t}</b><span class="sum">${ok ? r.done(s).join(' · ') : (r.key === 'kyc' && s.user.verify && s.user.verify !== 'none') ? 'ทีมงานตรวจภายใน 1–3 วันทำการ' : r.why}</span></div>
        ${ok ? `<i class="tick">${I('check', 12, 'bold')}</i>` : (r.key === 'kyc' && s.user.verify && s.user.verify !== 'none') ? `<span class="wait-pill">${I('clock', 12, 'bold')}กำลังตรวจ</span>` : `<span class="add">${I('plus', 13, 'bold')}<em>เพิ่ม</em></span>`}
      </div>`;
    }).join('');
  }
  Ac.revealFill = d => {
    Store.set({ lastPct: pctDone(Store.get()) });
    const s = Store.get(), r = REVEAL_ROWS.find(x => x.key === d.k);
    const back = s.screen === 'profileHub' ? 'profileHub' : 'cardReveal';
    if (r.key === 'kyc') { Store.set({ revealKyc: back, revealSeen: true }); return Ac.openKyc(); }
    const steps = (r.keys || [r.key]).filter(k => WZ[k]);
    Store.set({ screen: 'fillOne', wizSteps: steps, wizI: 0, wizKind: 'one', wizReturn: back, err: null, revealSeen: true, dialog: null, sheet: null });
  };
  S.fillOne = s => wizard(s, 'one');
  const pctDone = s => { const l = rowsFor(s); return l.filter(r => rowDone(s, r)).length / l.length * 100; };
  Ac.wizFinishOne = () => {
    // toast ก่อน (toast = set state = render ใหม่) แล้วค่อยกลับหน้าการ์ด แถบความครบจะได้วิ่งจากค่าเดิมไปค่าใหม่ใน render สุดท้าย
    const s = Store.get();
    Store.toast(!hasCard(s) ? 'บันทึกแล้ว' : pctDone(s) === 100 ? 'การ์ดเต็มแล้ว · แบรนด์เห็นข้อมูลคุณครบ' : 'เพิ่มลงการ์ดแล้ว');
    Store.set({ screen: s.wizReturn || 'cardReveal', dialog: null, sheet: null, wizSteps: [], wizI: 0 });
  };
  const oldAfter = window.afterRender;
  window.afterRender = function (s) {
    oldAfter && oldAfter(s);
    // ทุกหน้าใหม่ของ flow StarCard (.pk: wizard · การ์ดเกิด · Star Profile) = status bar ขาว ไม่ใช่แดงของ Sale Here
    document.body.classList.toggle('light-status', !!document.querySelector('#screen .pk'));
    const bar = document.querySelector('.ach2-bt .bt-bar i');
    if (bar && bar.style.width !== bar.dataset.to + '%') { void bar.offsetWidth; bar.style.width = bar.dataset.to + '%'; Store.get().lastPct = null; }
    const root = document.getElementById('ach2');
    if (!root || root.dataset.done) return;
    root.dataset.done = '1';
    // ฝุ่นแสง: จุดเล็ก เบลอ ลอยขึ้นช้า ๆ
    const dust = document.getElementById('ach2-dust');
    if (dust) dust.innerHTML = Array.from({ length: 26 }, () => `<i style="left:${Math.random() * 100}%;top:${40 + Math.random() * 60}%;width:${2 + Math.random() * 3}px;height:${2 + Math.random() * 3}px;animation-duration:${(9 + Math.random() * 9).toFixed(1)}s;animation-delay:${(-Math.random() * 12).toFixed(1)}s;opacity:${(.25 + Math.random() * .4).toFixed(2)}"></i>`).join('');
    // parallax: เมาส์ / เอียงเครื่อง → เอียงการ์ด + เลื่อนแสงสะท้อน
    // เริ่มหลัง card-in จบเท่านั้น (ระหว่าง animation ค่า --rx/--ry จะกระโดดโดยไม่มี transition = สั่น) และอัปเดตแค่เฟรมละครั้ง
    const card = document.getElementById('ach2-card');
    if (!card) return;
    let ready = false, raf = 0, tx = 0, ty = 0;
    const apply = () => { raf = 0; card.style.setProperty('--rx', (ty * -8).toFixed(2) + 'deg'); card.style.setProperty('--ry', (tx * 12).toFixed(2) + 'deg'); card.style.setProperty('--sx', (50 + tx * 40).toFixed(1) + '%'); card.style.setProperty('--sy', (30 + ty * 40).toFixed(1) + '%'); };
    const set = (nx, ny) => { if (!ready || root.classList.contains('glass')) return; tx = nx; ty = ny; if (!raf) raf = requestAnimationFrame(apply); };
    const settle = () => { card.classList.add('settled'); card.closest('.ach2-stage').classList.add('settled'); ready = true; };
    card.addEventListener('animationend', e => { if (e.animationName === 'card-in') settle(); });
    setTimeout(settle, root.classList.contains('quiet') ? 50 : 2800);
    root.addEventListener('mousemove', e => { const r = root.getBoundingClientRect(); set((e.clientX - r.left) / r.width - .5, (e.clientY - r.top) / r.height - .5); });
    root.addEventListener('mouseleave', () => set(0, 0));
    window.addEventListener('deviceorientation', e => { if (e.gamma != null) set(Math.max(-.5, Math.min(.5, e.gamma / 60)), Math.max(-.5, Math.min(.5, (e.beta - 45) / 60))); });
  };
  Ac.revealNext = () => Store.set({ screen: 'register', revealSeen: true, dialog: null, sheet: null });
  const acceptMissing = s => ['bank', 'draftRounds'].filter(k => !P(s)[k]);


  // ---------- Unbox happy case เป็นลำดับเดียว + กติกาติ๊กข้อมูล ----------
  window.STAGES = [
    { t: 'เห็นงาน · หน้ากิจกรรม', set: { campaign: 'register', review: 'none', order: 'preparing', screen: 'campaign', reviewTab: false } },
    { t: 'แทรก: ข้อมูลของคุณ (ก่อนสมัคร)', set: { campaign: 'register', review: 'none', screen: 'fillProfile' } },
    { t: 'ฟอร์มสมัครเดิม (ไม่แก้)', set: { campaign: 'register', review: 'none', screen: 'register' } },
    { t: 'ลงทะเบียนสำเร็จ · dialog เดิม', set: { campaign: 'registered', review: 'none', screen: 'campaign', dialog: 'registerSuccess' } },
    { t: 'แบรนด์คัดคน · รอผล', set: { campaign: 'registered', review: 'none', screen: 'campaign' } },
    { t: 'ได้รับเลือก · ปุ่มตอบรับ (เดิม)', set: { campaign: 'waitingAcceptQuota', review: 'none', screen: 'campaign' } },
    { t: 'กดตอบรับ → แทรก: ข้อมูลก่อนตอบรับ', set: { campaign: 'waitingAcceptQuota', review: 'none', screen: 'fillAccept' } },
    { t: 'หน้าตอบรับเดิม (ที่อยู่เติมให้)', set: { campaign: 'waitingAcceptQuota', review: 'none', screen: 'accept' } },
    { t: 'ตอบรับแล้ว · รอของ', set: { campaign: 'acceptedQuota', review: 'notOpenDraft', order: 'shipping', screen: 'campaign' } },
    { t: 'ของถึง · สร้างดราฟต์ (เดิม)', set: { campaign: 'acceptedQuota', review: 'waitingDraft', order: 'delivered', screen: 'draft', briefRead: true } },
    { t: 'ส่งดราฟต์ · รอตรวจ (เดิม)', set: { campaign: 'acceptedQuota', review: 'waitingApproveDraft', order: 'delivered', screen: 'preview', briefRead: true } },
    { t: 'ดราฟต์ผ่าน · ส่งลิงก์ (เดิม)', set: { campaign: 'acceptedQuota', review: 'waitingReview', order: 'delivered', screen: 'link', briefRead: true } },
    { t: 'ส่งลิงก์แล้ว · จบ (หน้ากิจกรรมเดิม + dialog เดิม)', set: { campaign: 'acceptedQuota', review: 'reviewed', order: 'delivered', screen: 'campaign', reviewTab: true, dialog: 'linkSuccess', briefRead: true } },
  ];
  window.DATA_RULES = [
    { key: 'socials', label: 'โซเชียล ≥1 ช่อง + ยอดฟอล', askAt: 1, needFrom: 2 },
    { key: 'categories', label: 'สายที่ใช่', askAt: 1, needFrom: 2 },
    { key: 'about', label: 'แนะนำตัว 1 บรรทัด', askAt: 1, needFrom: 2 },
    { key: 'kyc', label: 'ยืนยันตัวตน (KYC)', askAt: 1, needFrom: 2 },
    { key: 'rate', label: 'เรทรับงานต่อรูปแบบคอนเทนต์', askAt: 1, needFrom: 2 },
    { key: 'province', label: 'จังหวัดที่รับงาน', askAt: 1, needFrom: 2 },
    { key: 'availability', label: 'วัน/เวลาว่างรับงาน', askAt: 1, needFrom: 2 },
    { key: 'address', label: 'ที่อยู่รับของ + เบอร์', askAt: 2, needFrom: 3 },
    { key: 'bank', label: 'บัญชีรับเงิน', askAt: 6, needFrom: 7 },
    { key: 'draftRounds', label: 'แก้งานได้กี่รอบ', askAt: 6, needFrom: 7 },
  ];
  const ruleApplies = (s, r) => true;
  window.stageOf = function (s) {
    const c = s.campaign, r = s.review, sc = s.screen;
    if (r === 'reviewed') return 12;
    if (sc === 'link' || r === 'waitingReview' || r === 'notOpenReview') return 11;
    if (sc === 'preview' || r === 'waitingApproveDraft' || r === 'rejectDraft') return 10;
    if (sc === 'draft' || r === 'waitingDraft' || r === 'draft') return 9;
    if (c === 'acceptedQuota') return 8;
    if (sc === 'accept') return 7;
    if (sc === 'fillAccept') return 6;
    if (c === 'waitingAcceptQuota') return 5;
    if (c === 'registered') return s.dialog === 'registerSuccess' ? 3 : 4;
    if (sc === 'register') return 2;
    if (sc === 'fillProfile' || sc === 'cardReveal' || sc === 'fillOne') return 1;
    return 0;
  };
  Ac.gotoStage = d => {
    const i = Number(d.i), s = Store.get();
    const pf = {}, user = {};
    window.DATA_RULES.forEach(r => { if (!ruleApplies(s, r)) return; if (i >= r.needFrom) { if (r.key === 'kyc') user.verify = 'approved'; else pf[r.key] = true; } });
    const patch = Object.assign({ dialog: null, sheet: null, err: null, quota: 'primary', reviewTab: false, profile: pf, user: Object.assign({ consent: i >= 2 }, user), form: Object.assign({}, s.form || {}) }, window.STAGES[i].set);
    Store.set(patch);
    const ns = Store.get();
    if (ns.screen === 'fillProfile') { const st = withIntro(applySteps(ns)); Store.set(st.length ? { wizSteps: st, wizI: 0, wizKind: 'apply' } : { screen: 'register', wizSteps: [], wizI: 0 }); }
    if (ns.screen === 'fillAccept') { const st = acceptSteps(ns); Store.set(st.length ? { wizSteps: st, wizI: 0, wizKind: 'accept' } : { screen: 'accept', wizSteps: [], wizI: 0 }); }
  };
  Ac.tickData = (key, on) => {
    const s = Store.get(), r = window.DATA_RULES.find(x => x.key === key);
    const patch = key === 'kyc' ? { user: { verify: on ? 'approved' : 'none', welcome: on ? [true, true, true] : s.user.welcome } } : { profile: { [key]: on } };
    if (!on && window.stageOf(s) >= r.needFrom) {
      Object.assign(patch, window.STAGES[r.askAt].set, { dialog: null, sheet: null, err: null });
      Store.set(patch);
      const ns = Store.get();
      if (ns.screen === 'fillProfile') { const st = withIntro(applySteps(ns)); Store.set(st.length ? { wizSteps: st, wizI: 0, wizKind: 'apply' } : { screen: 'register', wizSteps: [], wizI: 0 }); }
      if (ns.screen === 'fillAccept') { const st = acceptSteps(ns); Store.set(st.length ? { wizSteps: st, wizI: 0, wizKind: 'accept' } : { screen: 'accept', wizSteps: [], wizI: 0 }); }
      Store.toast(`ย้อนกลับไป "${window.STAGES[r.askAt].t}" เพราะข้อมูลนี้หายไป`);
      return;
    }
    Store.set(patch);
  };

  // ---------- จุด hook ----------
  const oldTap = Ac.tapRegister;
  Ac.tapRegister = () => {
    const s = Store.get();
    if (s.flow !== 'new') return oldTap();
    if (!s.user.isLogin) return Store.set({ screen: 'login', dialog: null, sheet: null });
    if (s.user.reviewStatus === 'reviewPending') return Store.set({ dialog: 'punish' });
    const steps = withIntro(applySteps(s));
    Store.set({ screen: steps.length ? 'fillProfile' : 'register', wizSteps: steps, wizI: 0, wizKind: 'apply', dialog: null, sheet: null, err: null });
  };
  const oldTapMain = Ac.tapMain;
  Ac.tapMain = () => {
    const s = Store.get();
    if (s.flow === 'new' && s.campaign === 'waitingAcceptQuota') { const steps = acceptSteps(s); return Store.set({ screen: steps.length ? 'fillAccept' : 'accept', wizSteps: steps, wizI: 0, wizKind: 'accept', dialog: null, sheet: null, err: null }); }
    return oldTapMain();
  };
  const oldKycDone = Ac.kycDone;
  Ac.kycDone = () => {
    const s = Store.get();
    if (s.flow !== 'new' || s.kyc.unbox) return oldKycDone();
    // กลับจาก KYC = ตัดขั้น kyc ทิ้งแล้วไปคำถามถัดไปเลย ไม่ต้องให้กดผ่านหน้า "ยืนยันตัวตนแล้ว" อีก
    if (s.kycBack) {
      const b = s.kycBack, steps = (s.wizSteps || []).filter(k => k !== 'kyc');
      const patch = { screen: b.screen, wizSteps: steps, wizI: Math.min(b.wizI, Math.max(0, steps.length - 1)), kycBack: null, dialog: null, sheet: null, kyc: { step: 'type', fails: 0 } };
      if (!steps.length) { Store.set(Object.assign(patch, { wizI: 0 })); return Ac.wizFinishApply(); }
      Store.set(patch);
      Store.toast(isVerified(s) ? 'ยืนยันตัวตนแล้ว · ไปต่อได้เลย' : 'ส่งคำขอยืนยันตัวตนแล้ว · สมัครงานต่อได้เลย');
      return;
    }
    if (s.revealKyc) { Store.set({ screen: typeof s.revealKyc === 'string' ? s.revealKyc : 'cardReveal', revealKyc: false, dialog: null, sheet: null, kyc: { step: 'type', fails: 0 } }); Store.toast(isVerified(s) ? 'ป้าย Verified ขึ้นการ์ดแล้ว' : 'ส่งคำขอยืนยันตัวตนแล้ว · รอทีมตรวจ'); return; }
    Store.set({ screen: 'campaign', dialog: null, sheet: null, kyc: { step: 'type', fails: 0 } });
    Store.toast(isVerified(s) ? 'ตรา Verified ขึ้นการ์ดแล้ว · ใบสมัครอัปเดตให้อัตโนมัติ' : 'ส่งคำขอยืนยันตัวตนแล้ว · รอทีมตรวจ');
  };
})();
