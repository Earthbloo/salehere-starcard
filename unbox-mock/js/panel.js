// แผงควบคุม state (ด้านขวา) — เปลี่ยนได้ทุก enum + flag ผู้ใช้ + กระโดดไปขั้นใดก็ได้ใน 14 ขั้น

window.renderPanel = function (s) {
  const D = window.UNBOX;
  const el = document.getElementById('panel');
  if (!s.devPanel) { el.innerHTML = '<button class="pn-toggle" data-act="panel:toggle">⚙︎ state</button>'; return; }

  const opt = (list, cur) => list.map(o => `<option value="${o.key}" ${o.key === cur ? 'selected' : ''}>${o.label || o.key}</option>`).join('');
  const chk = (id, label, on) => `<label class="pn-chk"><input type="checkbox" data-flag="${id}" ${on ? 'checked' : ''}><span>${label}</span></label>`;

  const stepIdx = currentStep(s);
  const isNew = s.flow === 'new';
  const steps = isNew ? D.NEW_STEPS : D.STEPS;

  if (isNew) {
    const stage = window.stageOf ? window.stageOf(s) : 0;
    const c = D.CAMPAIGNS.find(x => x.slug === s.campaignSlug) || D.CAMPAIGNS[0];
    const hasData = k => k === 'kyc' ? s.user.verify === 'approved' : !!s.profile[k];
    el.innerHTML = `
    <div class="pn-head"><b>Unbox × StarCard</b><span class="pn-sub">happy case · flow ใหม่</span><button class="pn-x" data-act="panel:toggle" title="ซ่อน">×</button></div>
    <section><h4>flow</h4><div class="pn-flow"><button data-flow="old">Unbox เดิม</button><button class="on" data-flow="new">ใหม่ · แทรก StarCard</button></div></section>
    <section>
      <h4>State ของ Unbox <small>กดเพื่อไป · ขั้นก่อนหน้าติ๊กข้อมูลให้เอง</small></h4>
      <ol class="pn-steps">${window.STAGES.map((st, i) => `<li class="${i === stage ? 'on' : ''} ${i < stage ? 'done' : ''} ${st.t.startsWith('แทรก') || st.t.includes('→ แทรก') ? 'insert' : ''}" data-stage="${i}"><span class="ph">${st.t.includes('แทรก') ? 'แทรก' : 'เดิม'}</span><span class="n">${i}</span><span class="t">${st.t}</span></li>`).join('')}</ol>
    </section>
    <section>
      <h4>ข้อมูลใน Star Profile <small>ติ๊กออก = ย้อน state กลับไปขั้นที่ขอ</small></h4>
      <div class="pn-level">Star Card: <b>${window.hasStarCard && window.hasStarCard(s) ? 'มีแล้ว (เป็น STAR)' : 'ยังไม่มี'}</b> · กิจกรรม <b>${c.ep}</b></div>
      ${window.DATA_RULES.map(r => { const applies = true; return `<label class="pn-chk pn-pf ${applies ? '' : 'na'}"><input type="checkbox" data-tick="${r.key}" ${hasData(r.key) ? 'checked' : ''} ${applies ? '' : 'disabled'}><span>${r.label}</span><small>ขอที่ขั้น ${r.askAt}${applies ? '' : (r.need === 'fee' ? ' · งานนี้ไม่มีค่าตัว' : ' · งานนี้ไม่ใช้')}</small></label>`; }).join('')}
      <div class="pn-actions"><button data-act="pfAll">มีครบ</button><button data-act="pfNone">ไม่มีเลย</button></div>
    </section>
    <section>
      <h4>กิจกรรม</h4>
      <label>กิจกรรม<select data-set="campaignSlug">${D.CAMPAIGNS.map(x => `<option value="${x.slug}" ${x.slug === s.campaignSlug ? 'selected' : ''}>${x.ep} ${x.brand} · ${x.needs.measurements ? 'ขอสัดส่วน ' : ''}${x.needs.province ? 'ลงพื้นที่ ' : ''}${x.needs.video ? 'ขอวิดีโอ' : ''}</option>`).join('')}</select></label>
      <div class="pn-actions"><button data-act="copyLink">คัดลอกลิงก์ state นี้</button><button data-act="reset">รีเซ็ต</button></div>
    </section>`;
    return;
  }

  el.innerHTML = `
    <div class="pn-head">
      <b>Unbox flow · state</b>
      <span class="pn-sub">salehere-ios 2.114 · mock</span>
      <button class="pn-x" data-act="panel:toggle" title="ซ่อน">×</button>
    </div>

    <section>
      <h4>flow</h4>
      <div class="pn-flow"><button class="${!isNew ? 'on' : ''}" data-flow="old">Unbox เดิม</button><button class="${isNew ? 'on' : ''}" data-flow="new">ใหม่ · แทรก StarCard</button></div>
    </section>

    ${isNew ? `<section>
      <h4>ข้อมูลใน Star Profile <small>มี = เติมให้/ข้าม · ไม่มี = ถามตรงขั้นที่ใช้</small></h4>
      ${D.PROFILE_FIELDS.map(f => `<label class="pn-chk pn-pf"><input type="checkbox" data-flag="profile.${f.key}" ${s.profile[f.key] ? 'checked' : ''}><span>${f.label}</span><small>${f.step}</small></label>`).join('')}
      <div class="pn-actions"><button data-act="pfAll">มีครบ</button><button data-act="pfNone">ไม่มีเลย</button><button data-act="pfL1">แค่มีการ์ด</button></div>
    </section>` : ''}

    <section>
      <h4>${isNew ? 'ขั้นของ flow ใหม่' : 'ขั้นทั้ง 14'} <small>กดเพื่อกระโดด</small></h4>
      <ol class="pn-steps">
        ${steps.map((st, i) => `<li class="${i === stepIdx ? 'on' : ''} ${i < stepIdx ? 'done' : ''} ${isNew && String(st.t).includes('เหมือนเดิม') ? 'same' : ''}" data-step="${i}"><span class="ph">${st.phase}</span><span class="n">${st.n}</span><span class="t">${st.t}</span></li>`).join('')}
      </ol>
    </section>

    <section>
      <h4>ฉากสำเร็จรูป</h4>
      <div class="pn-presets">${(isNew ? D.NEW_PRESETS : D.PRESETS).map(p => `<button data-preset="${p.key}">${p.label}</button>`).join('')}</div>
    </section>

    <section>
      <h4>กิจกรรม</h4>
      <label>BrandCampaignState<select data-set="campaign">${opt(D.CAMPAIGN_STATES, s.campaign)}</select></label>
      <label>BrandCampaignReviewState<select data-set="review">${opt(D.REVIEW_STATES, s.review)}</select></label>
      <label>OrderStatus<select data-set="order">${opt(D.ORDER_STATUSES, s.order)}</select></label>
      <label>QuotaType<select data-set="quota">${opt(D.QUOTA_TYPES, s.quota)}</select></label>
      <label>กิจกรรม<select data-set="campaignSlug">${D.CAMPAIGNS.map(c => `<option value="${c.slug}" ${c.slug === s.campaignSlug ? 'selected' : ''}>${c.ep} ${c.brand}</option>`).join('')}</select></label>
      ${chk('won', 'ประกาศผล: ได้รับเลือก', s.won)}
      ${chk('briefRead', 'อ่านรายละเอียดการรีวิวแล้ว', s.briefRead)}
      ${chk('reviewTab', 'เปิดแท็บ "รีวิว"', s.reviewTab)}
    </section>

    <section>
      <h4>ผู้ใช้</h4>
      ${chk('user.isLogin', 'ล็อกอินแล้ว', s.user.isLogin)}
      <div class="pn-row3">
        ${chk('user.welcome.0', 'ผูกโซเชียล', s.user.welcome[0])}
        ${chk('user.welcome.1', 'เลือกหมวด', s.user.welcome[1])}
        ${chk('user.welcome.2', 'ยืนยันตัวตน (ขั้น 3)', s.user.welcome[2])}
      </div>
      <label>โปรไฟล์ครีเอเตอร์ <b>${s.user.percent}%</b><input type="range" min="0" max="100" step="17" value="${s.user.percent}" data-set="user.percent"></label>
      <label>UserVerifyStatus (KYC)<select data-set="user.verify">${opt(D.VERIFY_STATUSES, s.user.verify)}</select></label>
      <label>PunishmentStatus<select data-set="user.punishment">${opt(D.PUNISHMENTS, s.user.punishment)}</select></label>
      <label>BrandCampaignReviewStatus<select data-set="user.reviewStatus">${opt(D.REVIEW_STATUSES, s.user.reviewStatus)}</select></label>
      <label>ผล AI ตรวจบัตร (KYC)<select data-set="kyc.aiResult">
        <option value="pass" ${s.kyc.aiResult === 'pass' ? 'selected' : ''}>ผ่าน (ID_CARD_VERIFIED)</option>
        <option value="notClear" ${s.kyc.aiResult === 'notClear' ? 'selected' : ''}>ไม่ชัด (ID_CARD_NOT_CLEAR)</option>
        <option value="faceMismatch" ${s.kyc.aiResult === 'faceMismatch' ? 'selected' : ''}>หน้าไม่ตรง (ID_CARD_FACE_MISMATCH)</option>
        <option value="expired" ${s.kyc.aiResult === 'expired' ? 'selected' : ''}>บัตรหมดอายุ</option>
        <option value="exist" ${s.kyc.aiResult === 'exist' ? 'selected' : ''}>บัตรถูกใช้แล้ว</option>
      </select></label>
      <div class="pn-sub">พยายาม KYC ล้มเหลวแล้ว ${s.kyc.fails} ครั้ง (ครบ 3 → คนตรวจ)</div>
    </section>

    <section>
      <h4>หน้าจอ</h4>
      <label>screen<select data-set="screen">${['fillProfile', 'cardReveal', 'fillAccept', 'home', 'campaign', 'register', 'accept', 'brief', 'draft', 'verdict', 'preview', 'link', 'myCampaigns', 'awardList', 'kyc', 'onboarding', 'onboardingSteps', 'profileHub', 'profile', 'post', 'chat', 'login'].map(k => `<option ${k === s.screen ? 'selected' : ''}>${k}</option>`).join('')}</select></label>
      <div class="pn-actions">
        <button data-act="copyLink">คัดลอกลิงก์ state นี้</button>
        <button data-act="reset">รีเซ็ต</button>
      </div>
    </section>
  `;
};

