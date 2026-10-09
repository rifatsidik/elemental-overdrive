# Elemental Combat Foundation — Contract v0.1

## Responsibility boundaries

- **ElementDefinition** is data only: identity, color, damage/impulse scales, status, chain budget, and tags.
- **AbilityExecutor** validates a data-driven ability and produces a structured simulation event. It does not perform raycasts, apply health changes, move bodies, or spawn VFX.
- **InteractionResolver** is deterministic rule logic. It returns modifiers and status/reaction metadata; it never mutates the world.
- **Gameplay/world adapter (future)** owns authoritative hit detection, damage application, physics impulses, and world state.
- **Element renderers** consume events for presentation. Visual quality must not change damage, status, or reaction outcomes.

## Ability dictionary

Required: `ability_id`, `element_id`. Optional fields: `damage` (default 10), `impulse` (0), `cooldown` (0), `enabled` (true).

Context may include `caster_id`, `target_ids`, `secondary_element_id`, and rule-specific values such as `wet_surface`. Target IDs are de-duplicated and capped by the element/reaction chain budget. Actual target validity and distance checks belong to the future world adapter.

## Initial elements

| Element | Gameplay identity | Default status |
| --- | --- | --- |
| Lightning | Fast, bounded chaining; wet surfaces can increase chain budget | charged |
| Wind | Redirect and push; elevated impulse | staggered |
| Fire | Strong damage and burn duration | burning |
| Water | Pressure/push and wet status | soaked |

## Initial reactions

| Pair | Reaction ID | Rule |
| --- | --- | --- |
| Fire + Wind | `fire_spread` | 1.15x damage, 1.25x impulse |
| Fire + Water | `steam_burst` | 0.65x damage, 0.8x impulse; steamed status |
| Lightning + Water | `conductive_chain` | 3 targets normally, up to 5 on wet surfaces |
| Water + Wind | `driven_spray` | 0.9x damage, 1.4x impulse |
| Lightning + Wind | `ionized_gust` | 1.05x damage, 1.15x impulse, up to 4 targets |
| Same element | `elemental_resonance` | 1.1x damage |

These are starter tuning values, not final balance. Missing pairings return no reaction. Chain targets are capped to prevent unbounded fan-out; world-level cycle prevention remains the chain manager's responsibility.

## Manual test plan (Godot 4.7.x)

1. Open the project and confirm there are no script parse errors.
2. Instantiate `OverdriveAbilityExecutor`, call `register_default_elements()`, and confirm all four element IDs are registered.
3. Execute `{ "ability_id": "arc_bolt", "element_id": "lightning", "damage": 10, "impulse": 5 }`; verify the result is accepted with finite damage and impulse.
4. Add context `{ "caster_id": "player", "target_ids": ["a", "b", "a", "c", "d"], "secondary_element_id": "water", "wet_surface": true }`; verify targets are unique and capped to the lightning/water reaction budget.
5. Execute the same ability with a positive cooldown twice for the same caster; the second execution must return `cooldown_active`. Wait for cooldown to expire and retry.
6. Try an unknown element, a missing ability ID, and a disabled ability; each must be rejected with a reason and must not emit `ability_executed`.
7. Resolve each listed reaction in both input orders; pair-based reactions should return the same reaction ID and modifiers.
8. Confirm that changing visual quality or omitting a renderer does not alter the executor result.

## Verification status

This is an implementation contract and manual test plan, not a passed runtime test report. Run the project and these cases in Godot 4.7.x before treating parser/runtime correctness as verified.
