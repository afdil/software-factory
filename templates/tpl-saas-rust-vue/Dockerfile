# Stage 1: Build Vue 3 SPA static bundle
FROM node:22-slim AS frontend-builder
RUN corepack enable && corepack prepare pnpm@9 --activate
WORKDIR /app/frontend
COPY frontend/package.json frontend/pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile || pnpm install
COPY frontend/ ./
RUN pnpm run build

# Stage 2: Rust cargo-chef planner
FROM lukemathwalker/cargo-chef:latest-rust-1.85 AS chef
WORKDIR /app/backend

FROM chef AS planner
COPY backend/ ./
RUN cargo chef prepare --recipe-path recipe.json

# Stage 3: Cache Rust crate dependencies & compile release binary
FROM chef AS backend-builder
COPY --from=planner /app/backend/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json
COPY backend/ ./
RUN cargo build --release --bin backend

# Stage 4: Minimal non-root runtime serving Axum API + Vue static files
FROM debian:bookworm-slim AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -r -u 10001 -m appuser

WORKDIR /app
COPY --from=backend-builder /app/backend/target/release/backend /app/backend
COPY --from=frontend-builder /app/frontend/dist /app/dist

ENV PORT=8080
ENV STATIC_DIR=/app/dist
ENV RUST_LOG=info

USER appuser
EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -fsS http://127.0.0.1:8080/api/health || exit 1

CMD ["/app/backend"]
