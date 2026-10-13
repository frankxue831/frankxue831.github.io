(() => {
    const toggle = document.querySelector('.nav-toggle');
    const nav = document.getElementById('primary-nav');
    if (!toggle || !nav) return;

    const main = document.getElementById('main');
    const footers = Array.from(document.querySelectorAll('footer'));
    const backgrounds = [main, ...footers].filter(Boolean);
    const firstNavLink = nav.querySelector('.primary-nav__link');

    const setBackgroundInert = (inert) => {
        backgrounds.forEach((element) => { element.inert = inert; });
    };

    const setOpen = (open, { restoreFocus = false, moveFocus = false } = {}) => {
        toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
        document.body.classList.toggle('is-nav-open', open);
        setBackgroundInert(open);
        if (open && moveFocus && firstNavLink) {
            window.requestAnimationFrame(() => firstNavLink.focus());
        } else if (!open && restoreFocus) {
            toggle.focus();
        }
    };

    toggle.addEventListener('click', () => {
        const open = toggle.getAttribute('aria-expanded') !== 'true';
        setOpen(open, { moveFocus: open });
    });

    nav.addEventListener('click', (event) => {
        if (event.target.closest('a')) setOpen(false);
    });

    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape' && toggle.getAttribute('aria-expanded') === 'true') {
            setOpen(false, { restoreFocus: true });
        }
    });

    document.addEventListener('pointerdown', (event) => {
        if (toggle.getAttribute('aria-expanded') === 'true' && event.target === document.body) {
            setOpen(false, { restoreFocus: true });
        }
    });

    const desktop = window.matchMedia('(min-width: 760px)');
    const sync = () => { if (desktop.matches) setOpen(false); };
    desktop.addEventListener('change', sync);
    window.addEventListener('pageshow', sync);
    sync();
})();
