pub mod health;

use axum::{routing::get, Router};

use crate::{auth, AppState};

pub fn api_router() -> Router<AppState> {
    Router::new()
        .route("/health", get(health::health_check))
        .nest("/auth", auth::router())
}
