// Browser check for the Web export's sound (T-476). Usage:
//   node game/tools/web_audio_check.mjs <export dir> [--chrome PATH] [--port N]
// Serves the export over http, opens it in headless Chrome/Edge WITHOUT the autoplay override,
// records every Web Audio context, clicks once, starts a run, and prints the console lines and
// the audio state. Exit 0 when a context is "running" after the click and the page logged the
// "[audio] music playing" and "[audio] engine playing" lines (see game/scripts/game/web_audio_log.gd).
import http from "node:http"; import fs from "node:fs"; import path from "node:path";
import { spawn } from "node:child_process";
import { verdict, sfxEnabledFrom } from "./web_audio_rules.mjs";
const args = process.argv.slice(2);
const dir = args[0];
const opt = (n, d) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : d; };
const chrome = opt("--chrome", "C:/Program Files/Google/Chrome/Application/chrome.exe");
// --sfx on|off overrides; by default sfx_enabled is read from game/data/sfx.json next to this script.
const sfxOpt = opt("--sfx", "");
const sfxOn = sfxOpt ? sfxOpt === "on" : sfxEnabledFrom(fs.readFileSync(new URL("../data/sfx.json", import.meta.url), "utf8"));
const port = +opt("--port", 8099), dbg = port + 1;
const types = { ".html": "text/html", ".js": "text/javascript", ".wasm": "application/wasm", ".png": "image/png" };
const srv = http.createServer((q, r) => {
  const f = path.join(dir, decodeURIComponent(q.url.split("?")[0]).replace(/^\/$/, "/index.html"));
  if (!fs.existsSync(f)) { r.writeHead(404); return r.end(); }
  r.writeHead(200, { "content-type": types[path.extname(f)] || "application/octet-stream" }); fs.createReadStream(f).pipe(r);
}).listen(port);
const prof = fs.mkdtempSync(path.join(process.env.TEMP || "/tmp", "wac-"));
const proc = spawn(chrome, ["--headless=new", `--remote-debugging-port=${dbg}`, `--user-data-dir=${prof}`,
  "--window-size=1280,720", "--no-first-run", "--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "about:blank"], { stdio: "ignore" });
const sleep = ms => new Promise(r => setTimeout(r, ms));
let ws, id = 0; const pend = {}; const logs = [];
const send = (m, p = {}) => new Promise(r => { const i = ++id; pend[i] = r; ws.send(JSON.stringify({ id: i, method: m, params: p })); });
const ev = async e => (await send("Runtime.evaluate", { expression: e, returnByValue: true })).result?.result?.value;
let ok = false;
try {
  let list;
  for (let i = 0; i < 50; i++) { try { list = await (await fetch(`http://127.0.0.1:${dbg}/json`)).json(); break; } catch { await sleep(200); } }
  ws = new WebSocket(list.find(t => t.type === "page").webSocketDebuggerUrl);
  await new Promise(r => ws.onopen = r);
  ws.onmessage = m => { const d = JSON.parse(m.data); if (d.id) pend[d.id]?.(d); else if (d.method === "Runtime.consoleAPICalled") logs.push(d.params.type + ": " + d.params.args.map(a => a.value ?? a.description).join(" ")); else if (d.method === "Runtime.exceptionThrown") logs.push("EXC: " + JSON.stringify(d.params.exceptionDetails.exception?.description)); };
  await send("Runtime.enable"); await send("Page.enable");
  await send("Page.addScriptToEvaluateOnNewDocument", { source: `window.__ctx=[];const AC=window.AudioContext;window.AudioContext=function(...a){const c=new AC(...a);window.__ctx.push(c);return c};window.AudioContext.prototype=AC.prototype;window.__starts=0;const st=AudioBufferSourceNode.prototype.start;AudioBufferSourceNode.prototype.start=function(...a){window.__starts++;try{const b=this.buffer;let m=0;if(b){const d=b.getChannelData(0);for(let i=0;i<d.length;i+=50)m=Math.max(m,Math.abs(d[i]))}console.log('[probe] buffer source start: dur='+(b&&b.duration)+' ch='+(b&&b.numberOfChannels)+' peak='+m+' loop='+this.loop)}catch(e){console.log('[probe] err '+e)}return st.apply(this,a)};window.__gains=[];const oc0=AudioNode.prototype.connect;const GN=window.GainNode;window.GainNode=function(...a){const g=new GN(...a);window.__gains.push(g);return g};window.GainNode.prototype=GN.prototype;const cg=AudioContext.prototype.createGain;AudioContext.prototype.createGain=function(){const g=cg.call(this);window.__gains.push(g);try{const a=this.createAnalyser();a.fftSize=2048;oc0.call(g,a);(window.__gan=window.__gan||[]).push(a)}catch(e){}return g};window.__gpeaks=()=>window.__gan.map(a=>{const d=new Float32Array(a.fftSize);a.getFloatTimeDomainData(d);let m=0;for(const v of d)m=Math.max(m,Math.abs(v));return +m.toFixed(3)});window.__an=[];const oc=AudioNode.prototype.connect;AudioNode.prototype.connect=function(t,...r){const res=oc.call(this,t,...r);(window.__conn=window.__conn||[]).push(this.constructor.name+(this.gain?'('+this.gain.value+')':'')+' -> '+(t&&t.constructor.name)+(t&&t.gain?'('+t.gain.value+')':''));try{if(t&&t===t.context?.destination){const a=t.context.createAnalyser();a.fftSize=2048;oc.call(this,a);window.__an.push(a)}}catch(e){}return res};window.__peak=()=>{let m=0;for(const a of window.__an){const d=new Float32Array(a.fftSize);a.getFloatTimeDomainData(d);for(const v of d)m=Math.max(m,Math.abs(v))}return m};window.__wk=0;const AW=window.AudioWorkletNode;window.AudioWorkletNode=function(...a){window.__wk++;return new AW(...a)};` });
  await send("Page.navigate", { url: `http://127.0.0.1:${port}/index.html` });
  const state = () => ev(`JSON.stringify(window.__ctx.map(c=>c.state))`);
  await sleep(15000);
  console.log("before click, contexts:", await state());
  const click = async () => { for (const t of ["mousePressed", "mouseReleased"]) await send("Input.dispatchMouseEvent", { type: t, x: 5, y: 5, button: "left", clickCount: 1 }); };
  await click(); await sleep(3000);
  console.log("after click, contexts:", await state());
  if (process.env.MENUSHOT) fs.writeFileSync(process.env.MENUSHOT, Buffer.from((await send("Page.captureScreenshot")).result.data, "base64"));
  // Press the Start button (--start x,y; the button's place in the 1280x720 window), then drive.
  const [sx, sy] = opt("--start", "640,360").split(",").map(Number);
  for (const t of ["mousePressed", "mouseReleased"]) await send("Input.dispatchMouseEvent", { type: t, x: sx, y: sy, button: "left", clickCount: 1 });
  await sleep(3000);
  // Then the tutorial's next arrow (--next x,y) until the run starts.
  const [nx, ny] = opt("--next", "1188,297").split(",").map(Number);
  for (let i = 0; i < 4; i++) { for (const t of ["mousePressed", "mouseReleased"]) await send("Input.dispatchMouseEvent", { type: t, x: nx, y: ny, button: "left", clickCount: 1 }); await sleep(1500); }
  for (const t of ["mousePressed", "mouseReleased"]) await send("Input.dispatchMouseEvent", { type: t, x: 684, y: 382, button: "left", clickCount: 1 });  // GO LIVE
  await sleep(3000);
  await send("Input.dispatchKeyEvent", { type: "keyDown", key: "ArrowUp", code: "ArrowUp", windowsVirtualKeyCode: 38 });
  await sleep(5000);
  if (process.env.SHOT) fs.writeFileSync(process.env.SHOT, Buffer.from((await send("Page.captureScreenshot")).result.data, "base64"));
  if (process.env.EVAL) console.log("EVAL:", await ev(process.env.EVAL));
  console.log("final contexts:", await state(), "buffer sources started:", await ev("window.__starts"), "worklet nodes:", await ev("window.__wk"), "output taps:", await ev("window.__an.length"), "output peak:", await ev("window.__peak()"));
  console.log("---- console ----\n" + logs.join("\n"));
  const v = verdict(logs.join("\n"), JSON.parse(await state()), sfxOn);
  ok = v.ok;
  console.log("sfxOn:", sfxOn, "|", v.notes.join("; "));
  console.log("RESULT:", ok ? "PASS" : "FAIL");
} finally { proc.kill(); srv.close(); try { fs.rmSync(prof, { recursive: true, force: true }); } catch {} process.exit(ok ? 0 : 1); }
