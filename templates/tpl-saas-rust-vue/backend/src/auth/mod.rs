use argon2::{
    password_hash::{PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};
use axum::{
    extract::{FromRequestParts, State},
    http::{request::Parts, StatusCode},
    routing::{get, post},
    Json, Router,
};
use axum_extra::extract::cookie::{Cookie, CookieJar, SameSite};
use chrono::{DateTime, Duration, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use rand_core::OsRng;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

use crate::{error::AppError, AppState};

pub const SESSION_COOKIE_NAME: &str = "sf_session";
const SESSION_TTL_DAYS: i64 = 7;

#[derive(Debug, Serialize, Deserialize)]
struct Claims {
    sub: Uuid,
    email: String,
    exp: usize,
}

#[derive(Debug, Clone)]
pub struct AuthUser {
    pub id: Uuid,
    pub email: String,
}

impl FromRequestParts<AppState> for AuthUser {
    type Rejection = AppError;

    async fn from_request_parts(
        parts: &mut Parts,
        state: &AppState,
    ) -> Result<Self, Self::Rejection> {
        let jar = CookieJar::from_request_parts(parts, state)
            .await
            .map_err(|_| AppError::Unauthorized)?;

        let token = jar
            .get(SESSION_COOKIE_NAME)
            .map(|c| c.value().to_string())
            .ok_or(AppError::Unauthorized)?;

        let decoded = decode::<Claims>(
            &token,
            &DecodingKey::from_secret(state.config.jwt_secret.as_bytes()),
            &Validation::default(),
        )
        .map_err(|_| AppError::Unauthorized)?;

        Ok(AuthUser {
            id: decoded.claims.sub,
            email: decoded.claims.email,
        })
    }
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct RegisterRequest {
    pub email: String,
    pub name: String,
    pub password: String,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
}

#[derive(Debug, Serialize, ToSchema, FromRow)]
pub struct UserResponse {
    pub id: Uuid,
    pub email: String,
    pub name: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, FromRow)]
struct UserRecord {
    id: Uuid,
    email: String,
    name: String,
    password_hash: String,
    created_at: DateTime<Utc>,
}

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/register", post(register))
        .route("/login", post(login))
        .route("/logout", post(logout))
        .route("/me", get(me))
}

fn hash_password(password: &str) -> Result<String, AppError> {
    let salt = SaltString::generate(&mut OsRng);
    Argon2::default()
        .hash_password(password.as_bytes(), &salt)
        .map(|h| h.to_string())
        .map_err(|e| AppError::Internal(format!("Password hashing failed: {e}")))
}

fn verify_password(password: &str, hash: &str) -> bool {
    let Ok(parsed) = PasswordHash::new(hash) else {
        return false;
    };
    Argon2::default()
        .verify_password(password.as_bytes(), &parsed)
        .is_ok()
}

fn build_session_cookie(state: &AppState, user_id: Uuid, email: &str) -> Result<Cookie<'static>, AppError> {
    let exp = (Utc::now() + Duration::days(SESSION_TTL_DAYS)).timestamp() as usize;
    let claims = Claims {
        sub: user_id,
        email: email.to_string(),
        exp,
    };

    let token = encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(state.config.jwt_secret.as_bytes()),
    )
    .map_err(|e| AppError::Internal(format!("Token signing failed: {e}")))?;

    let cookie = Cookie::build((SESSION_COOKIE_NAME, token))
        .path("/")
        .http_only(true)
        .same_site(SameSite::Lax)
        .secure(state.config.is_https())
        .max_age(time::Duration::days(SESSION_TTL_DAYS))
        .build();

    Ok(cookie)
}

