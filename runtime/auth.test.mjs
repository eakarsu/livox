import assert from 'node:assert/strict';
import test from 'node:test';
import { hashPassword, issueToken, passwordMatches, verifyToken } from './auth.mjs';

test('password verification and signed short-lived tokens fail closed', () => {
  process.env.JWT_SECRET = 'test-only-secret-with-more-than-thirty-two-bytes';
  const credential = hashPassword('RuntimeAcceptance123!');
  assert.equal(passwordMatches('RuntimeAcceptance123!', credential.salt, credential.hash), true);
  assert.equal(passwordMatches('wrong', credential.salt, credential.hash), false);
  const token = issueToken('42');
  assert.equal(verifyToken(token)?.sub, '42');
  assert.equal(verifyToken(`${token}x`), null);
});
