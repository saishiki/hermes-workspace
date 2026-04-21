FROM node:22-slim AS build

RUN corepack enable \
 && apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package.json pnpm-lock.yaml* pnpm-workspace.yaml* ./
RUN pnpm install --frozen-lockfile

COPY . .
RUN pnpm build

FROM node:22-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl tini \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd -r workspace \
 && useradd -r -g workspace -u 10010 -m -d /home/workspace workspace \
 && mkdir -p /home/workspace/.hermes \
 && chown -R workspace:workspace /home/workspace

WORKDIR /app

COPY --from=build --chown=workspace:workspace /app/dist ./dist
COPY --from=build --chown=workspace:workspace /app/node_modules ./node_modules
COPY --from=build --chown=workspace:workspace /app/package.json ./package.json
COPY --from=build --chown=workspace:workspace /app/server-entry.js ./server-entry.js
COPY --from=build --chown=workspace:workspace /app/bootstrap.mjs ./bootstrap.mjs
COPY --from=build --chown=workspace:workspace /app/public ./public
COPY --from=build --chown=workspace:workspace /app/skills ./skills

USER workspace

ENV NODE_ENV=production \
    PORT=3000 \
    HOST=0.0.0.0 \
    HOME=/home/workspace \
    HERMES_HOME=/home/workspace/.hermes \
    HERMES_API_URL=http://hermes-gateway:8642 \
    NODE_OPTIONS=--enable-source-maps

EXPOSE 3000

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["node", "--trace-uncaught", "bootstrap.mjs"]
