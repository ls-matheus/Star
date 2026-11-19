# Star Android — base nativa 0.1.0

Cliente **React Native**, com componentes Android reais e Hermes. Não usa Flutter,
PWA, WebView, site empacotado, Expo Go, EAS ou um servidor Metro no APK distribuído.
O código do Star nesta `main` é a fonte de verdade. O backend e o cliente web
existentes permanecem intactos. Esta é uma migração inicial, **não o Star completo**.

## O que foi implementado

- Seleção da URL HTTPS da API, login por e-mail/usuário e senha, segundo fator TOTP.
- Token e URL da instância armazenados juntos usando Android Keystore via
  `expo-secure-store`. Senha e TOTP não são persistidos. Logout revoga a sessão
  no servidor quando disponível e limpa a sessão local.
- Comunidades (primeiras 100), canais de texto/anúncios, DMs e grupos já existentes,
  notas pessoais; leitura paginada (50 por página, até 500 em memória) e envio de
  texto. Menções não geram notificações nesta base (`allowed_mentions.parse=[]`).
- Gateway WSS descoberto em `/.well-known/star`, JSON sem compressão, versão 1,
  IDENTIFY, heartbeat/ACK, RESUME, reconexão com espera progressiva, assinatura da
  comunidade ativa e eventos de criação/edição/exclusão de mensagens.
- Atualização manual; desconexão em segundo plano e reconexão no retorno.
- Erros de rede, sessão expirada, permissão e limite de solicitações visíveis.
- Nome Android **Star**, ID **io.github.lsmatheus.star**, ícone vetorial próprio
  de estrela branca sobre o roxo `#4641D9`. Tema escuro baseado na família
  `neutralDark` de `star_app`. O ícone é novo; os arquivos históricos do Fluxer
  no repositório não foram apagados nem reapresentados como ativos novos.

## Mapeamento da arquitetura e reutilização

| Origem no repositório | Uso no Android |
| --- | --- |
| `star_app/src/features/app/constants/Endpoints.ts` | Importado diretamente: rotas REST compartilhadas |
| `packages/constants/src/AppConstants.ts` | Cor de marca e versão da API compartilhadas |
| `packages/constants/src/ChannelConstants.ts` | Tipos de canal importados diretamente |
| `packages/constants/src/GatewayConstants.ts` | Opcodes importados diretamente |
| `packages/schema/src/domains/auth/AuthSchemas.ts` | Contratos login, token e ticket MFA; subconjunto tipado em `src/api.ts` |
| `packages/schema/src/domains/message/MessageRequestSchemas.ts` | Envio de conteúdo, nonce e allowed_mentions |
| `star_api/src/api/auth/AuthController.ts` | Login, TOTP e logout existentes |
| `star_api/src/api/guild/controllers/GuildBaseController.ts` | Lista de comunidades |
| `star_api/src/api/guild/controllers/GuildChannelController.ts` | Canais da comunidade e autorização no servidor |
| `star_api/src/api/channel/controllers/MessageController.ts` | Histórico e envio de mensagens |
| `star_api/src/api/user/controllers/UserChannelController.ts` | Conversas privadas existentes |
| `star_api/src/api/instance/InstanceController.ts` e `packages/instance_bootstrap` | Descoberta canônica do endpoint WSS |
| `star_gateway/src/session/session_guilds.erl` | Formato `subscriptions` da comunidade ativa |
| `star_app/src/features/gateway/transport/GatewaySocket.ts` | Referência de protocolo, não importado por depender do runtime web |
| `star_app/src/features/theme/utils/ColorSystemPalette.ts` | Referência visual de cores e superfícies |

`star_api`, `star_gateway`, bancos, mídia e voz continuam no servidor. Nenhum deles
é incorporado ao APK. A interface DOM/CSS, MobX ligado ao runtime web, Electron,
editores Lexical e motores WebRTC web não podem ser transplantados diretamente
para componentes Android. A migração preserva os contratos e a separação
cliente/API/gateway, com um adaptador nativo pequeno, sem modificar o backend.

As dependências nativas ficam isoladas em `star_android/package-lock.json` usando
npm. Isso evita alterar o catálogo e o lockfile pnpm do monorepo existente. O
Metro observa a raiz apenas para importar os arquivos compartilhados, mas resolve
React e módulos nativos exclusivamente no `node_modules` deste cliente.

## Compilar e baixar sem Mac

Workflow: `.github/workflows/star-android-apk.yml`.

1. Cada push em `main` dispara a compilação; também existe **Actions → Star Android
   APK → Run workflow → main**.
2. Node 22, Java 17, SDK Android e cache npm/Gradle são preparados no runner Linux.
3. `npm ci` usa o lockfile; são executados verificação de integridade do Star,
   TypeScript, testes de contratos e checagem de compatibilidade Expo.
