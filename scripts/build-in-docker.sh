#!/usr/bin/env bash
#
# build-in-docker.sh: run the build inside a pinned Docker image so the
# artifact is identical no matter whose machine builds it. Takes the same
# arguments as build.sh.
#
#   Usage:  scripts/build-in-docker.sh --app=<name> --type=<frontend|backend> --env=<env>
#
# Mounts:
#   $PWD        -> /workspace   (the app you're shipping)
#   this kit    -> /deploy-kit  (build/config scripts)
#   ~/.ssh      -> /root/.ssh   (read-only, so scp can authenticate)
#
set -euo pipefail

kit="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
image="deploy-kit-build:node20"

# Build the image once; Docker caches it after the first run.
docker build -t "$image" "$kit/docker"

docker run --rm -it \
  -v "$PWD":/workspace \
  -v "$kit":/deploy-kit \
  -v "$HOME/.ssh":/root/.ssh:ro \
  -e BUILD_ENV=docker \
  -w /workspace \
  "$image" \
  /deploy-kit/scripts/build.sh "$@"
