# OVERDRIVE ENGINE — Technical Architecture v1.0

## Product boundary

OVERDRIVE ENGINE is a reusable 2D real-time effects framework inside Godot, not a replacement for Godot and not the survivor game itself. The main scene is an Engine Lab where individual systems can be inspected without enemies, upgrades, progression, or combat rules.

## Target

- Primary: Android landscape.
- Secondary: desktop editor iteration.
- Visual target: hybrid high-end; rich procedural energy effects with adjustable complexity.
- Initial performance objective: 60 FPS where device budget permits, with a 30 FPS fallback target on constrained devices. These are goals, not measured claims.

## Module contracts

### Core
Owns shared effect time, seeded randomness, common effect parameters, and event contracts. It must not depend on actors or gameplay scenes.

### Energy Renderer
Owns procedural 2D energy geometry: branching lightning, arcs, plasma ribbons, beams, and shockwave outlines. Geometry is generated at bounded complexity and uses stable inputs when repeatability is needed.

### Particle System
Owns short-lived sparks, debris, dust, and trails. Particle counts and lifetimes are bounded. Use GPUParticles2D where supported and useful; retain a simpler fallback path for low-end hardware.

### Impact & Physics
Gameplay-relevant impulses and collision responses must be explicit and separate from purely decorative camera/visual impulses. VFX may communicate force but must not silently change simulation outcomes.

### Animation
Provides reusable envelopes for anticipation, peak, and follow-through, plus procedural motion helpers. Timing is parameterized rather than embedded in one effect.

### Light & Color
Owns palettes, flashes, aura layers, and optional scene glow. Glow/HDR must be configurable because screen-space post-processing has a cost on mobile.

### Performance Director
Exposes Low, Balanced, and High presets. Quality changes should reduce effect complexity independently: particle budget, lightning branches, line layers, and active light count. Record FPS and active effect counts; never claim targets are met without device measurements.

### Engine Lab
Contains isolated demos, controls, and simple telemetry. The lab is an integration harness, not a gameplay prototype.

## Renderer decision

Start with the project's existing GL Compatibility configuration for the first minimal demo. Godot 4.7 documents Mobile as optimized for mobile GPUs and supports HDR 2D, while Compatibility targets broader/older hardware and lacks some advanced rendering capabilities. We will test a Mobile renderer branch after the baseline is stable, then choose the default based on actual target devices. Do not enable HDR/glow globally until measured.

Reference: https://docs.godotengine.org/en/4.7/engine_details/architecture/internal_rendering_architecture.html

## Testable milestones

1. **Lab boot** — project opens and runs the engine lab.
2. **Core contract** — effect clock and deterministic seed are reusable.
3. **Procedural energy** — click/tap spawns bounded lightning and shockwave effects.
4. **Quality director** — presets change geometry/particle budgets; telemetry is visible.
5. **Motion and impact** — envelope and impulse demos, isolated from gameplay.
6. **Renderer evaluation** — compare Compatibility and Mobile on desktop and real Android hardware.
7. **Particle and lighting layers** — add bounded particles and optional glow after measurement.

## Definition of done per commit

- One coherent subsystem or scene change.
- No survivor gameplay dependency.
- Godot 4.7.x project opens without script parse errors.
- Manual test steps documented.
- Runtime verification is only claimed after actually running the project.
