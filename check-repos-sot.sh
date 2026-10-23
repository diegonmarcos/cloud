#!/usr/bin/env bash
# #1073 this farm's repos.json is a SUBSET of the one registry, git-repos-master/repos.json.
# Fails (exit 1) when an entry drifted from it (url, private, status, a rename it did not follow).
#   ./check-repos-sot.sh          check          ./check-repos-sot.sh --fix   rewrite the drifted fields
# The registry and its checker are fetched from the declared url (override REPOS_SOT_BASE);
# a checkout of git-repos-master next to this one (../git-repos-master) is used when present.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
BASE="${REPOS_SOT_BASE:-https://raw.githubusercontent.com/diegonmarcos/git-repos-master/main}"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
if [ -f "$HERE/../git-repos-master/repos-sot.js" ]; then
  cp "$HERE/../git-repos-master/repos-sot.js" "$HERE/../git-repos-master/repos.json" "$T/"
else
  for f in repos.json repos-sot.js; do curl -fsSL --max-time 20 "$BASE/$f" -o "$T/$f" || { echo "check-repos-sot: cannot fetch $BASE/$f" >&2; exit 2; }; done
fi
node "$T/repos-sot.js" check-subset "$HERE/repos.json" ${1:+"$1"}
