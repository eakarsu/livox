import { hashPassword } from './auth.mjs';
import { query } from './db.mjs';

const email = String(process.env.PROVISION_ADMIN_EMAIL || process.env.ADMIN_EMAIL || '').trim().toLowerCase();
const password = String(process.env.PROVISION_ADMIN_PASSWORD || process.env.ADMIN_PASSWORD || '');
const name = String(process.env.PROVISION_ADMIN_NAME || 'Runtime Administrator').trim();
if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || password.length < 16 || name.length < 2) {
  throw new Error('A valid administrator email, name, and 16+ character password are required');
}

query(`
  CREATE TABLE IF NOT EXISTS runtime_users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(254) NOT NULL UNIQUE,
    name VARCHAR(160) NOT NULL,
    password_salt VARCHAR(64) NOT NULL,
    password_hash VARCHAR(128) NOT NULL,
    role VARCHAR(32) NOT NULL CHECK (role='ADMIN'),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );
  CREATE TABLE IF NOT EXISTS runtime_ai_results (
    id UUID PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES runtime_users(id),
    feature VARCHAR(64) NOT NULL,
    prompt TEXT NOT NULL,
    content TEXT NOT NULL,
    provider VARCHAR(32) NOT NULL CHECK (provider='openrouter'),
    model VARCHAR(160) NOT NULL,
    provider_response_id VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );
  CREATE INDEX IF NOT EXISTS runtime_ai_results_user_created_idx
    ON runtime_ai_results(user_id, created_at DESC);
`);

const credentials = hashPassword(password);
query(`
  INSERT INTO runtime_users(email,name,password_salt,password_hash,role,active)
  VALUES(:'email',:'name',:'salt',:'hash','ADMIN',TRUE)
  ON CONFLICT(email) DO UPDATE SET
    name=EXCLUDED.name,password_salt=EXCLUDED.password_salt,password_hash=EXCLUDED.password_hash,
    role='ADMIN',active=TRUE,updated_at=NOW();
`, { email, name, salt: credentials.salt, hash: credentials.hash });
console.log('Livox runtime schema and administrator are ready');
