# Initial Fork Setup History

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
