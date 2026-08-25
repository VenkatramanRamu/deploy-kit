#!/usr/bin/env bash
#
# restart.sh: (re)start the app's process under PM2, from its current release.
#
#   Usage:  ./scripts/restart.sh --app=<name>
#
set -euo pipefail

kit="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$kit/config/deploy.config.sh"

app=""
for arg in "$@"; do case "$arg" in --app=*) app="${arg#*=}" ;; esac; done
[[ -n "$app" ]] || { echo "usage: restart.sh --app=NAME" >&2; exit 2; }

current="$REMOTE_ROOT/$app/current"
eco="$current/ecosystem.config.js"

if [[ -f "$eco" ]]; then
  # Ecosystem file present, let PM2 manage the process from it.
  # startOrReload also handles the first start.
  ( cd "$current" && pm2 startOrReload "$eco" )
else
  pm2 restart "$app"
fi
echo "✓ restarted '$app'"
