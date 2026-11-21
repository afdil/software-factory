pub mod config;
pub mod error;
pub mod routes;

use axum::Router;
use sqlx::PgPool;
use tower_http::{compression::CompressionLayer, trace::TraceLayer};
use utoipa::OpenApi;

use crate::config::Config;

#[derive(Clone)]
pub struct AppState {
    pub pool: PgPool,
    pub config: Config,
}

#[derive(OpenApi)]
#[openapi(
    paths(routes::health::health_check),
    components(schemas(
        routes::health::HealthResponse,
        error::ErrorBody,
        error::ErrorDetail
    )),
    tags((name = "system", description = "Service health endpoints"))
)]
pub struct ApiDoc;

pub fn build_router(state: AppState) -> Router {
    Router::new()
        .nest("/api", routes::api_router())
        .layer(CompressionLayer::new())
        .layer(TraceLayer::new_for_http())
        .with_state(state)
}
