# Active Brief

## Current State

Flux Reticle Fork is a buildable and deployable Starsector mod fork with a separate in-game identity:

- Mod id: `shattersphere_flux_reticle_fork`
- Display name: `Flux Reticle Fork`
- Runtime prefix: `shat_fr`
- Source root: `D:\Sean Mods\Flux Reticle Fork`
- Live target: `C:\Games\Starsector\mods\Flux Reticle Fork`

The fork adds Luna/INI customization for reticle geometry, point-blank bar visibility, RGBA colors, and high-flux flashing. The old upstream UI-color override gate is removed, so configured RGBA values apply directly.

Last runtime code commit pushed before this doc restructure: `8bf11b4`.

## Commands

Build:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_mod.ps1 -StarsectorDirectory 'C:\Games\Starsector'
```

Deploy:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\deploy_mod.ps1 -RepoRoot 'D:\Sean Mods\Flux Reticle Fork' -DeployTarget 'C:\Games\Starsector\mods\Flux Reticle Fork'
```

## Current Blockers

- Runtime rendering still needs an in-game combat check after recent rendering/settings changes.
- If Starsector is running, deploy queues a background worker; verify deploy state before assuming the live folder is current.

## Risk Areas

- Starsector combat rendering and cursor reset behavior require runtime validation.
- Luna field IDs must keep the `shat_fr_` prefix and mod id `shattersphere_flux_reticle_fork`.
- `jars\FluxReticle.jar` is a tracked runtime artifact and must stay in sync with source changes.

## Next Best Step

Run an in-game combat check once the queued deploy has published or after manually running deploy with Starsector closed.