#[utoipa::path(
    post,
    path = "/api/auth/register",
    request_body = RegisterRequest,
    responses(
        (status = 201, description = "User registered", body = UserResponse),
        (status = 409, description = "Email already exists", body = crate::error::ErrorBody),
        (status = 422, description = "Validation error", body = crate::error::ErrorBody)
    ),
    tag = "auth"
)]
pub async fn register(
    State(state): State<AppState>,
    jar: CookieJar,
    Json(payload): Json<RegisterRequest>,
) -> Result<(StatusCode, CookieJar, Json<UserResponse>), AppError> {
    let email = payload.email.trim().to_lowercase();
    let name = payload.name.trim().to_string();

    if !email.contains('@') || email.len() < 5 {
        return Err(AppError::Validation("Please enter a valid email address".into()));
    }
    if name.is_empty() {
        return Err(AppError::Validation("Name is required".into()));
    }
    if payload.password.len() < 8 {
        return Err(AppError::Validation(
            "Password must be at least 8 characters".into(),
        ));
    }

    let existing: Option<(Uuid,)> = sqlx::query_as("SELECT id FROM users WHERE email = $1")
        .bind(&email)
        .fetch_optional(&state.pool)
        .await?;

    if existing.is_some() {
        return Err(AppError::Conflict("An account with this email already exists".into()));
    }

    let password_hash = hash_password(&payload.password)?;
    let user: UserResponse = sqlx::query_as(
        "INSERT INTO users (email, name, password_hash) VALUES ($1, $2, $3)
         RETURNING id, email, name, created_at",
    )
    .bind(&email)
    .bind(&name)
    .bind(&password_hash)
    .fetch_one(&state.pool)
    .await?;

    let cookie = build_session_cookie(&state, user.id, &user.email)?;
    Ok((StatusCode::CREATED, jar.add(cookie), Json(user)))
}

#[utoipa::path(
    post,
    path = "/api/auth/login",
    request_body = LoginRequest,
    responses(
        (status = 200, description = "Logged in", body = UserResponse),
        (status = 401, description = "Invalid credentials", body = crate::error::ErrorBody)
    ),
    tag = "auth"
)]
pub async fn login(
    State(state): State<AppState>,
    jar: CookieJar,
    Json(payload): Json<LoginRequest>,
) -> Result<(CookieJar, Json<UserResponse>), AppError> {
    let email = payload.email.trim().to_lowercase();

    let record: Option<UserRecord> = sqlx::query_as(
        "SELECT id, email, name, password_hash, created_at FROM users WHERE email = $1",
    )
    .bind(&email)
    .fetch_optional(&state.pool)
    .await?;

    let Some(user) = record else {
        return Err(AppError::Unauthorized);
    };

    if !verify_password(&payload.password, &user.password_hash) {
        return Err(AppError::Unauthorized);
    }

    let cookie = build_session_cookie(&state, user.id, &user.email)?;
    let response = UserResponse {
        id: user.id,
        email: user.email,
        name: user.name,
        created_at: user.created_at,
    };

    Ok((jar.add(cookie), Json(response)))
}

#[utoipa::path(
    post,
    path = "/api/auth/logout",
    responses((status = 204, description = "Logged out")),
    tag = "auth"
)]
pub async fn logout(State(state): State<AppState>, jar: CookieJar) -> (StatusCode, CookieJar) {
    let removal = Cookie::build((SESSION_COOKIE_NAME, ""))
        .path("/")
        .http_only(true)
        .same_site(SameSite::Lax)
        .secure(state.config.is_https())
        .max_age(time::Duration::ZERO)
        .build();
    (StatusCode::NO_CONTENT, jar.remove(removal))
}

#[utoipa::path(
    get,
    path = "/api/auth/me",
    responses(
        (status = 200, description = "Current authenticated user", body = UserResponse),
        (status = 401, description = "Unauthorized", body = crate::error::ErrorBody)
    ),
    tag = "auth"
)]
pub async fn me(
    State(state): State<AppState>,
    auth: AuthUser,
) -> Result<Json<UserResponse>, AppError> {
    let user: Option<UserResponse> =
        sqlx::query_as("SELECT id, email, name, created_at FROM users WHERE id = $1")
            .bind(auth.id)
            .fetch_optional(&state.pool)
            .await?;

    user.map(Json).ok_or(AppError::Unauthorized)
}
