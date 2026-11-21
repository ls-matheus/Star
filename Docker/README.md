# Star Docker — ambiente local e imagens de build

Este diretorio foi preparado **sem modificar** `Star Server`, `Star web` ou `Star mobile`.
A base do projeto e um fork AGPL-3.0-or-later do Fluxer. Veja os LICENSE e
avisos de distribuicao originais.

## O que foi preparado

| Servico/imagem | Pasta-fonte | Finalidade |
| --- | --- | --- |
| `star/server:local` (servico `star`) | `../Star Server` | Runtime monolitico original: web, API, gateway, banco e outros servicos. É o unico servico iniciado por padrao |
| `star/web-assets:local` | `../Star web` | Compilacao e empacotamento dos assets web, usando o alvo existente `app-assets`. **Nao é um segundo servidor web** |
| `star/mobile-builder:local` | `../Star mobile` | Imagem de ferramentas Flutter para gerar APK **de teste**; nao é um aplicativo mobile que roda no Docker |

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

Para gerar todas as tres imagens, separadamente do inicio do servidor:

```bash
./star.sh build
```

Para compilar o Android experimentalmente sem alterar o codigo original:

```bash
./star.sh mobile-apk
# APK de teste, quando a compilacao funcionar, em output/mobile/
```

O mobile usa Flutter 3.44.0 em container Linux, fontes montadas somente para
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
  build das tres imagens, inicializacao/healthchecks do monolito, APK e testes E2E.
- Nao afirmar que o Star esta no ar ate que os comandos acima passem.

## Licenciamento e origens

Os arquivos-fonte foram documentados como fork de `fluxerapp/fluxer` (AGPL),
`fluxerapp/flutter_client` e `fluxerapp/dart_sdk`. A utilizacao ou
distribuicao do codigo, inclusive em servidor de rede, deve respeitar
AGPL e licencas de arte/terceiros.

## Publicacao automatica GitHub Actions (GHCR)

O repositorio `ls-matheus/Star` publica imagens Docker no registro do GitHub
quando um commit chega a `main` e altera fontes ou configuracao Docker,
ou quando o workflow **Docker Images (GHCR)** e executado manualmente:

- `ghcr.io/ls-matheus/star-server:latest` — servidor monolitico executavel
  (inclui o frontend compilado do snapshot de `Star Server`).
- `ghcr.io/ls-matheus/star-web-assets:latest` — pacote de assets web compilados
  (nao e um servidor HTTP independente).
- `ghcr.io/ls-matheus/star-mobile-builder:latest` — ferramenta Flutter para
  builds Android; **nao** e APK/iOS nem app mobile executavel.

Cada imagem tambem recebe uma tag `sha-<commit>` para rastreabilidade.
As imagens so aparecem no GHCR **apos** cada build e push concluir com sucesso.
A publicacao inicial pode criar pacotes privados no GHCR, dependendo das
configuracoes do repositorio/pacote; verifique a visibilidade e permissoes.

Para usar apenas a imagem publicada no GitHub (sem reconstruir localmente):

```bash
cd "$HOME/Documents/Star - Web Mobile Server - Codigo-Fonte/Docker"
./star.sh up-image
```

A imagem publicada e disponibilizada apenas para **linux/amd64** nesta etapa.
As builds nativas Android, macOS e Windows existentes foram mantidas para
execucao manual; testes PR continuam disponiveis. Compilacao publicada e um
marco de CI, nao substitui testes reais e nao libera producao publica.

O pacote Docker de fonte **nao** inclui `.env` com configuracoes privadas,
volume de banco, backups locais ou credenciais. Os segredos gerados no primeiro
boot permanecem na maquina e nunca devem ser incluídos em commits.
