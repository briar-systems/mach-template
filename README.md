# mach-template

<!-- template -->
A bone stock [Mach](https://github.com/briar-systems/mach) 6.3 Hello, World,
the project `mach init` makes with every host target declared and its entry at
`src/bin/<id>.mach`, with a GitHub repository set up around it: pull request CI
on Linux, Windows and macOS, tag-driven releases with prebuilt binaries,
protected branches, and a label set.

## Using this template

```sh
gh repo create <owner>/<repo> --template briar-systems/mach-template --public --clone
cd <repo>
./setup.sh
```

`setup.sh` is run-and-delete. It runs once, removes itself in the commit it
makes, and is never needed again. If it fails partway, fix the cause and run
it again. It:

- sets the project id to the repository name, minus any leading `mach-` and
  with dashes turned into underscores, and renames the entry file to match.
  Pass an id to choose another: `./setup.sh <id>`
- removes this section from the README
- commits and pushes those changes
- creates the `main` and `dev` branches and makes `dev` the default
- allows merge commits only
- replaces GitHub's stock labels with the set below
- adds rulesets that protect `main`, `dev` and `v*` tags

It needs `git` and `gh`, logged in with admin rights on the repository.
Update the copyright holder in `LICENSE` yourself.
<!-- /template -->

## Build

```sh
mach dep pull .
mach build .
mach run .
mach test . --timeout 5m
```

## Workflow

`dev` is the default branch. Work branches from it as `feat/<issue>` or
`fix/<issue>` and merges back through a pull request. `main` only takes release
merges from `dev`. A `hotfix/<issue>` branches from `main` and merges into both.

Both branches require a pull request and a passing `gate` check. Neither can be
deleted or force-pushed, and pull requests merge with a merge commit. Repository
admins can bypass these rules to cut a release. Once a `v*` tag is pushed, only
an admin can move or delete it.

Commits follow [Conventional Commits](https://www.conventionalcommits.org), with
the issue number as the scope: `fix(#12): reject a negative length`.

Issues are labeled on independent axes:

| axis | labels |
| --- | --- |
| semver magnitude | `patch`, `minor`, `major` |
| kind of work | `feature`, `fix`, `removal`, `chore`, `performance` |
| where, omitted for core code | `testing`, `tooling`, `doc` |
| severity and state | `critical`, `blocked`, `parked`, `security` |
| discussion | `discussion` |

## CI

`.github/workflows/ci.yml` runs on pull requests and on dispatch. It spins up one
native runner per host OS and ISA that `mach.toml` declares a target for, and
each runs `mach test . --all` for its own targets. One Linux runner also checks
formatting and builds every target, including those no runner can execute, such
as riscv. Those are built, never tested, in CI. Nothing runs under emulation.

The host table is in the `plan` job. Delete a row to stop testing on that host
while still building for it. Anything else a project needs goes in as its own job
in `ci.yml`, listed in `gate`'s `needs`.

`gate` is the check the branch rules require. It fails if any job it needs
failed or was cancelled.

The compiler version is `MACH_VERSION`, an exact release, in `ci.yml` and
`cd.yml`. Change it together with the `mach` range in `mach.toml`.

## Releases

1. Set `version` in `mach.toml` and merge that into `dev`.
2. Merge `dev` into `main`.
3. Tag `main` and push the tag: `git tag vX.Y.Z && git push origin vX.Y.Z`.

`.github/workflows/cd.yml` checks that the tag matches the manifest version,
runs CI in the release profile, builds every artifact for every target in
release, and publishes a GitHub release. Each artifact is packaged per target
(`.zip` for Windows, `.tar.gz` elsewhere) with `SHA256SUMS`. Names and paths come
from `mach build --plan`, so a new target or artifact needs no workflow change.
The notes are the version's `CHANGELOG.md` section, or generated from merged pull
requests when there is none. A tag with a prerelease part, such as `v1.0.0-rc.1`,
is published as a prerelease.

## License

MIT. See [LICENSE](LICENSE).
