# Star Docker — ambiente local e imagens de build

Os fontes locais originais foram preservados. No GitHub, o Dockerfile do Web recebeu
um alvo extra `desktop-renderer` para os instaladores nativos.
A base do projeto e um fork AGPL-3.0-or-later do Fluxer. Veja os LICENSE e
avisos de distribuicao originais.

## O que foi preparado

| Servico/imagem | Pasta-fonte | Finalidade |
| --- | --- | --- |
| `star/server:local` (servico `star`) | `../Star Server` | Runtime monolitico original: web, API, gateway, banco e outros servicos. É o unico servico iniciado por padrao |
| `star/web-assets:local` | `../Star web` | Compilacao e empacotamento dos assets web, usando o alvo existente `app-assets`. **Nao é um segundo servidor web** |
| `star/desktop-renderer:local` | `../Star web` | Renderer desktop compartilhado para instaladores DMG/EXE |
| `star/mobile-builder:local` | `../Star mobile` + `../Star web` | Imagem de ferramentas Flutter e Rust para gerar APK **de teste** |

O projeto Star mantem uma copia completa do monorepositorio em Web e Server.
O Dockerfile monolitico do Server ja compila a interface web a partir da sua copia.
Por isso `web-assets` e uma imagem adicional para validacao/distribuicao de assets,
e nao e conectada ao monolito automaticamente. **Diferenças de codigo entre Web e
Server nao sao sincronizadas pelo Docker.** Antes de producao sera necessario
escolher uma fonte de verdade e corrigir divergencias (incluindo `Cargo.lock`).

## Comecar no Mac

O Mac verificado era macOS 13.7.8 / Intel, sem Docker Engine ou Compose instalado.
Instale um Docker Engine **compativel com macOS 13** (novas versoes de Docker Desktop
podem nao dar suporte), inicie-o e volte aqui. Requisitos sugeridos para tentar
compilar este monorepo pesado: 16 GB RAM e espaco livre adicional bem acima de 20 GB.
Esses numeros sao estimativas, nao medidas de um build final.

```bash
cd "$HOME/Documents/Star - Web Mobile Server - Codigo-Fonte/Docker"
./star.sh doctor
./star.sh up
```

Se o monolito compilar e ficar saudavel, acesse `http://localhost:8080`.
O tempo e uso de disco de uma primeira compilacao poderao ser altos.
No primeiro boot, o Star gera credenciais dentro do volume; o **setup token**
pode aparecer nos logs locais. Trate esse token como segredo.

Para compilar as quatro imagens, separadamente do inicio do servidor:

```bash
./star.sh build
```

Para compilar o Android experimentalmente sem alterar o codigo original:

```bash
./star.sh mobile-apk
# APK de teste, quando a compilacao funcionar, em output/mobile/
```

O mobile usa Flutter 3.50.0 (atualizado da imagem-base 3.44.0) e Rust 1.98.1 em container Linux, fontes montadas somente para
leitura, copia temporaria e flavor OSS/UnifiedPush. O pacote **nao implementa
assinatura de distribuicao**, nao gera IPA e nao incorpora chaves ou contas da
Google/Apple. Para iOS, compile e assine com Flutter/Xcode em macOS.

Para consultar status, logs e parar:

```bash
./star.sh status
./star.sh logs
./star.sh down
```

`down` **preserva** o volume nomeado `star-local-data`. Nao use `down -v`
sem um backup testado. Atualizacao de release precisa de plano de rollback.

## Perfil local: nao publicado

- Porta de navegador ligada apenas a `127.0.0.1:8080`.
- O arquivo `.env` padrao usa HTTP e `localhost` **somente para desenvolvimento**.
- SSL/TLS, DNS, hardening, armazenamento remoto, copias de seguranca externas,
  testes de carga, email, push e WebRTC em dispositivos remotos NAO foram
  homologados nesta entrega.
- Para acesso por celular ou internet, criar perfil separado com HTTPS valido,
  dominio real, firewall, relay/TURN, segredos e limites de rede antes de
  expor o projeto.
- `Star Server` ja inclui seus servicos internos e armazenamento no monolito;
  nao copie o Compose de desenvolvimento com credenciais de exemplo para producao.
- O Docker nao corrige `star.invalid` em codigo/documentacao nem garante que
  todos os builds Rust, pnpm e Flutter funcionem. Erros devem ser corrigidos
  na base, preferencialmente apos backup e testes reproduziveis.

## Estado de verificacao

- Arquivos Compose, Dockerfiles e scripts preparados em pasta separada.
- Sintaxe Shell/YAML e caminhos passives de validacao sem Docker.
- **PENDENTE:** Docker daemon instalado no Mac, `docker compose config` real,
  builds das imagens, healthchecks do monolito, testes do APK e testes E2E.
- Nao afirmar que o Star esta no ar ate que os comandos acima passem.

## Licenciamento e origens

Os arquivos-fonte foram documentados como fork de `fluxerapp/fluxer` (AGPL),
`fluxerapp/flutter_client` e `fluxerapp/dart_sdk`. A utilizacao ou
distribuicao do codigo, inclusive em servidor de rede, deve respeitar
AGPL e licencas de arte/terceiros.

## GitHub Actions: um unico workflow, artefatos na Release

O unico workflow ativo e **Star | Build & Release**:
https://github.com/ls-matheus/Star/actions/workflows/docker-publish.yml

- Push na branch main: executa os jobs de Apps quando mudam arquivos Web,
  Mobile, Docker ou CI. O Server so inicia se mudar algo em Star Server.
  Um commit que altera ambos pode executar os builds em paralelo.
