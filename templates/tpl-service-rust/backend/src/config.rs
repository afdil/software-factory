use std::env;

#[derive(Debug, Clone)]
pub struct Config {
    pub port: u16,
    pub database_url: String,
    pub api_key: Option<String>,
}

impl Config {
    pub fn from_env() -> Result<Self, String> {
        let port = env::var("PORT")
            .unwrap_or_else(|_| "8080".to_string())
            .parse::<u16>()
            .map_err(|e| format!("Invalid PORT value: {e}"))?;

        let database_url =
            env::var("DATABASE_URL").map_err(|_| "DATABASE_URL is required".to_string())?;
        let api_key = env::var("API_KEY").ok().filter(|v| !v.trim().is_empty());

        Ok(Self {
            port,
            database_url,
            api_key,
        })
    }
}
