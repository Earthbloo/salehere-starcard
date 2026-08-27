import { z } from 'zod'

/**
 * PortfolioDoc — สัญญากลางของ StarCard ใช้ร่วมกันทั้ง web / iOS / Android
 *
 * กฎเหล็ก: schema นี้ต้อง forward-compatible เสมอ เพราะแอปมือถืออัปเดตช้ากว่าเว็บ
 * — block type ที่ไม่รู้จักต้อง parse ผ่านและถูกเก็บ raw ไว้ (ห้าม throw, ห้ามลบตอน save)
 * ดูคำอธิบายเต็มที่ ./portfolio-doc.md
 */

export const SCHEMA_VERSION = 1 as const

// ── Tokens ────────────────────────────────────────────────────────────────
export const paletteToken = z.enum(['coral', 'mint', 'noir', 'sand', 'lavender', 'ocean'])
export const fontPairToken = z.enum(['modern', 'editorial', 'playful', 'minimal'])
export const radiusToken = z.enum(['sm', 'md', 'lg', 'full'])
export const cardStyleToken = z.enum(['solid', 'glass', 'outline'])

export const background = z.discriminatedUnion('kind', [
  z.object({ kind: z.literal('solid'), token: paletteToken }),
  z.object({ kind: z.literal('gradient'), token: z.string() }),
  z.object({ kind: z.literal('image'), mediaId: z.string(), dim: z.number().min(0).max(1).default(0.3) }),
  z.object({ kind: z.literal('glass'), token: paletteToken }),
])

