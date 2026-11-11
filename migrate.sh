#!/usr/bin/env bash
#
# migrate.sh — replace the NamiPairing_iOS Swift package repository with a
# manifest-only copy whose binaries live on GitHub Releases.
#
# Phases:
#
#   prepare  1. mirror-clone the source repository into WORKDIR (or refresh the
#               mirror); the mirror is also the local backup,
#            2. snapshot the source's settings, releases, collaborators, teams,
#            3. build the thin history: one commit per tag in commit-date order,
#               every *.xcframework removed, Package*.swift pointing at
#               https://github.com/<source>/releases/download/<tag>/<name>.xcframework.zip
#               with its sha256 checksum; author, message and dates of the
#               original tag commit are preserved, other branches are dropped.
#               The build is incremental: tags already built are kept and new
#               tags are appended, so re-running after a release only adds it,
#            4. create <source>_next with the source's settings (first run),
#               push main, the tags and this branch,
#            5. create one release per tag with its zip; a release that already
#               exists on the source keeps its title and notes,
#            6. copy collaborators and teams,
#            7. verify tags, releases and one checksum end to end.
#   swap     8. rename <source> to <source>_legacy, then <source>_next to <source>,
#            9. verify the final name serves the thin tags and the newest asset
#               downloads.
#
# Intended use: PHASE=prepare early, PHASE=prepare again after every release
# made on the source in the meantime (a sync, minutes), PHASE=all on migration
# day (final sync, then the swap). Nothing before the swap is visible to
# consumers. Rollback is two renames; see ROLLBACK.md.
#
# Environment:
#   SOURCE_REPO   owner/name of the repository to replace (namiai/NamiPairing_iOS)
#   SOURCE_URL    where to mirror-clone from; defaults to the GitHub SSH URL.
#                 A local path works for rehearsals.
#   WORKDIR       scratch and backup directory (./migration-work); every run
#                 for one migration must use the same one
#   PHASE         all | prepare | swap (all)
#   BRANCH        name of this branch, pushed into the new repository
#                 (migration/release-assets)
#   TAG_FILTER    regex; only matching tags are migrated. Rehearsals only:
#                 PHASE=swap and PHASE=all refuse a filter, and every run in a
#                 workdir must use the same filter.
#   DRY_RUN=1     print every GitHub write instead of performing it. The local
#                 build still runs; verification that needs the new repository
#                 is skipped.
#
# Requires bash 3.2+, git, gh (authenticated, admin on SOURCE_REPO), jq, ditto,
# shasum, perl, curl.

set -euo pipefail

SOURCE_REPO="${SOURCE_REPO:-namiai/NamiPairing_iOS}"
OWNER="${SOURCE_REPO%%/*}"
NAME="${SOURCE_REPO#*/}"
NEXT_NAME="${NAME}_next"
LEGACY_NAME="${NAME}_legacy"
NEXT_REPO="$OWNER/$NEXT_NAME"
LEGACY_REPO="$OWNER/$LEGACY_NAME"
SOURCE_URL="${SOURCE_URL:-git@github.com:${SOURCE_REPO}.git}"
WORKDIR="${WORKDIR:-$PWD/migration-work}"
PHASE="${PHASE:-all}"
BRANCH="${BRANCH:-migration/release-assets}"
TAG_FILTER="${TAG_FILTER:-}"
DRY_RUN="${DRY_RUN:-0}"

