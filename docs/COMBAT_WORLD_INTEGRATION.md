# Combat World Integration — v0.2

## Included systems

- `OverdriveCombatant`: reusable health, defeat state, timed status host, and impulse adapter for `RigidBody2D` / `CharacterBody2D`.
- `OverdriveStatusController`: duration refresh, expiry signals, and configurable periodic burn damage. Unknown status IDs remain data-only statuses.
- `OverdriveChainReactionManager`: nearest-first candidate selection, range cap, duplicate exclusion, and bounded target count.
- `OverdriveCombatWorldAdapter`: connects ability results to validated combatants, applies damage/status/impulse, and emits hit/reaction signals.
- `tests/elemental_combat_smoke_test.gd`: headless smoke checks for element registration, ability execution, cooldown rejection, and symmetric pair resolution.

## Contract

The adapter does not discover collision candidates by scanning the scene. A caller must pass targets from a raycast, overlap query, projectile collision, or other gameplay collision system. The adapter then filters invalid nodes, defeated combatants, duplicates, and out-of-range targets.

Example:
```gdscript
var adapter := OverdriveCombatWorldAdapter.new()
add_child(adapter)

var result := adapter.execute_ability(
	{
		"ability_id": &"arc_bolt",
		"element_id": &"lightning",
		"damage": 12.0,
		"impulse": 140.0,
		"cooldown": 0.4,
		"max_range": 700.0,
		"chain": true,
		"chain_range": 300.0
	},
	player,
	collision_candidates,
	{"secondary_element_id": &"water", "wet_surface": true}
)
```

Use the returned `hits` array for feedback/telemetry and the `reaction_triggered` signal for VFX/audio. Renderers must not change the simulation result. Chain candidates are selected nearest-first and the combined direct-plus-chain target count is kept within the executor's element/reaction target budget.

## Status behavior

- `burning`: periodic damage, default 2 damage per 0.5 seconds. Override with ability `status_parameters`, for example `{"damage_per_tick": 3.0, "tick_interval": 0.4}`.
- `soaked`, `charged`, `staggered`, and `steamed`: timed state markers in this iteration. Their additional behavior is intentionally deferred to explicit combat/world rules, not hidden in the renderer.
- Reapplying a status refreshes its remaining duration to the greater of current/new duration.

## Interactive integration lab

Open `scenes/elemental_combat_lab.tscn` and run the current scene (F6). Controls and manual checks are documented in `docs/ELEMENTAL_COMBAT_LAB.md`. The lab uses synthetic target selection; production gameplay must supply candidates from its real physics-query/collision pipeline.

## Run smoke tests

From a terminal with Godot 4.7.x installed, run the project headlessly with the test script, for example:

```bash
godot --headless --path . --script res://tests/elemental_combat_smoke_test.gd
```

Use the executable name installed on the machine (some Linux installations use `godot4`). A successful run should print `OVERDRIVE elemental combat smoke tests: PASS`.

## Important limitations before production

- Smoke tests must actually be run in Godot; they have not been run in this editing environment.
- The caller still owns accurate physics-query/collision candidate generation.
- Chain target selection is bounded and nearest-first but is not yet a multi-hop graph traversal across conductive surfaces.
- No network authority, save/load, enemy AI, animation state machine, audio mixer, or final mobile benchmark is claimed by this subsystem.
