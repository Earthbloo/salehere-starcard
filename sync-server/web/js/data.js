// แหล่งข้อมูลของผัง (เว็บ) — โปรไฟล์ของเจ้าของการ์ดจาก `doc.owner` (= model/SpecData.kt · Profile.kt · MockData.kt)
//
// การ์ดอ่านข้อมูลเจ้าของผ่านชุดเดียวกับแอป: `owner.values` (ข้อความที่พิมพ์) · `owner.list` (รายการชิป) ·
// `owner.intake` (ฟอร์ม: ช่องทาง เรต เวลา) · ตระกูลที่ยังไม่มีข้อมูลยืมชุดตัวอย่าง (`Mock.creator`) มาวาด เหมือนแอป
// รูป: ช่องรูปของชิ้น (`doc.photos`) → รูปครีเอเตอร์/โปรไฟล์ (ช่อง 1–3) → คลังรูป → รูปผลงาน → รูปตั้งต้นของระบบ

import { SpecItem } from './spec-solver.js'
import { swiftDouble } from './spec-model.js'

// MARK: - ตัวเลข (= Fmt)

export const Fmt = {
  compact(n) {
    const trim = (v, s) => (v >= 100 ? `${Math.round(v)}${s}` : `${v.toFixed(1)}${s}`)
    return n >= 1e6 ? trim(n / 1e6, 'M') : n >= 1e3 ? trim(n / 1e3, 'K') : String(n)
  },
  baht(n) { return Math.round(n).toLocaleString('en-US') },
  pct(v) { const s = v.toFixed(1); return (s.endsWith('.0') ? s.slice(0, -2) : s) + '%' },
  f(v, d = 1) { return v.toFixed(d) },
}

// MARK: - ช่องทาง · รูปแบบงาน

export const SOCIAL = {
  instagram: { name: 'Instagram', short: 'IG', tint: '#E85C9E', order: 0 },
  tiktok: { name: 'TikTok', short: 'TikTok', tint: '#33F0EB', order: 1 },
  youtube: { name: 'YouTube', short: 'YouTube', tint: '#FF524D', order: 3 },
  facebook: { name: 'Facebook', short: 'FB', tint: '#5C8FFA', order: 2 },
  lemon8: { name: 'Lemon8', short: 'Lemon8', tint: '#FFD640', order: 4 },
  x: { name: 'X (Twitter)', short: 'X', tint: '#D9D9E0', order: 5 },
}
const SOCIAL_ORDER = ['instagram', 'tiktok', 'youtube', 'facebook', 'lemon8', 'x']
const FORMATS = {
  instagram: { post: ['ภาพลงฟีด (1–3 ภาพ)', 'photo'], carousel: ['อัลบั้มรีวิว (4–10 ภาพ)', 'photo'], reels: ['Reels', 'shortVideo'], story: ['Story (ชุด 3 สไลด์)', 'photo'], live: ['IG Live', 'longVideo'] },
  tiktok: { short: ['คลิปสั้น (ไม่เกิน 60 วิ)', 'shortVideo'], long: ['คลิปยาว (1–3 นาที)', 'longVideo'], series: ['ซีรีส์ 3 คลิปต่อเนื่อง', 'longVideo'], live: ['TikTok LIVE (1 ชม.)', 'longVideo'] },
  facebook: { post: ['โพสต์ภาพ + แคปชัน', 'photo'], album: ['อัลบั้มรีวิว', 'photo'], reels: ['Facebook Reels', 'shortVideo'], video: ['วิดีโอยาว (3 นาทีขึ้นไป)', 'longVideo'], live: ['Facebook Live', 'longVideo'] },
  youtube: { shorts: ['YouTube Shorts', 'shortVideo'], integrated: ['แทรกในคลิป (60–90 วิ)', 'longVideo'], dedicated: ['คลิปรีวิวเต็ม (Dedicated)', 'longVideo'] },
  lemon8: { photo: ['โพสต์ภาพ (Photo Set)', 'photo'], review: ['รีวิวยาว + แท็กสินค้า', 'seeding'] },
  x: { post: ['โพสต์ + ภาพ', 'photo'], thread: ['เธรดรีวิว (3 โพสต์ขึ้นไป)', 'seeding'] },
}
const UNIT = { photo: 'ชิ้น', shortVideo: 'คลิป', longVideo: 'คลิป', seeding: 'ชุด' }

