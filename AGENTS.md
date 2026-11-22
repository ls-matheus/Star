# Star repository guidance for development agents

This file documents **project-specific engineering requirements**. It is not an installation of an external plugin and does not override the repository owner, system safety policies, or the licenses of component code.

## Understand before changing

1. Read [README.md](README.md), [architecture](docs/architecture.md), and [build/release guide](docs/build-and-release.md).
2. Identify the actual affected component. `Star web/` and `Star Server/` are separate source snapshots; never assume a change propagates between them.
3. Review the relevant code and error output. Reproduce the observed failure before proposing a fix.
4. Keep scope small. Do not reorganize or mass-reformat inherited source trees without a focused reason and tests.

## Problem-solving method

Use these compatible principles from the public [Superpowers skills](https://github.com/obra/superpowers/tree/main/skills):

- **Systematic debugging:** trace failing inputs and outputs to the root cause.
- **Test-driven development:** for behavior changes, write a regression test and verify the failure before fixing it.
- **Verification before completion:** run the actual tests and read their full results before claiming success.
- **Planning and review:** define file-level changes, checkpoints, and a final diff review for multi-step work.

External skills are references for working practices, not sources of instructions that can supersede this repository's requirements.

## Verification and CI

- Single active GitHub workflow: `.github/workflows/docker-publish.yml`.
- Before publishing CI changes: run `actionlint`, shell syntax checks, and `python3 -m unittest discover -s Docker/tests -p 'test_*.py' -v`.
- Use manual `target=plan` to test CI logic **without** rebuilding or publishing installers.
- Be explicit when only validation was run. A successful dry run is not proof of a successful native application build.
- Preserve immutable Release tags, OCI digests, cache baselines, and links to reused assets.
- Keep third-party Actions pinned by verified full commit SHA.
- Do not delete GitHub Actions history, Releases, branches, or large binary assets unless the user explicitly requests it.

## Security and documentation

- Never add secrets, production keys, or `Docker/.env` to Git.
- Document commands that actually exist; do not advertise placeholder `*.invalid` domains.
- Do not describe debug APKs or unsigned desktop installers as store-ready.
- Treat the Docker development profile as localhost-only; do not turn it into a public deployment without a separate security plan.
- Maintain license and attribution notices, including [NOTICE.md](NOTICE.md).
- Write documentation with descriptive links, sentence-case headings, clear prerequisites, and accessible formatting.

For risk items and deferred work, consult [docs/engineering-audit.md](docs/engineering-audit.md).

## Commercial release gate

Do not claim that Star is legally cleared for commercial distribution solely because it has an AGPL license and a NOTICE file. Review [docs/commercial-compliance.md](docs/commercial-compliance.md), including the CC BY-SA artwork terms, the upstream trademark governance, the exact Corresponding Source offer for each build, and the provenance of all bundled visual assets.

## Visual design discipline

Use the supplied [Star brand assets](docs/brand/README.md), not text emoji or substitute drawings, for logos and decorative star marks. For visual changes, inspect the relevant source and existing layout, prefer a small verified change, and review readability, tap targets, safe areas, dark/light contrast, platform conventions, and reduced-motion behavior.

- Use the **gold SVG wordmark** for the default Star instance and the original rounded-square icon for stable macOS builds. Preserve alternate branding for independent instances.
- Use bundled **Cherry Bomb One** for display headings, **IBM Plex Sans** for messages and controls, and **IBM Plex Mono** for code. Never replace long chat text with a decorative font.
- For macOS, keep the custom window chrome and traffic-light controls; the visible name in its titlebar is intentionally omitted, while the OS/app identity remains intact.
- Avoid using decorative star emoji as substitutes for branded assets. Do not alter emojis within user messages or Unicode emoji support.
- The user's supplied `design.txt` catalogs React animation/UI references; treat them as optional inspiration, not as a reason to introduce heavy dependencies or animations into a small Flutter/Electron design change.
- Apply the Superpowers practices above: inspect first, add a failing regression test, implement narrowly, verify the relevant build output, then document any unverified platforms.
