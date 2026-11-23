// Minimal static server for the Defold HTML5 bundle.
// Usage: node tools/serve.js <bundle_dir> [port]
const http = require('http');
const fs = require('fs');
const path = require('path');

const root = path.resolve(process.argv[2] || 'build/web');
const port = Number(process.argv[3] || 8080);

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript',
  '.wasm': 'application/wasm',
  '.css': 'text/css',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.json': 'application/json',
  '.ogg': 'audio/ogg',
  '.wav': 'audio/wav',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.data': 'application/octet-stream',
  '.arcd': 'application/octet-stream',
  '.arci': 'application/octet-stream',
  '.zip': 'application/zip',
};

const server = http.createServer((req, res) => {
  const url = decodeURIComponent((req.url || '/').split('?')[0]);
  const rel = url === '/' ? '/index.html' : url;
  const file = path.resolve(path.join(root, rel));
  if (!file.startsWith(root) || !fs.existsSync(file) || !fs.statSync(file).isFile()) {
    res.writeHead(404);
    res.end('not found');
    return;
  }
  res.writeHead(200, {
    'Content-Type': MIME[path.extname(file)] || 'application/octet-stream',
    'Cache-Control': 'no-store',
  });
  fs.createReadStream(file).pipe(res);
});

server.listen(port, '127.0.0.1', () => {
  console.log(`serving ${root} at http://127.0.0.1:${port}/`);
});
