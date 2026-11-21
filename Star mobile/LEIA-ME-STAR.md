# Star — Star mobile

Cliente Flutter para Android/iOS + SDK Dart integrado em star_dart_sdk/.

## Estrutura
- Os arquivos de código e os identificadores textuais do produto foram renomeados de Fluxer para Star.
- A versão foi montada a partir de snapshots públicos, sem modificar nenhuma cópia do usuário.
- As pastas Star web e Star Server incluem cópias completas do monorepo de origem:
  **isso é necessário para preservar as dependências entre web, desktop e back-end**.
- O cliente mobile usa o SDK local em `star_dart_sdk/`, em vez de um submódulo remoto.

## Antes de executar
1. Configurar domínio e URLs de API de Star. `star.invalid` é apenas um placeholder intencional.
2. Configurar autenticação, chaves, e-mail, storage, banco e certificados.
3. Instalar dependências compatíveis com este commit e corrigir integrações específicas.
4. Gerar app icons nativos adicionais (ICO/ICNS) onde aplicável e conferir o branding com os apps rodando.
5. Executar builds completos, integração mobile ↔ API e testes reais antes de produção.

## Fonte original e obrigações
- fluxerapp/fluxer — ee34297dc3df54b01aa919233a3754c058d78a1e
- fluxerapp/flutter_client — bed3dce5d3e8f159566d8bddec1d5465d028c282
- fluxerapp/dart_sdk — 42a42723fa10ac13330fe3a36fc2a45005287542
- Todos: https://github.com/fluxerapp
- Licença do código: AGPL-3.0-or-later; veja os arquivos LICENSE preservados.
- Licenças de arte e terceiros permanecem aplicáveis. O fork Star **não é um produto oficial Fluxer**.
- Redistribuição/uso em rede pode exigir disponibilização do código-fonte correspondente
  e avisos de modificações nos termos da AGPL.

## Escopo da conferência
Verifique a raiz do ZIP no relatório STAR-RELATORIO.txt para as verificações executadas.
Este pacote é um fork de código-fonte renomeado, **não** um binário pronto ou um deploy homologado.
