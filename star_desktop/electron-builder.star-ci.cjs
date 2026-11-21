// SPDX-License-Identifier: AGPL-3.0-or-later
// CI de teste: gera instaladores Star sem certificados comerciais.
// Nao usar esta configuracao para distribuicao publica assinada/notarizada.
const base = require('./electron-builder.config.cjs');
const {provisioningProfile: _unusedProfile, ...originalSign} = base.mac?.sign ?? {};

module.exports = {
  ...base,
  mac: {
    ...base.mac,
    notarize: false,
    sign: {
      ...originalSign,
      identity: null,
      hardenedRuntime: false,
    },
  },
  win: {
    ...base.win,
    target: [
      {target: 'nsis', arch: ['x64']},
      {target: 'portable', arch: ['x64']},
    ],
  },
  publish: null,
};
