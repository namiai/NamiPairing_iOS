#!/usr/bin/env bash
#
# migrate.sh — replace the NamiPairing_iOS Swift package repository with a
# manifest-only copy whose binaries live on GitHub Releases.
#
# One run (PHASE=all) does, in order:
#
#   prepare  1. mirror-clone the source repository into WORKDIR; the mirror is
#               also the local backup,
#            2. snapshot the source's settings, releases, collaborators, teams,
#            3. build the thin history: one commit per tag in commit-date order,
#               every *.xcframework removed, Package*.swift pointing at
#               https://github.com/<source>/releases/download/<tag>/<name>.xcframework.zip
#               with its sha256 checksum; author, message and dates of the
#               original tag commit are preserved, other branches are dropped,
#            4. create <source>_next with the source's settings, push main,
#               the tags and this branch,
#            5. create one release per tag with its zip; a release that already
#               exists on the source keeps its title and notes,
#            6. copy collaborators and teams,
#            7. verify tags, releases and one checksum end to end.
#   swap     8. rename <source> to <source>_legacy, then <source>_next to <source>,
#            9. verify the final name serves the thin tags and the newest asset
#               downloads.
#
# Nothing before the swap is visible to consumers. The swap is the go-live.
# Rollback is two renames; see ROLLBACK.md.
#
# Environment:
#   SOURCE_REPO   owner/name of the repository to replace (namiai/NamiPairing_iOS)
#   SOURCE_URL    where to mirror-clone from; defaults to the GitHub SSH URL.
#                 A local path works for rehearsals.
#   WORKDIR       scratch and backup directory (./migration-work)
#   PHASE         all | prepare | swap (all)
#   BRANCH        name of this branch, pushed into the new repository
#                 (migration/release-assets)
#   TAG_FILTER    regex; only matching tags are migrated. Rehearsals only:
#                 PHASE=swap and PHASE=all refuse a filter.
#   DRY_RUN=1     print every GitHub write instead of performing it. The local
#                 build still runs; verification that needs the new repository
#                 is skipped.
#   RESUME=1      keep a complete thin build and staged zips from a previous
#                 run instead of rebuilding. Every GitHub step is idempotent
#                 regardless, so re-running after an interruption continues.
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
RESUME="${RESUME:-0}"

RELEASE_BASE="https://github.com/${SOURCE_REPO}/releases/download"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$WORKDIR/source.git"
THIN="$WORKDIR/thin"
ASSETS="$WORKDIR/assets"
SNAP="$WORKDIR/snapshot"
TAGS_FILE="$WORKDIR/tags.txt"
COMMIT_MAP="$WORKDIR/commit-map.txt"
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

newest_tag() { tail -n1 "$TAGS_FILE" | awk '{print $3}'; }

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

