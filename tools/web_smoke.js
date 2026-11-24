// Browser smoke test for the HTML5 bundle: serves it locally, drives headless Edge/Chrome over CDP,
// counts Lua/JS errors and saves screenshots. The Playgama bridge runs in its "mock" platform.
//
// Usage:
//   node tools/web_smoke.js <bundle_dir> <out_dir> [--size=960x540] [--secs=8] [--lang=en]
//        [--cfg=potato_war.cheats=1,potato_war.skip_onboarding=1]
//        [--steps="wait:6;shot:menu;click:480,300;key:Escape;drag:300,300,200,350;hide;wait:1;show;js:window._isEngineLoopPaused"]
//
// Steps: wait:<s> | shot:<name> | click:<x>,<y> | drag:<x1>,<y1>,<x2>,<y2> | key:<Key> (Escape, Space, ArrowLeft, F10...)
//        hold:<Key>,<s> | hide | show (simulated tab visibility change) | js:<expression> (prints the result)
// Exit code is 1 when Lua/JS errors were seen, so it can gate a build.
const fs = require('fs');
const path = require('path');
const http = require('http');
const { spawn } = require('child_process');

const [, , BUNDLE, OUT, ...rest] = process.argv;
if (!BUNDLE || !OUT) {
  console.error('usage: node tools/web_smoke.js <bundle_dir> <out_dir> [--size=WxH] [--steps=...]');
  process.exit(2);
}
const opt = { size: '960x540', secs: '8', lang: '', steps: '', cfg: '', poki: '' };
for (const a of rest) {
  const m = a.match(/^--(\w+)=(.*)$/);
  if (m) opt[m[1]] = m[2];
}
const [VW, VH] = opt.size.split('x').map(Number);
if (!Number.isFinite(VW) || !Number.isFinite(VH)) {
  console.error('bad --size:', JSON.stringify(opt.size));
  process.exit(2);
}
const PORT = 8760 + Math.floor(Math.random() * 400);
const DBG_PORT = 9360 + Math.floor(Math.random() * 400);
const BROWSER = process.env.SMOKE_BROWSER || [
  'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
  'C:/Program Files/Google/Chrome/Application/chrome.exe',
  '/usr/bin/google-chrome',
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
].find(p => fs.existsSync(p));

if (!BROWSER) { console.error('No Edge/Chrome found'); process.exit(1); }
fs.mkdirSync(OUT, { recursive: true });

