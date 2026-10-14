# Full-stack starter

Laravel 13 API + React 19 / TypeScript / Vite, PostgreSQL 16 and Redis 7, all
run through Docker. The only local requirements are **Docker** and **make**.

> Status: Checkpoint 2 (minimal working structure). Project generation
> (`bin/new-project`), CI and the full usage guide come in later checkpoints.

```bash
make init     # build, install deps from lockfiles, .env + secrets, APP_KEY, start, migrate
make up       # day to day
make check    # lint + format + tests (SQLite and PostgreSQL) + frontend build
make help     # every command
```

- Frontend: http://localhost:5174 (shows API / PostgreSQL / Redis status)
- API health: http://localhost:8080/api/v1/health

See [docs/DECISIONS.md](docs/DECISIONS.md) for the stack decisions and the
differences from the FinanceSystem it was derived from.
