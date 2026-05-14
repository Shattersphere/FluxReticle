# Flux Reticle Fork Plans

Read `.agent/BRIEF.md` first. This file is for active work and blocked items, not completed history.

## Current Goal

Validate the customized reticle in game and keep repo/runtime deployment evidence accurate while preparing the private repo for eventual curated public release under `Shattersphere-Mods`.

## Acceptance Criteria

- Latest runtime files are either deployed with parity checks or explicitly queued by `scripts\deploy_mod.ps1`.
- Luna settings load under mod id `shattersphere_flux_reticle_fork`.
- In combat, custom reticle, soft flux, hard flux, divider, background, size/distance, and flash settings are visibly honored.
- The flux bar background border follows the reticle color and can be disabled with border width `0`.
- Soft/hard flux fill inset leaves the border visible without changing the background or border position.
- Reticle top/front offset visibly moves only the front cursor graphic and glow without changing the bar anchor or actual mouse aim point.
- Reticle top/front lateral offset visibly moves only the front cursor graphic and glow left/right relative to the bar.
- Reticle body lateral offset visibly moves the flux bar body and lower sprites left/right separately from the top/front graphic.
- Reticle top/front scale visibly resizes only the front cursor graphic and glow as a multiplier of the regular sprite size.
- Quarter/half sprite swapping visibly exchanges the sprites used at the 25%/75% and 50% bar marks.
- Soft/hard flux fills render under the marker sprites and hard-flux divider, not over them.
- Sprite-set selection can switch between bundled vanilla, 4x, 8x, and AI-generated 8x sprite folders while keeping logical in-game size stable.
- Disabling flux-change flashing suppresses the extra warning pulse when soft flux changes rapidly while leaving threshold flashing available.
- Cursor hiding/reset behavior remains correct after combat UI transitions.
- Public-facing changelog and private public-release checklist exist and stay aligned with version/release work.
- Public export excludes private docs, local paths, deploy state, and agent-only files.

## Active Work

- Run an in-game combat check after the latest rendering/settings changes:
  - reticle appears and hides the native cursor correctly
  - cursor resets after escape menu, command UI, combat end, and campaign return
  - soft flux, hard flux, divider, and background colors render distinctly
  - LunaLib settings load without parser errors
  - reticle top/front offset moves only the front cursor graphic and glow along the ship-to-cursor line
  - sprite-set selector swaps between bundled art sets and keeps the same in-game logical size
  - size/distance settings behave sensibly at different zoom levels
  - `keepBarVisibleAtMinimumDistance` keeps the bar visible at point blank range
  - flash thresholds and frequencies respond visibly
  - disabling flux-change flash stops rapid soft-flux changes from producing a warning pulse
- Before public release prep:
  - choose the public repo name under `Shattersphere-Mods`
  - update public release URLs only when that public repo exists
  - verify license/redistribution status
  - run the `.agent/PUBLIC_RELEASE.md` leak scan

## Decisions Needed

- Decide the final public repo name under `Shattersphere-Mods`.
- Decide whether the public source repo should track `jars/FluxReticle.jar` or publish jars only in release packages.
- Confirm license and upstream attribution before public release.
- Audit `mod_info.json`, `shat_fr.version`, download/source/changelog URLs, author/version text, and release packaging before publication.

## Maintenance Rules

- Keep `README.md` user-facing and concise.
- Keep `CHANGELOG.md` public-facing and free of private workflow details, local paths, and agent-only notes.
- Keep `.agent/PUBLIC_RELEASE.md` private and update it when public export rules or release metadata surfaces change.
- Keep `.agent/BRIEF.md` compact and current for normal handoff.
- Keep `HANDOVER.md` for stable project facts and validation commands.
- Keep `PLANS.md` for active work and blocked items only.
- Move completed history to `.agent/archive/`.
- Do not remove tracked runtime files (`jars\FluxReticle.jar`, `data\config`, `shat_fr`, `mod_info.json`, `shat_fr.version`) unless the deploy script and Starsector loading path are updated with proof.
- For rendering behavior changes, compile/deploy checks are necessary but not sufficient; require an in-game combat check.
