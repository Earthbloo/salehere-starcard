// คอมโพเนนต์ร่วม — ถอดจาก BaseRedNavigationController · BaseCampaignButton · AlertDialog/AnimatedConfirmDialog/BaseModalView · BaseBottomSheet
// ไอคอนใช้ asset จริงของแอป (assets/ic/*.png ที่ render จาก pdf/svg ของ salehere-ios)

window.UI = (function () {
  const I = window.icon;
  const SVG_ASSETS = new Set(['ic-exclamation-mark', 'ic-chevron-grey-1000']);
  /// รูป asset จริง — `A('ic-calendar-gray14', 14)`
  function A(name, size, cls = '') {
    const ext = SVG_ASSETS.has(name) ? 'svg' : 'png';
    const w = size ? `width="${size}" height="${size}"` : '';
    return `<img class="ic ${cls}" src="assets/ic/${name}.${ext}" ${w} alt="">`;
  }

  /// แถบแดง: back = ic-back-white · close = ic-close-white32 · ขวา = support32 + bell
  function navRed(title, { back = 'home', right = 'star', close = false, backAct = null } = {}) {
    const leftAttr = backAct ? `data-do="${backAct}"` : `data-go="${back}"`;
    const left = close ? '' : `<button class="nav-btn" ${leftAttr}>${A('ic-back-white', 32)}</button>`;
    const closeBtn = close ? `<button class="nav-btn" ${leftAttr}>${A('ic-close-white32', 32)}</button>` : '';
    const rights = right === 'star'
      ? `<button class="nav-btn">${A('ic-reward-support32', 32)}</button><button class="nav-btn">${A('ic-bell-white32', 32)}</button>${closeBtn}`
      : right === 'none' ? closeBtn : right + closeBtn;
    return `<header class="nav-red"><div class="nav-l">${left}</div><div class="nav-t">${title}</div><div class="nav-r">${rights}</div></header>`;
  }

  /// ปุ่มตระกูล BaseCampaignButton: red · gray · graydis · green · reddis · yellow · outline · outline-star · blue
  function btn(title, { style = 'red', enabled = true, icon = null, iconSize = 20, go = null, act = null, size = 'lg', extra = '', cls = '' } = {}) {
    const attrs = [go ? `data-go="${go}"` : '', act ? `data-do="${act}"` : '', enabled ? '' : 'disabled', extra].join(' ');
    return `<button class="btn btn-${style} btn-${size} ${cls}" ${attrs}>${icon ? A(icon, iconSize) : ''}<span>${title}</span></button>`;
  }

  /// นาฬิกาถอยหลัง: กล่อง 16×16 r4 #333 ตัวเลข 10 SemiBold ขาว
  function clock(seconds) {
    const d = Math.floor(seconds / 86400), h = Math.floor((seconds % 86400) / 3600), m = Math.floor((seconds % 3600) / 60), sec = seconds % 60;
    const box = v => `<span class="clk-box">${String(v).padStart(2, '0')}</span>`;
    return `<span class="clk">${d > 0 ? box(d) + '<i>:</i>' : ''}${box(h)}<i>:</i>${box(m)}<i>:</i>${box(sec)}</span>`;
  }

  /// dialog:
  ///  kind 'alert'  = AlertDialogView (r12, icon 82, title 16 SemiBold, detail 14 #828282, ปุ่ม 40 r10)
  ///  kind 'modal'  = BaseModalView (r20, icon 140 ลอยเหนือการ์ด, title 18 Bold, ปุ่ม 44 r8, cancel ขอบแดง)
  ///  kind 'lottie' = AnimatedConfirmDialog (r12, lottie 200, close ×)
  function dialog({ kind = 'alert', icon = null, lottie = null, title = '', detail = '', sub = '', buttons = [], closable = false, closeAct = 'closeDialog' }) {
    const isModal = kind === 'modal';
    const iconHtml = lottie
      ? `<div class="dlg-lottie lottie" data-anim="${lottie}"></div>`
      : icon ? (isModal ? `<div class="dlg-ic float">${A(icon)}</div>` : `<div class="dlg-ic ${icon.includes('140') || icon === 'ic-warning-outline' || icon === 'ic_disqualify' || icon.includes('gradient') || icon.includes('error2') ? 'l140' : ''}">${A(icon)}</div>`) : '';
    const btns = buttons.map((b, i) => {
      const o = Object.assign({ size: 'md' }, b);
      if (isModal && b.style === 'cancel') { o.style = 'gray'; o.cls = 'btn-cancel'; }
      return btn(b.t, o);
    }).join('');
    return `<div class="dlg-wrap"><div class="dlg ${isModal ? 'r20' : ''} ${isModal && icon ? 'with-icon' : ''}">
      ${closable ? `<button class="dlg-x" data-do="${closeAct}">${A('ic-close-button', 28)}</button>` : ''}
      ${iconHtml}
      ${title ? `<div class="dlg-title">${title}</div>` : ''}
      ${detail ? `<div class="dlg-detail">${detail}</div>` : ''}
      ${sub ? `<div class="dlg-sub">${sub}</div>` : ''}
      ${buttons.length ? `<div class="dlg-btns">${btns}</div>` : ''}
    </div></div>`;
  }

  /// bottom sheet: r16 · header 88 (title 20 Bold #171717 · subtitle 14 #919191) · close 28 · ไอคอน 140 ลอยเหนือหัว (optional)
  function sheet({ title = '', subtitle = '', body = '', full = false, h500 = false, icon = null, closeAct = 'closeSheet', back = null }) {
    return `<div class="sheet-wrap"><div class="sheet ${full ? 'full' : ''} ${h500 ? 'h500' : ''} ${icon ? 'with-icon' : ''}">
      ${icon ? `<div class="sheet-icon">${A(icon)}</div>` : ''}
      <div class="sheet-head">${back ? `<button class="sheet-back" data-do="${back}">${A('ic-back-button', 28)}</button>` : ''}<span>${title}</span>${subtitle ? `<small>${subtitle}</small>` : ''}<button class="sheet-x" data-do="${closeAct}">${A('ic-close-button', 28)}</button></div>
      <div class="sheet-body">${body}</div>
    </div></div>`;
  }

  /// หัวส่วนพื้นฟ้า (ฟอร์มสมัคร) 42pt #EDF4FF ตัว 14 Bold #0D499D
  function sectionHdr(t) { return `<div class="sec-hdr">${t}</div>`; }
  function sectionTitle(t, req = false, dot = false) { return `<div class="sec-title ${dot ? 'dot' : ''}">${req ? '<em>*</em>' : ''}${t}</div>`; }

  /// ช่องกรอก BaseTextFieldViewV2: r10 h40 border #E9E9E9 · disabled bg #F9F9F9 · error border แดง
  function field({ label, value = '', placeholder = '', req = false, bind = null, type = 'text', disabled = false, error = '', multiline = false, hint = '', select = false, icon = null, cls = '' }) {
    const attrs = `${bind ? `data-bind="${bind}"` : ''} ${disabled ? 'disabled' : ''} placeholder="${placeholder}"`;
    const style = icon ? `style="background-image:url(assets/ic/${icon}.png)"` : '';
    const input = multiline
      ? `<textarea class="fld-in" rows="3" ${attrs}>${value}</textarea>`
      : `<input class="fld-in" type="${type}" value="${value}" ${attrs} ${style}>`;
    return `<div class="fld ${error ? 'err' : ''} ${disabled ? 'dis' : ''} ${select ? 'fld-sel' : ''} ${icon ? '' : 'noicon'} ${cls}">
      ${label ? `<label class="fld-lb">${req ? '<em>*</em>' : ''}${label}</label>` : ''}
      ${input}
      ${error ? `<div class="fld-err">${error}</div>` : hint ? `<div class="fld-hint">${hint}</div>` : ''}
    </div>`;
  }

  function radio(name, options, value, bind, cls = '') {
    return `<div class="radios">${options.map(o => `<label class="radio ${cls} ${o === value ? 'on' : ''}"><input type="radio" name="${name}" value="${o}" data-bind="${bind}" ${o === value ? 'checked' : ''}><i></i><span>${o}</span></label>`).join('')}</div>`;
  }
  function checks(options, values, bind) {
    return `<div class="radios">${options.map(o => `<label class="check ${values.includes(o) ? 'on' : ''}"><input type="checkbox" value="${o}" data-bind="${bind}" ${values.includes(o) ? 'checked' : ''}><i></i><span>${o}</span></label>`).join('')}</div>`;
  }

  /// ไอคอนโซเชียล: 'social' = ic-*-social 44 (การ์ดผูกบัญชี) · 'chip' = ic-social-*28 (หน้าตอบรับ / ช่องลิงก์)
  const SOC44 = { facebook: 'ic-facebook-social', instagram: 'ic-instagram-social', x: 'ic-x-social', youtube: 'ic-youtube-social', tiktok: 'ic-tiktok-social', lemon8: 'ic-lemon8-social' };
  const SOC28 = { facebook: 'ic-social-facebook28', instagram: 'ic-social-instagram28', x: 'ic-social-twitter28', youtube: 'ic-social-youtube28', tiktok: 'ic-social-tiktok28', lemon8: 'ic-social-lemon8' };
  function socialIcon(type, size = 28, variant = 'chip') {
    const name = (variant === 'social' ? SOC44 : SOC28)[type];
    return A(name, size, 'soc-ic');
  }

  function fmtNum(n) { return n >= 1e6 ? (n / 1e6).toFixed(1) + 'M' : n >= 1e3 ? (n / 1e3).toFixed(1).replace(/\.0$/, '') + 'K' : String(n); }

  /// stepper 3 ขั้น (TopicReviewStateTopView): 24pt วง · เส้น 1pt · label 12
  function stepper(cur) {
    const names = ['สร้างดราฟต์รีวิว', 'ส่งดราฟต์รีวิว', 'ส่งลิงก์'];
    const cls = i => i < cur ? 'done' : i === cur ? 'cur' : '';
    return `<div class="stepper"><div class="dots">${names.map((n, i) => `${i ? `<span class="line ${i <= cur ? 'done' : ''}"></span>` : ''}<span class="dot ${cls(i)}">${i + 1}</span>`).join('')}</div><div class="labels">${names.map((n, i) => `<span class="${cls(i)}">${n}</span>`).join('')}</div></div>`;
  }

  return { A, navRed, btn, clock, dialog, sheet, sectionHdr, sectionTitle, field, radio, checks, socialIcon, fmtNum, stepper, I };
})();
