// SPDX-License-Identifier: AGPL-3.0-or-later

use star_admin::{Config, run};
use star_common::config::EnvMap;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let env = EnvMap::from_process()?;
    tracing_subscriber::registry()
        .with(env.tracing_filter("info"))
        .with(tracing_subscriber::fmt::layer())
        .init();

    let config = Config::from_env(&env)?;
    run(config, star_common::shutdown::signal_token()).await
}
