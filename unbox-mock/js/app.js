// จุดเริ่ม — render ทุกครั้งที่ state เปลี่ยน · ผูก event แบบ delegate ที่ #phone

(function () {
  const $screen = document.getElementById('screen');
  const $overlay = document.getElementById('overlay');
  const $toast = document.getElementById('toast');

  function render(s) {
    const scr = window.SCREENS[s.screen] || window.SCREENS.home;
    const prev = $screen.querySelector('.scroll');
    const keep = window.__keepScroll && prev ? prev.scrollTop : 0;
    const focused = document.activeElement && document.activeElement.dataset ? document.activeElement.dataset.bind : null;
    const caret = focused && document.activeElement.selectionStart;
    $screen.innerHTML = scr(s);
    const next = $screen.querySelector('.scroll');
    if (next && keep) next.scrollTop = keep;
    if (focused && window.__keepScroll) { const el = $screen.querySelector(`[data-bind="${focused}"]`); if (el) { el.focus(); try { el.setSelectionRange(caret, caret); } catch (e) {} } }
    window.__keepScroll = false;
    if (window.__scrollTo) { const el = $screen.querySelector(window.__scrollTo); if (el) { el.scrollIntoView({ block: 'center', behavior: 'smooth' }); el.classList.add('shake'); } window.__scrollTo = null; }
    if (s.screen !== window.__lastScreen) { const pk = $screen.querySelector('.pk, .pk-reveal'); if (pk) pk.classList.add('push-in'); window.__lastScreen = s.screen; }
    $overlay.innerHTML = window.renderOverlay(s);
    $overlay.classList.toggle('on', !!(s.dialog || s.sheet));
    $toast.textContent = s.toast || '';
    $toast.classList.toggle('on', !!s.toast);
    window.renderPanel(s);
    document.body.classList.toggle('no-panel', !s.devPanel);
    if (window.afterRender) window.afterRender(s);
  }

  Store.subscribe(render);
  window.bindPanel();

  // ทุกปุ่มบนจอมือถือใช้ data-go (เปลี่ยนหน้า) หรือ data-do (action ที่มี logic)
  document.getElementById('phone').addEventListener('click', e => {
    const b = e.target.closest('[data-go],[data-do]');
    if (!b) return;
    if (b.dataset.go) { Store.set({ screen: b.dataset.go, dialog: null, sheet: null }); return; }
    window.ACTIONS[b.dataset.do]?.(b.dataset, b, e);
  });
  document.getElementById('phone').addEventListener('input', e => {
    const t = e.target;
    if (t.dataset.filter) { window.ACTIONS[t.dataset.filter]?.(t); return; }
    if (t.dataset.bind) { window.__keepScroll = true; window.ACTIONS.bind(t.dataset.bind, t.type === 'checkbox' ? t.checked : t.value); }
  });

  render(Store.get());
})();
