# Flux Reticle Fork Handover

## Current state

The folder is now a git clone of the upstream Flux Reticle source with the packaged runtime files restored from the upstream release zip. The fork currently builds locally with `scripts/build_mod.ps1`, writes a fresh `jars/FluxReticle.jar`, and deploys to the live Starsector mod folder with `scripts/deploy_mod.ps1`.

The in-game mod identity is now separate from upstream Flux Reticle:

- Name: `Flux Reticle Fork`
- Mod id: `shattersphere_flux_reticle_fork`
- Runtime asset/settings prefix: `shat_fr`

The main implementation work for the requested customization goals is present in `src/flux_reticle/CombatPlugin.java`.

## Important files

- `src/flux_reticle/CombatPlugin.java`: combat input, cursor hiding/reset, reticle rendering, settings reads, soft/hard/divider gauge drawing.
- `FLUX_RETICLE_OPTIONS.ini`: fallback settings used when LunaLib is not enabled.
- `data/config/LunaSettings.csv`: LunaLib settings surface. Colors are exposed as separate integer RGBA rows.
- `scripts/build_mod.ps1`: local build task. It resolves Starsector from `-StarsectorDirectory`, `STARSECTOR_DIRECTORY`, or untracked `local.properties`.
- `scripts/deploy_mod.ps1`: rebuilds by default, clean-syncs repo-managed runtime files to the live mod folder, and checks source/live hash parity for important files.
- `jars/FluxReticle.jar`: rebuilt runtime jar.

## Build notes

Validated command:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_mod.ps1 -StarsectorDirectory 'C:\Games\Starsector'
```

The script resolved:

- Starsector core jars from `C:\Games\Starsector\starsector-core`
- LunaLib from `C:\Games\Starsector\mods\LunaLib-2.0.5`

The build completed and validated the jar as a readable zip. `javac` emitted only normal warnings about Java 8 bootstrap path, deprecated API usage, and unchecked operations.

Validated deploy command:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\deploy_mod.ps1 -StarsectorDirectory 'C:\Games\Starsector'
```

The expected live target is `C:\Games\Starsector\mods\Flux Reticle Fork`.

## Runtime risks

- Combat rendering has not yet been verified in game after the gauge split or fork identity rename.
- LunaLib settings have been structurally changed from old `Color` plus opacity fields to integer RGBA fields; existing user LunaLib saved settings may need to fall back to defaults for renamed fields.
- Distance settings are normalized to half the visible screen height because that matches the original reticle distance formula. The Luna descriptions say this, but in-game feel still needs testing.
- The hard flux divider still uses the existing `hardBar` sprite. Only its color path is newly separated.

## Next best task

Run an in-game combat check focused on TriOS identity, Luna settings loading, reticle geometry, split soft/hard rendering, and cursor reset behavior.
