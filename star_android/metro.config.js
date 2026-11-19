// SPDX-License-Identifier: AGPL-3.0-or-later
const path = require('node:path');
const {getDefaultConfig} = require('expo/metro-config');
const config = getDefaultConfig(__dirname);
config.watchFolders = [path.resolve(__dirname, '..')];
config.resolver.nodeModulesPaths = [path.resolve(__dirname, 'node_modules')];
// Keep nested npm dependencies (including expo/node_modules) resolvable.
// App imports originate here; shared Star files contain no React runtime imports.
config.resolver.disableHierarchicalLookup = false;
config.resolver.extraNodeModules = {
  '@star/constants': path.resolve(__dirname, '../packages/constants'),
};
module.exports = config;
