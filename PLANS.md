# Flux Reticle Fork Plans

Read `.agent/BRIEF.md` first. This file is for active work and blocked items, not completed history.

## Active Work

- Run an in-game combat check after the latest rendering/settings changes:
  - reticle appears and hides the native cursor correctly
  - cursor resets after escape menu, command UI, combat end, and campaign return
  - soft flux, hard flux, divider, and background colors render distinctly
  - LunaLib settings load without parser errors
  - size/distance settings behave sensibly at different zoom levels
  - `keepBarVisibleAtMinimumDistance` keeps the bar visible at point blank range
  - flash thresholds and frequencies respond visibly

## Decisions Needed

- Decide whether this stays a private source fork or becomes a distributable renamed fork.
- If distributable, audit `mod_info.json`, `shat_fr.version`, download/source/changelog URLs, author/version text, and release packaging.

## Maintenance Rules

- Keep `README.md` user-facing and concise.
- Keep `.agent/BRIEF.md` compact and current for normal handoff.
- Keep `HANDOVER.md` for stable project facts and validation commands.
- Keep `PLANS.md` for active work and blocked items only.
- Move completed history to `.agent/archive/`.
- Do not remove tracked runtime files (`jars\FluxReticle.jar`, `data\config`, `shat_fr`, `mod_info.json`, `shat_fr.version`) unless the deploy script and Starsector loading path are updated with proof.
- For rendering behavior changes, compile/deploy checks are necessary but not sufficient; require an in-game combat check.
