pub mod auth;
pub mod config;
pub mod error;
pub mod routes;

use axum::{http::HeaderValue, Router};
use sqlx::PgPool;
use std::path::PathBuf;
use tower_http::{
    compression::CompressionLayer,
    services::{ServeDir, ServeFile},
    set_header::SetResponseHeaderLayer,
    trace::TraceLayer,
};
use utoipa::OpenApi;

use crate::config::Config;

#[derive(Clone)]
pub struct AppState {
    pub pool: PgPool,
    pub config: Config,
}

#[derive(OpenApi)]
#[openapi(
    paths(
        routes::health::health_check,
        auth::register,
        auth::login,
        auth::logout,
        auth::me,
    ),
    components(
        schemas(
            routes::health::HealthResponse,
            auth::RegisterRequest,
            auth::LoginRequest,
            auth::UserResponse,
            error::ErrorBody,
            error::ErrorDetail,
        )
    ),
    tags(
        (name = "system", description = "System health endpoints"),
        (name = "auth", description = "Authentication endpoints")
    )
)]
pub struct ApiDoc;

pub fn build_router(state: AppState) -> Router {
    let static_dir = PathBuf::from(&state.config.static_dir);
    let index_file = static_dir.join("index.html");
    let spa_service = ServeDir::new(&static_dir).not_found_service(ServeFile::new(index_file));

    Router::new()
        .nest("/api", routes::api_router())
        .fallback_service(spa_service)
        .layer(CompressionLayer::new())
        .layer(SetResponseHeaderLayer::if_not_present(
            axum::http::header::X_CONTENT_TYPE_OPTIONS,
            HeaderValue::from_static("nosniff"),
        ))
        .layer(SetResponseHeaderLayer::if_not_present(
            axum::http::header::X_FRAME_OPTIONS,
            HeaderValue::from_static("DENY"),
        ))
        .layer(TraceLayer::new_for_http())
        .with_state(state)
}
