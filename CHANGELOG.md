# Changelog

## 1.19.0-fork.1 - 2026-05-15

- Added configurable system and shield state indicators with LunaLib position offsets and separate RGBA colours.
- Added a LunaLib toggle for hiding the shield indicator.

## 1.18.0-fork.1 - 2026-05-15

- Added front sprite variant choices through `wings_100pct_further_apart`.

## 1.17.1-fork.1 - 2026-05-15

- Fixed the hard and soft flux top divider markers so they render at full configured opacity whenever their flux segment exists.

## 1.17.0-fork.1 - 2026-05-15

- Updated the front sprite variant selector for the flat `front_variants` folder layout and added wing-gap variants through `wings_50pct_further_apart`.

## 1.16.0-fork.1 - 2026-05-15

- Added a LunaLib front sprite variant selector for bundled wing-gap `frontKeyTurn` and `frontMouseTurn` folders.

## 1.15.1-fork.1 - 2026-05-15

- Fixed a LunaLib settings crash caused by percent signs in the bar marker setting description.

## 1.15.0-fork.1 - 2026-05-15

- Added an option to hide the 25%, 50%, and 75% flux bar marker sprites while keeping the end cap visible.
- Fixed hard/soft divider height scaling so it adjusts the divider's visual thickness instead of its length.

## 1.14.0-fork.1 - 2026-05-15

- Added an optional soft-flux top divider that uses the same styling as the hard/soft boundary divider.
- Fixed the marker sprite option so it uses the half sprite for the quarter, middle, and three-quarter bar markers instead of swapping the middle marker to the quarter sprite.

## 1.13.0-fork.1 - 2026-05-15

- Added a LunaLib setting for scaling the hard/soft flux divider height without changing its position.

## 1.12.0-fork.1 - 2026-05-15

- Added a LunaLib setting for insetting soft and hard flux fills so the flux bar border stays visible.

## 1.11.1-fork.1 - 2026-05-15

- Fixed soft and hard flux fills rendering above or tinting the quarter and half reticle bar sprites.

## 1.11.0-fork.1 - 2026-05-15

- Added a LunaLib setting for swapping the quarter and half reticle bar sprites.

## 1.10.0-fork.1 - 2026-05-15

- Added a LunaLib setting for shifting the front reticle graphic and glow left or right relative to the flux bar.
- Added a separate LunaLib setting for shifting the flux bar body left or right.

## 1.9.0-fork.1 - 2026-05-15

- Added a LunaLib setting for drawing a reticle-colored border around the flux bar background.

## 1.8.0-fork.1 - 2026-05-15

- Added a LunaLib setting for independently scaling the front reticle graphic and glow relative to the main reticle sprite size.

## 1.7.1-fork.1 - 2026-05-15

- Added the AI-generated full 8x reticle art set to the LunaLib sprite-set selector.

## 1.7.0-fork.1 - 2026-05-15

- Added a LunaLib sprite-set selector for bundled vanilla, 4x, and 8x reticle art.
- Defaulted the reticle art to the 8x nearest edge-cleaned set.

## 1.6.1-fork.1 - 2026-05-15

- Fixed high-resolution reticle sprites rendering larger than the original logical sprite sizes.
- Changed the reticle top offset to move only the front cursor graphic and glow, leaving the flux bar anchored.

## 1.6.0-fork.1 - 2026-05-15

- Added an option to disable the extra warning flash pulse caused by rapid flux changes.

## 1.5.0-fork.1 - 2026-05-15

- Added a LunaLib and fallback setting for moving the reticle top/front along the ship-to-cursor line.

## 1.4.0-fork.1 - 2026-05-12

- Renamed the mod as `Flux Reticle Fork` with a separate Starsector mod id.
- Added LunaLib and fallback settings for flux bar width, reticle length, distance scaling, and point-blank bar visibility.
- Added separate RGBA controls for reticle, soft flux, hard flux, hard/soft divider, warning flash, and background colors.
- Added configurable high-flux flashing thresholds and flash frequencies.
- Improved cursor reset and combat plugin cleanup around combat UI transitions.
- Added source build and runtime deployment scripts for local testing.
