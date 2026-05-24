/* Scroll-reveal: fades/rises .reveal elements as they enter the viewport.
   Active only when <html> has `motion` (set by the head gate). Fail-open. */
(() => {
  const root = document.documentElement;
  if (!root.classList.contains('motion')) return;        // gate disabled -> visible
  if (!('IntersectionObserver' in window)) {              // belt-and-suspenders
    root.classList.remove('motion');
    return;
  }

  const targets = Array.from(document.querySelectorAll('.reveal'));
  const reveal = (el) => el.classList.add('is-revealed');

  // Reveal anything already in/above the viewport now, so above-the-fold
  // content is never left hidden waiting on the async observer callback.
  const vh = window.innerHeight || root.clientHeight;
  targets.forEach((el) => {
    if (el.getBoundingClientRect().top < vh * 0.9) reveal(el);
  });

  const io = new IntersectionObserver((entries, obs) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        reveal(entry.target);
        obs.unobserve(entry.target);
      }
    });
  }, { threshold: 0.12, rootMargin: '0px 0px -8% 0px' });

  targets.forEach((el) => {
    if (!el.classList.contains('is-revealed')) io.observe(el);
  });

  // bfcache restore -> ensure everything visible (no animation needed).
  window.addEventListener('pageshow', (e) => {
    if (e.persisted) targets.forEach(reveal);
  });

  // Signal the head watchdog so it doesn't strip `motion`.
  root.setAttribute('data-reveal-ready', 'true');
})();
