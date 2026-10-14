#!/usr/bin/env bash
# Tests for bin/new-project. Run from anywhere: bash tests/new-project.sh
#
# Safe by construction: it works on a throwaway `git clone` of the starter inside a
# temp dir, never starts containers, never touches volumes or the running stack.
# `docker compose config` (render only, no daemon needed) is used when available.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/new-project-test.XXXXXX")"
LISTENERS=()
pass=0 fail=0

cleanup() {
  local pid
  for pid in ${LISTENERS[@]+"${LISTENERS[@]}"}; do kill "$pid" 2>/dev/null; done
  rm -rf "$WORK"
}
trap cleanup EXIT

ok()  { pass=$((pass + 1)); echo "  ok   $1"; }
bad() { fail=$((fail + 1)); echo "  FAIL $1"; [ -z "${2:-}" ] || echo "       $2"; }
check() { # description command...
  local d="$1"; shift
  if "$@" >/dev/null 2>&1; then ok "$d"; else bad "$d"; fi
}
check_not() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then bad "$d"; else ok "$d"; fi; }
eq() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected '$3', got '$2'"; fi; }

# --- fixture: disposable clone of the committed starter + the script under test ---
CLONE="$WORK/starter"
git clone -q "$ROOT" "$CLONE"
mkdir -p "$CLONE/bin"
cp "$ROOT/bin/new-project" "$CLONE/bin/new-project"
NP="$CLONE/bin/new-project"

# Sensitive/local files force-added to the index, so only the denylist can stop them.
mkdir -p "$CLONE/backend/vendor/x" "$CLONE/frontend/node_modules/x" "$CLONE/frontend/dist" \
         "$CLONE/backend/storage/logs" "$CLONE/backend/database"
echo SECRET_ROOT_ENV > "$CLONE/.env"
echo SECRET_BACKEND_ENV > "$CLONE/backend/.env"
echo SECRET_ENV_LOCAL > "$CLONE/frontend/.env.local"
echo x > "$CLONE/backend/vendor/x/a.php"
echo x > "$CLONE/frontend/node_modules/x/a.js"
echo x > "$CLONE/frontend/dist/index.js"
echo x > "$CLONE/backend/storage/logs/laravel.log"
echo x > "$CLONE/backend/database/database.sqlite"
echo x > "$CLONE/backend/.phpunit.result.cache"
echo x > "$CLONE/frontend/tsconfig.app.tsbuildinfo"
git -C "$CLONE" add -f .env backend/.env frontend/.env.local backend/vendor frontend/node_modules \
  frontend/dist backend/storage/logs/laravel.log backend/database/database.sqlite \
  backend/.phpunit.result.cache frontend/tsconfig.app.tsbuildinfo
# Untracked and unignored stray file: must not be copied either (only tracked files are).
echo x > "$CLONE/stray-notes.txt"

gen() { "$NP" "$@" >"$WORK/out.txt" 2>&1; }  # stdout+stderr in $WORK/out.txt
free_port() {
  python3 -I -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1])'
}
listen_on() { # port
  python3 -I -c '
import socket, sys, time
s = socket.socket(); s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(("127.0.0.1", int(sys.argv[1]))); s.listen(); time.sleep(120)' "$1" &
  LISTENERS+=("$!"); disown "$!"
  sleep 0.5
}
envval() { grep -E "^$2=" "$1" | head -n1 | cut -d= -f2-; }

echo "name validation"
for bad_name in "Bad" "1abc" "a" "my_app" "my--app" "-x" "x-" "../x" "a b" 'a$(id)' "a;b" 'a`b' "UPPER" \
                "$(printf 'a%.0s' $(seq 1 41))"; do
  gen "$bad_name" --dir "$WORK/bad-out"
  rc=$?
  if [ "$rc" -ne 0 ] && [ ! -e "$WORK/bad-out" ]; then ok "rejects '$bad_name'"; else bad "rejects '$bad_name'" "rc=$rc"; fi
