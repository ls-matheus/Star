## Summary

Describe the observable change in one or two sentences.

## Motivation

Explain the problem, relevant issue, and how it was reproduced.

## Scope

- [ ] Web / desktop
- [ ] Mobile
- [ ] Server
- [ ] Docker / GitHub Actions
- [ ] Documentation only

## Verification

List the exact commands that were executed and their results. Mark checks that were not run.

- [ ] Python regression suite: `python3 -m unittest discover -s Docker/tests -p 'test_*.py' -v`
- [ ] Workflow validation: `actionlint .github/workflows/docker-publish.yml`
- [ ] Shell syntax checks
- [ ] Target-platform build or runtime test, if applicable

## Risks and compatibility

Describe security, caching, release packaging, source synchronization, or backward-compatibility implications. State explicitly when a build was *not* tested.

## Checklist

- [ ] Change is limited to the affected component.
- [ ] Tests cover any fixed bug where practical.
- [ ] No private keys, personal tokens, or `.env` files were committed.
- [ ] License headers and third-party notices are preserved.
- [ ] Documentation and Release behavior match the implementation.
