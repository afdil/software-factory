use std::env;

#[derive(Debug, Clone)]
pub struct Config {
    pub port: u16,
    pub app_url: String,
    pub database_url: String,
    pub jwt_secret: String,
    pub static_dir: String,
}

impl Config {
    pub fn from_env() -> Result<Self, String> {
        let port = env::var("PORT")
            .unwrap_or_else(|_| "8080".to_string())
            .parse::<u16>()
            .map_err(|e| format!("Invalid PORT value: {e}"))?;

        let app_url = env::var("APP_URL").unwrap_or_else(|_| format!("http://localhost:{port}"));
        let database_url =
            env::var("DATABASE_URL").map_err(|_| "DATABASE_URL is required".to_string())?;
        let jwt_secret =
            env::var("JWT_SECRET").map_err(|_| "JWT_SECRET is required".to_string())?;

        if jwt_secret.len() < 32 {
            return Err("JWT_SECRET must be at least 32 characters".to_string());
        }

        let static_dir = env::var("STATIC_DIR").unwrap_or_else(|_| "./dist".to_string());

        Ok(Self {
            port,
            app_url,
            database_url,
            jwt_secret,
            static_dir,
        })
    }

    pub fn is_https(&self) -> bool {
        self.app_url.starts_with("https://")
    }
}