export const theme = z.object({
  palette: paletteToken,
  /** hex เดียวที่ผู้ใช้กำหนดเองได้ — ต้องผ่าน WCAG AA contrast check ตอน publish */
  customAccent: z.string().regex(/^#[0-9a-fA-F]{6}$/).optional(),
  background,
  fontPair: fontPairToken,
  radius: radiusToken,
  cardStyle: cardStyleToken,
})

// ── Grid & spans ──────────────────────────────────────────────────────────
export const span = z.object({ w: z.number().int().min(1).max(4), h: z.number().int().min(1).max(4) })
export type Span = z.infer<typeof span>

export const SPAN_PRESETS = {
  S: { w: 1, h: 1 },
  M: { w: 2, h: 1 },
  L: { w: 2, h: 2 },
  W: { w: 4, h: 1 },
  XL: { w: 4, h: 2 },
  XXL: { w: 4, h: 4 },
} as const satisfies Record<string, Span>

export type SpanPreset = keyof typeof SPAN_PRESETS

/**
 * ลำดับ preset ที่ resize handle จะ snap ผ่าน — ลากออก = เดินหน้าในอาเรย์, ลากเข้า = ถอยหลัง
 * ลำดับนี้คือ single source of truth ของ resize behaviour ทั้ง 3 platform
 */
export const ALLOWED_SPANS = {
  profile: ['XL', 'XXL'],
  statsIG: ['M', 'L'],
  statsTikTok: ['M', 'L'],
  workGallery: ['L', 'XL', 'XXL'],
  brandLogos: ['S', 'M', 'W'],
  rateCard: ['XL'],
  video: ['L', 'XL', 'XXL'],
  testimonial: ['M', 'L', 'W'],
  contact: ['S', 'W'],
  text: ['M', 'W', 'XL'],
} as const satisfies Record<string, readonly SpanPreset[]>

export type KnownBlockType = keyof typeof ALLOWED_SPANS

// ── Blocks ────────────────────────────────────────────────────────────────
const blockBase = {
  id: z.string().min(1),
  span,
  order: z.number().int().min(0),
  style: z.object({ accent: z.string().optional(), cardStyle: cardStyleToken.optional() }).optional(),
}

const mediaId = z.string().min(1)

export const knownBlock = z.discriminatedUnion('type', [
  z.object({ ...blockBase, type: z.literal('profile'), data: z.object({
    name: z.string().max(60), tagline: z.string().max(120).optional(),
    avatarId: mediaId.optional(), location: z.string().max(60).optional(),
  })}),
  z.object({ ...blockBase, type: z.literal('statsIG'), data: z.object({
    followers: z.number().int().nonnegative(), engagementRate: z.number().min(0).max(100).optional(),
    avgReach: z.number().int().nonnegative().optional(), verified: z.boolean().default(false),
  })}),
  z.object({ ...blockBase, type: z.literal('statsTikTok'), data: z.object({
    followers: z.number().int().nonnegative(), avgViews: z.number().int().nonnegative().optional(),
    engagementRate: z.number().min(0).max(100).optional(),
  })}),
  z.object({ ...blockBase, type: z.literal('workGallery'), data: z.object({
    imageIds: z.array(mediaId).max(24), layout: z.enum(['grid', 'carousel']).default('grid'),
  })}),
  z.object({ ...blockBase, type: z.literal('brandLogos'), data: z.object({
    logoIds: z.array(mediaId).max(20),
  })}),
  z.object({ ...blockBase, type: z.literal('rateCard'), data: z.object({
    items: z.array(z.object({ label: z.string().max(60), price: z.number().nonnegative(), unit: z.string().max(20) })).max(10),
    currency: z.string().length(3).default('THB'), note: z.string().max(200).optional(),
  })}),
  z.object({ ...blockBase, type: z.literal('video'), data: z.object({
    provider: z.enum(['yt', 'tiktok', 'ig']), url: z.string().url(), thumbId: mediaId.optional(),
  })}),
  z.object({ ...blockBase, type: z.literal('testimonial'), data: z.object({
    quote: z.string().max(280), author: z.string().max(60), brandLogoId: mediaId.optional(),
  })}),
  z.object({ ...blockBase, type: z.literal('contact'), data: z.object({
    channels: z.array(z.object({ kind: z.enum(['email', 'line', 'phone', 'ig', 'tiktok']), value: z.string().max(120) })).max(6),
  })}),
  z.object({ ...blockBase, type: z.literal('text'), data: z.object({
    /** markdown subset: bold / italic / link เท่านั้น — sanitize ก่อน render ทุก platform */
    markdown: z.string().max(1000),
  })}),
])

/**
 * Block ที่ client เวอร์ชันนี้ไม่รู้จัก
 * เก็บ raw ไว้ครบเพื่อส่งกลับตอน save — ถ้าไม่ทำ ผู้ใช้ที่แก้จากแอปเก่าจะทำ block ใหม่หายหมด
 */
export const unknownBlock = z.object({
  id: z.string().min(1),
  type: z.string(),
  span,
  order: z.number().int().min(0),
})
  .passthrough()
  // ต้องกันไม่ให้ known block ที่ data พังตกมาแมตช์ตรงนี้ ไม่งั้นบั๊กจะกลายร่างเป็น
  // placeholder "อัปเดตแอป" เงียบ ๆ แทนที่จะถูกรายงานว่า doc เสีย
  .refine((b) => !(b.type in ALLOWED_SPANS), {
    message: 'known block type failed its own schema',
  })

export const block = z.union([knownBlock, unknownBlock])

// ── Document ──────────────────────────────────────────────────────────────
export const portfolioDoc = z.object({
  version: z.number().int().positive(),
  handle: z.string().regex(/^[a-z0-9._-]{3,30}$/),
  theme,
  grid: z.object({
    cols: z.literal(4),          // v1 ล็อกไว้ที่ 4 — responsive ทำโดย scale cell ไม่ใช่เพิ่มคอลัมน์
    gap: z.number().min(0).max(32).default(12),
    rowHeight: z.number().min(40).max(200).default(88),
  }),
  blocks: z.array(block).max(40),
})

export type PortfolioDoc = z.infer<typeof portfolioDoc>
export type Block = z.infer<typeof block>

// ── Helpers ───────────────────────────────────────────────────────────────

export function isKnownBlock(b: Block): b is z.infer<typeof knownBlock> {
  return b.type in ALLOWED_SPANS
}

function presetOf(s: Span): SpanPreset | undefined {
  return (Object.keys(SPAN_PRESETS) as SpanPreset[]).find(
    (k) => SPAN_PRESETS[k].w === s.w && SPAN_PRESETS[k].h === s.h,
  )
}

/**
 * preset ถัดไปเมื่อผู้ใช้ลาก resize handle
 * @param dir +1 = ลากออก (ใหญ่ขึ้น), -1 = ลากเข้า
 * @returns span ใหม่ หรือ null ถ้าชนขีดจำกัด (ให้ ghost เด้งกลับ + haptic rigid)
 */
export function nextSpan(type: string, current: Span, dir: 1 | -1): Span | null {
  const allowed = ALLOWED_SPANS[type as KnownBlockType]
  if (!allowed) return null
  const at = allowed.indexOf(presetOf(current) as never)
  // span ที่ไม่ตรง preset ใด (doc จากเวอร์ชันอื่น) → clamp เข้าตัวแรกแทนที่จะ error
  if (at === -1) return SPAN_PRESETS[allowed[0]]
  const next = at + dir
  if (next < 0 || next >= allowed.length) return null
  return SPAN_PRESETS[allowed[next]]
}

/**
 * Parse doc โดยไม่ throw — สำหรับ client ทุกตัว
 * block ที่พังจริง ๆ จะถูกดรอปทิ้งพร้อมรายงาน แทนที่จะทำให้ทั้งหน้าเปิดไม่ได้
 */
export function parseDocLenient(input: unknown): { doc: PortfolioDoc | null; dropped: string[] } {
  const shallow = portfolioDoc.safeParse(input)
  if (shallow.success) return { doc: shallow.data, dropped: [] }

  const raw = input as { blocks?: unknown[] }
  if (!Array.isArray(raw?.blocks)) return { doc: null, dropped: [] }

  const dropped: string[] = []
  const blocks = raw.blocks.filter((b, i) => {
    if (block.safeParse(b).success) return true
    dropped.push((b as { id?: string })?.id ?? `#${i}`)
    return false
  })

  const retry = portfolioDoc.safeParse({ ...raw, blocks })
  return { doc: retry.success ? retry.data : null, dropped }
}
