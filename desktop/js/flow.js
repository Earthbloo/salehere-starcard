// state + กติกาของ flow — ถอดจาก StarCard/StarCard/Model/StarFlow.swift (iOS, 6 ต.ค. 2569) แบบ 1:1
// ทุกกติกาอยู่ไฟล์นี้ไฟล์เดียว: หน้าจอ desktop แค่วาดต่างจากมือถือ ลำดับคำถาม/เงื่อนไขต้องเท่ากัน

const SOCIALS = [
  { id: 'instagram', name: 'Instagram', short: 'IG', formats: ['shortVideo', 'photo'], ph: 'instagram.com/username', fetch: 'connect', insight: true,
    re: /^https?:\/\/(www\.)?instagram\.com\/[A-Za-z0-9._]{1,30}\/?(\?.*)?$/i, bad: /\/(p|reel|reels|stories|explore)\//i, mock: ['https://instagram.com/mintmint.review', 24800] },
  { id: 'tiktok', name: 'TikTok', short: 'TikTok', formats: ['shortVideo'], ph: 'tiktok.com/@username', fetch: 'connect', insight: true,
    re: /^https?:\/\/(www\.)?tiktok\.com\/@[A-Za-z0-9._]{1,30}\/?(\?.*)?$/i, bad: /\/(video|photo)\//i, mock: ['https://tiktok.com/@mintmint.review', 58300] },
  { id: 'facebook', name: 'Facebook', short: 'FB', formats: ['shortVideo', 'photo'], ph: 'facebook.com/yourpage', fetch: 'connect', insight: true,
    re: /^https?:\/\/(www\.|web\.|m\.)?(facebook\.com|fb\.com)\/([A-Za-z0-9.]{3,60}|profile\.php\?id=\d+)\/?(\?.*)?$/i, bad: /\/(posts|photo|videos|watch|groups)\//i, mock: ['https://facebook.com/mintmintreview', 12400] },
  { id: 'youtube', name: 'YouTube', short: 'YouTube', formats: ['shortVideo', 'longVideo'], ph: 'youtube.com/@channel', fetch: 'api', insight: true,
    re: /^https?:\/\/(www\.|m\.)?youtube\.com\/(@[A-Za-z0-9._-]{3,30}|channel\/[A-Za-z0-9_-]{10,}|c\/[A-Za-z0-9._-]+)\/?(\?.*)?$/i, bad: /\/(watch|shorts|live)|youtu\.be\//i, mock: ['https://youtube.com/@mintmintreview', 8900] },
  { id: 'x', name: 'X', short: 'X', formats: ['shortVideo', 'seeding'], ph: 'x.com/username', fetch: 'connect', insight: false,
    re: /^https?:\/\/(www\.)?(x|twitter)\.com\/[A-Za-z0-9_]{1,15}\/?(\?.*)?$/i, bad: /\/status\//i, mock: ['https://x.com/mintmint_review', 3200] },
  { id: 'lemon8', name: 'Lemon8', short: 'Lemon8', formats: ['photo', 'shortVideo'], ph: 'lemon8-app.com/@username', fetch: 'manual', insight: false,
    re: /^https?:\/\/(www\.)?lemon8[\w.-]*\/[@A-Za-z0-9._\/-]+$/i, bad: null, mock: ['https://lemon8-app.com/@mintmint.review', 6700] },
];
const SOC = Object.fromEntries(SOCIALS.map(s => [s.id, s]));
const FORMATS = { shortVideo: ['Short Video', 1], photo: ['Photo', 0.8], longVideo: ['Long Video', 1.4], seeding: ['Seeding', 0.5] };

const KEY_LABEL = { kind: 'ประเภทครีเอเตอร์', socials: 'ช่องทางโซเชียล', categories: 'สายที่ใช่', about: 'แนะนำตัว', media: 'เกี่ยวกับคุณ', rate: 'เรทรับงาน',
  insight: 'ข้อมูลผู้ติดตาม', province: 'พื้นที่รับงาน', availability: 'วันเวลาว่างรับงาน', contact: 'ช่องทางติดต่อ', address: 'ที่อยู่รับของ', bank: 'บัญชีรับเงิน', body: 'สัดส่วน' };

// แถวของ Star Profile (= StarRow.all = `StarProfileRow.all` ของ salehere-ios 7 ต.ค. 2569) — key null = ยืนยันตัวตน
// 8 แถวแรก = 8 ข้อใน wizard ลำดับเดียวกัน · เรทอยู่ในแถวช่องทาง (ไม่มีแถวของตัวเอง) · ประเภทครีเอเตอร์มีแถวของตัวเอง · ยืนยันตัวตนท้ายสุด
const ROWS = [
  { key: 'kind', icon: 'user', title: 'ประเภทครีเอเตอร์', why: 'แบรนด์เห็นว่าคุยกับใคร' },
  { key: 'socials', icon: 'broadcast', title: 'ช่องทางของฉัน', why: 'ยอดผู้ติดตามขึ้นการ์ดอัตโนมัติ' },
  { key: 'categories', icon: 'sparkle', title: 'สายที่ใช่', why: 'งานตรงสายขึ้นหน้าแรกให้' },
  { key: 'media', icon: 'imageSquare', title: 'เกี่ยวกับคุณ', why: 'แบรนด์ดูหน้าตาและงานของคุณก่อนคัดเลือก' },
  { key: 'province', icon: 'mapPin', title: 'พื้นที่รับงาน', why: 'งานหน้าร้านใกล้คุณขึ้นก่อน' },
  { key: 'availability', icon: 'calendarDots', title: 'วันเวลาว่างรับงาน', why: 'แบรนด์ดูวันว่างของคุณตอนคัดคน' },
  { key: 'contact', icon: 'chatCircleText', title: 'ช่องทางติดต่อ', why: 'แบรนด์ทักคุณตรงนี้ · ขึ้นบนการ์ด' },
  { key: 'about', icon: 'textAlignLeft', title: 'แนะนำตัว', why: '1 บรรทัดใต้ชื่อบนการ์ด' },
  { key: 'insight', icon: 'usersThree', title: 'ข้อมูลผู้ติดตาม', why: 'แบรนด์เห็นว่าคนดูคุณเป็นใคร' },
  { key: 'bank', icon: 'bank', title: 'การรับเงิน', why: 'ค่าตัวเข้าบัญชีทันทีเมื่องานจบ' },
  { key: 'address', icon: 'package', title: 'ที่อยู่รับของ', why: 'กรอกตอนลงทะเบียนกิจกรรม · แบรนด์ส่งของรีวิวได้เลย' },
  // สัดส่วน = หน้า "สัดส่วน" ของ salehere-ios — กรอกเองที่ Star Profile เท่านั้น ไม่แทรกใน flow สมัคร (ผู้ใช้ 6 ต.ค. 2569)
  { key: 'body', icon: 'ruler', title: 'สัดส่วน', why: 'แบรนด์แฟชั่นดูไซซ์ก่อนส่งของ' },
  { key: null, icon: 'sealCheck', title: 'ยืนยันตัวตน', why: 'ต้องผ่านก่อนแบรนด์เลือกคุณ' },
];
const KYC_ROW = ROWS[ROWS.length - 1];

// ขั้นของ wizard (= WizStep) — page(): ช่องทาง+เรท+insight หน้าเดียว · แนะนำตัว+ผลงาน หน้าเดียว
const STEP = {
  page: s => (s === 'rate' || s === 'insight') ? 'socials' : s === 'about' ? 'media' : s,
  keys: s => s === 'socials' ? ['socials', 'rate', 'insight'] : s === 'media' ? ['media', 'about'] : (KEY_LABEL[s] ? [s] : []),
  pages: list => list.reduce((out, s) => { const p = STEP.page(s); if (!out.includes(p)) out.push(p); return out; }, []),
  name: s => s === 'socials' ? 'ช่องทางและเรท' : s === 'media' ? 'เกี่ยวกับคุณ' : s === 'kyc' ? 'ยืนยันตัวตน' : (KEY_LABEL[s] || ''),
  icon: s => s === 'kyc' ? 'sealCheck' : s === 'rate' ? 'coins' : (ROWS.find(r => r.key === s) || {}).icon || 'circleDashed',
  // ชื่อข้อ = ชื่อแถวในหน้า Star Profile = ชื่อช่องประบนการ์ดหน้า intro (= `WizStep.rowName` / `StarWizardStep.name` ของ salehere-ios) — ห้ามมีชื่อเล่นอื่น
  rowName: s => ({ kind: 'ประเภทครีเอเตอร์', socials: 'ช่องทางของฉัน', rate: 'ช่องทางของฉัน', insight: 'ช่องทางของฉัน', categories: 'สายที่ใช่', media: 'เกี่ยวกับคุณ', about: 'เกี่ยวกับคุณ',
    province: 'พื้นที่รับงาน', availability: 'วันเวลาว่างรับงาน', contact: 'ช่องทางติดต่อ', address: 'ที่อยู่รับของ', bank: 'การรับเงิน', body: 'สัดส่วน', kyc: 'ยืนยันตัวตน' }[s] || STEP.name(s)),
  line: {
    kind: ['แบรนด์เห็นว่าคุยกับใคร', 'เลือก 1 อย่าง'], socials: ['แบรนด์ดูข้อนี้ก่อนคัดเลือก', 'ผูก 1 ช่องพอ', 'ตั้งเรทได้ตอนเชื่อม'],
    categories: ['แบรนด์ใช้ตัดสินใจ', 'เลือก 3–5 สาย'], about: ['แบรนด์อ่านความเป็นตัวคุณจากบรรทัดนี้'], media: ['แบรนด์ดูหน้าตาและงานก่อนคัดเลือก'],
    kyc: ['ต้องผ่านก่อนส่งใบสมัคร', 'ทำครั้งเดียว ใช้ได้ทุกงาน'], rate: ['แบรนด์ดูราคาก่อนคัดเลือก', 'ใส่ราคามาตรฐานให้แล้ว'],
    insight: ['แบรนด์ใช้คัดเลือกกลุ่มเป้าหมาย', 'ทำช่องเดียวก็ได้'], province: ['แบรนด์ใช้คัดเลือกงานหน้าร้าน', 'เลือกได้ถึง 3'],
    availability: ['แบรนด์ดูวันว่างตอนคัดเลือก'], contact: ['แบรนด์ทักคุณตรงนี้', 'ขึ้นบนการ์ด'],
    body: ['แบรนด์แฟชั่นใช้เลือกไซซ์ของที่ส่ง', 'กรอกเท่าที่สะดวก'],
  },
};

const WEEK = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
const WEEK_FULL = { 'จ': 'จันทร์', 'อ': 'อังคาร', 'พ': 'พุธ', 'พฤ': 'พฤหัสฯ', 'ศ': 'ศุกร์', 'ส': 'เสาร์', 'อา': 'อาทิตย์' };
// ช่วงเวลาของวัน = CreatorTimeSlots ของ salehere-ios ตัวต่อตัว (เดิม เช้า/บ่าย/เย็น — ผู้ใช้ 6 ต.ค. 2569) · ค่าที่เก็บ = คีย์ของ API
const DAY_SLOTS = ['slot_09_12', 'slot_12_14', 'slot_14_17', 'slot_17_late'];
const SLOT_HOURS = { slot_09_12: [9, 12], slot_12_14: [12, 14], slot_14_17: [14, 17], slot_17_late: [17, null] };
const hh = h => String(h).padStart(2, '0') + '.00';
const SLOT_LABEL = Object.fromEntries(DAY_SLOTS.map(k => { const [a, b] = SLOT_HOURS[k]; return [k, b == null ? `${hh(a)} เป็นต้นไป` : `${hh(a)}–${hh(b)}`]; }));
// ครบ 4 = "ตลอดวัน" · ติดกันรวมเป็น "09.00–14.00" · ห่างกันคั่น " + " · ว่าง = ""
function slotText(keys) {
  const picked = DAY_SLOTS.filter(k => keys.includes(k));
  if (!picked.length) return ''; if (picked.length === DAY_SLOTS.length) return 'ตลอดวัน';
  const runs = []; picked.forEach(k => { const [a, b] = SLOT_HOURS[k], last = runs[runs.length - 1]; if (last && last[1] === a) last[1] = b; else runs.push([a, b]); });
  return runs.map(([a, b]) => b == null ? `${hh(a)} เป็นต้นไป` : `${hh(a)}–${hh(b)}`).join(' + ');
}
// ค่ารุ่นก่อน (เช้า/บ่าย/เย็น) → คีย์ช่วงเวลาของแอปหลัก
function migrateSlots(list) {
  const map = { 'เช้า': ['slot_09_12'], 'บ่าย': ['slot_12_14', 'slot_14_17'], 'เย็น': ['slot_17_late'], 'ตลอดวัน': DAY_SLOTS };
  const keys = new Set((list || []).flatMap(x => map[x] || (DAY_SLOTS.includes(x) ? [x] : [])));
  return DAY_SLOTS.filter(k => keys.has(k));
}
const CATEGORIES = ['💄 บิวตี้', '👗 แฟชั่น', '🍜 อาหาร', '☕️ คาเฟ่', '✨ ไลฟ์สไตล์', '✈️ ท่องเที่ยว', '💪 สุขภาพ', '👶 แม่และเด็ก', '🐶 สัตว์เลี้ยง', '📱 เทค', '🎮 เกม', '🎬 บันเทิง', '🎪 อีเวนต์'];
// = `getProvinces` ของ salehere-ios — ไม่มี "ทุกจังหวัด (งานออนไลน์)" (เอาออก 7 ต.ค. 2569 ให้ตรงแอปหลัก)
const PROVINCE_ALIAS = { 'กรุงเทพมหานคร': 'กทม กรุงเทพ bangkok bkk', 'นครราชสีมา': 'โคราช', 'พระนครศรีอยุธยา': 'อยุธยา', 'ภูเก็ต': 'phuket', 'เชียงใหม่': 'chiang mai', 'ชลบุรี': 'พัทยา pattaya' };
const PROVINCES = [...('กรุงเทพมหานคร กระบี่ กาญจนบุรี กาฬสินธุ์ กำแพงเพชร ขอนแก่น จันทบุรี ฉะเชิงเทรา ชลบุรี ชัยนาท ชัยภูมิ ชุมพร เชียงราย เชียงใหม่ ตรัง ตราด ตาก นครนายก นครปฐม นครพนม นครราชสีมา นครศรีธรรมราช นครสวรรค์ นนทบุรี นราธิวาส น่าน บึงกาฬ บุรีรัมย์ ปทุมธานี ประจวบคีรีขันธ์ ปราจีนบุรี ปัตตานี พระนครศรีอยุธยา พะเยา พังงา พัทลุง พิจิตร พิษณุโลก เพชรบุรี เพชรบูรณ์ แพร่ ภูเก็ต มหาสารคาม มุกดาหาร แม่ฮ่องสอน ยโสธร ยะลา ร้อยเอ็ด ระนอง ระยอง ราชบุรี ลพบุรี ลำปาง ลำพูน เลย ศรีสะเกษ สกลนคร สงขลา สตูล สมุทรปราการ สมุทรสงคราม สมุทรสาคร สระแก้ว สระบุรี สิงห์บุรี สุโขทัย สุพรรณบุรี สุราษฎร์ธานี สุรินทร์ หนองคาย หนองบัวลำภู อ่างทอง อำนาจเจริญ อุดรธานี อุตรดิตถ์ อุทัยธานี อุบลราชธานี').split(' ')];
const BANKS = ['กสิกรไทย', 'ไทยพาณิชย์', 'กรุงเทพ', 'กรุงไทย', 'กรุงศรีอยุธยา', 'ทหารไทยธนชาต (ttb)', 'ออมสิน', 'ธ.ก.ส.', 'ยูโอบี', 'ซีไอเอ็มบี ไทย', 'เกียรตินาคินภัทร', 'แลนด์ แอนด์ เฮ้าส์'];
const INSIGHT_SLOTS = [
  { key: 'gender', title: 'เพศ', icon: 'genderIntersex' }, { key: 'age', title: 'ช่วงอายุ', icon: 'cake' }, { key: 'location', title: 'พื้นที่ยอดนิยม', icon: 'mapPin' },
];
const SAMPLE_INSIGHT = {
  gender: [['หญิง', 68], ['ชาย', 30], ['อื่น ๆ', 2]], age: [['18–24 ปี', 31], ['25–34 ปี', 42], ['35–44 ปี', 17]], location: [['กรุงเทพ', 35], ['เชียงใหม่', 9], ['ชลบุรี', 7]],
};
const INSIGHT_APP = s => s === 'youtube' ? 'YouTube Studio' : SOC[s].name;
const INSIGHT_PATH = { facebook: 'เพจ → Professional dashboard → ข้อมูลเชิงลึก → ผู้ติดตาม', instagram: 'โปรไฟล์ → Professional dashboard → ข้อมูลเชิงลึก → ผู้ติดตามทั้งหมด',
  tiktok: 'โปรไฟล์ → ☰ → เครื่องมือครีเอเตอร์ → ข้อมูลวิเคราะห์ → ผู้ติดตาม', youtube: 'ข้อมูลวิเคราะห์ → แท็บผู้ชม' };
const INSIGHT_WEB = { facebook: 'https://facebook.com', instagram: 'https://instagram.com', tiktok: 'https://tiktok.com', youtube: 'https://studio.youtube.com' };
// รูปของคุณ · รูปผลงาน · วิดีโอ อย่างละ 1–3 (ผู้ใช้ 7 ต.ค. 2569) = `StarFlow.minPhotos/minWorks/minVideos` + `Portfolio.creatorSlots/workMax/videoMax`
const MIN = { photos: 1, works: 1, videos: 1 }, MAX = { photos: 3, works: 3, videos: 3 }, VIDEO_MAX_MB = 100;
// `myProfile.tel` / `myProfile.lineId` ของบัญชี Sale Here (= SHMockUser.accountTel/accountLine) — ขั้นช่องทางติดต่อเติมให้ล่วงหน้า
const ACCOUNT_TEL = '+66891234567', ACCOUNT_LINE = '';
const ACCOUNT_NAME = 'Tarmjaipa', FALLBACK_BIO = 'ชอบพาไปเที่ยว ทานอาหารอร่อยๆ แวะจิบกาแฟที่ร้านคาเฟ่น่ารักๆ';

const CAMPAIGNS = [
  { id: '1585', episode: 'EP.1585', title: 'WONDER ONE Music Festival 2027 รวมพลสายคอนเสิร์ต ท่ามกลางบรรยากาศธรรมชาติริมทะเลสาบ', brand: 'WONDER ONE',
    logo: 'assets/logo-wonder.png', cover: 'assets/cover-wonder.png', dateRange: '21 ก.ย. 69 - 28 ก.ย. 69',
    howTo: 'จัดเต็มความสนุกตั้งแต่เที่ยงวันยันเที่ยงคืนกับ 5 WONDERS ทั้งวิวธรรมชาติ ร้านเด็ดกว่า 30 ร้าน โซนถ่ายรูปสุดฮิป 🎡 และคอนเสิร์ตสุดอลังการจาก 7 ศิลปินฮอต JEFF SATUR, NONT TANONT, PiXXiE, MILLI, SLOT MACHINE, TIMETHAI และ RISA NARISA 🎶🔥 ปิดท้ายค่ำคืนด้วยงานไฟ Immersive Light สุดว้าว พร้อมที่จอดรถเพียบและห้องน้ำสะอาดติดสปีด 🚗 บัตร Early Bird มาพร้อมสิทธิพิเศษ จองก่อนได้ราคาดีกว่า แล้วเจอกันที่ริมทะเลสาบ!',
    left: 14 * 3600 + 59 * 60 + 48, reward: 'บัตร Early Bird 2 ใบ + ชุด Merchandise', quota: 20, registered: 184, channels: ['instagram', 'tiktok'], contentTypes: ['Photo', 'Short Video'],
    timeline: [['ลงทะเบียน', '21 – 28 ก.ย. 69'], ['ประกาศผล', '30 ก.ย. 69'], ['ตอบรับกิจกรรม', '30 ก.ย. – 2 ต.ค. 69'], ['จัดส่งสินค้า', '3 ต.ค. 69'], ['ส่งดราฟต์รีวิว', '5 – 12 ต.ค. 69'], ['ส่งลิงก์รีวิว', '13 – 20 ต.ค. 69']],
    questions: [{ kind: 'text', q: 'ทำไมคุณถึงอยากไปงานนี้? (สั้น ๆ)' }, { kind: 'radio', q: 'เคยไปเทศกาลดนตรีมาก่อนไหม', options: ['เคย', 'ไม่เคย'] },
      { kind: 'checkbox', q: 'ศิลปินที่คุณตั้งใจไปดู', options: ['JEFF SATUR', 'NONT TANONT', 'PiXXiE', 'MILLI', 'SLOT MACHINE', 'TIMETHAI', 'RISA NARISA'] },
      { kind: 'upload', q: 'แนบตัวอย่างคอนเทนต์สายคอนเสิร์ตของคุณ' }],
    acceptQuestions: [{ kind: 'radio', q: 'สะดวกไปงานวันไหน', options: ['เสาร์ 4 ต.ค.', 'อาทิตย์ 5 ต.ค.', 'ทั้งสองวัน'] }], fee: 3000 },
  { id: '1569', episode: 'EP.1569', title: 'Thymora ผลิตภัณฑ์สมุนไทยบำรุงผิว บอกลาปัญหาผิวและเส้นผม', brand: 'Thymora', logo: 'assets/logo-thymora.png', cover: 'assets/cover-thymora.png',
    dateRange: '26 ส.ค. 69 - 30 ก.ย. 69',
    howTo: 'รับผลิตภัณฑ์ Thymora ชุดบำรุงผิวและเส้นผมจากสมุนไพรไทย ทดลองใช้จริง 14 วัน แล้วรีวิวประสบการณ์ผ่านช่องทางของคุณ พร้อมแนบรูปก่อน-หลังใช้ และติดแฮชแท็ก #Thymora #SaleHereSTAR ในโพสต์ ทีมงานคัดเลือกรีวิวคุณภาพเพื่อรับของรางวัลเพิ่มเติม',
    left: 8 * 86400 + 3 * 3600 + 12 * 60 + 5, reward: 'ชุดผลิตภัณฑ์ Thymora มูลค่า 1,890 บาท', quota: 50, registered: 412, channels: ['instagram'], contentTypes: ['Photo'],
    timeline: [['ลงทะเบียน', '26 ส.ค. – 30 ก.ย. 69'], ['ประกาศผล', '2 ต.ค. 69'], ['ตอบรับกิจกรรม', '2 – 4 ต.ค. 69'], ['จัดส่งสินค้า', '6 ต.ค. 69'], ['ส่งดราฟต์รีวิว', '20 – 27 ต.ค. 69'], ['ส่งลิงก์รีวิว', '28 ต.ค. – 4 พ.ย. 69']],
    questions: [{ kind: 'radio', q: 'สภาพผิวของคุณ', options: ['ผิวมัน', 'ผิวแห้ง', 'ผิวผสม', 'ผิวแพ้ง่าย'] }], acceptQuestions: [], fee: 0 },
  { id: '1571', episode: 'EP.1571', title: 'Terminal 21 เช็คอินคาเฟ่ลับ 5 ชั้น เก็บครบทุกมุมถ่ายรูป', brand: 'Terminal 21', logo: 'assets/ph03.jpg', cover: 'assets/ph02.jpg',
    dateRange: '14 ก.ย. 69 - 20 ก.ย. 69',
    howTo: 'เดินเก็บคาเฟ่ลับใน Terminal 21 ให้ครบ 5 ร้าน ถ่ายรูปกับมุมประจำชั้น แล้วโพสต์รีวิวแบบ carousel อย่างน้อย 5 รูป พร้อมพิกัดร้านและเมนูแนะนำ',
    left: null, reward: 'Gift Voucher 1,000 บาท', quota: 30, registered: 0, channels: ['instagram', 'lemon8'], contentTypes: ['Photo'], timeline: [], questions: [], acceptQuestions: [], fee: 1500 },
];
const BOOT = Date.now();
CAMPAIGNS.forEach(c => { c.headline = c.episode + ' ' + c.title; c.isOpen = c.left != null; c.deadline = c.isOpen ? BOOT + c.left * 1000 : null; });

// ขั้นทั้ง 15 ของ happy case (= StarFlow.stages) — แผง Lab กดกระโดด
const STAGES = [
  { t: 'เห็นงาน · หน้ากิจกรรม', phase: 'register' },
  { t: 'แทรก: ข้อมูลของคุณ (ก่อนสมัคร)', ins: 1, phase: 'register', screen: 'wizard:apply' },
  { t: 'แทรก: การ์ดเกิด (โชว์ครั้งแรกครั้งเดียว)', ins: 1, phase: 'register', screen: 'reveal' },
  { t: 'ฟอร์มสมัครเดิม (ที่อยู่ 7 ช่องเหมือนแอปหลัก)', phase: 'register', screen: 'register' },
  { t: 'ลงทะเบียนสำเร็จ · dialog เดิม', phase: 'registered', dialog: 'registerSuccess' },
  { t: 'แบรนด์คัดคน · รอผล', phase: 'registered' },
  { t: 'ได้รับเลือก · ปุ่มตอบรับ (เดิม)', phase: 'waitingAcceptQuota' },
  { t: 'กดตอบรับ (ไม่แทรกอะไรแล้ว — ที่อยู่กรอกตอนสมัคร)', ins: 1, phase: 'waitingAcceptQuota', screen: 'wizard:accept' },
  { t: 'หน้าตอบรับเดิม (ที่อยู่จากฟอร์มสมัคร)', phase: 'waitingAcceptQuota', screen: 'accept' },
  { t: 'ตอบรับแล้ว · รอของ', phase: 'acceptedQuota', order: 'shipping' },
  { t: 'ของถึง · สร้างดราฟต์ (เดิม)', phase: 'acceptedQuota', order: 'delivered', note: 'หน้าสร้างดราฟต์ = หน้าเดิมของแอปหลัก ยังไม่ได้จำลอง' },
  { t: 'ส่งดราฟต์ · รอตรวจ (เดิม)', phase: 'acceptedQuota', order: 'delivered', note: 'หน้าดราฟต์รอตรวจ = หน้าเดิมของแอปหลัก ยังไม่ได้จำลอง' },
  { t: 'ดราฟต์ผ่าน · ปุ่มส่งลิงก์ (เดิม)', phase: 'acceptedQuota', order: 'delivered', draftApproved: true },
  { t: 'หน้าส่งลิงก์เดิม', phase: 'acceptedQuota', order: 'delivered', draftApproved: true, screen: 'link' },
  { t: 'ส่งลิงก์แล้ว · จบ (หน้ากิจกรรมเดิม)', phase: 'acceptedQuota', order: 'delivered', draftApproved: true, reviewed: true },
];
const PROFILE_ONLY = 99;
const RULES = [ // [key, askAt, needFrom]
  ['kind', 1, 2], ['socials', 1, 2], ['categories', 1, 2], ['about', 2, 99], ['media', 1, 2], [null, 1, 2], ['rate', 1, 2], ['insight', 1, 99],
  ['province', 1, 2], ['availability', 1, 2], ['contact', 1, 2], ['address', 3, 4], ['bank', PROFILE_ONLY, 99], ['body', PROFILE_ONLY, 99],
];
const ALL_KEYS = Object.keys(KEY_LABEL);
const CARD_KEYS = ['kind', 'socials', 'categories', 'about', 'media'];
const APPLY_KEYS = [...CARD_KEYS, 'rate', 'insight', 'province', 'availability', 'contact'];
const PRESETS = [
  { id: 'new', t: 'ผู้ใช้ใหม่ · ยังไม่มีอะไรเลย', have: [], verify: 'none' },
  { id: 'card', t: 'มีการ์ดแล้ว · ยังไม่ยืนยันตัวตน', have: CARD_KEYS, verify: 'none' },
  { id: 'cardWait', t: 'มีการ์ด · KYC รอทีมงานตรวจ', have: CARD_KEYS, verify: 'waiting' },
  // สถานะ C ของ salehere-ios: ได้ยศจาก 3 ขั้นต้อนรับแบบเดิม (ช่องทาง · สาย · ยืนยันตัวตน) แต่ 8 ข้อยังไม่ครบ
  { id: 'oldStar', t: 'STAR เก่า · ข้อมูลยังไม่ครบ (สถานะ C)', have: ['socials', 'rate', 'categories'], verify: 'approved', rank: true },
  { id: 'apply', t: 'STAR พร้อมสมัคร (ครบที่แบรนด์ถาม)', have: APPLY_KEYS, verify: 'approved' },
  { id: 'full', t: `ครบทุกอย่าง ${ROWS.length}/${ROWS.length}`, have: ALL_KEYS, verify: 'approved' },
  { id: 'registered', t: 'สมัครแล้ว · รอผล (การ์ดยังขาด)', have: [...CARD_KEYS, 'rate', 'province', 'availability', 'contact'], verify: 'waiting', phase: 'registered' },
  { id: 'selected', t: 'ได้รับเลือก · รอตอบรับ (ยังไม่มีที่อยู่)', have: APPLY_KEYS, verify: 'approved', phase: 'waitingAcceptQuota' },
  { id: 'working', t: 'ตอบรับแล้ว · ของกำลังส่ง', have: ALL_KEYS.filter(k => k !== 'bank'), verify: 'approved', phase: 'acceptedQuota', order: 'shipping' },
  { id: 'linkTime', t: 'ดราฟต์ผ่าน · รอส่งลิงก์', have: ALL_KEYS.filter(k => k !== 'bank'), verify: 'approved', phase: 'acceptedQuota', order: 'delivered', draftApproved: true },
  { id: 'done', t: 'ส่งรีวิวแล้ว · เสร็จสิ้น', have: ALL_KEYS, verify: 'approved', phase: 'acceptedQuota', order: 'delivered', draftApproved: true, reviewed: true },
];
// สถานะยืนยันตัวตน = UserVerifyStatus ของแอปหลักตัวต่อตัว: none · waiting (waiting_approve) · approved · rejected (reject)
const VERIFY_LABEL = { none: 'ยังไม่ได้ยืนยันตัวตน', waiting: 'รอทีมงานตรวจ', approved: 'ยืนยันตัวตนแล้ว', rejected: 'ไม่ผ่าน · ส่งใหม่ได้' };
// เหตุผลตีกลับที่ staff ใช้บ่อย (= StarFlow.rejectReasons)
const REJECT_REASONS = ['รูปบัตรไม่ชัด มองไม่เห็นเลขบัตรและวันหมดอายุ', 'ใบหน้าไม่ตรงกับรูปบนบัตร'];
const REJECT_FALLBACK = 'กรุณาทำรายการใหม่อีกครั้ง เนื่องจากรูปบัตรประชาชนไม่ตรงกัน';
// ตารางรหัสไปรษณีย์ย่อ (= ZipBook จำลอง getSubDistricts + getDistrictProvince) — รหัสที่ไม่รู้จักให้พิมพ์เอง
const ZIPBOOK = {
  '10110': ['คลองเตย', 'กรุงเทพมหานคร', ['คลองเตย', 'คลองตัน', 'พระโขนง']],
  '10250': ['สวนหลวง', 'กรุงเทพมหานคร', ['สวนหลวง', 'อ่อนนุช']],
  '10400': ['พญาไท', 'กรุงเทพมหานคร', ['สามเสนใน', 'ถนนพญาไท', 'ทุ่งพญาไท']],
  '10900': ['จตุจักร', 'กรุงเทพมหานคร', ['จตุจักร', 'ลาดยาว', 'เสนานิคม', 'จันทรเกษม', 'จอมพล']],
  '11000': ['เมืองนนทบุรี', 'นนทบุรี', ['สวนใหญ่', 'ตลาดขวัญ', 'บางกระสอ', 'ท่าทราย', 'บางเขน']],
  '50200': ['เมืองเชียงใหม่', 'เชียงใหม่', ['ศรีภูมิ', 'พระสิงห์', 'หายยา', 'ช้างม่อย', 'ช้างคลาน']],
};
const zipSubs = z => (ZIPBOOK[z] || [])[2] || [];
const zipPlace = (z, sub) => { const b = ZIPBOOK[z]; return b && b[2].includes(sub) ? { district: b[0], province: b[1] } : null; };
const SAMPLE_ADDRESS = name => ({ name, tel: '0891234567', address: '99/12 คอนโดลุมพินี ซ.สุขุมวิท 77', zip: '10250', sub: 'สวนหลวง', district: 'สวนหลวง', province: 'กรุงเทพมหานคร' });
// Lab: ผลจำลองตอนจบหน้ากล้อง — approved = OCR ผ่าน อนุมัติทันที · waiting = AI อ่านไม่ผ่าน ตกไปกรอกมือ ส่งทีมงานตรวจ
const KYC_OUTCOME_KEY = 'starflow.desktop.kycOutcome';
const kycOutcome = { get() { try { return localStorage.getItem(KYC_OUTCOME_KEY) || 'approved'; } catch (e) { return 'approved'; } },
  set(v) { try { localStorage.setItem(KYC_OUTCOME_KEY, v); } catch (e) { /* ไม่มี storage = ใช้ค่าเริ่มต้น */ } } };
const ORDER_LABEL = { preparing: 'กำลังจัดเตรียมพัสดุ', shipping: 'เช็กเลขติดตามพัสดุ', delivered: 'จัดส่งสำเร็จ' };

const STORE_KEY = 'starflow.desktop.v1';
const SAMPLE_BODY = { weight: '48', height: '165', chest: '32', waist: '25', hip: '35', shoe: '38' };
const blank = () => ({
  have: [], verify: 'none', starRank: false, verifyReason: '', kycSentAt: null, pendingCampaign: null, phase: 'register', order: 'preparing', reviewed: false, draftApproved: false, connected: [], revealSeen: false, consent: false,
  about: '', categories: [], provinces: [], availWeek: {}, creatorKind: 'creator', payKind: 'person', rates: {}, insightSlots: [], insightValues: {},
  lineID: '', phone: '', website: '', links: {}, followerCounts: {}, followerSources: {},
  addressInfo: { name: '', tel: '', address: '', zip: '', sub: '', district: '', province: '' },
  bankInfo: { bank: '', no: '', name: '', coName: '', taxID: '', branch: '', address: '', vat: '', shot: false },
  // สัดส่วน (= InputCreatorBodyMeasurement): รอบตัวเลือกหน่วยต่อช่อง นิ้ว/ซม. · รองเท้า EU
  bodyInfo: { weight: '', height: '', chest: '', waist: '', hip: '', shoe: '', chestUnit: 'นิ้ว', waistUnit: 'นิ้ว', hipUnit: 'นิ้ว' },
  media: { photos: [null, null, null], works: [], videos: [] },
  cards: 0, cardRevealSeen: false, starLevelSeen: false, fullCheered: false, autofill: true, jobs: [],
});

const F = {
  s: blank(),
  load() { try { const d = JSON.parse(localStorage.getItem(STORE_KEY)); if (d) {
    this.s = Object.assign(blank(), d);
    // state รุ่นก่อนเก็บ เช้า/บ่าย/เย็น → คีย์ช่วงเวลาของแอปหลัก · สัดส่วนรุ่นก่อนไม่มี = ค่าว่าง
    this.s.availWeek = Object.fromEntries(Object.entries(this.s.availWeek || {}).map(([d, v]) => [d, migrateSlots(v)]).filter(([, v]) => v.length));
    this.s.bodyInfo = Object.assign(blank().bodyInfo, d.bodyInfo || {});
    this.s.addressInfo = Object.assign(blank().addressInfo, d.addressInfo || {});
    // เพดานรูป/คลิปลดเหลือ 3 (7 ต.ค. 2569) — state รุ่นก่อนที่เก็บไว้เกินตัดทิ้งให้ตรงกติกา
    const m = this.s.media; if (m) { m.works = (m.works || []).slice(0, MAX.works); m.videos = (m.videos || []).slice(0, MAX.videos); }
  } } catch (e) { /* state เสีย = เริ่มใหม่ */ } },
  save() { try { localStorage.setItem(STORE_KEY, JSON.stringify(this.s)); } catch (e) { /* เต็ม/ปิด storage = ยังเล่นต่อได้ในหน่วยความจำ */ } },

  has(k) { return this.s.have.includes(k); },
  add(...ks) { ks.forEach(k => { if (!this.has(k)) this.s.have.push(k); }); },
  remove(k) { this.s.have = this.s.have.filter(x => x !== k); },
  get hasCard() { return this.has('kind') && this.has('categories') && this.has('media'); },
  get isVerified() { return this.s.verify === 'approved'; },
  // ตีกลับ = ต้องส่งใหม่ นับเหมือนยังไม่ส่ง
  get isMember() { return this.s.verify === 'waiting' || this.s.verify === 'approved'; },
  // ติดด่านยืนยันตัวตน (ผู้ใช้ 6 ต.ค. 2569: ต้อง "ผ่าน" ก่อนถึงส่งใบสมัครได้)
  get kycBlocked() { return this.s.verify === 'waiting' || this.s.verify === 'rejected'; },
  get rejectReason() { return this.s.verifyReason || REJECT_FALLBACK; },
  // STAR = มียศ STAR (`myProfile.userRank` — STAR เก่าที่ได้ยศจาก 3 ขั้นต้อนรับแบบเดิมเป็น STAR ต่อ แม้ 8 ข้อยังไม่ครบ · salehere-ios 7 ต.ค. 2569)
  // หรือครบ 8 ข้อที่แบรนด์ใช้คัดเลือก (รวมยืนยันตัวตนผ่าน) = `StarFlow.isStar` · ยศตั้งจาก Lab เท่านั้น ("STAR เก่า")
  get isStar() { return !!this.s.starRank || !this.starMissing.length; },
  // สถานะ C: เป็น STAR (มียศ) แต่ 8 ข้อยังไม่ครบ — ไม่มี % · banner "เติมข้อมูล STAR" · การ์ดทองกางพร้อมปุ่ม "เพิ่ม" · ด่านสมัครกิจกรรมบังคับกรอกก่อน = `needsStarInfo`
  get needsStarInfo() { return this.isStar && this.starMissing.length > 0; },
  // ครบ 8 ข้อจริง (ฉลอง/ล้างฉลองดูตัวนี้ ไม่ใช่ isStar ที่รวมยศ)
  get starComplete() { return !this.starMissing.length; },
  // % ทางไปเป็น STAR = (8 − ข้อที่ขาด) ÷ 8 — banner กับหน้า Star Profile เลขเดียวกัน · โชว์เฉพาะก่อนเป็น STAR = `starPct`
  get starPct() { return (8 - this.starMissing.length) / 8; },
  // เป็น STAR แล้ว (ครบ 8 ข้อ ไม่นับช่องทางที่เอาออกได้) = ข้อมูลที่กรอกแล้วลบไม่ได้ แก้ได้อย่างเดียว (ผู้ใช้ 7 ต.ค. 2569) = `StarFlow.keepsData`
  // ยกเว้นช่องทาง: เอาออกได้จนหมด → ไม่เป็น STAR จนกว่าจะเชื่อมใหม่ · ลงทะเบียนงานถัดไปถามช่องทางอีกรอบ (`registerSteps`)
  get keepsData() { return this.isStar || this.starMissing.every(s => s === 'socials'); },
  // แถวช่องทาง = เชื่อมแล้ว + ตั้งเรทแล้ว (ขั้นเดียวกันใน wizard) — แถวเส้นประตรงกับ `starMissing` ทุกข้อ
  done(row) { return !row.key ? this.isVerified : row.key === 'socials' ? this.has('socials') && this.has('rate') : this.has(row.key); },

  // ข้อไม่บังคับ: ยังไม่กรอกก็ไม่ทำให้หน้าของมันโผล่ซ้ำ ("ไม่บังคับ = ไม่ถามซ้ำ")
  needs(step) { return step === 'kyc' ? !this.isVerified : STEP.keys(step).some(k => !['insight', 'about', 'body'].includes(k) && !this.has(k)); },
  // 8 ข้อที่แบรนด์ใช้คัดเลือก STAR (= `StarFlow.starSteps`) — ทุกทางเข้าถามชุดนี้ก่อนเสมอ ครบ = เป็น STAR (motion) แล้วค่อยทำต่อ
  get starMissing() { return ['kind', 'socials', 'categories', 'media', 'province', 'availability', 'contact', 'kyc'].filter(s => this.needs(s)); },
  get registerSteps() { return this.starMissing; },
  // 8 ข้อก่อน แล้วค่อย ที่อยู่ · บัญชี · สัดส่วน (สัดส่วนถามต่อท้ายเฉพาะทาง "สมัครเป็น STAR" จาก Star Profile — ผู้ใช้ 6 ต.ค. 2569)
  get applySteps() { return [...this.starMissing, ...['address', 'bank', 'body'].filter(s => s === 'body' ? !this.has('body') : this.needs(s))]; },
  // ว่างแล้ว: ที่อยู่กรอกในฟอร์มสมัครเดิม (ผู้ใช้ 6 ต.ค. 2569) · บัญชีรับเงินฟอร์ม payout ของแอปหลักเก็บเอง
  get acceptSteps() { return []; },
  get pct() { return ROWS.filter(r => this.done(r)).length / ROWS.length; },
  // ขั้นที่ยังขาดตามลำดับแถว (ยืนยันตัวตนท้ายสุด) — เริ่มจากแถวที่แตะ แล้ววนต่อให้ครบ (= `missingSteps(from:)` ของ salehere-ios) · fromKey: คีย์แถว / 'kyc' / undefined
  missingSteps(fromKey) {
    const steps = [];
    ROWS.filter(r => !this.done(r)).forEach(r => { const st = r.key ? STEP.page(r.key) : 'kyc'; if (!steps.includes(st)) steps.push(st); });
    if (fromKey === undefined) return steps;
    const i = steps.indexOf(fromKey === 'kyc' || fromKey == null ? 'kyc' : STEP.page(fromKey));
    return i < 0 ? steps : [...steps.slice(i), ...steps.slice(0, i)];
  },
  // "เติมข้อมูลต่อ" (หลัง STAR) = ข้อที่ขาดใน 8 ข้อก่อน แล้วข้อเสริมที่ขาด = `fillMoreSteps`
  get fillMoreSteps() { const m = this.starMissing; return [...m, ...this.missingSteps().filter(s => !m.includes(s))]; },

  followers(id) { return this.s.followerCounts[id] || 0; },
  link(id) { return this.s.links[id] || ''; },
  handle(id) { const m = this.link(id).replace(/[?#].*$/, '').replace(/\/$/, '').split('/').pop() || ''; return m.replace(/^@/, ''); },
  get socials() { return SOCIALS.filter(s => this.s.connected.includes(s.id)); },
  get handleMain() { const s = this.socials[0]; return (s && this.handle(s.id)) || ACCOUNT_NAME.toLowerCase(); },
  checkLink(id, raw) {
    let v = (raw || '').trim(); if (!v) return { ok: false, msg: '', url: '' };
    if (!/^https?:\/\//i.test(v)) v = 'https://' + v;
    const s = SOC[id];
    if (s.bad && s.bad.test(v)) return { ok: false, msg: 'นี่คือลิงก์โพสต์ ไม่ใช่ลิงก์โปรไฟล์ — ใส่ลิงก์หน้าโปรไฟล์/ช่องแทน', url: v };
    if (!s.re.test(v)) return { ok: false, msg: `รูปแบบลิงก์ ${s.name} ไม่ถูกต้อง (ตัวอย่าง: ${s.ph})`, url: v };
    return { ok: true, msg: '', url: v };
  },
  // format ช่องทางติดต่อ — regex เดียวกับแอปหลัก (`validateLineId` / `validatePhoneNumber` / `isValidURL`)
  validLine: v => /^@?[a-z0-9._-]{4,20}$/.test(v),
  validPhone: v => /^(06|08|09)[0-9]{8}$/.test(v),
  // เว็บไซต์ไม่มี https:// เติมให้เอง แล้วค่อยตรวจ (host ต้องมีจุด ไม่ขึ้น/ลงท้ายด้วยจุด)
  normalizedWebsite(raw) { const v = (raw || '').trim(); return !v ? '' : /^https?:\/\//i.test(v) ? v : 'https://' + v; },
  validURL(v) { if (/\s/.test(v)) return false; try { const h = new URL(v).hostname; return h.includes('.') && !h.startsWith('.') && !h.endsWith('.'); } catch (e) { return false; } },
  // เบอร์จากบัญชี/ที่อยู่ → เติมช่องเบอร์: "+66"/"66" แปลงเป็น "0" · ไม่ผ่าน format = ไม่เติม (null)
  prefillPhone(raw) { let v = String(raw || '').replace(/[^0-9+]/g, ''); if (v.startsWith('+66')) v = '0' + v.slice(3); else if (v.startsWith('66') && v.length === 11) v = '0' + v.slice(2); return this.validPhone(v) ? v : null; },
  suggest(followers, f) { return Math.max(500, Math.round(followers / 1000 * 120 * FORMATS[f][1] / 100) * 100); },
  rate(id, f) { const v = this.s.rates[id + '_' + f]; return v != null ? v : this.suggest(this.followers(id), f); },
  fmt(n) { if (n >= 1e6) return (n / 1e6).toFixed(1) + 'M'; if (n >= 1000) return (n / 1000).toFixed(1).replace('.0', '') + 'K'; return String(n); },
  insightCount(id) { return INSIGHT_SLOTS.filter(x => this.s.insightSlots.includes(id + '_' + x.key)).length; },
  // หมวดที่ยังไม่ถึงขั้นต่ำ → { photos: '1 รูป', … } (error ขึ้นใต้หมวดนั้น)
  mediaLack() {
    const m = this.s.media, have = { photos: m.photos.filter(Boolean).length, works: m.works.length, videos: m.videos.length };
    return Object.fromEntries(['photos', 'works', 'videos'].filter(k => have[k] < MIN[k]).map(k => [k, `${MIN[k] - have[k]} ${k === 'videos' ? 'คลิป' : 'รูป'}`]));
  },
  mediaMissing() {
    const l = this.mediaLack(), name = { photos: 'รูปของคุณ', works: 'รูปผลงาน', videos: 'คลิป' };
    return Object.entries(l).map(([k, t]) => `${name[k]} ${t}`).join(' · ');
  },
  get availDays() { return WEEK.filter(d => (this.s.availWeek[d] || []).length); },
  availSummary() {
    const groups = [];
    WEEK.forEach((d, i) => {
      const s = DAY_SLOTS.filter(x => (this.s.availWeek[d] || []).includes(x)); if (!s.length) return;
      const g = groups.find(x => x.slots.join() === s.join()); if (g) g.days.push(i); else groups.push({ slots: s, days: [i] });
    });
    return groups.map(g => {
      const run = g.days.length > 2 && g.days[g.days.length - 1] - g.days[0] === g.days.length - 1;
      const d = run ? `${WEEK[g.days[0]]}–${WEEK[g.days[g.days.length - 1]]}` : g.days.map(i => WEEK[i]).join(' ');
      return d + ' ' + slotText(g.slots);
    });
  },
  bodyFilled() { const b = this.s.bodyInfo; return ['weight', 'height', 'chest', 'waist', 'hip', 'shoe'].some(k => b[k]); },
  // "165 ซม." · "50 กก." · "32-25-35 นิ้ว" (หน่วยเดียวกันครบสาม) · "EU 38"
  bodyFacts() {
    const b = this.s.bodyInfo, out = [];
    if (b.height) out.push(`${b.height} ซม.`); if (b.weight) out.push(`${b.weight} กก.`);
    const g = [[b.chest, b.chestUnit], [b.waist, b.waistUnit], [b.hip, b.hipUnit]];
    if (g.every(x => x[0]) && new Set(g.map(x => x[1])).size === 1) out.push(`${b.chest}-${b.waist}-${b.hip} ${b.chestUnit}`); else g.forEach(([v, u]) => v && out.push(`${v} ${u}`));
    if (b.shoe) out.push(`EU ${b.shoe}`);
    return out;
  },
  audienceTop() {
    for (const s of this.socials) { const g = this.s.insightValues[s.id + '_gender']; if (g && g.length) return s.id; }
    return (this.socials[0] || {}).id;
  },
  // ค่าที่กรอกไว้ของแถว (= facts) — ป้ายชิ้นละค่า
  facts(row) {
    const s = this.s, k = row.key, shortP = p => p === 'กรุงเทพมหานคร' ? 'กรุงเทพฯ' : p.replace(' (ออนไลน์)', '');
    if (!k) return ['Verified'];
    switch (k) {
      case 'rate': { const l = this.socials, shown = l.slice(0, 2).map(x => `${x.short} ฿${this.rate(x.id, x.formats[0]).toLocaleString('en-US')}`);
        const more = l.reduce((n, x) => n + x.formats.length, 0) - Math.min(2, l.length); return more > 0 ? [...shown, `+${more} รูปแบบ`] : shown; }
      case 'about': return [s.about.slice(0, 28) + (s.about.length > 28 ? '…' : '')];
      case 'media': return [`รูป ${s.media.photos.filter(Boolean).length}`, `ผลงาน ${s.media.works.length}`, `คลิป ${s.media.videos.length}`];
      // ช่องที่แนบข้อมูลผู้ติดตามแล้ว "IG ✓" (= salehere-ios)
      case 'insight': return this.socials.filter(x => Object.keys(s.insightValues).some(k => k.startsWith(x.id + '_'))).map(x => `${x.short} ✓`);
      case 'province': return s.provinces.length > 2 ? [...s.provinces.slice(0, 2).map(shortP), `+${s.provinces.length - 2}`] : s.provinces.map(shortP);
      case 'availability': return this.availSummary();
      case 'contact': return [s.lineID ? 'LINE ' + s.lineID : '', s.phone, s.website].filter(Boolean);
      // แถวช่องทางรวมเรท: ยอดผู้ติดตามต่อช่อง แล้วตามด้วยเรท (= salehere-ios)
      case 'socials': return [...this.socials.map(x => `${x.short} ${this.fmt(this.followers(x.id))}`), ...(this.has('rate') ? this.facts({ key: 'rate' }) : [])];
      case 'categories': return s.categories.map(c => c.split(' ').slice(1).join(' '));
      case 'bank': { const last = s.bankInfo.no.replace(/\D/g, '').slice(-4); return [s.payKind === 'company' ? 'นามบริษัท' : 'นามบุคคล', s.bankInfo.bank, last ? '···' + last : ''].filter(Boolean); }
      case 'address': return [[s.addressInfo.sub, s.addressInfo.zip].filter(Boolean).join(' ')].filter(Boolean);
      case 'body': return this.bodyFacts();
      case 'kind': return [s.creatorKind === 'page' ? 'Page (เพจ)' : 'Creator (บุคคล)'];
    }
    return [];
  },
  addressComplete() { const a = this.s.addressInfo; return !!(a.name && a.tel && a.address && a.zip); },
  // ครบ 7 ช่องแบบที่ createBrandCampaignApplication / createUserAddress บังคับ
  addressFull() { const a = this.s.addressInfo; return this.addressComplete() && !!(a.sub && a.district && a.province); },
  bankComplete() { const b = this.s.bankInfo, base = !!(b.bank && b.no && b.name); return this.s.payKind === 'company' ? base && !!b.coName && !!b.taxID : base; },

  // ---------- แผง Lab ----------
  stageIndex(ui) {
    const s = this.s, sc = ui.screen, k = ui.wiz && ui.wiz.kind;
    if (s.reviewed) return 14; if (sc === 'link') return 13;
    if (s.phase === 'acceptedQuota') return s.draftApproved ? 12 : s.order === 'delivered' ? 10 : 9;
    if (sc === 'accept') return 8; if (sc === 'wizard' && k === 'accept') return 7;
    if (s.phase === 'waitingAcceptQuota') return 6;
    if (s.phase === 'registered') return ui.dialog === 'registerSuccess' ? 4 : 5;
    if (sc === 'register') return 3; if (sc === 'reveal') return 2; if (sc === 'wizard') return 1;
    return 0;
  },
  goto(i) {
    const st = STAGES[i], s = this.s; s.have = []; s.verify = 'none'; s.verifyReason = ''; s.kycSentAt = null;
    RULES.forEach(([k, , need]) => { if (i >= need) { if (k) s.have.push(k); else s.verify = 'approved'; } });
    s.phase = st.phase; s.order = st.order || 'preparing'; s.reviewed = !!st.reviewed; s.draftApproved = !!st.draftApproved; s.consent = i >= 3;
    this.labSample(); if (i === 2) s.revealSeen = false;
    this.save(); return st;
  },
  tick(key, on, stage) {
    if (key) { on ? this.add(key) : this.remove(key); } else this.s.verify = on ? 'approved' : 'none';
    this.labSample(); this.save();
    const r = RULES.find(x => x[0] === key);
    return (!on && r && stage >= r[2]) ? r[1] : null;
  },
  applyPreset(p) {
    const s = this.s; s.have = [...p.have]; s.verify = p.verify; s.starRank = !!p.rank; s.verifyReason = ''; s.kycSentAt = null; s.phase = p.phase || 'register'; s.order = p.order || 'preparing';
    s.reviewed = !!p.reviewed; s.draftApproved = !!p.draftApproved; s.consent = s.phase !== 'register';
    this.labSample(); this.save();
  },
  fillAll() { this.s.have = [...ALL_KEYS]; if (!this.isVerified) this.s.verify = 'approved'; this.labSample(); this.save(); },
  // ค่าตัวอย่างสำหรับ Lab เท่านั้น — กระโดดขั้นแล้วหัวข้อที่ติ๊กว่า "มี" ต้องมีค่าให้หน้าวาด
  labSample() {
    const s = this.s;
    if (this.has('socials') && !s.connected.length) {
      s.connected = ['instagram', 'tiktok', 'youtube'];
      s.links = { instagram: 'https://instagram.com/mae.review', tiktok: 'https://tiktok.com/@mae.review', youtube: 'https://youtube.com/@maereview' };
      s.followerCounts = { instagram: 24800, tiktok: 86200, youtube: 12400 }; s.followerSources = { instagram: 'connect', tiktok: 'connect', youtube: 'api' };
    }
    if (this.has('categories') && !s.categories.length) s.categories = ['👗 แฟชั่น', '☕️ คาเฟ่', '✈️ ท่องเที่ยว'];
    if (this.has('about') && !s.about) s.about = FALLBACK_BIO;
    if (this.has('media')) this.sampleMedia();
    if (this.has('province') && !s.provinces.length) s.provinces = ['กรุงเทพมหานคร'];
    if (this.has('availability') && !this.availDays.length) s.availWeek = Object.fromEntries(WEEK.map(d => [d, [...DAY_SLOTS]]));
    if (this.has('contact') && !s.phone) { s.phone = '0891234567'; if (!s.lineID) s.lineID = '@maneerat.review'; }
    if (this.has('insight') && !s.insightSlots.length) INSIGHT_SLOTS.forEach(x => { s.insightSlots.push('instagram_' + x.key); s.insightValues['instagram_' + x.key] = SAMPLE_INSIGHT[x.key]; });
    if (this.has('address') && !s.addressInfo.address) s.addressInfo = SAMPLE_ADDRESS(ACCOUNT_NAME);
    if (this.has('bank') && !s.bankInfo.no) Object.assign(s.bankInfo, { bank: 'กสิกรไทย', no: '1234567890', name: ACCOUNT_NAME });
    if (this.has('body') && !this.bodyFilled()) Object.assign(s.bodyInfo, SAMPLE_BODY);
  },
  sampleMedia() {
    const m = this.s.media, ph = n => `assets/ph0${n}.jpg`;
    m.photos = m.photos.map((p, i) => p || ph(i + 1));
    while (m.works.length < MIN.works) m.works.push({ id: 'w' + Date.now() + m.works.length, src: ph(4 - m.works.length) });
    while (m.videos.length < MIN.videos) m.videos.push({ id: 'v' + Date.now() + m.videos.length, src: ph(2 + m.videos.length), dur: '0:02' });
  },
  // "กรอกตัวอย่างให้": เติมช่องว่างของขั้นที่ wizard จะถาม — ไม่ติ๊ก have ให้ ยังต้องกดถัดไปทุกหน้า
  autofill(steps) {
    const s = this.s; if (!s.autofill) return;
    steps.forEach(st => {
      if (['socials', 'rate', 'insight'].includes(st)) {
        const pick = s.connected.length ? s.connected : ['instagram', 'tiktok', 'youtube'];
        pick.forEach(id => { if (!this.followers(id) || !this.link(id)) {
          s.links[id] = SOC[id].mock[0]; s.followerCounts[id] = SOC[id].mock[1]; s.followerSources[id] = SOC[id].fetch;
          SOC[id].formats.forEach(f => { s.rates[id + '_' + f] = this.suggest(SOC[id].mock[1], f); });
        } });
        if (!s.connected.length) s.connected = [...pick];
        s.connected.filter(id => SOC[id].insight).forEach(id => INSIGHT_SLOTS.forEach(x => {
          const k = id + '_' + x.key; if (!s.insightValues[k]) { s.insightValues[k] = SAMPLE_INSIGHT[x.key]; if (!s.insightSlots.includes(k)) s.insightSlots.push(k); }
        }));
      }
      if (st === 'categories' && !s.categories.length) s.categories = ['👗 แฟชั่น', '☕️ คาเฟ่', '✈️ ท่องเที่ยว'];
      if (st === 'about' || st === 'media') { if (!s.about) s.about = FALLBACK_BIO; if (st === 'media') this.sampleMedia(); }
      if (st === 'province' && !s.provinces.length) s.provinces = ['กรุงเทพมหานคร', 'นนทบุรี'];
      if (st === 'availability' && !this.availDays.length) s.availWeek = { 'จ': ['slot_17_late'], 'อ': ['slot_17_late'], 'พ': ['slot_17_late'], 'พฤ': ['slot_17_late'], 'ศ': ['slot_17_late'], 'ส': [...DAY_SLOTS], 'อา': [...DAY_SLOTS] };
      if (st === 'body' && !this.bodyFilled()) Object.assign(s.bodyInfo, SAMPLE_BODY);
      if (st === 'contact') { if (!s.lineID) s.lineID = '@maneerat.review'; if (!s.phone) s.phone = '0891234567'; }
      if (st === 'address' && !s.addressInfo.address) s.addressInfo = SAMPLE_ADDRESS('มณีรัตน์ ใจดี');
      if (st === 'bank' && !s.bankInfo.no) Object.assign(s.bankInfo, { bank: 'กสิกรไทย', no: '1234567890', name: 'มณีรัตน์ ใจดี' });
    });
    // ไม่เติม LINE นอกขั้นช่องทางติดต่อแล้ว (= iOS `autofill`)
    this.save();
  },
  reset(all) { const keep = all ? {} : { jobs: this.s.jobs, autofill: this.s.autofill }; this.s = Object.assign(blank(), keep); this.save(); },
};
F.load();

// ---------- ST★R Insight (ข้อมูลจำลอง = StarInsight.mock) ----------
const INSIGHT_WEEK = [318, 362, 948, 622, 521, 468, 681];
const INSIGHT = {
  mode: new URLSearchParams(location.search).get('insightEmpty') || '', // YES = ยังไม่เคยมีคนเห็น · week = 7 วันล่าสุดเงียบ
  get(range) {
    if (this.mode === 'YES' || (this.mode === 'week' && range === 'week')) return { daily: [0, 0, 0, 0, 0, 0, 0], prev: 0, opened: 0, styles: [], axis: [], names: [], empty: true, views: 0 };
    const styles = range === 'week' ? [['คาเฟ่', 14], ['บิวตี้', 9], ['แฟชั่น', 6], ['อื่น ๆ', 5]] : [['คาเฟ่', 43], ['บิวตี้', 31], ['แฟชั่น', 22], ['อื่น ๆ', 16]];
    const daily = range === 'week' ? INSIGHT_WEEK : [352, 371, 398, 420, 388, 365, 342, 377, 402, 431, 455, 418, 392, 380, 405, 428, 462, 480, 441, 423, 430, ...INSIGHT_WEEK];
    const names = range === 'week' ? ['จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์', 'เสาร์', 'วันนี้'] : daily.map((_, i) => i === 27 ? 'วันนี้' : (7 + i <= 30 ? `${7 + i} ก.ย.` : `${i - 23} ต.ค.`));
    const views = daily.reduce((a, b) => a + b, 0), prev = range === 'week' ? 3322 : 10400, opened = range === 'week' ? 1284 : 3870;
    return { daily, prev, opened, styles, names, views, empty: false, axis: range === 'week' ? ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'] : ['7 ก.ย.', '21 ก.ย.', 'วันนี้'],
      peakNote: 'วันที่แชร์ลง IG Story', today: ['คาเฟ่', 3], change: (views - prev) / prev, openRate: opened / views, brands: styles.reduce((a, b) => a + b[1], 0) };
  },
  get neverSeen() { return this.get('week').empty && this.get('month').empty; },
};

// ---------- ตารางงาน (= StarSchedule) — วันที่เก็บเป็น 'YYYY-MM-DD' ----------
const SD = {
  months: ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'],
  monthsFull: ['มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'],
  weekdays: ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'],
  iso(d) { return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`; },
  date(iso) { const [y, m, d] = iso.split('-').map(Number); return new Date(y, m - 1, d); },
  get today() { return this.iso(new Date()); },
  day(n, from) { const d = this.date(from || this.today); d.setDate(d.getDate() + n); return this.iso(d); },
  gap(a, b) { return Math.round((this.date(a) - this.date(b)) / 86400000); },
  short(iso) { const d = this.date(iso); return `${d.getDate()} ${this.months[d.getMonth()]}`; },
  weekday(iso) { return this.weekdays[this.date(iso).getDay()]; },
  label(iso) { return iso === this.today ? 'วันนี้' : iso === this.day(1) ? 'พรุ่งนี้' : `${this.weekday(iso)}. ${this.short(iso)}`; },
  title(iso) { const full = `${this.weekday(iso)}. ${this.short(iso)}`; return iso === this.today ? 'วันนี้ · ' + full : iso === this.day(1) ? 'พรุ่งนี้ · ' + full : full; },
  monthTitle(iso) { const d = this.date(iso); return `${this.monthsFull[d.getMonth()]} ${d.getFullYear() + 543}`; },
  first(iso) { return iso.slice(0, 8) + '01'; },
  baht(n) { return '฿' + Number(n).toLocaleString('en-US'); },
};
const JOB_PLATFORMS = ['instagram', 'tiktok', 'youtube', 'facebook'];
const JOB_FORMATS = { instagram: ['Reel', 'โพสต์', 'Story', 'ไลฟ์'], tiktok: ['คลิป', 'ไลฟ์'], youtube: ['คลิป', 'Shorts', 'ไลฟ์'], facebook: ['โพสต์', 'Reel', 'ไลฟ์'] };
const SCHED = {
  get jobs() { return F.s.jobs; },
  get entries() { return this.jobs.flatMap(j => j.steps.map(st => ({ job: j, step: st }))); },
  get overdue() { return this.entries.filter(e => e.step.date < SD.today && !e.step.done).sort((a, b) => a.step.date < b.step.date ? -1 : 1); },
  on(iso) { return this.entries.filter(e => e.step.date === iso).sort((a, b) => (a.step.time || '99') < (b.step.time || '99') ? -1 : 1); },
  open(iso) { return this.entries.filter(e => e.step.date === iso && !e.step.done).length; },
  nextDay(iso) { return this.entries.filter(e => e.step.date > iso && !e.step.done).map(e => e.step.date).sort()[0]; },
  get next() { return this.entries.filter(e => e.step.date >= SD.today && !e.step.done).sort((a, b) => (a.step.date + (a.step.time || '99')) < (b.step.date + (b.step.time || '99')) ? -1 : 1)[0]; },
  get pendingMoney() { return this.jobs.filter(j => j.fee > 0 && !j.paid).reduce((n, j) => n + j.fee, 0); },
  job(id) { return this.jobs.find(j => j.id === id); },
  // ติ๊กขั้นของงานทั่วไป — คืนคำถามที่ควรถามต่อ (งานจบทุกขั้น = ถามโชว์บน Star Card)
  toggle(jobId, stepId) {
    const j = this.job(jobId); if (!j) return null; const st = j.steps.find(x => x.id === stepId); if (!st) return null;
    st.done = !st.done; F.save();
    if (st.done && !j.showOnCard && j.steps.every(x => x.done)) return { jobId, title: `งาน ${j.brand} จบแล้ว โชว์บน Star Card ไหม`, sub: 'แบรนด์เห็นชื่อแบรนด์และชิ้นงาน ไม่เห็นค่าตัว', yes: 'โชว์', no: 'ไม่โชว์', doneText: 'เพิ่มผลงานลง Star Card แล้ว' };
    return null;
  },
  draftMissing(d, step) {
    if (step === 1) { if (!d.brand.trim()) return 'ชื่อแบรนด์'; if (!d.title.trim()) return 'งานอะไร'; }
    else if (step === 2) {
      const chosen = JOB_PLATFORMS.filter(p => d.plats[p]); if (!chosen.length) return 'ลงที่ไหน';
      for (const p of chosen) { const v = d.plats[p]; if (Object.values(v.counts).every(n => !n)) return 'ชิ้นงานของ ' + SOC[p].short; if (!v.date) return 'วันลง ' + SOC[p].short; }
    } else { if (d.site == null) return 'ต้องไปหน้างานไหม'; if (d.site && !d.siteDate) return 'วันที่ไปหน้างาน'; }
    return '';
  },
  build(d) {
    const posts = JOB_PLATFORMS.filter(p => d.plats[p] && d.plats[p].date).map(p => ({ platform: p, date: d.plats[p].date,
      items: JOB_FORMATS[p].filter(f => d.plats[p].counts[f] > 0).map(f => ({ name: f, count: d.plats[p].counts[f] })) })).sort((a, b) => a.date < b.date ? -1 : 1);
    const steps = [], uid = () => 's' + Math.random().toString(36).slice(2, 9), place = d.sitePlace.trim();
    if (d.site && d.siteDate) steps.push({ id: uid(), kind: 'event', label: 'ไปหน้างาน', date: d.siteDate, time: d.siteTime || null, sub: place || null, done: false });
    [...new Set(posts.map(p => p.date))].sort().forEach(day => steps.push({ id: uid(), kind: 'post', label: 'ลงคอนเทนต์', date: day, time: null, done: false }));
    steps.sort((a, b) => (a.date + (a.time || '99')) < (b.date + (b.time || '99')) ? -1 : 1);
    return { id: 'j' + Date.now(), source: 'own', brand: d.brand.trim(), title: d.title.trim(), posts, steps, fee: Number(String(d.fee).replace(/\D/g, '')) || 0, showOnCard: false, paid: false, place: d.site && place ? place : null };
  },
};
