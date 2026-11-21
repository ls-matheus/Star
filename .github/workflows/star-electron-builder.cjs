// SPDX-License-Identifier: AGPL-3.0-or-later
// CI: distribuições para teste, sem assinatura nem notarizacao comercial.
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../..');
const sourceDir = fs.existsSync(path.join(root, 'starweb', 'star_desktop'))
  ? 'starweb'
  : 'Star web';
const original = require(path.join(root, sourceDir, 'star_desktop', 'electron-builder.config.cjs'));
const signing = {...(original.mac?.sign || {}), identity: null, hardenedRuntime: false};
delete signing.provisioningProfile;

module.exports = {
  ...original,
  mac: {
    ...original.mac,
    notarize: false,
    sign: signing,
  },
  win: {
    ...original.win,
    target: [
      {target: 'nsis', arch: ['x64']},
      {target: 'portable', arch: ['x64']},
    ],
  },
  publish: null,
};
