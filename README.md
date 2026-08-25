# deploy-kit

Scripts I use to build a frontend or Node.js backend, ship it to a Linux VM, and run it under PM2. You build once, upload a single artifact, switch to it with a symlink, and roll back with one command if it breaks.

It's just Bash, SSH, and PM2. Nothing to set up beyond that. It's meant for small setups: a few apps on one or two servers, where you still want deploys that don't surprise you.

> This is a generic version of the deploy setup I run for a multi-app EdTech platform at work, with the company-specific parts stripped out. It's small on purpose. For anything bigger you'd want a real CI/CD pipeline, health checks, and blue-green.

---

## What it does for you

The usual problems with "SSH in and git pull":

- **It won't build a dirty tree.** If you have uncommitted changes, the build stops.
- **It checks the branch matches the environment.** `production` only builds from `main`, `staging` only from `staging`, so you can't push the wrong branch by accident.
- **It records what's live.** The git commit is written into every build (a `COMMIT` file), so you can always tell which commit is running.
- **Releases swap atomically, and rollback is one command.** Each deploy unpacks into its own `releases/<timestamp>/` folder, then a `current` symlink is pointed at it. Rolling back just points the symlink back at the previous release. The old releases stay on disk.
- **Builds can run in Docker.** Run the build inside a pinned `node:20-bookworm` image so it doesn't matter whose machine builds it or what they have installed.

---

## How it works

```
  LOCAL (your machine)                    SERVER (the VM)
  ────────────────────                    ──────────────
  build.sh --env=production
    ├─ guard: clean git tree?
    ├─ guard: branch == main?
    ├─ npm ci && npm run build
    ├─ stamp git commit → COMMIT
    └─ tar → app.production.<ts>.<sha>.tar.gz
                    │
                    │  scp
                    ▼
                              upload/app.production.<ts>.<sha>.tar.gz
                                            │
                              deploy.sh --app=app --artifact=… --restart
                                ├─ unpack → releases/<ts>/
                                ├─ ln -sfn releases/<ts>  current   (atomic swap)
                                ├─ prune to newest KEEP_RELEASES
                                └─ pm2 startOrReload current/ecosystem.config.js
```

Static frontends get served by pointing the web server's root at `.../current`. Backends run under PM2 from `.../current`.

---

## Server layout

```
/var/www/app/
├── upload/                  # incoming build artifacts land here
└── <app-name>/
    ├── current -> releases/20260825-074500     # symlink to the live release
    └── releases/
        ├── 20260825-074500/   # newest (live)
        ├── 20260824-181200/   # kept for rollback
        └── …                  # older ones pruned past KEEP_RELEASES
```

---

## Usage

**1. Configure.** Copy the example config and fill in your hosts, branches, and paths:

```bash
cp config/deploy.config.example.sh config/deploy.config.sh
# edit config/deploy.config.sh   (it's gitignored, so real hosts never get committed)
```

**2. Build and upload** (from your machine, inside the app you're shipping).

Build inside the pinned Docker image (what I'd usually do):

```bash
/path/to/deploy-kit/scripts/build-in-docker.sh --app=api --type=backend --env=production
```

Or run the build directly with your local toolchain (same arguments):

```bash
/path/to/deploy-kit/scripts/build.sh --app=web --type=frontend --env=production
```

`build.sh` picks the package manager from whatever lockfile is present (`pnpm-lock.yaml` → pnpm, `package-lock.json` → npm).

**3. Activate on the server.** SSH in, then:

```bash
./scripts/deploy.sh --app=api --artifact=api.production.20260825-074500.a1b2c3d4.tar.gz --restart
```

**4. Roll back if something breaks:**

```bash
./scripts/rollback.sh --app=api
```

Other server helpers: `restart.sh --app=api`, `stop.sh --app=api`, `status.sh [--app=api]`.

---

## Configuration (`config/deploy.config.sh`)

| Setting | What it does |
|---|---|
| `DEPLOY_HOST[env]` | `user@host` SSH target per environment |
| `DEPLOY_BRANCH[env]` | the only branch allowed to deploy to that environment |
| `REMOTE_ROOT` | base directory for apps and uploads on the server |
| `REMOTE_UPLOAD` | where build artifacts are uploaded |
| `KEEP_RELEASES` | how many old releases to keep for rollback |

---

## Try it

`examples/` has a small static frontend and an Express backend (with a PM2 `ecosystem.config.js`) so you can run through the whole build, deploy, and rollback yourself.

---

## Setup notes

- Make the scripts executable after cloning: `chmod +x scripts/*.sh`
- Needs `bash`, `git`, `tar`, and `ssh`/`scp` locally, and `pm2` on the server.

## License

MIT, see [LICENSE](LICENSE).
