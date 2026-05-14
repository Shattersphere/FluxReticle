# Flux Reticle Fork Handover

Read `.agent/BRIEF.md` first for current active state. This file keeps stable project facts and command references.

## Stable Context

This repo is a working Starsector mod fork, not just source notes. Keep runtime files and source aligned:

- Source root: `D:\Sean Mods\Flux Reticle Fork`
- Live target: `C:\Games\Starsector\mods\Flux Reticle Fork`
- Deploy staging/state: `.agent-deploy\`
- Mod id: `shattersphere_flux_reticle_fork`
- Runtime prefix: `shat_fr`
- Built jar: `jars\FluxReticle.jar`
- Eventual public organization: `https://github.com/Shattersphere-Mods`
- Public release checklist: `.agent/PUBLIC_RELEASE.md`

## Ownership Map

- `src/flux_reticle/CombatPlugin.java`: reticle rendering, cursor hiding/reset, input handling, Luna/INI setting reads, top/front reticle offset, soft/hard/divider drawing, and minimum-distance visibility behavior.
- `FLUX_RETICLE_OPTIONS.ini`: non-Luna fallback settings. Add new runtime settings here whenever Luna gets a matching field.
- `data/config/LunaSettings.csv`: LunaLib settings. Field IDs must use `shat_fr_`.
- `scripts/build_mod.ps1`: compiles Java against Starsector and LunaLib.
- `scripts/deploy_mod.ps1`: rebuilds, stages, deploys, removes retired upstream files, and checks live hash parity.
- `.agent/archive/deep-dives/deploy-queue.md`: deploy queue behavior and parity details.
- `README.md`: user-facing overview. Keep agent workflow details here in `HANDOVER.md` or `PLANS.md`.
- `CHANGELOG.md`: public-facing release history. Do not add private workflow details, local paths, or agent-only notes.
- `.agent/PUBLIC_RELEASE.md`: private include/exclude checklist and public export guidance.

## Current Behavior Notes

- The fork uses separate integer RGBA Luna settings; the old upstream color override gate is intentionally gone.
- Saved Luna settings from upstream or earlier fork fields may not migrate to the renamed `shat_fr_` fields; verify resolved settings in game when colors or sizes appear unchanged.
- `reticleTopOffset` shifts the rendered top/front of the reticle along the ship-to-cursor line without changing the actual mouse aim point.
- Distance settings are normalized to half the visible screen height.
- `enableFluxChangeFlash` controls only the extra flux-change pulse; threshold-based flashing still follows the flash threshold/frequency settings.
- `keepBarVisibleAtMinimumDistance` defaults on and prevents the flux bar from fading out at point blank range.
- The hard/soft divider still uses the `hardBar` sprite, but its color is controlled separately.
- Combat rendering still needs in-game confirmation after UI-facing changes; build success is not enough.

## Public Release Notes

- Public repos/packages should be curated outputs, not automatic mirrors of this private repo.
- Do not publish or update public version/download URLs without an explicit release-prep or publication request.
- `.agent/`, `AGENTS.md`, `HANDOVER.md`, `PLANS.md`, `.agent-deploy/`, local paths, and private notes must be excluded from public outputs.
- `mod_info.json`, `shat_fr.version`, `README.md`, and `CHANGELOG.md` are the main public version/metadata surfaces.

## Validation

For code changes:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_mod.ps1 -StarsectorDirectory 'C:\Games\Starsector'
```

For deploy:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\deploy_mod.ps1 -RepoRoot 'D:\Sean Mods\Flux Reticle Fork' -DeployTarget 'C:\Games\Starsector\mods\Flux Reticle Fork'
```

For Luna/settings changes, import `data/config/LunaSettings.csv` and check for empty or duplicate `fieldID` values.

If Starsector is running, deploy queues a worker instead of forcing file replacement. Verify queued deploys before assuming the live folder is current.
