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

## GitHub Actions: quatro imagens, tres instaladores, sem fila do Server

O workflow
[`Docker Images and Apps (GHCR)`](https://github.com/ls-matheus/Star/actions/workflows/docker-publish.yml)
valida a configuracao e cria a prerelease `star-build-<SHA>` para o commit.

Em seguida, quatro builds Docker **independentes** iniciam em paralelo:

| Imagem GHCR | Conteudo | Dependente |
| --- | --- | --- |
| `ghcr.io/ls-matheus/star-server` | Servidor monolitico Star (inclui web) | Sem bloqueio dos demais jobs; uso futuro em VM |
| `ghcr.io/ls-matheus/star-web-assets` | Assets da Web standalone | Publicacao imediata do manifesto |
| `ghcr.io/ls-matheus/star-desktop-renderer` | Renderer Electron compilado no Docker | DMG macOS e EXE Windows |
| `ghcr.io/ls-matheus/star-mobile-builder` | Toolchain Flutter/Rust/Android | APK Android debug |

**O job lento do Server nao bloqueia Web, Mobile nem Desktop.**
Cada imagem publica um JSON (`star-<componente>-<SHA>.json`) com tag e digest
SHA-256 na Release assim que o respectivo build termina. O corpo da imagem
fica no GHCR, nao como arquivo enorme dentro da Release.

### Instalares derivados das imagens

- **APK Android ARM64 de teste:** `docker run` usa a imagem
  `star-mobile-builder` publicada, mais os fontes de `Star mobile` e
  `Star web` montados somente para leitura. O APK debug vai diretamente
  para a mesma Release quando a compilacao concluir. Nao esta assinado
  para distribuicao comercial.
- **DMG Mac Intel e EXE Windows x64:** o CI extrai o renderer de dentro
  da imagem `star-desktop-renderer`, envia-o como artifact temporario e
  conclui o empacotamento com Electron e addons nativos nos respectivos
  runners do macOS/Windows. Os instaladores resultantes sao anexados
  individualmente a mesma Release, sem aguardar Server ou Android.

Os workflows nativos `Android`, `Mac` e `Windows` continuam disponiveis
para execucao manual, independentemente do novo pipeline Docker.

`Star web` e `Star Server` contem copies completas de um monorepo:
Docker nao sincroniza alteracoes entre eles. Builds no GHCR usam o codigo
presente no GitHub para o commit escolhido.

### Instalacao local opcional

O Compose continua permitindo build local do Server e imagens de assets.
`./star.sh up-image` baixa a imagem publicada de Server do GHCR
**quando ela existir**. Um fluxo para VM publica e HTTPS devera ser
projetado separadamente (rede, dominios, segredos, backups e TLS).

**Estado de qualidade:** manifesto publicado ou instalador compilado
nao comprovam testes de login, mensagens, chamadas ou assinatura de loja.
Mac/Windows foram configurados para pacotes de teste sem notarizacao/certificado
comercial, e Android e intencionalmente DEBUG.
