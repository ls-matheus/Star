---
# SPDX-License-Identifier: AGPL-3.0-or-later
title: Linux repositories
description: How to add the apt, dnf, pacman and Flatpak repositories Star publishes.
---

Star publishes apt, dnf, pacman and Flatpak repositories, all signed with the key whose fingerprint is `09D01339EE128925F75E675C855C5BDE34D205D2`. You pick the channel with the entry file on apt and dnf, by package name on pacman and by app ID on Flatpak.

| Package manager | Pick stable with | Pick canary with |
| --- | --- | --- |
| apt | `star.sources` | `star-canary.sources` |
| dnf | `star.repo` | `star-canary.repo` |
| pacman | `star` | `star-canary` |
| Flatpak | `app.star.Star` | `app.star.StarCanary` |

## Debian and Ubuntu

```sh
sudo install -d -m 0755 /etc/apt/keyrings
sudo curl -fsSL -o /etc/apt/keyrings/star-archive-keyring.gpg \
  https://pkgs.star.invalid/keys/star-archive-keyring.gpg
sudo curl -fsSL -o /etc/apt/sources.list.d/star.sources \
  https://pkgs.star.invalid/deb/star.sources
sudo apt update && sudo apt install star
```

A `.deb` you downloaded only gets updates after you add the entry for its channel. For canary, add the canary entry and install `star-canary`.

```sh
sudo curl -fsSL -o /etc/apt/sources.list.d/star-canary.sources \
  https://pkgs.star.invalid/deb/star-canary.sources
sudo apt update && sudo apt install star-canary
```

## Fedora and RHEL

RHEL, Rocky, Alma and CentOS Stream need `sudo dnf install epel-release` first, because the package depends on `libXScrnSaver`.

```sh
sudo curl -fsSL -o /etc/yum.repos.d/star.repo \
  https://pkgs.star.invalid/rpm/star.repo
sudo dnf install star
```

dnf asks you to import the signing key on the first install, once for the repository and once for the package. Check that the fingerprint matches the one above both times.

For canary, add the canary entry and install `star-canary`.

```sh
sudo curl -fsSL -o /etc/yum.repos.d/star-canary.repo \
  https://pkgs.star.invalid/rpm/star-canary.repo
sudo dnf install star-canary
```

dnf keeps the repository metadata for six hours, so a new build can take up to six hours to show up. Run `sudo dnf --refresh upgrade` to check sooner.

## Arch Linux

Add the signing key to the pacman keyring once, or pacman refuses the repository with `unknown trust`.

```sh
sudo pacman-key --init
curl -fsSL -o /tmp/star-archive-keyring.asc \
  https://pkgs.star.invalid/keys/star-archive-keyring.asc
sudo pacman-key --add /tmp/star-archive-keyring.asc
sudo pacman-key --lsign-key 09D01339EE128925F75E675C855C5BDE34D205D2
```

Then add the repository and install `star` or `star-canary`.

```sh
sudo tee -a /etc/pacman.conf >/dev/null <<'REPO'

[star]
SigLevel = Required TrustedOnly
Server = https://pkgs.star.invalid/arch/$repo/os/$arch
REPO
sudo pacman -Syu star
```

## Flatpak

Stable is also on Flathub as `app.star.Star`, but canary is only in the Star repository. The reference file adds a remote called `star` and installs the app.

```sh
flatpak install https://pkgs.star.invalid/flatpak/star.flatpakref
```

For canary, use the canary reference file.

```sh
flatpak install https://pkgs.star.invalid/flatpak/star-canary.flatpakref
```
