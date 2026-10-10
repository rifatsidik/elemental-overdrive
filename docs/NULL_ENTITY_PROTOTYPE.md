# NULL//ENTITY — Prototype 01

A playable glyph-based arena-survivor prototype built into the existing Godot 4.7.x project. It is isolated in its own scene and script so the current default scene remains unchanged.

## Open and run

1. Open this repository in Godot 4.7.x.
2. Open `res://scenes/null_entity_lab.tscn`.
3. Run the current scene (F6).

The project default scene has intentionally not been changed.

## Controls

- **WASD / arrow keys:** move the entity.
- **R:** restart after defeat.
- **Esc:** quit.

Attacks fire automatically at the nearest enemy. Defeated enemies emit glyph fragments. Deaths can trigger bounded chain lightning against up to two nearby enemies. Defeating enemies grants evolution progress and increases attack strength. Enemy types include triangular Glyph Drones, rotating Orbit Wisps, fast Rune Shards, and heavier Symbol Cuboids.

## Design

- 2D side-view arena with black background and monochrome glyph structures.
- Color reserved for enemy identities and energy effects.
- Player is an abstract energy core with rotating glyph orbitals, not a humanoid.
- Procedural drawing only; no character/enemy PNG sprites are used.
- Particle counts are bounded to avoid unbounded visual allocations.

## Scope and known limitations

This is a first gameplay proof-of-concept, not a production-ready build. Touch controls, platform traversal, true destructible terrain, boss behavior, save/progression, and device performance testing are not implemented yet. Runtime verification in Godot is still required before treating this as tested.
