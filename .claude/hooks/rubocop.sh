#!/usr/bin/env bash
# PostToolUse hook: autocorrect the edited Ruby file, report what is left.
set -uo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
file="$(jq -r '.tool_response.filePath // .tool_input.file_path // empty')"

[ -n "$file" ] || exit 0
[ -f "$file" ] || exit 0
case "$file" in
  "$repo"/*) ;;
  *) exit 0 ;;
esac
case "$file" in
  *.rb|*.rake|*/Gemfile|*/Rakefile) ;;
  *) exit 0 ;;
esac

cd "$repo" || exit 0
# The project requires this comment, but only the unsafe pass adds it.
bin/rubocop -A --only Style/FrozenStringLiteralComment --force-exclusion "$file" >/dev/null 2>&1

out="$(bin/rubocop --autocorrect --format simple --force-exclusion "$file" 2>&1)" && exit 0

echo "RuboCop offenses remain in ${file#"$repo"/} after autocorrect:" >&2
echo "$out" >&2
exit 2