- Execucao manual (Run workflow): escolha **apps**, **server** ou **all**.
  O Server nunca e pre-requisito de APK, DMG ou EXE.
- **backfill**: informe o SHA de uma Release existente (8 caracteres) para
  anexar os arquivos Docker dessa compilacao sem rebuildar imagens.

Para cada novo commit compilado, duas prereleases com titulos descritivos
sao criadas logo apos a validacao: **star-build-SHA** (artefatos) e
**star-meta-SHA** (JSONs e metadados). As releases historicas foram
reorganizadas por tipo e preservam suas tags originais, mesmo as anteriores
a essa separacao. Cada resultado e anexado a sua propria Release
**assim que seu job termina**, sem aguardar os outros:

| Build independente | Publicacao na GitHub Release |
| --- | --- |
| Web | Manifesto JSON na Release de metadados e arquivo Docker comprimido na de artefatos |
| Desktop renderer | JSON na Release de metadados; imagem Docker, DMG, ZIP e EXE na de artefatos |
| Mobile builder | JSON na Release de metadados; imagem Docker e APK ARM64 DEBUG na de artefatos |
| Server (quando solicitado ou modificado) | JSON na Release de metadados; imagem Docker na de artefatos, sem bloquear apps |

O GitHub Container Registry (GHCR) tambem recebe as imagens originais com
tags associadas ao commit e seus digests SHA-256.

### Compilacao incremental (a partir de v0.0.8)

O workflow unico **Star | Build & Release** tem um planejador de cache por
componente. O arquivo **star-incremental-base.json**, na Release de JSONs
e metadados, guarda as impressoes digitais Git (hashes) e as referencias
imutaveis GHCR dos ultimos builds aprovados. A primeira base ja foi criada
usando os artefatos existentes da compilacao df8b6e0e (o Server, da
compilacao e7d1bebf). A base nao duplica arquivos grandes.

| Mudanca | Builds necessarios |
| --- | --- |
| Apenas codigo Mobile | APK Android, reaproveitando imagem Mobile Builder |
| Dockerfile ou script do builder Android | Mobile Builder e APK |
| Codigo Star Web | Web Assets, Desktop Renderer, APK, DMG e EXE |
| Apenas Star Server | Imagem Server, sem recompilar apps |
| Somente documentacao Docker/CI | Nenhum build de aplicativo, se fontes inalterados |
| Configuracao Electron de empacotamento | DMG e EXE, usando renderer imutavel anterior |

Quando nao ha mudancas, o job de instalador e ignorado. Os artefatos
existentes **nao sao recompilados nem duplicados**: a nova Release aponta
explicitamente para os arquivos originais na secao **Reutilizacao incremental**.
O mesmo vale para JSONs de imagens reutilizadas, sempre com links e digest
do objeto original. Somente novos arquivos sao anexados como Assets na
Release atual. Nao delete Releases antigas que servem de base.

Quando um build alterado passa, o job final grava outro
**star-incremental-base.json** na Release de metadados correspondente,
sem sobrescrever a base antiga; essa nova referencia sera considerada no
proximo commit. Se a base estiver ausente ou for incompativel com o historico
Git, o planejador usa rebuild seguro para os componentes selecionados.

Cache intermediario: Docker Buildx usa GHA cache por imagem em mode=max,
macOS/Windows reaproveitam Rust e pnpm, e Android tenta restaurar caches de
Flutter/Dart, Gradle e Cargo (falha de armazenamento de cache nao invalida
um APK ja compilado). A integridade dos instaladores continua dependendo
de build real e dos testes da plataforma.

No botao **Run workflow**: escolha apps, server ou all; marque
**force_rebuild=true** para ignorar a base e recompilar o escopo selecionado.
A opcao backfill continua disponivel para exportar imagens existentes sem build.
Escolha **plan** para executar somente o planejador e os testes de validacao,
sem criar Releases nem iniciar compilacoes.

### Como baixar as imagens Docker

Cada imagem gera um arquivo **.docker.tar.zst** diretamente na Release.
Se ultrapassar o limite de 2 GiB por arquivo do GitHub, sera dividida em
**.docker.tar.zst.part-aa**, **part-ab**, etc. O job publica ainda os arquivos
**.docker.sha256** (verificacao) e **.docker.README.txt** (comandos para importar
a imagem no Docker). Todos os arquivos de uma imagem devem ser baixados juntos.
Para uso conectado, tambem e possivel fazer Docker pull pelo digest no JSON
da Release.

A compactacao e a publicacao dos arquivos Docker acontecem em jobs
independentes, depois de cada imagem estar no GHCR. Elas nunca atrasam o
empacotamento do APK nem dos instaladores macOS/Windows.

### Instaladores

O APK de teste e compilado pela imagem mobile-builder com fontes montados
somente para leitura. O renderer desktop e extraido da imagem Docker, e os
runners nativos de macOS/Windows compilam os modulos Electron do proprio OS.
Os instaladores sao enviados **diretamente** para a Release e sua presenca
e verificada por nome depois do upload. O APK e debug, sem assinatura para loja;
os instaladores desktop tambem nao tem certificado comercial/notarizacao.

### Instalacao local opcional

O Compose continua permitindo build local do Server e imagens de assets.
`./star.sh up-image` baixa a imagem publicada de Server do GHCR
**quando ela existir**. Um fluxo para VM publica e HTTPS devera ser
projetado separadamente (rede, dominios, segredos, backups e TLS).

**Estado de qualidade:** manifesto publicado ou instalador compilado
nao comprovam testes de login, mensagens, chamadas ou assinatura de loja.
Mac/Windows foram configurados para pacotes de teste sem notarizacao/certificado
comercial, e Android e intencionalmente DEBUG.
