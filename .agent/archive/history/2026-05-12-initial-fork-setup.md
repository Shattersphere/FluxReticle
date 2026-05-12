# Initial fork setup history

Status: historical
Scope: Flux Reticle Fork initial source/runtime setup
Last verified: 2026-05-12
Read when: reconstructing why this repo tracks runtime files, renamed ids/assets, or restored release assets
Do not read for: normal feature work, small bug fixes, or routine deploys
Related files: `mod_info.json`, `FLUX_RETICLE_OPTIONS.ini`, `data/config`, `shat_fr`, `shat_fr.version`, `jars/FluxReticle.jar`
Search tags: setup, fork, runtime-surface, Luna, metadata, graphics, jar

## Summary

- The folder was converted from a packaged mod folder into a buildable source fork.
- Runtime files were restored and are intentionally tracked because Starsector loads more than the jar.
- The fork identity was separated from upstream Flux Reticle for TriOS and Starsector mod loading.
- Luna/INI customization was expanded for geometry, flashing, point-blank visibility, and RGBA color control.

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

## Evidence / provenance

- Runtime/source split and source restoration happened during the initial fork setup on 2026-05-11 and 2026-05-12.
