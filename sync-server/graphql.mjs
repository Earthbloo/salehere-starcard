// Star Card GraphQL — model เดียว ใช้ได้ทั้งแอปและเว็บ (ทดลอง · ดู MODEL.md)
//
// ของมีสองอย่าง: **WidgetSpec** (JSON ผังของ widget หนึ่งชนิด) กับ **StarCard** (การ์ด = หน้า → ชิ้น widget)
// ที่เก็บจริงของการทดลองคือไฟล์ (sync-server/data · shared/WidgetSpecs) — ของจริงเปลี่ยนเป็น DB โดย schema ไม่เปลี่ยน

import { buildSchema, graphql, GraphQLScalarType, Kind } from 'graphql'

export const SDL = /* GraphQL */ `
  "ก้อน JSON อิสระ (ธีม · ตัวเลือกของชิ้น · ผัง widget)"
  scalar JSON

  type Query {
    "การ์ด — ตอนนี้มีใบเดียว (id = main)"
    starCard(id: ID): StarCard
    "ผังของ widget ทุกชนิด"
    widgetSpecs: [WidgetSpec!]!
    widgetSpec(kind: String!): WidgetSpec
    "เปลี่ยนเมื่อไฟล์ผังใดเปลี่ยน — เทียบค่านี้ก่อนโหลดผังทั้งชุดใหม่"
    widgetSpecsVersion: String!
    "รูป mock ชุดเดียวของทุก platform (ทดลอง) — ช่องรูปที่ชิ้นไม่ได้ใส่รูปเองใช้ชุดนี้"
    mockPhotos: MockPhotos!
  }

  """
  กติกาเลือกรูปของช่อง i (เหมือนกันทุก platform):
  1) รูปที่ใส่ในช่องนั้นของชิ้น (StarCard.photos["<widgetId>#i"].imageId)
  2) i % 12 อยู่ใน 1…3 (ช่องรูปครีเอเตอร์) → creators[(i % 12 − 1) % creators.length]
  3) ที่เหลือ → works[i % works.length]
  ไฟล์รูป: GET /api/images/<id>
  """
  type MockPhotos {
    "เปลี่ยนเมื่อชุดรูปเปลี่ยน"
    version: String!
    creators: [String!]!
    works: [String!]!
  }

  type Mutation {
    "เก็บการ์ด · baseRev = rev ที่ผู้เขียนเห็นล่าสุด (ไม่ตรง = มีคนเขียนก่อน → conflict)"
    saveStarCard(card: StarCardInput!, baseRev: Int!, by: String): SaveResult!
  }

  type StarCard {
    id: ID!
    "เลขฉบับ — เพิ่มทุกครั้งที่บันทึก"
    rev: Int!
    "story (หน้าเดียว 540×960) · portfolio (3 หน้า กว้าง 402)"
    format: String!
    name: String
    theme: JSON
    pages: [Page!]!
    "ข้อมูลเจ้าของการ์ด (ชื่อ · ช่องทาง · เรต …) ที่ widget อ่าน"
    owner: JSON
    "ข้อความอิสระต่อชิ้น — คีย์ = id ของชิ้น[#ช่อง]"
    notes: JSON
    "รูปต่อช่องของชิ้น — คีย์ = id ของชิ้น#ช่อง → {imageId, fit}"
    photos: JSON
    backgroundImageId: String
    updatedAt: String
    updatedBy: String
  }

  type Page { items: [Widget!]! }

  "ชิ้น widget หนึ่งชิ้นบนหน้า — kind ชี้ไปที่ WidgetSpec · x/y/w/h เป็นหน่วยออกแบบของหน้า"
  type Widget {
    id: ID!
    kind: String!
    x: Float!
    y: Float!
    w: Float!
    h: Float!
    "glass · dim · pane · clear"
    surface: String
    border: Boolean
    "ตัวเลือกอื่นของชิ้น (ฟอนต์/สี/ขนาดต่อช่อง · ลาย · ชุดห้าสไตล์ …)"
    options: JSON
  }

  type WidgetSpec {
    kind: String!
    "ชื่อในตู้ (ใบจากไฟล์ผังอย่างเดียว)"
    title: String
    category: String
    design: JSON!
    "ไฟล์ผังทั้งไฟล์"
    json: JSON!
  }

  input StarCardInput {
    format: String!
    name: String
    theme: JSON
    pages: [PageInput!]!
    owner: JSON
    notes: JSON
    photos: JSON
    backgroundImageId: String
  }
  input PageInput { items: [WidgetInput!]! }
  input WidgetInput {
    id: ID!
    kind: String!
    x: Float!
    y: Float!
    w: Float!
    h: Float!
    surface: String
    border: Boolean
    options: JSON
  }

  type SaveResult {
    ok: Boolean!
    rev: Int!
    "มีคนบันทึกก่อน — อ่าน starCard ใหม่แล้วลองอีกครั้ง"
    conflict: Boolean!
  }
`

