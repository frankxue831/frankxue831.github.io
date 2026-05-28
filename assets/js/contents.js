/* Contents rail ("On this page") for project detail pages.
   Built entirely from the page's <h2> structure — no per-page markup. Adds a
   sticky rail in the right margin (wide viewports only; CSS hides it < 1024px),
   tracks the section you're reading (scroll-spy), and jumps on click via plain
   anchors (global `scroll-behavior: smooth` + the reduced-motion reset in CSS
   handle the animation, so no JS click handler is needed).

   Pure progressive enhancement: if this never runs, or there's no detail
   article, or there are too few sections, the page is exactly as it was. */
(() => {
  const detail = document.querySelector('.project-detail');
  if (!detail) return; // not a detail page

  const headings = Array.from(detail.querySelectorAll('h2'));
  if (headings.length < 3) return; // not worth a rail

  // --- stable, unique ids on each heading -------------------------------
  const used = new Set();
  document.querySelectorAll('[id]').forEach((el) => used.add(el.id));
  const slugify = (s) =>
    s.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
  const ensureId = (h, i) => {
    if (h.id) { used.add(h.id); return h.id; }
    const base = slugify(h.textContent || '') || ('section-' + (i + 1));
    let id = base, n = 2;
    while (used.has(id)) { id = base + '-' + n; n++; }
    used.add(id);
    h.id = id;
    return id;
  };

  // --- build the rail ----------------------------------------------------
  const label = (document.body.getAttribute('data-toc-label') || 'On this page').trim();
  const nav = document.createElement('nav');
  nav.className = 'toc';
  nav.setAttribute('aria-label', label);

  const heading = document.createElement('p');
  heading.className = 'toc__label';
  heading.textContent = label;
  nav.appendChild(heading);

  const list = document.createElement('ol');
  list.className = 'toc__list';

  const links = new Map(); // id -> <a>
  const ordered = [];      // { id, el } in document order
  headings.forEach((h, i) => {
    const id = ensureId(h, i);
    const item = document.createElement('li');
    item.className = 'toc__item';
    const a = document.createElement('a');
    a.className = 'toc__link';
    a.href = '#' + id;
    a.textContent = (h.textContent || '').trim();
    item.appendChild(a);
    list.appendChild(item);
    links.set(id, a);
    ordered.push({ id: id, el: h });
  });
  nav.appendChild(list);

  const section = detail.closest('.section') || detail.parentNode;
  if (!section) return;
  section.classList.add('has-toc');
  section.appendChild(nav); // lands in the grid's right column

  // --- scroll-spy --------------------------------------------------------
  const header = document.querySelector('.site-header');
  // A heading becomes "current" once it passes below the sticky header's
  // bottom edge plus a little reading margin.
  let offset = 0;
  const measure = () => { offset = (header ? header.offsetHeight : 0) + 24; };
  measure();

  let currentId = null;
  const setActive = (id) => {
    if (id === currentId) return;
    currentId = id;
    links.forEach((a, hid) => {
      if (hid === id) {
        a.classList.add('is-active');
        a.setAttribute('aria-current', 'true');
      } else {
        a.classList.remove('is-active');
        a.removeAttribute('aria-current');
      }
    });
  };

  const computeActive = () => {
    const doc = document.documentElement;
    // At the very bottom, the last section is current even if its short
    // heading never crossed the threshold line.
    if (window.innerHeight + window.scrollY >= doc.scrollHeight - 2) {
      return ordered[ordered.length - 1].id;
    }
    const line = window.scrollY + offset;
    let activeId = ordered[0].id;
    for (let i = 0; i < ordered.length; i++) {
      const top = ordered[i].el.getBoundingClientRect().top + window.scrollY;
      if (top <= line) activeId = ordered[i].id;
      else break; // headings are in document order
    }
    return activeId;
  };

  let ticking = false;
  const onScroll = () => {
    if (ticking) return;
    ticking = true;
    requestAnimationFrame(() => {
      setActive(computeActive());
      ticking = false;
    });
  };

  const onResize = () => { measure(); onScroll(); };

  window.addEventListener('scroll', onScroll, { passive: true });
  window.addEventListener('resize', onResize);
  window.addEventListener('load', onScroll);
  // bfcache restore: layout/scroll may differ — recompute.
  window.addEventListener('pageshow', onScroll);

  setActive(computeActive()); // initial paint
})();
