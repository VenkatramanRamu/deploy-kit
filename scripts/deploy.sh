#!/usr/bin/env bash
#
# deploy.sh: activate an uploaded artifact as the current release. Runs on the server.
#
#   Usage:  ./scripts/deploy.sh --app=<name> --artifact=<file> [--restart]
#
set -euo pipefail

kit="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$kit/config/deploy.config.sh"

app="" artifact="" restart=0
for arg in "$@"; do
  case "$arg" in
    --app=*)      app="${arg#*=}" ;;
    --artifact=*) artifact="${arg#*=}" ;;
    --restart)    restart=1 ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done
[[ -n "$app" && -n "$artifact" ]] || { echo "usage: deploy.sh --app=NAME --artifact=FILE [--restart]" >&2; exit 2; }

src="$REMOTE_UPLOAD/$artifact"
[[ -f "$src" ]] || { echo "✗ artifact not found: $src" >&2; exit 1; }

app_root="$REMOTE_ROOT/$app"
releases="$app_root/releases"
release="$releases/$(date -u +%Y%m%d-%H%M%S)"
mkdir -p "$release"

echo "→ unpacking $artifact"
tar -xzf "$src" -C "$release"

# Point `current` at the new release. ln -sfn is atomic, so there's never a
# moment where `current` points at nothing.
ln -sfn "$release" "$app_root/current"
short="$(cut -c1-8 "$release/COMMIT" 2>/dev/null || echo unknown)"
echo "✓ '$app' now points at $(basename "$release")  (commit $short)"

# Keep only the newest $KEEP_RELEASES releases, prune the rest.
# (releases/ holds only the timestamped dirs. The `current` symlink lives one
# level up, so it never gets pruned.)
ls -1dt "$releases"/*/ 2>/dev/null | tail -n +"$((KEEP_RELEASES + 1))" | xargs -r rm -rf

[[ "$restart" == 1 ]] && "$kit/scripts/restart.sh" --app="$app"
exit 0
