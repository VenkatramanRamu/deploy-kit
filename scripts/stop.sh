#!/usr/bin/env bash
#
# stop.sh: stop the app's PM2 process.
#
#   Usage:  ./scripts/stop.sh --app=<name>
#
set -euo pipefail

app=""
for arg in "$@"; do case "$arg" in --app=*) app="${arg#*=}" ;; esac; done
[[ -n "$app" ]] || { echo "usage: stop.sh --app=NAME" >&2; exit 2; }

pm2 stop "$app"
echo "✓ stopped '$app'"
