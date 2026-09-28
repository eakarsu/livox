import http from 'node:http';
import crypto from 'node:crypto';

const port = Number(process.env.FRONTEND_PORT);
const target = Number(process.env.BACKEND_PORT);
const nonce = crypto.randomBytes(18).toString('base64');
const page = `<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Livox Runtime</title><style>body{font:16px system-ui;background:#08131f;color:#e7f0fa;min-height:100vh;display:grid;place-items:center;margin:0}main{width:min(420px,calc(100% - 40px));padding:32px;background:#10243a;border-radius:18px}form,label{display:grid;gap:8px}form{gap:14px}input,button{font:inherit;padding:12px;border-radius:9px;border:1px solid #52708f}button{cursor:pointer}.primary{background:#1877d2;color:white}.secondary{background:transparent;color:#dceeff}.error{color:#fecaca}[hidden]{display:none}</style></head><body><main><section id="login"><h1>Livox governed runtime</h1><p>Sign in for authenticated file-transfer readiness operations.</p><form id="login-form"><label>Email<input id="email" type="email" autocomplete="username" required></label><label>Password<input id="password" type="password" autocomplete="current-password" required></label><p id="error" class="error" role="alert"></p><button id="fill" type="button" class="secondary">Auto Fill Demo Credentials</button><button type="submit" class="primary">Sign In</button></form></section><section id="dashboard" hidden><h1>Authenticated File Operations</h1><p id="identity"></p><p>The governed file-transfer readiness dashboard is available.</p></section></main><script nonce="${nonce}">const login=document.querySelector('#login');const dashboard=document.querySelector('#dashboard');const email=document.querySelector('#email');const password=document.querySelector('#password');const error=document.querySelector('#error');document.querySelector('#fill').addEventListener('click',async()=>{error.textContent='';const response=await fetch('/api/auth/demo-credentials');if(!response.ok){error.textContent='Demo credentials are unavailable.';return}const value=await response.json();email.value=value.email;password.value=value.password});document.querySelector('#login-form').addEventListener('submit',async event=>{event.preventDefault();error.textContent='';const response=await fetch('/api/auth/login',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({email:email.value,password:password.value})});if(!response.ok){error.textContent='Sign in failed.';return}const value=await response.json();sessionStorage.setItem('livox_access_token',value.token);document.querySelector('#identity').textContent='Signed in as '+(value.user?.email||email.value);login.hidden=true;dashboard.hidden=false});</script></body></html>`;
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
  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8', 'Content-Security-Policy': `default-src 'none'; style-src 'unsafe-inline'; script-src 'nonce-${nonce}'; connect-src 'self'`, 'X-Frame-Options': 'DENY', 'Cache-Control': 'no-store' });
  res.end(page);
});
server.listen(port, '127.0.0.1', () => console.log(`Livox runtime UI listening on 127.0.0.1:${port}`));
for (const signal of ['SIGINT', 'SIGTERM']) process.on(signal, () => server.close(() => process.exit(0)));