4. Expo Prebuild gera o projeto Gradle/Kotlin a partir de `app.json` e do plugin
   versionado. `assembleRelease -PreactNativeArchitectures=arm64-v8a` incorpora
   o JavaScript e Hermes; não requer Expo Go ou Metro ao executar.
5. O job confere ID Android, nome, assinatura, arquitetura ARM64 e bundle JS.
6. Baixe **Star-Android-arm64-N** em **Artifacts** na execução concluída. O ZIP
   inclui `Star-Android-arm64.apk`, SHA-256 e metadados. Retenção: 30 dias.

O APK usa **modo release com a chave de desenvolvimento do template Expo** para
permitir instalação de avaliação sem inventar credenciais de produção. Não é
assinatura de publicação na Play Store. Uma distribuição pública exige keystore
própria protegida por secrets, política de versionCode e atualização da assinatura.
Nesta base versionCode=1; não há promessa de atualização contínua de produção.

Para reproduzir em Linux com SDK Android/Java 17:

```sh
cd star_android
npm ci --workspaces=false
npm run typecheck
npm test
npm run prebuild
cd android
./gradlew :app:assembleRelease -PreactNativeArchitectures=arm64-v8a
```

`android/` é gerado e ignorado: altere `app.json`/`plugins/withStarAndroid.js`, não
arquivos gerados. O plugin define identidade, HTTPS e recursos vetoriais nativos.

## Conectar à instância

Informe a URL real da API, por exemplo **https://SEU-SERVIDOR/api** (exemplo, não um
serviço fornecido). Uma URL sem caminho recebe `/api`; um caminho explícito como
`/api/v1` é preservado. Não há servidor padrão e nenhuma chamada a `star.example`
ou a serviços Fluxer predefinidos. O gateway vem da descoberta da mesma API.
O administrador deve publicar API por HTTPS e gateway por WSS com certificados
válidos. O APK não inicia infraestrutura e não depende do antigo Mac.

Esta versão requer conta existente com senha, e TOTP quando habilitado. Restrições
da instância continuam sendo aplicadas pelo servidor. Se ela exigir SSO, CAPTCHA,
passkeys ou aprovação de IP, essa base não contorna a exigência e informa a falha.

## Pendências precisas

- Cadastro, recuperação de conta, SSO, WebAuthn/passkeys, CAPTCHA, aprovação de IP
  e todas as opções de MFA além de TOTP; múltiplas contas e política completa de instâncias.
- Criar DMs/comunidades/canais; convites; permissões visuais, cargos, membros,
  perfis, configurações, busca e administração. O servidor continua autorizando
  as operações implementadas, inclusive retornando 403 para canais restritos.
- Fóruns/threads, voz, vídeo, compartilhamento de tela, motores LiveKit/WebRTC e E2EE.
- Upload/download de anexos, imagens e avatars, Markdown, embeds, reações,
  respostas, edição/exclusão por UI, stickers, GIFs, presença detalhada,
  indicadores de digitação, não lidas e confirmações de leitura.
- Push, tarefas em segundo plano, banco offline, fila de envio, sincronização
  completa de exclusões/permissões durante desconexões e cache persistente.
- Paridade visual completa: temas configuráveis, fontes, animações, internacionalização
  e componentes do web. Esta base mantém nome, cor, organização de conversas e tema
  escuro; não promete reproduzir todas as telas do `star_app`.
- Paginação de comunidades além de 100 e histórico acima de 500 mensagens.
- Assinatura de produção, versionamento de releases e publicação na loja.

## O que os testes comprovam — e o que não comprovam

`npm test` usa transportes simulados: valida URLs, HTTPS, autenticação, payloads,
paginação, rate limit, erros HTTP, deduplicação/ordem de mensagens, HELLO/IDENTIFY,
assinaturas e heartbeat solicitado pelo servidor. Não envia mensagens a pessoas.
Typecheck e bundle verificam que os imports compartilhados funcionam no cliente nativo.
A inspeção do APK confirma pacote, ABI, runtime, assinatura e bundle incorporado.

**Isso não comprova login real, entrega de mensagens em um backend publicado,
comportamento em aparelho, voz ou paridade com o Star web.** Não foi fornecida uma
instância HTTPS operacional nem uma conta de teste do Star. As credenciais GitHub
não são credenciais do Star. O checklist abaixo permanece pendente até testes reais:

- Instalar em Android ARM64; abrir offline e conferir tela, teclado, rotação e retorno.
- Conectar à instância de teste, login/TOTP, logout e restauração após reinício.
- Dois usuários: envio/recebimento em comunidade e DM, perda de rede/reconexão.
- Respostas 401/403/429, perda de permissão, exclusão de canal e troca de comunidade.
- Acessibilidade/TalkBack, escala de fonte, uso de memória/bateria e Android mínimo.

## Licença

Código AGPL-3.0-or-later, conforme `../LICENSE`. Atribuições e licenças existentes
foram preservadas; o cliente não inclui o Flutter upstream. Distribuições devem
fornecer o código correspondente e observar as licenças das dependências.
