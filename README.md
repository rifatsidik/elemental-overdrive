# OVERDRIVE ENGINE

A modular real-time 2D VFX, motion, and elemental-combat foundation built on Godot 4.7.x, targeting high-end visuals with adaptive quality for Android landscape.

## Purpose

This repository builds the **engine lab and reusable engine systems**, not a finished game. Subsystems must remain independently testable before they are connected to a future game.

## Architecture

See [docs/ENGINE_ARCHITECTURE.md](docs/ENGINE_ARCHITECTURE.md) for the engine overview and [docs/ELEMENTAL_COMBAT_CONTRACT.md](docs/ELEMENTAL_COMBAT_CONTRACT.md) for ability/reaction contracts.

- **Core** — shared clock, seeded effects, and event contracts.
- **Element Definitions** — data-driven element identity, color, status, damage/impulse scaling, and bounded chain budgets.
- **Ability Executor** — validates ability requests and emits simulation result payloads, with per-caster cooldowns.
- **Interaction Resolver** — deterministic element-pair rules, reaction modifiers, statuses, and chain caps.
- **Combat/world adapter (future)** — authoritative collision, target validation, health, and physics changes; intentionally separate from ability resolution.
- **Energy Renderer** — procedural lightning, arcs, plasma ribbons, beams, and shockwaves.
- **Particle System** — bounded sparks, debris, and trails.
- **Impact & Physics** — gameplay impulses kept separate from decorative motion.
- **Performance Director** — Low / Balanced / High quality budgets and runtime telemetry.
- **Engine Lab** — isolated demonstrations and controls.

## Requirements

- Godot Engine 4.7.x
- Git

## Run

Open this folder in Godot and press **F5**. The default scene is `scenes/engine_lab.tscn`. In the current visual lab, click/tap the canvas to trigger a procedural energy burst.

The elemental modules are reusable building blocks; the current lab scene does not yet wire them to real actors, collision, health, or game progression.

## Quality and renderer policy

The project keeps GL Compatibility as a conservative boot target. Renderer/HDR/glow changes must be checked against the actual Godot 4.7.x installation and target Android devices before being committed as the default. Visual quality must never alter simulation damage or reaction rules.

## Development rules

- Keep commits small and independently testable.
- Keep ability simulation separate from renderer nodes and quality settings.
- Keep effects and chain reactions bounded.
- Do not report parser/runtime correctness or performance targets as verified until tested in Godot and measured on hardware.