RELEASE_BASE="https://github.com/${SOURCE_REPO}/releases/download"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$WORKDIR/source.git"
THIN="$WORKDIR/thin"
ASSETS="$WORKDIR/assets"
SNAP="$WORKDIR/snapshot"
TAGS_FILE="$WORKDIR/tags.txt"
COMMIT_MAP="$WORKDIR/commit-map.txt"   # "<source commit> <thin commit> <tag>"
NEXT_MARKER="$WORKDIR/next-repo.id"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[err]\033[0m %s\n' "$*" >&2; exit 1; }

# Every GitHub write goes through run() so DRY_RUN=1 shows the plan instead.
run() {
  if [ "$DRY_RUN" = "1" ]; then
    printf '\033[1;35m[dry-run]\033[0m %s\n' "$*"
  else
    "$@"
  fi
}

# ----------------------------------------------------------------------------
# Preflight
# ----------------------------------------------------------------------------
preflight() {
  local tool
  for tool in git gh jq ditto shasum perl curl; do
    command -v "$tool" >/dev/null || die "$tool is required"
  done
  case "$PHASE" in
    all|prepare|swap) ;;
    *) die "PHASE must be all, prepare or swap (got '$PHASE')" ;;
  esac
  if [ -n "$TAG_FILTER" ] && [ "$PHASE" != "prepare" ]; then
    die "TAG_FILTER is for rehearsals: it only works with PHASE=prepare"
  fi
  gh auth status >/dev/null 2>&1 || die "gh is not authenticated (run: gh auth login)"
  [ "$(gh api "repos/$SOURCE_REPO" --jq .permissions.admin)" = "true" ] \
    || die "the authenticated user is not an admin of $SOURCE_REPO"
  mkdir -p "$WORKDIR"
  log "Source $SOURCE_REPO -> next $NEXT_REPO, legacy $LEGACY_REPO; workdir $WORKDIR; phase $PHASE"
  [ "$DRY_RUN" = "1" ] && warn "DRY_RUN=1: GitHub writes are printed, not performed"
  return 0
}

repo_exists() { gh api "repos/$1" --jq .id >/dev/null 2>&1; }

# "<draft> <asset count>" of the release for tag $2 on repository $1, or
# MISSING. gh api prints the error body on stdout for a 404, so only the
# exit status can decide.
release_state() {
  local state
  state=$(gh api "repos/$1/releases/tags/$2" --jq '"\(.draft) \(.assets | length)"' 2>/dev/null) || state=MISSING
  printf '%s' "$state"
}

# Tags are dotted numbers (1.4, 5.4.10); sort them as versions, not as text.
version_sort() { sort -t. -k1,1n -k2,2n -k3,3n; }

# ----------------------------------------------------------------------------
# 1. Mirror the source (also the local backup)
# ----------------------------------------------------------------------------
mirror_source() {
  if [ -d "$SRC" ]; then
    log "Refreshing mirror at $SRC"
    git -C "$SRC" remote update --prune >/dev/null
  else
    log "Mirroring $SOURCE_URL into $SRC (this is the backup; keep it)"
    git clone --mirror --quiet "$SOURCE_URL" "$SRC"
  fi
  log "Mirror has $(git -C "$SRC" tag | wc -l | tr -d ' ') tags, $(du -sh "$SRC" | awk '{print $1}')"
}

# ----------------------------------------------------------------------------
# 2. Snapshot what the new repository must reproduce
# ----------------------------------------------------------------------------
snapshot_source() {
  log "Snapshotting $SOURCE_REPO settings, releases, collaborators and teams into $SNAP"
  mkdir -p "$SNAP"
  gh api "repos/$SOURCE_REPO" > "$SNAP/repo.json"
  gh api "repos/$SOURCE_REPO/releases?per_page=100" --paginate --slurp \
    | jq 'add' > "$SNAP/releases.json"
  gh api "repos/$SOURCE_REPO/collaborators?affiliation=direct&per_page=100" --paginate \
    --jq '.[] | "\(.login) \(.role_name)"' > "$SNAP/collaborators.txt"
  gh api "repos/$SOURCE_REPO/teams?per_page=100" --paginate \
    --jq '.[] | "\(.slug) \(.permission)"' > "$SNAP/teams.txt"
  log "  $(jq length "$SNAP/releases.json") releases, $(wc -l < "$SNAP/collaborators.txt" | tr -d ' ') collaborators, $(wc -l < "$SNAP/teams.txt" | tr -d ' ') teams"
}

# ----------------------------------------------------------------------------
# 3. Thin history
# ----------------------------------------------------------------------------

# "<commit-time> <commit> <tag>" per tag, oldest first, filtered by TAG_FILTER.
collect_tags() {
  local tag commit when
  : > "$TAGS_FILE"
  for tag in $(git -C "$SRC" tag); do
    if [ -n "$TAG_FILTER" ] && ! printf '%s' "$tag" | grep -Eq "$TAG_FILTER"; then
      continue
    fi
    commit=$(git -C "$SRC" rev-list -n1 "$tag^{commit}")
    when=$(git -C "$SRC" log -1 --format=%ct "$commit")
    printf '%s %s %s\n' "$when" "$commit" "$tag"
  done | sort -n -k1,1 > "$TAGS_FILE"
  [ -s "$TAGS_FILE" ] || die "no tags selected from $SRC"
  log "Selected $(wc -l < "$TAGS_FILE" | tr -d ' ') tags"
}

