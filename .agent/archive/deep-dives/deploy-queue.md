# Deploy queue deep dive

Status: active-reference
Scope: Flux Reticle Fork deploy workflow
Last verified: 2026-05-15
Read when: changing deploy scripts, runtime artifact validation, blocked deploy behavior, or `.agent-deploy` state handling
Do not read for: ordinary Java rendering edits that do not change build/deploy behavior
Related files: `scripts/deploy_mod.ps1`, `scripts/build_mod.ps1`, `.gitignore`, `.agent-deploy/`, `AGENTS.md`, `.agent/BRIEF.md`
Search tags: deploy, queue, staging, Starsector, locked jar, parity, `.agent-deploy`, `flux-reticle-fork-deploy`

## Summary

- The source repo is authoritative; `C:\Games\Starsector\mods\Flux Reticle Fork` is a deploy target.
- Runtime changes must use `scripts\deploy_mod.ps1`, not manual live-folder copies.
- The deploy script is copied from the shared queue-and-supersede template under `D:\Sean Mods\agent-deploy-template`.
- Deploy state and staged artifacts live under `.agent-deploy/`, which is intentionally gitignored.
- The deploy name is `flux-reticle-fork-deploy`; superseding should only affect older queued deploys for the same repo root, deploy target, and deploy name.
- If Starsector is running, the deploy script stages already-built artifacts and starts a background waiter instead of overwriting a potentially locked jar.
- If the native minimized/no-activate worker launch fails, the script falls back to `Start-Process -WindowStyle Minimized` so the deploy still has a visible waiting worker without trapping the agent session.
- Queued means not live yet. Report deploy status as queued/pending until the worker publishes and post-deploy validation passes.
- Post-deploy validation checks source/live hashes for runtime files and ensures retired upstream paths are absent.

## Index

- `Deploy Surface`: runtime files copied to the live mod folder.
- `Blocked Deploy Behavior`: how queued deploys should behave when Starsector is running.
- `Validation`: checks that prove source/live parity.
- `Common Mistakes`: behaviors to avoid.

## Details

### Deploy Surface

The deploy script stages and publishes these repo paths:

- `FLUX_RETICLE_OPTIONS.ini`
- `data`
- `jars`
- `mod_info.json`
- `shat_fr.version`
- individual root runtime files under `shat_fr\graphics`
- bundled selectable sprite-set folders under `shat_fr\graphics`

The script removes retired upstream paths from the live target during publish:

- `Change Log.url`
- `jars\src.url`
- `sun_fr`
- `sun_fr.version`
- temporary local asset folders under `shat_fr\graphics`, such as `backup-before-*`, `lanczos`, and `nearest`

### Blocked Deploy Behavior

Blocked processes are Starsector-related `java` and `Starsector` processes. When found, the script should:

- stage the current artifacts;
- start a minimized visible background worker;
- fall back to a normal minimized `Start-Process` worker if the native no-activate launch fails;
- return control to the agent;
- wait in the worker until blockers exit;
- publish the staged artifacts afterward;
- supersede only older queued deploys for this same repo/deploy target/deploy name.

### Validation

Pre-deploy validation checks `data\config\LunaSettings.csv` for:

- non-empty `fieldID`;
- mod id `shattersphere_flux_reticle_fork`;
- field ids using `shat_fr_`;
- no duplicate `fieldID`.

Post-deploy validation checks source/live SHA-256 parity for important runtime files:

- `FLUX_RETICLE_OPTIONS.ini`
- `data\config\LunaSettings.csv`
- `data\config\LunaSettingsConfig.json`
- `data\config\settings.json`
- `data\config\sounds.json`
- `data\config\version\version_files.csv`
- `jars\FluxReticle.jar`
- `mod_info.json`
- `shat_fr.version`

### Common Mistakes

- Do not claim live deploy completed when the script queued a worker.
- Do not kill Starsector to force deploy.
- Do not manually copy runtime files into the live mod folder unless the user explicitly asks.
- Do not treat jar parity alone as enough when `data/config`, metadata, or assets changed.
- Do not manage unrelated deploy queues from other repos.

## Evidence / provenance

- This repo adopted the shared deploy-template behavior after the color/settings work made repeated runtime deploys likely.
- A queued deploy was observed under `.agent-deploy/` while Starsector was running, then later reached `Phase: complete`.
