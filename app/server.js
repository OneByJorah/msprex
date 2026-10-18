// Tiny demo app so the template builds, runs, and screenshots end to end.
// Replace this folder with your real project. Keep GET /healthz.
import http from "node:http";

const PORT = Number(process.env.PORT || 8080);
const DEMO = process.env.DEMO_MODE !== "false";
const NAME = process.env.PROJECT_NAME || "Project Name";

const demoData = {
  status: "operational",
  uptime: "14d 06h",
  services: [
    { name: "api", state: "healthy", latencyMs: 12 },
    { name: "worker", state: "healthy", latencyMs: 31 },
    { name: "scheduler", state: "healthy", latencyMs: 8 },
    { name: "cache", state: "degraded", latencyMs: 74 },
  ],
};

const page = () => `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${NAME}</title>
<style>
  :root { --bg:#0a0a09; --card:#141412; --line:#2a2a26; --amber:#FFB300; --text:#e8e6df; --muted:#8a877c; --bad:#ff6b4a; }
  * { box-sizing: border-box; }
  body { margin:0; background:var(--bg); color:var(--text); font-family:"JetBrains Mono",ui-monospace,monospace; padding:48px; }
  h1 { margin:0 0 4px; font-size:28px; color:var(--amber); }
  p.sub { margin:0 0 32px; color:var(--muted); }
  .grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(240px,1fr)); gap:16px; }
  .card { background:var(--card); border:1px solid var(--line); border-radius:8px; padding:20px; }
  .card h2 { margin:0 0 8px; font-size:14px; color:var(--muted); font-weight:500; text-transform:uppercase; letter-spacing:.08em; }
  .big { font-size:26px; }
  .ok { color:var(--amber); } .warn { color:var(--bad); }
</style>
</head>
<body>
<main id="app-ready">
  <h1>${NAME}</h1>
  <p class="sub">Demo data · ${DEMO ? "demo mode on" : "live mode"}</p>
  <div class="grid">
    <div class="card"><h2>Status</h2><div class="big ok">${demoData.status}</div></div>
    <div class="card"><h2>Uptime</h2><div class="big">${demoData.uptime}</div></div>
    ${demoData.services.map((s) => `<div class="card"><h2>${s.name}</h2><div class="big ${s.state === "healthy" ? "ok" : "warn"}">${s.state}</div><div>${s.latencyMs} ms</div></div>`).join("")}
  </div>
</main>
</body>
</html>`;

const server = http.createServer((req, res) => {
  if (req.url === "/healthz") {
    res.writeHead(200, { "content-type": "application/json" });
    res.end(JSON.stringify({ ok: true }));
    return;
  }
  if (req.url === "/" || req.url === "/index.html") {
    res.writeHead(200, { "content-type": "text/html; charset=utf-8" });
    res.end(page());
    return;
  }
  res.writeHead(404, { "content-type": "text/plain" });
  res.end("not found");
});

server.listen(PORT, "0.0.0.0", () => console.log(`${NAME} listening on :${PORT} (demo=${DEMO})`));
