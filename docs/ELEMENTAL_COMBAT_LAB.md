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
- `T` — preview fire tornado at the pointer
- `G` — preview fire burst at the pointer
- `Y` — preview water jet burst at the pointer
- `U` — preview water torrent at the pointer
- `I` — preview wind cyclone at the pointer
- `O` — preview wind blade storm at the pointer

The lab uses test combatants and passes them as collision candidates to the world adapter. A production game must replace this demonstration selection with its actual raycast/overlap/projectile collision query.

## What to verify

1. Fire travels as a flame projectile, water as a pressurized water shot, and wind as a crescent sword-like slash; impact plays when the visual projectile arrives. Lightning remains a fast directional strike.
2. Water uses controlled alpha blending so its blue body, cyan edge and white highlight stay readable instead of overexposing into a white/neon streak.
3. Water impact forms smooth curved crown jets, separated droplets and staggered ripples; it should not show angular three-point kinks.
4. T/G/Y/U/I/O preview reusable special-skill visual presets. These are presentation-only previews; gameplay damage/collision must be authored separately.
5. Each element creates its own renderer at the resolved hit position.
6. Lightning travels from the resolved cast origin to the impact point; it must not default to a fixed point above the target.
7. Wind pressure rings/gust ribbons, fire flame tongues/embers, and water splash rims/droplets remain visibly distinct and readable at the Balanced preset.
8. Fire applies a burning status and periodic damage.
9. Wind and water impulses differ, and rigid/character bodies receive physics-compatible impulses.
10. Lightning chains only through bounded candidate targets; targets outside chain range are ignored.
11. Shift combinations produce reaction metadata and the corresponding visual cue.
12. Low/Balanced/High changes visual complexity only; damage and status results stay independent of the quality profile.
13. Repeated casts do not cause effect child count to grow without bound.
14. `X` restores all target health and clears timed statuses.

## Verification status

This scene and its smoke-test hook are committed but have not been run in Godot in the current environment. Complete the manual test on desktop, then profile on actual Android landscape hardware.
