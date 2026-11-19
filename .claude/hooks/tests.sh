#!/usr/bin/env bash
# Stop hook: keep the suite and the coverage gate green while Ruby changed.
set -uo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo" || exit 0

# Escape valve, e.g. while background agents are still editing tests.
[ -e tmp/gate-paused ] && exit 0

git status --porcelain -- '*.rb' '*.rake' | grep -q . || exit 0

out="$(RAILS_ENV=test bin/rails test 2>&1)" && exit 0

echo "Tests or the SimpleCov gate failed. Fix before finishing:" >&2
echo "$out" | tail -40 >&2
exit 2
