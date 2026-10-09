# Elemental Combat Foundation — Contract v0.2

## Responsibility boundaries

- **ElementDefinition** is data only: identity, color, damage/impulse scales, status, chain budget, and tags.
- **AbilityExecutor** validates ability requests, enforces cooldowns, resolves modifiers, and emits structured simulation results. It does not perform collision queries or mutate combatants.
- **InteractionResolver** returns deterministic reaction metadata and never mutates the world.
- **Combatant** owns health, defeat state, timed statuses, and an adapter for physical impulse.
- **StatusController** owns status lifetime and explicitly defined status behavior. In this iteration, burning deals periodic damage; soaked, charged, staggered, and steamed are timed markers.
- **ChainReactionManager** selects nearest valid chain candidates with duplicate/range/count guards. It does not apply damage.
- **CombatWorldAdapter** applies executor results to candidate combatants supplied by the caller. It does not search the entire scene for targets.
- **Element renderers** consume result/reaction signals. Visual quality must not change damage, status, or reaction outcomes.

## Ability dictionary

Required: `ability_id`, `element_id`. Optional fields: `damage` (default 10), `impulse` (0), `cooldown` (0), `enabled` (true), `max_range` (1200), `chain` (false), `max_targets` (1 for non-chain abilities), `chain_range` (360), and `status_parameters`.

Context may include `caster_id`, `origin`, `secondary_element_id`, `wet_surface`, and `chain_candidates`. Pass candidate nodes from a physics query or collision system as the `targets` argument to `CombatWorldAdapter.execute_ability`. The adapter filters invalid, defeated, duplicate, and out-of-range combatants. For chain abilities, candidate selection is nearest-first and the result is capped by the element/reaction chain budget.

## Initial elements

| Element | Gameplay identity | Default status |
| --- | --- | --- |
| Lightning | Fast, bounded chaining; wet surfaces increase the conductive-chain limit | charged |
| Wind | Redirect and push; elevated impulse | staggered |
| Fire | Strong damage and periodic burn | burning |
| Water | Pressure/push and wet status | soaked |

## Initial reactions

| Pair | Reaction ID | Rule |
| --- | --- | --- |
| Fire + Wind | `fire_spread` | 1.15x damage, 1.25x impulse |
| Fire + Water | `steam_burst` | 0.65x damage, 0.8x impulse; steamed status |
| Lightning + Water | `conductive_chain` | 3 targets normally, up to 5 on wet surfaces |
| Water + Wind | `driven_spray` | 0.9x damage, 1.4x impulse |
| Lightning + Wind | `ionized_gust` | 1.05x damage, 1.15x impulse, up to 4 chain targets |
| Same element | `elemental_resonance` | 1.1x damage |

These are starter tuning values, not final balance. Missing pairings return no reaction. Chain candidates are bounded; a future multi-hop conductive graph must keep a visited set and a total event budget.

## Status behavior

- `burning`: periodic damage, default 2 damage per 0.5 seconds. Override with `status_parameters: { "damage_per_tick": 3.0, "tick_interval": 0.4 }`.
- Reapplying a status refreshes its remaining duration to the greater of the current and incoming duration.
- Other status IDs remain timed markers until explicit world rules are implemented; no gameplay effect is hidden inside VFX.

## Smoke test

With Godot 4.7.x installed:

```bash
godot --headless --path . --script res://tests/elemental_combat_smoke_test.gd
```

A successful run should print `OVERDRIVE elemental combat smoke tests: PASS`. Some installations use `godot4` instead of `godot`.

## Verification status

The smoke test is committed but has not been executed in this editing environment because Godot is unavailable here. Parser/runtime correctness and Android performance remain unverified until tested in Godot 4.7.x and on target hardware.
