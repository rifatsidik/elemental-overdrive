# Elemental Combat Lab

## Open

Open `scenes/elemental_combat_lab.tscn` in Godot 4.7.x and run the current scene (F6). This scene is an integration harness; it does not replace the default visual Engine Lab.

## Controls

- `Q` — lightning
- `W` — wind
- `E` — fire
- `R` — water
- Click/tap close to a live target — execute the selected ability
- Shift + click — combine the selected element with the previous cast element
- `0` — adaptive quality
- `1` — Low
- `2` — Balanced
- `3` — High
- `X` — reset target health and statuses

The lab uses test combatants and passes them as collision candidates to the world adapter. A production game must replace this demonstration selection with its actual raycast/overlap/projectile collision query.

## What to verify

1. Each element creates its own renderer at the resolved hit position.
2. Lightning travels from the resolved cast origin to the impact point; it must not default to a fixed point above the target.
3. Wind pressure rings/gust ribbons, fire flame tongues/embers, and water splash rims/droplets should remain visibly distinct and readable at the Balanced preset.
4. Fire applies a burning status and periodic damage.
5. Wind and water impulses differ, and rigid/character bodies receive physics-compatible impulses.
6. Lightning chains only through bounded candidate targets; targets outside chain range are ignored.
7. Shift combinations produce reaction metadata and the corresponding visual cue.
8. Low/Balanced/High changes visual complexity only; damage and status results stay independent of the quality profile.
9. Repeated casts do not cause effect child count to grow without bound.
10. `X` restores all target health and clears timed statuses.

## Verification status

This scene and its smoke-test hook are committed but have not been run in Godot in the current environment. Complete the manual test on desktop, then profile on actual Android landscape hardware.
