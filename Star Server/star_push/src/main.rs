// SPDX-License-Identifier: AGPL-3.0-or-later

use clap::Parser;
use star_common::config::EnvMap;
use star_push::{cli, run};

#[tokio::main(flavor = "multi_thread")]
async fn main() -> anyhow::Result<()> {
    let args = cli::Args::parse();
    let env = EnvMap::from_process()?;
    if matches!(args.command, Some(cli::Command::Healthcheck)) {
        return star_common::healthcheck::run(star_common::healthcheck::address(
            &env,
            "STAR_PUSH_SERVICE_HOST",
            "STAR_PUSH_SERVICE_PORT",
            args.mode.default_port(),
        )?)
        .await;
    }

    star_svc::init_tracing(&env);

    let cfg = cli::load_config(&args, &env)?;
    run(cfg, star_common::shutdown::signal_token()).await
}
