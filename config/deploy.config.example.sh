#!/usr/bin/env bash
# deploy-kit configuration.
# Copy this file to `deploy.config.sh` (which is gitignored) and fill in
# the values for your project. Never commit real hostnames or paths.

# SSH target for each environment ("user@host").
declare -A DEPLOY_HOST=(
  [staging]="deploy@staging.example.com"
  [production]="deploy@example.com"
)

# The only git branch allowed to deploy to each environment.
# The build refuses to run if you're on a different branch.
declare -A DEPLOY_BRANCH=(
  [staging]="staging"
  [production]="main"
)

# Server-side layout.
REMOTE_ROOT="/var/www/app"           # apps and uploads live under here
REMOTE_UPLOAD="$REMOTE_ROOT/upload"  # build artifacts are uploaded here

# How many old releases to keep on disk for rollback.
KEEP_RELEASES=5
