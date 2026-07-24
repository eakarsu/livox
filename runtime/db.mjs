import { spawnSync } from 'node:child_process';

export function query(sql, variables = {}) {
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) throw new Error('DATABASE_URL is required');
  const args = ['-X', databaseUrl, '--set=ON_ERROR_STOP=1', '--no-align', '--tuples-only', '--quiet'];
  for (const [name, value] of Object.entries(variables)) args.push('--set', `${name}=${String(value)}`);
  const result = spawnSync('psql', args, { input: sql, encoding: 'utf8', maxBuffer: 4 * 1024 * 1024 });
  if (result.status !== 0) throw new Error(`Database query failed: ${(result.stderr || '').trim().slice(0, 400)}`);
  return result.stdout.trim();
}

export function queryJson(sql, variables = {}) {
  const output = query(sql, variables);
  return output ? JSON.parse(output.split('\n')[0]) : null;
}
