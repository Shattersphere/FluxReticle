# Agent Instructions

## Startup

- Start repository-changing work with `git status --short --branch`.
- Read `.agent/INDEX.md` first for doc routing.
- Read `.agent/BRIEF.md` for current state before code, build, deploy, or runtime-work changes.
- Use targeted searches before opening larger docs.

## Project Identity

- Source root: `D:\Sean Mods\Flux Reticle Fork`
- Game: Starsector
- Live deploy target: `C:\Games\Starsector\mods\Flux Reticle Fork`
- Mod id: `shattersphere_flux_reticle_fork`
- Runtime prefix: `shat_fr`
- Main plugin: `flux_reticle.ModPlugin`
- Combat plugin: `flux_reticle.CombatPlugin`

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
- If Starsector is running, the deploy script should queue a worker and supersede older queued deploys. Do not kill Starsector.
- After deploy, verify whether the script completed or queued; queued deploys mean the live folder is not current until Starsector exits.

## Verification Policy

- Compile success is required for Java changes but is not proof of runtime behavior.
- For Luna/config changes, validate `data\config\LunaSettings.csv` has non-empty unique `fieldID` values and uses mod id `shattersphere_flux_reticle_fork`.
- For rendering or cursor behavior, require an in-game combat check before claiming runtime correctness.
- Validate the deployed artifact when stale live files are plausible.

## Safety

- Do not edit saves, Luna saved settings, game core files, TriOS state, or public releases unless explicitly requested.
- Do not remove tracked runtime files unless Starsector loading and deploy paths are updated with proof.
- Keep commits cohesive and push completed work to `origin/master` for this personal modding repo unless the user says otherwise.
