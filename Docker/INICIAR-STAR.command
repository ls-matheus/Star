#!/bin/bash
cd "$(dirname "$0")" || exit 1
./star.sh up
status=$?
printf '\nResultado (codigo %s). Pressione Enter para fechar...\n' "$status"
read -r _
exit "$status"
