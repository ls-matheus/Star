# Star — visão geral em português

O **Star** é uma integração experimental de um aplicativo de mensagens com cliente Web/Desktop, aplicativo Flutter Mobile, servidor Rust e ferramentas de build Docker.

**Estado atual:** pré-lançamento técnico. Os arquivos publicados não têm validação completa de instalação nem assinatura comercial. Não existe uma implantação pública de produção homologada neste repositório.

## Onde começar

- [README principal](../../README.md) — funcionalidades verificadas, requisitos e downloads.
- [Releases](https://github.com/ls-matheus/Star/releases) — instaladores e metadados existentes.
- [Arquitetura](../architecture.md) — separação entre Mobile, Web, Desktop e Server.
- [Compilação e publicação](../build-and-release.md) — GitHub Actions, cache incremental e imagens Docker.
- [Ambiente Docker](../../Docker/README.md) — comandos de desenvolvimento local.
- [Segurança](../../SECURITY.md) — cuidados ao usar credenciais e reportar vulnerabilidades.

## Releases separadas

Para cada commit compilado existem dois tipos de pré-lançamento:

| Tipo | Arquivos |
| --- | --- |
| **Artefatos** (`star-build-<SHA>`) | APK, EXE, DMG, ZIP e imagens Docker compactadas |
| **JSONs e metadados** (`star-meta-<SHA>`) | Manifestos das imagens, digests SHA-256 e base incremental |

Quando uma parte do projeto não muda, o workflow evita recompilá-la e aponta para os arquivos já publicados, sem fazer cópias desnecessárias.

## Iniciar o Server localmente

Instale Docker Engine e o plugin Compose. Na raiz do repositório, execute:

```bash
cd Docker
cp .env.example .env
./star.sh doctor
./star.sh up
./star.sh status
```

Se o servidor ficar saudável, abra **http://localhost:8080** no mesmo computador. A configuração de exemplo usa `127.0.0.1` e **não deve ser exposta diretamente à internet**.

Para contribuir, leia [CONTRIBUTING.md](../../CONTRIBUTING.md).
