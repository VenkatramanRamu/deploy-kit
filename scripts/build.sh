#!/usr/bin/env bash
#
# build.sh: build an app, package it, and upload the artifact to a target env.
#
#   Usage:  scripts/build.sh --app=<name> --type=<frontend|backend> --env=<staging|production>
#
# Run from inside the app you want to ship. For reproducible builds, run it
# through scripts/build-in-docker.sh instead (same arguments).
#
set -euo pipefail

kit="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$kit/config/deploy.config.sh"

# parse arguments
app="" type="" env=""
for arg in "$@"; do
  case "$arg" in
    --app=*)  app="${arg#*=}" ;;
    --type=*) type="${arg#*=}" ;;
    --env=*)  env="${arg#*=}" ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done

if [[ -z "$app" || -z "$type" || -z "$env" ]]; then
  echo "usage: build.sh --app=NAME --type=frontend|backend --env=staging|production" >&2
  exit 2
fi

host="${DEPLOY_HOST[$env]:-}"
want_branch="${DEPLOY_BRANCH[$env]:-}"
[[ -n "$host" ]] || { echo "no host configured for env '$env'" >&2; exit 2; }

# safety guards
# don't ship uncommitted work
if [[ -n "$(git status --porcelain)" ]]; then
  echo "✗ working tree is dirty; commit or stash before deploying." >&2
  exit 1
fi
# don't ship the wrong branch to the wrong environment
branch="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$branch" != "$want_branch" ]]; then
  echo "✗ '$env' deploys from '$want_branch', but you are on '$branch'." >&2
  exit 1
fi

# pick the package manager from whatever lockfile is present
if [[ -f pnpm-lock.yaml ]]; then
  PM=pnpm;  install="pnpm install --frozen-lockfile";        install_prod="pnpm install --frozen-lockfile --prod"
elif [[ -f package-lock.json ]]; then
  PM=npm;   install="npm ci";                                install_prod="npm ci --omit=dev"
else
  PM=npm;   install="npm install";                           install_prod="npm install --omit=dev"
fi

commit="$(git rev-parse HEAD)"
stamp="$(date -u +%Y%m%d-%H%M%S)"
artifact="${app}.${env}.${stamp}.${commit:0:8}.tar.gz"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "→ building '$app' ($type) for '$env' at ${commit:0:8} with $PM"

case "$type" in
  frontend)
    $install
    $PM run build
    out="build"; [[ -d dist ]] && out="dist"
    echo "$commit" > "$out/COMMIT"
    tar -C "$out" -czf "$tmp/$artifact" .
    ;;
  backend)
    $install_prod
    echo "$commit" > COMMIT
    # ship source + production deps, skip vcs, local, and secret files
    tar --exclude='./.git' --exclude='./_local' --exclude='./.env*' \
        -czf "$tmp/$artifact" .
    rm -f COMMIT
    ;;
  *)
    echo "unknown type '$type' (expected frontend|backend)" >&2; exit 2 ;;
esac

echo "→ uploading $artifact → $host:$REMOTE_UPLOAD"
scp "$tmp/$artifact" "$host:$REMOTE_UPLOAD/"

echo "✓ uploaded. now, on the server, run:"
echo "    ./scripts/deploy.sh --app=$app --artifact=$artifact --restart"