# The highest version among the selected tags: what main points at, what is
# marked Latest, and what the end-to-end checks download. Not the newest by
# date, so an out-of-order hotfix never takes over.
highest_tag() { awk '{print $3}' "$TAGS_FILE" | version_sort | tail -n1; }

# Swap every local xcframework path in a manifest for a URL + checksum.
#   $1 file  $2 xcframework basename without extension  $3 url  $4 checksum
rewrite_manifest() {
  NAME_="$2" URL_="$3" SUM_="$4" perl -0777 -i -pe '
    my $n = quotemeta($ENV{NAME_});
    s{path:\s*"[^"]*${n}\.xcframework"}{url: "$ENV{URL_}",\n            checksum: "$ENV{SUM_}"}g;
  ' "$1"
}

# Commit the staged thin tree with the original tag commit's metadata.
commit_as() {
  local commit="$1" message
  message=$(git -C "$SRC" log -1 --format=%B "$commit")
  GIT_AUTHOR_NAME=$(git -C "$SRC" log -1 --format='%an' "$commit") \
  GIT_AUTHOR_EMAIL=$(git -C "$SRC" log -1 --format='%ae' "$commit") \
  GIT_AUTHOR_DATE=$(git -C "$SRC" log -1 --format='%aI' "$commit") \
  GIT_COMMITTER_NAME=$(git -C "$SRC" log -1 --format='%cn' "$commit") \
  GIT_COMMITTER_EMAIL=$(git -C "$SRC" log -1 --format='%ce' "$commit") \
  GIT_COMMITTER_DATE=$(git -C "$SRC" log -1 --format='%cI' "$commit") \
    git -C "$THIN" commit -q --allow-empty-message -m "$message"
}