build_thin() {
  local built staged
  if [ "$RESUME" = "1" ] && [ -d "$THIN/.git" ]; then
    built=$(git -C "$THIN" tag | wc -l | tr -d ' ')
    staged=$(find "$ASSETS" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    if [ "$built" = "$(wc -l < "$TAGS_FILE" | tr -d ' ')" ] && [ "$staged" = "$built" ]; then
      log "RESUME: thin repository ($built tags) and staged zips are complete; skipping build"
      return 0
    fi
    warn "RESUME: build incomplete (tags=$built zips=$staged); rebuilding"
  fi

  log "Building thin repository at $THIN"
  rm -rf "$THIN" "$ASSETS"
  mkdir -p "$THIN" "$ASSETS"
  git -C "$THIN" init -q -b main
  : > "$COMMIT_MAP"

  local when commit tag reused xcf base name zip sum thin_commit sums_file
  while read -r when commit tag; do
    reused=$(awk -v c="$commit" '$1 == c { print $2 }' "$COMMIT_MAP")
    if [ -n "$reused" ]; then
      git -C "$THIN" tag -f "$tag" "$reused" >/dev/null
      log "tag $tag -> same commit as an earlier tag, reused ${reused:0:8}"
      continue
    fi

    log "tag $tag (source ${commit:0:8})"
    find "$THIN" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
    git -C "$SRC" archive "$tag" | tar -x -C "$THIN"
    mkdir -p "$ASSETS/$tag"
    sums_file="$ASSETS/$tag/.checksums"
    : > "$sums_file"

    if find "$THIN" -type d -name '*.xcframework' | grep -q .; then
      # Normal case: zip each xcframework, record its checksum, drop it.
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
      # The tag is already asset-backed (released by the new CI after the
      # cut-over tooling landed): keep its manifests, re-host its assets.
      log "  already asset-backed; downloading its release assets from $SOURCE_REPO"
      gh release download "$tag" --repo "$SOURCE_REPO" --pattern '*.xcframework.zip' \
        --dir "$ASSETS/$tag" --clobber </dev/null
    else
      die "tag $tag has no xcframework and no asset-backed manifest"
    fi

    if grep -REIn 'path:[[:space:]]*"[^"]*\.xcframework"' "$THIN"/Package*.swift 2>/dev/null; then
      die "tag $tag: a manifest still references a local xcframework (see above)"
    fi
    find "$ASSETS/$tag" -name '*.zip' | grep -q . || die "tag $tag: no zip staged"

    git -C "$THIN" add -A
    commit_as "$commit"
    thin_commit=$(git -C "$THIN" rev-parse HEAD)
    printf '%s %s\n' "$commit" "$thin_commit" >> "$COMMIT_MAP"
    git -C "$THIN" tag -f "$tag" "$thin_commit" >/dev/null
  done < "$TAGS_FILE"

  log "Thin history: $(git -C "$THIN" rev-list --count main) commits, $(git -C "$THIN" tag | wc -l | tr -d ' ') tags, .git $(du -sh "$THIN/.git" | awk '{print $1}'); zips $(du -sh "$ASSETS" | awk '{print $1}')"
}

# This branch travels with the new repository so the tooling stays findable.
add_tooling_branch() {
  log "Adding $BRANCH (this tooling) to the thin repository"
  git -C "$THIN" branch -D "$BRANCH" >/dev/null 2>&1 || true
  git -C "$THIN" checkout -q --orphan "$BRANCH"
  git -C "$THIN" rm -rfq --cached . >/dev/null 2>&1 || true
  find "$THIN" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
  cp "$SCRIPT_DIR/migrate.sh" "$SCRIPT_DIR/README.md" "$SCRIPT_DIR/ROLLBACK.md" "$THIN/"
  git -C "$THIN" add -A
  git -C "$THIN" commit -q -m "Repository migration tooling"
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
  # default branch is then pinned explicitly rather than inferred.
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
      # latest while the loop runs; the newest tag is marked at the end.
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
  log "Releases: already-ok=$ok created=$new fixed=$fixed; marking $(newest_tag) as latest"
  run gh release edit "$(newest_tag)" --repo "$NEXT_REPO" --latest
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
manifest_checksum() {  # $1 tag; the checksum our own manifest records for the tag
  git -C "$THIN" show "$1:Package.swift" | grep -o 'checksum: "[0-9a-f]*"' | head -n1 | cut -d'"' -f2
}

verify_next_repo() {
  local repo="$1" tag remote_tags local_tags missing draft_or_empty tmp sum
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

  tag=$(newest_tag)
  tmp=$(mktemp -d)
  gh release download "$tag" --repo "$repo" --pattern '*.xcframework.zip' --dir "$tmp" </dev/null
  sum=$(shasum -a 256 "$tmp"/*.xcframework.zip | head -n1 | awk '{print $1}')
  rm -rf "$tmp"
  [ "$sum" = "$(manifest_checksum "$tag")" ] || die "checksum of the $tag asset on $repo does not match its manifest"
  log "  $(wc -l < "$TAGS_FILE" | tr -d ' ') tags, all releases published with assets, $tag checksum matches"
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
  tag=$(newest_tag)
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
