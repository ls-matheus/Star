# Contributing to Star

Star is an experimental integration of several sizeable open-source codebases. Contributions should improve one clearly scoped component without accidentally breaking the others.

## Before opening a pull request

1. Check [open issues](https://github.com/ls-matheus/Star/issues) for an existing report or proposal.
2. Describe the problem, affected platform, expected behavior, and steps to reproduce it.
3. For non-trivial work, write a short implementation plan and identify the tests that will demonstrate the change.
4. Create a focused branch. Avoid unrelated formatting or mass rewrites of inherited source trees.

Use the [architecture overview](docs/architecture.md) to identify whether the change belongs in Web, Mobile, Server, or Docker. `Star web/` and `Star Server/` contain separate source snapshots: changing one does not automatically update the other.

## Development checks

Run the lightweight repository tests before requesting review:

```bash
python3 -m unittest discover -s Docker/tests -p 'test_*.py' -v
bash -n Docker/scripts/build-android.sh
bash -n Docker/scripts/prepare-releases.sh
bash -n Docker/scripts/publish-docker-release.sh
```

If installed, run the GitHub Actions linter:

```bash
actionlint .github/workflows/docker-publish.yml
```

For changes to build scripts or GitHub Actions, perform a plan-only workflow run. For application changes, supply logs or test results from the relevant platform. Do not describe validation as a full release build when only static checks ran.

## Pull request checklist

- Explain **why** the change is needed and which component it affects.
- Reference the issue or reproduction steps.
- Add a regression test for a bug fix when practical.
- State which commands and platforms were actually tested.
- Document compatibility, deployment, and security implications.
- Confirm that no private keys, tokens, `.env` files, or production credentials were added.
- Preserve existing third-party notices and license headers.

## Review expectations

Use root-cause investigation rather than repeated speculative patches. Verify failures first, implement a bounded fix, run the relevant tests, and review the final diff for security and maintainability.

The [build and release guide](docs/build-and-release.md) explains how to avoid unnecessary expensive CI builds and how the incremental cache behaves.

## Licensing

By contributing, you agree that your contributions will be distributed under the repository's [AGPL-3.0-or-later license](LICENSE), subject to the applicable component licenses and notices. Retain third-party copyright statements and document any new external dependencies.

## Security issues

**Do not report vulnerabilities in public issues.** Follow [SECURITY.md](SECURITY.md) for coordinated private disclosure.
