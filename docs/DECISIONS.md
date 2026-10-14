# Decisions and differences from FinanceSystem

The kit is independent: nothing from FinanceSystem's domain (workspaces,
accounts, cards, transactions, roles, audit) is present.

## Versions actually installed (inside the containers)

| Item | Starter | FinanceSystem (lockfile) |
|---|---|---|
| PHP | 8.3.35 (image `php:8.3-cli-bookworm`) | `^8.3` declared, lock needs >= 8.4.1 |
| Laravel | 13.36.0 | 13.21.1 |
| Sanctum / Tinker | 4.3.3 / 3.0.2 | 4.3.3 / 3.0.2 |
| Pint / PHPUnit | 1.32.1 / 12.5.39 | 1.29.3 / 12.5.31 |
| Symfony components | 7.4.x | 8.1.x |
| phpredis | 6.2.0 | n/a |
| Node / npm | 22.23.3 / 11.21.0 | 22.23.1 / 10.9.8 (host) |
| React / React DOM | 19.3.0 | 19.2.8 |
| TypeScript / Vite / Vitest | 6.0.3 / 8.3.4 / 4.1.11 | 6.0.3 / 8.2.2 / 4.1.11 |
| Tailwind | 4.3.3 | 4.3.3 |

Frontend ranges are the same carets as FinanceSystem, so a fresh resolve picks
newer minors (React 19.3, Vite 8.3). Lockfiles pin what was validated.

## Differences and why

- **Symfony 7.4 instead of 8.1.** Symfony 8 needs PHP >= 8.4.1. The kit stays on
  PHP 8.3 (approved decision), so Composer resolves Symfony 7.4. Observation
  (not executed): FinanceSystem's `composer.lock` pins Symfony 8.1 while its CI
  uses PHP 8.3, so its CI `composer install` would be expected to fail.
- **npm pinned to 11.21.0.** npm 10.9.9 (bundled with `node:22`) crashes on a
  fresh install of this dependency set (`Cannot read properties of null
  (reading 'edgesOut')` while resolving vitest's peers). Reproduced, and npm 11
  fixes it. FinanceSystem avoids it only because its lockfile is already resolved.
- **TypeScript `strict: true`** (FinanceSystem does not enable it); `tests/` is
  type-checked by `tsc -b` too.
- **Single env file.** The root `.env` feeds compose, which injects values into
  the containers (`DB_HOST=postgres`, `REDIS_HOST=redis`). `backend/.env` is an
  empty placeholder (Laravel/phpdotenv expect the file).
- **Redis requires a password;** secrets are generated per machine by
  `bin/setup-env`, never committed.
- **Test database** `<DB_DATABASE>_test` is created automatically on first
  start of the Postgres volume (FinanceSystem: manual).
- **Test isolation.** `phpunit*.xml` set every variable as `<env>` *and*
  `<server>` with `force`, because Laravel reads `$_SERVER` first and the
  container environment (pgsql, redis) would otherwise leak into tests.
  `tests/TestCase.php` refuses to run on a non-SQLite database not ending in
  `_test`. `failOnWarning` is on, so warnings cannot hide behind exit code 0.
- **PostgreSQL tests use `vendor/bin/phpunit` directly**, not `artisan test
  --configuration=...` (Collision adds its own `--configuration`, which clashes).
- **`laravel/pao`, Pest/php-http plugin allowances, AI-agent guideline files
  (`AGENTS.md`, `CLAUDE.md`), the backend `package.json`/Vite/AWS leftovers
  were removed** from the Laravel skeleton (API-only backend).
- **Bearer tokens only** (`statefulApi()` is not enabled), as in FinanceSystem's
  actual behavior.
- Ports default to 8080 / 5174 / 5440 / 6390 so the kit can run beside
  FinanceSystem (8000 / 5173 / 5433 / 6379). Postgres and Redis publish on
  127.0.0.1 only.
- `vendor/` and `node_modules/` live in named volumes (fast on macOS, no mixing
  host and container binaries). Consequence: no `vendor/` on the host for IDE
  indexing.

## Not done yet (later checkpoints)

`bin/new-project` and name-safe generation, MUI add-on (`--with-mui`), CI
workflow, frontend-swap contract doc, usage guide.
