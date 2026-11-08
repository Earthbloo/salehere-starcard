#!/usr/bin/env node
// สำหรับทีม API — หลังอัปภาพใน previews/ ขึ้น server แล้ว (generatePreSignedUrl → PUT → ได้ fileUrl)
//   1. ใส่ fileUrl ของแต่ละภาพลงใน preview-urls.json  ({ "previews/<ไฟล์>.jpg": "https://…" })
//   2. node tools/fill-preview-urls.mjs   (รันในโฟลเดอร์ชุดข้อมูลนี้ · Node 18+ · ไม่ต้องติดตั้งอะไร)
// ได้ templates-with-preview.json = templates.json + exampleImage { imgPath, width, height } (รูปแบบ InputImage) ต่อใบ
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const read = (f) => JSON.parse(fs.readFileSync(path.join(root, f), 'utf8'))
const templates = read('templates.json'), index = read('templates-index.json'), urls = read('preview-urls.json')
const missing = Object.entries(urls).filter(([, v]) => typeof v !== 'string' || !/^https?:\/\//.test(v)).map(([k]) => k)
if (missing.length) { console.error(`ยังไม่ได้ใส่ URL ${missing.length} ภาพใน preview-urls.json:\n  ${missing.join('\n  ')}`); process.exit(1) }
const out = templates.map((t) => {
  const i = index.find((x) => x.name === t.name && x.format === t.format)
  if (!i) { console.error('ไม่พบภาพของ ' + t.name + ' ' + t.format); process.exit(1) }
  return { ...t, exampleImage: { imgPath: urls[i.preview.file], width: i.preview.width, height: i.preview.height } }
})
fs.writeFileSync(path.join(root, 'templates-with-preview.json'), JSON.stringify(out, null, 1))
console.log(`templates-with-preview.json — ${out.length} ใบ มี exampleImage ครบ`)
