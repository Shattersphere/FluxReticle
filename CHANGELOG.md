# Changelog

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
