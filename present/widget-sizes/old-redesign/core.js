/* core.js — ข้อมูลตัวอย่าง · ชิ้นส่วนร่วม · ทะเบียน widget · ตัวเรนเดอร์หน้า
   ทุก widget ลงทะเบียนด้วย reg({ id, title, family, sizes, note, render(size) })
   size ∈ 'small' | 'wide' | 'large' — ผังต้องออกแบบแยกต่อขนาด ไม่ใช่ย่อ/ขยายผังเดียว */

const SIZE = { small: [178, 178], wide: [366, 178], large: [366, 366] };
const SIZE_TH = { small: 'เล็ก 1×1', wide: 'แนวนอน 2×1', large: 'ใหญ่ 2×2' };

const D = {
  name: 'นิรา ภัทรวดี', first: 'นิรา', en: 'NIRA', handle: '@nira.beauty', tagline: 'Beauty & Skincare Creator',
  city: 'กรุงเทพฯ', about: 'รีวิวสกินแคร์และเมคอัพแบบตรงไปตรงมา เน้นผิวแพ้ง่าย ถ่ายเองตัดเองทุกคลิป',
  cats: ['บิวตี้', 'ไลฟ์สไตล์', 'ออกกำลังกาย', 'คาเฟ่'],
  interests: ['ความงามและสุขภาพ', 'แฟชั่นและช้อปปิ้ง', 'แม่และเด็ก', 'ท่องเที่ยว'],
  styles: ['อ้างอิงวิจัย', 'รีวิวยาว 30 วัน', 'How-to', 'ก่อน–หลัง', 'โทนใส สว่าง'],
  socials: [
    { k: 'ig', name: 'Instagram', short: 'IG', handle: '@nira.beauty', n: '184K', raw: 184000, er: '4.7%', views: '92K' },
    { k: 'tt', name: 'TikTok', short: 'TikTok', handle: '@nirabeauty', n: '320.5K', raw: 320500, er: '8.1%', views: '128K' },
    { k: 'yt', name: 'YouTube', short: 'YT', handle: '@niraskin', n: '41.2K', raw: 41200, er: '4.6%', views: '22.4K' },
  ],
  total: '545.7K',
  rates: [
    { label: 'TikTok Video', price: '35,000', unit: 'คลิป', k: 'tt' },
    { label: 'IG Reel', price: '25,000', unit: 'คลิป', k: 'ig' },
    { label: 'IG Story ×3', price: '12,000', unit: 'ชุด', k: 'ig' },
    { label: 'รีวิวลงบล็อก', price: '18,000', unit: 'ชิ้น', k: 'ig' },
  ],
  contact: { phone: '081-234-5678', email: 'nira@beautyworks.co', line: '@nirabeauty', web: 'nira.beauty', reply: 'ตอบภายใน 3 ชม.' },
  audience: {
    female: 78, male: 20, other: 2,
    ages: [['18–24', 27], ['25–34', 41], ['35–44', 22], ['45+', 10]],
    places: [['กรุงเทพฯ', 34], ['ชลบุรี', 9], ['เชียงใหม่', 7], ['ขอนแก่น', 5]],
    reach: { n: '184.2K', delta: '+14.4%', fresh: '93.4%', window: '30 วัน' },
  },
  brands: ['Sivanna', 'Scotch', 'BioActive+', 'Cathy Doll', 'Srichand', 'Mistine'],
  works: [
    { brand: 'Sivanna Colors', camp: 'Ballet Dream', ep: 'EP.1335', k: 'tt', fmt: 'คลิปยาว', views: '1.24M', er: '6.8%', tag: '1M+ Views', seed: 11 },
    { brand: 'Cathy Doll', camp: 'Glow Serum Launch', ep: 'EP.1206', k: 'ig', fmt: 'Reel', views: '820K', er: '7.4%', tag: 'High Conversion', seed: 12 },
    { brand: 'Srichand', camp: 'Oil Control Challenge', ep: 'EP.1189', k: 'yt', fmt: 'Short', views: '615K', er: '5.9%', seed: 13 },
    { brand: 'Mistine', camp: 'Sunscreen Everyday', ep: 'EP.1142', k: 'tt', fmt: 'คลิปสั้น', views: '486K', er: '6.2%', seed: 14 },
    { brand: 'Scotch', camp: 'Collagen 30 Days', ep: 'EP.1098', k: 'ig', fmt: 'Reel', views: '352K', er: '8.1%', seed: 15 },
  ],
  track: { done: 24, brands: 6, er: '6.4%' },
  seal: { date: '13.10.69', no: 'TH 4495648', channels: 3 },
  time: { days: ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'], on: [1, 1, 1, 1, 1, 1, 0], slots: ['เช้า', 'บ่าย', 'เย็น', 'ค่ำ'], slotOn: [1, 0, 1, 1], areas: ['กรุงเทพฯ', 'นนทบุรี', 'ชลบุรี'] },
  body: [['สูง', '165', 'ซม.'], ['น้ำหนัก', '48', 'กก.'], ['รองเท้า', '38', 'EU'], ['อก', '32', 'นิ้ว'], ['เอว', '25', 'นิ้ว'], ['สะโพก', '35', 'นิ้ว']],
};

/* รูป — picsum seed ตายตัว จะได้รูปเดิมทุกครั้ง · 1–3 = ตัวคน · 11–15 = ผลงาน */
const PH = (seed, w = 600, h = 600) => `https://picsum.photos/seed/star${seed}/${w}/${h}`;
const PERSON = PH(3, 600, 800);

/* ไอคอนช่องทาง (inline SVG) */
const ICO = {
  ig: '<svg viewBox="0 0 24 24"><rect x="3" y="3" width="18" height="18" rx="5" fill="none" stroke="currentColor" stroke-width="2"/><circle cx="12" cy="12" r="4" fill="none" stroke="currentColor" stroke-width="2"/><circle cx="17.3" cy="6.7" r="1.2" fill="currentColor"/></svg>',
  tt: '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M14 3h3c.3 2.4 1.8 3.9 4 4.1V10c-1.5 0-2.9-.5-4-1.3V15a6 6 0 1 1-6-6v3a3 3 0 1 0 3 3V3z"/></svg>',
  yt: '<svg viewBox="0 0 24 24"><rect x="2" y="5" width="20" height="14" rx="4" fill="currentColor"/><path d="M10 9l5 3-5 3z" fill="#fff"/></svg>',
  line: '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M12 3C6.5 3 2 6.6 2 11c0 3.9 3.5 7.1 8.1 7.8.3.1.8.2.9.5.1.3 0 .8 0 1.1l-.1.9c0 .3-.2 1 .9.6s5.8-3.4 7.9-5.8C21.1 14.6 22 12.9 22 11c0-4.4-4.5-8-10-8z"/></svg>',
  phone: '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M6.6 10.8a15 15 0 0 0 6.6 6.6l2.2-2.2a1 1 0 0 1 1-.2c1.1.4 2.3.6 3.6.6a1 1 0 0 1 1 1V20a1 1 0 0 1-1 1A17 17 0 0 1 3 4a1 1 0 0 1 1-1h3.5a1 1 0 0 1 1 1c0 1.2.2 2.4.6 3.6a1 1 0 0 1-.3 1l-2.2 2.2z"/></svg>',
  mail: '<svg viewBox="0 0 24 24"><rect x="3" y="5" width="18" height="14" rx="3" fill="none" stroke="currentColor" stroke-width="2"/><path d="M4 7l8 6 8-6" fill="none" stroke="currentColor" stroke-width="2"/></svg>',
  web: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" stroke-width="2"/><path d="M3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18" fill="none" stroke="currentColor" stroke-width="2"/></svg>',
  check: '<svg viewBox="0 0 24 24"><path d="M5 12.5l4.5 4.5L19 7.5" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>',
  play: '<svg viewBox="0 0 24 24"><path d="M8 5v14l11-7z" fill="currentColor"/></svg>',
  pin: '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M12 2a7 7 0 0 0-7 7c0 5 7 13 7 13s7-8 7-13a7 7 0 0 0-7-7zm0 9.5A2.5 2.5 0 1 1 12 6a2.5 2.5 0 0 1 0 5.5z"/></svg>',
  star: '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M12 2l2.9 6.6 7.1.7-5.4 4.8 1.6 7L12 17.4 5.8 21l1.6-7L2 9.3l7.1-.7z"/></svg>',
  eye: '<svg viewBox="0 0 24 24"><path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z" fill="none" stroke="currentColor" stroke-width="2"/><circle cx="12" cy="12" r="3" fill="currentColor"/></svg>',
  heart: '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M12 21s-7.5-4.6-9.5-9A5.3 5.3 0 0 1 12 6a5.3 5.3 0 0 1 9.5 6c-2 4.4-9.5 9-9.5 9z"/></svg>',
  arrow: '<svg viewBox="0 0 24 24"><path d="M5 12h14M13 6l6 6-6 6" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>',
};
const SOC_COLOR = { ig: '#E1306C', tt: '#111111', yt: '#FF0000', line: '#06C755' };
const soc = k => D.socials.find(s => s.k === k);

/* ---------- ชิ้นส่วนร่วม ---------- */
const H = {
  ico: (k, cls = '') => `<i class="ico ${cls}">${ICO[k]}</i>`,
  badge: (k, size = 26) => `<i class="sbadge" style="--s:${size}px;background:${SOC_COLOR[k]}">${ICO[k]}</i>`,
  avatar: (size = 64, cls = '') => `<div class="avatar${cls ? ' ' + cls : ''}" style="--s:${size}px"><img src="${PH(3, 300, 300)}" alt=""></div>`,
  photo: (seed, cls = '', w = 600, h = 600) => `<div class="photo${cls ? ' ' + cls : ''}"><img src="${PH(seed, w, h)}" alt=""></div>`,
  person: (cls = '') => `<div class="person ${cls}"><img src="${PERSON}" alt=""></div>`,
  verified: (txt = 'Verified by Sale Here') => `<span class="vby">${ICO.check}<b>${txt}</b></span>`,
  chip: (t, cls = '') => `<span class="chip ${cls}">${t}</span>`,
  chips: (arr, cls = '', n = arr.length) => arr.slice(0, n).map(t => H.chip(t, cls)).join(''),
  stat: (k, big = 28) => `<div class="stat" style="--big:${big}px">${H.badge(k, big * 0.9)}<b>${soc(k).n}</b><small>${soc(k).name}</small></div>`,
  statCols: (big = 26) => `<div class="stat-cols">${['ig', 'tt', 'yt'].map(k => H.stat(k, big)).join('')}</div>`,
  socialRows: (n = 3, cls = '') => D.socials.slice(0, n).map(s => `<div class="srow ${cls}">${H.badge(s.k, 22)}<span class="h">${s.handle}</span><b>${s.n}</b></div>`).join(''),
  bar: (pct, cls = '') => `<div class="bar ${cls}"><i style="width:${pct}%"></i></div>`,
  /* QR ปลอมที่ดูเหมือนจริง: finder 3 มุม (วงนอก · ช่องว่าง · จุดกลาง) + โมดูลสุ่มแบบ hash ต่อช่อง (ไม่เป็นแถบ) */
  qr: (n = 15, cls = '') => {
    n = Math.max(n, 13); let bits = '';
    const h = i => { let x = (i + 1) * 2654435761 >>> 0; x ^= x >>> 15; x = Math.imul(x, 2246822519) >>> 0; x ^= x >>> 13; return x & 1; };
    const finder = (r, c) => { const f = [[0, 0], [0, n - 5], [n - 5, 0]]; for (const [fr, fc] of f) { const dr = r - fr, dc = c - fc; if (dr >= 0 && dr < 5 && dc >= 0 && dc < 5) { if (dr === 0 || dr === 4 || dc === 0 || dc === 4) return 1; if (dr === 2 && dc === 2) return 1; return 0; } if ((dr === -1 || dr === 5) && dc >= -1 && dc <= 5) return 0; if ((dc === -1 || dc === 5) && dr >= -1 && dr <= 5) return 0; } return -1; };
    for (let i = 0; i < n * n; i++) { const r = Math.floor(i / n), c = i % n; const f = finder(r, c); const on = f >= 0 ? f : h(i); bits += `<i class="${on ? 'on' : ''}"></i>`; }
    return `<div class="qr${cls ? ' ' + cls : ''}" style="--n:${n}">${bits}</div>`;
  },
  coin: (name, i, size = 44) => `<div class="coin" style="--s:${size}px;--hue:${(i * 57) % 360}"><span>${name.split(' ')[0].slice(0, 7)}</span></div>`,
  coins: (n = 6, size = 44) => D.brands.slice(0, n).map((b, i) => H.coin(b, i, size)).join(''),
  sealMark: (size = 64) => `<div class="seal" style="--s:${size}px"><svg viewBox="0 0 100 100"><path d="M50 4l9 7 11-2 5 10 10 5-2 11 7 9-7 9 2 11-10 5-5 10-11-2-9 7-9-7-11 2-5-10-10-5 2-11-7-9 7-9-2-11 10-5 5-10 11 2z" fill="var(--seal-fill,#F3E7C9)"/><path d="M31 52l12 12 26-28" fill="none" stroke="var(--seal-ink,#5A0F1E)" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/></svg></div>`,
  ratePill: r => `<div class="rate"><span class="l">${H.badge(r.k, 18)}${r.label}</span><b>฿${r.price}</b><small>/${r.unit}</small></div>`,
  donut: (pct, size = 56, cls = '') => `<div class="donut ${cls}" style="--s:${size}px;--p:${pct}"><b>${pct}%</b></div>`,
  label: (t, cls = '') => `<div class="wlabel ${cls}">${t}</div>`,
  byline: () => `<div class="byline">${ICO.check}<span>Verified by</span><em>Sale Here</em></div>`,
  esc: s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;'),
};

/* ---------- ทะเบียน ---------- */
const REG = [];
const FAM = {};
function reg(w) { REG.push(w); (FAM[w.family] ||= []).push(w); }

const FAMILY_TH = {
  profile: 'โปรไฟล์', intro: 'แนะนำตัว', channels: 'ช่องทาง / ผู้ติดตาม', niche: 'สายที่ใช่', rate: 'เรทรับงาน',
  work: 'ผลงาน', brand: 'แบรนด์ที่เคยร่วมงาน', contact: 'ติดต่อ', audience: 'ข้อมูลผู้ติดตาม', verify: 'ยืนยันตัวตน',
  schedule: 'วันเวลา · พื้นที่', body: 'สัดส่วน', text: 'ข้อความ / ตกแต่ง',
};
const FAMILY_ORDER = ['profile', 'intro', 'channels', 'niche', 'rate', 'work', 'brand', 'contact', 'audience', 'verify', 'schedule', 'body', 'text'];

/* ---------- เรนเดอร์หน้า ---------- */
/* ภาพใบจริงจาก iOS (ShapeMatrix export, หน้าพอร์ต, @2x) — ฐานของทุกแบบ · HTML ต้องหน้าตาเดียวกัน ต่างแค่ผังต่อขนาด */
function iosTile(w, size) {
  const [W, Hh] = SIZE[size];
  return `<figure class="lab ios">
    <img src="ios/cell-${w.id}-${size}-port.png" width="${W + 24}" height="${Hh + 24}" alt="" loading="lazy" onerror="this.parentNode.classList.add('missing')">
    <figcaption>iOS จริง · ${SIZE_TH[size]}</figcaption>
  </figure>`;
}

function tile(w, size) {
  const [W, Hh] = SIZE[size];
  return `<figure class="lab">
    <div class="wg s-${size} ${w.cls || ''}" style="--w:${W}px;--h:${Hh}px" data-id="${w.id}" data-size="${size}">${w.render(size)}</div>
    <figcaption>HTML · ${SIZE_TH[size]}<em>${W}×${Hh}</em></figcaption>
  </figure>`;
}

function renderAll(root) {
  const nav = [];
  let html = '';
  for (const fam of FAMILY_ORDER) {
    const list = FAM[fam]; if (!list) continue;
    nav.push(`<a href="#f-${fam}">${FAMILY_TH[fam]}<small>${list.length}</small></a>`);
    html += `<section class="family" id="f-${fam}"><h2>${FAMILY_TH[fam]}<small>${list.length} ใบ</small></h2>`;
    for (const w of list) {
      html += `<article class="widget" id="w-${w.id}">
        <header><h3>${w.title}<code>${w.id}</code></h3><p>${w.note || ''}</p></header>
        <div class="stage ios-row">${w.sizes.map(s => iosTile(w, s)).join('')}</div>
        <div class="stage">${w.sizes.map(s => tile(w, s)).join('')}</div>
      </article>`;
    }
    html += '</section>';
  }
  root.innerHTML = html;
  document.getElementById('nav').innerHTML = nav.join('');
  document.getElementById('count').textContent = `${REG.length} widget · ${REG.reduce((a, w) => a + w.sizes.length, 0)} ใบ`;
}
