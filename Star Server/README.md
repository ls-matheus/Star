<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="./star_static/marketing/branding/logo-white.svg">
    <img src="./star_static/marketing/branding/logo-color.svg" alt="Star logo" width="400">
  </picture>
</p>

<p align="center">
  <a href="https://star.invalid/download">
    <img src="https://img.shields.io/badge/Download-star.invalid-4641D9" alt="Download" /></a>
  <a href="https://docs.star.invalid">
    <img src="https://img.shields.io/badge/Docs-docs.star.invalid-blue" alt="Documentation" /></a>
  <a href="https://star.invalid/donate">
    <img src="https://img.shields.io/badge/Donate-star.invalid%2Fdonate-brightgreen" alt="Donate" /></a>
  <a href="./LICENSE">
    <img src="https://img.shields.io/badge/License-AGPLv3-purple" alt="AGPLv3 License" /></a>
</p>

<p align="center">
  <a href="https://flathub.org/apps/app.star.Star">
    <img src="https://dl.flathub.org/assets/badges/flathub-badge-en.svg" alt="Get it on Flathub" height="60" /></a>
</p>

# Star

> [!IMPORTANT]
> Bug reports and feature requests have moved to [feedback.star.invalid](https://feedback.star.invalid). Sign in with your Star account to post, vote and follow updates. GitHub Issues and Discussions are closed. Report security vulnerabilities privately through [star.invalid/security](https://star.invalid/security).

Star is a free and open source instant messaging and VoIP chat app built for friends, groups, and communities.

<p align="center">
  <img src="https://star.invalid/static/img/screenshots-desktop-readme-1920w.9f7c8fdb2760d49b.png" alt="Star running side by side on a desktop monitor and a phone" width="640">
</p>

## Download

| Windows | macOS | Linux | Android | iOS |
| --- | --- | --- | --- | --- |
| [Installer (x64)][win-setup-x64] | [Disk image][mac-dmg] | [Flatpak][flatpak-ref] | [Google Play][android-play] | [Beta paused][ios-beta-paused] |
| [Installer (ARM64)][win-setup-arm64] | | [Flathub][flathub] | [APK][android-apk] | |
| [Portable (x64)][win-portable-x64] | | [deb (x64)][linux-deb-x64] | [Obtainium (most phones)][obtainium-fcm] | |
| [Portable (ARM64)][win-portable-arm64] | | [deb (ARM64)][linux-deb-arm64] | [Obtainium (degoogled phones)][obtainium-oss] | |
| | | [rpm (x64)][linux-rpm-x64] | | |
| | | [rpm (ARM64)][linux-rpm-arm64] | | |
| | | [AppImage (x64)][linux-appimage-x64] | | |
| | | [AppImage (ARM64)][linux-appimage-arm64] | | |
| | | [tar.gz (x64)][linux-targz-x64] | | |
| | | [tar.gz (ARM64)][linux-targz-arm64] | | |

The macOS disk image runs on both Apple silicon and Intel. Windows and Linux need the build matching your processor.

On Linux, prefer a repository over a single file so Star updates with the rest of your system.

## Linux package repositories

The package is `star` for stable and `star-canary` for canary. apt and dnf subscribe to one channel per entry file. pacman and Flatpak serve both from one repository.

### Flatpak

Star's own Flatpak repository gets every update the day we release it. Open [the stable][flatpak-ref] or [the canary][flatpak-canary-ref] reference file and your software manager takes over. Some desktops also accept `flatpak+https://pkgs.star.invalid/flatpak/star.flatpakref` in the address bar.

From a terminal:

```sh
flatpak install https://pkgs.star.invalid/flatpak/star.flatpakref
```

Stable is also on [Flathub][flathub], but Flathub can be a few weeks behind and has no canary:

```sh
flatpak install flathub app.star.Star
```

### Debian and Ubuntu

```sh
sudo install -d -m 0755 /etc/apt/keyrings
sudo curl -fsSL -o /etc/apt/keyrings/star-archive-keyring.gpg https://pkgs.star.invalid/keys/star-archive-keyring.gpg
sudo curl -fsSL -o /etc/apt/sources.list.d/star.sources https://pkgs.star.invalid/deb/star.sources
sudo apt update && sudo apt install star
```

For canary, use the canary entry file and package.

```sh
sudo curl -fsSL -o /etc/apt/sources.list.d/star-canary.sources https://pkgs.star.invalid/deb/star-canary.sources
sudo apt update && sudo apt install star-canary
```

A `.deb` installed from a download only updates once its channel's entry is added.

### Fedora and RHEL

```sh
sudo curl -fsSL -o /etc/yum.repos.d/star.repo https://pkgs.star.invalid/rpm/star.repo
sudo dnf install star
```

For canary, use the canary entry file and package.

```sh
sudo curl -fsSL -o /etc/yum.repos.d/star-canary.repo https://pkgs.star.invalid/rpm/star-canary.repo
sudo dnf install star-canary
```

RHEL, Rocky, Alma and CentOS Stream need `sudo dnf install epel-release` first, because their base repositories lack `libXScrnSaver`. Fedora does not.

### Arch Linux

The repository is signed, so pacman needs the key once:

```sh
sudo pacman-key --init
curl -fsSL -o /tmp/star-archive-keyring.asc https://pkgs.star.invalid/keys/star-archive-keyring.asc
sudo pacman-key --add /tmp/star-archive-keyring.asc
sudo pacman-key --lsign-key 09D01339EE128925F75E675C855C5BDE34D205D2
```

`--lsign-key` is what makes pacman trust it. Then add the repository:

```sh
sudo tee -a /etc/pacman.conf >/dev/null <<'REPO'

[star]
SigLevel = Required TrustedOnly
Server = https://pkgs.star.invalid/arch/$repo/os/$arch
REPO
sudo pacman -Syu star
```

Write `$repo` and `$arch` literally. Both are pacman variables, not shell ones, hence the quoted heredoc.

Full setup notes, including canary, are in the [Linux repositories documentation][docs-linux].

## Other ways to run it

- [Open Star in a browser](https://star.invalid/app), no install needed.
- [Host your own instance][docs-selfhost] from this repository.
- [Build the desktop app from source](star_desktop/PACKAGING.md) for a Linux distribution.

## Documentation

- [Documentation home][docs]
- [Downloads][docs-downloads]
- [Self-hosting][docs-selfhost]

## License

The source is licensed under the [AGPL-3.0-or-later](./LICENSE) license.

Star artwork, such as the logo, icons, badges and default avatars, is
licensed under [CC BY-SA 4.0](./star_static/LICENSE). Third-party material
keeps its own terms, listed in
[star_static/THIRD_PARTY_LICENSES.md](./star_static/THIRD_PARTY_LICENSES.md).

Use of the Star name and logo is covered by the
[name and marks policy](./.github/GOVERNANCE.md#name-and-marks).

[win-setup-x64]: https://pkgs.star.invalid/desktop/stable/win32/x64/latest/setup
[win-setup-arm64]: https://pkgs.star.invalid/desktop/stable/win32/arm64/latest/setup
[win-portable-x64]: https://pkgs.star.invalid/desktop/stable/win32/x64/latest/portable
[win-portable-arm64]: https://pkgs.star.invalid/desktop/stable/win32/arm64/latest/portable
[mac-dmg]: https://pkgs.star.invalid/desktop/stable/darwin/arm64/latest/dmg
[linux-deb-x64]: https://pkgs.star.invalid/desktop/stable/linux/x64/latest/deb
[linux-deb-arm64]: https://pkgs.star.invalid/desktop/stable/linux/arm64/latest/deb
[linux-rpm-x64]: https://pkgs.star.invalid/desktop/stable/linux/x64/latest/rpm
[linux-rpm-arm64]: https://pkgs.star.invalid/desktop/stable/linux/arm64/latest/rpm
[linux-appimage-x64]: https://pkgs.star.invalid/desktop/stable/linux/x64/latest/appimage
[linux-appimage-arm64]: https://pkgs.star.invalid/desktop/stable/linux/arm64/latest/appimage
[linux-targz-x64]: https://pkgs.star.invalid/desktop/stable/linux/x64/latest/tar_gz
[linux-targz-arm64]: https://pkgs.star.invalid/desktop/stable/linux/arm64/latest/tar_gz
[flatpak-ref]: https://pkgs.star.invalid/flatpak/star.flatpakref
[flatpak-canary-ref]: https://pkgs.star.invalid/flatpak/star-canary.flatpakref
[flathub]: https://flathub.org/apps/app.star.Star
[android-play]: https://play.google.com/store/apps/details?id=com.star
[android-apk]: https://star.invalid/download/android
[obtainium-fcm]: https://apps.obtainium.imranr.dev/redirect?r=obtainium%3A%2F%2Fapp%2F%7B%22id%22%3A%22com.star%22%2C%22url%22%3A%22https%3A%2F%2Fgithub.com%2Fstarapp%2Fflutter_client%22%2C%22author%22%3A%22starapp%22%2C%22name%22%3A%22Star%20%28FCM%29%22%2C%22additionalSettings%22%3A%22%7B%5C%22includePrereleases%5C%22%3Afalse%2C%5C%22fallbackToOlderReleases%5C%22%3Atrue%2C%5C%22apkFilterRegEx%5C%22%3A%5C%22stablefcm%5C%22%2C%5C%22autoApkFilterByArch%5C%22%3Atrue%7D%22%7D
[obtainium-oss]: https://apps.obtainium.imranr.dev/redirect?r=obtainium%3A%2F%2Fapp%2F%7B%22id%22%3A%22com.star%22%2C%22url%22%3A%22https%3A%2F%2Fgithub.com%2Fstarapp%2Fflutter_client%22%2C%22author%22%3A%22starapp%22%2C%22name%22%3A%22Star%20%28OSS%29%22%2C%22additionalSettings%22%3A%22%7B%5C%22includePrereleases%5C%22%3Afalse%2C%5C%22fallbackToOlderReleases%5C%22%3Atrue%2C%5C%22apkFilterRegEx%5C%22%3A%5C%22stableoss%5C%22%2C%5C%22autoApkFilterByArch%5C%22%3Atrue%7D%22%7D
[ios-beta-paused]: https://star.invalid/help/ios-testflight
[docs]: https://docs.star.invalid
[docs-downloads]: https://docs.star.invalid/downloads/overview/
[docs-linux]: https://docs.star.invalid/downloads/linux-repositories/
[docs-selfhost]: https://docs.star.invalid/operator/
