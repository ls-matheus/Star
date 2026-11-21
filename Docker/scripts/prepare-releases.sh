#!/usr/bin/env bash
# Create two clearly separated Releases before any independent builds.
set -euo pipefail

test -n "$GITHUB_SHA"
test -n "$GITHUB_RUN_NUMBER"
test -n "$GH_TOKEN"
test -n "$GH_REPO"

sha8="$(printf '%s' "$GITHUB_SHA" | cut -c1-8)"
version="0.0.$GITHUB_RUN_NUMBER"
artifacts="star-build-$sha8"
metadata="star-meta-$sha8"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

cat > "$work/artifacts.md" <<EOF
## Visao geral

Artefatos de distribuicao do Star, gerados para o commit [$sha8](https://github.com/$GH_REPO/commit/$GITHUB_SHA). Esta e a Release de **downloads**; manifestos JSON ficam em uma [Release separada](https://github.com/$GH_REPO/releases/tag/$metadata).

## Downloads

| Destino | Arquivos | Observacoes |
| --- | --- | --- |
| Android ARM64 | APK | Compilacao de depuracao (debug), nao assinada para loja |
| Windows x64 | EXE | Instalador e/ou executavel sem assinatura comercial |
| macOS Intel | DMG e ZIP | Distribuicao sem notarizacao comercial |
| Docker / Linux AMD64 | docker.tar.zst ou partes numeradas | Exporte e importe com as instrucoes README e checksums |

Os arquivos sao anexados **individualmente** assim que os respectivos jobs finalizam. Nem todos os formatos necessariamente estarao presentes em uma compilacao parcial. Use a secao Assets abaixo para ver o que realmente foi publicado.

## Proveniencia e integridade

- Versao do build: **v$version**
- Commit: **$GITHUB_SHA**
- Publicador: [GitHub Actions](https://github.com/$GH_REPO/actions/workflows/docker-publish.yml)
- Metadados, digests GHCR e JSONs: [Release de metadados](https://github.com/$GH_REPO/releases/tag/$metadata)
- Arquivos Docker comprimidos podem vir divididos. Baixe todas as partes e verifique os checksums antes de importar.

## Limitacoes

Esta e uma **pre-release tecnica**. A publicacao comprova a geracao do arquivo, nao a instalacao ponta a ponta ou assinatura de distribuicao comercial.
EOF

cat > "$work/metadata.md" <<EOF
## Visao geral

Manifestos JSON e metadados verificaveis das imagens Docker do Star no commit [$sha8](https://github.com/$GH_REPO/commit/$GITHUB_SHA). Esta Release **nao contem instaladores**; APK, EXE, DMG, ZIP e arquivos Docker estao na [Release de artefatos](https://github.com/$GH_REPO/releases/tag/$artifacts).

## Estrutura dos manifestos

Cada arquivo JSON identifica o componente compilado e inclui o commit de origem, registro GHCR, plataforma, tag, digest SHA-256 e referencia imutavel da imagem.

| Componente | Arquivo JSON |
| --- | --- |
| Web | star-web-assets-$sha8.json |
| Desktop | star-desktop-renderer-$sha8.json |
| Mobile Builder | star-mobile-builder-$sha8.json |
| Server | star-server-$sha8.json, somente quando o build Server for executado |

A lista representa os tipos de manifestos possiveis. Consulte Assets para confirmar quais efetivamente foram produzidos neste commit.

## Uso e rastreabilidade

- Versao do build: **v$version**
- Commit: **$GITHUB_SHA**
- Digest imutavel: disponivel dentro de cada manifesto JSON
- Downloads do aplicativo e imagens Docker exportadas: [Release de artefatos](https://github.com/$GH_REPO/releases/tag/$artifacts)

Os manifestos nao substituem os arquivos binarios; o download de imagens tambem pode ser realizado diretamente pelo GHCR usando o digest informado no JSON.
EOF

publish_release() {
  local tag="$1"
  local title="$2"
  local notes="$3"
  if gh release view "$tag" >/dev/null 2>&1; then
    gh release edit "$tag" --title "$title" --notes-file "$notes" --prerelease
  else
    gh release create "$tag" --target "$GITHUB_SHA" --title "$title" --notes-file "$notes" --prerelease
  fi
  echo "Release initialized: $tag"
}

publish_release "$artifacts" "Star | Artefatos | v$version ($sha8)" "$work/artifacts.md"
publish_release "$metadata" "Star | JSONs e metadados | v$version ($sha8)" "$work/metadata.md"

{
  echo "## Releases por commit"
  echo ""
  echo "- Artefatos: https://github.com/$GH_REPO/releases/tag/$artifacts"
  echo "- JSONs e metadados: https://github.com/$GH_REPO/releases/tag/$metadata"
} >> "$GITHUB_STEP_SUMMARY"
