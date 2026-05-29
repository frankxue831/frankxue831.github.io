/* Light/dark theme toggle.
   Pre-paint script in head.html has already resolved & applied the right
   theme. This file only handles the user-facing button: cycling the
   preference, persisting it, keeping the button + aria-label + PWA chrome
   in sync, and re-resolving when the OS theme changes (if in 'auto'). */
(() => {
  const KEY = 'frankxue.theme';
  const CYCLE = { auto: 'light', light: 'dark', dark: 'auto' };
  const btn = document.querySelector('.theme-toggle');
  if (!btn) return; // no toggle on this page; nothing to do

  const mq = window.matchMedia ? window.matchMedia('(prefers-color-scheme: dark)') : null;

  const readPref = () => {
    try {
      const s = localStorage.getItem(KEY);
      return (s === 'light' || s === 'dark') ? s : 'auto';
    } catch (e) { return 'auto'; }
  };

  const writePref = (pref) => {
    try {
      if (pref === 'auto') localStorage.removeItem(KEY);
      else localStorage.setItem(KEY, pref);
    } catch (e) { /* storage blocked — preference is session-only */ }
  };

  const resolve = (pref) => {
    if (pref === 'light' || pref === 'dark') return pref;
    return (mq && mq.matches) ? 'dark' : 'light';
  };

  // PWA chrome / theme-color: when the reader makes an explicit choice we
  // add a non-media meta that wins over the two media-queried ones in head.
  // Removed when going back to auto so the media-queried metas track the OS.
  // Browsers pick the FIRST matching theme-color meta — the override has to
  // be inserted *before* the media-queried metas, otherwise on a light OS
  // the earlier `media="(prefers-color-scheme: light)"` tag would win and
  // an explicit dark choice would never reach the address bar / PWA chrome.
  const setThemeColorOverride = (effective, isExplicit) => {
    let m = document.querySelector('meta[name="theme-color"][data-override]');
    if (!isExplicit) { if (m) m.remove(); return; }
    if (!m) {
      m = document.createElement('meta');
      m.setAttribute('name', 'theme-color');
      m.setAttribute('data-override', '');
      const firstThemeColor = document.querySelector('meta[name="theme-color"]');
      if (firstThemeColor && firstThemeColor.parentNode) {
        firstThemeColor.parentNode.insertBefore(m, firstThemeColor);
      } else {
        document.head.appendChild(m);
      }
    }
    m.setAttribute('content', effective === 'dark' ? '#1a1814' : '#f5f1e8');
  };

  // Templates own their own punctuation — ZH uses "：" and "。", EN uses ": "
  // and ". " — so the whole aria sentence is a template string per language,
  // with {current}/{next} placeholders that JS substitutes.
  const state = {
    auto:  btn.dataset.stateAuto  || 'Auto',
    light: btn.dataset.stateLight || 'Light',
    dark:  btn.dataset.stateDark  || 'Dark'
  };
  const ariaTemplate = btn.dataset.ariaTemplate || 'Theme: {current}. Switch to {next}.';

  // Briefly enable a colour transition for an explicit theme switch (toggle or
  // OS change) — never on the initial load (that would flash), never under
  // reduced motion (re-checked live). The class carries the transition; a
  // forced reflow commits it before data-theme flips so the change actually
  // animates, then it's removed once the crossfade is done.
  const ANIM_CLASS = 'theme-anim';
  const ANIM_MS = 380; // slightly longer than --dur (320ms) so it isn't cut short
  let animTimer = null;
  const beginThemeAnim = () => {
    if (window.matchMedia &&
        window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    const el = document.documentElement;
    el.classList.add(ANIM_CLASS);
    void el.offsetWidth; // commit the transition property before the value change
    if (animTimer) clearTimeout(animTimer);
    animTimer = setTimeout(() => el.classList.remove(ANIM_CLASS), ANIM_MS);
  };

  const apply = (pref) => {
    const effective = resolve(pref);
    document.documentElement.setAttribute('data-theme', effective);
    btn.setAttribute('data-theme-pref', pref);
    const next = CYCLE[pref];
    btn.setAttribute(
      'aria-label',
      ariaTemplate.replace('{current}', state[pref]).replace('{next}', state[next])
    );
    setThemeColorOverride(effective, pref !== 'auto');
  };

  // Hold the current preference in memory so a storage-blocked browser
  // (Safari private mode, strict cookie/storage policies) still cycles
  // correctly. We try to persist on each change but never re-read storage
  // for the source of truth after init — otherwise a silently-failing
  // setItem would leave readPref() returning 'auto' forever and the
  // toggle would be stuck after one click.
  let currentPref = readPref();
  apply(currentPref);

  btn.addEventListener('click', () => {
    currentPref = CYCLE[currentPref];
    writePref(currentPref); // best-effort; failure is non-fatal
    beginThemeAnim();        // crossfade the explicit switch
    apply(currentPref);
  });

  // Live OS-theme sync — only acts when the reader is in 'auto'.
  if (mq) {
    const onChange = () => { if (currentPref === 'auto') { beginThemeAnim(); apply('auto'); } };
    if (mq.addEventListener) mq.addEventListener('change', onChange);
    else if (mq.addListener) mq.addListener(onChange); // older Safari
  }
})();
