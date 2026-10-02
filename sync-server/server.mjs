// Star Card — ที่เก็บกลางสำหรับ "โหมดลองทำ"
//
// การ์ดใบเดียวเป็น JSON ก้อนเดียว iOS กับ Android อ่าน/เขียนที่นี่ เพื่อดูว่า
// ค่าที่แพลตฟอร์มหนึ่งเขียน พออีกแพลตฟอร์มอ่านแล้วเขียนกลับ ค่าเปลี่ยนไปไหม
//
// ไม่มี dependency — `node sync-server/server.mjs` (พอร์ต 8787 หรือ PORT)
// สัญญาเต็มอยู่ใน ./README.md

import http from 'node:http'
import fs from 'node:fs'
import path from 'node:path'
import crypto from 'node:crypto'
import { fileURLToPath } from 'node:url'

const here = path.dirname(fileURLToPath(import.meta.url))
const dataDir = path.join(here, 'data')
const imageDir = path.join(dataDir, 'images')
const statePath = path.join(dataDir, 'state.json')
const port = Number(process.env.PORT || 8787)

fs.mkdirSync(imageDir, { recursive: true })

// ── สถานะ ─────────────────────────────────────────────────────────────────
// history เก็บ doc ทุก rev ไว้ทั้งก้อน — การ์ดหนึ่งใบราว 3 KB เก็บเป็นพัน rev ก็ยังเล็ก
let state = { rev: 0, history: [], echoes: [] }
try { state = JSON.parse(fs.readFileSync(statePath, 'utf8')) } catch {}
const saveState = () => fs.writeFileSync(statePath, JSON.stringify(state))
const current = () => state.history[state.history.length - 1] || null

// ── diff ──────────────────────────────────────────────────────────────────
// เทียบค่าต่อค่า · ตัวเลขเทียบแบบ JS (18 กับ 18.0 ถือว่าเท่ากัน — ต่างกันแค่การเขียน)
// รายการใน items[] จับคู่ด้วย id ไม่ใช่ลำดับ ย้ายลำดับแล้วจะไม่ขึ้นว่าเปลี่ยนทั้งแถว
const isObj = (v) => v !== null && typeof v === 'object' && !Array.isArray(v)
const label = (el, i) => (isObj(el) && el.id ? `${el.kind || 'item'}·${String(el.id).slice(0, 6)}` : String(i))

function diff(a, b, at = '', out = []) {
  if (Array.isArray(a) && Array.isArray(b)) {
    const keyed = [...a, ...b].every((el) => isObj(el) && el.id)
    if (keyed) {
      // จับคู่แบบไม่สนตัวพิมพ์ — iOS เขียน UUID ตัวใหญ่ Android ตัวเล็ก ถ้าจับคู่ตรงตัว
      // ทุกชิ้นจะขึ้นว่า "หาย + เพิ่มใหม่" ทั้งที่ที่เปลี่ยนจริงคือตัวพิมพ์ของ id (ซึ่งจะโผล่เป็น .id)
      const key = (el) => String(el.id).toLowerCase()
      const am = new Map(a.map((el, i) => [key(el), [el, i]]))
      const bm = new Map(b.map((el, i) => [key(el), [el, i]]))
      for (const [id, [el, i]] of am) {
        const p = `${at}[${label(el, i)}]`
        if (!bm.has(id)) out.push({ path: p, from: el, to: undefined })
        else {
          const [other, j] = bm.get(id)
          if (i !== j) out.push({ path: `${p}.(ลำดับ)`, from: i, to: j })
          diff(el, other, p, out)
        }
      }
      for (const [id, [el, i]] of bm) if (!am.has(id)) out.push({ path: `${at}[${label(el, i)}]`, from: undefined, to: el })
      return out
    }
    const n = Math.max(a.length, b.length)
    for (let i = 0; i < n; i++) diff(a[i], b[i], `${at}[${i}]`, out)
    return out
  }
  if (isObj(a) && isObj(b)) {
    for (const k of new Set([...Object.keys(a), ...Object.keys(b)])) diff(a[k], b[k], at ? `${at}.${k}` : k, out)
    return out
  }
  if (a === b) return out
  if (typeof a === 'number' && typeof b === 'number' && Number.isNaN(a) && Number.isNaN(b)) return out
  out.push({ path: at || '(ทั้งก้อน)', from: a, to: b })
  return out
}

// ── http ──────────────────────────────────────────────────────────────────
const send = (res, code, body, type = 'application/json; charset=utf-8') => {
  res.writeHead(code, { 'Content-Type': type, 'Cache-Control': 'no-store', 'Access-Control-Allow-Origin': '*' })
  res.end(type.startsWith('application/json') ? JSON.stringify(body) : body)
}

const readBody = (req, limit = 20 * 1024 * 1024) =>
  new Promise((resolve, reject) => {
    const chunks = []
    let size = 0
    req.on('data', (c) => {
      size += c.length
      if (size > limit) { reject(new Error('too large')); req.destroy() } else chunks.push(c)
    })
    req.on('end', () => resolve(Buffer.concat(chunks)))
    req.on('error', reject)
  })

const readJSON = async (req) => JSON.parse((await readBody(req, 2 * 1024 * 1024)).toString('utf8') || '{}')

const who = (b) => ({ platform: String(b.platform || '?'), device: String(b.device || '') })