function patchedIndex() {
  let html = fs.readFileSync(path.join(BUNDLE, 'index.html'), 'utf8');
  const args = [];
  if (opt.lang) args.push(`--config=potato_war.lang=${opt.lang}`);
  if (opt.cfg) for (const kv of opt.cfg.split(',')) args.push(`--config=${kv}`);
  if (args.length) {
    const re = /(<script id=["']engine-setup["'][^>]*>)/;
    if (!re.test(html)) console.error('WARN: engine-setup script tag not found, parameters not injected');
    html = html.replace(re, `$1\nCUSTOM_PARAMETERS["engine_arguments"] = ${JSON.stringify(args)};`);
  }
  if (opt.poki) {
    const re = /<\/head>/;
    if (!re.test(html)) console.error('WARN: </head> not found, Poki mock not injected');
    html = html.replace(re, '<script>window.BastionPokiTest = true;</script>\n</head>');
  }
  if (opt.lang) {
    html = html.replace('<head>', `<head>\n<script>Object.defineProperty(navigator, 'language', { get: function () { return '${opt.lang}'; } });</script>`);
  }
  return html;
}

const MIME = {
  '.html': 'text/html', '.js': 'application/javascript', '.wasm': 'application/wasm', '.css': 'text/css',
  '.png': 'image/png', '.json': 'application/json', '.ogg': 'audio/ogg',
};
const srv = http.createServer((req, res) => {
  const url = decodeURIComponent(req.url.split('?')[0]);
  if (url === '/' || url === '/index.html') {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(patchedIndex());
    return;
  }
  const root = path.resolve(BUNDLE);
  const fp = path.resolve(path.join(root, url));
  if (fp.startsWith(root)) {
    if (fs.existsSync(fp) && fs.statSync(fp).isFile()) {
      res.writeHead(200, { 'Content-Type': MIME[path.extname(fp)] || 'application/octet-stream' });
      fs.createReadStream(fp).pipe(res);
      return;
    }
  }
  res.writeHead(404); res.end();
});

srv.listen(PORT, '127.0.0.1', async () => {
  const userData = path.resolve(OUT, '_prof_' + PORT);
  const proc = spawn(BROWSER, [
    '--headless=new', '--disable-gpu', '--use-angle=swiftshader', '--enable-unsafe-swiftshader',
    '--autoplay-policy=no-user-gesture-required', `--remote-debugging-port=${DBG_PORT}`,
    `--window-size=${VW},${VH}`, `--user-data-dir=${userData}`,
    '--no-first-run', '--no-default-browser-check', `http://127.0.0.1:${PORT}/`,
  ], { stdio: 'ignore' });
  console.error(`browser ${path.basename(BROWSER)} pid=${proc.pid} ui=${PORT} cdp=${DBG_PORT}`);
  proc.on('error', e => console.error('browser error:', e.message));
  proc.on('exit', (code, sig) => console.error('browser exit:', code, sig));

  const killBrowser = () => {
    if (!proc || proc.killed) return;
    try {
      if (process.platform === 'win32') {
        spawn('taskkill', ['/pid', String(proc.pid), '/T', '/F'], { stdio: 'ignore' });
      } else {
        proc.kill('SIGKILL');
      }
    } catch {}
  };

  const sleep = ms => new Promise(r => setTimeout(r, ms));
  let ws;
  let lastList = null;
  let lastErr = null;
  for (let i = 0; i < 40; i++) {
    await sleep(250);
    try {
      lastList = await (await fetch(`http://127.0.0.1:${DBG_PORT}/json`)).json();
      const page = lastList.find(t => t.type === 'page');
      if (page) { ws = new WebSocket(page.webSocketDebuggerUrl); break; }
    } catch (e) { lastErr = e; }
  }
  if (!ws) {
    killBrowser();
    srv.close();
    console.error('CDP connect failed', lastErr ? String(lastErr.message) : '', lastList ? JSON.stringify(lastList).slice(0, 300) : 'no /json');
    process.exit(1);
  }

  let msgId = 0;
  let errors = 0;
  const cdp = (method, params = {}) => new Promise(res => {
    const id = ++msgId;
    const onMsg = ev => {
      const d = JSON.parse(ev.data);
      if (d.id === id) { ws.removeEventListener('message', onMsg); res(d.result); }
    };
    ws.addEventListener('message', onMsg);
    ws.send(JSON.stringify({ id, method, params }));
  });
  ws.addEventListener('message', ev => {
    const d = JSON.parse(ev.data);
    if (d.method === 'Runtime.consoleAPICalled') {
      const line = d.params.args.map(a => a.value !== undefined ? a.value : a.description).join(' ');
      if (/ERROR:SCRIPT|ERROR:GAMEOBJECT|ERROR:GUI|ERROR:ENGINE|stack traceback|attempt to (index|call|perform|compare|concatenate)/.test(line)) {
        errors++;
        console.log('[lua-err]', line.trim());
      } else if (process.env.SMOKE_VERBOSE) console.log('[console]', line.trim());
    } else if (d.method === 'Runtime.exceptionThrown') {
      errors++;
      const ex = d.params.exceptionDetails;
      console.error('[js-err]', ex.text, ex.exception && ex.exception.description);
    }
  });

  await new Promise(r => ws.addEventListener('open', r));
  await cdp('Runtime.enable');
  await cdp('Emulation.setDeviceMetricsOverride', { width: VW, height: VH, deviceScaleFactor: 1, mobile: false });

  const shot = async name => {
    const s = await cdp('Page.captureScreenshot', { format: 'png' });
    const p = path.join(OUT, `${name}_${VW}x${VH}.png`);
    fs.writeFileSync(p, Buffer.from(s.data, 'base64'));
    console.log('shot:', p);
  };
  const evalJs = async expr => {
    const r = await cdp('Runtime.evaluate', { expression: expr, returnByValue: true, awaitPromise: true });
    return r && r.result ? r.result.value : undefined;
  };
  const mouse = (type, x, y) => cdp('Input.dispatchMouseEvent', { type, x, y, button: 'left', clickCount: 1 });
  const KEYS = {
    Escape: 27, Space: 32, ArrowLeft: 37, ArrowUp: 38, ArrowRight: 39, ArrowDown: 40, Enter: 13,
    F7: 118, F8: 119, F9: 120, F10: 121, KeyQ: 81, KeyA: 65, KeyD: 68, KeyW: 87, Digit1: 49, Digit2: 50, Backspace: 8,
  };
  const key = async (name, type) => {
    const code = KEYS[name] || name.toUpperCase().charCodeAt(0);
    await cdp('Input.dispatchKeyEvent', { type, key: name === 'Space' ? ' ' : name, code: name, windowsVirtualKeyCode: code, nativeVirtualKeyCode: code });
  };
  const setHidden = hidden => evalJs(`(function(){
    Object.defineProperty(document, 'hidden', { configurable: true, get: function(){ return ${hidden}; } });
    Object.defineProperty(document, 'visibilityState', { configurable: true, get: function(){ return '${hidden ? 'hidden' : 'visible'}'; } });
    document.dispatchEvent(new Event('visibilitychange'));
    return document.visibilityState;
  })()`);

  if (!opt.steps) {
    await sleep(Number(opt.secs) * 1000);
    await shot('boot');
  } else {
    for (const step of opt.steps.split(';').filter(Boolean)) {
      const idx = step.indexOf(':');
      const cmd = idx < 0 ? step : step.slice(0, idx);
      const arg = idx < 0 ? '' : step.slice(idx + 1);
      const n = arg.split(',').map(Number);
      if (cmd === 'wait') await sleep(n[0] * 1000);
      else if (cmd === 'shot') await shot(arg || 'step');
      else if (cmd === 'click') {
        await mouse('mouseMoved', n[0], n[1]);
        await mouse('mousePressed', n[0], n[1]);
        await sleep(90);
        await mouse('mouseReleased', n[0], n[1]);
        await sleep(150);
      } else if (cmd === 'drag') {
        await mouse('mouseMoved', n[0], n[1]);
        await mouse('mousePressed', n[0], n[1]);
        for (let k = 1; k <= 10; k++) {
          await sleep(30);
          await mouse('mouseMoved', n[0] + (n[2] - n[0]) * k / 10, n[1] + (n[3] - n[1]) * k / 10);
        }
        await sleep(120);
        await mouse('mouseReleased', n[2], n[3]);
        await sleep(150);
      } else if (cmd === 'press') {
        await mouse('mouseMoved', n[0], n[1]);
        await mouse('mousePressed', n[0], n[1]);
        await sleep(120);
      } else if (cmd === 'move') {
        await mouse('mouseMoved', n[0], n[1]);
        await sleep(120);
      } else if (cmd === 'release') {
        await mouse('mouseReleased', n[0], n[1]);
        await sleep(150);
      } else if (cmd === 'key') {
        await key(arg, 'keyDown'); await sleep(60); await key(arg, 'keyUp'); await sleep(120);
      } else if (cmd === 'hold') {
        const [k, secs] = arg.split(',');
        await key(k, 'keyDown'); await sleep(Number(secs) * 1000); await key(k, 'keyUp');
      } else if (cmd === 'fps') {
        const ms = Number(arg) || 2000;
        const v = await evalJs(`new Promise(resolve => { let n = 0; const t0 = performance.now(); function f(){ n++; if (performance.now() - t0 < ${ms}) requestAnimationFrame(f); else resolve(n / ((performance.now() - t0) / 1000)); } requestAnimationFrame(f); })`);
        console.log('fps:', typeof v === 'number' ? v.toFixed(1) : v);
      } else if (cmd === 'hide') console.log('visibility:', await setHidden(true));
      else if (cmd === 'show') console.log('visibility:', await setHidden(false));
      else if (cmd === 'js') console.log(`js ${arg} =>`, JSON.stringify(await evalJs(arg)));
      else console.error('unknown step', step);
    }
  }
  console.log(`Lua/JS errors: ${errors}`);
  ws.close();
  killBrowser();
  srv.close();
  await sleep(500);
  try { fs.rmSync(userData, { recursive: true, force: true }); } catch {}
  process.exit(errors ? 1 : 0);
});
