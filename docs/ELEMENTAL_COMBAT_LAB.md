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
2. Water projectile must read as a moving volume with a tapered silhouette, uneven liquid surface, broken specular highlight and detached droplets—not as straight neon lines.
3. Water impact must form a broad irregular liquid sheet, a few short thick curling splashes, a flattened surface ripple and ballistic droplets. The sheet contour must never fold across itself or emit polygon triangulation errors. Water skill previews should use flowing sheets/streams rather than generic circular energy rings.
4. Verify water remains blue/cyan and translucent without washing out to a white blob. Test both before and after a renderer node enters the scene tree.
5. T/G/Y/U/I/O preview reusable special-skill visual presets. These are presentation-only previews; gameplay damage/collision must be authored separately.
6. Each element creates its own renderer at the resolved hit position.
7. Lightning travels from the resolved cast origin to the impact point; it must not default to a fixed point above the target.
8. Wind pressure rings/gust ribbons, fire flame tongues/embers, and water splash rims/droplets remain visibly distinct and readable at the Balanced preset.
9. Fire applies a burning status and periodic damage.
10. Wind and water impulses differ, and rigid/character bodies receive physics-compatible impulses.
11. Lightning chains only through bounded candidate targets; targets outside chain range are ignored.
12. Shift combinations produce reaction metadata and the corresponding visual cue.
13. Low/Balanced/High changes visual complexity only; damage and status results stay independent of the quality profile.
14. Repeated casts do not cause effect child count to grow without bound.
15. `X` restores all target health and clears timed statuses.

## Verification status

This scene and its smoke-test hook are committed but have not been run in Godot in the current environment. Complete the manual test on desktop, then profile on actual Android landscape hardware.
