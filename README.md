# OVERDRIVE ENGINE

A modular real-time 2D VFX, motion, and elemental-combat foundation built on Godot 4.7.x, targeting high-end visuals with adaptive quality for Android landscape.

## Purpose

This repository builds the **engine lab and reusable engine systems**, not a finished game. Subsystems must remain independently testable before they are connected to a future game.

## Architecture

- **Core** — shared clock, seeded effects, and event contracts.
- **Element Definitions** — data-driven element identity, color, damage/impulse scaling, statuses, and chain budgets.
- **Ability Executor** — validates abilities, resolves modifiers, and manages per-caster cooldowns.
- **Interaction Resolver** — deterministic elemental pair reactions.
- **Combatant & Status Controller** — health, defeat state, timed statuses, periodic burn damage, and impulse adaptation.
- **Chain Reaction Manager** — nearest-first, range-limited, duplicate-safe target selection.
- **Combat World Adapter** — applies simulation results to caller-supplied collision candidates.
- **Element VFX Router** — routes combat hit results to lightning, wind, fire, and water renderers without mutating simulation state.
- **Energy Renderer & Particles** — procedural lightning and bounded energy/particle effects.
- **Performance Director** — Low / Balanced / High visual budgets and runtime telemetry.
- **Engine Lab** — isolated visual demonstrations and controls.

See [docs/ENGINE_ARCHITECTURE.md](docs/ENGINE_ARCHITECTURE.md), [docs/ELEMENTAL_COMBAT_CONTRACT.md](docs/ELEMENTAL_COMBAT_CONTRACT.md), and [docs/COMBAT_WORLD_INTEGRATION.md](docs/COMBAT_WORLD_INTEGRATION.md).

## Run

Open this folder in Godot 4.7.x and press **F5**. The default scene remains the visual Engine Lab. For combat integration, open `scenes/elemental_combat_lab.tscn` and run the current scene (F6); see [docs/ELEMENTAL_COMBAT_LAB.md](docs/ELEMENTAL_COMBAT_LAB.md). The combat lab uses test targets and is not the finished game.

Run the headless smoke test from a terminal with Godot installed:

```bash
godot --headless --path . --script res://tests/elemental_combat_smoke_test.gd
```

## Design guarantees

- Ability simulation is independent of renderer quality.
- World adapter requires candidate targets from a collision/physics query; it does not scan the entire scene.
- Chain candidates and target counts are bounded.
- Visual effects are presentation only; they must not silently mutate health or physics.
- Keep commits small and testable. Do not claim runtime correctness or performance until measured.
