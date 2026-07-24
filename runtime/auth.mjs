import crypto from 'node:crypto';

export function hashPassword(password, salt = crypto.randomBytes(16).toString('base64url')) {
  return { salt, hash: crypto.scryptSync(password, salt, 32).toString('base64url') };
}

export function passwordMatches(password, salt, expectedHash) {
  const actual = Buffer.from(hashPassword(password, salt).hash);
  const expected = Buffer.from(expectedHash || '');
  return actual.length === expected.length && crypto.timingSafeEqual(actual, expected);
}

function signingSecret() {
  const secret = process.env.JWT_SECRET || process.env.SESSION_SECRET;
  if (!secret || Buffer.byteLength(secret) < 32) throw new Error('JWT_SECRET must be at least 32 bytes');
  return secret;
}

export function issueToken(userId) {
  const encoded = Buffer.from(JSON.stringify({ sub: String(userId), exp: Math.floor(Date.now() / 1000) + 900 })).toString('base64url');
  const signature = crypto.createHmac('sha256', signingSecret()).update(encoded).digest('base64url');
  return `${encoded}.${signature}`;
}

export function verifyToken(token) {
  const [encoded, suppliedSignature] = String(token || '').split('.');
  if (!encoded || !suppliedSignature) return null;
  const expectedSignature = crypto.createHmac('sha256', signingSecret()).update(encoded).digest('base64url');
  const actual = Buffer.from(suppliedSignature);
  const expected = Buffer.from(expectedSignature);
  if (actual.length !== expected.length || !crypto.timingSafeEqual(actual, expected)) return null;
  try {
    const payload = JSON.parse(Buffer.from(encoded, 'base64url').toString('utf8'));
    return payload.sub && payload.exp > Math.floor(Date.now() / 1000) ? payload : null;
  } catch {
    return null;
  }
}
