# OVERDRIVE ENGINE — Technical Architecture v1.1

## Product boundary

OVERDRIVE ENGINE is a reusable 2D real-time effects and elemental-combat foundation inside Godot, not a replacement for Godot and not the finished game. The Engine Lab is an integration harness, not a gameplay prototype.

## Target

- Primary: Android landscape.
- Secondary: desktop editor iteration.
- Visual target: hybrid high-end, with scalable procedural effects.
- Initial performance objective: 60 FPS where device budget permits, with a 30 FPS fallback target on constrained devices. These are goals, not measured claims.

## Module contracts

### Core

Owns shared effect time, seeded randomness, common effect parameters, and event contracts. It must not depend on actors or gameplay scenes.

### Element definitions

`scripts/elements/element_definition.gd` defines a data-only element: stable ID, display name, visual color, damage/impulse scales, status metadata, tags, and a chain-target budget. The definition describes an element; it does not execute gameplay or render effects.

### Ability executor

`scripts/combat/ability_executor.gd` validates data-driven ability requests, enforces a basic per-caster ability cooldown, applies element/reaction modifiers, caps and de-duplicates requested target IDs, and emits a structured result. It does **not** own hit detection, health, target distance, body impulses, or VFX spawning. Those responsibilities belong to a future world/gameplay adapter.

### Interaction resolver

`scripts/elements/interaction_resolver.gd` resolves element pairs into deterministic reaction metadata. Initial pairs cover fire + wind, fire + water, lightning + water, water + wind, and lightning + wind. Reaction fan-out is capped; the future chain manager must also prevent repeated visits/cycles.

### Combat/world adapter (future)

Owns authoritative collision and target validation, damage/status application, physics impulses, environmental changes, and chain traversal. It consumes executor results and applies them to actual world objects.

### Energy renderer

Owns procedural 2D energy geometry: branching lightning, arcs, plasma ribbons, beams, and shockwave outlines. Geometry is generated at bounded complexity and uses stable inputs when repeatability is needed.

### Particle system

Owns short-lived sparks, debris, dust, and trails. Particle counts and lifetimes are bounded, with simpler fallback behavior for low-end hardware.

### Impact & physics

Gameplay-relevant impulses and collision responses must be explicit and separate from decorative camera/visual impulses. VFX may communicate force but must not silently change simulation outcomes.

### Performance director

Exposes Low, Balanced, and High presets. Quality reduces presentation complexity (particles, branches, line layers, lights), not damage, status durations, collision, or reaction rules.

### Engine Lab

Contains isolated demos, controls, and simple telemetry. Elemental contracts currently have a separate manual test plan; they are not yet wired to a real actor/world adapter.

## Renderer decision

Keep the project's existing GL Compatibility configuration as a conservative baseline. Evaluate other Godot renderers and HDR/glow on the actual Godot 4.7.x installation and target Android devices before changing defaults.

Reference: https://docs.godotengine.org/en/4.7/engine_details/architecture/internal_rendering_architecture.html

## Testable milestones

1. **Lab boot** — project opens and runs the visual engine lab.
2. **Core contract** — effect clock and seeded randomness are reusable.
3. **Procedural energy** — click/tap spawns bounded lightning and impact effects.
4. **Quality director** — presets change visual budgets; telemetry is visible.
5. **Elemental foundation** — definitions, ability execution, cooldowns, and pair-based reaction resolution.
6. **World adapter** — collision validation, authoritative damage/status, impulse, and bounded chain traversal.
7. **Element renderers** — wind, fire, and water renderers use the same ability/event contract as lightning.
8. **Android validation** — measure frame time, allocations, input latency, and simultaneous-effect load on real landscape devices.

## Definition of done per change

- One coherent subsystem or integration step.
- No dependency on a specific game's progression.
- Manual test steps documented.
- Godot 4.7.x parser/runtime checks are reported only after actually running the project.
- Performance targets are reported only after measurements on target hardware.
