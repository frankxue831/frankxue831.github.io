/* Keep captions outside code-heavy videos. Native tracks remain the no-JS,
   load-error and fullscreen fallback; no media or cue timing is rewritten. */
(() => {
  document.querySelectorAll('[data-video-captions]').forEach((figure) => {
    const video = figure.querySelector('video');
    const panel = figure.querySelector('.video-captions');
    const select = panel.querySelector('select');
    const text = panel.querySelector('.video-captions__text');
    const tracks = Array.from(video.querySelectorAll('track'));
    const initial = tracks.find((track) => track.default);
    if (!initial || !video.textTracks) return;
    let enhanced = false;
    let nativeFullscreen = false;
    const inFullscreen = () => nativeFullscreen || document.fullscreenElement === video;
    const selected = () => tracks.find((track) => track.srclang === select.value);
    const render = () => {
      const active = selected();
      const cues = active ? Array.from(active.track.activeCues || []) : [];
      // getCueAsHTML strips WebVTT cue markup without interpreting it as HTML.
      text.textContent = cues.map((cue) => cue.getCueAsHTML().textContent).join('\n') ||
        (select.value === 'off' ? text.dataset.off : (video.currentTime === 0 ? text.dataset.waiting : ''));
    };
    const apply = () => {
      if (!enhanced) return;
      tracks.forEach((track) => {
        const mode = track === selected() ? (inFullscreen() ? 'showing' : 'hidden') : 'disabled';
        if (track.track.mode !== mode) track.track.mode = mode;
      });
      render();
    };
    const start = () => {
      // Do not suppress working native captions until their cues have loaded.
      if (enhanced) return;
      if (initial.readyState !== 2) {
        // WebKit leaves a default track disabled, with no cues loaded, unless the
        // viewer's caption preference selects it; hidden loads cues without drawing.
        if (initial.track.mode === 'disabled') initial.track.mode = 'hidden';
        return;
      }
      enhanced = true;
      panel.hidden = false;
      apply();
    };
    tracks.forEach((track) => {
      track.addEventListener('load', () => { start(); if (enhanced) render(); });
      track.track.addEventListener('cuechange', () => { if (enhanced) render(); });
      track.addEventListener('error', () => {
        if (!enhanced) return;
        enhanced = false;
        panel.hidden = true;
        tracks.forEach((item) => { item.track.mode = item === initial ? 'showing' : 'disabled'; });
      });
    });
    select.addEventListener('change', apply);
    // Honor language changes made from the browser's own CC menu too.
    video.textTracks.addEventListener('change', () => {
      if (!enhanced) return;
      const showing = tracks.find((track) => track.track.mode === 'showing');
      if (showing) select.value = showing.srclang;
      else if (tracks.every((track) => track.track.mode === 'disabled')) select.value = 'off';
      apply();
    });
    document.addEventListener('fullscreenchange', apply);
    video.addEventListener('webkitbeginfullscreen', () => { nativeFullscreen = true; apply(); });
    video.addEventListener('webkitendfullscreen', () => { nativeFullscreen = false; apply(); });
    video.addEventListener('loadedmetadata', start);
    start();
  });
})();
