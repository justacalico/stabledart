#!/bin/bash
# Final gate for a freshly scaffolded project. Run from the project root
# after everything is committed and pushed. Exits 0 only when every
# check passes — nothing may be reported "done" until it does.
#
#   bash scripts/verify-project.sh
#
# SKIP_FLUTTER_TESTS=1 reuses an existing coverage/lcov.info instead of
# re-running the suite (iteration only — the final run must be real).

set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

RUNNER_ID=55109445
RUNNER_TAG=linux-truenas
CI_FILE=.gitlab-ci.yml

fail=0
ok()  { printf '  ok   %s\n' "$1"; }
bad() { printf '  FAIL %s\n' "$1"; fail=$((fail + 1)); }
hdr() { printf '\n%s\n' "$1"; }

api() { glab api "$1" 2>/dev/null; }

command -v glab    >/dev/null || { echo "glab not installed"; exit 2; }
command -v python3 >/dev/null || { echo "python3 not installed"; exit 2; }

hdr "== GitLab runner (section 0) =="
runner_ids=$(api projects/:id/runners | python3 -c 'import json,sys
try:
    for r in json.load(sys.stdin): print(r.get("id"))
except Exception: pass')
if grep -qx "$RUNNER_ID" <<<"$runner_ids"; then
  ok "runner $RUNNER_ID assigned to project"
else
  bad "runner $RUNNER_ID not assigned — run: glab api -X POST projects/:id/runners -f runner_id=$RUNNER_ID"
fi

hdr "== CI tags on every job (section 0/11) =="
if [ ! -f "$CI_FILE" ]; then
  bad "$CI_FILE missing"
else
  untagged=$(python3 - "$CI_FILE" <<'PY'
import re, sys

RESERVED = {"stages", "workflow", "include", "variables", "image",
            "services", "cache", "before_script", "after_script"}
TAG = "linux-truenas"

blocks = {}
cur = None
in_tags = in_extends = False

for raw in open(sys.argv[1]):
    line = raw.rstrip()
    s = line.strip()
    if not s or s.startswith("#"):
        continue
    indent = len(line) - len(line.lstrip())
    top = re.match(r"^([A-Za-z0-9_.\-]+)\s*:", line)
    if top and indent == 0:
        cur = top.group(1)
        in_tags = in_extends = False
        if cur not in RESERVED:
            blocks.setdefault(cur, {"tag": False, "extends": []})
        continue
    if cur is None or cur not in blocks:
        continue

    m = re.match(r"^(tags|extends)\s*:\s*(.*)$", s)
    if m:
        key, rest = m.groups()
        in_tags = key == "tags" and rest == ""
        in_extends = key == "extends" and rest == ""
        if key == "tags" and TAG in rest:
            blocks[cur]["tag"] = True
        if key == "extends" and rest:
            blocks[cur]["extends"] += re.findall(r"[A-Za-z0-9_.\-]+", rest)
        continue
    if in_tags and TAG in s:
        blocks[cur]["tag"] = True
        continue
    if in_extends:
        blocks[cur]["extends"] += re.findall(r"[A-Za-z0-9_.\-]+", s.lstrip("- "))
        continue
    if indent <= 2:
        in_tags = in_extends = False

def_tag = blocks.get("default", {}).get("tag", False)

def tagged(name, seen):
    if name in seen or name not in blocks:
        return False
    seen.add(name)
    b = blocks[name]
    return b["tag"] or def_tag or any(tagged(e, seen) for e in b["extends"])

print("\n".join(n for n in blocks
                if not n.startswith(".") and n != "default"
                and not tagged(n, set())))
PY
)
  if [ -z "$untagged" ]; then
    ok "every job in $CI_FILE carries tags: [$RUNNER_TAG]"
  else
    bad "jobs missing 'tags: [$RUNNER_TAG]':"$'\n'"$untagged"
  fi
fi

hdr "== Pipeline green on HEAD (final gate) =="
head_sha=$(git rev-parse HEAD 2>/dev/null)
pipeline=$(api "projects/:id/pipelines?per_page=1" | python3 -c 'import json,sys
p = json.load(sys.stdin)
if p: print(p[0].get("status", ""), p[0].get("sha", ""))' 2>/dev/null)
p_status=${pipeline%% *}; p_sha=${pipeline##* }
if [ -z "$pipeline" ]; then
  bad "no pipeline found — push and verify a pipeline runs"
elif [ "$p_status" != "success" ]; then
  bad "latest pipeline is '$p_status' (must be success) — glab ci trace <job> for logs"
elif [ "$p_sha" != "$head_sha" ]; then
  bad "latest pipeline is green but on $p_sha, not HEAD $head_sha — unpushed commits"
else
  ok "latest pipeline success on HEAD ($head_sha)"
fi

hdr "== Tests, coverage, goldens (sections 3-4) =="
if [ "${SKIP_FLUTTER_TESTS:-0}" != "1" ]; then
  if flutter test --coverage >/dev/null 2>&1; then
    ok "flutter test --coverage passed"
  else
    bad "flutter test --coverage failed"
  fi
fi
if [ ! -f coverage/lcov.info ]; then
  bad "coverage/lcov.info missing — run flutter test --coverage"
else
  cov=$(python3 -c '
lf = lh = 0
for l in open("coverage/lcov.info"):
    if l.startswith("LF:"): lf += int(l[3:])
    if l.startswith("LH:"): lh += int(l[3:])
print(f"{lh} {lf}")')
  lh=${cov%% *}; lf=${cov##* }
  if [ "$lf" -gt 0 ] && [ "$lh" -eq "$lf" ]; then
    ok "line coverage 100% ($lh/$lf)"
  else
    bad "line coverage $lh/$lf — not 100%"
  fi
fi
if find test -name '*.png' -print -quit 2>/dev/null | grep -q .; then
  ok "golden PNGs exist under test/"
else
  bad "no golden PNGs — write golden tests and run flutter test --update-goldens"
fi
if grep -rlq 'matchesGoldenFile' test/ 2>/dev/null; then
  ok "golden tests use matchesGoldenFile"
else
  bad "no matchesGoldenFile usage found in test/"
fi

hdr "== Repo hygiene =="
[ -f LICENSE ] && grep -qi 'AFFERO' LICENSE \
  && ok "LICENSE is AGPL" || bad "LICENSE missing or not AGPL-3.0"
[ -f cog.toml ] && ok "cog.toml present" || bad "cog.toml missing (Cocogitto versioning)"
[ -f AGENTS.md ] && ok "AGENTS.md present" || bad "AGENTS.md missing"
if [ -f CLAUDE.md ] && grep -qi 'AGENTS.md' CLAUDE.md; then
  ok "CLAUDE.md points at AGENTS.md"
else
  bad "CLAUDE.md missing or does not point at AGENTS.md"
fi
if git check-ignore -q key.properties android/key.properties 2>/dev/null \
   || { [ -f .gitignore ] && grep -q 'key.properties' .gitignore; }; then
  ok "key.properties gitignored"
else
  bad "key.properties not gitignored"
fi
if { [ -f .gitignore ] && grep -Eq '(\.jks|\*.jks)' .gitignore; }; then
  ok ".jks gitignored"
else
  bad "keystore .jks not gitignored"
fi
if [ -f android/key.properties ] || compgen -G "*.jks" >/dev/null || compgen -G "android/*.jks" >/dev/null; then
  ok "keystore/key.properties exist locally"
else
  bad "no keystore or android/key.properties — section 6 not done"
fi
if compgen -G "$HOME/Desktop/*-keystore" >/dev/null; then
  ok "keystore backup on Desktop"
else
  bad "no ~/Desktop/<app>-keystore backup folder"
fi
if [ -d ios ]; then
  if [ -f repos/altstore.json ] && python3 -c 'import json; json.load(open("repos/altstore.json"))' 2>/dev/null; then
    ok "repos/altstore.json valid"
  else
    bad "repos/altstore.json missing/invalid (iOS project needs AltStore source)"
  fi
fi
if command -v cog >/dev/null && [ -f cog.toml ]; then
  if cog check >/dev/null 2>&1; then
    ok "cog check: commits conventional"
  else
    bad "cog check failed — non-conventional commits in history"
  fi
fi

proj=$(api projects/:id | python3 -c 'import json,sys
p = json.load(sys.stdin)
print(p.get("visibility", ""), p.get("path_with_namespace", "").lower())' 2>/dev/null)
vis=${proj%% *}; ns_path=${proj##* }
[ "$vis" = "public" ] && ok "repo is public" || bad "repo visibility is '$vis', must be public"

hdr "== GitLab Pages (section 10) =="
if [ -n "$ns_path" ] && [ "$ns_path" != "$proj" ]; then
  pages_host="https://${ns_path%%/*}.gitlab.io/${ns_path##*/}"
  for path in "/" "/app/"; do
    live=""
    for _ in 1 2 3 4 5 6; do
      curl -fsI "$pages_host$path" >/dev/null 2>&1 && { live=1; break; }
      sleep 10
    done
    [ -n "$live" ] && ok "Pages $pages_host$path loads" \
                  || bad "Pages $pages_host$path not reachable"
  done
else
  bad "could not resolve project path for Pages check"
fi

hdr "== README URLs (section 15) =="
if [ -f README.md ]; then
  urls=$(grep -oE 'https?://[^)"'"'"' <>]+' README.md | sed 's/[.,;]*$//' | sort -u)
  n=0
  while IFS= read -r u; do
    [ -z "$u" ] && continue
    n=$((n + 1))
    curl -fsI --max-time 15 "$u" >/dev/null 2>&1 \
      || curl -fs --max-time 15 -o /dev/null "$u" >/dev/null 2>&1 \
      && { ok "URL live: $u"; } || bad "URL dead: $u"
  done <<<"$urls"
  [ "$n" -eq 0 ] && bad "no URLs found in README.md"
else
  bad "README.md missing"
fi

hdr "== Result =="
if [ "$fail" -eq 0 ]; then
  echo "ALL CHECKS PASSED"
  exit 0
else
  echo "$fail check(s) FAILED — fix and re-run. Do not report done."
  exit 1
fi
