/* w-text.js — ข้อความ / ตกแต่ง */

reg({ id: 'textBlock', family: 'text', title: 'ข้อความ', sizes: ['wide'], cls: '',
  note: 'ก้อนข้อความลอยอิสระ ไม่อยู่ในกริด 3 ขนาด (กล่อง = ตัวอักษรพอดี) — โชว์ตัวอย่างบนกรอบแนวนอน',
  render() { return `<div class="center" style="height:100%;gap:10px"><div class="h-serif" style="font-size:40px;line-height:1;text-align:center"><i>Honest skin,</i><br><b>honest reviews.</b></div><div class="h-script" style="font-size:22px;color:var(--accent)">— ${D.first}</div></div>`; } });

reg({ id: 'flowCards', family: 'text', title: 'การ์ดขั้นตอน', sizes: ['wide', 'large'], cls: 'glass pad',
  note: 'ขั้นตอนทำงาน 1→2→3 · แนวนอน = 3 ขั้นเรียงมีลูกศร · ใหญ่ = 4 ขั้น 2×2 พร้อมคำอธิบาย + ระยะเวลา',
  render(s) {
    const steps = [['บรีฟ', 'คุยคอนเซปต์ · เลือกแพลตฟอร์ม', '1 วัน'], ['ถ่าย', 'ถ่ายเองตัดเองทุกคลิป', '3 วัน'], ['ส่งดราฟต์', 'แก้ฟรี 2 รอบ', '1 วัน'], ['โพสต์', 'ส่งลิงก์ + อินไซต์ 7 วัน', '7 วัน']];
    const card = ([t, d, dur], i, big) => `<div class="col" style="gap:3px;padding:${big ? 12 : 10}px;border-radius:14px;background:var(--glass);flex:1;min-width:0"><span class="num" style="font-size:${big ? 22 : 18}px;color:var(--accent)">0${i + 1}</span><b style="font-size:${big ? 15 : 13}px">${t}</b>${big ? `<span class="dim" style="font-size:11px;line-height:1.35">${d}</span><span class="chip outline" style="font-size:9.5px;align-self:flex-start;margin-top:4px">${dur}</span>` : ''}</div>`;
    if (s === 'wide') return `<div class="col" style="height:100%;justify-content:center;gap:12px"><div class="row between">${H.label('How we work')}<span class="dim" style="font-size:11px">รวม ~12 วัน</span></div><div class="row" style="gap:6px;align-items:stretch">${steps.slice(0, 3).map((x, i) => card(x, i, false) + (i < 2 ? `<span class="dim" style="align-self:center">${ICO.arrow.replace('<svg', '<svg width="16"')}</span>` : '')).join('')}</div></div>`;
    return `<div class="col" style="height:100%;gap:10px"><div class="row between"><div class="h-serif" style="font-size:24px"><i>How we</i> <b>work</b></div><span class="dim" style="font-size:11px">รวม ~12 วัน</span></div><div class="grid2" style="flex:1;gap:8px">${steps.map((x, i) => card(x, i, true)).join('')}</div></div>`;
  } });

reg({ id: 'scrapLabel', family: 'text', title: 'หัวข้อกล่องคำ', sizes: ['wide'], cls: 'pinkp',
  note: 'ป้ายหัวข้อกระดาษ ตัวหนังสือลายมือใหญ่ — แนวนอนเท่านั้น',
  render() { return `<div class="center" style="height:100%;padding:14px"><div class="scrap-paper" style="padding:14px 28px;transform:rotate(-1.5deg);position:relative"><div class="doodle" style="font-size:38px;line-height:1">my beauty diary ✎</div><span class="tape" style="top:-8px;left:20px"></span><span class="tape" style="top:-8px;right:20px;left:auto;transform:rotate(6deg)"></span></div></div>`; } });
