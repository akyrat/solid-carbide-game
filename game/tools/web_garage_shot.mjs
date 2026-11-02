// Browser screenshots of the Web export's menu and garage (T-511). Usage:
//   node game/tools/web_garage_shot.mjs <export dir> <out dir> [--chrome PATH] [--port N]
// Serves the export, clicks once, shoots the main menu, presses Down + Enter (Garage), shoots the garage.
import http from "node:http"; import fs from "node:fs"; import path from "node:path"; import { spawn } from "node:child_process";
const args = process.argv.slice(2), dir = args[0], out = args[1];
const opt = (n, d) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : d; };
const chrome = opt("--chrome", "C:/Program Files/Google/Chrome/Application/chrome.exe");
const port = +opt("--port", 8199), dbg = port + 1;
const types = { ".html": "text/html", ".js": "text/javascript", ".wasm": "application/wasm", ".png": "image/png" };
const srv = http.createServer((q, r) => {
  const f = path.join(dir, decodeURIComponent(q.url.split("?")[0]).replace(/^\/$/, "/index.html"));
  if (!fs.existsSync(f)) { r.writeHead(404); return r.end(); }
  r.writeHead(200, { "content-type": types[path.extname(f)] || "application/octet-stream" }); fs.createReadStream(f).pipe(r);
}).listen(port);
const prof = fs.mkdtempSync(path.join(process.env.TEMP || "/tmp", "wgs-"));
const proc = spawn(chrome, ["--headless=new", `--remote-debugging-port=${dbg}`, `--user-data-dir=${prof}`, "--window-size=1280,720",
  "--no-first-run", "--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "about:blank"], { stdio: "ignore" });
const sleep = ms => new Promise(r => setTimeout(r, ms));
let ws, id = 0; const pend = {};
const send = (m, p = {}) => new Promise(r => { const i = ++id; pend[i] = r; ws.send(JSON.stringify({ id: i, method: m, params: p })); });
const shot = async n => fs.writeFileSync(path.join(out, n), Buffer.from((await send("Page.captureScreenshot")).result.data, "base64"));
const key = async (k, c) => { for (const t of ["keyDown", "keyUp"]) await send("Input.dispatchKeyEvent", { type: t, key: k, code: k, windowsVirtualKeyCode: c }); await sleep(800); };
try {
  fs.mkdirSync(out, { recursive: true });
  let list;
  for (let i = 0; i < 50; i++) { try { list = await (await fetch(`http://127.0.0.1:${dbg}/json`)).json(); break; } catch { await sleep(200); } }
  ws = new WebSocket(list.find(t => t.type === "page").webSocketDebuggerUrl);
  await new Promise(r => ws.onopen = r);
  ws.onmessage = m => { const d = JSON.parse(m.data); if (d.id) pend[d.id]?.(d); };
  await send("Page.enable");
  await send("Page.navigate", { url: `http://127.0.0.1:${port}/index.html` });
  await sleep(15000);
  for (const t of ["mousePressed", "mouseReleased"]) await send("Input.dispatchMouseEvent", { type: t, x: 5, y: 5, button: "left", clickCount: 1 });
  await sleep(3000); await shot("menu.png");
  await key("ArrowDown", 40); await key("Enter", 13); await sleep(2500); await shot("garage.png");
  console.log("done");
} finally { proc.kill(); srv.close(); try { fs.rmSync(prof, { recursive: true, force: true }); } catch {} process.exit(0); }
