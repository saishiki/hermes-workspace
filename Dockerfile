# syntax=docker/dockerfile:1.6
# Hermes Workspace — production Docker image
#
# Build locally:
#   docker build -t hermes-workspace .
#
# Run locally:
#   docker run -p 3000:3000 \
#     -e HERMES_API_URL=http://host.docker.internal:8642 \
#     -e HERMES_API_TOKEN=your_api_server_key \
#     hermes-workspace

# ─── build stage ─────────────────────────────────────────────────────────
FROM node:22-slim AS build

RUN corepack enable \
 && apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install deps first for better layer caching
COPY package.json pnpm-lock.yaml* pnpm-workspace.yaml* ./
RUN pnpm install --frozen-lockfile

# Copy full source and build
COPY . .
RUN pnpm build

# ─── runtime stage ────────────────────────────────────────────────────────
FROM node:22-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl tini \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd -r workspace \
 && useradd -r -g workspace -u 10010 workspace

WORKDIR /app

# Copy runtime artifacts
COPY --from=build --chown=workspace:workspace /app/dist ./dist
COPY --from=build --chown=workspace:workspace /app/node_modules ./node_modules
COPY --from=build --chown=workspace:workspace /app/package.json ./package.json

# Copy skills only if the directory exists in the repo
COPY --from=build --chown=workspace:workspace /app/skills ./skills

USER workspace

ENV NODE_ENV=production \
    PORT=3000 \
    HOST=0.0.0.0 \
    HERMES_API_URL=http://hermes-gateway:8642

EXPOSE 3000

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["node", "--max-old-space-size=2048", "dist/server/server.js"]
