import http from 'node:http';

const port = Number(process.env.FRONTEND_PORT);
const target = Number(process.env.BACKEND_PORT);
const page = '<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Livox Runtime</title></head><body><main><h1>Livox governed runtime</h1><p>Authenticated file-transfer readiness operations are available through the local API.</p></main></body></html>';
const server = http.createServer((req, res) => {
  if (req.url?.startsWith('/api/')) {
    const upstream = http.request({ hostname: '127.0.0.1', port: target, method: req.method, path: req.url, headers: { ...req.headers, host: `127.0.0.1:${target}` } }, (response) => {
      res.writeHead(response.statusCode || 502, response.headers);
      response.pipe(res);
    });
    upstream.on('error', () => { res.writeHead(502); res.end('Upstream unavailable'); });
    req.pipe(upstream);
    return;
  }
  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8', 'Content-Security-Policy': "default-src 'none'; style-src 'unsafe-inline'", 'X-Frame-Options': 'DENY' });
  res.end(page);
});
server.listen(port, '127.0.0.1', () => console.log(`Livox runtime UI listening on 127.0.0.1:${port}`));
for (const signal of ['SIGINT', 'SIGTERM']) process.on(signal, () => server.close(() => process.exit(0)));