# Stage the tag's tree in $THIN with its xcframeworks zipped into $ASSETS/<tag>
# and the manifests rewritten.
stage_tag_tree() {
  local tag="$1" sums_file xcf base zip sum name manifest
  find "$THIN" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
  git -C "$SRC" archive "$tag" | tar -x -C "$THIN"
  rm -rf "$ASSETS/$tag"
  mkdir -p "$ASSETS/$tag"
  sums_file="$ASSETS/$tag/.checksums"
  : > "$sums_file"

  if find "$THIN" -type d -name '*.xcframework' | grep -q .; then
    find "$THIN" -type d -name '*.xcframework' | sort | while read -r xcf; do
      base=$(basename "$xcf")
      zip="$ASSETS/$tag/${base}.zip"
      # --keepParent: SwiftPM wants the .xcframework directory at the top of
      # the archive. No --sequesterRsrc: extended attributes stay out of the
      # zip, so the checksum depends on the framework alone.
      (cd "$(dirname "$xcf")" && ditto -c -k --keepParent "$base" "$zip")
      sum=$(shasum -a 256 "$zip" | awk '{print $1}')
      printf '%s %s\n' "${base%.xcframework}" "$sum" >> "$sums_file"
      log "  $base -> $(du -h "$zip" | awk '{print $1}') sha256 ${sum:0:12}…"
      rm -rf "$xcf"
    done
    while read -r name sum; do
      for manifest in "$THIN"/Package*.swift; do
        [ -f "$manifest" ] || continue
        rewrite_manifest "$manifest" "$name" "$RELEASE_BASE/$tag/${name}.xcframework.zip" "$sum"
      done
    done < "$sums_file"
  elif grep -q "$RELEASE_BASE/$tag/" "$THIN/Package.swift" 2>/dev/null; then
    # Already asset-backed (released by the new CI): keep the manifests,
    # re-host the assets.
    log "  already asset-backed; downloading its release assets from $SOURCE_REPO"
    gh release download "$tag" --repo "$SOURCE_REPO" --pattern '*.xcframework.zip' \
      --dir "$ASSETS/$tag" --clobber </dev/null
    # Re-host only bytes the manifest actually describes.
    for zip in "$ASSETS/$tag"/*.xcframework.zip; do
      [ -f "$zip" ] || die "tag $tag: no asset downloaded from $SOURCE_REPO"
      sum=$(shasum -a 256 "$zip" | awk '{print $1}')
      grep -q "checksum: \"$sum\"" "$THIN/Package.swift" \
        || die "tag $tag: hosted $(basename "$zip") is sha256 ${sum:0:12}… but its manifest records a different checksum; the source release is inconsistent"
    done
  else
    die "tag $tag has no xcframework and no asset-backed manifest"
  fi

  if grep -REIn 'path:[[:space:]]*"[^"]*\.xcframework"' "$THIN"/Package*.swift 2>/dev/null; then
    die "tag $tag: a manifest still references a local xcframework (see above)"
  fi
  find "$ASSETS/$tag" -name '*.zip' | grep -q . || die "tag $tag: no zip staged"
}

build_thin() {
  local when commit tag existing mapped reused parent thin_commit newest_built src_commit
  mkdir -p "$ASSETS"
  if [ ! -d "$THIN/.git" ]; then
    log "Creating thin repository at $THIN"
    git init -q -b main "$THIN"
    : > "$COMMIT_MAP"
  fi

  # The chain is append-only. A tag older than one already built would have
  # to be inserted, which rewrites every commit after it and moves tags that
  # may already be on the new repository.
  newest_built=0
  while read -r src_commit thin_commit tag; do
    when=$(git -C "$SRC" log -1 --format=%ct "$src_commit")
    [ "$when" -gt "$newest_built" ] && newest_built=$when
  done < "$COMMIT_MAP"

  parent=""
  while read -r when commit tag; do
    existing=$(git -C "$THIN" rev-parse -q --verify "refs/tags/$tag^{commit}" || true)
    if [ -n "$existing" ]; then
      mapped=$(awk -v t="$tag" '$3 == t { print $1; exit }' "$COMMIT_MAP")
      [ "$mapped" = "$commit" ] \
        || die "tag $tag was built from ${mapped:0:8} but now points at ${commit:0:8}; a moved tag cannot be synced"
      [ -d "$ASSETS/$tag" ] \
        || die "tag $tag is built but $ASSETS/$tag is missing; delete $THIN and $ASSETS to rebuild"
      parent="$existing"
      continue
    fi

    reused=$(awk -v c="$commit" '$1 == c { print $2; exit }' "$COMMIT_MAP")
    if [ -n "$reused" ]; then
      git -C "$THIN" tag -f "$tag" "$reused" >/dev/null
      printf '%s %s %s\n' "$commit" "$reused" "$tag" >> "$COMMIT_MAP"
      log "tag $tag -> same source commit as an earlier tag, reused ${reused:0:8}"
      parent="$reused"
      continue
    fi

    [ "$when" -ge "$newest_built" ] \
      || die "tag $tag (source ${commit:0:8}) is older than tags already built; delete $THIN and $ASSETS to rebuild from scratch"

    log "tag $tag (source ${commit:0:8})"
    if [ -n "$parent" ]; then
      git -C "$THIN" checkout -q --detach "$parent"
    fi
    stage_tag_tree "$tag"
    git -C "$THIN" add -A
    commit_as "$commit"
    thin_commit=$(git -C "$THIN" rev-parse HEAD)
    printf '%s %s %s\n' "$commit" "$thin_commit" "$tag" >> "$COMMIT_MAP"
    git -C "$THIN" tag -f "$tag" "$thin_commit" >/dev/null
    parent="$thin_commit"
  done < "$TAGS_FILE"

  git -C "$THIN" checkout -q --detach
  git -C "$THIN" branch -f main "refs/tags/$(highest_tag)^{commit}"
  git -C "$THIN" checkout -q main
  log "Thin history: $(git -C "$THIN" tag | wc -l | tr -d ' ') tags, main at $(highest_tag), .git $(du -sh "$THIN/.git" | awk '{print $1}'); zips $(du -sh "$ASSETS" | awk '{print $1}')"
}

# This branch travels with the new repository so the tooling stays findable.
# Commits only when the files changed, so a re-run pushes nothing new.
add_tooling_branch() {
  log "Updating $BRANCH (this tooling) in the thin repository"
  if git -C "$THIN" rev-parse -q --verify "refs/heads/$BRANCH" >/dev/null; then
    git -C "$THIN" checkout -q "$BRANCH"
  else
    git -C "$THIN" checkout -q --orphan "$BRANCH"
    git -C "$THIN" rm -rfq --cached . >/dev/null 2>&1 || true
  fi
  find "$THIN" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
  cp "$SCRIPT_DIR/migrate.sh" "$SCRIPT_DIR/README.md" "$SCRIPT_DIR/ROLLBACK.md" "$THIN/"
  git -C "$THIN" add -A
  if git -C "$THIN" rev-parse -q --verify HEAD >/dev/null && git -C "$THIN" diff --cached --quiet; then
    log "  unchanged"
  else
    git -C "$THIN" commit -q -m "Repository migration tooling"
  fi
  git -C "$THIN" checkout -q main
}

# ----------------------------------------------------------------------------
# 4. New repository, settings, push
# ----------------------------------------------------------------------------
create_next_repo() {
  local description homepage has_issues has_wiki has_projects id
  if repo_exists "$NEXT_REPO"; then
    [ -f "$NEXT_MARKER" ] || die "$NEXT_REPO already exists and was not created by this tool; remove or rename it"
    log "$NEXT_REPO exists from a previous run (id $(cat "$NEXT_MARKER")); reusing it"
  else
    description=$(jq -r '.description // ""' "$SNAP/repo.json")
    log "Creating $NEXT_REPO (public)"
    run gh repo create "$NEXT_REPO" --public --description "$description"
    if [ "$DRY_RUN" != "1" ]; then
      id=$(gh api "repos/$NEXT_REPO" --jq .id)
      printf '%s\n' "$id" > "$NEXT_MARKER"
    fi
  fi

  homepage=$(jq -r '.homepage // ""' "$SNAP/repo.json")
  has_issues=$(jq -r .has_issues "$SNAP/repo.json")
  has_wiki=$(jq -r .has_wiki "$SNAP/repo.json")
  has_projects=$(jq -r .has_projects "$SNAP/repo.json")
  log "Applying settings (issues=$has_issues wiki=$has_wiki projects=$has_projects)"
  run gh api -X PATCH "repos/$NEXT_REPO" \
    -f homepage="$homepage" \
    -F has_issues="$has_issues" -F has_wiki="$has_wiki" -F has_projects="$has_projects" \
    --silent
  if [ "$(jq '.topics | length' "$SNAP/repo.json")" != "0" ]; then
    run gh api -X PUT "repos/$NEXT_REPO/topics" \
      --input <(jq '{names: .topics}' "$SNAP/repo.json") --silent
  fi
}

push_next_repo() {
  log "Pushing main, tags and $BRANCH to $NEXT_REPO"
  git -C "$THIN" remote remove next >/dev/null 2>&1 || true
  git -C "$THIN" remote add next "git@github.com:${NEXT_REPO}.git"
  # main first and on its own, so it is the first branch GitHub sees; the
  # default branch is then pinned explicitly rather than inferred. Tags that
  # already exist on the remote are unchanged by construction; git refuses a
  # moved one, which is the right outcome.
  run git -C "$THIN" push -q next main
  run gh api -X PATCH "repos/$NEXT_REPO" -f default_branch=main --silent
  run git -C "$THIN" push -q next "$BRANCH"
  run git -C "$THIN" push -q next --tags
}

# ----------------------------------------------------------------------------
# 5. Releases
# ----------------------------------------------------------------------------
release_title() { jq -r --arg t "$1" '.[] | select(.tag_name == $t) | .name // empty' "$SNAP/releases.json" | head -n1; }
release_notes() { jq -r --arg t "$1" '.[] | select(.tag_name == $t) | .body // empty' "$SNAP/releases.json" | head -c 65000; }

create_releases() {
  local when commit tag state expected title notes_file ok new fixed
  ok=0; new=0; fixed=0
  shopt -s nullglob
  while read -r when commit tag; do
    local zips=("$ASSETS/$tag"/*.zip)
    expected=${#zips[@]}
    [ "$expected" -gt 0 ] || die "tag $tag: no zip staged"
    state=$(release_state "$NEXT_REPO" "$tag")
    if [ "$state" = "false $expected" ]; then
      ok=$((ok + 1)); continue
    fi
    title=$(release_title "$tag")
    [ -n "$title" ] || title="$tag"
    notes_file="$ASSETS/$tag/.notes.md"
    release_notes "$tag" > "$notes_file"
    if [ ! -s "$notes_file" ]; then
      printf 'NamiPairing %s. The xcframework is attached as a release asset and referenced by Package.swift as a remote binary target.\n' "$tag" > "$notes_file"
    fi
    if [ "$state" = "MISSING" ]; then
      log "Release $tag: create with $expected asset(s)"
      new=$((new + 1))
      # --latest=false keeps GitHub from marking each historical release as
      # latest while the loop runs; the highest version is marked at the end.
      run gh release create "$tag" "${zips[@]}" --repo "$NEXT_REPO" \
        --title "$title" --notes-file "$notes_file" --verify-tag --latest=false
    else
      log "Release $tag: exists with state '$state', uploading assets (want $expected)"
      fixed=$((fixed + 1))
      run gh release upload "$tag" "${zips[@]}" --repo "$NEXT_REPO" --clobber
      run gh release edit "$tag" --repo "$NEXT_REPO" --draft=false
    fi
  done < "$TAGS_FILE"
  shopt -u nullglob
  log "Releases: already-ok=$ok created=$new fixed=$fixed; marking $(highest_tag) as latest"
  run gh release edit "$(highest_tag)" --repo "$NEXT_REPO" --latest
}

# ----------------------------------------------------------------------------
# 6. Access
# ----------------------------------------------------------------------------
copy_access() {
  local login role slug permission
  log "Copying collaborators and teams to $NEXT_REPO"
  while read -r login role; do
    [ -n "$login" ] || continue
    case "$role" in
      read) permission=pull ;;
      write) permission=push ;;
      admin|maintain|triage) permission="$role" ;;
      *) warn "collaborator $login has unknown role '$role'; skipping"; continue ;;
    esac
    run gh api -X PUT "repos/$NEXT_REPO/collaborators/$login" -f permission="$permission" --silent
  done < "$SNAP/collaborators.txt"
  while read -r slug permission; do
    [ -n "$slug" ] || continue
    run gh api -X PUT "orgs/$OWNER/teams/$slug/repos/$NEXT_REPO" -f permission="$permission" --silent
  done < "$SNAP/teams.txt"
}

# ----------------------------------------------------------------------------
# 7. Verification of the prepared repository
# ----------------------------------------------------------------------------
manifest_checksum() {  # $1 tag $2 asset file name; the checksum the manifest records for that asset
  git -C "$THIN" show "$1:Package.swift" | tr -d '\n' \
    | grep -o "url: \"[^\"]*/$2\",[[:space:]]*checksum: \"[0-9a-f]*\"" | head -n1 | grep -o '[0-9a-f]\{64\}'
}

