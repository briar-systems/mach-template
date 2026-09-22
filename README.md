# mach-template

A starting point for [Mach](https://github.com/briar-systems/mach) projects. It
is a small working library with tests, tiered CI across Linux, Windows and
macOS, tag-driven GitHub releases, and the repository's branch rules and labels
kept as data you can apply with one command.

It follows the layout and workflow the Briar Systems Mach libraries use, scaled
down to what a single project needs.

## Using this template

1. Click **Use this template** on GitHub, or from the command line:

   ```sh
   gh repo create you/mach-widgets --template briar-systems/mach-template --public --clone
   cd mach-widgets
   mach dep pull .
   ```

2. Rename the project id. The id is what consumers write in `use widgets;`.

   ```sh
   tools/rename.sh widgets
   mach test .
   ```

3. Replace this README, set the copyright holder in `LICENSE`, and reset
   `CHANGELOG.md` to an empty `## [Unreleased]` section. Commit and push to
   `main`.

4. Apply the repository settings, labels and rulesets:

   ```sh
   tools/github-apply.sh --prune-labels
   ```

   This creates `dev` from `main` and makes it the default branch, switches the
   repository to merge commits only, replaces GitHub's stock labels with the set
   in `.github/repo/labels.json`, and protects `main`, `dev` and release tags.
   It needs `gh` authenticated with admin rights on the repository, and `jq`.

From here, work happens on branches off `dev`. See [CONTRIBUTING.md](CONTRIBUTING.md).

## Layout

```
src/
  example.mach        library surface: re-exports the public api behind `use example;`
  range.mach          a module with its tests
dep/std               the standard library, a git submodule pinned by mach
mach.toml             manifest: targets, profiles, the library artifact, dependencies
CHANGELOG.md          release notes, one section per version
tools/
  rename.sh           rename the project id
  github-apply.sh     apply .github/repo to the GitHub repository
  changelog.sh        print one version's changelog section
.github/
  ci/legs.json        the runners CI builds and tests on
  mach-version        the mach release CI installs
  actions/setup-mach  installs that release, verified against its SHA256SUMS
  workflows/ci.yml    pull request CI
  workflows/cd.yml    tag-driven release
  repo/               settings, labels and rulesets, as data
```

Tests live beside the code they test, as `test "name" { ... }` blocks that
return 0 on success. `mach test .` runs every one of them.

## Branches

| branch | role |
| --- | --- |
| `dev` | default branch. Feature and fix branches merge here |
| `main` | releases only. Takes merges from `dev` and hotfixes |
| `feat/<n>`, `fix/<n>` | work for issue `n`, branched from `dev` |
| `hotfix/<n>` | urgent fix branched from `main`, merged to both |

The `branches` ruleset requires a pull request and a passing `gate` check on
`main` and `dev`, and forbids deleting or force-pushing either. Only merge
commits are allowed, so history shows exactly what each pull request brought in.
Repository admins can bypass the rules, which is how a maintainer cuts a
release merge. The `release tags` ruleset stops anyone but an admin from moving
or deleting a `v*` tag once it is pushed.

## CI

`ci.yml` runs on pull requests only. A merge is covered because a pull request
builds the merge result, not the branch tip.

- A pull request into `dev` runs the **light** legs, which by default is
  `x86_64-linux` alone.
- A pull request into `main` runs **every** leg: `aarch64-linux`,
  `x86_64-windows`, `aarch64-darwin` and `x86_64-darwin` as well.
- **Run workflow** in the Actions tab, or `gh workflow run CI --ref <branch> -f heavy=all`,
  runs every leg on any branch.

Each leg installs mach, pulls dependencies, then builds and tests in `debug` and
`release`. The first leg also checks formatting and builds every target in the
manifest. To add or retier a runner, edit `.github/ci/legs.json`. The first
entry must stay light.

Every job feeds a final job named `gate`, which is the one check the rulesets
require. It fails if any job failed, and also if a job in `ci.yml` is missing
from its `needs`, so a new job cannot slip past it. When you add a job, add it
to `gate`'s `needs`.

To move to a newer compiler, change `.github/mach-version` and the `mach`
range in `mach.toml` together.

## Releases

1. Move the `## [Unreleased]` notes into a `## [X.Y.Z] - date` section of
   `CHANGELOG.md` and set `version = "X.Y.Z"` in `mach.toml`. Commit it as
   `chore(release): X.Y.Z`.
2. Merge `dev` into `main` through a pull request. That runs every leg.
3. Tag the merge and push the tag:

   ```sh
   git switch main && git pull
   git tag vX.Y.Z && git push origin vX.Y.Z
   ```

4. Merge `main` back into `dev`.

`cd.yml` checks that the tag matches the manifest version and that the
changelog has a section for it, runs every CI leg on the tagged commit, and
then publishes a GitHub release with that section as its notes. A version with
a prerelease part, such as `1.0.0-rc.1`, is published as a prerelease. Pushing
the same tag twice never creates a second release.

Consumers depend on the library by version range, and mach resolves ranges
against these tags:

```sh
mach dep add . widgets --git https://github.com/you/mach-widgets --version ^0.1
```

## License

MIT. See [LICENSE](LICENSE).
