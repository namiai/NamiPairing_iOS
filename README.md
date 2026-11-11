# NamiPairing_iOS repository migration

This branch holds the tooling that replaces the NamiPairing_iOS Swift package
repository (≈2.3 GB, every release's `.xcframework` committed) with a
manifest-only repository (<2 MB) whose binaries are GitHub Release assets.
Partner-facing plan and the one-time cache reset partners run afterwards:
Notion, "Communication - Optimize SwiftPM Package Distribution".

The branch is an orphan: it shares no history with `main`, so it adds nothing
to a clone, and `migrate.sh` pushes it into the new repository so the tooling
stays with the package it migrated.

## Why a new repository instead of rewriting history in place

SwiftPM and Xcode clone packages with `git clone --mirror` (`+refs/*:refs/*`).
That fetches GitHub's `refs/pull/N/head` refs, which cannot be deleted or
moved and keep every object of the closed pull requests reachable — for this
repository, more bytes than all release tags together. A force-pushed thin
`main` would therefore change nothing for SwiftPM consumers, and GitHub
Support removes pull request refs only for sensitive data.

A new repository has none of that. It is prepared under a temporary name and
takes over the original name with two renames, so the URL, the tags and the
partner instructions are unchanged. GitHub documents that a renamed
repository's old name may be reused and that the redirect then stops; that is
exactly the intent.

## The flow

```
now ──── PHASE=prepare ──── after each release: PHASE=prepare ──── migration day: PHASE=all
         builds _next        syncs the new tag into _next          final sync, then the swap
```

Nothing before the swap is visible to consumers; the swap is the go-live.
Releases keep going out of the old pipeline into the old repository until the
swap; each one is synced into `_next` by re-running `PHASE=prepare`, which
takes minutes because only the new tag is built and uploaded. Rollback is two
renames: [ROLLBACK.md](ROLLBACK.md).

## What `migrate.sh` does

`PHASE=prepare`:

1. Mirror-clones the source into `WORKDIR/source.git`, or refreshes the
   mirror. This is the local backup; keep it until the grace period ends.
2. Snapshots the source's settings, releases, collaborators and teams.
3. Builds the thin history: one commit per tag in commit-date order, same
   author, message and dates as the original tag commit, every `.xcframework`
   zipped (`ditto -c -k --keepParent`) and replaced in `Package*.swift` by
   `url: https://github.com/<source>/releases/download/<tag>/<name>.xcframework.zip`
   plus its SHA-256. All other branches are dropped. The build is
   incremental: tags already built are kept untouched and new tags are
   appended, so tags already pushed to `_next` never move. A tag that is
   already asset-backed (released by the new CI) keeps its manifests and has
   its assets re-hosted.
4. Creates `<source>_next` (public, same description and feature flags) on
   the first run, pushes `main`, the tags and this branch.
5. Creates one release per tag with its zip. The eleven releases that exist on
   the source keep their titles and notes; the others get a one-line note.
   The highest version is marked *Latest*.
6. Copies direct collaborators (including the CI bot) and teams with their
   permissions. Access that comes from organization membership needs no copy;
   the repository is public anyway. An outside collaborator, if one is ever
   added, receives an invitation they must accept.
7. Verifies: tags on `_next` equal the thin repository's, every release is
   published with an asset, and the highest version's asset checksum matches
   its manifest.

`PHASE=swap` (under a minute):

8. Renames `<source>` to `<source>_legacy`, then `<source>_next` to
   `<source>`. Between the two renames GitHub redirects the original name to
   `_legacy`, so nothing breaks in the gap.
9. Verifies that the original name serves the thin tags and that the highest
   version's asset downloads.

`PHASE=all` runs both: a final sync, then the swap. Every GitHub step is
idempotent, so re-running after an interruption continues where it stopped.

### Out-of-order releases

A hotfix tagged with a lower version than the newest release (say `4.8.4`
after `5.4.4`) is just another tag: the sync appends its commit to the chain
in date order. `main` and *Latest* stay on the highest version, so the hotfix
never takes over the default branch. The branch the hotfix lives on in the
old repository is irrelevant; only tags are migrated.

What the sync refuses, with a message: a tag that was moved on the source
after it was built, and a new tag whose commit is older than tags already
built (it would have to be inserted into the chain, moving every later tag).
Both mean: delete `WORKDIR/thin` and `WORKDIR/assets`, re-run — and if
`_next` already holds the affected tags, delete `_next` and start over; it is
invisible to consumers until the swap.

## Running it

Requirements: bash 3.2+, git, `gh` authenticated as an **admin of the
source repository** (`gh auth login`), jq, ditto, shasum, perl, curl. The
first prepare zips ~60 releases (minutes) and uploads ~2.3 GB of assets
(about 1.5 hours in the September rehearsal); a sync afterwards takes
minutes.

```bash
git clone --branch migration/release-assets git@github.com:namiai/NamiPairing_iOS.git namipairing-migration
cd namipairing-migration

# See the plan without touching GitHub (the local build still runs):
DRY_RUN=1 PHASE=prepare ./migrate.sh

# Build the new repository:
PHASE=prepare ./migrate.sh

# After every release made on the old repository in the meantime:
PHASE=prepare ./migrate.sh

# Migration day: final sync, then the swap.
PHASE=all ./migrate.sh
```

`WORKDIR` defaults to `./migration-work`; every run for one migration must
use the same one (it holds the backup mirror, the thin repository, the staged
zips and the id of the repository it created).

Rehearsal against the September proof repository:

```bash
SOURCE_REPO=namiai/NamiPairing_iOS_thin TAG_FILTER='^5\.4\.' PHASE=prepare ./migrate.sh
```

`TAG_FILTER` is refused for `swap` and `all` so a partial build can never be
swapped into production, and every run in a workdir must use the same filter.

## Before the swap

- Run the final sync (part of `PHASE=all`) with no release in flight.
- If the CI token (`ACCESS_TOKEN_GITHUB`) is a fine-grained token with
  repository selection, grant it the new repository.

## After the swap

- Merge the CI change in `nami_app_multiplatform` (PR #1212) so releases are
  published as assets from now on. The first release after the swap goes
  straight into the new repository.
- Repoint every in-house `Package.resolved` pin of `namipairing_ios`
  (Lookout24, SdkDemo, SetupApp Runner, the workspace) and clear the
  self-hosted runners' SwiftPM caches and fingerprints; they hold the old
  commits.
- Send the "now live" partner email with the cache reset.
- Add a ruleset on the new repository that blocks force-push and deletion on
  `main` and `refs/tags/*`.
- Archive `<source>_legacy` once the grace period ends. Archiving keeps it
  readable, including its releases.

Rollback: [ROLLBACK.md](ROLLBACK.md).
