# OVERDRIVE ENGINE — Technical Architecture v1.2

## Product boundary

OVERDRIVE ENGINE is a reusable 2D real-time effects and elemental-combat foundation inside Godot, not a replacement for Godot and not the finished game. The Engine Lab remains an integration harness. Element renderers are routed through a presentation-only consumer, separate from combat simulation.

## Target

- Primary: Android landscape.
- Secondary: desktop editor iteration.
- Visual target: hybrid high-end, with scalable procedural effects.
- Initial objective: 60 FPS where device budget permits, with a 30 FPS fallback goal on constrained devices. These are not measured claims.

## Runtime modules

### Core and elemental definitions

Core owns shared effect timing and event contracts. Element definitions own stable identity, visual palette, gameplay multipliers, status metadata, tags, and chain budgets. Definitions contain data only.

### Ability executor and interaction resolver

The executor validates ability requests, enforces per-caster cooldowns, calculates damage/impulse modifiers, and returns structured results. The resolver is deterministic pair-based rule logic. Neither performs physics queries, mutates health, nor spawns visual effects.

### Combatant and status controller

Combatants own health, defeat state, status controller, and an impulse adapter for `RigidBody2D` / `CharacterBody2D`. Statuses have explicit lifetime behavior; burning currently applies periodic damage, while other elemental states are timed markers. This keeps status gameplay out of the renderer.

### Chain reaction manager

Selects nearest candidates within a bounded radius and excludes already-hit/duplicate instances. It does not apply damage. Any future multi-hop chain system must use a visited set, per-cast event budget, and a depth limit.

### Combat world adapter

Receives candidate targets from the game's raycast, overlap query, projectile collision, or other physics system. It filters invalid/defeated/duplicate/out-of-range combatants, asks the executor for the simulation result, applies damage/status/impulse, and emits hit/reaction signals for presentation. It never scans the entire scene to discover targets.

### Energy renderer and particle system

Own procedural lightning, arcs, plasma ribbons, beams, shockwaves, sparks, debris, and trails. Geometry, particle counts, and line layers must be bounded and scalable.

### Performance director

Exposes Low, Balanced, and High presets. Quality changes presentation complexity only, not damage, collision, status duration, or reaction rules. Measure actual frame time and allocations before tuning thresholds for a specific Android device.

### Engine Labs

The default Engine Lab demonstrates procedural energy VFX and quality controls. A separate Elemental Combat Lab wires test combatants, the world adapter, status effects, and the VFX router together. It remains an integration harness with synthetic targets, not a production enemy arena.

## Renderer policy

Keep GL Compatibility as a conservative baseline. Evaluate renderer changes and HDR/glow on the actual Godot 4.7.x installation and target Android devices before changing defaults.

## Milestones

1. Lab boot and procedural energy.
2. Element definitions, ability execution, and deterministic reactions.
3. Combatant health/status and world adapter.
4. Automated smoke tests in Godot 4.7.x.
5. Collision-query integration and multi-hop chain graph with cycle guards.
6. Element VFX router and procedural wind, fire, and water renderers consuming combat hit events.
7. Android landscape profiling, allocation/latency checks, and Low/Balanced/High tuning.

## Definition of done

- Manual/automated tests documented and actually run before claiming success.
- No hidden gameplay changes caused by VFX quality.
- No unbounded target fan-out or status/effect lifetime growth.
- Runtime and Android performance claims supported by recorded test results.
