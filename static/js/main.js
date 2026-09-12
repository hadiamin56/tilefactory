// ── Date display ──
document.addEventListener('DOMContentLoaded', () => {
  const el = document.getElementById('topbar-date');
  if (el) {
    el.textContent = new Date().toLocaleDateString('en-IN', {
      weekday: 'short', day: 'numeric', month: 'long', year: 'numeric'
    });
  }
});

// ── Tab switcher ──
function switchTab(tab, el, panelA, panelB) {
  el.closest('.tabs').querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
  el.classList.add('active');
  document.getElementById(panelA).style.display = tab === 'feet' ? 'block' : 'none';
  document.getElementById(panelB).style.display = tab === 'interlock' ? 'block' : 'none';
}

// ── Modal ──
function closeModal(id) {
  document.getElementById(id).classList.remove('open');
}
document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.modal-overlay').forEach(o => {
    o.addEventListener('click', e => { if (e.target === o) o.classList.remove('open'); });
  });
});

// ── Toast ──
function toast(msg, type = 'ok') {
  const t = document.getElementById('toast');
  t.innerHTML = (type === 'ok' ? '✅' : '❌') + ' ' + msg;
  t.style.borderColor = type === 'ok' ? 'var(--success)' : 'var(--danger)';
  t.classList.add('show');
  setTimeout(() => t.classList.remove('show'), 2800);
}
