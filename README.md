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

## What `migrate.sh` does

`PHASE=prepare` (invisible to consumers):

1. Mirror-clones the source into `WORKDIR/source.git`. This is the local
   backup; keep it until the grace period ends.
2. Snapshots the source's settings, releases, collaborators and teams.
3. Builds the thin history: one commit per tag in commit-date order, same
   author, message and dates as the original tag commit, every `.xcframework`
   zipped (`ditto -c -k --keepParent`) and replaced in `Package*.swift` by
   `url: https://github.com/<source>/releases/download/<tag>/<name>.xcframework.zip`
   plus its SHA-256. All other branches are dropped. A tag that is already
   asset-backed (released by the new CI) keeps its manifests and has its
   assets re-hosted.
4. Creates `<source>_next` (public, same description and feature flags),
   pushes `main`, the tags and this branch.
5. Creates one release per tag with its zip. The eleven releases that exist on
   the source keep their titles and notes; the others get a one-line note.
   The newest tag is marked *Latest*.
6. Copies direct collaborators (including the CI bot) and teams with their
   permissions. Access that comes from organization membership needs no copy;
   the repository is public anyway. An outside collaborator, if one is ever
   added, receives an invitation they must accept.
7. Verifies: tags on `_next` equal the thin repository's, every release is
   published with an asset, and the newest asset's checksum matches its
   manifest.

`PHASE=swap` (the go-live, under a minute):

8. Renames `<source>` to `<source>_legacy`, then `<source>_next` to
   `<source>`. Between the two renames GitHub redirects the original name to
   `_legacy`, so nothing breaks in the gap.
9. Verifies that the original name serves the thin tags and that the newest
   asset downloads.

`PHASE=all` runs both. Every GitHub step is idempotent: re-running after an
interruption continues where it stopped.

## Running it

Requirements: bash 3.2+, git, `gh` authenticated as an **admin of the
source repository** (`gh auth login`), jq, ditto, shasum, perl, curl. Allow
time: zipping ~60 releases takes minutes, uploading ~2.3 GB of assets took
about 1.5 hours in the September rehearsal.

```bash
git clone --branch migration/release-assets git@github.com:namiai/NamiPairing_iOS.git namipairing-migration
cd namipairing-migration

# See the plan without touching GitHub (the local build still runs):
DRY_RUN=1 PHASE=prepare ./migrate.sh

# Prepare the new repository (for example on the 12th):
PHASE=prepare ./migrate.sh

# Go live (for example on the 16th), from the same directory:
PHASE=swap ./migrate.sh
```

`WORKDIR` defaults to `./migration-work`; the swap needs the same workdir the
prepare phase used (it holds the backup mirror, the thin repository and the
id of the repository it created). `PHASE=all` does everything in one go.

Rehearsal against the September proof repository:

```bash
SOURCE_REPO=namiai/NamiPairing_iOS_thin TAG_FILTER='^5\.4\.' PHASE=prepare ./migrate.sh
```

`TAG_FILTER` is refused for `swap` and `all` so a partial build can never be
swapped into production.

## Before the swap

- Freeze iOS SDK releases from `nami_app_multiplatform`; a release that lands
  between prepare and swap goes to the old repository.
- Check the invitations of outside collaborators were accepted, or re-add
  them after the swap.
- If the CI token (`ACCESS_TOKEN_GITHUB`) is a fine-grained token with
  repository selection, grant it the new repository.

## After the swap

- Merge the CI change in `nami_app_multiplatform` (PR #1212) so releases are
  published as assets from now on.
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
