// macOS 26/27 traffic lights for Electron apps on Hyprland.
//
// Loaded into an app's main process either with NODE_OPTIONS=--require
// (apps on the system electron) or by a one-line require prepended to the
// app's entry file (bundled apps; see patch-asar.py).
//
// For every window it: hides the app's own window buttons (profile.hide),
// adds per-app CSS (profile.css), and draws the three lights in a shadow-DOM
// host at (profile.x, profile.y). Clicks come back as console messages with a
// per-process token. profiles.json is watched and re-applied live.
'use strict';
if (process.type === 'browser' && process.versions.electron && !global.__macTrafficLights) {
  global.__macTrafficLights = true;
  try { main(); } catch (e) { try { console.error('[mac-tl]', e); } catch (_) {} }
}

function main() {
  const fs = require('fs');
  const path = require('path');
  const crypto = require('crypto');
  const { spawn } = require('child_process');
  const { app, BrowserWindow, webContents } = require('electron');

  const DIR = __dirname;
  const PROFILES = path.join(DIR, 'profiles.json');
  const CACHE = path.join(process.env.HOME || '/tmp', '.cache/electron-tl');
  const MINIMIZE = path.join(process.env.HOME || '', '.config/hypr/scripts/minimize_window.py');
  const TOKEN = '⁣mac-tl:' + crypto.randomBytes(8).toString('hex') + ':';
  const PAGE_JS = fs.readFileSync(path.join(DIR, 'tl-page.js'), 'utf8');

  let profiles = {};
  function loadProfiles() {
    try { profiles = JSON.parse(fs.readFileSync(PROFILES, 'utf8')); } catch (e) { console.error('[mac-tl] profiles', e.message); }
  }
  loadProfiles();

  function appKey() {
    const names = [app.getName(), path.basename(process.execPath)];  // never touch getPath() early: it freezes userData
    for (const n of names) if (profiles.apps && profiles.apps[n]) return n;
    return names[0];
  }
  function profileFor(wc) {
    const key = appKey();
    const base = Object.assign({}, profiles.default || {});
    const p = (profiles.apps && profiles.apps[key]) || {};
    const out = Object.assign(base, p, { key });
    // per-URL overrides: [{match: "regex", ...}]
    let url = '';
    try { url = wc.getURL(); } catch (_) {}
    for (const v of p.variants || []) {
      try { if (new RegExp(v.match).test(url)) Object.assign(out, v); } catch (_) {}
    }
    if (out.urlMatch) { try { if (!new RegExp(out.urlMatch).test(url)) out.enabled = false; } catch (_) {} }
    return out;
  }

  // Apps that use Electron's native Window Controls Overlay (drawn by
  // Chromium, unreachable from CSS): drop titleBarOverlay before the window is
  // built by handing the app a BrowserWindow subclass via require('electron').
  try {
    const key0 = appKey();
    const p0 = Object.assign({}, profiles.default || {}, (profiles.apps || {})[key0] || {});
    if (p0.stripOverlay) {
      const Module = require('module');
      const real = require('electron');
      const RealBW = real.BrowserWindow;
      class BrowserWindow extends RealBW {
        constructor(opts) {
          if (opts && opts.titleBarOverlay) { opts = Object.assign({}, opts); delete opts.titleBarOverlay; }
          super(opts);
        }
        setTitleBarOverlay() {}
      }
      const proxy = new Proxy(real, { get: (t, k) => (k === 'BrowserWindow' ? BrowserWindow : t[k]) });
      const load = Module._load;
      Module._load = function (request, parent, isMain) {
        if (request === 'electron' || request === 'electron/main') return proxy;
        return load.apply(this, arguments);
      };
    }
  } catch (e) { console.error('[mac-tl] overlay hook', e); }

  const cssKeys = new WeakMap();
  async function inject(win, wc) {
    if (!wc || wc.isDestroyed()) return;
    const prof = profileFor(wc);
    if (prof.probe) setTimeout(() => { if (!wc.isDestroyed()) probe(wc, prof); }, prof.probeDelay || 3500);
    if (prof.enabled === false) return;
    let css = '';
    if (prof.hide && prof.hide.length) css += prof.hide.join(',\n') + ' { display: none !important; }\n';
    if (prof.css) css += prof.css + '\n';
    try {
      const old = cssKeys.get(wc);
      if (old) await wc.removeInsertedCSS(old).catch(() => {});
      if (css) cssKeys.set(wc, await wc.insertCSS(css, { cssOrigin: 'user' }));
    } catch (_) {}
    const cfg = {
      token: TOKEN, x: prof.x, y: prof.y, size: prof.size, gap: prof.gap,
      zoomOnly: !!prof.zoomOnly, focused: win ? win.isFocused() : true,
      hideWhenFullscreen: prof.hideWhenFullscreen !== false,
      rtlMirror: !!prof.rtlMirror,
    };
    try {
      const r = await wc.executeJavaScript(PAGE_JS + '\n;window.__macTL ? (window.__macTL.setup(' + JSON.stringify(cfg) + '), "ok") : "no-api";', true);
      if (r !== 'ok') log(prof.key, 'setup: ' + r);
    } catch (e) { log(prof.key, 'inject failed: ' + (e && e.message)); }
  }

  function log(key, msg) {
    try { fs.mkdirSync(CACHE, { recursive: true }); fs.appendFileSync(path.join(CACHE, String(key).replace(/[^\w.-]+/g, '_') + '.log'), new Date().toISOString() + ' ' + msg + '\n'); } catch (_) {}
  }

  function probe(wc, prof) {
    const js = `(() => {
      const out = { url: location.href, title: document.title, w: innerWidth, h: innerHeight, dir: document.dir || document.documentElement.dir, els: [] };
      const re = /close|minimi|maximi|restore|window-?control|titlebar|title-bar|traffic|winButton|caption/i;
      for (const el of document.querySelectorAll('*')) {
        const r = el.getBoundingClientRect();
        if (r.top > 70 || r.width === 0 || r.height === 0) continue;
        const cls = typeof el.className === 'string' ? el.className : (el.getAttribute && el.getAttribute('class')) || '';
        const lab = (el.getAttribute('aria-label') || '') + ' ' + (el.getAttribute('title') || '');
        const reg = getComputedStyle(el).webkitAppRegion;
        if (re.test(cls) || re.test(el.id) || re.test(lab) || reg === 'drag' && r.height < 80) {
          out.els.push({ tag: el.tagName, id: el.id, cls: cls.slice(0, 160), lab: lab.trim().slice(0, 60), reg,
            r: [Math.round(r.left), Math.round(r.top), Math.round(r.width), Math.round(r.height)],
            path: (() => { let p = [], e = el; while (e && e.nodeType === 1 && p.length < 6) { p.unshift(e.tagName.toLowerCase() + (e.id ? '#' + e.id : '') + (typeof e.className === 'string' && e.className ? '.' + e.className.trim().split(/\\s+/).slice(0, 3).join('.') : '')); e = e.parentElement; } return p.join(' > '); })() });
        }
      }
      if (${JSON.stringify(prof.probeTree || '')}) {
        const tree = (el, d) => { const r = el.getBoundingClientRect(); const cls = typeof el.className === 'string' ? el.className : (el.getAttribute('class') || '');
          return { t: el.tagName.toLowerCase(), c: cls.slice(0, 100), l: (el.getAttribute('aria-label') || ''), r: [Math.round(r.left), Math.round(r.top), Math.round(r.width), Math.round(r.height)], k: d > 0 ? [...el.children].map(c => tree(c, d - 1)) : el.children.length }; };
        out.tree = [...document.querySelectorAll(${JSON.stringify(prof.probeTree || 'x')})].slice(0, 3).map(e => tree(e, 4));
      }
      return out;
    })()`;
    wc.executeJavaScript(js, true).then((res) => {
      try {
        fs.mkdirSync(CACHE, { recursive: true });
        const f = path.join(CACHE, prof.key.replace(/[^\w.-]+/g, '_') + '.' + wc.id + '.probe.json');
        fs.writeFileSync(f, JSON.stringify(res, null, 1));
      } catch (_) {}
    }).catch(() => {});
  }

  function onAction(win, act) {
    if (!win || win.isDestroyed()) return;
    if (act === 'close') win.close();
    else if (act === 'min') {
      if (fs.existsSync(MINIMIZE)) {
        try { spawn('/usr/bin/python3', [MINIMIZE, 'min'], { detached: true, stdio: 'ignore' }).unref(); } catch (_) { win.minimize(); }
      } else win.minimize();
    } else if (act === 'zoom') {
      // Hyprland reports tiled windows as maximized, so toggle its own
      // "maximized" fullscreen mode on the active (just clicked) window.
      if (process.env.HYPRLAND_INSTANCE_SIGNATURE && !win.isFullScreen()) {
        try {
          spawn('hyprctl', ['eval', 'hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized" }))'], { detached: true, stdio: 'ignore' }).unref();
          return;
        } catch (_) {}
      }
      if (win.isFullScreen()) win.setFullScreen(false);
      else if (win.isMaximized()) win.unmaximize();
      else win.maximize();
    }
  }

  const tracked = new Set();
  function attach(wc) {
    if (tracked.has(wc)) return;
    const win = () => BrowserWindow.fromWebContents(wc) || (wc.hostWebContents && BrowserWindow.fromWebContents(wc.hostWebContents)) || null;
    let type = '';
    try { type = wc.getType(); } catch (_) {}
    if (type !== 'window' && type !== 'browserView') return;
    tracked.add(wc);
    const run = () => inject(win(), wc);
    wc.on('dom-ready', run);
    wc.on('did-navigate-in-page', run);
    wc.on('console-message', function (e) {
      const msg = (e && typeof e.message === 'string') ? e.message : arguments[2];
      if (typeof msg === 'string' && msg.startsWith(TOKEN)) onAction(win() || BrowserWindow.getFocusedWindow(), msg.slice(TOKEN.length));
    });
    wc.once('destroyed', () => tracked.delete(wc));
    const w = win();
    if (w && !w.__macTL) {
      w.__macTL = true;
      const st = (f) => { for (const c of webContents.getAllWebContents()) { const ww = BrowserWindow.fromWebContents(c); if (ww === w || (c.hostWebContents && BrowserWindow.fromWebContents(c.hostWebContents) === w)) c.executeJavaScript('window.__macTL&&window.__macTL.state(' + JSON.stringify(f) + ')', true).catch(() => {}); } };
      w.on('focus', () => st({ focused: true }));
      w.on('blur', () => st({ focused: false }));
      w.on('enter-full-screen', () => st({ fullscreen: true }));
      w.on('leave-full-screen', () => st({ fullscreen: false }));
    }
    if (!wc.isLoading() && wc.getURL()) run();
  }

  app.on('web-contents-created', (_e, wc) => setImmediate(() => attach(wc)));
  app.whenReady().then(() => { for (const wc of webContents.getAllWebContents()) attach(wc); });

  try {
    let t = null;
    fs.watch(DIR, (_ev, f) => {
      if (f !== 'profiles.json') return;
      clearTimeout(t);
      t = setTimeout(() => {
        loadProfiles();
        for (const wc of tracked) if (!wc.isDestroyed()) inject(BrowserWindow.fromWebContents(wc), wc);
      }, 150);
    });
  } catch (_) {}
}
