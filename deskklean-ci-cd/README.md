# DeskKlean CI/CD — How `.github/workflows/ci.yml` and `electron-builder.yml` Work Together

Reference project: `~/Documents/coding/antigravity-projects/DeskKlean/` (repo [`chairielazizi/deskklean`](https://github.com/chairielazizi/deskklean), local branch `v1.1.0-work`).

## What is CI/CD

- **CI (Continuous Integration)** — automatically verifies every code change the moment it is pushed or opened as a PR. It checks out the code, installs dependencies deterministically, runs type-checks, builds the app, and runs the entire test suite. If anything fails, the pipeline stops and broken code never proceeds.
- **CD (Continuous Delivery / Deployment)** — once CI passes, the finished application is packaged and published. For DeskKlean, pushing a git tag like `git tag v1.1.0 && git push origin v1.1.0` triggers the packaging job: it compiles Electron + React, builds the Windows installer + portable executable, generates differential-update manifests, and publishes a GitHub Release with attached release notes.

DeskKlean's CI/CD is driven by the interaction of two files:

1. `electron-builder.yml` — the **packaging blueprint**. Describes how compiled JS/HTML becomes Windows desktop binaries and how auto-updates are configured.
2. `.github/workflows/ci.yml` — the **cloud pipeline**. The GitHub Actions robot that spins up a virtual Windows runner to test, build, package, and publish releases.

Neither file references the other directly — they coordinate through shared conventions (output directory `release/`, versions in `package.json`, `publish.provider: github`, runner node version, artifact glob patterns).

---

## 1. Relationship between the two files (coordinated, not coupled)

They do not import one another. The glue is a chain of shared values:

| Shared value | Who owns it | Consequence if they disagree |
|---|---|---|
| `release/` as output dir | electron-builder (`directories.output`) | CI's `release/*.exe` upload glob matches nothing; `if-no-files-found: warn` papers over it silently |
| `package.json` `version` field | source of truth `1.0.1` | electron-builder bakes this into `latest.yml`/artifact names; the app's `APP_VERSION` constant (updater.ts) must be kept in sync manually |
| `publish.provider: github`, `owner`, `repo` | electron-builder | Phase-16 auto-updater (electron-updater) reads GitHub Releases matching these to pull `latest.yml`; if CI stops publishing there (or drifts to another owner), updates silently break |
| `--publish never` flag | package.json `dist` script | EB runs without trying to authenticate to GitHub; CI must upload the files instead via `GITHUB_TOKEN` |
| runner OS `windows-latest` + Node 20.x | ci.yml | install/build/test/package all assume Windows runtime; NSIS installers cannot be produced on macOS/Linux |
| `resources/icon.ico` exists | electron-builder (`buildResources`) | EB fails at package step; only detected at CI packaging time |
| `docs/RELEASE-NOTES.md` | CI `body_path` | Fresh tag extraction needs this file present; missing = gh-release step fails at release |

In short: ci.yml decides **when** and **how to orchestrate**; electron-builder.yml decides **what the artefacts look like**. Changing one without the other usually manifests as a silent drift (bad uploads, stale metadata, broken auto-updater) rather than a hard failure.

---

## 2. `electron-builder.yml` — The Packaging Blueprint

Config for electron-builder, the standard tool for packaging Electron desktop apps. Consumed automatically when `electron-builder` runs — the `publish:`, `directories:`, `win:` definitions are read by it.

### Identity & copyright

```yaml
appId: com.deskklean.app
productName: DeskKlean
copyright: Copyright © 2026 DeskKlean Team
```

- `appId` → Windows Application ID used for registration, notifications, single-instance locks.
- `productName` → display name in Start Menu / Windows Settings.
- `copyright` → embedded copyright string in the installed files.

### Auto-update metadata

```yaml
publish:
  provider: github
  owner: chairielazizi
  repo: deskklean
  releaseType: release
```

- Tells electron-builder where the published app lives on the internet.
- When run, it generates `latest.yml` (version number, file size, SHA-512) and `*.blockmap` files (binary chunk maps for differential downloads) in the output dir.
- Why `--publish never` (in package.json): the local/CI runner should NOT try to push to GitHub itself (needs a PAT) — it just **generates** the metadata; CI's GitHub Actions bot publishes through `GITHUB_TOKEN`.

### Directories

```yaml
directories:
  output: release
  buildResources: resources
```

- All artefacts land in `release/` (this is the directory CI ends up uploading).
- `resources/` holds binary assets (e.g. `resources/icon.ico`) that ship in the main bundle.

### Bundle whitelist

```yaml
files:
  - dist/**/*
  - package.json
```

- Only what's listed gets packed into the final `.asar` archive. Everything else (`src/`, `scripts/`, `docs/`, dev dependencies) is excluded — keeps the installer ~80 MB instead of hundreds.

### Windows build targets

```yaml
win:
  target:
    - target: nsis
      arch: [x64]
    - target: portable
      arch: [x64]
  icon: resources/icon.ico
  requestedExecutionLevel: asInvoker
```

- **`nsis`** → standard Windows Setup wizard installer (`DeskKlean.Setup.x.y.z.exe`).
- **`portable`** → single-file, zero-install executable (`DeskKlean-Portable-x.y.z.exe`).
- `requestedExecutionLevel: asInvoker` → launches **without** immediately demanding admin rights. DeskKlean elevates on-demand through its own framework (registry cleaner, scheduled task, etc.) so the installer doesn't UAC-prompt the user unnecessarily.

### NSIS installer UX

```yaml
nsis:
  oneClick: false
  allowToChangeInstallationDirectory: true
  perMachine: false
  createDesktopShortcut: always
  createStartMenuShortcut: true
  shortcutName: DeskKlean
  uninstallDisplayName: DeskKlean System Optimizer
```

- Wizard style (user can choose install directory).
- `perMachine: false` → per-user install, no admin rights required.
- Desktop / Start Menu shortcuts are created.
- Clean branding in "Uninstall programs".

### Portable

```yaml
portable:
  artifactName: ${productName}-Portable-${version}.${ext}
```

Renders as `DeskKlean-Portable-1.0.1.exe` etc. Depends on `package.json` `version` (`1.0.1` currently).

---

## 3. `.github/workflows/ci.yml` — The GitHub Actions Pipeline

Runs on `windows-latest`, triggered by three events:

```yaml
on:
  push:
    branches: [main]
    tags: ['v*']
  pull_request:
    branches: [main]

permissions:
  contents: write
```

- Any push or PR to `main` → runs CI (tests + builds).
- Push a **tag** matching `v*` (e.g. `v1.1.0`) → triggers the full **release** path: packaging, artifact upload, GitHub Release creation.
- `contents: write` → GitHub bot can create releases and upload artefacts.

### Pipeline flow (in order)

```text
1. Checkout        (actions/checkout@v4)
2. Setup Node 20.x  (actions/setup-node@v4, npm cache)
3. npm ci          (deterministic install from package-lock.json)
4. Type-check main (npx tsc -p tsconfig.main.json --noEmit)
5. Type-check renderer (npx tsc -p tsconfig.json --noEmit)
6. Build main      (npm run build:main → dist/main/)
7. Pure-logic unit tests (scripts/test-*.mjs, set -e)
8. Build renderer (npm run build:renderer → dist/renderer/ via Vite)
9. Release gate  →  if startsWith(github.ref, 'refs/tags/v')
   └─ Package    (npm run dist)
      └─ electron-builder generates release/*.exe, *.zip, latest.yml, *.blockmap
10. Upload build artefacts (release/*.exe, *.zip, latest.yml, *.blockmap)
11. Create GitHub Release (softprops/action-gh-release@v2,
    body_path: docs/RELEASE-NOTES.md, GITHUB_TOKEN)
```

### Points to flag

- **Pipeline assumes Windows.** NSIS installers and Windows-native tests require `windows-latest`; building for macOS/Linux is not supported by this pipeline.
- **Two type-check gates.** `tsconfig.main.json` verifies the Electron main process / IPC / system modules; `tsconfig.json` verifies the React renderer.
- **`npm ci` vs `npm install`.** `npm ci` deletes node_modules and reinstalls strictly from the lockfile → reproducible builds.
- **Test loop quirk:** it runs *every* `scripts/test-*.mjs` except `*test-phase2-live.mjs*`. Any new test script added (e.g. `test-leftovers.mjs`, `test-scheduled-clean.mjs`) runs automatically on every push. A single failure kills the job (`set -e`).
- **Gated packaging.** Steps 9–11 only execute when a `v*` tag was pushed. Opening a PR or pushing a commit to `main` ends at Step 8.
- **`if-no-files-found: warn`** on the upload-artifact step is lenient. If `release/` failed to emit the expected binaries (EB config drift, missing `icon.ico`), the job still succeeds and nothing is uploaded — silently.
- **No auto-version-bump.** You must bump `package.json` `version` and push the matching tag yourself; there is no automation updating the version field.

---

## 4. How the chain powers DeskKlean's auto-updater (Phase 16)

The whole point of wiring `provider: github` in EB config + tag-driven release publishing is to feed `electron-updater`:

```text
Developer:  git tag v1.1.0 && git push origin v1.1.0
                       │
                       ▼
               GitHub Actions (ci.yml)
                       │
   runs npm run dist  →  reads electron-builder.yml
                       │
   Generates in release/:
     ├── DeskKlean.Setup.1.1.0.exe
     ├── latest.yml     ← version, SHA-512 hashes, file link
     └── .blockmap files
                       │
                       ▼
   Published to GitHub Release on chairielazizi/deskklean
                       │
                       ▼
   User's running DeskKlean (v1.0.1):
     ├── updater.ts queries: github.com/chairielazizi/deskklean/releases/latest/download/latest.yml
     ├── Compares version 1.1.0 > 1.0.1
     ├── Downloads changed blocks using .blockmap
     └── Prompts: "Update 1.1.0 downloaded — restart to install"
```

If `publish: provider: github` were removed from electron-builder.yml → EB wouldn't emit `latest.yml` / blockmaps → the app would have **no manifest to read** → auto-updating silently dead.

If CI's upload path (`release/*`) drifted from EB's `directories.output` → artefacts never land on the release page → installed clients never see anything newer.

---

## 5. When to reinstall / run pieces again (operational notes)

| If you change … | You need to re-run … |
|---|---|
| CI trigger filter / Node version | Nothing local; the next push/PR automatically uses the new YAML |
| `electron-builder.yml` (icon, targets, output dir, publish) | The next tag push (or run `npm run dist` locally on Windows) — there's no dry-run locally that proves the CI wiring; the release is the proof |
| `package.json` version | Both `package.json` and push a matching `v*` tag; mismatched or missing tag → pipeline runs but only uploads artefacts to Actions storage, no public Release |
| `docs/RELEASE-NOTES.md` | Latest tag push consumes it; it's the release-body source |

Local diagnostic only: `npm run build` on Linux compiles bundles but **cannot** produce NSIS artefacts — only Windows runners can package.