done
gen; rc=$?; if [ "$rc" -ne 0 ]; then ok "name is required"; else bad "name is required"; fi
gen ok-name --bogus; rc=$?; if [ "$rc" -ne 0 ]; then ok "unknown option rejected"; else bad "unknown option rejected"; fi

echo "destination"
mkdir "$WORK/exists"; echo keep > "$WORK/exists/marker"
gen app-one --dir "$WORK/exists"; rc=$?
if [ "$rc" -ne 0 ] && grep -q "already exists" "$WORK/out.txt" && [ "$(cat "$WORK/exists/marker")" = keep ] \
   && [ "$(ls "$WORK/exists")" = marker ]; then ok "existing directory is refused and untouched"; else bad "existing directory is refused and untouched"; fi
ln -s "$WORK/exists" "$WORK/link"
gen app-one --dir "$WORK/link"; rc=$?
if [ "$rc" -ne 0 ]; then ok "existing symlink is refused"; else bad "existing symlink is refused"; fi
gen app-one --dir "$WORK/no-parent/app-one"; rc=$?
if [ "$rc" -ne 0 ] && [ ! -e "$WORK/no-parent" ]; then ok "missing parent is refused, nothing created"; else bad "missing parent is refused"; fi
gen app-one --dir "$CLONE/inside"; rc=$?
if [ "$rc" -ne 0 ] && [ ! -e "$CLONE/inside" ]; then ok "destination inside the starter is refused"; else bad "destination inside the starter is refused"; fi
gen app-one; rc=$?
if [ "$rc" -eq 0 ] && [ -d "$WORK/app-one" ]; then ok "default destination is a sibling of the starter"; else bad "default destination is a sibling of the starter" "rc=$rc"; fi
rm -rf "$WORK/app-one"

echo "ports: validation"
for p in 80 1023 65536 70000 abc 0 08080 -1 "80 80" ""; do
  gen port-test --dir "$WORK/port-out" --backend-port "$p"; rc=$?
  if [ "$rc" -ne 0 ] && [ ! -e "$WORK/port-out" ]; then ok "rejects port '$p' before creating anything"; else bad "rejects port '$p'" "rc=$rc"; fi
done
gen port-test --dir "$WORK/port-out" --backend-port 9100 --frontend-port 9100; rc=$?
if [ "$rc" -ne 0 ] && [ ! -e "$WORK/port-out" ] && grep -q "more than one service" "$WORK/out.txt"; then ok "duplicate ports are rejected"; else bad "duplicate ports are rejected"; fi
busy="$(free_port)"; listen_on "$busy"
gen port-test --dir "$WORK/port-out" --redis-port "$busy"; rc=$?
if [ "$rc" -ne 0 ] && [ ! -e "$WORK/port-out" ] && grep -q "already in use" "$WORK/out.txt"; then ok "occupied explicit port is rejected"; else bad "occupied explicit port is rejected" "rc=$rc"; fi

echo "ports: automatic selection"
gen auto-app --dry-run; a="$(grep '^Ports:' "$WORK/out.txt")"
gen auto-app --dry-run; b="$(grep '^Ports:' "$WORK/out.txt")"
eq "automatic ports are deterministic for a name" "$a" "$b"
gen other-app --dry-run; c="$(grep '^Ports:' "$WORK/out.txt")"
if [ "$a" != "$c" ]; then ok "different names get different ports"; else bad "different names get different ports" "$a"; fi
gen auto-app --dry-run; auto_be="$(grep '^Ports:' "$WORK/out.txt" | sed 's/.*backend=\([0-9]*\).*/\1/')"
listen_on "$auto_be"
gen auto-app --dry-run; d="$(grep '^Ports:' "$WORK/out.txt")"
if [ "$a" != "$d" ] && ! grep -q "backend=$auto_be " "$WORK/out.txt"; then ok "automatic selection skips an occupied port"; else bad "automatic selection skips an occupied port" "$d"; fi
n=0; for v in $(grep '^Ports:' "$WORK/out.txt" | grep -o '[0-9]\{4,5\}'); do n=$((n + 1)); done
uniq_n="$(grep '^Ports:' "$WORK/out.txt" | grep -o '[0-9]\{4,5\}' | sort -u | wc -l | tr -d ' ')"
eq "the four automatic ports are distinct" "$uniq_n" "4"
gen auto-app --dry-run; if [ ! -e "$WORK/auto-app" ]; then ok "--dry-run creates nothing"; else bad "--dry-run creates nothing"; fi

