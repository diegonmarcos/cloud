#!/usr/bin/env bash
# #1073 this farm's repos.json is a SUBSET of the one registry, _git-repos-master/0_registry/repos.json.
# Fails (exit 1) when an entry drifted from it (url, private, status, a rename it did not follow).
#   ./check-repos-sot.sh          check          ./check-repos-sot.sh --fix   rewrite the drifted fields
# The registry and its checker (0_registry/) are fetched from the declared url (override REPOS_SOT_BASE);
# a checkout of _git-repos-master next to this one (../_git-repos-master) is used when present.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
BASE="${REPOS_SOT_BASE:-https://raw.githubusercontent.com/diegonmarcos/_git-repos-master/main}"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
if [ -f "$HERE/../_git-repos-master/0_registry/repos-sot.js" ]; then
  cp "$HERE/../_git-repos-master/0_registry/repos-sot.js" "$HERE/../_git-repos-master/0_registry/repos.json" "$T/"
else
  for f in repos.json repos-sot.js; do curl -fsSL --max-time 20 "$BASE/0_registry/$f" -o "$T/$f" || { echo "check-repos-sot: cannot fetch $BASE/0_registry/$f" >&2; exit 2; }; done
fi
node "$T/repos-sot.js" check-subset "$HERE/repos.json" ${1:+"$1"}
