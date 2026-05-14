# Public Release Checklist

Status: private-checklist
Scope: Flux Reticle Fork public repo/package preparation
Target organization: `https://github.com/Shattersphere-Mods`
Current private source repo: `https://github.com/Shattersphere/FluxReticle`
Intended public repo name: undecided
Last updated: 2026-05-12

This file is private release/export guidance. Do not include it in public repos or release packages.

## Release Policy

- The private repo remains the default work target.
- Public repos/packages are curated outputs, not automatic mirrors.
- Do not update public releases after every change.
- Do not publish, tag, upload, or sync public release artifacts unless the user explicitly asks for release preparation or publication.
- Before public export, verify that private docs, local paths, deploy queues, and agent-only files are excluded.

## Include In Public Source Repo

- `src/`
- `data/`
- `shat_fr/`
- bundled selectable sprite-set folders under `shat_fr/graphics`
- `jars/FluxReticle.jar`
- `mod_info.json`
- `shat_fr.version`
- `FLUX_RETICLE_OPTIONS.ini`
- `scripts/build_mod.ps1`
- `README.md`
- `CHANGELOG.md`
- `LICENSE`, if one is added or restored with confirmed rights

## Exclude From Public Source Repo And Packages

- `AGENTS.md`
- `.agent/`
- `.agent-deploy/`
- `HANDOVER.md`
- `PLANS.md`
- `LESSONS.md`
- `local.properties`
- `build/`
- old logs, backups, generated deploy manifests, and machine-local state

## Public Metadata Surfaces

- `mod_info.json`
  - `id`
  - `name`
  - `author`
  - `version`
  - `description`
  - `gameVersion`
- `shat_fr.version`
  - `masterVersionFile`
  - `directDownloadURL`
  - `modName`
  - `modVersion`
- `data/config/version/version_files.csv`
- `README.md`
- `CHANGELOG.md`

## Required Public-Prep Transformations

- Decide the public repo name under `Shattersphere-Mods`.
- Update `shat_fr.version` URLs from the private repo to the public release repo when the public repo exists.
- Remove local machine paths from public-facing docs before export.
- Decide whether to keep `jars/FluxReticle.jar` in the public source repo or build it only for release packages.
- Add or verify the license before public release. No `LICENSE` file is currently present.
- Confirm upstream attribution and any redistribution requirements before publishing.
- Confirm the final public version string and align all version surfaces.

## Package Contents For Player Release

Include only the runtime surface Starsector loads:

- `mod_info.json`
- `FLUX_RETICLE_OPTIONS.ini`
- `data/`
- `shat_fr/`
- `jars/FluxReticle.jar`
- `shat_fr.version`
- `README.md`
- `CHANGELOG.md`
- `LICENSE`, if present

Exclude source-only scripts and private docs unless the release package is intentionally a source bundle.

## Validation Before Public Export

- Build the jar through `scripts/build_mod.ps1`.
- Validate `data/config/LunaSettings.csv` has non-empty unique `fieldID` values.
- Deploy locally through `scripts/deploy_mod.ps1` and verify live parity or queued status.
- Run an in-game combat check for reticle visibility, cursor reset, color customization, distance scaling, and flash behavior.
- Verify TriOS or the Starsector launcher sees `Flux Reticle Fork` as separate from upstream Flux Reticle.
- Inspect the public output for private material and machine-specific paths.

## Leak-Scan Terms

Search public output for these terms before publishing:

- `Codex`
- `agent`
- `.agent`
- `.agent-deploy`
- `HANDOVER`
- `PLANS`
- `LESSONS`
- `D:\`
- `C:\Games`
- `Sean Mods`
- `local.properties`
- `Shattersphere/FluxReticle`
