/* Copy-to-clipboard for command snippets (the gm-crypto-rs install line).
   Binds any [data-copy-target] button to copy the referenced element's text,
   with a brief "Copied" flip + a polite status announcement. Fail-safe: when
   the Clipboard API is unavailable or blocked, it selects the text so the
   reader can copy by hand. The button is hidden by CSS when JS is off, so the
   command stays plainly selectable either way. */
(() => {
  const buttons = Array.from(document.querySelectorAll('[data-copy-target]'));
  if (!buttons.length) return;

  const selectText = (el) => {
    try {
      const range = document.createRange();
      range.selectNodeContents(el);
      const sel = window.getSelection();
      sel.removeAllRanges();
      sel.addRange(range);
    } catch (e) { /* selection not available — nothing more we can do */ }
  };

  buttons.forEach((btn) => {
    const targetId = btn.getAttribute('data-copy-target');
    const target = targetId && document.getElementById(targetId);
    if (!target) return;

    const textSpan = btn.querySelector('.install__copy-text');
    const status = btn.closest('.install') &&
      btn.closest('.install').querySelector('.install__status');
    const copyLabel = btn.getAttribute('data-label-copy') || 'Copy';
    const doneLabel = btn.getAttribute('data-label-done') || 'Copied';
    let timer = null;

    const showDone = () => {
      if (textSpan) textSpan.textContent = doneLabel;
      if (status) status.textContent = doneLabel;
      btn.classList.add('is-copied');
      if (timer) clearTimeout(timer);
      timer = setTimeout(() => {
        if (textSpan) textSpan.textContent = copyLabel;
        if (status) status.textContent = '';
        btn.classList.remove('is-copied');
      }, 1600);
    };

    btn.addEventListener('click', () => {
      const text = (target.textContent || '').trim();
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(showDone).catch(() => selectText(target));
      } else {
        // No async Clipboard API (older/insecure context): select for manual copy.
        selectText(target);
      }
    });
  });
})();
