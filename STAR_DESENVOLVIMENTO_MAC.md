# Star - desenvolvimento no Mac Intel

Este projeto e um fork do Fluxer, ainda em preparacao. Use a pasta **Documentos/Star** no VS Code.

## Configuracao local

- macOS 13.7.8 Intel (x86_64), Node.js 24.22.3, pnpm 11.27.0 (Corepack) e Rust/Cargo 1.98.1.
- Extensoes recomendadas: Biome, Rust Analyzer, TOML, Dev Containers e EditorConfig.
- Rancher Desktop 1.25.0 foi instalado em `~/Applications/Rancher Desktop.app`. Ele oferece Docker/Moby e Compose no macOS Ventura, e foi testado localmente. **Fica desligado quando nao estiver em uso para economizar recursos**.
- O arquivo `config/env/development.env` e privado. Para uma copia nova, use `config/env/development.example.env` como modelo; o Dev Container automatiza essa copia se necessario. Nunca use credenciais de exemplo em producao.

## Abrir e verificar

1. Abra `~/Documents/Star` no VS Code.
2. No terminal, execute `pnpm check:source` para validar caminhos, manifestos e referencias entre pacotes.
3. Para testar somente a API, use `pnpm --filter star_api typecheck` e `pnpm --filter star_api build`.
4. Para testar a documentacao, use `pnpm --filter star_docs typecheck` ou `pnpm --filter star_docs build`.
5. Para validar o gerenciador Rust, use `cargo check -p star-dev --locked`.

## Ambiente completo de desenvolvimento

1. Abra o **Rancher Desktop** pelo Finder e aguarde o motor Docker iniciar; deixe selecionado Moby/Docker, sem Kubernetes.
2. Com o Docker ativo, no VS Code acione **Dev Containers: Reopen in Container**.
3. O container usa ferramentas Linux e executa o bootstrap do Star. A primeira criacao pode consumir memoria, disco e bastante CPU.
4. No terminal *dentro do container*, execute `pnpm dev` quando o bootstrap tiver sido concluido. O proxy de desenvolvimento foi configurado para `http://localhost:8088`.
5. Ao encerrar o trabalho, pare os servicos e encerre o Rancher Desktop para liberar memoria do Mac.

## Estado de verificacao (18/11/2026)

**Aprovado:** verificacao estatica de 40 pacotes JS e 46 caminhos Cargo, sintaxe dos scripts JS e configs, pnpm install com lockfile, typecheck de API/desktop/docs, 31 testes de autenticacao simulados, build da API, build de documentacao, cargo check do star-dev, Docker daemon/Compose e validacao de Docker Compose sem iniciar stacks.

**Ainda nao homologado:** build completo da interface web, inicializacao conjunta de API/gateway/bancos/cache/voz, chamadas, upload, E2E no navegador, compilacao final do aplicativo desktop, publicacao HTTPS e seguranca de producao. Nao declare o Star pronto para venda ate esses testes passarem.

**Identidade:** enderecos `star.example` sao placeholders. Nao configurar dominio real por adivinhacao. Direitos de uso de marca e ativos do Fluxer precisam ser respeitados. O repositorio preserva AGPL e atribui o projeto original. Nao enviar codigo sem verificar regras AGPL.

## Backup e recuperacao

Backup anterior as mudancas: `~/Documents/Star-backup-2026-11-18-preparacao.tar.gz`. O projeto agora possui Git local e commits. A configuracao pessoal de desenvolvimento foi excluida do Git. Nao sobrescreva ou publique `config/env/development.env`.

Logs locais de instalacao e testes: `.star/setup-logs/` (ignorado pelo Git).
