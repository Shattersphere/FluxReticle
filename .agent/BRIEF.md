# Active Brief

## Current State

Flux Reticle Fork is a buildable and deployable Starsector mod fork with a separate in-game identity:

- Mod id: `shattersphere_flux_reticle_fork`
- Display name: `Flux Reticle Fork`
- Runtime prefix: `shat_fr`
- Source root: `D:\Sean Mods\Flux Reticle Fork`
- Live target: `C:\Games\Starsector\mods\Flux Reticle Fork`
- Deploy staging/state: `.agent-deploy\`
- Deploy name: `flux-reticle-fork-deploy`
- Eventual public organization: `https://github.com/Shattersphere-Mods`

The fork adds Luna/INI customization for reticle geometry, flux bar background border, sprite-set selection including bundled AI-generated 8x art, quarter/half sprite swapping, front cursor graphic scale, separate top/body lateral offsets, point-blank bar visibility, RGBA colors, high-flux flashing, and the separate flux-change flash pulse. The old upstream UI-color override gate is removed, so configured RGBA values apply directly.

## Known-Good Baseline

- Latest runtime code baseline: sprite-set selector including the AI-generated full 8x set, quarter/half sprite swapping, flux bar background border, front cursor graphic scale, separate top/body lateral offsets, fixed logical sprite sizing for high-res assets, and flux-change flash toggle.
- Latest deploy state observed in this pass: `waiting` for target `C:\Games\Starsector\mods\Flux Reticle Fork` after staging run `8a8a34b7-4036-4c13-a0cf-81b34e0b0e0f`.
- Last known-good build command: `powershell -ExecutionPolicy Bypass -File scripts\build_mod.ps1 -StarsectorDirectory 'C:\Games\Starsector'`.
- Runtime behavior remains not in-game verified after recent rendering/settings changes.

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
- Docs-only changes do not require deploy because docs are not part of the live mod surface.
- Public release/export is not automatic; use `.agent/PUBLIC_RELEASE.md` before preparing anything for `Shattersphere-Mods`.

## Risk Areas

- Starsector combat rendering and cursor reset behavior require runtime validation.
- Luna field IDs must keep the `shat_fr_` prefix and mod id `shattersphere_flux_reticle_fork`.
- Existing saved Luna values from upstream or earlier fork field names may not affect the renamed `shat_fr_` settings.
- `jars\FluxReticle.jar` is a tracked runtime artifact and must stay in sync with source changes.
- Public-facing `CHANGELOG.md` must not include local paths, agent/private-doc details, or internal handoff notes.

## Next Best Step

Run an in-game combat check against the current live deploy.

## Deeper Docs

- Repo rules and deploy policy: `AGENTS.md`
- Doc map: `.agent/INDEX.md`
- Archive map: `.agent/archive/INDEX.md`
- Deploy queue details: `.agent/archive/deep-dives/deploy-queue.md`
- Public release checklist: `.agent/PUBLIC_RELEASE.md`
