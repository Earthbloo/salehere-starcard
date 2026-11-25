// node present/hero-verified-swap/build.mjs — เขียน index.html จาก variants.mjs (รูปอยู่ใน img/ จาก shot.mjs)
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { VARIANTS } from './variants.mjs'
const here = path.dirname(fileURLToPath(import.meta.url))
const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;')
const cards = VARIANTS.map((v) => `
  <article class="v${v.id === 'now' ? ' now' : ''}" data-id="${v.id}">
    <header><span class="tag">${v.id === 'now' ? 'เดิม' : v.id}</span><h2>${esc(v.name)}</h2>
      ${v.id === 'now' ? '' : `<button class="pick" type="button" data-id="${v.id}" aria-pressed="false">เลือกแบบนี้</button>`}</header>
    <div class="pair">
      ${['paper', 'glass'].map((s) => `<figure><img loading="lazy" data-src="img/${v.id}-${s}-" src="img/${v.id}-${s}-grey.png" alt="${esc(v.name)} · ${s === 'paper' ? 'กระดาษเทป' : 'กระจก'}"><figcaption>${s === 'paper' ? 'ป้ายชื่อ กระดาษเทป' : 'ป้ายชื่อ กระจก'}</figcaption></figure>`).join('')}
    </div>
    <p class="note">${esc(v.note)}</p>
    <p class="data"><span>ข้อมูล</span>${esc(v.data)}</p>
  </article>`).join('')
