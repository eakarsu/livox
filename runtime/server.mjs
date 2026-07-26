import crypto from 'node:crypto';
import http from 'node:http';
import { issueToken, passwordMatches, verifyToken } from './auth.mjs';
import { query, queryJson } from './db.mjs';

const port = Number(process.env.BACKEND_PORT);
if (!Number.isInteger(port)) throw new Error('BACKEND_PORT is required');

function json(res, status, body) {
  res.writeHead(status, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff' });
  res.end(JSON.stringify(body));
}

async function body(req) {
  let raw = '';
  for await (const chunk of req) {
    raw += chunk;
    if (raw.length > 128 * 1024) throw new Error('Request is too large');
  }
  return raw ? JSON.parse(raw) : {};
}

function activeUser(req) {
  const [scheme, token] = String(req.headers.authorization || '').split(' ');
  const payload = scheme === 'Bearer' ? verifyToken(token) : null;
  if (!payload) return null;
  return queryJson(`SELECT row_to_json(u)::text FROM (
    SELECT id,email,name,role FROM runtime_users WHERE id=:'id'::bigint AND active=TRUE
  ) u`, { id: payload.sub });
}

const server = http.createServer(async (req, res) => {
  try {
    const url = new URL(req.url, `http://${req.headers.host || '127.0.0.1'}`);
    if (req.method === 'GET' && url.pathname === '/api/health') {
      query('SELECT 1');
      return json(res, 200, { status: 'ready', service: 'livox-runtime' });
    }
    if (req.method === 'GET' && url.pathname === '/api/auth/demo-credentials') {
      if (process.env.NODE_ENV === 'production') return json(res, 404, { error: 'Not found' });
      const email = process.env.PROVISION_ADMIN_EMAIL || process.env.ADMIN_EMAIL || '';
      const password = process.env.PROVISION_ADMIN_PASSWORD || process.env.ADMIN_PASSWORD || '';
      return email && password ? json(res, 200, { email, password }) : json(res, 503, { error: 'Demo credentials unavailable' });
    }
    if (req.method === 'POST' && url.pathname === '/api/auth/login') {
      const input = await body(req);
      const email = String(input.email || input.username || '').trim().toLowerCase();
      const user = queryJson(`SELECT row_to_json(u)::text FROM (
        SELECT id,email,name,role,password_salt,password_hash FROM runtime_users
        WHERE email=:'email' AND active=TRUE
      ) u`, { email });
      if (!user || !passwordMatches(String(input.password || ''), user.password_salt, user.password_hash)) {
        return json(res, 401, { error: 'Invalid credentials' });
      }
      return json(res, 200, { token: issueToken(user.id), user: { id: user.id, email: user.email, name: user.name, role: user.role } });
    }
    if (req.method === 'GET' && url.pathname === '/api/auth/me') {
      const user = activeUser(req);
      return user ? json(res, 200, { user }) : json(res, 401, { error: 'Unauthorized' });
    }
    if (req.method === 'POST' && url.pathname === '/api/runtime-ai/file-readiness') {
      const user = activeUser(req);
      if (!user) return json(res, 401, { error: 'Unauthorized' });
      const input = await body(req);
      const prompt = String(input.prompt || '').trim();
      if (!prompt || prompt.length > 8000) return json(res, 400, { error: 'Prompt must contain 1 through 8000 characters' });
      const apiKey = process.env.OPENROUTER_API_KEY;
      const model = process.env.OPENROUTER_MODEL;
      const baseUrl = process.env.OPENROUTER_BASE_URL;
      if (!apiKey || !model || !baseUrl) return json(res, 503, { error: 'OpenRouter is not configured' });
      const provider = await fetch(`${baseUrl.replace(/\/$/, '')}/chat/completions`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model,
          temperature: 0.2,
          messages: [
            { role: 'system', content: 'Review an enterprise mobile file-transfer workflow. Return concise security and operational risks, evidence gaps, next actions, uncertainty, and mandatory human approval gates.' },
            { role: 'user', content: prompt },
          ],
        }),
        signal: AbortSignal.timeout(60_000),
      });
      if (!provider.ok) return json(res, 502, { error: `OpenRouter returned ${provider.status}` });
      const payload = await provider.json();
      const content = String(payload?.choices?.[0]?.message?.content || '').trim();
      const receipt = String(payload?.id || provider.headers.get('x-request-id') || '').trim();
      if (!content || !receipt) return json(res, 502, { error: 'OpenRouter returned an incomplete response' });
      const id = crypto.randomUUID();
      query(`INSERT INTO runtime_ai_results
        (id,user_id,feature,prompt,content,provider,model,provider_response_id)
        VALUES(:'id'::uuid,:'user_id'::bigint,'file-readiness',:'prompt',:'content','openrouter',:'model',:'receipt')`,
      { id, user_id: user.id, prompt, content, model, receipt });
      return json(res, 200, { id, content, provider: 'openrouter', model, providerReceipt: { id: receipt } });
    }
    return json(res, 404, { error: 'Not found' });
  } catch (error) {
    console.error(JSON.stringify({ event: 'request_failed', message: error instanceof Error ? error.message : 'unknown' }));
    return json(res, 500, { error: 'Internal server error' });
  }
});

server.listen(port, '127.0.0.1', () => console.log(`Livox runtime API listening on 127.0.0.1:${port}`));
for (const signal of ['SIGINT', 'SIGTERM']) process.on(signal, () => server.close(() => process.exit(0)));
