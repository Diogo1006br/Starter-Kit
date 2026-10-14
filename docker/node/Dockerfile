# syntax=docker/dockerfile:1
FROM node:22-alpine

ARG UID=1000
ARG GID=1000
# npm 10.9.9 (bundled with node:22) crashes while resolving vitest's peer set on a
# fresh install ("Cannot read properties of null (reading 'edgesOut')"), so npm is
# pinned to a newer, working release. FinanceSystem uses npm 10.9.8 only because
# its lockfile was already resolved.
ARG NPM_VERSION=11.21.0

# The official image ships a `node` user with UID/GID 1000. Re-map it to the
# host user so bind-mounted files keep the right owner. node_modules/ is a
# named volume (see compose.yaml) and inherits the ownership set here.
RUN npm install -g "npm@${NPM_VERSION}" \
    && apk add --no-cache shadow \
    && (getent group "${GID}" >/dev/null || groupmod -g "${GID}" node) \
    && usermod -u "${UID}" -g "${GID}" node \
    && mkdir -p /app/node_modules && chown -R "${UID}:${GID}" /app /home/node

WORKDIR /app
USER node

EXPOSE 5173
