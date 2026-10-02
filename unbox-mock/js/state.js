// store กลางของ mock — state ทั้งหมดอยู่ที่นี่ แผงควบคุมและหน้าจออ่าน/เขียนผ่าน set()
// เก็บลง localStorage + เข้ารหัสใน URL hash ให้แชร์ลิงก์ที่ state เดิมได้

window.Store = (function () {
  const KEY = 'unbox-mock-state-v1';

  const DEFAULT = {
    screen: 'home',           // home | campaign | register | accept | brief | draft | verdict | preview | link | myCampaigns | awardList | kyc | onboarding | onboardingSteps | profileHub | post | chat
    campaignSlug: 'wonder-one-2027',
    campaign: 'register',     // BrandCampaignState
    review: 'none',           // BrandCampaignReviewState
    order: 'preparing',       // OrderStatus
    quota: 'primary',         // primary | backup
    won: true,                // ผลประกาศ (awardAnnouncement)
    reviewTab: false,         // แท็บ "รีวิว" เปิดอยู่ไหม
    briefRead: false,         // อ่าน "รายละเอียดการรีวิว" แล้ว (ต้องอ่านก่อนสร้างดราฟต์)
    draft: null,              // { title, caption, images:[...] }
    links: {},                // { instagram: url, tiktok: url }
    dialog: null,             // key ของ dialog ที่เปิดอยู่
    sheet: null,              // key ของ bottom sheet ที่เปิดอยู่
    toast: null,
    kyc: { step: 'type', docType: 'idcard', fails: 0, aiResult: 'pass' }, // aiResult: pass | notClear | faceMismatch
    user: {
      isLogin: true,
      welcome: [true, true, false],   // ผูกโซเชียล · เลือกหมวด · ยืนยันตัวตน
      percent: 67,                    // creatorProfile.profileProgress.percentTotal
      verify: 'none',                 // none | waiting_approve | approved | reject
      punishment: 'none',             // none | warn | banned
      reviewStatus: 'none',           // none | reviewComplete | reviewPending
      consent: false,
    },
    devPanel: true,
    // flow ใหม่ (แทรก StarCard เข้า Unbox) — 'old' | 'new' · new.html ตั้ง window.DEFAULT_FLOW = 'new'
    flow: (window.DEFAULT_FLOW || 'old'),
    // ข้อมูลที่กรอกไว้ใน Star Profile แล้ว — ติ๊กในแผง: มี = เติมให้/ข้าม · ไม่มี = ถามตรงขั้นที่ใช้
    profile: { socials: false, categories: false, about: false, rate: false, insight: false, consent: false, address: false, draftRounds: false, availability: false, contact: false, bank: false, measurements: false, province: false, video: false },
    myTab: 'all',
  };

  let state = load();
  const listeners = [];

  function load() {
    let s = JSON.parse(JSON.stringify(DEFAULT));
    try {
      const h = location.hash.replace(/^#/, '');
      if (h) { const p = JSON.parse(decodeURIComponent(atob(h))); s = deepMerge(s, p); return s; }
    } catch (e) {}
    try {
      const raw = localStorage.getItem(KEY);
      if (raw) s = deepMerge(s, JSON.parse(raw));
    } catch (e) {}
    return s;
  }
  function persist() {
    try { localStorage.setItem(KEY, JSON.stringify(state)); } catch (e) {}
    try {
      const { toast, dialog, sheet, ...rest } = state;
      history.replaceState(null, '', '#' + btoa(encodeURIComponent(JSON.stringify(rest))));
    } catch (e) {}
  }
  function deepMerge(a, b) {
    const out = Array.isArray(a) ? a.slice() : Object.assign({}, a);
    for (const k in b) {
      if (b[k] && typeof b[k] === 'object' && !Array.isArray(b[k]) && a && typeof a[k] === 'object' && !Array.isArray(a[k])) out[k] = deepMerge(a[k], b[k]);
      else out[k] = b[k];
    }
    return out;
  }

  function get() { return state; }
  function set(patch) {
    state = deepMerge(state, patch);
    persist();
    listeners.forEach(fn => fn(state));
  }
  function reset() { state = JSON.parse(JSON.stringify(DEFAULT)); persist(); listeners.forEach(fn => fn(state)); }
  function subscribe(fn) { listeners.push(fn); }

  /// ใช้ preset / step: `set` ของมันมี user แยกออกมา
  function applyScenario(sc) {
    const p = Object.assign({}, sc.set);
    const patch = {};
    if (p.user) { patch.user = p.user; delete p.user; }
    if (p.hint) delete p.hint;
    Object.assign(patch, p);
    if (!('dialog' in patch)) patch.dialog = null;
    patch.sheet = null;
    set(patch);
  }

  function toast(msg) {
    set({ toast: msg });
    clearTimeout(toast._t);
    toast._t = setTimeout(() => set({ toast: null }), 1800);
  }

  return { get, set, reset, subscribe, applyScenario, toast, DEFAULT };
})();