/// ขั้นปัจจุบัน (0-based) — เดาจาก state เพื่อไฮไลต์ในแผง
window.currentStep = function (s) {
  const c = s.campaign, r = s.review;
  if (s.flow === 'new') {
    const m = { fillProfile: 1, cardReveal: 2, register: 3, fillAccept: 6, accept: 7, draft: 9, link: 10 };
    if (m[s.screen] != null) return m[s.screen];
    if (s.dialog === 'registerSuccess' || s.screen === 'kyc') return 4;
    if (r === 'reviewed') return 11;
    if (r !== 'none' && r !== 'notOpenDraft') return 9;
    if (c === 'acceptedQuota') return 8;
    if (c === 'waitingAcceptQuota') return 6;
    if (c === 'registered') return 5;
    return 0;
  }
  if (s.screen === 'myCampaigns') return 13;
  if (r === 'reviewed') return 12;
  if (r === 'waitingReview' || r === 'notOpenReview' || s.screen === 'link') return 11;
  if (r === 'rejectDraft' || r === 'waitingApproveDraft' || s.screen === 'verdict' || s.screen === 'preview') return 10;
  if (s.screen === 'draft' || r === 'draft') return 9;
  if (s.screen === 'brief' || (r === 'waitingDraft' && s.briefRead)) return 8;
  if (r === 'waitingDraft') return 8;
  if (c === 'acceptedQuota') return 7;
  if (c === 'forceVerifyUser') return 6;
  if (c === 'waitingAcceptQuota' || s.screen === 'accept') return 5;
  if (c === 'registered' && s.dialog === 'registerSuccess') return 3;
  if (c === 'registered' || c === 'awardAnnouncement') return 4;
  if (s.screen === 'register') return 2;
  if (['onboarding', 'onboardingSteps', 'profileHub', 'login'].includes(s.screen) || s.dialog === 'punish') return 1;
  return 0;
};

