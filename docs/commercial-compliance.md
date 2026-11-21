# Commercial distribution compliance review

**Status: NOT CLEARED for unconditional commercial distribution.** This is an evidence-based engineering and licensing review, not a legal opinion or permission from the copyright or trademark holders. Reviewed on 2026-11-21.

## Sources and verified licenses

| Material | Evidence | Applicable conditions |
| --- | --- | --- |
| Web/Server source | `Star web/LICENSE`, `Star Server/LICENSE` | GNU AGPL v3 license text; preserve notices and provide Corresponding Source under applicable conditions |
| Mobile source | `Star mobile/LICENSE` and `LICENSE-APPSTORE-EXCEPTION` | AGPL v3 plus a section 7 application-store additional permission; it does not waive the other AGPL obligations |
| Fluxer-owned artwork | `Star web/star_static/LICENSE` and `Star Server/star_static/LICENSE` | CC BY-SA 4.0 for covered original artwork; attribution, license link, modification indication, and ShareAlike for adapted artwork; **no trademark rights** |
| Bundled third-party artwork | `Star web/star_static/THIRD_PARTY_LICENSES.md` | Twemoji CC BY 4.0, other assets under their respective licenses |
| Fonts and embedded libraries | `packages/fonts/NOTICE.md`, `star_app/rust/*/NOTICE.md`, `star_app/src/features/voice/utils/noise_suppression/NOTICE.md` | Retain component-specific notices and license files |
| Project governance and marks | https://github.com/fluxerapp/fluxer/blob/main/.github/GOVERNANCE.md | Substantively modified forks must use a distinct name and logo; other uses of Fluxer marks need permission |
| AGPL requirements | https://www.gnu.org/licenses/agpl-3.0.html | Sections 4–6 (distribution, modification notices, corresponding source), 7 (additional terms), 13 (remote network users) |

The source trees contain historical upstream path names and third-party notices. Renaming an asset or a code symbol does not automatically extinguish its copyright, license, or trademark implications.

## Immediate findings

1. **Code:** Root AGPL text is present, but a repository-level LICENSE does not establish compliance for every included asset or dependency. Do not represent the whole repository or every binary as exclusively AGPL-licensed.
2. **Artwork:** The static asset directories contain CC BY-SA 4.0 artwork and third-party CC BY 4.0 assets. Their license and attribution files must accompany redistribution in an accessible form. Some files have Star names; whether each is original, a permitted adaptation, or derived from protected Fluxer artwork has **not** been established by the filename.
3. **Brand:** The upstream governance explicitly restricts use of the Fluxer name and logo for substantively changed forks. Star uses its own name, but every icon, splash screen, default avatar, email template, social preview, desktop installer icon, and marketing graphic still needs a visual/provenance review.
4. **Mobile:** The upstream app-store additional permission is included, but distribution must still comply with the applicable source and attribution terms. Store acceptance and signing are separate matters.
5. **Binaries and network service:** A public GitHub repository is helpful but not by itself proof that every exact distributed APK, EXE, DMG, Docker image, and running server exposes the correct Corresponding Source, build scripts, legal notices, and modification dates.
6. **Third parties:** Bundled libraries, fonts, dictionaries, emoji and media require license-by-license verification of what is included in each final binary. No complete generated SBOM or binary-level notice audit has been performed.

## Required release gate (before selling or distributing widely)

- [ ] **Source provenance:** identify the exact upstream commit(s) and dates for Web/Server and Mobile, plus every material modification. Preserve copyright notices and mark changes and dates prominently where required.
- [ ] **Source offer:** publish a source archive for the **exact binary build**, including the Corresponding Source, necessary build scripts and installation information required by the applicable AGPL sections. Link it prominently from each downloadable binary's Release.
- [ ] **Network users:** ensure any modified AGPL service offered to remote users prominently provides the corresponding source through the application or a network-accessible notice, as applicable under AGPL section 13.
- [ ] **Legal notices in interfaces:** check whether interactive clients display the notices required by AGPL section 5(d); verify existing upstream notices before modifying them.
- [ ] **Brand independence:** visually compare every distributed Star logo, icon, splash, avatar, email and marketing asset with the original Fluxer marks; replace confusing marks with demonstrably original designs or obtain explicit permission from Fluxer Platform AB.
- [ ] **CC BY-SA 4.0:** for any reused Fluxer artwork, include the creator attribution, original license link, change indication, and adapted-material license when required. Do not imply endorsement.
- [ ] **Third-party notices:** produce and ship an accurate notice bundle for each platform; inspect the actual packaged assets, fonts, media and dependency licenses.
- [ ] **Mobile exception:** retain the app-store additional permission only where applicable and confirm the exact distribution method does not add conflicting restrictions.
- [ ] **Commercial terms:** do not promise proprietary exclusivity over AGPL-covered source. Any commercial service or support agreement must respect recipients' existing license rights.
- [ ] **Independent review:** have qualified intellectual-property counsel review brand identity, asset provenance, AGPL distribution/source-offer compliance, and intended countries/marketplaces before commercial launch.

## Practical attribution

A suggested attribution statement for the README, Releases, and an in-app Open Source Licenses screen:

> Star is an independent project derived in part from Fluxer open-source software (https://github.com/fluxerapp/fluxer) and the Fluxer Flutter client (https://github.com/fluxerapp/flutter_client). Applicable source-code components are provided under the GNU Affero General Public License v3, subject to their respective notices and additional permissions. Artwork and other third-party resources retain their own licenses, including CC BY-SA 4.0 where applicable. Star is not affiliated with or endorsed by Fluxer Platform AB. See NOTICE.md and the component license files for details.

This text is **not a substitute** for asset-specific author credits, modification indications, complete license notices, or an appropriate source-code offer.

## References

- [Fluxer governance, including names and marks](https://github.com/fluxerapp/fluxer/blob/main/.github/GOVERNANCE.md)
- [Fluxer static artwork license](https://github.com/fluxerapp/fluxer/blob/main/fluxer_static/LICENSE)
- [Fluxer third-party asset notices](https://github.com/fluxerapp/fluxer/blob/main/fluxer_static/THIRD_PARTY_LICENSES.md)
- [Fluxer Flutter client](https://github.com/fluxerapp/flutter_client)
- [GNU AGPLv3 official text](https://www.gnu.org/licenses/agpl-3.0.html)
- [Creative Commons BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)
