/* Home hero "decrypt": the title arrives as cipher glyphs that resolve into the
   real headline. In place, reflow-free (fixed-width cells), a11y-safe (stable
   aria-label + aria-hidden cells), reduced-motion / no-JS / bfcache safe. */
(() => {
  const title = document.querySelector('.hero__title');
  if (!title) return; // home only (only the home hero uses .hero__title)

  const GLYPHS = '0123456789ABCDEF/\\{}[]#*+=$%@?';
  const rnd = () => GLYPHS[(Math.random() * GLYPHS.length) | 0];

  const toGraphemes = (str) => {
    if (window.Intl && Intl.Segmenter) {
      return Array.from(
        new Intl.Segmenter(undefined, { granularity: 'grapheme' }).segment(str),
        (s) => s.segment
      );
    }
    return Array.from(str);
  };
  // CJK ranges (incl. CJK punctuation + fullwidth forms) break per character.
  const isCJK = (ch) =>
    /[　-〿㐀-鿿豈-﫿＀-￯]/.test(ch);

  // 1) Read real text segments (preserve the <em> boundary), normalize whitespace.
  const segments = [];
  title.childNodes.forEach((node) => {
    if (node.nodeType === Node.TEXT_NODE) {
      const t = node.textContent.replace(/\s+/g, ' ').trim();
      if (t) segments.push({ node, text: t, accent: false });
    } else if (node.nodeType === Node.ELEMENT_NODE) {
      const t = node.textContent.replace(/\s+/g, ' ').trim();
      segments.push({ node, text: t, accent: node.tagName === 'EM' });
    }
  });
  if (!segments.length) return;

  // 2) Lock the accessible name. Join segments with a space, EXCEPT between two
  //    CJK boundaries (Chinese runs together with no space; English keeps spaces).
  const accessibleName = segments.reduce((acc, seg, i) => {
    if (i === 0) return seg.text;
    const sep = (isCJK(acc[acc.length - 1]) && isCJK(seg.text[0])) ? '' : ' ';
    return acc + sep + seg.text;
  }, '');
  title.setAttribute('aria-label', accessibleName);

  // 3) Reduced motion -> leave the real title untouched. Done.
  const mq = window.matchMedia;
  if (mq && mq('(prefers-reduced-motion: reduce)').matches) return;

  const cells = []; // { span, real }

  const buildSegment = (seg) => {
    const frag = document.createDocumentFragment();
    let word = null;
    toGraphemes(seg.text).forEach((g) => {
      if (g === ' ') { frag.appendChild(document.createTextNode(' ')); word = null; return; }
      const cell = document.createElement('span');
      cell.className = 'hero-cell';
      cell.setAttribute('aria-hidden', 'true');
      cell.textContent = g;
      cells.push({ span: cell, real: g });
      if (isCJK(g)) {
        frag.appendChild(cell);          // CJK: standalone, breaks per char
        word = null;
      } else {
        if (!word) {                     // Latin: group into a nowrap word
          word = document.createElement('span');
          word.className = 'hero-word';
          word.setAttribute('aria-hidden', 'true');
          frag.appendChild(word);
        }
        word.appendChild(cell);
      }
    });
    if (seg.node.nodeType === Node.TEXT_NODE) {
      const holder = document.createElement('span');
      holder.setAttribute('aria-hidden', 'true');
      holder.appendChild(frag);
      title.replaceChild(holder, seg.node);
    } else {
      seg.node.setAttribute('aria-hidden', 'true');
      seg.node.textContent = '';
      seg.node.appendChild(frag);
    }
  };

  const DURATION = 900; // ms — total decrypt time, independent of title length
  let cancelled = false;
  const settleAll = () => { cancelled = true; cells.forEach((c) => { c.span.textContent = c.real; }); };

  const animate = () => {
    segments.forEach(buildSegment);
    // Lock each cell width to its natural (final-glyph) advance -> swaps never reflow.
    cells.forEach((c) => { c.span.style.width = c.span.getBoundingClientRect().width + 'px'; });
    // FIX C: if the page is frozen mid-animation and restored from bfcache, settle to
    // the real title instead of resuming/replaying the scramble.
    window.addEventListener('pagehide', settleAll);
    window.addEventListener('pageshow', (e) => { if (e.persisted) settleAll(); });
    // Resolve left -> right over DURATION (time-based, ~constant duration), re-rolling
    // unresolved glyphs each tick.
    const total = cells.length;
    const nowMs = () => (window.performance && performance.now) ? performance.now() : Date.now();
    const t0 = nowMs();
    const tick = () => {
      if (cancelled) return;
      const t = Math.min(1, (nowMs() - t0) / DURATION);
      const resolved = Math.floor(t * total);
      for (let i = 0; i < total; i++) {
        cells[i].span.textContent = i < resolved ? cells[i].real : rnd();
      }
      if (t < 1) window.setTimeout(tick, 45);
      else settleAll(); // final frame: all real
    };
    tick();
  };

  // 4) Start after fonts are ready (correct width measurement). If fonts take
  //    longer than 800ms, SKIP the animation and leave the real title (fail open).
  let settled = false;
  if (document.fonts && document.fonts.ready) {
    const timer = window.setTimeout(() => { settled = true; /* skip: real title stays */ }, 800);
    document.fonts.ready.then(() => {
      if (settled) return;
      settled = true;
      window.clearTimeout(timer);
      animate();
    });
  } else {
    animate();
  }
})();
