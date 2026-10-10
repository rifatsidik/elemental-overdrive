# Dungeon Art Lab — Prototype 01

An isolated, procedural pixel-art dungeon scene added for visual exploration. It does not replace the repository's default neon platformer scene.

## Run

Open the existing Godot 4.7.x project, then open:

`res://prototypes/dungeon_art_lab.tscn`

Press **F6** (Run Current Scene). The main project scene remains unchanged.

## Controls

- **WASD / Arrow keys:** move the hero
- **Space / Enter:** swing the sword and damage nearby enemies
- **E:** open the treasure chest when close

## Prototype contents

- Hand-drawn pixel-style stone floor and walls
- Four animated torch lights
- Hero with sword, armor, and a simple movement bob
- Skeleton, slime, and floating wisp enemies
- Basic chase behavior and hit points
- Treasure chest, gold counter, and HUD

## Scope and known limitations

This is an art and interaction blockout, not a finished game. All visuals are drawn procedurally in GDScript so the first pass has no external asset dependencies. Character animations are intentionally simple; collision, enemy attack behavior, real lighting, tilemap extraction, audio, and mobile touch controls remain future work. Run it in Godot to validate runtime behavior before treating it as production-ready.
