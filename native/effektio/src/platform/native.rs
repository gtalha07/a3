use matrix_sdk::{Client, ClientBuilder};
use matrix_sdk_sled::make_store_config;
use std::{fs, path};

pub async fn new_client_config(base_path: String, home: String) -> anyhow::Result<ClientBuilder> {
    let data_path = sanitize(base_path, home);

    fs::create_dir_all(&data_path)?;

    Ok(Client::builder()
        .store_config(make_store_config(&data_path, None).await?)
        .user_agent(format!("effektio-testing/{:}", env!("CARGO_PKG_VERSION"))))
}

pub fn init_logging(filter: Option<String>) -> anyhow::Result<()> {
    Ok(())
}

pub fn sanitize(base_path: String, home: String) -> path::PathBuf {
    path::PathBuf::from(base_path).join(sanitize_filename_reader_friendly::sanitize(&home))
}
