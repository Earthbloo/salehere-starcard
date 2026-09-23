// หน้าจอทั้งหมด + dialog/sheet + ACTIONS — layout/copy ตาม salehere-ios (UnboxInfo · UnboxRegister · UnboxAcceptingDetail · ReviewShopping · TopicPreview · DraftVerdict · ApproveLink · UserBrandCampaign · VerifyUser)

(function () {
  const D = window.UNBOX, U = window.UI, I = window.icon, A = U.A;
  const S = window.SCREENS = {};
  const Ac = window.ACTIONS = {};

  const cur = s => D.CAMPAIGNS.find(c => c.slug === s.campaignSlug) || D.CAMPAIGNS[0];
  const cstate = s => D.CAMPAIGN_STATES.find(x => x.key === s.campaign);
  const rstate = s => D.REVIEW_STATES.find(x => x.key === s.review);
  const ostate = s => D.ORDER_STATUSES.find(x => x.key === s.order);
  const isVerified = s => s.user.verify === 'approved';
  const welcomeDone = s => s.user.welcome.every(Boolean);

  // นาฬิกาถอยหลัง: ตรึงเส้นตายไว้ตอนโหลดหน้า (14:59:48 เหมือน screenshot)
  const DEADLINE = Date.now() + (14 * 3600 + 59 * 60 + 48) * 1000;
  const left = () => Math.max(0, Math.floor((DEADLINE - Date.now()) / 1000));

  // ---------- tab bar (HomePage: 5 แท็บ 65pt · ไอคอน 24 · label 12 Medium · active แดง) ----------
  function tabbar(active) {
    const t = (k, ic, icOn, lb, go) => `<button class="tab ${active === k ? 'on' : ''}" data-go="${go}">${A(active === k ? icOn : ic, 24)}<span>${lb}</span></button>`;
    return `<nav class="tabbar">
      ${t('community', 'ic-homepage-community', 'ic-homepage-community-active', 'คอมมูนิตี้', 'home')}
      ${t('article', 'ic-bookopentext-outline', 'ic-bookopentext-outline-active', 'บทความ', 'home')}
      <button class="tab tab-star ${active === 'home' ? 'on' : ''}" data-go="home">${A(active === 'home' ? 'ic-salehere-star-outline-active' : 'ic-salehere-star-outline')}<span>หน้าแรก</span></button>
      ${t('promo', 'ic-sealpercent-outline', 'ic-sealpercent-outline-active', 'หาโปร', 'home')}
      <button class="tab ${active === 'profile' ? 'on' : ''}" data-go="profile"><img class="tab-ava" src="${D.USER.avatar}"><span>โปรไฟล์</span></button>
    </nav><div class="tab-safe"></div>`;
  }

  // ---------- การ์ดกิจกรรม (UnboxListCollectionViewCell 175×250 · BrandCampaignCardStatus) ----------
  function cardStatus(c, s) {
    if (c.slug === s.campaignSlug) {
      const k = s.campaign;
      if (k === 'notOpenRegister') return ['ยังไม่เปิดลงทะเบียน', 'graydis', 'ic-Time', false];
      if (k === 'register') return ['ลงทะเบียนร่วมกิจกรรม', 'red', 'ic-draft-reject-button-20', true];
      if (k === 'registered') return ['คุณได้ลงทะเบียนแล้ว', 'outline-star', 'ic-sent-review-unbox-success-green-20', false];
      if (k === 'expire' || k === 'maxRegister') return ['หมดเวลาลงทะเบียน', 'graydis', 'ic-Time', false];
      return ['สิ้นสุดเวลากิจกรรม', 'graydis', 'ic-Time', false];
    }
    return c.slug === 'terminal21-1571' ? ['หมดเวลาลงทะเบียน', 'graydis', 'ic-Time', false] : ['ลงทะเบียนร่วมกิจกรรม', 'red', 'ic-draft-reject-button-20', true];
  }
  function campaignCard(c, s) {
    const [label, style, icon, live] = cardStatus(c, s);
    return `<div class="ccard" data-do="openCampaign" data-slug="${c.slug}">
      <div class="ccard-img"><img src="${c.cover}"></div>
      <div class="ccard-body">
        <div class="ccard-title"><img class="ccard-logo" src="${c.logo}"><span>${c.ep} ${c.title}</span></div>
        <div class="ccard-date">${A('ic-calendar-gray14', 14)}<span>${c.dateRange}</span></div>
        ${U.btn(label, { style, icon, iconSize: 16, size: 'sm', enabled: live, act: live ? 'cardRegister' : 'openCampaign', extra: `data-slug="${c.slug}"` })}
      </div></div>`;
  }

  // ================= หน้าแรก (MainPage · section Sale Here STAR) =================
  S.home = s => `
    <header class="nav-red nav-home"><div class="nav-l">${A('ic-salehere-logo-red42', 32, 'logo-ring')}</div><div class="nav-t">Sale Here STAR</div><div class="nav-r"><button class="nav-btn">${A('btn-chat', 32)}</button><button class="nav-btn">${A('btn-alert', 32)}</button></div></header>
    <div class="scroll page-white">
      <div class="home-banner"><img src="assets/cover-wonder.png"></div>
      ${s.user.isLogin && !welcomeDone(s) ? `<div class="wel-card" data-do="openSheet" data-sheet="steps"><div><b>ทำโปรไฟล์ให้สมบูรณ์กันเถอะ</b><p>เพื่อโอกาสรับงานรีวิวจากแบรนด์<br>หลากหลาย ที่ Sale Here STAR</p></div><span class="chip-red">เข้าร่วม</span></div>` : ''}
      ${s.user.isLogin && welcomeDone(s) && s.user.percent < 100 ? `<div class="wel-card" data-go="profileHub"><div><b>สร้างโปรไฟล์ครีเอเตอร์กันเถอะ !</b><p>เพื่อเพิ่มโอกาสในการรับงานรีวิวจาก<br>แบรนด์</p></div><span class="chip-red">ทำเลย</span></div>` : ''}
      ${s.user.isLogin && welcomeDone(s) && s.user.percent === 100 ? `<div class="wel-card" data-do="openSheet" data-sheet="starDetail"><div><b>ยินดีด้วยโปรไฟล์ผ่านแล้ว</b><p>ดูข้อมูล STAR ของคุณได้ที่นี่</p></div><span class="chip-red">ดู</span></div>` : ''}
      <div class="home-title"><div class="lottie" data-anim="home_title_sale_here_star" style="width:210px;height:46px"></div><button class="seeall" data-go="home">ดูทั้งหมด ${I('caret-right', 12)}</button></div>
      <div class="hscroll">${D.CAMPAIGNS.map(c => campaignCard(c, s)).join('')}</div>
      <div class="sec-tips"><div class="sec-star-head"><span class="sec-h">STAR Tips</span><button class="seeall">ดูทั้งหมด ${I('caret-right', 12)}</button></div>
        <div class="hscroll">${['ตั้งเรทยังไงให้แบรนด์เลือก', 'ส่งดราฟต์ให้ผ่านรอบเดียว', 'ถ่ายรูปสินค้าให้ปัง'].map((t, i) => `<div class="tip"><img src="assets/ph0${i + 2}.jpg"><span>${t}</span></div>`).join('')}</div></div>
    </div>
    ${tabbar('home')}`;

  // ================= โปรไฟล์ (MyProfile) =================
  S.profile = s => `
    <header class="nav-red"><div class="nav-l">${A('ic-salehere-logo-red42', 32, 'logo-ring')}</div><div class="nav-t">${D.USER.username}</div><div class="nav-r"><button class="nav-btn">${A('btn-chat', 32)}</button><button class="nav-btn">${I('list', 26)}</button></div></header>
    <div class="scroll page-gray">
      <div class="pf-cover"><span class="pf-cam">${I('camera', 18)}</span></div>
      <div class="pf-head">
        <div class="pf-ava"><img src="${D.USER.avatar}"><span class="pf-star">★</span><span class="pf-qr">${I('qr-code', 18)}</span></div>
        <div class="pf-name">${isVerified(s) ? `<span class="verified-blue">${I('seal-check', 18, 'fill')}</span>` : ''}<b>${D.USER.username}</b><button class="pf-share">${I('share-fat', 18)}</button></div>
        <p class="pf-bio">ชอบพาไปเที่ยว ทานอาหารอร่อยๆ แวะจิบกาแฟที่ร้านคาเฟ่น่ารักๆ</p>
      </div>
      <div class="pf-stats"><div><b>0</b><span>ผู้ติดตาม</span></div><div><b>0</b><span>กำลังติดตาม</span></div><div><b>5</b><span>โพสต์</span></div><div><b>7</b><span>Engagement</span></div></div>
      <div class="pf-btns"><button class="btn btn-outline btn-md">${I('pencil-simple', 18)}<span>แก้ไขโปรไฟล์</span></button><button class="btn btn-outline btn-md" data-do="creatorProfile">${A('ic-identificationBadge-outline', 20)}<span>โปรไฟล์ครีเอเตอร์</span></button></div>
      <div class="pf-tiles">
        <div class="pf-tile"><span class="pf-tile-ic blue">${I('ticket', 22, 'fill')}</span><div><b class="blue">Coupon</b><span>เก็บคูปอง</span></div></div>
        <div class="pf-tile" data-go="myCampaigns"><span class="pf-tile-ic red">${A('ic-salehere-star-outline-active', 28)}</span><div><b class="red">Sale Here STAR</b><span>${D.USER.campaignCount} กิจกรรม</span></div></div>
        <div class="pf-tile"><span class="pf-tile-ic gold">${A('ic-star-point-16', 22)}</span><div><b class="gold">STAR Rewards</b><span>${D.USER.starPoints.toLocaleString()} Points</span></div></div>
      </div>
      ${!welcomeDone(s) ? `<div class="wel-card" data-do="openSheet" data-sheet="steps"><div><b>ทำโปรไฟล์ให้สมบูรณ์กันเถอะ</b><p>เพื่อโอกาสรับงานรีวิวจากแบรนด์<br>หลากหลาย ที่ Sale Here STAR</p></div><span class="chip-red">เข้าร่วม</span></div>` : ''}
      ${verifyCard(s)}
      <div class="pf-composer"><img src="${D.USER.avatar}"><span>สวัสดีค่ะ คุณ ${D.USER.username}, โพสต์บอกเล่าประสบการณ์ หรือรีวิวกิจกรรมของคุณ</span>${I('image-square', 22)}</div>
      ${['waitingApproveDraft', 'rejectDraft', 'draft'].includes(s.review) ? `<div class="draft-banner" data-do="reviewAction" data-a="preview"><span class="db-ic">${I('note-pencil', 20, 'fill')}</span><b>สถานะดราฟต์รีวิว</b></div>` : ''}
      <div class="pf-feedtabs"><span class="on">${I('squares-four', 22)}</span><span>${I('list', 22)}</span><span>${I('at', 22)}</span></div>
      <div class="pf-grid"><img src="assets/ph01.jpg"><img src="assets/ph02.jpg"><img src="assets/ph03.jpg"><img src="assets/ph04.jpg"><img src="assets/cover-thymora.png"><img src="assets/ph02.jpg"></div>
    </div>
    ${tabbar('profile')}`;

  /// VerifyUserStatusView: การ์ดเส้นประ 4 สถานะ
  function verifyCard(s) {
    const v = s.user.verify;
    const body = v === 'approved' ? `<div class="vc-t">เราได้รับข้อมูลการยืนยันตัวตนแล้ว</div><div class="vc-s st">สถานะ : <b class="ok">ยืนยันตัวตนแล้ว</b></div>`
      : v === 'waiting_approve' ? `<div class="vc-t">เราได้รับข้อมูลการยืนยันตัวตนแล้ว</div><div class="vc-s st">สถานะ : <b class="amber">รอพิจารณา</b></div>`
      : v === 'reject' ? `<div class="vc-t">เราได้รับข้อมูลการยืนยันตัวตนแล้ว</div><div class="vc-s st">สถานะ : <b class="red">ไม่ผ่านการอนุมัติ</b></div>`
      : `<div class="vc-t">คุณยังไม่ได้ยืนยันตัวตน</div><div class="vc-s">ยืนยันตัวตนเพื่อรับสิทธิพิเศษที่มากกว่า</div><span class="vc-btn">ยืนยันตัวตน ${A('ic-arrow-right-white12', 12)}</span>`;
    const reject = v === 'reject' ? `<div class="vc-r">${A('ic-xcircle-outline', 16)}<span>กรุณาทำรายการใหม่อีกครั้ง เนื่องจากรูปบัตรประชาชนไม่ตรงกัน</span></div>` : '';
    return `<div class="verify-card v-${v}" data-do="openKyc"><img class="thumb" src="assets/ic/ic-face-thaiid-correct.png"><div class="vc">${body}${reject}</div>${v !== 'none' && v !== 'approved' ? A('ic-arrow-right-gray18v2', 18) : ''}</div>`;
  }

  // ================= หน้ากิจกรรม (UnboxInfo) =================
  S.campaign = s => {
    const c = cur(s);
    return `${U.navRed('Sale Here STAR', { back: 'home' })}
    <div class="scroll page-white">
      <div class="cp-cover"><img src="${c.cover}"></div>
      <div class="cp-title"><img class="cp-logo" src="${c.logo}"><h2>${c.ep} ${c.title}</h2></div>
      <div class="cp-date"><span>${A('ic-calendar-gray14', 14)} ${c.dateRange}</span><button class="btn-share" data-do="share">แชร์ ${A('ic-share-red20', 20)}</button></div>
      <div class="cp-sep"></div>
      <div class="cp-tabs"><button class="${!s.reviewTab ? 'on' : ''}" data-do="tab" data-tab="detail">${A('ic-clipboard-text-gray', 20)} วิธีการร่วมกิจกรรม</button><button class="${s.reviewTab ? 'on' : ''}" data-do="tab" data-tab="review">${A('ic-file-hart-gray', 20)} รีวิว</button></div>
      ${s.reviewTab ? reviewTab(s, c) : `<div class="cp-body">${c.howTo}
        <div class="cp-reward"><b>ของรางวัล</b><span>${c.reward}</span><b>จำนวนสิทธิ์</b><span>${c.quota} สิทธิ์ · ลงทะเบียนแล้ว ${c.registered} คน</span></div>
        <div class="cp-timeline"><b>Timeline แคมเปญ</b>${c.timeline.map(t => `<div><span>${t.k}</span><span>${t.v}</span></div>`).join('')}</div>
      </div>`}
    </div>
    ${s.reviewTab ? reviewBar(s) : mainBar(s)}`;
  };

  // ปุ่มล่างตาม BrandCampaignState (ไอคอน · สี · คำอธิบาย · นาฬิกา) — ค่าตรงกับ BrandCampaignState.swift
  const MAIN_ICON = { notOpenRegister: 'ic-Time', register: 'ic-draft-reject-button-20', maxRegister: 'ic-Button-MaxRegister', registered: 'ic-sent-review-unbox-success-green-20', expire: 'ic-Time', waitingAcceptQuota: 'ic-gift-whites-16', rejectQuotaByUser: 'ic-reject', rejectQuotaByExpire: 'ic-reject', rejectQuotaByAdmin: 'ic-reject', forceVerifyUser: 'ic-draft-reject-button-20', awardAnnouncement: 'ic_personCheck', acceptedQuota: 'ic-review-detail' };
  const STYLE = { red: 'red', gray: 'graydis', green: 'green', outline: 'red' };
  function mainBar(s) {
    const st = cstate(s);
    let desc = st.desc, descCls = '', descIcon = 'ic-calendar-gray14', icon = MAIN_ICON[st.key], style = STYLE[st.style] || st.style, title = st.button;
    if (['rejectQuotaByUser', 'rejectQuotaByExpire', 'rejectQuotaByAdmin'].includes(st.key)) { style = 'reddis'; descIcon = 'ic-gift-gray'; }
    if (st.key === 'rejectQuotaByAdmin') { descCls = 'link'; descIcon = 'ic-info-blue'; }
    if (st.key === 'forceVerifyUser') { descCls = 'red'; descIcon = 'ic_personCheck_red'; }
    if (st.key === 'awardAnnouncement') { descIcon = 'ic-gift-gray'; }
    if (st.key === 'notOpenRegister') desc = 'ลงทะเบียนได้ในอีก 3 วัน';
    if (st.key === 'acceptedQuota') {
      const o = ostate(s);
      desc = o.key === 'paid' ? `${o.label} 3 ต.ค. 69` : o.label; descCls = 'ink'; descIcon = o.key === 'shipping' ? 'ic_status_shipped' : 'ic_gfit_box';
      if (o.key === 'parcelReject') { title = 'ติดต่อผู้ช่วยส่วนตัว'; icon = 'ic-calling-assistant-button-18x16'; descCls = 'red4'; }
      if (o.key === 'shipping') { desc = 'เช็กเลขติดตามพัสดุ'; descCls = 'link'; }
    }
    const top = st.clock
      ? `<div class="bar-clock">${A('ic-calendar-gray14', 14)}<span>${desc}</span>${U.clock(left())}</div>`
      : `<div class="bar-desc ${descCls}" ${st.key === 'rejectQuotaByAdmin' ? 'data-do="rejectReason"' : ''}>${A(descIcon, 14)}<span>${desc}</span></div>`;
    return bar(top, U.btn(title, { style, enabled: st.enabled, act: 'tapMain', icon, iconSize: 20 }));
  }
  const REV_ICON = { brief: 'ic-brief-button-20', createDraft: 'ic-create-new-draft-20', editDraft: 'ic-draft-reject-button-20', preview: 'ic-checking-draft-button-orange-20', verdict: 'ic-draft-reject-button-20', link: 'ic-send-link-button-20', chat: 'ic-calling-assistant-button-18x16', post: 'ic-show-post-unbox-button-white-20' };
  function reviewBar(s) {
    const r = rstate(s);
    if (!r.buttons.length) return bar(`<div class="bar-desc">ยังไม่ถึงขั้นตอนรีวิว</div>`, '');
    let desc = r.desc.replace('{days}', '5'), descCls = r.key.startsWith('expire') ? 'red4' : r.key === 'reviewed' ? 'green' : '';
    const top = r.clock ? `<div class="bar-clock">${A('ic-calendar-gray14', 14)}<span>${desc}</span>${U.clock(left())}</div>` : `<div class="bar-desc ${descCls}">${A(r.key === 'forceVerifyUser' ? 'ic_personCheck_red' : r.key === 'waitingVerifyUser' ? 'ic-Time' : 'ic-calendar-gray14', 14)}<span>${desc}</span></div>`;
    const btns = r.buttons.map(b => U.btn(b.t.replace('{date}', '5 ต.ค. 69 เวลา 09:00'), { style: STYLE[b.s] === 'red' && !b.e ? 'graydis' : b.s === 'gray' ? 'graydis' : b.s === 'outline' ? 'gray' : STYLE[b.s] || b.s, enabled: b.e, act: 'reviewAction', extra: `data-a="${b.a || ''}"`, icon: b.a ? REV_ICON[b.a] : (b.s === 'green' ? 'ic-draft-reject-button-20' : b.s === 'gray' ? 'ic-Time' : null) })).join('');
    return bar(top, `<div class="bar-btns ${r.buttons.length > 1 ? 'two' : ''}">${btns}</div>`);
  }
  function bar(top, btn) { return `<div class="bottombar">${top}${btn}</div>`; }

  function reviewTab(s, c) {
    if (!c.posts.length) return `<div class="empty">${A('ic-review-empty-gray', 72)}<p>ไม่มีโพสต์รีวิว</p></div>`;
    return `<div class="posts">${c.posts.map(p => `<div class="post"><div class="post-h"><img src="${p.avatar}"><b>${p.user}</b><span class="star-badge">★</span><small>2 วันที่แล้ว</small></div><img class="post-img" src="${p.img}"><div class="post-t">${p.title}</div><div class="post-m">${I('heart', 14)} ${p.likes} · ${I('chat-circle', 14)} ${p.comments}</div></div>`).join('')}</div>`;
  }

  // ================= ฟอร์มสมัคร (UnboxRegister) =================
  S.register = s => {
    const c = cur(s), u = D.USER, a = u.address, f = s.form || {};
    return `${U.navRed('ลงทะเบียนร่วมกิจกรรม', { back: 'campaign', right: 'none', close: true })}
    <div class="scroll page-white form">
      ${U.sectionHdr('ข้อมูลที่อยู่')}
      <div style="padding:16px 0 8px">
      ${U.field({ label: 'ชื่อ - นามสกุล', req: true, value: a.name, bind: 'form.name', placeholder: 'กรอกชื่อ - นามสกุล' })}
      ${U.field({ label: 'เบอร์โทรศัพท์', req: true, value: a.tel, bind: 'form.tel', type: 'tel', placeholder: 'กรอกเบอร์โทรศัพท์' })}
      ${U.field({ label: 'รายละเอียดที่อยู่', req: true, value: a.address, bind: 'form.address', multiline: true, placeholder: 'กรอกบ้านเลขที่, ชื่อหมู่บ้าน, ห้อง, ชั้น, ถนน, ซอย' })}
      ${U.field({ label: 'รหัสไปรษณีย์', req: true, value: a.zipcode, bind: 'form.zip', type: 'tel', placeholder: 'กรอกรหัสไปรษณีย์' })}
      ${U.field({ label: 'ตำบล/แขวง', req: true, value: a.subDistrict, select: true, placeholder: 'เลือกตำบล/แขวง' })}
      ${U.field({ label: 'อำเภอ/เขต', req: true, value: a.district, disabled: true })}
      ${U.field({ label: 'จังหวัด', req: true, value: a.province, disabled: true })}
      </div>
      ${c.questions.length ? U.sectionHdr('คำถาม') + `<div style="padding:16px 0 0">${c.questions.map((q, i) => question(q, i, f)).join('')}</div>` : ''}
      ${U.sectionHdr('โซเชียลมีเดีย')}
      <div style="padding:8px 0 0">
      <div class="soc-note"><div><em>* </em>ลิงก์โซเชียลมีเดียที่ต้องการลงทะเบียน<br><span>(ผูกบัญชีอย่างน้อย 1 ช่องทางเพื่อส่งรีวิว)</span></div><button class="btn btn-xs" data-do="openSheet" data-sheet="socialConnect">เพิ่ม/แก้ไขบัญชี</button></div>
      ${u.socials.map(so => socialCard(so)).join('')}
      <label class="consent ${s.user.consent ? 'on' : ''}"><input type="checkbox" data-bind="user.consent" ${s.user.consent ? 'checked' : ''}><i></i><b>ฉันยอมรับข้อกำหนดและเงื่อนไข</b><p>ฉันยินยอมที่จะโพสต์รีวิวสินค้า และ เปิดเป็นสาธารณะ ตามช่องทางโซเชียลมีเดียที่ลงทะเบียนไว้ภายหลังจากได้ รับกล่อง Unbox หากไม่ได้รีวิวตามเวลาที่กำหนด ฉันจะถูกตัดสิทธิ์และไม่สามารถลงทะเบียนเข้าร่วมกิจกรรม ‘Sale Here UNBOX’ ได้อีกในครั้งต่อไป</p></label>
      </div>
    </div>
    <div class="bottombar"><div style="padding-top:8px">${U.btn('ลงทะเบียนร่วมกิจกรรม', { enabled: s.user.consent, act: 'submitRegister', icon: s.user.consent ? 'ic-draft-reject-button-20' : 'ic-draft-reject-button-20-gray' })}</div></div>`;
  };
  function question(q, i, f) {
    const k = `form.q${i}`;
    if (q.type === 'text') return `<div class="q"><div class="q-t"><em>*</em>${q.q}</div>${U.field({ value: f['q' + i] || '', bind: k, placeholder: 'กรอกคำตอบ', multiline: true })}</div>`;
    if (q.type === 'radio') return `<div class="q"><div class="q-t"><em>*</em>${q.q}</div>${U.field({ value: f['q' + i] || '', bind: k, placeholder: 'เลือกคำตอบ', select: true })}</div>`;
    if (q.type === 'checkbox') return `<div class="q"><div class="q-t"><em>*</em>${q.q}</div><div class="q-h">เลือกได้มากกว่า 1 ตัวเลือก</div>${U.checks(q.options, f['q' + i] || [], k)}</div>`;
    return `<div class="q"><div class="q-t"><em>*</em>${q.q}</div><div class="upl">${(f['q' + i] || []).map(src => `<div class="upl-img"><img src="${src}"></div>`).join('')}<button class="upl-add" data-do="mockUpload" data-k="${k}"></button></div></div>`;
  }
  function socialCard(so) {
    const m = D.SOCIAL_META[so.type];
    const insight = so.connected && ['facebook', 'instagram', 'tiktok', 'youtube'].includes(so.type)
      ? `<div class="soc-ins"><div class="ins-col"><div class="ins-title">ข้อมูลผู้ติดตาม ${so.insight >= 3 ? `<span class="ins-chip ok">${I('check-circle', 16, 'fill')}</span>` : `<span class="ins-chip ${so.insight > 0 ? 'amber' : ''}">${so.insight}/3</span>`}</div><div class="ins-t ${so.insight > 0 && so.insight < 3 ? 'amber' : ''}">${so.insight >= 3 ? 'อัปเดตล่าสุด 12 ก.ย. 69' : 'อัปโหลดรูป Insight เพศ / ช่วงอายุ / พื้นที่ยอดนิยม'}</div></div><button class="btn ${so.insight >= 3 ? 'btn-outline' : 'btn-red'} btn-xs" data-do="openSheet" data-sheet="insight"><span>${so.insight >= 3 ? 'อัปเดตข้อมูล' : 'เพิ่มข้อมูล'}</span></button></div>` : '';
    return `<div class="soc-card ${so.connected ? 'on' : ''}">
      <div class="soc-row">${so.connected ? `<img class="soc-ic" src="${D.USER.avatar}" style="border:1px solid #E3E3E3;object-fit:cover">` : U.socialIcon(so.type, 44, 'social')}<div class="soc-n"><b>${so.connected ? so.handle : m.name.toUpperCase()}</b>${so.connected ? `<span>${so.url}</span>` : ''}</div><span class="soc-chip ${so.connected ? 'ok' : ''}">${so.connected ? 'ผูกบัญชีแล้ว' : 'ยังไม่ได้ผูกบัญชี'}</span></div>
      ${so.connected ? `<div class="soc-fol">${I('users-three', 14)} ${U.fmtNum(so.followers)} ผู้ติดตาม</div>` : ''}${insight}
    </div>`;
  }

  // ================= หน้าตอบรับ (UnboxAcceptingDetailPage) =================
  S.accept = s => {
    const c = cur(s), a = D.USER.address, f = s.form || {};
    return `${U.navRed('รายละเอียดตอบรับกิจกรรม', { back: 'campaign' })}
    <div class="scroll page-white form">
      ${s.quota === 'backup' ? `<div class="backup-note">${I('info', 18)} คุณเป็น <b>ผู้รับรางวัลสำรอง</b> จะได้สิทธิ์เมื่อผู้ได้รับคัดเลือกสละสิทธิ์</div>` : ''}
      <div class="acc-hero"><img src="${c.cover}"><b>${c.ep} ${c.title}</b></div>
      <div class="acc-card">
        <div>${U.sectionTitle('โซเชียลที่คุณต้องรีวิว', false, true)}<div class="chips">${c.socialChannels.map(t => `<span class="chip-soc">${U.socialIcon(t, 32)}</span>`).join('')}</div></div>
        <div>${U.sectionTitle('ประเภทคอนเทนต์ที่ต้องรีวิว', false, true)}${c.contentTypes.map(t => `<div class="chip-gray">- ${t}</div>`).join('')}</div>
        <div>${U.sectionTitle('Timeline แคมเปญ', false, true)}<div class="tl">${[c.timeline[3], c.timeline[4], c.timeline[5]].filter(Boolean).map(t => `<div class="tl-row"><i></i><span>${t.k}</span><b>${t.v}</b></div>`).join('')}</div></div>
        <div>${U.sectionTitle('ที่อยู่ในการจัดส่ง', false, true)}<div class="addr"><div><b>${a.name}</b><p>${a.tel}</p><p>${a.address} ${a.subDistrict} ${a.district} ${a.province} ${a.zipcode}</p></div><button class="btn-edit" data-do="openSheet" data-sheet="editAddress">${A('ic-edit-address', 16)}แก้ไขที่อยู่</button></div></div>
        <div>${U.sectionTitle('ข้อมูลที่ควรรู้ก่อนตอบรับ', false, true)}<ul class="know"><li>ต้องส่งดราฟต์รีวิวภายในเวลาที่กำหนด และโพสต์จริงหลังดราฟต์ผ่านเท่านั้น</li><li>หากไม่ส่งรีวิวตามกำหนด จะถูกตัดสิทธิ์และไม่สามารถลงทะเบียนกิจกรรมอื่นได้</li><li>ของรางวัลจะจัดส่งตามที่อยู่ข้างต้น กรุณาตรวจสอบให้ถูกต้อง</li></ul></div>
      </div>
      ${c.acceptQuestions.length ? `<div style="padding-top:8px">${c.acceptQuestions.map((q, i) => question(q, 'a' + i, f)).join('')}</div>` : ''}
      <div class="bar-clock" style="justify-content:center;padding:16px 0 8px">${A('ic-calendar-gray14', 14)}<span>เหลือเวลาตอบรับ</span>${U.clock(left())}</div>
      <div style="height:40px"></div>
    </div>
    <div class="bottombar h88"><div class="bar-btns two">${U.btn('สละสิทธิ์', { style: 'gray', act: 'declineAsk', icon: 'icn-reject-gray' })}${U.btn('ตอบรับกิจกรรม', { act: 'acceptAsk', icon: 'ic-gift' })}</div></div>`;
  };

  // ================= รายละเอียดการรีวิว (UnboxBrief) =================
  S.brief = s => {
    const c = cur(s);
    return `${U.navRed('รายละเอียดการรีวิว', { back: 'campaign', right: 'none' })}
    <div class="brief-card"><img src="${c.cover}"><div><b>${c.ep} ${c.title}</b><span>${A('ic-calendar-bdbdbd-gray15x14', 14)}${c.dateRange}</span></div></div>
    <div class="cp-tabs"><button class="on">${A('ic-file-hart-gray', 20)} รายละเอียดการส่งรีวิว</button><button data-go="accept">${A('ic-clipboard-text-gray', 20)} ข้อมูลการตอบรับ</button></div>
    <div class="scroll page-white form">
      <div class="brief"><h4>บรีฟจากแบรนด์</h4>${c.brief ? c.brief.replace(/\n/g, '<br>') : '<span class="empty">ไม่มีข้อมูล</span>'}
        <h4>โซเชียลที่คุณต้องรีวิว</h4><div class="chips">${c.socialChannels.map(t => `<span class="chip-soc">${U.socialIcon(t, 32)}</span>`).join('')}</div>
        <h4>ประเภทคอนเทนต์ที่ต้องรีวิว</h4>${c.contentTypes.map(t => `<div class="chip-gray">- ${t}</div>`).join('')}
        <h4>กำหนดส่ง</h4><div class="tl">${c.timeline.slice(4).map(t => `<div class="tl-row"><i></i><span>${t.k}</span><b>${t.v}</b></div>`).join('')}</div>
      </div>
    </div>
    ${briefBar(s)}`;
  };
  function briefBar(s) {
    const r = s.review;
    if (r === 'waitingDraft' || r === 'none' || r === 'notOpenDraft') return `<div class="bottombar"><div style="padding-top:8px">${U.btn('สร้างดราฟต์รีวิว', { act: 'briefRead', icon: 'ic-create-new-draft-20', enabled: r === 'waitingDraft' })}</div></div>`;
    if (r === 'draft') return `<div class="bottombar"><div style="padding-top:8px">${U.btn('แก้ไขแบบร่าง', { act: 'briefRead', icon: 'ic-draft-reject-button-20' })}</div></div>`;
    if (r === 'rejectDraft') return `<div class="bottombar"><div style="padding-top:8px">${U.btn('แก้ไขดราฟต์รีวิว', { act: 'reviewAction', extra: 'data-a="verdict"', icon: 'ic-draft-reject-button-20' })}</div></div>`;
    if (r === 'waitingReview') return `<div class="bottombar"><div style="padding-top:8px">${U.btn('ส่งลิงก์รีวิว', { act: 'reviewAction', extra: 'data-a="link"', icon: 'ic-sent-review-button-20' })}</div></div>`;
    return `<div class="bottombar"><div style="padding-top:8px">${U.btn('กลับ', { style: 'gray', go: 'campaign' })}</div></div>`;
  }

  // ================= ดราฟต์ (ReviewShopping composer) =================
  S.draft = s => {
    const c = cur(s), d = s.draft || { title: '', caption: '', images: [] };
    const title = s.review === 'rejectDraft' ? 'แก้ไขดราฟต์รีวิว' : s.review === 'draft' ? 'แก้ไขแบบร่าง' : 'ส่งดราฟต์รีวิว';
    const cap = d.caption.length;
    return `${U.navRed(title, { back: 'campaign', right: 'none', close: true })}
    <div class="scroll page-white">
      <div style="height:8px"></div>
      ${U.stepper(0)}
      ${s.review === 'rejectDraft' ? `<div class="status-card reject">${A('ic-preview-reject-state-64', 64)}<div><b>สถานะ : <em>ดราฟต์รีวิวไม่ผ่าน</em></b><span>รอการแก้ไขดราฟต์รีวิว</span></div><button class="sc-cta" data-do="reviewAction" data-a="verdict">ดูรายละเอียด<br>ที่ต้องการแก้ไข</button></div>` : ''}
      <div class="author"><img src="${D.USER.avatar}"><b>${D.USER.username}</b></div>
      ${d.images.length ? `<div class="img-square"><img src="${d.images[0]}"></div><div class="pagedots">${d.images.map((_, i) => `<i class="${i === 0 ? 'on' : ''}"></i>`).join('')}</div>` : `<div class="add-img-cta" data-do="mockUpload" data-k="draft.images">${A('ic-upload-image-new', 32)}*เพิ่มรูป</div>`}
      <div class="add-video">${A('ic-add-video-32', 32)}เพิ่มวิดีโอ</div><p class="add-video-hint">แนบไฟล์ mov, mp4 และขนาดไม่เกิน 100 MB เพื่อตรวจดราฟต์</p>
      <div class="mini-strip"><button class="mini-add" data-do="mockUpload" data-k="draft.images">${A('ic-upload-image-new', 32)}</button>${d.images.map(src => `<img class="mini" src="${src}">`).join('')}</div>
      <div class="title-fld"><input data-bind="draft.title" value="${d.title}" placeholder="*หัวข้อรีวิวที่น่าสนใจ" maxlength="70"><span class="cnt">${d.title.length}/70</span></div>
      <div class="cap-fld"><textarea data-bind="draft.caption" placeholder="ลองเล่าประสบการณ์ของคุณเพิ่มอีกหน่อย... (ถ้ามี)">${d.caption}</textarea><div class="cap-foot"><span class="hint ${cap >= 300 ? 'ok' : ''}">${cap >= 300 ? 'เนื้อหาครบ 300 ตัวอักษรแล้ว' : 'เขียนรีวิวให้ครบ 300 ตัวอักษร เพื่อเพิ่มการมองเห็นให้โพสต์ของคุณ'}</span><span class="cnt">${cap}/300</span></div></div>
      <div class="chips-row"><span class="chip-tag">${I('users-three', 16)}แท็กเพื่อน</span><span class="chip-tag">${I('map-pin', 16)}เช็กอิน</span><span class="chip-tag">#แฮชแท็ก</span>${A('ic-mic-red-26', 26, 'mic')}</div>
      <div class="add-brand">${A('ic-upload-image-new', 24)}เพิ่มแบรนด์ ${I('caret-right', 14)}</div>
      ${s.review === 'rejectDraft' || s.review === 'draft' ? '' : `<div class="tips"><b>โพสต์อย่างโปร?</b><em>ตกแต่งภาพปก </em>ด้วยข้อความ<em> เพิ่มรูป </em>อย่างน้อย 3 ภาพ<br><em>เขียนแคปชั่น </em>มากกว่า 300 ตัวอักษร และ<em>ติด #แฮชแท็ก</em> ที่เกี่ยวข้อง</div>`}
      <div class="unbox-row"><div class="unbox-card"><img src="${c.cover}"><b>${c.ep} ${c.title}</b>${I('x', 16)}</div><button class="unbox-brief" data-go="brief">${A('ic-brief-button-20', 32)}บรีฟ</button></div>
    </div>
    <div class="footer64">${s.review === 'rejectDraft' ? '' : U.btn('บันทึกแบบร่าง', { style: 'blue', act: 'saveDraft', icon: 'ic-draft-post-gray-20' })}${U.btn('ส่งตรวจดราฟต์รีวิว', { act: 'submitDraft', enabled: !!(d.title && d.caption && d.images.length), icon: 'ic-post-topic-button-20' })}</div>`;
  };

  // ================= ผลตรวจดราฟต์ (DraftVerdict page + sheet) =================
  S.verdict = s => {
    const d = s.draft || { title: 'ริมทะเลสาบสวยมาก เดินทั้งวันไม่เบื่อ', caption: 'ไปงาน WONDER ONE มา บรรยากาศดีมาก ร้านเยอะ วิวสวย คอนเสิร์ตสนุก', images: ['assets/ph01.jpg', 'assets/ph04.jpg'] };
    return `${U.navRed('ส่งดราฟต์รีวิว', { back: 'campaign', right: 'none', close: true })}
    <div class="scroll page-white">
      <div style="height:8px"></div>${U.stepper(1)}
      <div class="vd-status"><span class="tile">${I('x-circle', 24, 'fill')}</span><div><div class="t1">สถานะ : <em>ดราฟต์รีวิวไม่ผ่าน</em></div><div class="t2">แก้ตามรายละเอียด แล้วส่งตรวจอีกครั้ง</div></div><button class="cta" data-do="openVerdictSheet">ดูรายละเอียด<br>ที่ต้องการแก้ไข</button></div>
      <div class="author"><img src="${D.USER.avatar}"><b>${D.USER.username}</b></div>
      <div class="img-square"><img src="${d.images[0] || 'assets/ph01.jpg'}"></div>
      <div class="vd-h" style="margin:0 8px;border-radius:8px 8px 0 0">${I('image-square', 16, 'fill')}<b>รูปภาพรีวิว</b><span class="pill-must">${I('warning-circle', 12, 'fill')} ต้องแก้ (1)</span></div>
      <div class="text-card"><div class="vd-h" style="margin:-8px -8px 0;border-radius:8px 8px 0 0">${I('text-t', 16, 'fill')}<b>หัวข้อรีวิว</b><span class="pill-should">แนะนำแก้ (1)</span></div><b>${d.title}</b><div class="vd-h" style="margin:0 -8px">${I('text-align-left', 16, 'fill')}<b>แคปชั่นรีวิว</b><span class="pill-must">ต้องแก้ (2)</span></div><p>${d.caption}</p></div>
    </div>
    <div class="footer82"><div class="bar-clock">${A('ic-calendar-gray14', 14)}<span>เหลือเวลาส่งดราฟต์รีวิว</span>${U.clock(left())}</div><div class="bar-btns" style="display:flex;gap:8px">${U.btn('รายละเอียดการรีวิว', { style: 'gray', go: 'brief', icon: 'ic-brief-button-20' })}${U.btn('แก้ไขดราฟต์รีวิว', { act: 'editDraft', icon: 'ic-edit-topic-button-20' })}</div></div>
    ${s.sheet === 'verdict' ? verdictSheet(d) : ''}`;
  };
  function verdictSheet(d) {
    return `<div class="vd-scrim" data-do="closeSheet"><div class="vd-panel" onclick="event.stopPropagation()">
      <div class="vd-handle"></div>
      <div class="vd-head"><b>ผลการตรวจดราฟต์รีวิว</b><span class="pill-must">ต้องแก้</span><button class="vd-close" data-do="closeSheet">${I('x', 18, 'bold')}</button></div>
      <div class="vd-body">
        <div class="vd-card should"><div class="vd-h">${I('text-t', 18, 'fill')}<b>จุดที่แนะนำให้แก้ไขในหัวข้อ</b>${I('caret-down', 13, 'bold')}</div><div class="vd-bd"><p class="vd-q"><mark>${d.title}</mark></p><div class="vd-pt"><i>1</i><span>เพิ่มชื่องานในหัวข้อ เพื่อให้ค้นหาเจอง่ายขึ้น (AI auto suggest · ไม่ถูกนับเป็นการแก้ไขในระบบ)</span></div></div></div>
        <div class="vd-card"><div class="vd-h">${I('text-align-left', 18, 'fill')}<b>จุดที่ต้องแก้ไขในแคปชั่น</b>${I('caret-down', 13, 'bold')}</div><div class="vd-bd"><p class="vd-q">${d.caption} <mark>#WONDERONE2027</mark></p><div class="vd-pt"><i>1</i><span>ไม่พบแฮชแท็ก #WONDERONE2027 และ #SaleHereSTAR ตามบรีฟ</span></div><div class="vd-pt"><i>2</i><span>ยังไม่ได้แท็ก @wonderone.official</span></div></div></div>
        <div class="vd-card"><div class="vd-h">${I('image-square', 18, 'fill')}<b>จุดที่ต้องแก้ไขในรูปภาพ</b>${I('caret-down', 13, 'bold')}</div><div class="vd-bd"><div class="vd-pt"><i>1</i><span>รูปที่ 2 เห็นโลโก้ผู้จัดถูกครอปออก ต้องเห็นโลโก้ครบ</span></div><div class="vd-media"><div class="vd-paper"><img src="${d.images[1] || 'assets/ph04.jpg'}"><div class="vd-cap"><i class="vd-pt" style="display:none"></i><span class="pill-must" style="border-radius:50%;padding:0;width:16px;height:16px;display:inline-grid;place-items:center;font-size:9.5px">1</span>รูปที่ 2</div></div></div></div></div>
        <div class="sheet-cta">${U.btn('ส่งตรวจดราฟต์รีวิว', { act: 'editDraft' })}</div>
      </div></div></div>`;
  }

  // ================= สถานะดราฟต์ (TopicPreview) =================
  S.preview = s => {
    const c = cur(s), d = s.draft || { title: 'ริมทะเลสาบสวยมาก เดินทั้งวันไม่เบื่อ', caption: 'ไปงาน WONDER ONE มา บรรยากาศดีมาก #WONDERONE2027 #SaleHereSTAR', images: ['assets/ph01.jpg', 'assets/ph04.jpg'] };
    const r = s.review;
    const st = r === 'waitingApproveDraft' ? ['', 'ic-preview-waiting-approve-state-64', 'กำลังตรวจดราฟต์รีวิว', 'รอตรวจดราฟต์รีวิว คุณสามารถปิดหน้านี้ได้']
      : r === 'rejectDraft' ? ['reject', 'ic-preview-reject-state-64', 'ดราฟต์รีวิวไม่ผ่าน', 'รอการแก้ไขดราฟต์รีวิว']
      : ['approved', 'ic-preview-approved-state-64', 'ดราฟต์รีวิวผ่านแล้ว', 'รอส่งลิงก์รีวิว'];
    const footer = r === 'waitingApproveDraft' ? `<div class="cancel-gray"><button data-do="cancelDraft">ยกเลิกส่งตรวจดราฟต์รีวิว</button></div>`
      : r === 'rejectDraft' ? `<div class="footer82"><div class="bar-clock">${A('ic-calendar-gray14', 14)}<span>เหลือเวลาส่งดราฟต์รีวิว</span>${U.clock(left())}</div><div style="display:flex;gap:8px">${U.btn('รายละเอียดการรีวิว', { style: 'gray', go: 'brief', icon: 'ic-brief-button-20' })}${U.btn('แก้ไขดราฟต์รีวิว', { act: 'reviewAction', extra: 'data-a="verdict"', icon: 'ic-edit-topic-button-20' })}</div></div>`
      : r === 'waitingReview' || r === 'notOpenReview' ? `<div class="footer82"><div class="bar-clock">${A('ic-calendar-gray14', 14)}<span>${r === 'notOpenReview' ? 'เริ่มส่งลิงก์รีวิวได้ในอีก 5 วัน' : 'เหลือเวลาส่งลิงก์รีวิว'}</span>${r === 'waitingReview' ? U.clock(left()) : ''}</div>${U.btn('ส่งลิงก์รีวิว', { act: 'reviewAction', extra: 'data-a="link"', icon: 'ic-send-link-button-20', enabled: r === 'waitingReview' })}</div>`
      : r === 'expireDraft' ? `<div class="footer82"><div class="bar-clock" style="color:#D3180F">${A('ic-calendar-gray14', 14)}<span>หมดเวลาส่งดราฟต์รีวิว</span></div>${U.btn('ติดต่อผู้ช่วยส่วนตัว', { go: 'chat', icon: 'ic-call-center-20' })}</div>` : '';
    return `${U.navRed('ส่งดราฟต์รีวิว', { back: 'campaign', right: 'none', close: true })}
    <div class="scroll page-white">
      <div style="height:8px"></div>${U.stepper(1)}
      <div class="status-card ${st[0]}">${A(st[1], 64)}<div><b>สถานะ : <em>${st[2]}</em></b><span>${st[3]}</span></div>${r === 'rejectDraft' ? `<button class="sc-cta" data-do="reviewAction" data-a="verdict">ดูรายละเอียด<br>ที่ต้องการแก้ไข</button>` : ''}</div>
      <div class="author"><img src="${D.USER.avatar}"><b>${D.USER.username}</b></div>
      <div class="img-square"><img src="${d.images[0] || 'assets/ph01.jpg'}"></div>
      <div class="camp-chip"><img src="${c.logo}">${c.ep} ${c.brand}</div>
      <div class="pagedots"><i class="on"></i><i></i></div>
      <div class="text-card"><b>${d.title}</b><p>${d.caption}</p><span class="copy-pill">${A('ic-copy-button-18', 18)}คัดลอก</span></div>
    </div>
    ${footer}`;
  };

  // ================= ส่งลิงก์รีวิว (ApproveLinkPage) =================
  S.link = s => {
    const c = cur(s), l = s.links || {};
    const opt = Object.keys(D.SOCIAL_META).filter(t => !c.socialChannels.includes(t));
    return `${U.navRed('ส่งดราฟต์รีวิว', { back: 'campaign', right: 'none', close: true })}
    <div class="scroll page-white">
      <div style="height:8px"></div>${U.stepper(2)}
      <div class="lk-head"><span><em>*</em>ลิงก์โพสต์รีวิวบนโซเชียลมีเดีย ที่เราอยากให้คุณส่งรีวิว<br>(วางลิงก์รีวิวให้ครบทุกช่องทาง)</span>${A('ic-info-red24', 24)}</div>
      ${c.socialChannels.map(t => linkField(t, l[t], true)).join('')}
      <div class="lk-head"><span>ลิงก์โพสต์รีวิวบนโซเชียลมีเดีย ที่สามารถส่งรีวิวเพิ่มเติม</span></div>
      ${opt.map(t => linkField(t, l[t], false)).join('')}
    </div>
    <div class="footer82"><div class="bar-clock">${A('ic-calendar-gray14', 14)}<span>เหลือเวลาส่งลิงก์รีวิว</span>${U.clock(left())}</div>${U.btn('ส่งลิงก์รีวิว', { act: 'submitLinks', enabled: c.socialChannels.every(t => /^https?:\/\/\S+$/.test(l[t] || '')), icon: 'ic-send-link-button-20' })}</div>`;
  };
  function linkField(t, v, req) {
    const bad = v && !/^https?:\/\/\S+$/.test(v);
    return `<div class="lk-row ${bad ? 'err' : ''}"><div class="lk-in">${U.socialIcon(t, 28)}<input data-bind="links.${t}" value="${v || ''}" placeholder="วางลิงก์โพสต์รีวิวบน ${D.SOCIAL_META[t].name} ของคุณ"></div>${bad ? `<div class="lk-err">ลิงก์ไม่ถูกต้อง</div>` : `<div class="lk-sub">${A('ic-help-gray20', 18)}ตรวจสอบบัญชี ${D.SOCIAL_META[t].name} ที่ลงทะเบียน <a>คลิก</a></div>`}</div>`;
  }

  // ================= กิจกรรมของฉัน (UserBrandCampaign) =================
  S.myCampaigns = s => {
    const tab = s.myTab || 'all', c = cur(s);
    const rows = [
      { c, state: s.campaign, review: s.review, order: s.order },
      { c: D.CAMPAIGNS[1], state: 'registered', review: 'none' },
      { c: D.CAMPAIGNS[2], state: 'rejectQuotaByExpire', review: 'none' },
    ];
    const win = r => ['waitingAcceptQuota', 'forceVerifyUser', 'acceptedQuota'].includes(r.state);
    const shown = rows.filter(r => tab === 'all' || (tab === 'win' ? win(r) : !win(r) && r.state !== 'registered'));
    const hdr = { all: 'ทั้งหมด', win: 'ผ่านการคัดเลือก', lose: 'ไม่ผ่านการคัดเลือก' }[tab];
    return `${U.navRed('กิจกรรม', { back: 'profile', right: `<button class="nav-btn">${A('ic-bell-white32', 32)}</button>` })}
    <div class="seg">${[['all', 'ทั้งหมด'], ['win', 'ผ่านการคัดเลือก'], ['lose', 'ไม่ผ่านการคัดเลือก']].map(([k, t]) => `<button class="${tab === k ? 'on' : ''}" data-do="myTab" data-tab="${k}">${t}</button>`).join('')}</div>
    <div class="scroll page-white">
      <div class="my-hdr">${hdr} <span>(${shown.length})</span></div>
      ${shown.length ? shown.map(r => myRow(r, s)).join('') : `<div class="empty">${A('ic-unbox-gray72', 72)}<p>ไม่พบข้อมูล</p></div>`}
    </div>
    ${tabbar('profile')}`;
  };
  function myRow(r, s) {
    const chip = r.state === 'registered' ? ['green', 'คุณลงทะเบียนแล้ว'] : r.state === 'waitingAcceptQuota' ? ['brown', 'คุณผ่านการคัดเลือก'] : r.state === 'acceptedQuota' ? ['brown', 'คุณได้รับรีวิว Sale Here STAR']
      : r.state === 'forceVerifyUser' ? ['gray', 'ยืนยันตัวตนเพื่อเข้าร่วมกิจกรรม'] : r.state === 'rejectQuotaByUser' ? ['gray', 'คุณสละสิทธิ์'] : r.state === 'rejectQuotaByExpire' ? ['gray', 'คุณไม่ตอบรับภายในเวลาที่กำหนด'] : r.state === 'rejectQuotaByAdmin' ? ['gray', 'คุณถูกตัดสิทธิ์'] : ['gray', 'คุณไม่ผ่านการคัดเลือก'];
    const date = r.review === 'reviewed' ? ['green', 'เสร็จสิ้นการส่งรีวิวกิจกรรม'] : r.review === 'waitingReview' ? ['red', 'เหลือเวลาส่งลิงก์รีวิว 3 วัน'] : r.review === 'expireReview' ? ['red4', 'หมดเวลาส่งลิงก์รีวิว'] : r.review === 'expireDraft' ? ['red4', 'หมดเวลาส่งดราฟต์']
      : ['waitingDraft', 'draft', 'rejectDraft', 'waitingApproveDraft'].includes(r.review) ? ['', 'ส่งดราฟต์ได้ถึง 12 ต.ค. 69 เวลา 23:59 น.'] : r.review === 'notOpenReview' ? ['', 'เริ่มส่งลิงก์รีวิว 13 ต.ค. 69 เวลา 09:00 น.'] : r.review === 'notOpenDraft' ? ['', 'เริ่มส่งดราฟต์รีวิว 5 ต.ค. 69 เวลา 09:00 น.']
      : r.state === 'acceptedQuota' ? ['', 'เริ่มส่งสินค้า/คูปองออนไลน์ 3 ต.ค. 69 เวลา 09:00 น.'] : r.state === 'waitingAcceptQuota' ? ['red', 'ตอบรับได้ถึง 2 ต.ค. 69 เวลา 23:59 น.'] : r.state === 'registered' ? ['', 'รอประกาศชื่อผู้ได้รับคัดเลือก'] : ['', r.c.dateRange];
    const track = r.state === 'acceptedQuota' && r.order === 'shipping' ? `<a class="my-track">เช็กเลขติดตามพัสดุ</a>` : '';
    const isMine = r.c.slug === s.campaignSlug;
    const btns = isMine && ['waitingAcceptQuota', 'acceptedQuota', 'forceVerifyUser'].includes(r.state) ? (s.reviewTab || r.review !== 'none' ? reviewBar(s) : mainBar(s)).replace('class="bottombar"', 'class="my-actions"') : '';
    return `<div class="my-row" data-do="openCampaign" data-slug="${r.c.slug}"><div class="my-top"><img src="${r.c.cover}"><div><b>${r.c.ep} ${r.c.title}</b><div class="my-date ${date[0]}">${A('ic-calendar-gray14', 14)}${date[1]}</div></div></div>
      <div class="my-st-row">${chip[0] === 'brown' ? A('ic_gfit_box', 30, 'gift') : ''}<span class="my-chip ${chip[0]}">${chip[1]}</span>${track}</div>${btns.replace(/<div class="bar-clock">[\s\S]*?<\/div>|<div class="bar-desc[^"]*"[^>]*>[\s\S]*?<\/div>/, '')}</div>`;
  }

  // ================= รายชื่อผู้ได้รีวิว =================
  S.awardList = s => {
    const c = cur(s);
    return `${U.navRed("รายชื่อผู้ได้รีวิว 'Sale Here STAR'", { back: 'campaign', right: 'none', close: true })}
    <div class="scroll page-white">
      <div class="aw-hdr">${s.won ? `<div class="lottie lottie-celebrate" data-anim="unboxCelebration"></div>` : ''}<img class="ava" src="${D.USER.avatar}"><span class="aw-pill ${s.won ? '' : 'lose'}">${s.won ? 'ยินดีด้วย! คุณได้รีวิว Sale Here STAR' : 'คุณไม่ได้รีวิว Sale Here STAR'}</span></div>
      <div class="aw-sec">รายชื่อผู้ที่ได้รีวิว 'Sale Here STAR' ทั้งหมด</div>
      ${c.applications.filter(a => s.won || !a.me).map((a, i) => `<div class="aw-row"><img src="${a.avatar}"><b>${a.name}${a.me ? ' <span class="me-tag">คุณ</span>' : ''}</b>${i > 0 && i < 3 ? `<a>ดูรีวิว ${A('ic-arrow-blue12', 12)}</a>` : ''}</div>`).join('')}
    </div>`;
  };

  // ================= onboarding (WelcomeOnboardingPage) =================
  S.onboarding = s => {
    const createProfile = welcomeDone(s) && s.user.percent < 100;
    return `<div class="onb"><button class="onb-x" data-go="campaign">${A('ic-close-white32', 32)}</button>
      <img class="art" src="assets/ic/${createProfile ? 'image_star_card_register' : 'image_welcome_onboarding_register'}.png">
      <div class="onb-bottom"><div class="onb-dots"><i class="on"></i></div><button class="onb-cta" data-do="${createProfile ? 'goProfileHub' : 'goSteps'}">สร้าง STAR PROFILE</button></div></div>`;
  };
  S.onboardingSteps = s => S.campaign(s);

  // ================= hub โปรไฟล์ครีเอเตอร์ (CreatorProfilePage) =================
  S.profileHub = s => {
    const p = s.user.percent, done = Math.round(p / 100 * 6);
    const rows = ['ข้อมูลส่วนตัว', 'ข้อมูลโซเชียล & การรับงาน', 'ข้อมูลที่อยู่สำหรับรับของรีวิว', 'ตัวอย่างผลงาน'];
    const ex = i => i < done ? '' : A('ic-exclamation-mark', 22, 'ex');
    return `${U.navRed('โปรไฟล์ครีเอเตอร์', { back: 'campaign', right: 'none', close: true })}
    <div class="scroll page-white">
      <div class="hub-strip"><div class="hub-pill"><span>โปรไฟล์ครีเอเตอร์เสร็จสมบูรณ์&nbsp;&nbsp;${p} %</span><span class="trk"><i style="width:${p}%"></i></span></div></div>
      <div class="hub-user"><span class="t">ข้อมูลผู้ใช้งาน ${ex(0)}</span><div class="hub-ava"><img src="${D.USER.avatar}"><span class="pen">${A('ic-pencilSimpleLine-outline', 20)}</span></div><b>${D.USER.username}</b><span class="hub-cap">ชอบพาไปเที่ยว ทานอาหารอร่อยๆ แวะจิบกาแฟที่ร้านคาเฟ่น่ารักๆ</span><button class="hub-edit">${A('ic-pencilSimpleLine-outline', 16)}แก้ไขข้อมูลผู้ใช้งาน</button></div>
      <div class="hub-row" data-do="hubRow"><div><span>รูปโปรไฟล์ครีเอเตอร์</span>${ex(1)}${A('ic-chevron-grey-1000', 18, 'chev')}</div></div>
      ${rows.map((t, i) => `<div class="hub-row" data-do="hubRow"><div><span>${t}</span>${ex(i + 2)}${A('ic-chevron-grey-1000', 18, 'chev')}</div></div>`).join('')}
      <div style="padding:16px;font-size:12px;color:#919191">mock: แตะแถวที่มี ! เพื่อกรอกส่วนนั้นให้ครบทันที</div>
    </div>
    <div class="bottombar h84">${U.btn('ดูตัวอย่างโปรไฟล์ครีเอเตอร์', { act: 'previewProfile' })}</div>`;
  };

  // ================= KYC (VerifyUser) =================
  S.kyc = s => {
    const k = s.kyc, st = k.step;
    const head = (t, sub = '', back = true) => `<div class="sheet-head">${back ? `<button class="sheet-back" data-do="kycBack">${A('ic-back-button', 28)}</button>` : ''}<span>${t}</span>${sub ? `<small>${sub}</small>` : ''}<button class="sheet-x" data-do="kycExit">${A('ic-close-button', 28)}</button></div>`;
    if (st === 'type') return `<div class="kyc">${head('ยืนยันตัวตน', 'กรุณาเลือกวิธียืนยันตัวตนเพื่อความปลอดภัย', false)}<div class="scroll">
      <div class="kyc-hero">${A('ic-verify-user-icon', 153)}</div>
      <div class="kyc-info">${A('ic-select-verify', 40)}<div><b>การยืนยันตัวตน</b><p>บัญชีที่ได้รับการตรวจสอบแล้วจะมีเครื่องหมายติ๊กถูกสีเขียวแสดงอยู่หน้าชื่อเพื่อแสดงว่าได้รับการยืนยันตัวตน<br>จากเซลเฮียร์แล้ว</p></div></div>
      <div class="kyc-info">${A('ic-select-verify-protect', 40)}<div><b>ความปลอดภัยของข้อมูล</b><p>ข้อมูลของคุณจะถูกจัดเก็บอย่างปลอดภัยตามนโยบาย<br>ความปลอดภัยความเป็นส่วนตัวของเซลเฮียร์</p><a class="link-blue">อ่านเพิ่มเติม</a></div></div>
      <div class="kyc-h16">เลือกเพื่อยืนยันตัวตน</div>
      <div class="radios"><label class="radio doc ${k.docType === 'idcard' ? 'on' : ''}"><input type="radio" name="doc" value="บัตรประจำตัวประชาชน" data-bind="kyc.docTypeLabel" ${k.docType === 'idcard' ? 'checked' : ''}>${A('ic-thai-id', 40)}<span>บัตรประจำตัวประชาชน</span><i></i></label><label class="radio doc ${k.docType === 'passport' ? 'on' : ''}"><input type="radio" name="doc" value="Passport" data-bind="kyc.docTypeLabel" ${k.docType === 'passport' ? 'checked' : ''}>${A('ic-passport', 40)}<span>Passport</span><i></i></label></div>
      <div style="height:24px"></div>
    </div><div class="bottombar h84">${U.btn('ยืนยัน', { act: 'kycNext' })}</div></div>`;
    if (st === 'instruction' || st === 'instruction2') {
      const face = st === 'instruction2';
      const rules = face ? ['✅  ถ่ายภาพตนเองพร้อมถือบัตรประชาชน โดยให้เห็นใบหน้าและบัตรประชาชนอย่างชัดเจน', '✅  บัตรประชาชนต้องชัดเจน ตัวอักษรต้องอ่านได้ ไม่ถูกบังหรือสะท้อนแสง', '✅  ถือบัตรประชาชนด้วยมือของตนเองและให้เห็นข้อมูลบนบัตรประชาชนอย่างครบถ้วน', '🚫  ห้ามแก้ไขหรือปรับแต่งรูปภาพ เช่น การเบลอข้อมูลการเพิ่มหรือลบรายละเอียดในภาพ', '🚫  ห้ามใช้ภาพถ่ายจากหน้าจอ อุปกรณ์อิเล็กทรอนิกส์หรือสำเนาเอกสาร ต้องเป็นรูปถ่ายบัตรประชาชนจริงเท่านั้น']
        : ['✅  วางบัตรประชาชนบนพื้นเรียบ โดยใช้พื้นหลังที่ไม่มีลวดลาย สีเรียบ และไม่มีวัตถุอื่นอยู่ในภาพ', '✅  ถ่ายให้เห็นบัตรประชาชนทั้งใบโดยไม่มีส่วนใดถูกตัดออกจากกรอบภาพ', '✅  ใช้แสงสว่างที่เหมาะสมหลีกเลี่ยงเงาหรือแสงสะท้อนที่อาจบดบังข้อมูลบนบัตรประชาชน', '✅  ภาพต้องมีความคมชัดสามารถอ่านข้อมูลบนบัตรประชาชนได้อย่างชัดเจน ไม่พร่ามัว', '🚫  ห้ามแก้ไขหรือปรับแต่งรูปภาพ เช่น การเบลอข้อมูลการเพิ่มหรือลบรายละเอียดในภาพ', '🚫  ห้ามใช้ภาพถ่ายจากหน้าจอ อุปกรณ์อิเล็กทรอนิกส์หรือสำเนาเอกสาร ต้องเป็นรูปถ่ายบัตรประชาชนจริงเท่านั้น'];
      return `<div class="kyc">${head(face ? 'วิธีการถ่ายรูปคู่บัตรประชาชน' : 'วิธีการถ่ายรูปบัตรประชาชน')}<div class="scroll">
        <div class="kyc-samples"><div class="${face ? 'face' : ''}">${A('ic-checkcircle-stroke', 24, 'badge')}<img class="samp" src="assets/ic/${face ? 'ic-face-thaiid-correct' : 'ic-thaiid-correct'}.png"></div><div class="${face ? 'face' : ''}">${A('ic-xcircle-stroke', 24, 'badge')}<img class="samp" src="assets/ic/${face ? 'ic-face-thaiid-incorrect' : 'ic-thaiid-incorrect'}.png"></div></div>
        <div class="kyc-h14">ข้อกำหนดและเงื่อนไข</div>
        <ul class="kyc-rules">${rules.map(r => `<li>${r}</li>`).join('')}</ul><div style="height:24px"></div>
      </div><div class="bottombar h84">${U.btn('ถ่ายรูป', { act: 'kycNext', icon: 'ic-camera-outline' })}</div></div>`;
    }
    if (st === 'camera' || st === 'camera2') {
      const face = st === 'camera2';
      return `<div class="cam"><div class="cam-top"><i></i><span>${face ? 'ถ่ายรูปคู่บัตรประชาชน' : 'ถ่ายรูปบัตรประชาชน'}</span><button data-do="kycBack">${A('ic-x-outline', 24)}</button></div>
        <div class="cam-view"><div class="cam-frame">${A(face ? 'ic-id-card-form-with-face' : 'ic-id-card-form')}</div></div>
        <div class="cam-bar"><p class="cam-desc">${face ? 'ตรวจสอบให้มั่นใจว่าเห็นใบหน้า<br>และบัตรประชาชนอยู่ในกรอบและชัดเจน' : 'กรุณาวางรูปให้ตรงตามกรอบ และ ไม่วางนิ้วมือบดบังรูป ตัวอักษร<br>หรือสัญลักษณ์บนหน้าบัตร'}</p><div class="cam-actions"><button class="shutter" data-do="kycShot">${A('ic-take-photo', 76)}</button><button class="cam-flip">${A('ic-camera-flip', 32)}</button></div></div></div>`;
    }
    if (st === 'preview' || st === 'preview2') {
      return `<div class="cam"><div class="cam-top"><i></i><span>ยืนยันข้อมูล</span><button data-do="kycExit">${A('ic-x-outline', 24)}</button></div><div class="cam-view"><div class="cam-shot"></div></div>
        <div class="cam-bar"><p class="cam-desc"><b>ยืนยันข้อมูล</b>กรุณาตรวจสอบความชัดเจนของภาพบัตรของคุณ</p><div class="cam-confirm">${U.btn('ถ่ายใหม่', { style: 'outline-white', act: 'kycBack', icon: 'ic-arraows-counter-clockwise-outline' })}${U.btn('ยืนยัน', { act: 'kycNext', icon: 'ic-check-outline', cls: 'btn-r8' })}</div></div></div>`;
    }
    if (st === 'form') {
      const docBad = k.aiResult === 'notClear', faceBad = k.aiResult === 'faceMismatch';
      return `<div class="kyc">${head('ยืนยันตัวตน', '', false)}<div class="scroll">
      <div class="kyc-h16">Step 1 : ถ่ายรูป</div>
      <div class="kyc-thumbs"><div class="kyc-thumb ${docBad ? 'bad bad-doc' : 'ok'}"><img src="assets/ic/ic-verify-idcard-148x74.png"><b>หน้าบัตรประชาชน</b><small>${docBad ? 'รูปบัตรประชาชนสำหรับยืนยันตัวตน<br>โปรดมั่นใจว่าชัดเจนและถูกต้อง' : 'หน้าบัตรประชาชนอยู่ในกรอบ<br>ถูกต้องและชัดเจน'}</small></div><div class="kyc-thumb ${faceBad ? 'bad' : 'ok'}"><img src="assets/ic/ic-verify-face-148x74.png"><b>รูปคู่บัตรประชาชน</b><small>${faceBad ? 'ภาพไม่ถูกต้องหรือไม่ชัดเจน<br>กรุณาตรวจสอบอีกครั้งก่อนส่ง' : 'รูปคู่หน้าบัตรประชาชนอยู่ในกรอบ<br>ถูกต้องและชัดเจน'}</small></div></div>
      <div class="kyc-retake">${U.btn('ถ่ายรูปบัตรประชาชนและรูปคู่ใหม่', { act: 'kycRetry', icon: 'ic-camera-white16', iconSize: 16 })}</div>
      <div class="kyc-h16">Step 2 : กรอกข้อมูลส่วนตัว</div>
      <div class="kyc-h14">ข้อมูลบัตรประชาชน</div>
      ${U.field({ label: 'เลขบัตรประชาชน', req: true, value: '1 1012 34567 89 0', type: 'tel', icon: 'ic-IdentificationCard-outline' })}
      ${U.field({ label: 'คำนำหน้าชื่อ', req: true, value: 'นางสาว', select: true, icon: 'ic-usercircle-outline' })}
      ${U.field({ label: 'ชื่อ <span style="color:#828282;font-weight:400">(ภาษาไทย)</span>', req: true, value: 'มณีรัตน์', icon: 'ic-userlist-outline' })}
      ${U.field({ label: 'นามสกุล <span style="color:#828282;font-weight:400">(ภาษาไทย)</span>', req: true, value: 'ใจดี', icon: 'ic-userlist-outline' })}
      ${U.field({ label: 'วันเกิด', req: true, value: '14/02/2541', select: true, icon: 'ic-calendarblank-outline' })}
      ${U.field({ label: 'วันที่บัตรหมดอายุ', req: true, value: '13/02/2574', select: true, icon: 'ic-creditcard-outline' })}
      <div class="kyc-h14">ข้อมูลที่อยู่</div>
      ${U.field({ label: 'รายละเอียดที่อยู่ <span style="color:#828282;font-weight:400">(ตามบัตรประชาชน)</span>', req: true, value: '99/12 ซ.สุขุมวิท 77', multiline: true, icon: 'ic-houseline-outline' })}
      ${U.field({ label: 'รหัสไปรษณีย์', req: true, value: '10250' })}
      ${U.field({ label: 'ตำบล/แขวง', req: true, value: 'สวนหลวง', select: true })}
      ${U.field({ label: 'อำเภอ/เขต', req: true, value: 'สวนหลวง', disabled: true })}
      ${U.field({ label: 'จังหวัด', req: true, value: 'กรุงเทพมหานคร', disabled: true })}
      <div style="height:16px"></div>
    </div><div class="bottombar h84">${U.btn('ยืนยันตัวตน', { act: 'kycSubmitManual', cls: 'btn-r8' })}</div></div>`;
    }
    return '';
  };

  // ================= อื่น ๆ =================
  S.post = s => `${U.navRed('โพสต์รีวิว', { back: 'campaign', right: 'none' })}<div class="scroll page-white"><div class="post" style="border:0"><div class="post-h"><img src="${D.USER.avatar}"><b>${D.USER.username}</b><span class="star-badge">★</span></div><img class="post-img" src="${(s.draft && s.draft.images[0]) || 'assets/ph01.jpg'}"><div class="post-t">${(s.draft && s.draft.title) || 'ริมทะเลสาบสวยมาก เดินทั้งวันไม่เบื่อ'}</div><div class="post-c">${(s.draft && s.draft.caption) || '#WONDERONE2027 #SaleHereSTAR'}</div><div class="post-links">${Object.entries(s.links || {}).filter(([, v]) => v).map(([t, v]) => `<a>${U.socialIcon(t, 16)} ${v}</a>`).join('')}</div></div></div>`;
  S.chat = s => `${U.navRed('ผู้ช่วยส่วนตัว Sale Here', { back: 'campaign', right: 'none' })}<div class="scroll page-gray chat"><div class="msg">สวัสดีค่ะ ทีม Sale Here STAR ยินดีช่วยเหลือค่ะ 🙌</div><div class="msg">เรื่องกิจกรรม ${cur(s).ep} ใช่ไหมคะ แจ้งปัญหาได้เลย</div><div class="msg me">${s.order === 'parcelReject' ? 'พัสดุถูกตีกลับค่ะ ขอส่งใหม่ได้ไหม' : 'ส่งดราฟต์ไม่ทันค่ะ ขอขยายเวลาได้ไหม'}</div></div><div class="chat-in"><input placeholder="พิมพ์ข้อความ…"><button>${I('paper-plane-tilt', 20, 'fill')}</button></div>`;
  S.login = s => `<div class="login"><button class="onb-x" data-go="campaign" style="filter:invert(1)">${A('ic-close-white32', 32)}</button><div class="login-logo">${A('ic-salehere-logo-red42', 84)}</div><h3>ต้องการอ่านต่อ!</h3><p>สมัครสมาชิก หรือเข้าสู่ระบบด้วยเบอร์โทรศัพท์</p><input class="fld-in" placeholder="กรอกเบอร์โทรศัพท์"><div class="login-otp"><input class="fld-in" placeholder="กรอกรหัส OTP จาก SMS"><button class="btn btn-outline btn-md"><span>ขอ OTP</span></button></div>${U.btn('เข้าสู่ระบบ', { act: 'doLogin' })}<div class="login-or">ช่องทางอื่นๆ</div><div class="login-soc">${['facebook-logo', 'x-logo', 'user', 'at'].map(i => `<span>${I(i, 22, 'fill')}</span>`).join('')}</div></div>`;

  // ================= overlay: dialog + sheet =================
  window.renderOverlay = function (s) {
    const c = cur(s);
    const dl = {
      punish: () => U.dialog({ kind: 'modal', icon: 'ic-warning-outline', title: 'คุณถูกตัดสิทธิ์', detail: 'เนื่องจากคุณไม่ได้ส่งรีวิวกิจกรรม', buttons: [{ t: 'ตกลง', act: 'closeDialog' }] }),
      notReviewed: () => U.dialog({ icon: 'ic-fail-green82', title: 'คุณยังไม่ส่งรีวิว', detail: 'กรุณาส่งรีวิวก่อนหน้า<br>เพื่อลงทะเบียนกิจกรรมอื่นๆได้', buttons: [{ t: 'ปิด', act: 'closeDialog' }] }),
      punishServer: () => U.dialog({ icon: 'ic-fail-red82', title: 'คุณถูกตัดสิทธิ์', detail: 'เนื่องจากคุณไม่ได้ส่งรีวิวกิจกรรม', buttons: [{ t: 'ปิด', act: 'closeToRoot' }] }),
      maxRegister: () => U.dialog({ icon: 'ic-fail-green82', title: 'สิทธิ์ของกิจกรรมนี้เต็มแล้ว', detail: 'กรุณาทำรายการใหม่อีกครั้ง', buttons: [{ t: 'ปิด', act: 'closeToRoot' }] }),
      uniqueSocial: () => U.dialog({ icon: 'ic-fail-green82', title: 'ลิงก์โซเชียลของคุณถูกใช้ลงทะเบียนไปแล้ว', detail: 'บัญชีนี้ถูกใช้ลงทะเบียนกิจกรรมนี้แล้ว', buttons: [{ t: 'ปิด', act: 'closeDialog' }] }),
      registerSuccess: () => U.dialog({ kind: 'lottie', lottie: 'animationSuccessUnboxRegister', closable: true, title: 'ลงทะเบียนสำเร็จ', detail: 'ผู้ที่ผ่านการคัดเลือกจะได้รับการแจ้งเตือน<br>ให้ยืนยันสิทธิ์ผ่านแอปฯ Sale Here', sub: isVerified(s) ? '' : '*กรุณายืนยันตัวตน เพื่อความรวดเร็ว ในการผ่านการคัดเลือก!!', buttons: isVerified(s) ? [{ t: 'แชร์กิจกรรมนี้', act: 'shareClose', icon: 'icon_share' }] : [{ t: 'แชร์กิจกรรมนี้', style: 'gray', act: 'shareClose', icon: 'icon_share' }, { t: 'ยืนยันตัวตน', act: 'openKyc', icon: 'ic-verify-white' }] }),
      readBriefFirst: () => U.dialog({ kind: 'modal', title: 'โปรดอ่านรายละเอียดการรีวิวก่อนส่งดราฟต์​รีวิวของคุณ', buttons: [{ t: 'อ่านรายละเอียดการรีวิว', act: 'gotoBrief', icon: 'ic-review-detail' }] }),
      rejectReason: () => U.dialog({ icon: 'ic_disqualify', title: 'เหตุผลที่ถูกตัดสิทธิ์ เนื่องจาก : ไม่ตอบกลับทีมงานภายในเวลาที่กำหนด', buttons: [{ t: 'ปิด', act: 'closeDialog' }] }),
      acceptConfirm: () => U.dialog({ title: 'ยืนยันตอบรับกิจกรรม<br>Sale Here STAR ครั้งนี้', detail: 'กดยืนยันและรอรีวิวตามระยะเวลากิจกรรมได้เลย', buttons: [{ t: 'ยกเลิก', style: 'gray', act: 'closeDialog' }, { t: 'ยืนยัน', act: 'doAccept' }] }),
      declineConfirm: () => U.dialog({ title: 'ยืนยันสละสิทธิ์กิจกรรม<br>Sale Here STAR ครั้งนี้', buttons: [{ t: 'ยกเลิก', style: 'gray', act: 'closeDialog' }, { t: 'ยืนยัน', act: 'doDecline' }] }),
      acceptSuccess: () => U.dialog({ kind: 'lottie', lottie: 'animationSuccessUnboxRegister', closable: true, title: 'ยินดีด้วย!<br>คุณตอบรับกิจกรรมสำเร็จ', detail: isVerified(s) ? 'เตรียมร่วมโพสต์ รีวิวความปังได้เลย' : 'กรุณายืนยันตัวตน เพื่อรักษาสิทธิ์เข้าร่วมกิจกรรม<br>หากคุณยืนยันตัวตนแล้วจะไม่ถูกตัดสิทธิ์', buttons: isVerified(s) ? [{ t: 'อ่านรายละเอียดการรีวิว', act: 'gotoBrief', icon: 'ic-review-detail' }] : [{ t: 'ยืนยันตัวตน', act: 'openKycUnbox', icon: 'ic-verify-white' }] }),
      draftSent: () => U.dialog({ icon: 'ic-success-green82', title: 'ส่งดราฟต์รีวิวแล้ว', detail: 'คุณสามารถตรวจสอบสถานะการตรวจได้ที่ <span class="dlg-hl">“ปุ่มสถานะดราฟต์รีวิว”</span> ในหน้าโปรไฟล์ หรือ ในหน้ารายละเอียด Sale Here STAR, Rewards ที่คุณได้รับรางวัล', buttons: [{ t: 'ตกลง', act: 'closeDialog' }] }),
      cancelDraft: () => U.dialog({ title: 'ต้องการยกเลิกส่งดราฟต์รีวิวหรือไม่', detail: 'รีวิวของคุณจะถูกเก็บไว้ในแบบร่าง คุณสามารถแก้ไขและส่งดราฟต์รีวิวนี้ได้ในภายหลัง', buttons: [{ t: 'ปิด', style: 'gray', act: 'closeDialog' }, { t: 'ยืนยัน', act: 'doCancelDraft' }] }),
      linkSuccess: () => U.dialog({ kind: 'lottie', lottie: 'animationSuccessUnboxRegister', title: 'ส่งลิงก์รีวิวสำเร็จ', detail: 'เสร็จสิ้นการส่งรีวิวกิจกรรม<br>ขอบคุณที่ร่วมกิจกรรมกับ Sale Here STAR', buttons: [{ t: 'ตกลง', act: 'closeToRoot' }] }),
      waitVerify: () => U.dialog({ kind: 'modal', title: 'กำลังตรวจสอบข้อมูลของคุณ<br>ใช้เวลาประมาณ 1-3 วันทำการ', detail: 'เมื่อได้รับการอนุมัติ เราจะแจ้งเตือนให้คุณทราบ<br>คุณจะสามารถสร้างโปรไฟล์ครีเอเตอร์ได้ทันที', buttons: [{ t: 'ตกลง', act: 'closeDialog' }] }),
      kycProcessing: () => `<div class="dlg-wrap"><div class="dlg r20" style="padding:24px"><div class="dlg-title" style="font-size:20px;font-weight:700;color:#232323">ระบบกำลังประมวลผลภาพ</div><div class="dlg-detail" style="color:#919191;font-weight:400">ขั้นตอนนี้อาจใช้เวลาประมาณ 1–2 นาที<br>กรุณาอย่าปิดหรือออกจากหน้านี้จนกว่าระบบ<br>จะดำเนินการเสร็จสิ้น</div><div class="spin"></div></div></div>`,
      kycConfirm: () => U.dialog({ kind: 'modal', title: 'กรุณายืนยันการส่งข้อมูล<br>เพื่อยืนยันตัวตน', detail: `<div style="color:#919191;font-weight:400">โปรดตรวจสอบข้อมูลของคุณอีกครั้งก่อนส่ง!</div><div class="kyc-recap"><img src="assets/ic/ic-thaiid-correct.png"><div><b>เลขบัตรประชาชน :</b> 1 1012 34567 89 0<br><b>วันที่บัตรหมดอายุ :</b> 13/02/2574<br><b>ชื่อ :</b> นางสาว มณีรัตน์ ใจดี<br><b>วันเกิด :</b> 14/02/2541<br><b>ที่อยู่ :</b> 99/12 ซ.สุขุมวิท 77 สวนหลวง กรุงเทพมหานคร 10250</div></div>`, buttons: [{ t: 'แก้ไข', style: 'cancel', act: 'kycEdit' }, { t: 'ยืนยัน', act: 'kycSubmitAuto' }] }),
      kycRetry: () => U.dialog({ kind: 'modal', icon: 'ic-warning-outline', title: s.kyc.aiResult === 'faceMismatch' ? 'ใบหน้าไม่ตรงกับบัตรประชาชน' : 'รูปบัตรประชาชนไม่ชัดเจน', detail: `AI ตรวจไม่ผ่าน (ครั้งที่ ${s.kyc.fails}/3)<br>กรุณาถ่ายรูปใหม่ตามคำแนะนำ`, buttons: [{ t: 'ลองอีกครั้ง', act: 'kycRetry' }] }),
      kycToManual: () => U.dialog({ kind: 'modal', icon: 'ic-warning-outline', title: 'AI ตรวจไม่ผ่าน 3 ครั้ง', detail: 'กรุณากรอกข้อมูลด้วยตนเอง<br>ทีมงานจะตรวจสอบให้ภายใน 1-3 วันทำการ', buttons: [{ t: 'กรอกข้อมูล', act: 'kycGoForm' }] }),
      kycTerminal: () => U.dialog({ kind: 'modal', icon: 'ic-error2-outline', title: s.kyc.aiResult === 'expired' ? 'บัตรประชาชนหมดอายุ ไม่สามารถทำรายการได้' : 'บัตรประชาชนนี้ถูกใช้ยืนยันตัวตนแล้ว', buttons: s.kyc.aiResult === 'exist' ? [{ t: 'ติดต่อทีม Sale here', act: 'kycExitChat' }] : [{ t: 'ปิด', act: 'kycExitNow' }] }),
      kycAutoSuccess: () => U.dialog({ kind: 'modal', icon: 'ic-sealcheck-gradient', title: 'ยืนยันตัวตนเสร็จสมบูรณ์', detail: 'ยินดีต้อนรับสู่ประสบการณ์ใหม่ที่ครบครันกว่าเดิม<br>สิทธิพิเศษของคุณพร้อมใช้งานแล้ว', buttons: [{ t: 'ตกลง', act: 'kycDone' }] }),
      kycManualSuccess: () => U.dialog({ kind: 'modal', icon: 'ic-sealcheck-gradient', title: 'ส่งคำขอยืนยันตัวตนสำเร็จ', detail: 'รอการอนุมัติภายใน 7 วันทำการ', buttons: [{ t: 'ปิด', act: 'kycDone' }] }),
      kycUnboxSuccess: () => U.dialog({ kind: 'lottie', lottie: 'animationSuccessUnboxRegister', title: 'ยินดีด้วย!<br>คุณตอบรับกิจกรรมสำเร็จ', detail: 'เตรียมร่วมโพสต์ รีวิวความปังได้เลย', buttons: [{ t: 'อ่านรายละเอียดการรีวิว', act: 'gotoBrief', icon: 'ic-review-detail' }] }),
      exitKyc: () => U.dialog({ kind: 'modal', title: 'ออกจากหน้ายืนยันตัวตน', detail: 'ออกจากหน้ายืนยันตัวตนใช่หรือไม่?', buttons: [{ t: 'ยกเลิก', style: 'cancel', act: 'closeDialog' }, { t: 'ยืนยัน', act: 'kycExitNow' }] }),
      share: () => U.dialog({ title: 'แชร์กิจกรรมนี้', detail: `<div class="share-grid">${['คัดลอกลิงก์', 'Messenger', 'Facebook', 'Instagram', 'Instagram Stories', 'LINE', 'X', 'เพิ่มเติม'].map(t => `<span><i>${I(t === 'คัดลอกลิงก์' ? 'copy' : t === 'เพิ่มเติม' ? 'dots-three' : 'share-network', 22)}</i>${t}</span>`).join('')}</div>`, buttons: [{ t: 'ปิด', style: 'gray', act: 'closeDialog' }] }),
    };
    const sh = {
      steps: () => U.sheet({ icon: 'ic-createor-cup', h500: true, title: 'สร้างโปรไฟล์ครีเอเตอร์', subtitle: 'เพิ่มข้อมูลของคุณให้ครบถ้วนเพื่อรับงานรีวิวกับเรา', body: `
        <div class="steps-prog"><b>สำเร็จแล้ว : ${s.user.welcome.filter(Boolean).length}/3</b><span class="steps-badge">ได้รับ : ${A('ic-star-badge', 16)}</span></div>
        <div class="steps-bar"><i style="width:${s.user.welcome.filter(Boolean).length / 3 * 100}%"></i></div>
        ${['ขั้นตอนที่ 1 : ผูกบัญชีโซเชียลมีเดียของคุณ', 'ขั้นตอนที่ 2 : เลือกหมวดหมู่ที่คุณถนัดและสนใจ', 'ขั้นตอนที่ 3 : ยืนยันตัวตนเพื่อรับงานรีวิว'].map((t, i) => {
          const done = s.user.welcome[i], active = !done && s.user.welcome.slice(0, i).every(Boolean);
          const vchip = i === 2 ? (s.user.verify === 'approved' ? '<span class="vchip ok">สำเร็จ</span>' : s.user.verify === 'reject' ? '<span class="vchip bad">ไม่ผ่าน</span>' : s.user.verify === 'waiting_approve' ? '<span class="vchip wait">รอพิจารณา</span>' : '') : '';
          return `<div class="step-row ${done ? 'done' : ''} ${active ? 'active' : ''}" data-do="stepRow" data-i="${i}">${A(done ? 'ic-checkCircle-outline' : active ? 'ic-checkcircle-stroke-outline' : 'ic-checkCircle-disable-outline', 20)}<span>${t}</span>${vchip}</div>`;
        }).join('')}
        <div class="steps-foot">${U.btn(welcomeDone(s) ? 'เริ่มต้นการเป็น STAR ของคุณ' : 'เริ่มทำเลย', { act: 'stepsCta', cls: 'btn-h44' })}</div>` }),
      socialConnect: () => U.sheet({ title: 'ผูกบัญชีโซเชียลมีเดียของคุณ', full: true, body: `<div style="height:8px"></div>` + D.USER.socials.map(so => `<div class="soc-card" style="margin:0 0 12px"><div class="soc-row">${U.socialIcon(so.type, 44, 'social')}<div class="soc-n"><b>${D.SOCIAL_META[so.type].name.toUpperCase()}</b>${so.connected ? `<span>${so.url}</span>` : ''}</div>${so.connected ? `<span class="soc-chip ok">ผูกบัญชีแล้ว</span>` : `<button class="btn btn-red btn-xs" data-do="connectSocial" data-t="${so.type}"><span>ผูกบัญชี</span></button>`}</div>${so.connected ? `<div class="soc-fol">${I('users-three', 14)} ${U.fmtNum(so.followers)} ผู้ติดตาม · <a class="link-red">ราคารับงานต่อโพสต์</a></div>` : ''}</div>`).join('') + `<div class="sheet-cta">${U.btn('เสร็จสิ้น', { act: 'socialDone' })}</div>` }),
      categories: () => U.sheet({ title: 'เลือกหมวดหมู่ที่คุณถนัดและสนใจ', subtitle: 'เลือกอย่างน้อย 3 หมวดหมู่', full: true, body: `<div class="cat-grid">${['💄 บิวตี้', '👗 แฟชั่น', '🍜 อาหาร & เครื่องดื่ม', '☕️ คาเฟ่', '✨ ไลฟ์สไตล์', '✈️ ท่องเที่ยว', '💪 สุขภาพ', '👶 แม่และเด็ก', '🐶 สัตว์เลี้ยง', '📱 เทคโนโลยี', '🎮 เกม', '🪴 บ้าน & สวน', '🚗 รถยนต์', '💰 การเงิน', '📚 การศึกษา', '⚽️ กีฬา', '🎬 บันเทิง', '🎪 อีเวนต์'].map((c, i) => `<span class="cat ${[1, 3, 5].includes(i) ? 'on' : ''}">${c}</span>`).join('')}</div><div class="sheet-cta">${U.btn('บันทึก', { act: 'categoriesDone' })}</div>` }),
      insight: () => U.sheet({ title: 'ข้อมูลผู้ติดตาม', full: true, body: `<h4 class="ins-h">วิธีอัปโหลดรูป Insights ของคุณ</h4><ol class="ins-steps"><li>เปิดแอป Instagram</li><li>เข้าหน้าข้อมูลผู้ติดตาม<br><small>เพศ · ช่วงอายุ · พื้นที่ยอดนิยม</small></li><li>แคป 3 ภาพ แล้วกลับมาอัปโหลดที่นี่</li></ol><div class="sec-title" style="margin-left:0">แนบข้อมูลผู้ติดตามของคุณ <small>1/3</small></div><p style="font-size:12px;color:#828282;margin:0 0 8px">แนบภาพหน้าสถิติของแต่ละหมวด สรุปจะขึ้นให้ทันที</p><div class="ins-slots">${['เพศ', 'ช่วงอายุ', 'พื้นที่ยอดนิยม'].map((t, i) => `<div class="ins-slot ${i === 0 ? 'ok' : ''}"><div class="box">${i === 0 ? I('check-circle', 22, 'fill') : I('plus', 22)}</div><b>${t}</b><span>${i === 0 ? 'บันทึกภาพแล้ว' : 'แตะช่องรูปเพื่อแนบภาพ'}</span></div>`).join('')}</div><div class="sheet-cta">${U.btn('เปิดแอป', { style: 'outline', act: 'closeSheet' })}</div>` }),
      editAddress: () => U.sheet({ title: 'ที่อยู่สำหรับรับของรีวิว', full: true, body: `<div style="height:8px"></div>${U.field({ label: 'ชื่อ - นามสกุล', req: true, value: D.USER.address.name })}${U.field({ label: 'เบอร์โทรศัพท์', req: true, value: D.USER.address.tel })}${U.field({ label: 'รายละเอียดที่อยู่', req: true, value: D.USER.address.address, multiline: true })}${U.field({ label: 'รหัสไปรษณีย์', req: true, value: D.USER.address.zipcode })}${U.field({ label: 'ตำบล/แขวง', req: true, value: D.USER.address.subDistrict, select: true })}${U.field({ label: 'อำเภอ/เขต', req: true, value: D.USER.address.district, disabled: true })}${U.field({ label: 'จังหวัด', req: true, value: D.USER.address.province, disabled: true })}<div class="sheet-cta">${U.btn('บันทึก', { act: 'addressSaved' })}</div>` }),
      decline: () => `<div class="dlg-wrap"><div class="dlg" style="padding-top:24px"><div class="dlg-title" style="font-size:14px;font-weight:500;text-align:left;width:100%;padding:0 8px"><em style="color:#ED1C24;font-style:normal">*</em>กรุณากรอกเหตุผลขอสละสิทธิ์ครั้งนี้</div><div style="width:100%;padding:0 8px">${U.field({ value: s.form?.reason || '', bind: 'form.reason', placeholder: 'กรอกเหตุผล', multiline: true, cls: 'nopad' })}</div><div class="dlg-btns">${U.btn('ยกเลิก', { style: 'gray', act: 'closeSheet', size: 'md' })}${U.btn('บันทึก', { act: 'declineAskConfirm', size: 'md', enabled: !!(s.form && s.form.reason) })}</div></div></div>`,
      starDetail: () => U.sheet({ title: 'ข้อมูลโปรไฟล์ของคุณ', full: true, body: `<div class="sd-head"><img src="${D.USER.avatar}"><b>${D.USER.username} ${isVerified(s) ? `<span class="verified-blue">${I('seal-check', 18, 'fill')}</span>` : ''}</b><span>27 ปี, กรุงเทพมหานคร</span></div>
        ${!isVerified(s) ? `<div class="sd-verify">${A('ic-Time', 20)}<div><b>กำลังตรวจสอบการยืนยันตัวตน</b>ระบบใช้เวลาตรวจสอบประมาณ 1-3 วันทำการ</div></div>` : ''}
        <div class="sec-title" style="margin-left:0">บัญชีโซเชียลที่รับงานรีวิว</div>${D.USER.socials.filter(x => x.connected).map(so => `<div class="sd-soc">${U.socialIcon(so.type, 22)}<b>${so.handle}</b><span>${U.fmtNum(so.followers)} ผู้ติดตาม</span><em>รูปภาพ ฿1,500 · วิดีโอสั้น ฿3,000 ต่อโพสต์</em></div>`).join('')}
        <div class="sec-title" style="margin-left:0">หมวดหมู่ที่สนใจ</div><div class="cat-grid">${D.USER.categories.map(c => `<span class="cat on">${c}</span>`).join('')}</div>
        <div class="sheet-cta">${U.btn('สร้างโปรไฟล์ครีเอเตอร์', { act: 'starDetailCta', cls: 'btn-h44' })}</div>` }),
    };
    return (s.dialog && dl[s.dialog] ? dl[s.dialog]() : '') + (s.sheet && sh[s.sheet] ? sh[s.sheet]() : '');
  };

  // ================= ACTIONS =================
  const go = (screen, extra = {}) => Store.set(Object.assign({ screen, dialog: null, sheet: null }, extra));

  Ac.bind = (path, value) => {
    const s = Store.get();
    const parts = path.split('.');
    if (parts[0] === 'form' || parts[0] === 'draft' || parts[0] === 'links') {
      const obj = Object.assign({}, s[parts[0]] || (parts[0] === 'draft' ? { title: '', caption: '', images: [] } : {}));
      if (parts[0] === 'form' && document.querySelectorAll(`input[type=checkbox][data-bind="${path}"]`).length > 1) {
        obj[parts[1]] = [...document.querySelectorAll(`input[type=checkbox][data-bind="${path}"]:checked`)].map(i => i.value);
      } else obj[parts[1]] = value;
      Store.set({ [parts[0]]: obj });
      return;
    }
    if (path === 'user.consent') { Store.set({ user: { consent: !!value } }); return; }
    if (path === 'kyc.docTypeLabel') { Store.set({ kyc: { docType: value === 'Passport' ? 'passport' : 'idcard' } }); return; }
  };

  Ac.none = () => {};
  Ac.closeDialog = () => Store.set({ dialog: null });
  Ac.closeSheet = () => Store.set({ sheet: null });
  Ac.closeToRoot = () => go('campaign');
  Ac.openSheet = d => Store.set({ sheet: d.sheet });
  Ac.openVerdictSheet = () => Store.set({ sheet: 'verdict' });
  Ac.tab = d => Store.set({ reviewTab: d.tab === 'review' });
  Ac.myTab = d => Store.set({ myTab: d.tab });
  Ac.share = () => Store.set({ dialog: 'share' });
  Ac.shareClose = () => Store.set({ dialog: 'share' });
  Ac.rejectReason = () => Store.set({ dialog: 'rejectReason' });
  Ac.openCampaign = (d, b, e) => { e.stopPropagation(); go('campaign', { campaignSlug: d.slug, reviewTab: false }); };
  Ac.cardRegister = (d, b, e) => { e.stopPropagation(); Store.set({ campaignSlug: d.slug }); Ac.tapRegister(); };
  Ac.doLogin = () => { Store.set({ user: { isLogin: true } }); go('campaign'); };

  // ---- ด่านตอนกดสมัคร (ValidateRegisterSaleHereStarManagerInteractor:20-40) ----
  Ac.tapRegister = () => {
    const s = Store.get();
    if (!s.user.isLogin) return go('login');
    if (s.user.reviewStatus === 'reviewPending') return Store.set({ dialog: 'punish' });
    if (!welcomeDone(s)) return go('onboarding');
    if (s.user.percent !== 100) return go('onboarding');
    go('register');
  };
  Ac.tapMain = () => {
    const s = Store.get();
    switch (s.campaign) {
      case 'register': return Ac.tapRegister();
      case 'awardAnnouncement': return go('awardList');
      case 'waitingAcceptQuota': return go('accept');
      case 'forceVerifyUser': return Ac.openKycUnbox();
      case 'acceptedQuota': return s.order === 'parcelReject' ? go('chat') : go('brief');
      default: return;
    }
  };
  Ac.reviewAction = d => {
    const s = Store.get();
    switch (d.a) {
      case 'brief': return go('brief');
      case 'createDraft': return s.briefRead ? go('draft') : Store.set({ dialog: 'readBriefFirst' });
      case 'editDraft': return go('draft');
      case 'preview': return go('preview');
      case 'verdict': return go('verdict', { sheet: 'verdict' });
      case 'link': return go('link');
      case 'chat': return go('chat');
      case 'post': return go('post');
    }
  };
  Ac.gotoBrief = () => go('brief', { briefRead: true });
  Ac.briefRead = () => { const s = Store.get(); Store.set({ briefRead: true }); if (s.review === 'waitingDraft' || s.review === 'draft') go('draft'); else go('campaign', { reviewTab: true }); };

  // ---- ฟอร์มสมัคร ----
  Ac.mockUpload = (d, b, e) => {
    e && e.stopPropagation();
    const s = Store.get();
    const [root, key] = d.k.split('.');
    const obj = Object.assign({}, s[root] || (root === 'draft' ? { title: '', caption: '', images: [] } : {}));
    const pool = ['assets/ph01.jpg', 'assets/ph04.jpg', 'assets/ph02.jpg', 'assets/ph03.jpg'];
    const arr = (obj[key] || []).slice(); arr.push(pool[arr.length % pool.length]); obj[key] = arr;
    window.__keepScroll = true;
    Store.set({ [root]: obj });
  };
  Ac.submitRegister = () => {
    const s = Store.get();
    if (s.user.punishment === 'warn') return Store.set({ dialog: 'notReviewed' });
    if (s.user.punishment === 'banned') return Store.set({ dialog: 'punishServer' });
    Store.set({ campaign: 'registered', screen: 'campaign', dialog: 'registerSuccess', reviewTab: false });
  };
  Ac.connectSocial = d => { const so = D.USER.socials.find(x => x.type === d.t); so.connected = true; so.handle = D.USER.username.toLowerCase(); so.url = `https://${d.t}.com/${D.USER.username.toLowerCase()}`; so.followers = 5200; window.__keepScroll = true; Store.set({}); Store.toast('ผูกบัญชีสำเร็จ'); };
  Ac.socialDone = () => { const s = Store.get(); const w = s.user.welcome.slice(); w[0] = true; Store.set({ user: { welcome: w }, sheet: s.screen === 'register' ? null : 'steps' }); Store.toast('บันทึกสำเร็จ'); };
  Ac.categoriesDone = () => { const w = Store.get().user.welcome.slice(); w[1] = true; Store.set({ user: { welcome: w }, sheet: 'steps' }); Store.toast('บันทึกสำเร็จ'); };
  Ac.addressSaved = () => { Store.set({ sheet: null }); Store.toast('บันทึกสำเร็จ'); };

  // ---- onboarding ----
  Ac.goSteps = () => Store.set({ screen: 'campaign', sheet: 'steps', dialog: null });
  Ac.stepRow = d => {
    const i = Number(d.i), s = Store.get();
    if (s.user.welcome[i] || !s.user.welcome.slice(0, i).every(Boolean)) return;
    if (i === 0) Store.set({ sheet: 'socialConnect' });
    if (i === 1) Store.set({ sheet: 'categories' });
    if (i === 2) Ac.openKyc();
  };
  Ac.stepsCta = () => {
    const s = Store.get();
    if (welcomeDone(s)) return Store.set({ sheet: 'starDetail' });
    const i = s.user.welcome.findIndex(x => !x); Ac.stepRow({ i });
  };
  Ac.starDetailCta = () => { const s = Store.get(); if (!isVerified(s)) return Store.set({ dialog: 'waitVerify' }); go('profileHub'); };
  Ac.creatorProfile = () => { const s = Store.get(); if (!welcomeDone(s)) return Store.set({ sheet: 'steps' }); go('profileHub'); };
  Ac.goProfileHub = () => go('profileHub');
  Ac.hubRow = () => { const s = Store.get(); let p = Math.min(100, s.user.percent + 17); if (p >= 95) p = 100; Store.set({ user: { percent: p } }); Store.toast('บันทึกสำเร็จ'); };
  Ac.previewProfile = () => { const s = Store.get(); if (s.user.percent < 100) return Store.toast('กรุณาเพิ่มข้อมูลให้ครบถ้วน'); go('campaign'); Store.toast('โปรไฟล์ครบ 100% แล้ว · กดสมัครได้เลย'); };

  // ---- ตอบรับ / สละสิทธิ์ ----
  Ac.acceptAsk = () => Store.set({ dialog: 'acceptConfirm' });
  Ac.doAccept = () => { const v = isVerified(Store.get()); Store.set({ campaign: v ? 'acceptedQuota' : 'forceVerifyUser', review: v ? 'notOpenDraft' : 'forceVerifyUser', order: 'preparing', screen: 'campaign', dialog: 'acceptSuccess' }); };
  Ac.declineAsk = () => Store.set({ sheet: 'decline' });
  Ac.declineAskConfirm = () => Store.set({ sheet: null, dialog: 'declineConfirm' });
  Ac.doDecline = () => { Store.set({ campaign: 'rejectQuotaByUser', review: 'none', screen: 'campaign', sheet: null, dialog: null }); Store.toast('สละสิทธิ์เข้าร่วมกิจกรรมแล้ว'); };

  // ---- ดราฟต์ / ลิงก์ ----
  Ac.saveDraft = () => { Store.set({ review: 'draft', screen: 'campaign', reviewTab: true }); Store.toast('บันทึกแบบร่างแล้ว'); };
  Ac.submitDraft = () => Store.set({ review: 'waitingApproveDraft', screen: 'preview', dialog: 'draftSent' });
  Ac.editDraft = () => go('draft');
  Ac.cancelDraft = () => Store.set({ dialog: 'cancelDraft' });
  Ac.doCancelDraft = () => { Store.set({ review: 'draft', dialog: null }); Store.toast('ยกเลิกส่งตรวจรีวิวสำเร็จ และบันทึกไว้ที่แบบร่างของคุณแล้ว'); };
  Ac.submitLinks = () => Store.set({ review: 'reviewed', screen: 'campaign', reviewTab: true, dialog: 'linkSuccess' });

  // ---- KYC ----
  Ac.openKyc = () => Store.set({ screen: 'kyc', kyc: { step: 'type', unbox: false }, dialog: null, sheet: null });
  Ac.openKycUnbox = () => Store.set({ screen: 'kyc', kyc: { step: 'type', unbox: true }, dialog: null, sheet: null });
  const ORDER = ['type', 'instruction', 'camera', 'preview', 'instruction2', 'camera2', 'preview2'];
  Ac.kycNext = () => {
    const k = Store.get().kyc, i = ORDER.indexOf(k.step);
    if (i < ORDER.length - 1) return Store.set({ kyc: { step: ORDER[i + 1] } });
    Store.set({ dialog: 'kycProcessing' });
    setTimeout(Ac.kycAiResult, 1400);
  };
  Ac.kycShot = () => Store.set({ kyc: { step: Store.get().kyc.step === 'camera' ? 'preview' : 'preview2' } });
  Ac.kycBack = () => { const k = Store.get().kyc, i = ORDER.indexOf(k.step); if (i <= 0) return Ac.kycExit(); Store.set({ kyc: { step: ORDER[i - 1] } }); };
  Ac.kycAiResult = () => {
    const s = Store.get(), r = s.kyc.aiResult;
    if (r === 'pass') return Store.set({ dialog: 'kycConfirm' });
    if (r === 'expired' || r === 'exist') return Store.set({ dialog: 'kycTerminal' });
    const fails = s.kyc.fails + 1;
    if (fails >= 3) return Store.set({ kyc: { fails }, dialog: 'kycToManual' });
    Store.set({ kyc: { fails }, dialog: 'kycRetry' });
  };
  Ac.kycRetry = () => Store.set({ kyc: { step: 'instruction' }, dialog: null });
  Ac.kycGoForm = () => Store.set({ kyc: { step: 'form' }, dialog: null });
  Ac.kycEdit = () => Store.set({ kyc: { step: 'form' }, dialog: null });
  Ac.kycSubmitAuto = () => { const w = Store.get().user.welcome.slice(); w[2] = true; Store.set({ user: { verify: 'approved', welcome: w }, dialog: 'kycAutoSuccess' }); };
  Ac.kycSubmitManual = () => Store.set({ user: { verify: 'waiting_approve' }, dialog: 'kycManualSuccess' });
  Ac.kycDone = () => {
    const s = Store.get();
    if (s.kyc.unbox) {
      Store.set({ campaign: 'acceptedQuota', review: 'notOpenDraft', screen: 'campaign', dialog: isVerified(s) ? 'kycUnboxSuccess' : null, kyc: { step: 'type', fails: 0 } });
      return;
    }
    Store.set({ screen: 'campaign', dialog: null, sheet: welcomeDone(s) ? 'starDetail' : 'steps', kyc: { step: 'type', fails: 0 } });
  };
  Ac.kycExit = () => Store.set({ dialog: 'exitKyc' });
  Ac.kycExitNow = () => go('campaign', { kyc: { step: 'type', fails: 0 } });
  Ac.kycExitChat = () => go('chat', { kyc: { step: 'type', fails: 0 } });

  // นาฬิกาเดินทุกวินาที (อัปเดตเฉพาะตัวเลข ไม่ render ใหม่ทั้งจอ)
  setInterval(() => { document.querySelectorAll('.clk').forEach(el => { el.outerHTML = U.clock(left()); }); }, 1000);

  // lottie: โหลดจากไฟล์ json ของแอปจริง (animationSuccessUnboxRegister · home_title_sale_here_star · unboxCelebration)
  window.afterRender = function (s) {
    document.body.classList.toggle('dark-status', ['onboarding', 'login'].includes(s.screen) || (s.screen === 'kyc' && /camera|preview/.test(s.kyc.step)));
    if (!window.lottie) return;
    document.querySelectorAll('.lottie[data-anim]').forEach(el => {
      if (el.dataset.loaded) return; el.dataset.loaded = '1';
      window.lottie.loadAnimation({ container: el, renderer: 'svg', loop: true, autoplay: true, path: `assets/${el.dataset.anim}.json` });
    });
  };
})();