const html = `<title>ป้ายชื่อ แทน VERIFIED</title>
<meta name="claude:viewport-fit-sides" content="cover">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Noto+Sans+Thai:wght@400;600;800;900&family=IBM+Plex+Mono:wght@500&display=swap">
<style>
/* ผังแบบแผ่นเทียบ: แต่ละแบบ = 1 แผ่น มีภาพเรนเดอร์จริง 2 สกินคู่กัน · พื้นหลังสลับได้ */
:root {
  --bg: #F3F2F6; --panel: #FFFFFF; --ink: #1C1A21; --ink2: #6A6672; --line: #E3E1E8; --accent: #E0262E; --pickbg: #FFF1F1;
  --display: "Noto Sans Thai", system-ui, sans-serif; --mono: "IBM Plex Mono", ui-monospace, monospace;
}
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { --bg: #141317; --panel: #1E1C22; --ink: #F2F0F5; --ink2: #A29DAB; --line: #312E37; --accent: #FF5A5F; --pickbg: #3A1D20; color-scheme: dark } }
:root[data-theme="dark"] { --bg: #141317; --panel: #1E1C22; --ink: #F2F0F5; --ink2: #A29DAB; --line: #312E37; --accent: #FF5A5F; --pickbg: #3A1D20; color-scheme: dark }
body { background: var(--bg); color: var(--ink); font-family: var(--display); font-size: 15px; line-height: 1.55 }
.wrap { max-width: 1180px; margin: 0 auto; padding-block: 32px 56px; padding-left: max(16px, env(safe-area-inset-left, 0px)); padding-right: max(16px, env(safe-area-inset-right, 0px)); display: grid; gap: 24px }
.top { display: flex; flex-wrap: wrap; gap: 16px 32px; align-items: end; justify-content: space-between }
.top h1 { margin: 0; font-size: clamp(26px, 4vw, 36px); font-weight: 900; line-height: 1.15; text-wrap: balance }
.top p { margin: 6px 0 0; color: var(--ink2); max-width: 60ch }
.ctl { display: flex; gap: 8px; align-items: center; flex-wrap: wrap }
.ctl span { font-family: var(--mono); font-size: 12px; color: var(--ink2); letter-spacing: .04em }
.sw { border: 1px solid var(--line); background: var(--panel); color: var(--ink); border-radius: 999px; padding: 6px 14px 6px 8px; font: 600 13px var(--display); display: inline-flex; gap: 8px; align-items: center; cursor: pointer }
.sw i { width: 18px; height: 18px; border-radius: 50%; display: block }
.sw[aria-pressed="true"] { border-color: var(--ink); box-shadow: inset 0 0 0 1px var(--ink) }
.sw:focus-visible, .pick:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(min(100%, 520px), 1fr)); gap: 16px }
.v { background: var(--panel); border: 1px solid var(--line); border-radius: 14px; padding: 16px; display: grid; gap: 12px; min-width: 0 }
.v.now { opacity: .82 }
.v.picked { border-color: var(--accent); box-shadow: 0 0 0 2px var(--accent) }
.v header { display: flex; align-items: center; gap: 10px }
.v h2 { margin: 0; font-size: 18px; font-weight: 800; flex: 1; min-width: 0 }
.tag { font-family: var(--mono); font-size: 13px; min-width: 28px; height: 28px; padding: 0 6px; border-radius: 8px; display: grid; place-items: center; background: var(--ink); color: var(--panel) }
.now .tag { background: var(--line); color: var(--ink2); font-family: var(--display); font-weight: 700 }
.pick { border: 1px solid var(--line); background: transparent; color: var(--ink); border-radius: 999px; padding: 5px 14px; font: 600 13px var(--display); cursor: pointer }
.pick[aria-pressed="true"] { background: var(--accent); border-color: var(--accent); color: #fff }
.pair { display: grid; grid-template-columns: 1fr 1fr; gap: 10px }
figure { margin: 0; display: grid; gap: 4px; min-width: 0 }
figure img { width: 100%; height: auto; border-radius: 10px; display: block }
figcaption { font-size: 12px; color: var(--ink2) }
.note { margin: 0 }
.data { margin: 0; font-size: 13px; color: var(--ink2); display: flex; gap: 8px; flex-wrap: wrap }
.data span { font-family: var(--mono); font-size: 11px; letter-spacing: .06em; text-transform: uppercase; border: 1px solid var(--line); border-radius: 6px; padding: 1px 6px }
.foot { color: var(--ink2); font-size: 13px }
.foot b { color: var(--ink) }
@media (max-width: 420px) { .pair { grid-template-columns: 1fr } }
</style>
<div class="wrap">
  <div class="top">
    <div>
      <h1>ป้ายชื่อ: อะไรมาแทนปุ่ม VERIFIED สีฟ้า</h1>
      <p>ติ๊กแดงข้างชื่อยังบอกว่ายืนยันแล้วอยู่ ช่องล่างจึงว่างให้ใส่ข้อมูลที่แบรนด์อยากรู้ ทุกภาพเรนเดอร์จาก JSON จริงด้วย web renderer ตัวเดียวกับแอป ไม่ใช่ภาพวาด</p>
    </div>
    <div class="ctl" role="group" aria-label="สีการ์ด">
      <span>สีการ์ด</span>
      <button class="sw" type="button" data-bg="grey" aria-pressed="true"><i style="background:#3B3B3D"></i>เทาเข้ม</button>
      <button class="sw" type="button" data-bg="lilac" aria-pressed="false"><i style="background:#B9A6F0"></i>ม่วงอ่อน</button>
    </div>
  </div>
  <div class="grid">${cards}
  </div>
  <p class="foot" id="foot">ยังไม่ได้เลือก · กด <b>เลือกแบบนี้</b> ที่แบบที่ชอบ (เลือกได้หลายแบบ)</p>
</div>
<script>
const KEY = 'hero-verified-picks'
let picks = []
try { picks = JSON.parse(localStorage.getItem(KEY) || '[]') } catch (e) {}
const foot = document.getElementById('foot')
function paint() {
  document.querySelectorAll('.pick').forEach((b) => { const on = picks.includes(b.dataset.id); b.setAttribute('aria-pressed', on); b.textContent = on ? 'เลือกแล้ว' : 'เลือกแบบนี้'; b.closest('.v').classList.toggle('picked', on) })
  foot.innerHTML = picks.length ? 'เลือกไว้: <b>' + picks.join(', ') + '</b> · ส่งตัวอักษรนี้กลับมาในแชทได้เลย' : 'ยังไม่ได้เลือก · กด <b>เลือกแบบนี้</b> ที่แบบที่ชอบ (เลือกได้หลายแบบ)'
}
document.addEventListener('click', (e) => {
  const p = e.target.closest('.pick')
  if (p) { const id = p.dataset.id; picks = picks.includes(id) ? picks.filter((x) => x !== id) : [...picks, id].sort(); try { localStorage.setItem(KEY, JSON.stringify(picks)) } catch (err) {} paint() }
  const s = e.target.closest('.sw')
  if (s) { document.querySelectorAll('.sw').forEach((b) => b.setAttribute('aria-pressed', b === s)); document.querySelectorAll('img[data-src]').forEach((im) => { im.src = im.dataset.src + s.dataset.bg + '.png' }) }
})
paint()
</script>
`
fs.writeFileSync(path.join(here, 'index.html'), html)
console.log('index.html', html.length)