const literal = (ast) => {
  switch (ast.kind) {
    case Kind.STRING: case Kind.BOOLEAN: return ast.value
    case Kind.INT: case Kind.FLOAT: return Number(ast.value)
    case Kind.OBJECT: return Object.fromEntries(ast.fields.map((f) => [f.name.value, literal(f.value)]))
    case Kind.LIST: return ast.values.map(literal)
    default: return null
  }
}
const JSONScalar = new GraphQLScalarType({ name: 'JSON', serialize: (v) => v, parseValue: (v) => v, parseLiteral: literal })

const schema = buildSchema(SDL)
// SDL ประกาศ scalar ได้แค่ชื่อ — ใส่ตัวแปลงค่าให้ JSON ที่นี่
Object.assign(schema.getType('JSON'), { serialize: JSONScalar.serialize, parseValue: JSONScalar.parseValue, parseLiteral: JSONScalar.parseLiteral })

// ชิ้นในเอกสารที่เก็บ = ที่แอปเขียน = Widget: ฟิลด์หลัก 8 ตัว + `options` (19 ต.ค. 2569)
// ไฟล์ก่อนหน้านั้นเก็บตัวเลือกเป็นคีย์แบน — อ่านคีย์ที่ไม่ใช่ฟิลด์หลักทั้งหมดเป็น options ให้ตัวอ่านแปลงต่อ
const CORE = ['id', 'kind', 'x', 'y', 'w', 'h', 'surface', 'border']
const toWidget = (it) => {
  let options = it.options
  if (!options) {
    options = {}
    for (const [k, v] of Object.entries(it)) if (!CORE.includes(k)) options[k] = v
  }
  return { id: it.id, kind: it.kind, x: it.x, y: it.y, w: it.w, h: it.h, surface: it.surface ?? 'glass', border: !!it.border, options }
}
const fromWidget = (w) => {
  const it = { id: w.id, kind: w.kind, x: w.x, y: w.y, w: w.w, h: w.h, surface: w.surface ?? 'glass', border: !!w.border }
  if (w.options && Object.keys(w.options).length) it.options = w.options
  return it
}

/**
 * store = { current() → {rev, doc, by, at} | null, write(doc, baseRev, by) → {rev, conflict}, specs() → {hash, specs},
 *           mockPhotos() → {version, creators, works} }
 */
export function graphqlHandler(store) {
  const card = () => {
    const c = store.current()
    if (!c) return null
    const d = c.doc
    return {
      id: 'main', rev: c.rev, format: d.format || 'story', name: d.name, theme: d.theme || {},
      pages: (d.pages || []).map((p) => ({ items: (p.items || []).map(toWidget) })),
      owner: d.owner || {}, notes: d.notes || {}, photos: d.photos || {}, backgroundImageId: d.backgroundImageId || null,
      updatedAt: c.at, updatedBy: c.by?.platform,
    }
  }
  const spec = (kind, json) => ({ kind, title: json.widget?.title ?? null, category: json.widget?.category ?? null, design: json.design, json })
  const root = {
    starCard: ({ id }) => (!id || id === 'main' ? card() : null),
    widgetSpecs: () => Object.entries(store.specs().specs).map(([k, j]) => spec(k, j)),
    widgetSpec: ({ kind }) => { const j = store.specs().specs[kind]; return j ? spec(kind, j) : null },
    widgetSpecsVersion: () => store.specs().hash,
    mockPhotos: () => store.mockPhotos(),
    saveStarCard: ({ card: input, baseRev, by }) => {
      // เก็บตามที่ผู้เขียนส่งมา · ฟิลด์ที่ไม่ส่ง = คงของเดิม · backgroundImageId: null = เอาออก
      const prev = store.current()?.doc || {}
      const doc = {
        schemaVersion: 1, format: input.format, name: input.name ?? prev.name, theme: input.theme ?? prev.theme ?? {},
        pages: input.pages.map((p) => ({ items: p.items.map(fromWidget) })),
        photos: input.photos ?? prev.photos ?? {}, notes: input.notes ?? prev.notes ?? {},
      }
      const owner = input.owner === undefined ? prev.owner : input.owner
      if (owner) doc.owner = owner
      const bg = input.backgroundImageId === undefined ? prev.backgroundImageId : input.backgroundImageId
      if (bg) doc.backgroundImageId = bg
      if (doc.name == null) delete doc.name
      const r = store.write(doc, baseRev, { platform: by || 'graphql', device: '' })
      return { ok: !r.conflict, rev: r.rev, conflict: !!r.conflict }
    },
  }
  return async (body) => graphql({ schema, source: body.query || '', rootValue: root, variableValues: body.variables || {}, operationName: body.operationName })
}
