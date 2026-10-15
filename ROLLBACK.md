# Rolling the migration back

The migration never modifies the original repository: it renames it to
`<source>_legacy` and puts a new repository under the original name. Rolling
back is therefore two renames, done by an admin, in this order.

Names below assume the default `SOURCE_REPO=namiai/NamiPairing_iOS`.

## 1. Move the new repository out of the way

Rename `namiai/NamiPairing_iOS` (the thin repository) to something that
cannot be confused with the real thing, for example `NamiPairing_iOS_failed`:

```bash
gh api -X PATCH repos/namiai/NamiPairing_iOS -f name=NamiPairing_iOS_failed
```

or on GitHub: repository → Settings → General → Repository name → Rename.

Do not delete it yet; its releases are the record of what went live.

## 2. Give the original repository its name back

```bash
gh api -X PATCH repos/namiai/NamiPairing_iOS_legacy -f name=NamiPairing_iOS
```

## 3. Verify

```bash
git ls-remote --tags https://github.com/namiai/NamiPairing_iOS.git | tail -n 3
```

must list the original tag commits (for `5.4.3`:
`8a776abfc742d0fc0da9af4399f0fea7779f825e`), and

```bash
gh api repos/namiai/NamiPairing_iOS --jq .size
```

must report the original size (≈2.3 GB in KB). The eleven original releases
are untouched because the original repository was never written to.

## 4. Tell everyone

- Partners who already ran the cache reset recorded the thin commits in their
  SwiftPM fingerprints. For them the rollback looks like the migration did:
  the tags moved again, and they need the same reset once more. Partners who
  had not reset yet notice nothing.
- Do not merge, or revert, the CI change in `nami_app_multiplatform`
  (PR #1212): it publishes binaries as release assets, which the original
  repository does not use.
- Clear the self-hosted runners' SwiftPM caches again if they were cleared
  after the swap.

## 5. Afterwards

Delete `NamiPairing_iOS_failed` when it is no longer needed as evidence. The
local backup mirror in the tool's `WORKDIR/source.git` is a second copy of the
original repository, including every tag.
