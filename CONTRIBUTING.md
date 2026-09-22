# Contributing

## Workflow

- Open or find an issue first. Substantial work is tracked by an issue before a pull request.
- Branch from `dev` as `feat/<issue>` or `fix/<issue>`. A hotfix branches from `main` as `hotfix/<issue>` and merges back to both.
- Open a draft pull request early, link its issue with `Closes #<issue>`, and mark it ready when the work is complete.
- Pull requests merge into `dev` with a merge commit. `main` only takes release merges from `dev`.
- The `gate` check must pass before a pull request can merge.

## Commits

Commits are small, self-contained [Conventional Commits](https://www.conventionalcommits.org). The issue number is the scope:

```
fix(#12): reject a negative length

Longer explanation if needed.
```

The types are `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `style`, `ci` and `perf`. A breaking change adds `!` before the colon, as in `feat(#12)!: ...`. A change with no issue has no scope (`chore: bump std`), and a release commit is `chore(release): <version>`.

## Labels

Issues are labeled along independent axes, one or more from each that applies:

| axis | labels |
| --- | --- |
| semver magnitude | `patch`, `minor`, `major` |
| kind of work | `feature`, `fix`, `removal`, `chore`, `performance` |
| where, omitted for core code | `testing`, `tooling`, `doc` |
| severity and state | `critical`, `blocked`, `security` |
| discussion | `discussion` |

## Before you push

```sh
mach fmt .
mach test .
```

CI runs the same checks, plus `mach fmt --check .` and a release build of every target.
