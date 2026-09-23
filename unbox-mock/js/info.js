// อินโฟกราฟิกข้างมือถือ (flow ใหม่เท่านั้น): เป็น STAR → สมัครงานได้ → ตอบรับได้ ต้องมีข้อมูลอะไร · ถามตอนไหน
// ติ๊กตาม state จริง (s.profile / s.user.verify) และไฮไลต์ด่านที่ผู้ใช้อยู่ตอนนี้ (ตาม stageOf)
(function () {
  const I = window.icon;
  const GATES = [
    { key: 'card', n: 1, t: 'มีการ์ด', when: 'กดสมัครงานแรก · ถามเท่าที่การ์ดต้องใช้', get: 'การ์ดเกิดทันที · ครั้งหน้าไม่ต้องตอบอีก',
      items: [['socials', 'ช่องทางโซเชียล ≥ 1 ช่อง', 'ดึงยอดผู้ติดตามให้'], ['categories', 'สายที่ใช่', 'แบรนด์กรองด้วยข้อนี้ก่อน']] },
    { key: 'prep', n: 2, t: 'ส่งใบสมัครได้ · แบรนด์คัดทันที', when: 'หน้าตรวจข้อมูลก่อนส่ง · ใส่ค่ามาตรฐานให้แล้ว แก้เฉพาะที่อยากแก้', get: 'แบรนด์มีข้อมูลครบตั้งแต่วินาทีที่คัด',
      items: [['rate', 'เรทรับงาน', 'ใส่ราคามาตรฐานให้แล้ว'], ['province', 'พื้นที่ + วันว่าง', 'เติมค่าเริ่มต้นให้จากบัญชี'], ['about', 'แนะนำตัว 1 บรรทัด', 'ร่างให้จากสายที่ใช่'], ['kyc', 'ยืนยันตัวตน (KYC)', 'แบรนด์เลือกเฉพาะคนที่ยืนยันแล้ว · ส่งใบสมัครได้ระหว่างรอตรวจ']] },
    { key: 'accept', n: 3, t: 'ตอบรับงานได้', when: 'กดตอบรับแล้วถาม · ที่อยู่ใช้จากใบสมัคร', get: 'รับของ รับเงิน เริ่มงานได้',
      items: [['bank', 'บัญชีรับเงิน', 'งานที่มีค่าตัว'], ['draftRounds', 'แก้งานได้กี่รอบ', '1–3 รอบ']] },
  ];
  const OPTIONAL = [['insight', 'ข้อมูลผู้ติดตาม', 'แคปหน้าสถิติ 3 หมวด · ระบบอ่านให้ · ทำตอนไหนก็ได้']];
  const has = (s, k) => k === 'kyc' ? s.user.verify === 'approved' : !!(s.profile || {})[k];
  function gateNow(s) {
    const st = window.stageOf ? window.stageOf(s) : 0;
    const card = has(s, 'socials') && has(s, 'categories');
    if (st <= 1) return card ? 'prep' : 'card';
    if (st <= 5) return 'prep';
    if (st <= 8) return 'accept';
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