download_and_hash() {  # $1 repo $2 tag $3 asset file name; sha256 of the served bytes
  local tmp sum
  tmp=$(mktemp -d)
  gh release download "$2" --repo "$1" --pattern "$3" --dir "$tmp" </dev/null
  sum=$(shasum -a 256 "$tmp/$3" | awk '{print $1}')
  rm -rf "$tmp"
  printf '%s' "$sum"
}

verify_next_repo() {
  local repo="$1" tag remote_tags local_tags missing draft_or_empty tmp sum when commit
  if [ "$DRY_RUN" = "1" ]; then
    warn "DRY_RUN=1: skipping verification of $repo"
    return 0
  fi
  log "Verifying $repo"
  remote_tags=$(git ls-remote --tags "https://github.com/${repo}.git" | grep -v '\^{}' | awk '{print $2 " " $1}' | sed 's#refs/tags/##' | sort)
  local_tags=$(git -C "$THIN" show-ref --tags | awk '{print $2 " " $1}' | sed 's#refs/tags/##' | sort)
  [ "$remote_tags" = "$local_tags" ] || { diff <(echo "$local_tags") <(echo "$remote_tags") || true; die "tags on $repo differ from the thin repository"; }

  missing=0; draft_or_empty=0
  while read -r when commit tag; do
    case "$(release_state "$repo" "$tag")" in
      MISSING) missing=$((missing + 1)); warn "release $tag missing" ;;
      "false 0"|"true "*) draft_or_empty=$((draft_or_empty + 1)); warn "release $tag is a draft or has no asset" ;;
    esac
  done < "$TAGS_FILE"
  [ "$missing" = "0" ] && [ "$draft_or_empty" = "0" ] || die "releases on $repo are incomplete"

  # Every asset's sha256 (GitHub's digest, or a download when GitHub has
  # none) must be the checksum its manifest records, otherwise SwiftPM
  # rejects the download. The highest version is downloaded regardless, to
  # prove the served bytes.
  local asset digest expected mismatched=0
  while read -r when commit tag; do
    while read -r asset digest; do
      [ -n "$asset" ] || continue
      if [ "$digest" = "null" ] || [ "$tag" = "$(highest_tag)" ]; then
        digest="sha256:$(download_and_hash "$repo" "$tag" "$asset")"
      fi
      expected=$(manifest_checksum "$tag" "$asset")
      if [ "$digest" != "sha256:$expected" ]; then
        mismatched=$((mismatched + 1))
        warn "release $tag: $asset is $digest, its manifest records ${expected:-nothing}"
      fi
    done < <(gh api "repos/$repo/releases/tags/$tag" --jq '.assets[] | "\(.name) \(.digest)"')
  done < "$TAGS_FILE"
  [ "$mismatched" = "0" ] || die "$mismatched asset(s) on $repo do not match their manifests"
  log "  $(wc -l < "$TAGS_FILE" | tr -d ' ') tags, all releases published, every asset matches its manifest"
}

