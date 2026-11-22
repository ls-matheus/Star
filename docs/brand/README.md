# Star visual identity

This directory contains the Star identity artwork provided by the project maintainer. The **star symbol**, **application icon**, and **Star lettering** are kept as unmodified source SVGs under [sources](sources/).

## Correct logotype and typography

The word "Star" in `star-wordmark-white.svg` and the horizontal logos comes directly from `sources/star-wordmark-original.svg`, provided as `Frame 8.svg`. The letters are **already converted to vector paths**. Do not replace them with a generic sans-serif font or redraw the letterforms.

The original typeface is [**Cherry Bomb One** on Google Fonts](https://fonts.google.com/specimen/Cherry+Bomb+One), designed by Satsuyako. The font is available under [SIL Open Font License 1.1](https://github.com/google/fonts/blob/main/ofl/cherrybombone/OFL.txt). No font binaries are bundled here; SVG wordmarks do **not** require an external font download or runtime network access. If a font file is bundled later, include the font license notice with it.

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

Run `python3 docs/brand/generate.py` from the repository root to regenerate the derived SVGs and replace the SVG logos in the Mobile, Web, and Server source trees. This deliberately leaves **raster launcher icons, splash screens, and all runtime text fonts** unchanged, pending platform-specific review.

The project is independent from Fluxer and does not claim official affiliation or ownership of upstream artwork. See [source provenance](../../NOTICE.md) and [commercial compliance](../commercial-compliance.md) for licensing boundaries.
