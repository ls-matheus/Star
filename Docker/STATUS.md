# Estado da preparacao Docker - 21/11/2026

## Concluido
- Docker Compose local com um runtime Star Server (monolito oficial de build contendo o frontend) e dois alvos extras: `web-assets` e `mobile-builder`.
- Build contexts relativos referenciando Star Server, Star web e Star mobile, sem editar os fontes.
- Arquivo `.env` de demonstracao HTTP local, com permissao 0600, sem tokens em claro.
- Volumes persistentes: `star-local-data` para o estado do monolito.
- Atalhos `star.sh` e `INICIAR-STAR.command`.
- Builder Android faz copia temporaria e possui recuperacao do Gradle Wrapper ausente.
- `.dockerignore` para o contexto do builder; imagens de assets usam o ignore existente dos repositorios.

## Verificacao executada
- Shell: `bash -n` aprovado para os scripts.
- YAML: parse pelo Ruby/Psych aprovado, tres servicos.
- Caminhos dos Dockerfiles e `pubspec.yaml`: encontrados.
- `./star.sh doctor`: diagnostico executado e retornou BLOQUEIO esperado pela ausencia de Docker.

## Pendente (nao afirmar que passou)
- Docker Desktop/Engine e Compose v2 reais nao instalados no Mac.
- `docker compose config --quiet` e `docker compose build` nao executados.
- Inicializacao real, healthchecks, login, mensagens, chamadas, rede e APK nao validados.
- Diferenca entre `Star web/Cargo.lock` e `Star Server/Cargo.lock` continua no codigo-fonte.
- Auditoria de seguranca, TLS, dominio publico e suporte multiplataforma nao concluidos.

## Protecao dos dados
- As tres pastas-fonte continuam intactas.
- `./star.sh down` preserva o volume de dados; nao ha comando de apagar volumes.
- Ambiente padrao restrito a loopback e HTTP, inadequado para expor na internet.