# ----------------------------------------------------------------------------
# 8. Swap
# ----------------------------------------------------------------------------
swap_repos() {
  local next_id
  repo_exists "$NEXT_REPO" || die "$NEXT_REPO does not exist; run PHASE=prepare first"
  if repo_exists "$LEGACY_REPO"; then
    die "$LEGACY_REPO already exists; the swap was done, or the name is taken"
  fi
  [ -f "$NEXT_MARKER" ] || die "$NEXT_MARKER missing: prepare ran elsewhere; copy its workdir here"
  next_id=$(cat "$NEXT_MARKER")
  [ "$(gh api "repos/$NEXT_REPO" --jq .id)" = "$next_id" ] || die "$NEXT_REPO is not the repository this tool created"

  log "Renaming $SOURCE_REPO -> $LEGACY_NAME"
  run gh api -X PATCH "repos/$SOURCE_REPO" -f name="$LEGACY_NAME" --silent
  [ "$DRY_RUN" = "1" ] || [ "$(gh api "repos/$LEGACY_REPO" --jq .name)" = "$LEGACY_NAME" ] \
    || die "$LEGACY_REPO is not reachable after the rename"

  log "Renaming $NEXT_REPO -> $NAME"
  run gh api -X PATCH "repos/$NEXT_REPO" -f name="$NAME" --silent
  [ "$DRY_RUN" = "1" ] || [ "$(gh api "repos/$SOURCE_REPO" --jq .id)" = "$next_id" ] \
    || die "$SOURCE_REPO does not resolve to the new repository after the rename"
}

