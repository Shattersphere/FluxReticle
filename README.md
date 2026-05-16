# Flux Reticle Fork

Fork of Flux Reticle with a separate Starsector identity and LunaLib-facing customization for reticle geometry, flux-bar colors, high-flux flashing, and point-blank bar visibility.

## Runtime Identity

- Mod id: `shattersphere_flux_reticle_fork`
- Display name: `Flux Reticle Fork`
- Runtime prefix: `shat_fr`
- Main plugin: `flux_reticle.ModPlugin`
- Combat renderer/input plugin: `flux_reticle.CombatPlugin`

## Key Files

- `CHANGELOG.md`: public-facing release history.
- `src/flux_reticle/CombatPlugin.java`: combat input, cursor hiding/reset, reticle rendering, settings reads, soft/hard/divider gauge drawing, and minimum-distance bar visibility handling.
- `FLUX_RETICLE_OPTIONS.ini`: fallback settings when LunaLib is not enabled.
- `data/config/LunaSettings.csv`: LunaLib settings surface.
- `shat_fr/graphics/`: reticle sprite assets.
- `jars/FluxReticle.jar`: rebuilt runtime jar tracked for Starsector loading.
- `scripts/build_mod.ps1`: compiles Java sources against Starsector and LunaLib.
- `scripts/deploy_mod.ps1`: builds, stages, deploys to the live mod folder, and verifies live file hashes.

## Current Features

- Configurable flux bar width and min/max bar length.
- Configurable reticle-colored border around the flux bar background.
- Configurable soft/hard flux fill inset so the border stays visible when the bar fills.
- Configurable hard/soft flux divider visual height/thickness.
- Configurable front cursor graphic scale plus separate top and flux-bar-body left/right offsets.
- Ship-system cooldown marker anchored at a fixed reticle-local offset from the top of the flux bar, with configurable fade, position, ring shape, charge-count text, alpha, and RGBA state colors.
- Optional 25%, 50%, and 75% bar marker sprites.
- Option to use the half bar marker sprite at the quarter, middle, and three-quarter positions.
- Optional soft-flux top divider using the same divider styling as the hard/soft boundary.
- LunaLib sprite-set selector for the bundled vanilla, 4x, 8x, and AI-generated 8x reticle art sets.
- LunaLib front sprite variant selector for bundled wing-gap frontKeyTurn/frontMouseTurn folders from `wings_05pct_further_apart` through `wings_100pct_further_apart`.
- LunaLib settings are split into focused tabs for general controls, reticle art, flux bar geometry, system marker controls, flashing, and colours.
- Configurable min/max cursor distance for bar scaling.
- `keepBarVisibleAtMinimumDistance`: keeps the bar visible at minimum length at point blank range instead of fading out.
- Separate RGBA settings for reticle, soft flux, hard flux, hard/soft divider, warning flash, and background.
- Configurable high-flux flash thresholds and frequency.
- Optional flux-change flash pulse, separate from threshold-based high-flux flashing.
- Cursor reset handling for combat end, command UI, escape menu, and campaign return.

## Build

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_mod.ps1 -StarsectorDirectory '<Starsector install path>'
```

The build script resolves:

- Starsector core jars from `starsector-core`
- LunaLib from the installed `lunalib` mod
- Output jar at `jars\FluxReticle.jar`

Expected compiler warnings are Java 8 bootstrap/deprecation/unchecked warnings from the Starsector modding toolchain.

## Deploy

```powershell
powershell -ExecutionPolicy Bypass -File scripts\deploy_mod.ps1 -RepoRoot '<repo path>' -DeployTarget '<Starsector mods path>\Flux Reticle Fork'
```

The deploy script rebuilds by default, validates `LunaSettings.csv`, stages the runtime files, copies them to the live mod folder, removes retired upstream shortcut files, and checks source/live hash parity. If Starsector is running, it queues a background worker rather than killing or overwriting the running game.

## Runtime Checks

After rendering changes, compile success is not enough. Test an in-game combat and verify:

- The reticle appears and hides the native cursor correctly.
- The cursor resets after escape menu, command UI, combat end, and campaign return.
- Soft flux, hard flux, divider, and background colors render distinctly.
- LunaLib settings load without parser errors.
- Size and distance settings behave sensibly at different zoom levels.
- `keepBarVisibleAtMinimumDistance` keeps the bar visible at minimum length near the ship.
- Flash thresholds and frequencies respond visibly.
- The ship-system marker stays to the same local side of the top of the flux bar when the cursor points above, below, left, or right of the ship.

## Notes

- Distance settings are normalized to half the visible screen height, matching the original Flux Reticle distance formula.
- LunaLib color settings use separate integer RGBA controls, not the old hex-color fields.
- The old upstream UI-color override gate is intentionally gone; configured RGBA values apply directly.
