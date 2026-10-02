// อินโฟกราฟิกข้างมือถือ (flow ใหม่เท่านั้น): เป็น STAR → สมัครงานได้ → ตอบรับได้ ต้องมีข้อมูลอะไร · ถามตอนไหน
// ติ๊กตาม state จริง (s.profile / s.user.verify) และไฮไลต์ด่านที่ผู้ใช้อยู่ตอนนี้ (ตาม stageOf)
(function () {
  const I = window.icon;
  const GATES = [
    { key: 'star', n: 1, t: 'เป็น STAR · สมัครงานได้', when: 'ถามตอนกดสมัครงานแรก ในหน้า "สมัครเป็น STAR" · กรอกครั้งเดียว ใช้ทุกงาน', get: 'ได้ Star Card · แบรนด์เห็นครบตั้งแต่ตอนคัด',
      items: [['socials', 'ช่องทางโซเชียล ≥ 1 ช่อง', 'ดึงยอดผู้ติดตามให้'], ['categories', 'สายที่ใช่', 'แบรนด์ใช้จับคู่งาน'], ['about', 'แนะนำตัว 1 บรรทัด', 'ขึ้นใต้ชื่อบนการ์ด'], ['kyc', 'ยืนยันตัวตน (KYC)', 'ส่งใบสมัครได้ระหว่างรอตรวจ · เป็น STAR เมื่อผ่าน'], ['rate', 'เรทรับงาน', 'ใส่ราคามาตรฐานให้แล้ว'], ['province', 'พื้นที่รับงาน', 'งานหน้าร้าน'], ['availability', 'วันเวลาว่างรับงาน', 'แบรนด์ใช้คัดคนให้ตรงช่วงงาน'], ['contact', 'LINE ID · เบอร์ · เว็บ', 'ขึ้นบนการ์ด ให้แบรนด์ทัก']] },
    { key: 'accept', n: 2, t: 'ตอบรับงานได้', when: 'กดตอบรับแล้วถาม · ครั้งแรกครั้งเดียว', get: 'รับของ รับเงิน เริ่มงานได้',
      items: [['address', 'ที่อยู่รับของ', 'ถามเมื่อได้งานแล้วเท่านั้น'], ['bank', 'บัญชีรับเงิน', 'งานที่มีค่าตัว'], ['draftRounds', 'แก้งานได้กี่รอบ', '1–3 รอบ']] },
  ];
  const OPTIONAL = [['insight', 'ข้อมูลผู้ติดตาม', 'แคปหน้าสถิติ 3 หมวด · ระบบอ่านให้ · ทำตอนไหนก็ได้']];
  const has = (s, k) => k === 'kyc' ? s.user.verify === 'approved' : !!(s.profile || {})[k];
  function gateNow(s) {
    const st = window.stageOf ? window.stageOf(s) : 0;
    if (st <= 4) return 'star';
    if (st <= 7) return 'accept';
    return null;
  }
  const row = (s, [k, t, sub]) => { const ok = has(s, k); return `<li class="${ok ? 'ok' : ''}"><i>${ok ? I('check', 11, 'bold') : ''}</i><div><b>${t}</b><span>${sub}</span></div></li>`; };
  window.renderInfo = function (s) {
    const el = document.getElementById('info');
    if (!el) return;
    el.hidden = s.flow !== 'new';
    if (el.hidden) return;
    const now = gateNow(s);
    el.innerHTML = `
      <div class="inf-h"><b>จะเป็น STAR · สมัคร · ตอบรับ</b><span>ต้องมีข้อมูลอะไรบ้าง · ติ๊กตามที่กรอกจริงในมือถือ</span></div>
      ${GATES.map((g, gi) => {
        const done = g.items.every(it => has(s, it[0]));
        return `${gi ? `<div class="inf-link">${I('caret-down', 14, 'bold')}</div>` : ''}
        <section class="inf-gate ${done ? 'done' : ''} ${now === g.key ? 'now' : ''}">
          <div class="inf-gt"><em>${done ? I('check', 13, 'bold') : g.n}</em><div><b>${g.t}</b><span>${g.when}</span></div>${now === g.key ? '<mark>ตอนนี้</mark>' : ''}</div>
          <ul>${g.items.map(it => row(s, it)).join('')}</ul>
          <div class="inf-get">${I('arrow-right', 12, 'bold')}${g.get}</div>
        </section>`;
      }).join('')}
      <section class="inf-gate opt"><div class="inf-gt"><em>+</em><div><b>ไม่บังคับ</b><span>ช่วยให้แบรนด์เลือกง่ายขึ้น</span></div></div><ul>${OPTIONAL.map(it => row(s, it)).join('')}</ul></section>`;
  };
  const prev = window.afterRender;
  window.afterRender = function (s) { prev && prev(s); window.renderInfo(s); };
})();
