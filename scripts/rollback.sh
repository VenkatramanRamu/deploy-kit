#!/usr/bin/env bash
#
# rollback.sh: point `current` back to the previous release, then restart.
#
#   Usage:  ./scripts/rollback.sh --app=<name>
#
set -euo pipefail

kit="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$kit/config/deploy.config.sh"

app=""
for arg in "$@"; do case "$arg" in --app=*) app="${arg#*=}" ;; esac; done
[[ -n "$app" ]] || { echo "usage: rollback.sh --app=NAME" >&2; exit 2; }

app_root="$REMOTE_ROOT/$app"
releases="$app_root/releases"

# releases newest-first; [0] is live, [1] is the one to roll back to
mapfile -t rel < <(ls -1dt "$releases"/*/ 2>/dev/null)
[[ "${#rel[@]}" -ge 2 ]] || { echo "✗ need at least 2 releases to roll back" >&2; exit 1; }

previous="${rel[1]%/}"
ln -sfn "$previous" "$app_root/current"
echo "✓ rolled '$app' back to $(basename "$previous")"

"$kit/scripts/restart.sh" --app="$app"
