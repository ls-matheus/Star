#!/bin/sh

export TMPDIR="${XDG_RUNTIME_DIR}/app/${FLATPAK_ID}"
export STAR_FLATPAK_COMMAND="${FLATPAK_ID}"

exec zypak-wrapper "/app/star/star-canary" "$@"
