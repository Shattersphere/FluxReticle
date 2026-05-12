# Agent Instructions

## Standard Work Loop

- Start repository-changing work with `git status --short --branch`.
- Identify likely affected files, build/check/deploy commands, deploy target, staging path, and dirty/untracked files before editing.
- Read `.agent/INDEX.md` for doc routing, then `.agent/BRIEF.md` when the task depends on current project state.
- Search before opening larger docs: `rg -n "<term>" HANDOVER.md PLANS.md .agent README.md`.
- Avoid broad scans of build output, binary assets, jars, old logs, and deploy state unless directly relevant.
- Keep patches small and commit/push completed work to `origin/master` for this personal modding repo unless the user says otherwise.

## Project Identity

- Source root: `D:\Sean Mods\Flux Reticle Fork`
- Game: Starsector
- Live deploy target: `C:\Games\Starsector\mods\Flux Reticle Fork`
- Deploy staging/state path: `.agent-deploy\`
- Deploy name: `flux-reticle-fork-deploy`
- Mod id: `shattersphere_flux_reticle_fork`
- Runtime prefix: `shat_fr`
- Main plugin: `flux_reticle.ModPlugin`
- Combat plugin: `flux_reticle.CombatPlugin`

## Project Knowledge Map

- Deploy queue behavior: `.agent/archive/deep-dives/deploy-queue.md`.
  Read before changing `scripts\deploy_mod.ps1`, runtime artifact parity checks, blocked deploy behavior, or `.agent-deploy` handling.
- Initial fork setup history: `.agent/archive/history/2026-05-12-initial-fork-setup.md`.
  Read only when reconstructing why the fork has tracked runtime files, renamed ids, or restored release assets.

## Commands

Build:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_mod.ps1 -StarsectorDirectory 'C:\Games\Starsector'
```

Deploy:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\deploy_mod.ps1 -RepoRoot 'D:\Sean Mods\Flux Reticle Fork' -DeployTarget 'C:\Games\Starsector\mods\Flux Reticle Fork'
```

## Deploy Policy

- Treat this repo as source of truth and the Starsector mod folder as a deploy target.
- Runtime changes must be built and deployed or explicitly queued by `scripts\deploy_mod.ps1`.
- The deploy script is based on the external template at `D:\Sean Mods\agent-deploy-template`; do not edit that external toolkit unless the task is specifically about it.
- Docs-only changes do not require deployment because docs are not mirrored to the live mod folder.
- If Starsector is running, the deploy script should stage artifacts, queue a worker, and supersede only older queued deploys for the same repo root, deploy target, and deploy name. Do not kill Starsector.
- After deploy, verify whether the script completed or queued; queued deploys mean the live folder is not current until Starsector exits and the worker publishes.

## Verification Policy

- Compile success is required for Java changes but is not proof of runtime behavior.
- For Luna/config changes, validate `data\config\LunaSettings.csv` has non-empty unique `fieldID` values and uses mod id `shattersphere_flux_reticle_fork`.
- For rendering or cursor behavior, require an in-game combat check before claiming runtime correctness.
- Validate the deployed artifact when stale live files are plausible.

## Safety

- Do not edit saves, Luna saved settings, game core files, TriOS state, or public releases unless explicitly requested.
- Do not remove tracked runtime files unless Starsector loading and deploy paths are updated with proof.
- Keep commits cohesive and push completed work to `origin/master` for this personal modding repo unless the user says otherwise.
