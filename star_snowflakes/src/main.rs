// SPDX-License-Identifier: AGPL-3.0-or-later

use star_common::config::EnvMap;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let env = EnvMap::from_process()?;
    star_svc::init_tracing(&env);
    let config = star_snowflakes::Config::from_env(&env)?;
    star_snowflakes::run(config, star_common::shutdown::signal_token()).await
}