echo "generation"
P1="$WORK/proj-one"
gen proj-one --dir "$P1" --backend-port 9201 --frontend-port 9202 --postgres-port 9203 --redis-port 9204; rc=$?
eq "generation succeeds" "$rc" "0"
for f in .env.example backend/composer.json frontend/package.json compose.yaml Makefile bin/setup-env \
         backend/storage/logs/.gitignore backend/bootstrap/cache/.gitignore frontend/public/favicon.svg; do
  check "copies $f" test -e "$P1/$f"
done
for f in .env.example; do check "keeps $f" test -f "$P1/$f"; done

echo "exclusions"
for f in backend/.env frontend/.env.local backend/vendor frontend/node_modules frontend/dist \
         backend/storage/logs/laravel.log backend/database/database.sqlite backend/.phpunit.result.cache \
         frontend/tsconfig.app.tsbuildinfo stray-notes.txt bin/new-project tests docs; do
  check_not "does not copy $f" test -e "$P1/$f"
done
check_not "template secret is not in the generated tree" grep -rqE 'SECRET_(ROOT|BACKEND)_ENV|SECRET_ENV_LOCAL' "$P1"
check_not "no template .git history carried over" test -n "$(git -C "$P1" rev-list --all 2>/dev/null)"

echo "rename"
check_not "no 'starter' left (any case) in the generated tree" grep -rIiq starter "$P1" --exclude-dir=.git
eq "COMPOSE_PROJECT_NAME" "$(envval "$P1/.env" COMPOSE_PROJECT_NAME)" "proj-one"
eq "APP_NAME" "$(envval "$P1/.env" APP_NAME)" '"Proj One"'
check "composer name" grep -q '"name": "proj-one/app"' "$P1/backend/composer.json"
check "package name" grep -q '"name": "proj-one-frontend"' "$P1/frontend/package.json"
eq "package-lock only differs by the two name lines" \
  "$(diff "$CLONE/frontend/package-lock.json" "$P1/frontend/package-lock.json" | grep -c '^[<>]')" "4"
eq "composer.json only differs by name and description" \
  "$(diff "$CLONE/backend/composer.json" "$P1/backend/composer.json" | grep -c '^[<>]')" "4"
eq "package.json only differs by name" \
  "$(diff "$CLONE/frontend/package.json" "$P1/frontend/package.json" | grep -c '^[<>]')" "2"
check "index.html title" grep -q '<title>Proj One</title>' "$P1/frontend/index.html"
check "compose.yaml is unchanged" cmp -s "$CLONE/compose.yaml" "$P1/compose.yaml"
check "Makefile is unchanged" cmp -s "$CLONE/Makefile" "$P1/Makefile"

echo "configuration"
eq "BACKEND_PORT" "$(envval "$P1/.env" BACKEND_PORT)" "9201"
eq "FRONTEND_PORT" "$(envval "$P1/.env" FRONTEND_PORT)" "9202"
eq "POSTGRES_HOST_PORT" "$(envval "$P1/.env" POSTGRES_HOST_PORT)" "9203"
eq "REDIS_HOST_PORT" "$(envval "$P1/.env" REDIS_HOST_PORT)" "9204"
eq "APP_URL follows the backend port" "$(envval "$P1/.env" APP_URL)" "http://localhost:9201"
eq "frontend/.env.example API URL" "$(envval "$P1/frontend/.env.example" VITE_API_BASE_URL)" "http://localhost:9201/api/v1"
check "secrets are blank before init" test -z "$(envval "$P1/.env" DB_PASSWORD)$(envval "$P1/.env" REDIS_PASSWORD)$(envval "$P1/.env" APP_KEY)"
check ".env is git-ignored" git -C "$P1" check-ignore -q .env
eq "independent git repo" "$(git -C "$P1" rev-parse --show-toplevel)" "$(cd "$P1" && pwd -P)"
eq "no remotes configured" "$(git -C "$P1" remote | wc -l | tr -d ' ')" "0"

