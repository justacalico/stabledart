#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

if [ -n "${GITLAB_TOKEN:-}" ]; then
  printf '%s' "$GITLAB_TOKEN" | glab auth login     --hostname "${CI_SERVER_HOST:-gitlab.com}" --stdin >/dev/null 2>&1 || true
fi

RELEASE_TAG="${RELEASE_TAG:-}"
GITHUB_RUN_ID="${GITHUB_RUN_ID:-}"
PROJECT_DIR="${CI_PROJECT_DIR:-$PWD}"

GITHUB_REPO="justacalico/stabledart"

cd "$PROJECT_DIR"

# Determine which GitHub release to sync.
if [ -z "$RELEASE_TAG" ]; then
  RELEASE_TAG=$(gh release view -R "$GITHUB_REPO" --json tagName -q .tagName)
fi

echo "Syncing GitHub release: $RELEASE_TAG"

# Resolve the commit that the release tag points to on GitHub.
# The GitLab pipeline may run on main, but the actual release tag may be a
# different commit (e.g. a version bump), so we use the tag's target commit.
RELEASE_COMMIT=$(gh api "repos/$GITHUB_REPO/commits?sha=$RELEASE_TAG&per_page=1" -q '.[0].sha' 2>/dev/null || true)
if [ -z "$RELEASE_COMMIT" ]; then
  echo "Warning: could not resolve tag $RELEASE_TAG on GitHub, falling back to $CI_COMMIT_SHA" >&2
  RELEASE_COMMIT="$CI_COMMIT_SHA"
fi

# Download assets from the GitHub release.
rm -rf release-assets SHA256SUMS.txt
mkdir -p release-assets
gh release download "$RELEASE_TAG" -R "$GITHUB_REPO" --dir release-assets

# Fetch GitHub Actions job logs if a run ID was provided.
if [ -n "$GITHUB_RUN_ID" ]; then
  gh run view "$GITHUB_RUN_ID" -R "$GITHUB_REPO" --log > github-logs.txt 2>/dev/null || true
  if [ -s github-logs.txt ]; then
    cp github-logs.txt release-assets/
  fi
fi

# Generate checksums.
cd release-assets
sha256sum * > "$PROJECT_DIR/SHA256SUMS.txt"
cd "$PROJECT_DIR"
cp SHA256SUMS.txt release-assets/

ls -la release-assets/

API="${CI_API_V4_URL:-https://gitlab.com/api/v4}/projects/${CI_PROJECT_ID}"
AUTH="Authorization: Bearer $GITLAB_TOKEN"

# Remove any stale GitLab release, tag and generic package so the
# package-registry upload does not collide with existing assets and the release
# is recreated at the current commit.
curl -sf -X DELETE -H "$AUTH" "$API/releases/$RELEASE_TAG" || true
PKG_ID=$(curl -sf -H "$AUTH" "$API/packages?package_name=release-assets&package_version=$RELEASE_TAG" 2>/dev/null | jq -r 'if type == "array" and length > 0 then .[0].id else empty end' 2>/dev/null || true)
if [ -n "$PKG_ID" ] && [ "$PKG_ID" != "null" ]; then
  curl -sf -X DELETE -H "$AUTH" "$API/packages/$PKG_ID" || true
fi

# Mirror the tag only when GitLab does not already have it.
if ! git ls-remote --tags origin "refs/tags/$RELEASE_TAG" | grep -q .; then
  git remote add gitlab-https "https://oauth2:${GITLAB_TOKEN}@${CI_SERVER_HOST:-gitlab.com}/${CI_PROJECT_PATH}.git" 2>/dev/null || true
  git tag -f "$RELEASE_TAG" "$RELEASE_COMMIT"
  git push -f gitlab-https "refs/tags/${RELEASE_TAG}"
fi

# Mirror to a GitLab release with the same tag.
curl -sf -X POST -H "$AUTH" "$API/releases" \
  -d "name=StableDart $RELEASE_TAG" \
  -d "tag_name=$RELEASE_TAG" \
  -d "ref=$RELEASE_COMMIT" \
  --data-urlencode "description=Mirrored from the GitHub release." > /dev/null

for asset in "$PROJECT_DIR/release-assets"/*; do
  name=$(basename "$asset")
  curl -sf -X PUT -H "$AUTH" --data-binary "@$asset" \
    "$API/packages/generic/release-assets/$RELEASE_TAG/$name" > /dev/null
  curl -sf -X POST -H "$AUTH" \
    "$API/releases/$RELEASE_TAG/assets/links" \
    --data-urlencode "name=$name" \
    --data-urlencode "url=${CI_SERVER_URL:-https://gitlab.com}/api/v4/projects/${CI_PROJECT_ID}/packages/generic/release-assets/$RELEASE_TAG/$name" \
    > /dev/null
done

echo "GitLab release $RELEASE_TAG created"
