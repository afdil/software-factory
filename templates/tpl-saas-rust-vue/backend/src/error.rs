use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde::Serialize;
use thiserror::Error;
use utoipa::ToSchema;

#[derive(Debug, Serialize, ToSchema)]
pub struct ErrorBody {
    pub error: ErrorDetail,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct ErrorDetail {
    pub code: String,
    pub message: String,
}

#[derive(Debug, Error)]
pub enum AppError {
    #[error("{0}")]
    Validation(String),

    #[error("Unauthorized")]
    Unauthorized,

    #[error("Forbidden")]
    Forbidden,

    #[error("{0}")]
    NotFound(String),

    #[error("{0}")]
    Conflict(String),

    #[error("Database error")]
    Database(#[from] sqlx::Error),

    #[error("Internal error")]
    Internal(String),
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, code, message) = match self {
            AppError::Validation(msg) => (StatusCode::UNPROCESSABLE_ENTITY, "VALIDATION_ERROR", msg),
            AppError::Unauthorized => (
                StatusCode::UNAUTHORIZED,
                "UNAUTHORIZED",
                "Authentication required".to_string(),
            ),
            AppError::Forbidden => (
                StatusCode::FORBIDDEN,
                "FORBIDDEN",
                "You do not have permission to access this resource".to_string(),
            ),
            AppError::NotFound(msg) => (StatusCode::NOT_FOUND, "NOT_FOUND", msg),
            AppError::Conflict(msg) => (StatusCode::CONFLICT, "CONFLICT", msg),
            AppError::Database(err) => {
                // Log internal SQLx error server-side; never leak schema/SQL details to clients
                tracing::error!(error = %err, "Database operation failed");
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "INTERNAL_ERROR",
                    "An unexpected internal error occurred".to_string(),
                )
            }
            AppError::Internal(err) => {
                tracing::error!(error = %err, "Internal server error");
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "INTERNAL_ERROR",
                    "An unexpected internal error occurred".to_string(),
                )
            }
        };

        let body = ErrorBody {
            error: ErrorDetail {
                code: code.to_string(),
                message,
            },
        };

        (status, Json(body)).into_response()
    }
}
