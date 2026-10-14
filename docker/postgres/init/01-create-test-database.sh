#!/bin/bash
# Runs once, on first initialisation of the data volume. Creates the database
# used by `make test-pg`, kept separate so RefreshDatabase never touches
# development data.
set -euo pipefail

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<SQL
CREATE DATABASE "${POSTGRES_DB}_test" OWNER "${POSTGRES_USER}";
SQL
