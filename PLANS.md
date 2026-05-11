# Flux Reticle Fork Plans

## Done

- Restored a complete installable mod surface: metadata, fallback settings, Luna config, graphics, sounds, version file, and tracked runtime jar.
- Renamed the fork identity to `Flux Reticle Fork` / `shattersphere_flux_reticle_fork`.
- Added Luna/INI controls for bar width, min/max length, min/max distance, and point-blank visibility.
- Added Luna/INI controls for high-flux flashing.
- Replaced hex color controls with explicit integer RGBA fields.
- Split rendering paths for soft flux, hard flux, divider, and background color.
- Removed the old upstream UI-color override gate so configured colors apply directly.
- Added build and deploy scripts with live hash validation and queued deploy behavior.
- Consolidated user-facing docs into `README.md` and kept agent-facing state here plus `HANDOVER.md`.
- Removed stale upstream shortcut files: `Change Log.url` and `jars/src.url`.

## Open Work

- Run an in-game combat check after the latest rendering/settings changes:
  - reticle appears and hides the native cursor correctly
  - cursor resets after escape menu, command UI, combat end, and campaign return
  - soft flux, hard flux, divider, and background colors render distinctly
  - LunaLib settings load without parser errors
  - size/distance settings behave sensibly at different zoom levels
  - `keepBarVisibleAtMinimumDistance` keeps the bar visible at point blank range
  - flash thresholds and frequencies respond visibly
- Decide whether this stays a private source fork or becomes a distributable renamed fork.
- If distributable, audit `mod_info.json`, `shat_fr.version`, download/source/changelog URLs, author/version text, and release packaging.

## Maintenance Rules

- Keep `README.md` user-facing and concise.
- Keep `HANDOVER.md` for current agent context and validation commands.
- Keep `PLANS.md` for completed/current/future work; do not let it become a full changelog.
- Do not remove tracked runtime files (`jars\FluxReticle.jar`, `data\config`, `shat_fr`, `mod_info.json`, `shat_fr.version`) unless the deploy script and Starsector loading path are updated with proof.
- For rendering behavior changes, compile/deploy checks are necessary but not sufficient; require an in-game combat check.
