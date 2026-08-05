/* 404 locale gate — progressive enhancement only.
   GitHub Pages serves one static /404.html for every missing path, including
   ones under /zh/, and there is no way to give the ZH tree its own. The page
   therefore ships BOTH recovery blocks: with JS off a Chinese reader still
   gets Chinese links, which is the whole point.
   With JS, narrow the page to the locale implied by the requested path: keep
   one recovery block, set the document language, and relabel the header nav so
   the reader can carry on inside their own locale instead of being handed
   English links. Every string comes from data-* attributes the page rendered
   out of _data/i18n.yml — nothing is hardcoded here.
   Fails open: on any error both blocks simply stay visible. */
(function () {
    var isZh = window.location.pathname.indexOf('/zh/') === 0;
    var keep = isZh ? 'zh' : 'en';
    var drop = isZh ? 'en' : 'zh';

    function apply() {
    try {
        var inner = document.querySelector('.error-page__inner');
        if (!inner) return;

        var dropped = document.querySelectorAll('[data-error-locale="' + drop + '"]');
        for (var i = 0; i < dropped.length; i++) {
            dropped[i].hidden = true;
        }

        if (isZh) {
            document.documentElement.lang = 'zh-CN';
            document.body.classList.remove('lang-en');
            document.body.classList.add('lang-zh');
        }

        var data = function (name) { return inner.getAttribute('data-' + name + '-' + keep); };

        if (data('title')) document.title = data('title');

        var skip = document.querySelector('.skip-link');
        if (skip && data('skip')) skip.textContent = data('skip');

        var toggle = document.querySelector('.nav-toggle');
        if (toggle && data('menu')) toggle.setAttribute('aria-label', data('menu'));

        var mark = document.querySelector('.site-mark');
        if (mark && data('home')) mark.setAttribute('href', data('home'));

        var nav = document.querySelector('.primary-nav');
        if (nav && data('nav-aria')) nav.setAttribute('aria-label', data('nav-aria'));

        /* Relabel the five content links. The switcher and theme items carry
           their own classes and are left alone; the switcher is absent on 404
           anyway (no `alternate:`), and the theme button is not a link. */
        var items = JSON.parse(data('nav-items') || '[]');
        var links = nav ? nav.querySelectorAll('.primary-nav__link:not(.primary-nav__link--switch)') : [];
        for (var j = 0; j < links.length && j < items.length; j++) {
            var label = links[j].querySelector('.primary-nav__label');
            if (label) label.textContent = items[j].label;
            links[j].setAttribute('href', items[j].href);
        }
    } catch (e) { /* fail open: both locale blocks remain readable */ }
    }

    /* Run twice, because this file is loaded from inside <main>: the first pass
       narrows the recovery block before it can paint, but the per-locale
       footers below it have not been parsed yet at that point. Every operation
       is idempotent (set hidden, set the same text), so the second pass is
       free. */
    apply();
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', apply);
    }
})();