function log(...args) {
  console.log(new Date().toISOString().slice(11, 19), ...args)
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://x')
  const p = url.pathname
  try {
    if (req.method === 'OPTIONS') return send(res, 204, '')

    if (p === '/' || p === '/index.html') {
      return send(res, 200, fs.readFileSync(path.join(here, 'viewer.html')), 'text/html; charset=utf-8')
    }

    // การ์ดล่าสุด · ?known=N แล้ว rev ยังเท่าเดิม = 204 (แอป poll ถี่ได้โดยไม่ต้องโหลดก้อนซ้ำ)
    if (p === '/api/card' && req.method === 'GET') {
      const cur = current()
      const known = url.searchParams.get('known')
      if (known !== null && Number(known) === state.rev) return send(res, 204, '')
      return send(res, 200, cur ? { rev: cur.rev, doc: cur.doc, by: cur.by, at: cur.at } : { rev: 0, doc: null })
    }

    // เขียนทับ — baseRev ต้องตรงกับ rev ล่าสุด ไม่ตรง = มีอีกเครื่องเขียนก่อน (409 + ฉบับล่าสุด)
    if (p === '/api/card' && req.method === 'PUT') {
      const b = await readJSON(req)
      if (!isObj(b.doc)) return send(res, 400, { error: 'doc ต้องเป็น object' })
      const cur = current()
      if (Number(b.baseRev) !== state.rev) {
        log(`409 ${who(b).platform} baseRev=${b.baseRev} rev=${state.rev}`)
        return send(res, 409, { rev: state.rev, doc: cur?.doc ?? null, by: cur?.by, at: cur?.at })
      }
      const changes = diff(cur?.doc ?? {}, b.doc)
      if (cur && changes.length === 0) return send(res, 200, { rev: state.rev, unchanged: true })
      state.rev += 1
      const entry = { rev: state.rev, doc: b.doc, by: who(b), at: new Date().toISOString(), changes }
      state.history.push(entry)
      saveState()
      log(`rev ${state.rev} ← ${entry.by.platform} (${changes.length} จุด)`)
      return send(res, 200, { rev: state.rev })
    }

    // "อ่านแล้วเขียนกลับ" — แอปที่เพิ่งรับ rev N มา ส่ง doc ที่ตัวเองจะเขียนจากสถานะที่เพิ่งโหลด
    // server เทียบกับ doc ของ rev N ตรง ๆ: ว่าง = อ่านครบไม่มีค่าเพี้ยน
    if (p === '/api/echo' && req.method === 'POST') {
      const b = await readJSON(req)
      const src = state.history.find((h) => h.rev === Number(b.rev))
      if (!src) return send(res, 404, { error: 'ไม่มี rev นี้' })
      const diffs = diff(src.doc, b.doc)
      const entry = { rev: src.rev, by: who(b), at: new Date().toISOString(), diffs }
      state.echoes = state.echoes.filter((e) => !(e.rev === entry.rev && e.by.platform === entry.by.platform && e.by.device === entry.by.device))
      state.echoes.push(entry)
      saveState()
      log(`echo rev ${src.rev} ← ${entry.by.platform}: ${diffs.length ? diffs.length + ' จุดเพี้ยน' : 'ตรงกัน'}`)
      return send(res, 200, { diffs })
    }

    if (p === '/api/history' && req.method === 'GET') {
      const since = Number(url.searchParams.get('since') || 0)
      return send(res, 200, {
        rev: state.rev,
        current: current(),
        history: state.history.filter((h) => h.rev > since).map(({ doc, ...rest }) => rest),
        echoes: state.echoes,
      })
    }

    if (p.startsWith('/api/rev/') && req.method === 'GET') {
      const h = state.history.find((x) => x.rev === Number(p.slice(9)))
      return h ? send(res, 200, h) : send(res, 404, { error: 'ไม่มี rev นี้' })
    }

    // รูป — id = sha256 ของไบต์ที่ส่งมา (อัปซ้ำได้ ไม่เกิดไฟล์ซ้ำ)
    if (p === '/api/images' && req.method === 'POST') {
      const buf = await readBody(req)
      if (!buf.length) return send(res, 400, { error: 'ไม่มีไฟล์' })
      const id = crypto.createHash('sha256').update(buf).digest('hex').slice(0, 32)
      const type = String(req.headers['content-type'] || 'image/jpeg')
      const file = path.join(imageDir, id)
      if (!fs.existsSync(file)) {
        fs.writeFileSync(file, buf)
        fs.writeFileSync(file + '.type', type)
        log(`image ${id.slice(0, 8)} ${(buf.length / 1024).toFixed(0)} KB ${type}`)
      }
      return send(res, 200, { imageId: id })
    }

    if (p.startsWith('/api/images/') && req.method === 'GET') {
      const id = p.slice(12).replace(/[^a-f0-9]/g, '')
      const file = path.join(imageDir, id)
      if (!id || !fs.existsSync(file)) return send(res, 404, { error: 'ไม่มีรูปนี้' })
      let type = 'image/jpeg'
      try { type = fs.readFileSync(file + '.type', 'utf8') } catch {}
      res.writeHead(200, { 'Content-Type': type, 'Cache-Control': 'public, max-age=31536000, immutable' })
      return res.end(fs.readFileSync(file))
    }

    // ล้างการ์ดกลาง (รูปเก็บไว้ — ไม่มีผลกับผลลัพธ์ และอัปซ้ำได้ฟรี)
    if (p === '/api/reset' && req.method === 'POST') {
      state = { rev: 0, history: [], echoes: [] }
      saveState()
      log('reset')
      return send(res, 200, { rev: 0 })
    }

    send(res, 404, { error: 'not found' })
  } catch (e) {
    log('error', e.message)
    send(res, 500, { error: e.message })
  }
})

server.listen(port, '0.0.0.0', () => {
  log(`Star Card sync — http://localhost:${port}  (Android emulator: http://10.0.2.2:${port})`)
})
