#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
set -a
# shellcheck disable=SC1091
source "$project_dir/.env"
set +a

mode="${1:-start}"
case "$mode" in
  start) ;;
  migrate) exec node "$project_dir/runtime/migrate.mjs" ;;
  check) exec node --test "$project_dir/runtime/auth.test.mjs" ;;
  *) echo 'usage: ./start.sh [start|migrate|check]' >&2; exit 2 ;;
esac

: "${DATABASE_URL:?DATABASE_URL is required}"
: "${BACKEND_PORT:?BACKEND_PORT is required}"
: "${FRONTEND_PORT:?FRONTEND_PORT is required}"
: "${OPENROUTER_API_KEY:?OPENROUTER_API_KEY is required}"
: "${OPENROUTER_MODEL:?OPENROUTER_MODEL is required}"
: "${OPENROUTER_BASE_URL:?OPENROUTER_BASE_URL is required}"
[[ "$BACKEND_PORT" != "$FRONTEND_PORT" ]] || { echo 'BACKEND_PORT and FRONTEND_PORT must differ' >&2; exit 1; }
for port in "$BACKEND_PORT" "$FRONTEND_PORT"; do
  [[ "$port" =~ ^[0-9]+$ ]] && (( port >= 1024 && port <= 65535 )) || { echo 'Invalid assigned port' >&2; exit 1; }
  ! lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1 || { echo "Port $port is occupied" >&2; exit 1; }
done
command -v psql >/dev/null || { echo 'psql is required' >&2; exit 1; }

node "$project_dir/runtime/migrate.mjs"
api_pid=''; ui_pid=''
cleanup() {
  trap - INT TERM EXIT
  [[ -z "$ui_pid" ]] || kill "$ui_pid" 2>/dev/null || true
  [[ -z "$api_pid" ]] || kill "$api_pid" 2>/dev/null || true
  [[ -z "$ui_pid" ]] || wait "$ui_pid" 2>/dev/null || true
  [[ -z "$api_pid" ]] || wait "$api_pid" 2>/dev/null || true
}
trap cleanup INT TERM EXIT
node "$project_dir/runtime/server.mjs" & api_pid=$!
for _ in $(seq 1 240); do
  curl -fsS "http://127.0.0.1:$BACKEND_PORT/api/health" >/dev/null 2>&1 && break
  kill -0 "$api_pid" 2>/dev/null || { wait "$api_pid"; exit $?; }
  sleep 0.25
done
curl -fsS "http://127.0.0.1:$BACKEND_PORT/api/health" >/dev/null
node "$project_dir/runtime/ui.mjs" & ui_pid=$!
wait "$api_pid" "$ui_pid"
