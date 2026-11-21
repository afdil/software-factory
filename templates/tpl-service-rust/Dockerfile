# Stage 1: cargo-chef planner
FROM lukemathwalker/cargo-chef:latest-rust-1.85 AS chef
WORKDIR /app/backend

FROM chef AS planner
COPY backend/ ./
RUN cargo chef prepare --recipe-path recipe.json

# Stage 2: Cache dependencies & build release binary
FROM chef AS builder
COPY --from=planner /app/backend/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json
COPY backend/ ./
RUN cargo build --release --bin service

# Stage 3: Minimal non-root runtime
FROM debian:bookworm-slim AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -r -u 10001 -m appuser

WORKDIR /app
COPY --from=builder /app/backend/target/release/service /app/service

ENV PORT=8080
ENV RUST_LOG=info

USER appuser
EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -fsS http://127.0.0.1:8080/api/health || exit 1

CMD ["/app/service"]
