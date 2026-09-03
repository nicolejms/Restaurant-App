use diesel::prelude::*;

use diesel::Connection;
use diesel::pg::PgConnection;
use dotenvy::dotenv;
use std::env;

pub fn establish_connection() -> PgConnection {
    dotenv().ok();

    let database_url = database_url().expect(
        "DATABASE_URL or DATABASE_HOST, DATABASE_NAME, DATABASE_USERNAME, and DATABASE_PASSWORD must be set",
    );
    PgConnection::establish(&database_url)
        .unwrap_or_else(|_| panic!("Error connecting to the configured PostgreSQL database"))
}

fn database_url() -> Result<String, String> {
    if let Ok(database_url) = env::var("DATABASE_URL") {
        return Ok(database_url);
    }

    build_database_url(
        &required_env("DATABASE_HOST")?,
        &env::var("DATABASE_PORT").unwrap_or_else(|_| "5432".to_string()),
        &required_env("DATABASE_NAME")?,
        &required_env("DATABASE_USERNAME")?,
        &required_env("DATABASE_PASSWORD")?,
    )
}

fn required_env(name: &str) -> Result<String, String> {
    env::var(name).map_err(|_| format!("{name} must be set when DATABASE_URL is not provided"))
}

fn build_database_url(
    host: &str,
    port: &str,
    database: &str,
    username: &str,
    password: &str,
) -> Result<String, String> {
    let port = port
        .parse::<u16>()
        .map_err(|_| "DATABASE_PORT must be a valid TCP port".to_string())?;
    if host.is_empty() || database.is_empty() || username.is_empty() {
        return Err("Database host, name, and username must not be empty".to_string());
    }

    Ok(format!(
        "postgresql://{}:{}@{}:{}/{}",
        percent_encode(username),
        percent_encode(password),
        host,
        port,
        percent_encode(database)
    ))
}

fn percent_encode(value: &str) -> String {
    value
        .bytes()
        .map(|byte| match byte {
            b'A'..=b'Z'
            | b'a'..=b'z'
            | b'0'..=b'9'
            | b'-'
            | b'.'
            | b'_'
            | b'~' => (byte as char).to_string(),
            _ => format!("%{byte:02X}"),
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::build_database_url;

    #[test]
    fn builds_encoded_database_url_from_discrete_settings() {
        let database_url = build_database_url(
            "catalog.example.com",
            "5432",
            "catalogdb",
            "catalog-user",
            "p@ss word",
        )
        .unwrap();

        assert_eq!(
            "postgresql://catalog-user:p%40ss%20word@catalog.example.com:5432/catalogdb",
            database_url
        );
    }
}