P2="$WORK/proj-two"
gen proj-two --dir "$P2" --no-git; rc=$?
eq "second project generated with automatic ports" "$rc" "0"
check_not "--no-git skips git init" test -e "$P2/.git"

echo "isolation of two generated projects"
(cd "$P1" && ./bin/setup-env >/dev/null) && (cd "$P2" && ./bin/setup-env >/dev/null)
s1="$(envval "$P1/.env" DB_PASSWORD)"; s2="$(envval "$P2/.env" DB_PASSWORD)"
if [ -n "$s1" ] && [ "$s1" != "$s2" ]; then ok "database passwords are generated per project"; else bad "database passwords differ"; fi
r1="$(envval "$P1/.env" REDIS_PASSWORD)"; r2="$(envval "$P2/.env" REDIS_PASSWORD)"
if [ -n "$r1" ] && [ "$r1" != "$r2" ]; then ok "redis passwords are generated per project"; else bad "redis passwords differ"; fi
check_not "template passwords are not reused" grep -q "SECRET_" "$P1/.env"
ports1="$(for k in BACKEND FRONTEND; do envval "$P1/.env" ${k}_PORT; done; envval "$P1/.env" POSTGRES_HOST_PORT; envval "$P1/.env" REDIS_HOST_PORT)"
ports2="$(for k in BACKEND FRONTEND; do envval "$P2/.env" ${k}_PORT; done; envval "$P2/.env" POSTGRES_HOST_PORT; envval "$P2/.env" REDIS_HOST_PORT)"
eq "no host port is shared between the two projects" "$(printf '%s\n%s\n' "$ports1" "$ports2" | sort | uniq -d | wc -l | tr -d ' ')" "0"

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  c1="$(cd "$P1" && docker compose config 2>&1)"; rc1=$?
  c2="$(cd "$P2" && docker compose config 2>&1)"; rc2=$?
  eq "docker compose config renders project one" "$rc1" "0"
  eq "docker compose config renders project two" "$rc2" "0"
  check_not "no fixed container_name" grep -q container_name <<<"$c1$c2"
  eq "compose project name 1" "$(sed -n 's/^name: //p' <<<"$c1")" "proj-one"
  eq "compose project name 2" "$(sed -n 's/^name: //p' <<<"$c2")" "proj-two"
  check "volumes are namespaced by project" grep -q 'name: proj-one_postgres_data' <<<"$c1"
  check "networks are namespaced by project" grep -q 'name: proj-one_default' <<<"$c1"
  check "images are namespaced by project" grep -q 'image: proj-one-php' <<<"$c1"
  check_not "project one does not mention project two" grep -q 'proj-two' <<<"$c1"
  check_not "project two does not mention project one" grep -q 'proj-one' <<<"$c2"
  check "CORS follows the frontend port" grep -q 'CORS_ALLOWED_ORIGINS: http://localhost:9202,http://127.0.0.1:9202' <<<"$c1"
  check "frontend gets the backend port in VITE_API_BASE_URL" grep -q 'VITE_API_BASE_URL: http://localhost:9201/api/v1' <<<"$c1"
  check "published ports match" grep -q 'published: "9201"' <<<"$c1"
else
  echo "  skip docker compose config checks (docker compose not available)"
fi

echo
echo "passed: $pass  failed: $fail"
[ "$fail" -eq 0 ]
