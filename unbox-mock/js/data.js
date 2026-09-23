// ข้อมูลจำลอง + enum ทุกตัวของ flow Unbox (Sale Here STAR) — ถอดจาก salehere-ios 22 ก.ย. 2569
// ชื่อ enum และ copy ไทยตรงกับ GraphAPI + Localized.strings ของแอปจริง

window.UNBOX = (function () {
  // ---------- BrandCampaignState (แท็บ "วิธีการร่วมกิจกรรม" · ปุ่มล่าง) ----------
  // ที่มา: Views/UnboxStateView/UnboxEnumExtension/BrandCampaignState.swift
  const CAMPAIGN_STATES = [
    { key: 'notOpenRegister', label: 'ยังไม่เปิดลงทะเบียน', button: 'ยังไม่เปิดลงทะเบียน', style: 'gray', enabled: false, desc: 'ลงทะเบียนได้ในอีก {days} วัน', clock: false, phase: 'สมัคร' },
    { key: 'register', label: 'เปิดลงทะเบียน', button: 'ลงทะเบียนร่วมกิจกรรม', style: 'red', enabled: true, desc: 'เหลือเวลาลงทะเบียน', clock: true, phase: 'สมัคร' },
    { key: 'registered', label: 'ลงทะเบียนแล้ว', button: 'คุณได้ลงทะเบียนแล้ว', style: 'green', enabled: false, desc: 'รอประกาศชื่อผู้ได้รับคัดเลือก', clock: false, phase: 'สมัคร' },
    { key: 'maxRegister', label: 'สิทธิ์เต็ม', button: 'สิทธิ์ของกิจกรรมนี้เต็มแล้ว', style: 'gray', enabled: false, desc: 'รอประกาศชื่อผู้ได้รับคัดเลือก', clock: false, phase: 'สมัคร' },
    { key: 'expire', label: 'หมดเวลาลงทะเบียน', button: 'หมดเวลาลงทะเบียน', style: 'gray', enabled: false, desc: 'รอประกาศชื่อผู้ได้รับคัดเลือก', clock: false, phase: 'สมัคร' },
    { key: 'awardAnnouncement', label: 'ประกาศผลแล้ว', button: 'รายชื่อผู้เข้าร่วมกิจกรรม', style: 'outline', enabled: true, desc: 'ร่วมกิจกรรมอื่นได้ ที่หน้ารวมกิจกรรม Sale Here STAR', clock: false, phase: 'คัดเลือก' },
    { key: 'waitingAcceptQuota', label: 'ได้รับเลือก · รอตอบรับ', button: 'ตอบรับกิจกรรม', style: 'red', enabled: true, desc: 'เหลือเวลาตอบรับ', clock: true, phase: 'คัดเลือก' },
    { key: 'forceVerifyUser', label: 'ต้องยืนยันตัวตน', button: 'ส่งข้อมูลยืนยันตัวตน', style: 'red', enabled: true, desc: 'ยืนยันตัวตนเพื่อเข้าร่วมกิจกรรม', clock: false, phase: 'คัดเลือก' },
    { key: 'acceptedQuota', label: 'ตอบรับแล้ว · ทำงาน', button: 'รายละเอียดการรีวิว', style: 'red', enabled: true, desc: '{order}', clock: false, phase: 'ทำงาน' },
    { key: 'rejectQuotaByUser', label: 'สละสิทธิ์', button: 'คุณสละสิทธิ์เข้าร่วม Sale Here STAR', style: 'gray', enabled: false, desc: 'ร่วมกิจกรรมอื่นได้ ที่หน้ารวมกิจกรรม Sale Here STAR', clock: false, phase: 'คัดเลือก' },
    { key: 'rejectQuotaByExpire', label: 'ไม่ตอบรับทันเวลา', button: 'คุณไม่ได้ตอบรับภายในเวลาที่กำหนด', style: 'gray', enabled: false, desc: 'ร่วมกิจกรรมอื่นได้ ที่หน้ารวมกิจกรรม Sale Here STAR', clock: false, phase: 'คัดเลือก' },
    { key: 'rejectQuotaByAdmin', label: 'ถูกตัดสิทธิ์', button: 'คุณถูกตัดสิทธิ์เข้าร่วม Sale Here STAR', style: 'gray', enabled: false, desc: 'เหตุผลที่ถูกตัดสิทธิ์', clock: false, phase: 'คัดเลือก' },
  ];

  // ---------- OrderStatus (ใต้ปุ่ม acceptedQuota) ----------
  const ORDER_STATUSES = [
    { key: 'preparing', label: 'กำลังจัดเตรียมพัสดุ' },
    { key: 'waitingPickup', label: 'รอขนส่งเข้ารับพัสดุ' },
    { key: 'shipping', label: 'เช็คเลขติดตามพัสดุ' },
    { key: 'parcelReject', label: 'พัสดุถูกตีกลับ' },
    { key: 'delivered', label: 'จัดส่งสำเร็จ' },
    { key: 'paid', label: 'เริ่มส่งสินค้า/คูปองออนไลน์' },
  ];

  // ---------- BrandCampaignReviewState (แท็บ "รีวิว") ----------
  // ที่มา: Views/UnboxStateView/UnboxEnumExtension/BrandCampaignReviewState.swift
  const REVIEW_STATES = [
    { key: 'none', label: '— ยังไม่ถึงขั้นรีวิว', buttons: [], desc: '' },
    { key: 'notOpenDraft', label: 'ยังไม่เปิดส่งดราฟต์', buttons: [{ t: 'เริ่มส่งดราฟต์รีวิว {date} น.', s: 'gray', e: false }], desc: 'เริ่มส่งดราฟต์ได้ในอีก {days} วัน' },
    { key: 'waitingDraft', label: 'รอส่งดราฟต์', buttons: [{ t: 'รายละเอียดการรีวิว', s: 'outline', e: true, a: 'brief' }, { t: 'สร้างดราฟต์รีวิว', s: 'red', e: true, a: 'createDraft' }], desc: 'เหลือเวลาส่งดราฟต์', clock: true },
    { key: 'draft', label: 'มีแบบร่าง', buttons: [{ t: 'รายละเอียดการรีวิว', s: 'outline', e: true, a: 'brief' }, { t: 'แก้ไขแบบร่าง', s: 'red', e: true, a: 'editDraft' }], desc: 'เหลือเวลาส่งดราฟต์', clock: true },
    { key: 'waitingApproveDraft', label: 'กำลังตรวจดราฟต์', buttons: [{ t: 'รายละเอียดการรีวิว', s: 'outline', e: true, a: 'brief' }, { t: 'กำลังตรวจดราฟต์รีวิว', s: 'yellow', e: true, a: 'preview' }], desc: 'เหลือเวลาส่งดราฟต์', clock: true },
    { key: 'rejectDraft', label: 'ดราฟต์ไม่ผ่าน', buttons: [{ t: 'รายละเอียดการรีวิว', s: 'outline', e: true, a: 'brief' }, { t: 'แก้ไขดราฟต์รีวิว', s: 'red', e: true, a: 'verdict' }], desc: 'เหลือเวลาส่งดราฟต์', clock: true },
    { key: 'expireDraft', label: 'หมดเวลาส่งดราฟต์', buttons: [{ t: 'ติดต่อผู้ช่วยส่วนตัว', s: 'outline', e: true, a: 'chat' }], desc: 'หมดเวลาส่งดราฟต์' },
    { key: 'notOpenReview', label: 'ดราฟต์ผ่าน · รอเปิดส่งลิงก์', buttons: [{ t: 'ดราฟต์ผ่านแล้ว : รอส่งลิงก์รีวิว', s: 'green', e: false }], desc: 'เริ่มส่งลิงก์รีวิวได้ในอีก {days} วัน' },
    { key: 'waitingReview', label: 'รอส่งลิงก์รีวิว', buttons: [{ t: 'ส่งลิงก์รีวิว', s: 'red', e: true, a: 'link' }], desc: 'เหลือเวลาส่งลิงก์รีวิว', clock: true },
    { key: 'reviewed', label: 'ส่งรีวิวแล้ว · เสร็จสิ้น', buttons: [{ t: 'ดูโพสต์รีวิว', s: 'outline', e: true, a: 'post' }], desc: 'เสร็จสิ้นการส่งรีวิวกิจกรรม' },
    { key: 'expireReview', label: 'หมดเวลาส่งลิงก์', buttons: [{ t: 'ติดต่อผู้ช่วยส่วนตัว', s: 'outline', e: true, a: 'chat' }], desc: 'หมดเวลาส่งลิงก์รีวิว' },
    { key: 'forceVerifyUser', label: 'ไม่ได้ยืนยันตัวตน', buttons: [{ t: 'สร้างดราฟต์รีวิว', s: 'gray', e: false }], desc: 'คุณไม่ได้ยืนยันตัวตน' },
    { key: 'waitingVerifyUser', label: 'รออนุมัติยืนยันตัวตน', buttons: [{ t: 'สร้างดราฟต์รีวิว', s: 'gray', e: false }], desc: 'รออนุมัติการยืนยันตัวตน' },
    { key: 'canNotReview', label: 'รีวิวไม่ได้', buttons: [{ t: 'สร้างดราฟต์รีวิว', s: 'gray', e: false }], desc: 'คุณไม่สามารถรีวิวได้' },
    { key: 'endReview', label: 'สิ้นสุดกิจกรรม', buttons: [{ t: 'สิ้นสุดเวลากิจกรรม', s: 'gray', e: false }], desc: '' },
  ];

  // ---------- สถานะฝั่งผู้ใช้ ----------
  const VERIFY_STATUSES = [
    { key: 'none', label: 'ยังไม่ได้ยืนยันตัวตน' },
    { key: 'waiting_approve', label: 'รอพิจารณา (คนตรวจ)' },
    { key: 'approved', label: 'ยืนยันตัวตนแล้ว' },
    { key: 'reject', label: 'ไม่ผ่านการอนุมัติ' },
  ];
  const PUNISHMENTS = [
    { key: 'none', label: 'ปกติ' },
    { key: 'warn', label: 'warn · เคยได้รางวัลแล้วยังไม่รีวิว (ยังอยู่ในเวลา)' },
    { key: 'banned', label: 'banned · ไม่ส่งรีวิว' },
  ];
  const REVIEW_STATUSES = [
    { key: 'none', label: 'ไม่เคยได้รับรางวัล' },
    { key: 'reviewComplete', label: 'ส่งรีวิวครบ' },
    { key: 'reviewPending', label: 'ค้างส่งรีวิว (โดนบล็อกสมัคร)' },
  ];
  const QUOTA_TYPES = [
    { key: 'primary', label: 'ตัวจริง' },
    { key: 'backup', label: 'ผู้รับรางวัลสำรอง' },
  ];

  // ---------- ข้อมูลกิจกรรม (BrandCampaignDetails) ----------
  const CAMPAIGNS = [
    {
      slug: 'wonder-one-2027', ep: 'EP.1585',
      title: 'WONDER ONE Music Festival 2027 รวมพลสายคอนเสิร์ต ท่ามกลางบรรยากาศธรรมชาติริมทะเลสาบ',
      brand: 'WONDER ONE', logo: 'assets/logo-wonder.png', cover: 'assets/cover-wonder.png',
      dateRange: '21 ก.ย. 69 - 28 ก.ย. 69',
      howTo: 'จัดเต็มความสนุกตั้งแต่เที่ยงวันยันเที่ยงคืนกับ 5 WONDERS ทั้งวิวธรรมชาติ ร้านเด็ดกว่า 30 ร้าน โซนถ่ายรูปสุดฮิป 🎡 และคอนเสิร์ตสุดอลังการจาก 7 ศิลปินฮอต JEFF SATUR, NONT TANONT, PiXXiE, MILLI, SLOT MACHINE, TIMETHAI และ RISA NARISA 🎶🔥 ปิดท้ายค่ำคืนด้วยงานไฟ Immersive Light สุดว้าว พร้อมที่จอดรถเพียบและห้องน้ำสะอาดติดสปีด 🚗 บัตร Early Bird มาพร้อมสิทธิพิเศษ จองก่อนได้ราคาดีกว่า แล้วเจอกันที่ริมทะเลสาบ!',
      reward: 'บัตร Early Bird 2 ใบ + ชุด Merchandise',
      quota: 20,
      socialChannels: ['instagram', 'tiktok'],
      contentTypes: ['Photo', 'Short Video'],
      timeline: [
        { k: 'ลงทะเบียน', v: '21 – 28 ก.ย. 69' },
        { k: 'ประกาศผล', v: '30 ก.ย. 69' },
        { k: 'ตอบรับกิจกรรม', v: '30 ก.ย. – 2 ต.ค. 69' },
        { k: 'จัดส่งสินค้า', v: '3 ต.ค. 69' },
        { k: 'ส่งดราฟต์รีวิว', v: '5 – 12 ต.ค. 69' },
        { k: 'ส่งลิงก์รีวิว', v: '13 – 20 ต.ค. 69' },
      ],
      brief: 'รีวิวบรรยากาศงาน WONDER ONE Music Festival 2027 เน้นโซนธรรมชาติริมทะเลสาบ ร้านค้า และคอนเสิร์ต\n\n• โพสต์ IG อย่างน้อย 1 โพสต์ (ภาพ 4–10 รูป) + Story 3 สไลด์\n• TikTok คลิปสั้น 30–60 วินาที เห็นบรรยากาศงานจริง\n• ติดแฮชแท็ก #WONDERONE2027 #SaleHereSTAR และแท็ก @wonderone.official\n• ห้ามใช้ภาพจากงานอื่น ห้ามตัดต่อโลโก้ผู้จัด\n• ส่งดราฟต์ก่อนโพสต์จริงทุกครั้ง',
      questions: [
        { type: 'text', q: 'ทำไมคุณถึงอยากไปงานนี้? (สั้น ๆ)' },
        { type: 'radio', q: 'เคยไปเทศกาลดนตรีมาก่อนไหม', options: ['เคย', 'ไม่เคย'] },
        { type: 'checkbox', q: 'ศิลปินที่คุณตั้งใจไปดู (เลือกได้มากกว่า 1 ตัวเลือก)', options: ['JEFF SATUR', 'NONT TANONT', 'PiXXiE', 'MILLI', 'SLOT MACHINE', 'TIMETHAI', 'RISA NARISA'] },
        { type: 'upload', q: 'แนบตัวอย่างคอนเทนต์สายคอนเสิร์ตของคุณ' },
      ],
      acceptQuestions: [
        { type: 'radio', q: 'สะดวกไปงานวันไหน', options: ['เสาร์ 4 ต.ค.', 'อาทิตย์ 5 ต.ค.', 'ทั้งสองวัน'] },
      ],
      // flow ใหม่: สิ่งที่งานนี้ขอเพิ่มจากการ์ด
      formats: [{ platform: 'instagram', key: 'reels', label: 'IG Reels', suggest: 3200 }, { platform: 'tiktok', key: 'short', label: 'TikTok คลิปสั้น', suggest: 4500 }],
      needs: { measurements: false, province: true, video: true }, fee: 3000, category: 'อีเวนต์',
      registered: 184, applications: [
        { name: 'มณีรัตน์ ใจดี', star: true, me: true, avatar: 'assets/ph01.jpg' },
        { name: 'Tarmjaipa', star: true, avatar: 'assets/ph02.jpg' },
        { name: 'ploy.review', star: true, avatar: 'assets/ph03.jpg' },
        { name: 'bank_eatlab', star: false, avatar: 'assets/ph04.jpg' },
        { name: 'nana.cafehop', star: true, avatar: 'assets/ph02.jpg' },
      ],
      posts: [
        { user: 'ploy.review', avatar: 'assets/ph03.jpg', img: 'assets/ph01.jpg', title: 'ริมทะเลสาบสวยมาก เดินทั้งวันไม่เบื่อ', likes: 128, comments: 12 },
        { user: 'nana.cafehop', avatar: 'assets/ph02.jpg', img: 'assets/ph04.jpg', title: 'โซนร้านค้า 30 ร้าน กินไม่หมด', likes: 96, comments: 8 },
      ],
    },
    {
      slug: 'thymora-1569', ep: 'EP.1569',
      title: 'Thymora ผลิตภัณฑ์สมุนไทยบำรุงผิว บอกลาปัญหาผิวและเส้นผม',
      brand: 'Thymora', logo: 'assets/logo-thymora.png', cover: 'assets/cover-thymora.png',
      dateRange: '26 ส.ค. 69 - 30 ก.ย. 69',
      howTo: 'รับผลิตภัณฑ์ Thymora ชุดบำรุงผิวและเส้นผมจากสมุนไพรไทย ทดลองใช้จริง 14 วัน แล้วรีวิวประสบการณ์ผ่านช่องทางของคุณ พร้อมแนบรูปก่อน-หลังใช้ และติดแฮชแท็ก #Thymora #SaleHereSTAR ในโพสต์',
      reward: 'ชุดผลิตภัณฑ์ Thymora มูลค่า 1,890 บาท', quota: 50,
      socialChannels: ['instagram'], contentTypes: ['Photo'],
      timeline: [
        { k: 'ลงทะเบียน', v: '26 ส.ค. – 30 ก.ย. 69' }, { k: 'ประกาศผล', v: '2 ต.ค. 69' }, { k: 'ตอบรับกิจกรรม', v: '2 – 4 ต.ค. 69' },
        { k: 'จัดส่งสินค้า', v: '6 ต.ค. 69' }, { k: 'ส่งดราฟต์รีวิว', v: '20 – 27 ต.ค. 69' }, { k: 'ส่งลิงก์รีวิว', v: '28 ต.ค. – 4 พ.ย. 69' },
      ],
      brief: 'รีวิวการใช้จริง 14 วัน แนบภาพก่อน-หลัง ติด #Thymora #SaleHereSTAR',
      questions: [{ type: 'radio', q: 'สภาพผิวของคุณ', options: ['ผิวมัน', 'ผิวแห้ง', 'ผิวผสม', 'ผิวแพ้ง่าย'] }],
      formats: [{ platform: 'instagram', key: 'post', label: 'IG ภาพลงฟีด', suggest: 1500 }],
      needs: { measurements: false, province: false, video: false }, fee: 0, category: 'บิวตี้',
      acceptQuestions: [], registered: 412, applications: [], posts: [],
    },
    {
      slug: 'terminal21-1571', ep: 'EP.1571',
      title: 'Terminal 21 เช็คอินคาเฟ่ลับ 5 ชั้น เก็บครบทุกมุมถ่ายรูป',
      brand: 'Terminal 21', logo: 'assets/ph03.jpg', cover: 'assets/ph02.jpg',
      dateRange: '14 ก.ย. 69 - 20 ก.ย. 69',
      howTo: 'เดินเก็บคาเฟ่ลับใน Terminal 21 ให้ครบ 5 ร้าน ถ่ายรูปกับมุมประจำชั้น แล้วโพสต์รีวิวแบบ carousel อย่างน้อย 5 รูป',
      reward: 'Gift Voucher 1,000 บาท', quota: 30, socialChannels: ['instagram', 'lemon8'], contentTypes: ['Photo'],
      timeline: [{ k: 'ลงทะเบียน', v: '14 – 20 ก.ย. 69' }, { k: 'ประกาศผล', v: '22 ก.ย. 69' }],
      formats: [{ platform: 'instagram', key: 'carousel', label: 'IG อัลบั้มรีวิว', suggest: 2000 }],
      needs: { measurements: true, province: true, video: false }, fee: 1500, category: 'แฟชั่น',
      brief: '', questions: [], acceptQuestions: [], registered: 96, applications: [], posts: [],
    },
  ];

  // ---------- ผู้ใช้ (MyProfile + myUserVerify + welcomeProgress) ----------
  const USER = {
    name: 'มณีรัตน์ ใจดี', username: 'Tarmjaipa', avatar: 'assets/ph01.jpg',
    tel: '0891234567', email: 'maneerat@email.com',
    address: { name: 'มณีรัตน์ ใจดี', tel: '0891234567', address: '99/12 คอนโดลุมพินี ซ.สุขุมวิท 77', zipcode: '10250', subDistrict: 'สวนหลวง', district: 'สวนหลวง', province: 'กรุงเทพมหานคร' },
    socials: [
      { type: 'instagram', name: 'Instagram', handle: 'mae.review', url: 'https://instagram.com/mae.review', followers: 24800, connected: true, insight: 3 },
      { type: 'tiktok', name: 'TikTok', handle: 'mae.review', url: 'https://tiktok.com/@mae.review', followers: 86200, connected: true, insight: 1 },
      { type: 'facebook', name: 'Facebook', handle: '', url: '', followers: 0, connected: false, insight: 0 },
      { type: 'youtube', name: 'YouTube', handle: 'maereview', url: 'https://youtube.com/@maereview', followers: 12400, connected: true, insight: 0 },
      { type: 'x', name: 'X', handle: '', url: '', followers: 0, connected: false, insight: 0 },
      { type: 'lemon8', name: 'Lemon8', handle: '', url: '', followers: 0, connected: false, insight: 0 },
    ],
    categories: ['แฟชั่น', 'คาเฟ่', 'ท่องเที่ยว'],
    starPoints: 1250, campaignCount: 15,
  };

  // ---------- ขั้นทั้ง 14 (timeline ของแผงควบคุม) → state ที่ต้องตั้ง ----------
  const STEPS = [
    { n: 1, phase: 'สมัคร', t: 'เห็นงาน · เปิดหน้ากิจกรรม', set: { campaign: 'register', review: 'none', screen: 'campaign' } },
    { n: 2, phase: 'สมัคร', t: 'กดสมัคร · ผ่านด่าน (ล็อกอิน / ค้างรีวิว / 3 ขั้น / 100%)', set: { campaign: 'register', review: 'none', screen: 'campaign', hint: 'กดปุ่มแดงแล้วดูว่าโดนด่านไหน — ปรับ flag ผู้ใช้ทางขวา' } },
    { n: 3, phase: 'สมัคร', t: 'กรอกฟอร์มสมัคร', set: { campaign: 'register', review: 'none', screen: 'register', user: { welcome: [true, true, true], percent: 100, reviewStatus: 'none', punishment: 'none' } } },
    { n: 4, phase: 'สมัคร', t: 'ลงทะเบียนสำเร็จ (ชวน KYC ถ้ายังไม่ยืนยัน)', set: { campaign: 'registered', review: 'none', screen: 'campaign', dialog: 'registerSuccess' } },
    { n: 5, phase: 'คัดเลือก', t: 'รอแบรนด์เลือก', set: { campaign: 'registered', review: 'none', screen: 'campaign' } },
    { n: 6, phase: 'คัดเลือก', t: 'ได้รับเลือก → หน้าตอบรับ', set: { campaign: 'waitingAcceptQuota', review: 'none', screen: 'accept' } },
    { n: 7, phase: 'คัดเลือก', t: 'ตอบรับแล้ว · บังคับ KYC ถ้ายังไม่ยืนยัน', set: { campaign: 'forceVerifyUser', review: 'forceVerifyUser', screen: 'campaign', user: { verify: 'none' } } },
    { n: 8, phase: 'ทำงาน', t: 'รอของ / คูปอง', set: { campaign: 'acceptedQuota', review: 'notOpenDraft', order: 'shipping', screen: 'campaign', user: { verify: 'approved' } } },
    { n: 9, phase: 'ทำงาน', t: 'อ่านบรีฟ "รายละเอียดการรีวิว"', set: { campaign: 'acceptedQuota', review: 'waitingDraft', order: 'delivered', screen: 'brief', user: { verify: 'approved' } } },
    { n: 10, phase: 'ทำงาน', t: 'สร้างดราฟต์รีวิว', set: { campaign: 'acceptedQuota', review: 'waitingDraft', order: 'delivered', screen: 'draft', briefRead: true, user: { verify: 'approved' } } },
    { n: 11, phase: 'ทำงาน', t: 'รอผลตรวจ → แก้ตามผลตรวจ', set: { campaign: 'acceptedQuota', review: 'rejectDraft', order: 'delivered', screen: 'verdict', briefRead: true, user: { verify: 'approved' } } },
    { n: 12, phase: 'ทำงาน', t: 'ดราฟต์ผ่าน → โพสต์จริง → ส่งลิงก์', set: { campaign: 'acceptedQuota', review: 'waitingReview', order: 'delivered', screen: 'link', briefRead: true, user: { verify: 'approved' } } },
    { n: 13, phase: 'จบงาน', t: 'เสร็จสิ้นการส่งรีวิว', set: { campaign: 'acceptedQuota', review: 'reviewed', order: 'delivered', screen: 'campaign', reviewTab: true, briefRead: true, user: { verify: 'approved' } } },
    { n: 14, phase: 'จบงาน', t: 'ประวัติในแท็บ "กิจกรรม"', set: { campaign: 'acceptedQuota', review: 'reviewed', order: 'delivered', screen: 'myCampaigns', briefRead: true, user: { verify: 'approved' } } },
  ];

  // ---------- flow ใหม่: ขั้นที่แทรก StarCard (จับคู่กับ 14 ขั้นเดิม) ----------
  const NEW_STEPS = [
    { n: 1, phase: 'สมัคร', t: 'เห็นงาน · หน้าเดิม (บอกระดับใต้นาฬิกา)', set: { campaign: 'register', review: 'none', screen: 'campaign' } },
    { n: 2, phase: 'สมัคร', t: 'แทรก: กรอกข้อมูล Star Profile ที่ยังขาด (การ์ด · เรท · ตามงาน · ยินยอม)', set: { campaign: 'register', review: 'none', screen: 'fillProfile', user: { isLogin: true, reviewStatus: 'none', punishment: 'none' } } },
    { n: 2.5, phase: 'สมัคร', t: 'การ์ดเกิด (โชว์ครั้งแรกครั้งเดียว)', set: { campaign: 'register', review: 'none', screen: 'cardReveal', profile: { socials: true, categories: true, about: true } } },
    { n: 3, phase: 'สมัคร', t: 'ฟอร์มสมัครเดิม (ไม่แก้)', set: { campaign: 'register', review: 'none', screen: 'register', profile: { socials: true, categories: true, about: true, rate: true, consent: true }, user: { consent: true } } },
    { n: 4, phase: 'สมัคร', t: 'dialog ลงทะเบียนสำเร็จเดิม → ชวน KYC (เหมือนเดิม)', set: { campaign: 'registered', review: 'none', screen: 'campaign', dialog: 'registerSuccess', user: { verify: 'none' } } },
    { n: 5, phase: 'คัดเลือก', t: 'รอแบรนด์เลือก (เหมือนเดิม)', set: { campaign: 'registered', review: 'none', screen: 'campaign', user: { verify: 'approved' } } },
    { n: 6, phase: 'คัดเลือก', t: 'แทรก: กรอกที่อยู่ · รอบแก้ · ยืนยันว่าง (ถ้ายังไม่มี) → หน้าตอบรับเดิม', set: { campaign: 'waitingAcceptQuota', review: 'none', screen: 'fillAccept', user: { verify: 'approved' } } },
    { n: 6.5, phase: 'คัดเลือก', t: 'หน้าตอบรับเดิม (ที่อยู่เติมให้)', set: { campaign: 'waitingAcceptQuota', review: 'none', screen: 'accept', profile: { address: true, draftRounds: true }, user: { verify: 'approved' } } },
    { n: 8, phase: 'ทำงาน', t: 'รอของ / คูปอง (เหมือนเดิม)', set: { campaign: 'acceptedQuota', review: 'notOpenDraft', order: 'shipping', screen: 'campaign', user: { verify: 'approved' } } },
    { n: 10, phase: 'ทำงาน', t: 'สร้างดราฟต์ (เหมือนเดิม)', set: { campaign: 'acceptedQuota', review: 'waitingDraft', order: 'delivered', screen: 'draft', briefRead: true, user: { verify: 'approved' } } },
    { n: 12, phase: 'ทำงาน', t: 'ส่งลิงก์รีวิว (เหมือนเดิม)', set: { campaign: 'acceptedQuota', review: 'waitingReview', order: 'delivered', screen: 'link', briefRead: true, user: { verify: 'approved' } } },
    { n: 13, phase: 'จบงาน', t: 'ส่งลิงก์แล้ว (เหมือนเดิม · dialog สำเร็จเดิม)', set: { campaign: 'acceptedQuota', review: 'reviewed', order: 'delivered', screen: 'campaign', reviewTab: true, dialog: 'linkSuccess', briefRead: true, user: { verify: 'approved' } } },
  ];

  // ---------- ข้อมูลใน Star Profile: ใครใช้ · ขั้นไหนถาม ----------
  const PROFILE_FIELDS = [
    { key: 'socials', label: 'โซเชียล ≥1 ช่อง + ยอดฟอล', step: '2 สร้างการ์ด', level: 1 },
    { key: 'categories', label: 'หมวดที่สนใจ', step: '2 สร้างการ์ด', level: 1 },
    { key: 'about', label: 'แนะนำตัว 1 บรรทัด', step: '2 สร้างการ์ด', level: 1 },
    { key: 'rate', label: 'เรทต่อรูปแบบคอนเทนต์ (ทุกช่องที่เชื่อม)', step: '3 ยื่นด้วยการ์ด', level: 2 },
    { key: 'insight', label: 'ข้อมูลผู้ติดตาม (แนบภาพสถิติ 3 หมวด)', step: '3 สมัคร (ไม่บังคับ)', level: 0 },
    { key: 'address', label: 'ที่อยู่รับของ + เบอร์', step: '6 ตอบรับ', level: 3 },
    { key: 'draftRounds', label: 'แก้งานได้กี่รอบ', step: '6 ตอบรับ', level: 3 },
    { key: 'availability', label: 'วัน/เวลาว่างรับงาน', step: '3 สมัคร (แบรนด์ใช้คัดคน)', level: 2 },
    { key: 'bank', label: 'ธนาคาร + เลขบัญชี', step: '6 ตอบรับ', level: 3 },
    { key: 'measurements', label: 'สัดส่วน 6 ค่า', step: '3 เฉพาะงานแฟชั่น', level: 0 },
    { key: 'province', label: 'จังหวัดที่รับงาน', step: '3 เฉพาะงานลงพื้นที่', level: 0 },
  ];

  const NEW_PRESETS = [
    { key: 'n-empty', label: 'ใหม่ · ยังไม่มีอะไรเลย (ประตู A มาหางาน)', set: { flow: 'new', profile: { socials: false, categories: false, about: false, rate: false, consent: false, address: false, draftRounds: false, availability: false, bank: false, measurements: false, province: false, video: false }, user: { isLogin: true, verify: 'none', punishment: 'none', reviewStatus: 'none' }, campaign: 'register', review: 'none', screen: 'campaign' } },
    { key: 'n-card', label: 'ใหม่ · มีการ์ดแล้ว (ระดับ 1) ยังไม่ KYC', set: { flow: 'new', profile: { socials: true, categories: true, about: true, rate: false, consent: false, address: false, draftRounds: false, availability: false, bank: false, measurements: false, province: false, video: false }, user: { isLogin: true, verify: 'none' }, campaign: 'register', review: 'none', screen: 'campaign' } },
    { key: 'n-apply', label: 'ใหม่ · สมัครได้ (ระดับ 2) เคยสมัครมาแล้ว', set: { flow: 'new', profile: { socials: true, categories: true, about: true, rate: true, consent: true, address: false, draftRounds: false, availability: false, bank: false, measurements: false, province: true, video: true }, user: { isLogin: true, verify: 'approved' }, campaign: 'register', review: 'none', screen: 'campaign' } },
    { key: 'n-full', label: 'ใหม่ · มีครบทุกอย่าง (ระดับ 4)', set: { flow: 'new', profile: { socials: true, categories: true, about: true, rate: true, consent: true, address: true, draftRounds: true, availability: true, bank: true, measurements: true, province: true, video: true }, user: { isLogin: true, verify: 'approved' }, campaign: 'register', review: 'none', screen: 'campaign' } },
    { key: 'n-fashion', label: 'ใหม่ · งานแฟชั่น (ขอสัดส่วนตอนสมัคร)', set: { flow: 'new', campaignSlug: 'terminal21-1571', profile: { socials: true, categories: true, about: true, rate: true, consent: true, measurements: false, province: false }, user: { isLogin: true, verify: 'approved' }, campaign: 'register', review: 'none', screen: 'fillProfile' } },
  ];

  // ---------- ฉากสำเร็จรูป ----------
  const PRESETS = [
    { key: 'newUser', label: 'ผู้ใช้ใหม่ ยังไม่ทำอะไร', set: { user: { isLogin: true, welcome: [false, false, false], percent: 0, verify: 'none', punishment: 'none', reviewStatus: 'none' }, campaign: 'register', review: 'none', screen: 'home' } },
    { key: 'guest', label: 'ยังไม่ล็อกอิน', set: { user: { isLogin: false }, campaign: 'register', review: 'none', screen: 'campaign' } },
    { key: 'star70', label: 'STAR ทำ 3 ขั้นแล้ว แต่โปรไฟล์ 67%', set: { user: { isLogin: true, welcome: [true, true, true], percent: 67, verify: 'approved', punishment: 'none', reviewStatus: 'none' }, campaign: 'register', review: 'none', screen: 'campaign' } },
    { key: 'star100', label: 'STAR ครบ 100% พร้อมสมัคร', set: { user: { isLogin: true, welcome: [true, true, true], percent: 100, verify: 'approved', punishment: 'none', reviewStatus: 'none' }, campaign: 'register', review: 'none', screen: 'campaign' } },
    { key: 'noKyc100', label: 'ครบ 100% แต่ KYC ยังไม่ผ่าน (รอคนตรวจ)', set: { user: { isLogin: true, welcome: [true, true, false], percent: 100, verify: 'waiting_approve' }, campaign: 'register', review: 'none', screen: 'campaign' } },
    { key: 'pendingReview', label: 'ค้างส่งรีวิวงานเก่า (โดนบล็อก)', set: { user: { isLogin: true, welcome: [true, true, true], percent: 100, verify: 'approved', reviewStatus: 'reviewPending', punishment: 'warn' }, campaign: 'register', review: 'none', screen: 'campaign' } },
    { key: 'banned', label: 'ถูกแบน (ไม่ส่งรีวิว)', set: { user: { isLogin: true, welcome: [true, true, true], percent: 100, verify: 'approved', reviewStatus: 'reviewPending', punishment: 'banned' }, campaign: 'register', review: 'none', screen: 'campaign' } },
    { key: 'selected', label: 'ได้รับเลือก รอตอบรับ', set: { user: { isLogin: true, welcome: [true, true, true], percent: 100, verify: 'approved', punishment: 'none', reviewStatus: 'none' }, campaign: 'waitingAcceptQuota', review: 'none', quota: 'primary', screen: 'campaign' } },
    { key: 'backup', label: 'ได้เป็นตัวสำรอง', set: { campaign: 'waitingAcceptQuota', review: 'none', quota: 'backup', screen: 'accept' } },
    { key: 'working', label: 'ตอบรับแล้ว ของกำลังส่ง', set: { user: { verify: 'approved' }, campaign: 'acceptedQuota', review: 'notOpenDraft', order: 'shipping', screen: 'campaign' } },
    { key: 'draftTime', label: 'ถึงเวลาส่งดราฟต์', set: { user: { verify: 'approved' }, campaign: 'acceptedQuota', review: 'waitingDraft', order: 'delivered', screen: 'campaign', reviewTab: true } },
    { key: 'draftRejected', label: 'ดราฟต์ไม่ผ่าน ต้องแก้', set: { user: { verify: 'approved' }, campaign: 'acceptedQuota', review: 'rejectDraft', order: 'delivered', screen: 'campaign', reviewTab: true, briefRead: true } },
    { key: 'linkTime', label: 'ดราฟต์ผ่าน ถึงเวลาส่งลิงก์', set: { user: { verify: 'approved' }, campaign: 'acceptedQuota', review: 'waitingReview', order: 'delivered', screen: 'campaign', reviewTab: true, briefRead: true } },
    { key: 'done', label: 'ส่งรีวิวแล้ว เสร็จสิ้น', set: { user: { verify: 'approved' }, campaign: 'acceptedQuota', review: 'reviewed', order: 'delivered', screen: 'campaign', reviewTab: true, briefRead: true } },
    { key: 'missedDraft', label: 'พลาดเส้นตายดราฟต์', set: { user: { verify: 'approved' }, campaign: 'acceptedQuota', review: 'expireDraft', order: 'delivered', screen: 'campaign', reviewTab: true } },
    { key: 'lost', label: 'ไม่ได้รับเลือก', set: { campaign: 'awardAnnouncement', review: 'none', screen: 'campaign', won: false } },
  ];

  const SOCIAL_META = {
    instagram: { name: 'Instagram', color: '#E1306C', icon: 'instagram-logo' },
    tiktok: { name: 'TikTok', color: '#010101', icon: 'tiktok-logo' },
    facebook: { name: 'Facebook', color: '#1877F2', icon: 'facebook-logo' },
    youtube: { name: 'YouTube', color: '#FF0000', icon: 'youtube-logo' },
    x: { name: 'X', color: '#000000', icon: 'x-logo' },
    lemon8: { name: 'Lemon8', color: '#FFD400', icon: 'sparkle' },
  };

  return { NEW_STEPS, PROFILE_FIELDS, NEW_PRESETS, CAMPAIGN_STATES, ORDER_STATUSES, REVIEW_STATES, VERIFY_STATUSES, PUNISHMENTS, REVIEW_STATUSES, QUOTA_TYPES, CAMPAIGNS, USER, STEPS, PRESETS, SOCIAL_META };
})();