# ----------------------------------------------------------------------------
# 9. Post-swap verification
# ----------------------------------------------------------------------------
verify_live() {
  local tag url attempt
  if [ "$DRY_RUN" = "1" ]; then
    warn "DRY_RUN=1: skipping live verification"
    return 0
  fi
  tag=$(highest_tag)
  url="$RELEASE_BASE/$tag/$(basename "$(ls "$ASSETS/$tag"/*.xcframework.zip | head -n1)")"
  log "Verifying $SOURCE_REPO serves tag $tag and $url"
  for attempt in 1 2 3 4 5 6; do
    if [ "$(git ls-remote "https://github.com/${SOURCE_REPO}.git" "refs/tags/$tag" | awk '{print $1}')" = "$(git -C "$THIN" rev-parse "$tag")" ] \
       && curl -sfLI "$url" -o /dev/null; then
      log "  live: tag and asset resolve under the original name"
      return 0
    fi
    sleep 10
  done
  die "the original name does not serve the thin tag or the asset yet; check ROLLBACK.md"
}

# ----------------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------------
preflight
case "$PHASE" in
  all|prepare)
    mirror_source
    snapshot_source
    collect_tags
    build_thin
    add_tooling_branch
    create_next_repo
    push_next_repo
    create_releases
    copy_access
    verify_next_repo "$NEXT_REPO"
    log "Prepared $NEXT_REPO. Backup mirror: $SRC"
    ;;
esac
case "$PHASE" in
  all|swap)
    [ -s "$TAGS_FILE" ] || collect_tags
    if [ "$PHASE" = "swap" ]; then
      [ -d "$THIN/.git" ] || die "$THIN missing: run PHASE=prepare in this workdir first"
      verify_next_repo "$NEXT_REPO"
    fi
    swap_repos
    verify_live
    log "Done. $SOURCE_REPO is the thin repository; the previous one is $LEGACY_REPO."
    log "Next: merge the CI change, repoint in-house Package.resolved pins, send the partner email."
    ;;
esac
