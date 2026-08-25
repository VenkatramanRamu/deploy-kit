# Pinned build environment, so `build.sh` produces identical artifacts
# no matter whose machine runs it. Build once with build-in-docker.sh.
FROM node:20-bookworm

# Tools the build needs:
#   zip             package the artifact
#   git             stamp the commit into the build
#   openssh-client  scp the artifact to the server
#   build-essential compile native npm modules
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential zip git openssh-client ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Pin the package manager so lockfile resolution is deterministic.
ENV PNPM_VERSION=10.4.0
RUN corepack enable && corepack prepare "pnpm@${PNPM_VERSION}" --activate \
    && npm install -g dotenv-cli \
    && pnpm config set store-dir /root/.pnpm

ENV PATH="${PATH}:node_modules/.bin"
WORKDIR /workspace
CMD ["bash"]
