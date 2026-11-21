# Star — compilacoes automaticas no GitHub

O codigo e gerenciado diretamente por Git. **Nao e necessario usar os ZIPs** quando o repositorio ja esta conectado.

## Desktop macOS e Windows

Workflow: `.github/workflows/star-desktop.yml`

- A cada push na branch `main` que altere `star_desktop/`, `star_app/`, pacotes compartilhados ou arquivos de build, inicia dois jobs.
- macOS Intel 64 bits: gera `.dmg` e `.zip` com Electron.
- Windows 64 bits: gera `.exe` (NSIS e portable) com Electron.
- Tambem pode iniciar manualmente em GitHub > Actions > Star Desktop - macOS e Windows > Run workflow.
- Arquivos gerados ficam na pagina da execucao em **Artifacts** por 14 dias.
- Nao publica automaticamente em lojas ou na VM; o servidor nao participa.

**Limites:** os artefatos de desktop sao destinados a avaliacao e nao possuem assinatura de codigo ou notarizacao macOS. Por isso podem mostrar alertas do Gatekeeper e SmartScreen. Os scripts foram inspecionados e os arquivos verificados estaticamente; a compilacao final depende da execucao real em runners do GitHub.

## Android

A main ja tinha `.github/workflows/star-android-apk.yml` que produz um APK **React Native** da pasta `star_android/`.

Um segundo cliente **Flutter completo** existe na branch `feat/original-fluxer-android`, em `star_mobile/`. O workflow dessa branch ja produziu um APK ARM64 na execucao de 19/11/2026. Quando essa branch for incorporada a `main`, ela substituira o workflow React Native por seu workflow Flutter.

Nao foi feito merge da branch Flutter nesta alteracao para nao publicar automaticamente uma mudanca grande de codigo sem homologacao.

## Como usar

1. Atualize o codigo na branch que deseja compilar e faca push.
2. Acesse a aba Actions do repositorio.
3. Abra a execucao; se estiver verde, baixe os artefatos.
4. Para producao, configurar dominio/API real, assinatura e testes em dispositivos.

Repositório: https://github.com/ls-matheus/Star
