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

    #[error("{0}")]
    NotFound(String),

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
            AppError::NotFound(msg) => (StatusCode::NOT_FOUND, "NOT_FOUND", msg),
            AppError::Database(err) => {
                tracing::error!(error = %err, "Database operation failed");
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "INTERNAL_ERROR",
                    "An unexpected internal error occurred".to_string(),
                )
            }
            AppError::Internal(err) => {
                tracing::error!(error = %err, "Internal error");
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "INTERNAL_ERROR",
                    "An unexpected internal error occurred".to_string(),
                )
            }
        };

        (
            status,
            Json(ErrorBody {
                error: ErrorDetail {
                    code: code.to_string(),
                    message,
                },
            }),
        )
            .into_response()
    }
}
