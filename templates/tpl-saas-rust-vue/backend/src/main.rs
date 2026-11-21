use std::net::SocketAddr;

use backend::{build_router, config::Config, AppState};
use sqlx::postgres::PgPoolOptions;
use tokio::net::TcpListener;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let _ = dotenvy::dotenv();

    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "info,backend=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer().json())
        .init();

    let config = Config::from_env().map_err(|msg| {
        tracing::error!(error = %msg, "Configuration error");
        msg
    })?;

    let pool = PgPoolOptions::new()
        .max_connections(10)
        .connect(&config.database_url)
        .await?;

    // Auto-run SQLx migrations on startup (Coolify-safe)
    sqlx::migrate!("./migrations").run(&pool).await?;

    let addr = SocketAddr::from(([0, 0, 0, 0], config.port));
    let state = AppState { pool, config };
    let app = build_router(state);

    tracing::info!(%addr, "Server listening");
    let listener = TcpListener::bind(addr).await?;
    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal())
        .await?;

    Ok(())
}

async fn shutdown_signal() {
    let ctrl_c = async {
        let _ = tokio::signal::ctrl_c().await;
    };

    #[cfg(unix)]
    let terminate = async {
        if let Ok(mut sig) =
            tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate())
        {
            sig.recv().await;
        }
    };

    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        _ = ctrl_c => {},
        _ = terminate => {},
    }
    tracing::info!("Shutdown signal received");
}
