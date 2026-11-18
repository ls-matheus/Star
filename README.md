# Star

Aplicativo de mensagens, voz e comunidades, em desenvolvimento a partir do código aberto do Fluxer.

## Estrutura

- `star_app`: interface web em React e TypeScript.
- `star_desktop`: aplicativo desktop com Electron.
- `star_api`: API e serviços em TypeScript.
- `star_gateway`: conexões em tempo real.
- `star_server` e demais diretórios `star_*`: serviços auxiliares.
- `packages`: bibliotecas compartilhadas com o namespace `@star`.
- `config/env/development.env`: configuração local de desenvolvimento.

## Desenvolvimento

As versões das ferramentas estão declaradas em `package.json`, `pnpm-workspace.yaml`, `Cargo.toml` e `rust-toolchain.toml`. Os scripts principais usam pnpm e Rust; a infraestrutura e os demais serviços também têm dependências próprias.

```sh
pnpm install
pnpm dev:bootstrap
pnpm dev
```

A configuração local mantém `localhost` e a porta pública `8088`.

## Identidade e configuração

O produto usa **Star**, os pacotes e diretórios usam `star` e as variáveis de ambiente usam o prefixo `STAR_`.

A Star ainda não tem domínio público, distribuição publicada ou repositório remoto definido. Os endereços sob `star.example`, incluindo `app.star.example`, `code.star.example` e `registry.star.example`, são exemplos de configuração. Antes de publicar, configure os domínios, o repositório, o registro de imagens, os canais de atualização e os serviços externos da Star. Os identificadores de lojas e de publicação também precisam ser registrados para este projeto.

Builds assinados para macOS devem usar perfis próprios, informados por `STAR_MAC_PROVISIONING_PROFILE` ou `STAR_MAC_CANARY_PROVISIONING_PROFILE`. Os perfis assinados do projeto original não são reutilizados.

## Créditos e licenças

Este projeto deriva do [Fluxer](https://github.com/fluxerapp/fluxer). O código mantém a licença [AGPL-3.0-or-later](LICENSE). As atribuições dos autores originais foram preservadas.

Os símbolos gráficos originais permanecem sujeitos à licença em [star_static/LICENSE](star_static/LICENSE). O nome nos wordmarks foi alterado para Star; os demais símbolos e ícones ainda são os da base original. As fontes mantêm as licenças e créditos descritos em [packages/fonts/NOTICE.md](packages/fonts/NOTICE.md). Consulte também [star_static/THIRD_PARTY_LICENSES.md](star_static/THIRD_PARTY_LICENSES.md).
