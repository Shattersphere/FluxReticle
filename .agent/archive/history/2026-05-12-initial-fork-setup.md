# Initial fork setup history

Status: historical
Scope: Flux Reticle Fork initial source/runtime setup
Last verified: 2026-05-12
Read when: reconstructing why this repo tracks runtime files, renamed ids/assets, restored release assets, or early validation/risk notes
Do not read for: normal feature work, small bug fixes, or routine deploys
Related files: `mod_info.json`, `FLUX_RETICLE_OPTIONS.ini`, `data/config`, `shat_fr`, `shat_fr.version`, `jars/FluxReticle.jar`
Search tags: setup, fork, runtime-surface, Luna, metadata, graphics, jar, validation, compatibility

## Summary

- The folder was converted from a packaged mod folder into a buildable source fork.
- Runtime files were restored and are intentionally tracked because Starsector loads more than the jar.
- The fork identity was separated from upstream Flux Reticle for TriOS and Starsector mod loading.
- Luna/INI customization was expanded for geometry, flashing, point-blank visibility, and RGBA color control.
- Early build validation resolved Starsector core jars and LunaLib from the local install, with only compiler warnings.
- Existing saved Luna settings from the upstream-style fields may not migrate cleanly to the fork's renamed `shat_fr_` fields.

## Details

Completed setup and implementation work:

- Cloned upstream Flux Reticle source into this repo.
- Restored the complete installable runtime surface:
  - `mod_info.json`
  - `FLUX_RETICLE_OPTIONS.ini`
  - `data/config`
  - `shat_fr/graphics`
  - `shat_fr.version`
  - `jars/FluxReticle.jar`
- Renamed the fork identity to `Flux Reticle Fork` / `shattersphere_flux_reticle_fork`.
- Added Luna/INI controls for bar width, min/max length, min/max distance, point-blank visibility, high-flux flashing, and RGBA color controls.
- Split rendering paths for soft flux, hard flux, divider, and background color.
- Removed the old upstream UI-color override gate so configured colors apply directly.
- Added build and deploy scripts with live hash validation and queued deploy behavior.
- Removed stale upstream shortcut files from the tracked runtime surface.

Recovered validation and risk notes from the retired root docs:

- The initial validated build used `scripts/build_mod.ps1 -StarsectorDirectory 'C:\Games\Starsector'`.
- That build resolved Starsector core jars from `C:\Games\Starsector\starsector-core` and LunaLib from `C:\Games\Starsector\mods\LunaLib-2.0.5`.
- The build warnings were limited to Java 8 bootstrap/deprecation/unchecked-operation warnings; the produced jar was readable as a zip.
- The combat sweep hardened null script removal, missing/corrupt common-data recovery, per-combat error-latch reset, and OpenGL matrix isolation around gauge drawing.
- The old upstream UI-color override gate was removed so the fork's RGBA settings apply directly.
- Users with saved Luna settings from older/upstream-style fields may see the renamed fork settings fall back to defaults until they configure the new `shat_fr_` fields.
- Distance settings were implemented as normalized values against half the visible screen height; point-blank behavior still needs in-game feel validation.
- `keepBarVisibleAtMinimumDistance` was intentionally defaulted on so the bar remains visible at minimum length at point blank.
- The hard/soft divider has a separate color path, but still uses the existing `hardBar` sprite.

## Evidence / provenance

- Runtime/source split and source restoration happened during the initial fork setup on 2026-05-11 and 2026-05-12.
