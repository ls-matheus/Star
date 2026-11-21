# Estado da integracao Docker / GitHub Actions

## Preparado no repositorio
- Quatro imagens GHCR independentes: server, web-assets, desktop-renderer e mobile-builder.
- Uma prerelease por commit, criada antes dos builds.
- Cada imagem inclui um manifesto JSON com digest imutavel na mesma Release assim que seu proprio job termina.
- APK debug produzido dentro da imagem mobile-builder, a partir dos fontes montados somente para leitura.
- DMG e EXE produzidos nos runners macOS/Windows usando assets extraidos da imagem desktop-renderer.
- O Server nao e pre-requisito dos demais builds.
- Workflows nativos de Mac e Windows mantem execucao manual.
- Configuracao local Docker/Compose nao contem segredos em arquivos versionados.

## Limites e verificacoes pendentes
- Mac original continua sem Docker Engine; nao houve build local.
- A validacao remota pelo GitHub Actions e o resultado dos instaladores dependem das execucoes reais.
- Android e um APK debug experimental, nao assinado para lojas.
- DMG/EXE sao instaladores de teste, sem assinatura/notarizacao comercial.
- Diferencas entre os Cargo.lock do monorepo Web e Server continuam pendentes.
- Builds nao substituem testes ponta a ponta, seguranca e plano para VM em producao.
