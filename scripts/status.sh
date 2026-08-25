#!/usr/bin/env bash
#
# status.sh: show PM2 process status.
#
#   Usage:  ./scripts/status.sh [--app=<name>]
#
set -euo pipefail

app=""
for arg in "$@"; do case "$arg" in --app=*) app="${arg#*=}" ;; esac; done

if [[ -n "$app" ]]; then
  pm2 describe "$app"
else
  pm2 ls
fi
