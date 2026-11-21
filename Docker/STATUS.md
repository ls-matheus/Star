# Estado da integracao Docker / GitHub Actions

## Preparado no repositorio
- Um unico workflow ativo em .github/workflows/docker-publish.yml.
- Jobs Web, Desktop e Mobile independentes. Server e acionado por alteracao
  nos fontes ou sob demanda, sem bloquear os instaladores.
- Duas prereleases por commit, uma para artefatos e outra para JSONs, criadas antes dos builds.
- Upload direto de APK, DMG, ZIP e EXE na Release com verificacao de presenca.
- Manifestos JSON e digests na Release de metadados; imagem Docker exportada para a Release de artefatos
  em .docker.tar.zst (dividida em partes de ate 1400 MiB se necessario).
- Cache incremental por 7 componentes (Web, renderer, Mobile Builder, Server,
  APK, macOS e Windows) com baseline JSON versionado na Release de metadados.
- Fingerprints de codigo evitam builds de componentes inalterados; artefatos
  reaproveitados permanecem no release de origem, com links na Release nova.
- GHA caches Buildx mode=max, Rust/pnpm desktop e Gradle/Dart/Cargo Android.
- Suite de testes de escopo incremental e finalizacao integrada a validacao.
- Modo manual backfill para preencher Releases anteriores sem recompilar imagens.
- Nao ha segredos em arquivos versionados.

## Limites e verificacoes pendentes
- Mac original continua sem Docker Engine; nao houve build local.
- A validacao remota pelo GitHub Actions e o resultado dos instaladores dependem das execucoes reais.
- Android e um APK debug experimental, nao assinado para lojas.
- DMG/EXE sao instaladores de teste, sem assinatura/notarizacao comercial.
- Diferencas entre os Cargo.lock do monorepo Web e Server continuam pendentes.
- Builds nao substituem testes ponta a ponta, seguranca e plano para VM em producao.
