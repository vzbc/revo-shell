// Renderer half of the Electron traffic lights (evaluated in the page's main
// world by tl-main.js). Builds a closed shadow root so the page's CSS can't
// reach it; reports clicks to the main process through console.debug + token.
(() => {
  if (window.__macTL) return;
  const NS = 'http://www.w3.org/2000/svg';
  const GLYPH = {
    close: [['path', { d: 'M4.5 4.5L9.5 9.5M9.5 4.5L4.5 9.5', stroke: 'rgba(0,0,0,0.55)', 'stroke-width': '1.2', 'stroke-linecap': 'round', fill: 'none' }]],
    min: [['path', { d: 'M3.8 7H10.2', stroke: 'rgba(0,0,0,0.55)', 'stroke-width': '1.2', 'stroke-linecap': 'round' }]],
    zoom: [['path', { d: 'M4 4H8.6L4 8.6Z M10 10H5.4L10 5.4Z', fill: 'rgba(0,0,0,0.55)' }]],
  };
  const CSS = `
  :host { all: initial; position: fixed; z-index: 2147483647; display: block;
          -webkit-app-region: no-drag; app-region: no-drag; direction: ltr; contain: layout style; }
  .tl { display: flex; gap: var(--gap); padding: 0; margin: 0; }
  button { all: unset; box-sizing: border-box; width: var(--s); height: var(--s); border-radius: 50%;
           background: #ff5f57; box-shadow: inset 0 0 0 0.5px #e0443e; display: grid; place-items: center;
           cursor: default; -webkit-app-region: no-drag; app-region: no-drag; }
  button.y { background: #febc2e; box-shadow: inset 0 0 0 0.5px #dea123; }
  button.g { background: #28c840; box-shadow: inset 0 0 0 0.5px #1aab29; }
  button svg { width: var(--s); height: var(--s); opacity: 0; }
  .tl:hover button svg { opacity: 1; }
  button:active { filter: brightness(0.85); }
  :host(.blur) .tl:not(:hover) button { background: #4a4a4c; box-shadow: inset 0 0 0 0.5px #555557; }
  :host(.light.blur) .tl:not(:hover) button { background: #d1d0d2; box-shadow: inset 0 0 0 0.5px #bfbfc1; }
  :host(.fs) { display: none; }`;
  let cfg = null, host = null, root = null, st = { focused: true, fullscreen: false };

  // DOM APIs only: VS Code & co. enforce Trusted Types, so no innerHTML.
  function build() {
    host = document.createElement('mac-traffic-lights');
    root = host.attachShadow({ mode: 'closed' });
    try {
      const sheet = new CSSStyleSheet(); sheet.replaceSync(CSS); root.adoptedStyleSheets = [sheet];
    } catch (_) {
      const st = document.createElement('style'); st.textContent = CSS; root.appendChild(st);
    }
    const tl = document.createElement('div'); tl.className = 'tl';
    for (const [cls, act, title] of [['r', 'close', 'Close'], ['y', 'min', 'Minimize'], ['g', 'zoom', 'Zoom']]) {
      const b = document.createElement('button');
      b.className = cls; b.title = title; b.dataset.a = act;
      const svg = document.createElementNS(NS, 'svg'); svg.setAttribute('viewBox', '0 0 14 14');
      for (const [tag, attrs] of GLYPH[act]) {
        const el = document.createElementNS(NS, tag);
        for (const k in attrs) el.setAttribute(k, attrs[k]);
        svg.appendChild(el);
      }
      b.appendChild(svg); tl.appendChild(b);
    }
    root.appendChild(tl);
    const log = console.debug.bind(console);
    tl.addEventListener('click', (e) => {
      const b = e.target.closest('button');
      if (b) { e.stopPropagation(); log(cfg.token + b.dataset.a); }
    });
    for (const ev of ['mousedown', 'dblclick', 'pointerdown'])
      host.addEventListener(ev, (e) => e.stopPropagation());
  }

  function place() {
    if (!host) return;
    if (!host.isConnected) (document.body || document.documentElement).appendChild(host);
    const s = cfg.size || 14;
    host.style.cssText = `left:${cfg.x ?? 13}px;top:${cfg.y ?? 13}px;--s:${s}px;--gap:${cfg.gap ?? 8}px;`;
    host.classList.toggle('blur', !st.focused);
    host.classList.toggle('fs', !!(cfg.hideWhenFullscreen && st.fullscreen));
    host.classList.toggle('light', !matchMedia('(prefers-color-scheme: dark)').matches);
  }

  window.__macTL = {
    setup(c) {
      cfg = c; st.focused = c.focused;
      if (!host) build();
      place();
      // SPA frameworks sometimes wipe <body>; re-attach when that happens.
      if (!window.__macTLObs) {
        window.__macTLObs = new MutationObserver(() => { if (host && !host.isConnected) place(); });
        window.__macTLObs.observe(document.documentElement, { childList: true, subtree: false });
        if (document.body) window.__macTLObs.observe(document.body, { childList: true });
      }
    },
    state(s) { Object.assign(st, s); place(); },
  };
})();
