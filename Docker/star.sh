#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
action="${1:-help}"
if [ "$#" -gt 0 ]; then shift; fi

usage() {
  cat <<'EOF'
Star Docker (perfil local)
  ./star.sh doctor       - checa Docker, Compose e ambiente
  ./star.sh up           - compila e inicia Web + Server
  ./star.sh up-image     - baixa imagem GHCR e inicia Star sem compilar
  ./star.sh build        - compila as 3 imagens (Web, Server, builder Android)
  ./star.sh images       - compila apenas Web assets + builder Android
  ./star.sh mobile-apk   - tenta gerar APK Android debug em output/mobile/
  ./star.sh status       - mostra servicos
  ./star.sh logs         - logs locais do servidor (podem conter setup token)
  ./star.sh down         - para, SEM apagar volume de dados
  ./star.sh help         - mostra esta ajuda
EOF
}

need_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "ERRO: Docker nao instalado. Este Mac precisa de Docker Engine + Compose." >&2
    echo "macOS 13 Intel: confira versao compativel; Docker Desktop recente pode nao suportar Ventura." >&2
    echo "Arquivos preparados em: $PWD" >&2
    exit 2
  fi
  if ! docker compose version >/dev/null 2>&1; then
    echo "ERRO: plugin Docker Compose v2 nao encontrado." >&2
    exit 2
  fi
  if ! docker info >/dev/null 2>&1; then
    echo "ERRO: Docker Engine nao esta iniciado." >&2
    exit 2
  fi
}

need_config() {
  if [ ! -f .env ]; then
    echo "ERRO: .env nao existe. Copie .env.example para .env e revise URLs/portas." >&2
    exit 2
  fi
}

doctor() {
  echo "=== Star Docker: diagnostico ==="
  printf 'Pasta: %s\n' "$PWD"
  printf 'Mac/arquitetura: '; uname -sm
  printf 'Espaco livre: '; df -h . | tail -1
  for part in "../Star Server/packaging/monolith/Dockerfile" "../Star web/star_app_proxy/Dockerfile" "../Star mobile/pubspec.yaml"; do
    test -f "$part" || { echo "FALTANDO: $part"; return 1; }
    echo "OK: $part"
  done
  test -f .env && echo "OK: .env (config local)" || echo "FALTANDO: .env"
  if ! command -v docker >/dev/null 2>&1; then
    echo "BLOQUEIO: Docker ausente. Nao houve build nem execucao."
    return 2
  fi
  docker compose version
  if ! docker info >/dev/null 2>&1; then
    echo "BLOQUEIO: Docker daemon nao esta ligado."
    return 2
  fi
  docker compose -f compose.yaml config --quiet
  docker compose -f compose.ghcr.yaml config --quiet
  echo "OK: Configuracoes Compose validadas pelo Docker (nao implica build ou teste de rede)."
}

case "$action" in
  help|-h|--help)
    usage
    ;;
  doctor|check)
    doctor
    ;;
  up|start)
    need_docker
    need_config
    docker compose -f compose.yaml config --quiet
    echo "Iniciando o monolito Web + Server no endereco local http://localhost:8080 ..."
    docker compose -f compose.yaml up -d --build star
    docker compose -f compose.yaml ps
    echo "Dados persistem no volume star-local-data."
    ;;
  up-image|pull-up)
    need_docker
    need_config
    docker compose -f compose.ghcr.yaml config --quiet
    docker compose -f compose.ghcr.yaml pull star
    docker compose -f compose.ghcr.yaml up -d --no-build star
    docker compose -f compose.ghcr.yaml ps
    echo "Acessar, se saudavel: http://localhost:8080 (apenas no proprio Mac)."
    ;;
  build)
    need_docker
    need_config
    docker compose -f compose.yaml --profile build-only build star web-assets mobile-builder
    ;;
  images)
    need_docker
    need_config
    docker compose -f compose.yaml --profile build-only build web-assets mobile-builder
    ;;
  mobile-apk)
    need_docker
    need_config
    mkdir -p output/mobile
    docker compose -f compose.yaml --profile build-only run --rm --build --no-deps mobile-builder
    echo "Verifique output/mobile/. APK debug nao deve ser publicado em lojas."
    ;;
  status|ps)
    need_docker
    docker compose -f compose.yaml ps
    ;;
  logs)
    need_docker
    echo "ATENCAO: logs locais podem conter o token inicial do admin. Nao compartilhe."
    docker compose -f compose.yaml logs --tail=100 -f star
    ;;
  down|stop)
    need_docker
    docker compose -f compose.yaml down
    echo "Contêiner parado. Volume star-local-data preservado."
    ;;
  *)
    echo "Opcao desconhecida: $action" >&2
    usage
    exit 2
    ;;
esac
