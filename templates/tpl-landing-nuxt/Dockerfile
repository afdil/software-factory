# Stage 1: Build Nuxt Nitro SSR server
FROM node:22-slim AS builder
RUN corepack enable && corepack prepare pnpm@11 --activate
WORKDIR /app
COPY package.json pnpm-workspace.yaml* pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile || pnpm install
COPY . ./
RUN pnpm run build

# Stage 2: Minimal non-root runtime
FROM node:22-slim AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -r -u 10001 -m appuser

WORKDIR /app
COPY --from=builder /app/.output /app/.output

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=8080

USER appuser
EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -fsS http://127.0.0.1:8080/ || exit 1

CMD ["node", "/app/.output/server/index.mjs"]
