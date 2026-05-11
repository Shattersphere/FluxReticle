# Flux Reticle Fork Plans

## Active goals

- Make the flux bar width configurable.
- Make reticle bar minimum length, maximum length, minimum-distance point, and maximum-distance point configurable.
- Make point-blank flux-bar visibility configurable so the bar can stop at minimum length instead of fading out.
- Keep the flux bar background color configurable.
- Use LunaLib integer RGBA controls instead of hex color controls for all relevant colors.
- Make high-flux flashing configurable by start threshold, maximum threshold, start frequency, and maximum frequency.
- Render and customize soft flux fill, hard flux fill, and the hard/soft divider separately.

## Completed in this fork

- Restored the installable mod surface around the upstream source tree:
  - `mod_info.json`
  - `FLUX_RETICLE_OPTIONS.ini`
  - `data/config`
  - `shat_fr/graphics`
  - `jars/FluxReticle.jar`
- Added configurable geometry settings:
  - `fluxBarWidth`
  - `minReticleLength`
  - `maxReticleLength`
  - `minReticleDistance`
  - `maxReticleDistance`
  - `keepBarVisibleAtMinimumDistance`
- Added configurable high-flux flash settings:
  - `flashStartThreshold`
  - `flashMaxThreshold`
  - `flashStartFrequency`
  - `flashMaxFrequency`
- Replaced LunaLib hex color rows with explicit integer RGBA rows.
- Removed the old upstream UI-color override gate so configured RGBA values are always used.
- Removed the old blank LunaLib spacer row pattern.
- Split flux-bar rendering into separate soft flux, hard flux, and divider color paths.
- Added `scripts/build_mod.ps1` as the contributor-facing local build task.
- Renamed the fork's Starsector identity to `Flux Reticle Fork` with mod id `shattersphere_flux_reticle_fork` so TriOS treats it separately from upstream Flux Reticle.
- Replaced the ad hoc deploy script with the Lessons deploy-template pattern so blocked deploys queue in the background and newer deploys supersede older pending ones.
- Fixed sweep findings in combat/plugin lifecycle handling: null script removal, missing/corrupt common-data recovery, per-combat error latch reset, and matrix isolation for gauge drawing.

## Remaining work

- Verify the affected combat flow in game:
  - reticle appears and hides the native cursor correctly
  - cursor resets after escape menu, command UI, combat end, and campaign return
  - soft flux, hard flux, divider, and background colors render distinctly
  - LunaLib RGBA settings load without parser errors
  - size and distance settings behave intuitively at different zoom levels
  - flash thresholds and frequencies respond visibly
- Decide whether this is a private source fork or a renamed distributable fork.
- If it becomes distributable, audit and update release metadata:
  - `mod_info.json`
  - `shat_fr.version`
  - `jars/src.url`
  - download/source/changelog URLs
  - mod name, author, version, and possibly mod id

## Validation cadence

- For source changes, run:
  - `powershell -ExecutionPolicy Bypass -File scripts/build_mod.ps1 -StarsectorDirectory <path>`
- After any runtime change, deploy to the live mod folder:
  - `powershell -ExecutionPolicy Bypass -File scripts/deploy_mod.ps1 -StarsectorDirectory <path>`
- For Luna/settings changes, import `data/config/LunaSettings.csv` and confirm every row has a non-empty `fieldID`.
- For user-facing rendering changes, compile success is not enough; open combat in game and test the exact reticle behavior.