window.bindPanel = function () {
  const el = document.getElementById('panel');
  el.addEventListener('change', e => {
    const t = e.target;
    if (t.dataset.set) {
      const v = t.type === 'range' ? Number(t.value) : t.value;
      Store.set(pathPatch(t.dataset.set, v));
    } else if (t.dataset.flag) {
      Store.set(pathPatch(t.dataset.flag, t.checked));
    } else if (t.dataset.tick) {
      ACTIONS.tickData(t.dataset.tick, t.checked);
    }
  });
  el.addEventListener('click', e => {
    const b = e.target.closest('[data-act],[data-preset],[data-step],[data-flow],[data-stage]');
    if (!b) return;
    if (b.dataset.flow) { Store.set({ flow: b.dataset.flow, screen: 'campaign', dialog: null, sheet: null }); return; }
    if (b.dataset.act === 'pfAll' || b.dataset.act === 'pfNone' || b.dataset.act === 'pfL1') {
      const v = b.dataset.act === 'pfAll'; const pf = {};
      UNBOX.PROFILE_FIELDS.forEach(f => { pf[f.key] = b.dataset.act === 'pfL1' ? f.level === 1 : v; });
      if (Store.get().flow === 'new' && !v) { Store.set({ profile: pf, user: { verify: 'none' } }); ACTIONS.gotoStage({ i: 0 }); return; }
      Store.set({ profile: pf, user: v ? { verify: 'approved' } : {} }); return;
    }
    if (b.dataset.stage != null) { ACTIONS.gotoStage({ i: b.dataset.stage }); return; }
    if (b.dataset.act === 'panel:toggle') Store.set({ devPanel: !Store.get().devPanel });
    if (b.dataset.act === 'reset') Store.reset();
    if (b.dataset.act === 'copyLink') { navigator.clipboard?.writeText(location.href); Store.toast('คัดลอกลิงก์แล้ว'); }
    if (b.dataset.preset) { const p = UNBOX.PRESETS.concat(UNBOX.NEW_PRESETS).find(x => x.key === b.dataset.preset); Store.applyScenario(p); }
    if (b.dataset.step) { const st = (Store.get().flow === 'new' ? UNBOX.NEW_STEPS : UNBOX.STEPS)[Number(b.dataset.step)]; Store.applyScenario(st); }
  });
};

function pathPatch(path, value) {
  // 'user.welcome.0' → { user: { welcome: [..with index set..] } } — array ต้อง copy ทั้งก้อน
  const parts = path.split('.');
  const s = Store.get();
  if (parts[0] === 'profile' && parts.length === 2) return { profile: { [parts[1]]: value } };
  if (parts.length === 3 && parts[1] === 'welcome') {
    const arr = s.user.welcome.slice(); arr[Number(parts[2])] = value;
    return { user: { welcome: arr } };
  }
  const out = {}; let cur = out;
  parts.forEach((p, i) => { if (i === parts.length - 1) cur[p] = value; else { cur[p] = {}; cur = cur[p]; } });
  return out;
}
