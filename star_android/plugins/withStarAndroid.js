// SPDX-License-Identifier: AGPL-3.0-or-later
// Generated native resources are reproducible from this plugin; no upstream logo is renamed.
const {withAndroidManifest, withDangerousMod} = require('expo/config-plugins');
const fs = require('node:fs');
const path = require('node:path');
module.exports = function withStarAndroid(config) {
  config = withAndroidManifest(config, result => {
    const app = result.modResults.manifest.application[0].$;
    app['android:icon'] = '@drawable/star_launcher';
    app['android:roundIcon'] = '@drawable/star_launcher';
    app['android:usesCleartextTraffic'] = 'false';
    app['android:allowBackup'] = 'false';
    return result;
  });
  return withDangerousMod(config, ['android', async result => {
    const dir = path.join(result.modRequest.platformProjectRoot, 'app/src/main/res/drawable');
    fs.mkdirSync(dir, {recursive: true});
    fs.writeFileSync(path.join(dir, 'star_launcher.xml'), `<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
  <path android:fillColor="#4641D9" android:pathData="M0,0H108V108H0Z"/>
  <path android:fillColor="#FFFFFF" android:pathData="M54,18L63,42L89,43L69,60L76,86L54,71L32,86L39,60L19,43L45,42Z"/>
</vector>`);
    return result;
  }]);
};
