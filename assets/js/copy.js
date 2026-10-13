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
    const manualLabel = btn.getAttribute('data-label-manual') || 'Copy manually';
    const copyAria = btn.getAttribute('data-aria-copy') || copyLabel;
    const doneAria = btn.getAttribute('data-aria-done') || doneLabel;
    const manualAria = btn.getAttribute('data-aria-manual') || manualLabel;
    let timer = null;

    const setState = ({ label, aria, announcement, copied = false }) => {
      if (textSpan) textSpan.textContent = label;
      btn.setAttribute('aria-label', aria);
      if (status) status.textContent = announcement;
      btn.classList.toggle('is-copied', copied);
    };

    const reset = () => setState({
      label: copyLabel,
      aria: copyAria,
      announcement: ''
    });

    const resetAfter = (delay) => {
      if (timer) clearTimeout(timer);
      timer = setTimeout(reset, delay);
    };

    const showDone = () => {
      setState({
        label: doneLabel,
        aria: doneAria,
        announcement: doneAria,
        copied: true
      });
      resetAfter(1600);
    };

    const showManual = () => {
      selectText(target);
      setState({
        label: manualLabel,
        aria: manualAria,
        announcement: manualAria
      });
      resetAfter(3000);
    };

    btn.addEventListener('click', () => {
      const text = (target.textContent || '').trim();
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(showDone).catch(showManual);
      } else {
        // No async Clipboard API (older/insecure context): select for manual copy.
        showManual();
      }
    });
  });
})();