/** handle จากลิงก์โปรไฟล์ (= `SocialType.handle(from:)`) */
function handleFrom(type, link) {
  let s = (link || '').trim()
  if (!s) return ''
  if (!/^https?:\/\//i.test(s)) s = 'https://' + s
  let u
  try { u = new URL(s) } catch { return '' }
  const parts = u.pathname.split('/').filter((p) => p && p !== '/')
  if (!parts.length) return ''
  let h = parts[0]
  if ((h === 'channel' || h === 'c') && parts.length > 1) h = parts[1]
  if (type === 'lemon8') { const at = [...parts].reverse().find((p) => p.startsWith('@')); if (at) h = at }
  return h.startsWith('@') ? h.slice(1) : h
}

// MARK: - ชุดตัวอย่าง (= Mock.creator)

const social = (type, handle, followerCount, avgViewCount, syncedAgo, engagementRate, source = 'connected') =>
  ({ type, handle, followerCount, avgViewCount, syncedAgo, engagementRate, source })
const work = (brand, ep, campaign, platform, format, views, engagementRate, photo, saves, shares, likes, comments, viralTag) =>
  ({ brand, ep, campaign, platform, format, views, engagementRate, photo, saves, shares, likes, comments, viralTag, cover: null })

export const MOCK = {
  name: 'นิรา ภัทรวดี', handle: 'nira.beauty', tagline: 'Beauty & Skincare Creator', location: 'กรุงเทพมหานคร',
  about: 'รีวิวสกินแคร์และเมคอัพแบบตรงไปตรงมา เน้นผิวแพ้ง่าย ถ่ายเองตัดเองทุกคลิป',
  verified: true,
  socials: [
    social('instagram', '@nira.beauty', 184000, 92000, '2 ชม.', 4.7),
    social('tiktok', '@nirabeauty', 320500, 128000, '2 ชม.', 8.1),
    social('youtube', '@niraskin', 41200, 22400, '5 ชม.', 4.6),
  ],
  rates: [
    { id: 'tiktok.shortVideo', label: 'TikTok Video', price: 35000, unit: 'คลิป', format: 'shortVideo', platform: 'tiktok' },
    { id: 'instagram.shortVideo', label: 'IG Reel', price: 25000, unit: 'คลิป', format: 'shortVideo', platform: 'instagram' },
    { id: 'instagram.seeding', label: 'IG Story x3', price: 12000, unit: 'ชุด', format: 'seeding', platform: 'instagram' },
    { id: 'instagram.photo', label: 'รีวิวลงบล็อก', price: 18000, unit: 'ชิ้น', format: 'photo', platform: 'instagram' },
  ],
  audience: {
    female: 78, male: 20, other: 2,
    ages: [['18–24', 27], ['25–34', 41], ['35–44', 22], ['45+', 10]].map(([label, share]) => ({ label, share })),
    places: [['กรุงเทพฯ', 34], ['ชลบุรี', 9], ['เชียงใหม่', 7], ['ขอนแก่น', 5]].map(([name, share]) => ({ name, share })),
    reach: { platform: 'instagram', window: '30 วัน', accounts: 184200, delta: 14.4, newShare: 93.4 },
  },
  track: {
    brands: [
      { name: 'Sivanna Colors', logo: 'https://img.salehere.co.th/p/300x0/2025/05/07/fe0pah3cmv3g.jpg', industry: 'Cosmetics' },
      { name: 'Scotch', logo: 'https://img.salehere.co.th/p/300x0/2023/12/06/yy7womguuk9w.jpg', industry: 'Supplement' },
      { name: 'BioActive+', logo: 'https://img.salehere.co.th/p/300x0/2019/12/20/oosmvnoxfb8m.jpg', industry: 'Supplement' },
      { name: 'Cathy Doll', logo: 'https://cathydoll.me/cdn/shop/files/New_CD_LOGO_2018.png?v=1669460778&width=600', industry: 'Skincare' },
      { name: 'Srichand', logo: 'https://srichand.co.th/wp-content/uploads/2025/12/square-big-logo.jpg', industry: 'Cosmetics' },
      { name: 'Mistine', logo: 'https://www.mistine.co.th/pic/logo.png', industry: 'Cosmetics' },
    ],
    works: [
      work('Sivanna Colors', 'EP.1335', 'Ballet Dream', 'tiktok', 'คลิปยาว', 1240000, 6.8, 0, 42600, 18900, 84200, 1930, '1M+ Views'),
      work('Cathy Doll', 'EP.1206', 'Glow Serum Launch', 'instagram', 'Reel', 820000, 7.4, 4, 31200, 9400, 52600, 1240, 'High Conversion'),
      work('Srichand', 'EP.1189', 'Oil Control Challenge', 'youtube', 'Short', 615000, 5.9, 5, 18700, 6100, 31800, 760, null),
      work('Mistine', 'EP.1142', 'Sunscreen Everyday', 'tiktok', 'คลิปสั้น', 486000, 6.2, 6, 14300, 5400, 27900, 640, null),
      work('Scotch', 'EP.1098', 'Collagen 30 Days', 'instagram', 'Reel', 352000, 8.1, 7, 21500, 4200, 24100, 1080, 'High Save Rate'),
    ],
  },
}

// MARK: - โปรไฟล์ (= Profile)

const PLACEHOLDER = {
  name: 'ชื่อของคุณ', nickname: 'ชื่อเล่น', tagline: 'สายงานของคุณ', about: 'แนะนำตัวสั้น ๆ ให้แบรนด์รู้จัก', quote: 'ประโยคที่อยากบอกแบรนด์',
  handle: 'yourname', contactName: 'ชื่อผู้รับงาน', role: 'ติดต่อโดยตรง', phone: '08x-xxx-xxxx', email: 'you@email.com', lineId: '@lineid',
  workArea: 'จังหวัด / เมืองที่รับงาน', weight: '— กก.', height: '— ซม.', bust: '— นิ้ว', waist: '— นิ้ว', hips: '— นิ้ว', shoe: '— EU',
  note: 'แตะเพื่อพิมพ์ข้อความ',
}
const FIELDS = new Set([...Object.keys(PLACEHOLDER), 'categories', 'rateLabels', 'ratePrices'])
const NOTE_PLACEHOLDER = 'แตะเพื่อพิมพ์ข้อความ'

export class Profile {
  /** @param owner `doc.owner` · @param notes `doc.notes` (คีย์ = uuid ของชิ้น [#ช่อง]) */
  constructor(owner = {}, notes = {}) {
    this.values = owner.values || {}
    this.list = owner.list || {}
    this.intake = owner.intake || null
    this.notes = Object.fromEntries(Object.entries(notes || {}).map(([k, v]) => [k.toLowerCase(), v]))
    this.build()
  }

  stored(f) { const v = this.values[f]; return v ? v : null }

  derived(f) {
    const d = this.intake
    if (!d) return null
    switch (f) {
      case 'tagline': { const c = this.items('categories'); return c.length ? c.join(' · ') : null }
      case 'handle': return this.enabledSocials().map((e) => handleFrom(e.type, e.link)).find((h) => h) || null
      case 'contactName': return this.stored('name')
      case 'nickname': { const n = this.stored('name'); if (!n) return null; return n.split(' ').find((p) => p) || n }
      case 'workArea': return (d.availability?.provinces || [])[0] ?? null
      case 'note': return NOTE_PLACEHOLDER
      default: return null
    }
  }

  fallback(f) { return this.derived(f) ?? PLACEHOLDER[f] ?? '' }

  text(f, i = null) {
    if (i != null) { const it = this.items(f); return i >= 0 && i < it.length ? it[i] : '' }
    // สายงานใต้ชื่อไม่มีที่กรอก — สร้างจากสายที่ใช่ของ Star Profile เสมอ (= iOS `Profile.text`)
    if (f === 'tagline') return this.fallback(f)
    const v = this.values[f]
    if (v) return v
    return this.fallback(f)
  }

  items(f) {
    if (this.intake && f === 'rateLabels') return this.rateRows().map((r) => r.label)
    if (this.intake && f === 'ratePrices') return this.rateRows().map((r) => (r.price > 0 ? String(r.price) : ''))
    return this.list[f] ?? (this.intake && f === 'categories' ? this.intake.interests || [] : [])
  }

  note(widget, index, preset) {
    const key = widget ? (index != null ? `${widget}#${index}` : widget).toLowerCase() : null
    const v = key != null ? this.notes[key] : undefined
    if (v === undefined) return preset ? preset : NOTE_PLACEHOLDER
    return v
  }

  enabledSocials() { return (this.intake?.socials || []).filter((s) => s.enabled !== false) }

  rateRows() {
    const d = this.intake
    if (!d) return []
    return (d.rates || []).map((c) => {
      const spec = FORMATS[c.platform]?.[c.formatKey]
      const format = spec ? spec[1] : 'photo'
      const label = c.label ? c.label : `${SOCIAL[c.platform]?.short ?? c.platform} ${spec ? spec[0] : c.formatKey}`
      return { id: `${c.platform}.${c.formatKey}`, label, price: c.price || 0, unit: UNIT[format], format, platform: c.platform }
    })
  }

  /** โปรไฟล์ที่ widget อ่าน (= `buildCreator`) + ตระกูลที่ยืมตัวอย่าง */
  build() {
    const d = this.intake
    if (!d) {
      this.sampleFamilies = new Set(['followers', 'rate', 'audience', 'brand', 'verified'])
      this.creator = { ...MOCK, categories: this.items('categories') }
      return
    }
    const socials = this.enabledSocials().filter((e) => (e.followers || 0) > 0)
      .sort((a, b) => (SOCIAL[a.type]?.order ?? 9) - (SOCIAL[b.type]?.order ?? 9))
      .map((e) => social(e.type, '@' + handleFrom(e.type, e.link), e.followers, 0,
        e.source && e.source !== 'manual' ? 'เชื่อมบัญชีแล้ว' : 'กรอกเอง', 0, e.source || 'manual'))
    const sample = new Set(['audience', 'brand', 'verified'])
    const rows = this.rateRows()
    if (!socials.length) sample.add('followers')
    if (!rows.length) sample.add('rate')
    this.sampleFamilies = sample
    this.creator = {
      verified: socials.length > 0 && socials.every((s) => s.source !== 'manual'),
      socials: socials.length ? socials : MOCK.socials,
      rates: rows.length ? rows : MOCK.rates,
      audience: MOCK.audience,
      track: MOCK.track,
    }
  }
}

// MARK: - ข้อความของช่อง

function slotParts(slot) {
  const [field, idx] = slot.split('#')
  const index = idx !== undefined && /^-?\d+$/.test(idx) ? Number(idx) : null
  return { field, index }
}

/** ขั้นขนาดของช่อง (= `WidgetTextSize.factor`) */
const FACES = new Set(['noto', 'mitr'])

/**
 * แหล่งข้อมูลของชิ้นหนึ่ง (= `AndroidSpecData`)
 * ctx = { profile, item (doc item), sample, inkLight, surface, duo, stamped, cutout, kitDark, verified }
 */
export class WebSpecData {
  constructor(ctx) {
    Object.assign(this, ctx)
    this.p = ctx.profile
    this.widget = ctx.item?.id ? String(ctx.item.id) : null
    this.kit = ctx.item?.kit || {}
    this.border = !!ctx.item?.border
  }

  lacks(f) { return this.p.sampleFamilies.has(f) }
  get socials() { return this.lacks('followers') ? MOCK.socials : this.p.creator.socials }
  get rates() { return this.lacks('rate') ? MOCK.rates : this.p.creator.rates }
  get audience() { return this.lacks('audience') ? MOCK.audience : this.p.creator.audience }
  track() { return MOCK.track }

  text(slot, preset) {
    if (slot.startsWith('stat:')) {
      const a = this.audience
      const p = this.p
      switch (slot.slice(5)) {
        case 'phoneFmt': {
          const v = p.text('phone')
          if (!v) return this.sample ? '081-234-5678' : ''
          const d = v.replace(/\D/g, '')
          return d.length === 10 ? `${d.slice(0, 3)}-${d.slice(3, 6)}-${d.slice(-4)}` : v
        }
        case 'site': return this.sample ? 'nirabeauty.co' : ''
        case 'lineFlow': return p.text('lineId') || (this.sample ? '@nirabeauty' : '')
        case 'totalFollowers': return Fmt.compact(this.socials.reduce((s, x) => s + x.followerCount, 0))
        case 'avgViews': return Fmt.compact(Math.trunc(this.socials.reduce((s, x) => s + x.avgViewCount, 0) / Math.max(1, this.socials.length)))
        case 'brandCount': return String(this.track().brands.length)
        case 'workCount': return String(this.track().works.length)
        case 'socialCount': return String(this.socials.length)
        // ประเภทครีเอเตอร์ (API `creatorType`) — ยังไม่ตอบ = ว่าง (= iOS)
        case 'creatorKind': { const k = p.intake?.kind; return k === 'creator' ? 'บุคคล' : k === 'page' ? 'เพจ' : (this.sample ? 'บุคคล' : '') }
        case 'rateCount': return String(this.rates.filter((r) => r.price > 0).length)
        case 'cardURL': return 'https://salehere.co.th/star/' + p.text('handle')
        case 'year': return '2026'
        case 'placeCount': return String(a.places.length)
        // ยังไม่มีการเข้าถึง (0) = ว่าง — ผังซ่อนบล็อกด้วย `has:stat:reach` (= iOS)
        case 'reach': return a.reach.accounts > 0 ? Fmt.compact(a.reach.accounts) : ''
        case 'reachRaw': return a.reach.accounts > 0 ? String(a.reach.accounts) : ''
        case 'reachDelta': return a.reach.accounts > 0 ? (a.reach.delta >= 0 ? '+' : '') + Fmt.pct(a.reach.delta) : ''
        case 'reachNew': return a.reach.accounts > 0 ? Fmt.pct(a.reach.newShare) : ''
        case 'reachWindow': return a.reach.window
        case 'reachPlatform': return SOCIAL[a.reach.platform]?.name ?? ''
        case 'reachIcon': return 'sh:' + a.reach.platform
        default: return ''
      }
    }
    if (slot.startsWith('count:')) return String(this.list(slot.slice(6)).length)
    const { field, index } = slotParts(slot)
    if (!FIELDS.has(field)) return ''
    if (field === 'about' && this.sample) return this.lacks('intro') ? MOCK.about : this.p.text('about')
    if (field === 'note') return this.p.note(this.widget, index, preset || '')
    return this.p.text(field, index)
  }

  flag(name) {
    switch (name) {
      case 'owner.verified': return !!this.verified || this.p.creator.verified
      case 'sample': return !!this.sample
      case 'ink.light': return !!this.inkLight
      case 'bordered': return this.border
      case 'papered': return this.surface === 'glass' || this.surface === 'dim'
      case 'duo': return !!this.duo
      case 'stamped': return !!this.stamped
      case 'cutout': return !!this.cutout
      case 'kit.dark': return !!this.kitDark
    }
    if (name.startsWith('surface=')) return this.surface === name.slice(8)
    if (name.startsWith('cfg:')) {
      const body = name.slice(4), eq = body.indexOf('=')
      if (eq < 0) return false
      const k = body.slice(0, eq), v = body.slice(eq + 1)
      if (k === 'fill') return (this.kit.fill || 'solid') === v
      if (k === 'corner') return (this.kit.corner || 'round') === v
      return false
    }
    const opts = this.kit.opts || {}
    if (name.startsWith('opt:')) {
      const body = name.slice(4), eq = body.indexOf('=')
      if (eq >= 0) return (opts[body.slice(0, eq)] || '') === body.slice(eq + 1)
      const v = opts[body] || ''
      return v !== '' && v !== '0'
    }
    if (name.startsWith('hidden:')) return (opts.hide || '').split(',').filter(Boolean).includes(name.slice(7))
    return false
  }

  list(name) {
    const I = (id, i, f) => new SpecItem(id, i, f)
    switch (name) {
      case 'categories': return this.p.items('categories').map((c, i) => I(`cat${i}`, i, { text: c }))
      case 'socials': return this.socials.map((s, i) => {
        const t = SOCIAL[s.type]
        return I(s.type, i, {
          platform: s.type, name: t.name, short: t.short, icon: 'sh:' + s.type, tint: t.tint, handle: s.handle,
          followers: Fmt.compact(s.followerCount), followersRaw: String(s.followerCount), followersFull: Fmt.baht(s.followerCount),
          viewsFull: Fmt.baht(s.avgViewCount), views: Fmt.compact(s.avgViewCount), viewsRaw: String(s.avgViewCount),
          engagement: Fmt.f(s.engagementRate, 1) + '%', engagementRaw: swiftDouble(s.engagementRate), synced: s.syncedAgo,
          verified: s.source !== 'manual' ? '1' : '',
        })
      })
      case 'rates': return this.rates.filter((r) => r.price > 0).map((r, i) => I(r.id, i, {
        label: r.label, price: '฿' + Fmt.baht(r.price), priceRaw: String(r.price), unit: r.unit, platform: r.platform,
        platformName: SOCIAL[r.platform]?.name ?? '', platformOrder: String(SOCIAL_ORDER.indexOf(r.platform) < 0 ? 99 : SOCIAL_ORDER.indexOf(r.platform)),
        priceNum: Fmt.baht(r.price), icon: 'sh:' + r.platform, tint: SOCIAL[r.platform]?.tint ?? '', format: r.format,
      }))
      case 'brands': return this.track().brands.map((b, i) => I(b.name, i, { name: b.name, logo: b.logo || '', industry: b.industry }))
      case 'works': {
        const tr = this.track()
        return tr.works.map((w, i) => I(`w${i}`, i, {
          brand: w.brand, ep: w.ep, campaign: w.campaign, platform: w.platform, icon: 'sh:' + w.platform, tint: SOCIAL[w.platform]?.tint ?? '',
          format: w.format, views: Fmt.compact(w.views), viewsRaw: String(w.views), photo: String(4 + i), workPhoto: String(w.photo),
          cover: w.cover || '', saves: Fmt.compact(w.saves), savesRaw: String(w.saves), shares: Fmt.compact(w.shares), sharesRaw: String(w.shares),
          likes: Fmt.compact(w.likes), comments: Fmt.compact(w.comments), engageRaw: String(w.likes + w.comments + w.shares + w.saves),
          engagement: Fmt.f(w.engagementRate, 1) + '%', viralTag: w.viralTag || '',
          brandLogo: tr.brands.find((b) => b.name === w.brand)?.logo || '',
        }))
      }
      case 'body': {
        if (!this.sample) return []
        return [['h', 'ส่วนสูง', '165 cm', '165', 'ซม.', ''], ['w', 'น้ำหนัก', '48 kg', '48', 'กก.', ''],
          ['g', 'รอบอก / เอว / สะโพก', '32 / 25 / 35', '32 / 25 / 35', 'นิ้ว', '1'], ['s', 'ไซซ์รองเท้า', 'EU 38', '38', 'EU', '']]
          .map((c, i) => I(c[0], i, { kind: c[0], label: c[1], value: c[2], num: c[3], unit: c[4], wide: c[5] }))
      }
      case 'avail': return (this.sample ? ['ส–อา 17.00 เป็นต้นไป'] : []).map((t, i) => I(`t${i}`, i, { text: t }))
      case 'areas': {
        const prov = this.p.intake?.availability?.provinces || []
        return (prov.length ? prov : this.sample ? ['กรุงเทพมหานคร', 'นนทบุรี'] : []).map((t, i) => I(`a${i}`, i, { text: t }))
      }
      case 'contacts': {
        const out = []
        for (const [k, v, icon, slot] of [['phone', this.p.text('phone'), 'ph:phone', 'phone'], ['email', this.p.text('email'), 'ph:envelope', 'email'],
          ['line', this.p.text('lineId'), 'sh:line', 'lineId'], ['web', '', 'ph:globe', 'website']]) {
          if (v) out.push(I(k, out.length, { kind: k, value: v, icon, slot }))
        }
        return out
      }
      case 'ages': return this.audience.ages.map((a, i) => I(a.label, i, { label: a.label, share: Fmt.f(a.share, 0) + '%', shareRaw: swiftDouble(a.share) }))
      case 'places': return this.audience.places.map((a, i) => I(a.name, i, { name: a.name, share: Fmt.f(a.share, 0) + '%', shareRaw: swiftDouble(a.share) }))
      case 'gender': {
        const a = this.audience
        return [['หญิง', a.female, '#FF8CBD'], ['ชาย', a.male, '#8299FF'], ['อื่น ๆ', a.other, '#5CE6AD']]
          .map(([label, v, tint], i) => I(label, i, { label, share: Fmt.f(v, 0) + '%', shareRaw: swiftDouble(v), tint }))
      }
      case 'photos': return [0, 1, 2, 3, 4, 5].map((i) => I(`p${i}`, i, { photo: String(4 + i) }))
      default: return []
    }
  }

  font(slot, face, size, weight) {
    let f = { face: FACES.has(face) ? face : 'noto', size, weight }
    if (slot != null) {
      const { field } = slotParts(slot)
      // ช่องที่ผูกข้อมูลจำกัดขนาด 6–160 (ไม่มีการปรับขนาด/ฟอนต์ของผู้ใช้แล้ว)
      if (FIELDS.has(field)) f = { ...f, size: Math.min(Math.max(size, 6), 160) }
    }
    return f
  }
}

// MARK: - รูป

const PHOTO_PROFILE = 'https://img.salehere.co.th/p/1200x0/2025/12/12/profilecreator0jpeg-cjhwjffusbti.jpg'
const PHOTO_WORKS = [
  'https://img.salehere.co.th/p/600x0/2026/07/12/reviewtopic0jpeg-oosenzv18wzj.jpg',
  'https://img.salehere.co.th/p/600x0/2025/09/21/reviewtopic0jpeg-ope9b0rviyjx.jpg',
  'https://img.salehere.co.th/p/600x0/2025/10/15/reviewtopic0jpeg-xqf0qpdhwb6j.jpg',
]
const COUNT = 12
const isProfileSlot = (i) => { const n = ((i % COUNT) + COUNT) % COUNT; return n >= 1 && n <= 3 }
export const sampleURL = (i) => { const n = ((i % COUNT) + COUNT) % COUNT; return n >= 1 && n <= 3 ? PHOTO_PROFILE : PHOTO_WORKS[n % PHOTO_WORKS.length] }

/** รูปของช่อง `slot` ของชิ้น `wid` → {url, fit} (= `WidgetPhoto` · `PhotoStore.uiImage` · `library`)
 *  `mock` = รูป mock ชุดเดียวของทุก platform (GraphQL `mockPhotos`) — มี = ช่องที่ไม่ได้ใส่รูปเองใช้ชุดนี้ */
export function photoFor(doc, slot, wid, imageURL, mock = null) {
  const photos = doc.photos || {}
  const key = Object.keys(photos).find((k) => k.toLowerCase() === `${String(wid).toLowerCase()}#${slot}`)
  const entry = key ? photos[key] : null
  const fit = { dx: entry?.fit?.dx ?? 0, dy: entry?.fit?.dy ?? 0, zoom: entry?.fit?.zoom ?? 1 }
  if (entry?.imageId) return { url: imageURL(entry.imageId), fit }
  if (mock && (mock.creators.length || mock.works.length)) {
    const n = ((slot % COUNT) + COUNT) % COUNT
    if (n >= 1 && n <= 3 && mock.creators.length) return { url: imageURL(mock.creators[(n - 1) % mock.creators.length]), fit }
    if (mock.works.length) return { url: imageURL(mock.works[Math.abs(slot) % mock.works.length]), fit }
    return { url: imageURL(mock.creators[0]), fit }
  }
  const o = doc.owner || {}
  const ids = (a) => (a || []).filter(Boolean)
  if (isProfileSlot(slot)) {
    const creators = ids(o.creatorImageIds)
    if (creators.length) { const n = ((slot % COUNT) + COUNT) % COUNT; return { url: imageURL(creators[Math.max(0, n - 1) % creators.length]), fit } }
    if (o.avatarImageId) return { url: imageURL(o.avatarImageId), fit }
  }
  const lib = ids(o.libraryImageIds)
  if (lib.length) return { url: imageURL(lib[slot % lib.length]), fit }
  const works = ids(o.workImageIds)
  if (works.length) return { url: imageURL(works[slot % works.length]), fit }
  return { url: sampleURL(slot), fit }
}
