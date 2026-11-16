// Tiny zero-dependency viewer for KANBAN.md.
//   node tools/kanban/server.js [path/to/file.md] [--open]
// Serves the board at http://localhost:4747 and pushes a reload whenever the file changes.
const http = require('http');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const args = process.argv.slice(2);
const mdArg = args.find(a => a.toLowerCase().endsWith('.md'));
const mdPath = path.resolve(mdArg || path.join(__dirname, '..', '..', 'KANBAN.md'));
const port = Number(process.env.PORT) || 4747;
const url = `http://localhost:${port}`;
const clients = new Set();

function openBrowser() {
  if (!args.includes('--open')) return;
  const cmd = process.platform === 'win32' ? `start "" ${url}`
    : process.platform === 'darwin' ? `open ${url}` : `xdg-open ${url}`;
  exec(cmd);
}

const server = http.createServer((req, res) => {
  const route = req.url.split('?')[0];
  if (route === '/') {
    fs.readFile(path.join(__dirname, 'board.html'), (err, data) => {
      if (err) { res.writeHead(500); return res.end(String(err)); }
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store' });
      res.end(data);
    });
  } else if (route === '/kanban.md') {
    fs.readFile(mdPath, 'utf8', (err, data) => {
      if (err) { res.writeHead(404); return res.end(`Cannot read ${mdPath}`); }
      res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8', 'Cache-Control': 'no-store' });
      res.end(data);
    });
  } else if (route === '/events') {
    res.writeHead(200, { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-store', Connection: 'keep-alive' });
    res.write('retry: 1000\n\n');
    clients.add(res);
    req.on('close', () => clients.delete(res));
  } else {
    res.writeHead(404); res.end('Not found');
  }
});

// Watch the folder rather than the file: editors often save by replacing the file.
let timer = null;
const base = path.basename(mdPath).toLowerCase();
fs.watch(path.dirname(mdPath), (event, filename) => {
  if (filename && filename.toLowerCase() !== base) return;
  clearTimeout(timer);
  timer = setTimeout(() => { for (const c of clients) c.write('data: changed\n\n'); }, 80);
});
setInterval(() => { for (const c of clients) c.write(': ping\n\n'); }, 25000);

server.on('error', err => {
  if (err.code === 'EADDRINUSE') {
    console.log(`Port ${port} is already in use; the board is probably already running at ${url}`);
    openBrowser();
    setTimeout(() => process.exit(0), 500);
  } else throw err;
});
server.listen(port, '127.0.0.1', () => {
  console.log(`Kanban board: ${url}\nWatching:     ${mdPath}\nCtrl+C to stop.`);
  openBrowser();
});
