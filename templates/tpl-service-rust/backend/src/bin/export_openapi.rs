use std::fs;
use std::path::PathBuf;

use service::ApiDoc;
use utoipa::OpenApi;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let json = ApiDoc::openapi().to_pretty_json()?;
    let out_path = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("openapi.json");
    fs::write(&out_path, format!("{json}\n"))?;
    println!("Exported OpenAPI specification to {}", out_path.display());
    Ok(())
}
