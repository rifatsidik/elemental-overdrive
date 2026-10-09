# OVERDRIVE ENGINE

A modular real-time 2D VFX and motion framework built on Godot 4.7.x, with a high-end visual target and adaptive quality for Android landscape.

## Purpose

This repository currently builds the **engine lab**, not survivor gameplay. Each subsystem should be testable in isolation before it is used by a future game.

## Architecture

See [docs/ENGINE_ARCHITECTURE.md](docs/ENGINE_ARCHITECTURE.md) for the v1.0 technical contract and implementation sequence.

- **Core** — shared clock, reproducible effect seeds, and event contracts.
- **Energy Renderer** — procedural arcs, filaments, ribbons, beams, and shockwaves.
- **Particle System** — bounded sparks, debris, and trails.
- **Impact & Physics** — gameplay impulses kept separate from decorative motion.
- **Animation** — anticipation, peak, and follow-through envelopes.
- **Light & Color** — palette, aura, flashes, and optional glow.
- **Performance Director** — Low / Balanced / High quality budgets and runtime telemetry.
- **Engine Lab** — isolated visual demonstrations and controls.

## Requirements

- Godot Engine 4.7.x
- Git

## Run

Open this folder in Godot and press **F5**. The default scene is `scenes/engine_lab.tscn`.

In the lab, click/tap the canvas to trigger a procedural energy burst. This first demo is intentionally small and is not a benchmark of final Android performance.

## Quality and renderer policy

The initial project keeps GL Compatibility as a conservative boot target while the first procedural demo is established. Renderer/HDR/glow changes must be checked against the actual Godot 4.7.x installation and target Android devices before being committed as the default. The engine must not assume every mobile GPU supports the same features or budget.

## Development rules

- Keep commits small and independently testable.
- Avoid gameplay-specific dependencies inside engine modules.
- Keep visual effects bounded and make their complexity quality-scalable.
- Do not report performance targets as achieved until measured on hardware.
