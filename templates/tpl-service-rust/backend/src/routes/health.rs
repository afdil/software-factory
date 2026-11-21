use axum::{extract::State, http::StatusCode, Json};
use serde::Serialize;
use utoipa::ToSchema;

use crate::AppState;

#[derive(Debug, Serialize, ToSchema)]
pub struct HealthResponse {
    pub status: String,
    pub db: String,
}

#[utoipa::path(
    get,
    path = "/api/health",
    responses(
        (status = 200, description = "Service and database healthy", body = HealthResponse),
        (status = 503, description = "Database unavailable", body = HealthResponse)
    ),
    tag = "system"
)]
pub async fn health_check(State(state): State<AppState>) -> (StatusCode, Json<HealthResponse>) {
    match sqlx::query_scalar::<_, i32>("SELECT 1")
        .fetch_one(&state.pool)
        .await
    {
        Ok(_) => (
            StatusCode::OK,
            Json(HealthResponse {
                status: "ok".to_string(),
                db: "ok".to_string(),
            }),
        ),
        Err(err) => {
            tracing::error!(error = %err, "Health check DB ping failed");
            (
                StatusCode::SERVICE_UNAVAILABLE,
                Json(HealthResponse {
                    status: "degraded".to_string(),
                    db: "error".to_string(),
                }),
            )
        }
    }
}
