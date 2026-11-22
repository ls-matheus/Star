# Star visual identity

This directory contains the Star identity artwork provided by the project maintainer. The **star symbol**, **application icon**, and **Star lettering** are kept as unmodified source SVGs under [sources](sources/).

## Correct logotype and typography

The word "Star" in `star-wordmark-white.svg` and the horizontal logos comes directly from `sources/star-wordmark-original.svg`, provided as `Frame 8.svg`. The letters are **already converted to vector paths**. Do not replace them with a generic sans-serif font or redraw the letterforms.

The original typeface is [**Cherry Bomb One** on Google Fonts](https://fonts.google.com/specimen/Cherry+Bomb+One), designed by Satsuyako. The font is available under [SIL Open Font License 1.1](https://github.com/google/fonts/blob/main/ofl/cherrybombone/OFL.txt). SVG wordmarks remain font-independent and require no runtime download. The mobile app bundles `CherryBombOne-Regular.ttf` **only for display headings**, with the original OFL notice in `Star mobile/assets/fonts/OFL-CherryBombOne.txt`. Chat messages, settings, inputs, and body text retain the legible IBM Plex Sans.

The brand typeface is for display lettering. Do not automatically apply it to chats, settings, input fields, or body text.

## Palette

| Color | Hex | Use |
| --- | --- | --- |
| Primary gold | `#D68F00` | App icon and brand |
| Deep gold | `#B87A00` | Large accents in supplied brand board |
| Cream | `#EDD082` | Alternate colored star |
| Soft yellow | `#FFD052` | Decorative star |
| Bright yellow | `#FFBA00` | Decorative star |
| White | `#FFFFFF` | Dark-background lettering |

## Files and usage

- `star-logo-badge.svg`: golden rounded rectangle with white symbol and **Star** wordmark
- `star-logo-horizontal-gold.svg`: symbol and letters in gold, for white or light backgrounds
- `star-logo-horizontal-white.svg`: white symbol and letters for dark or golden backgrounds
- `star-wordmark-gold.svg` and `star-wordmark-white.svg`: title only
- `star-symbol-gold.svg`, `star-symbol-white.svg`, `star-symbol-cream.svg`: star icon only
- `sources/star-app-icon-original.svg`: original rounded-square app icon
- `sources/star-brand-board-original.svg`: original reference sheet

Run `python3 docs/brand/generate.py` from the repository root to regenerate the derived SVGs and replace the SVG logos in the Mobile, Web, and Server source trees.

On macOS, run `bash docs/brand/build-macos-icon.sh` to rebuild the **stable-channel** `.icns` Dock/Finder icon and PNG sizes in both Web and Server from the exact supplied `sources/star-app-icon-original.svg`. The source is rendered at 1024 px before any downscaling, and the Electron builder selects `icons-stable/_compiled/AppIcon.icns` for stable releases.

Mobile's login and lock screens use the existing `InstanceWordmark` widget. For the default instance it displays the golden brand SVG; custom instance wordmarks and names still work. The decorative Cherry Bomb One font is used for short headings while other text stays accessible. The **Android and iOS launcher icon assets and splash screens** are not changed by these commands.

The project is independent from Fluxer and does not claim official affiliation or ownership of upstream artwork. See [source provenance](../../NOTICE.md) and [commercial compliance](../commercial-compliance.md) for licensing boundaries.
