# Engine Lab — Manual Test Plan

## Baseline boot

1. Open the repository in Godot Engine 4.7.x.
2. Wait for the filesystem scan to finish.
3. Press F5.
4. Confirm the Engine Lab opens with a dark grid, title, FPS, quality label, and an initial energy burst.
5. Confirm no script parse errors appear in the debugger.

## Natural lightning checks

1. Click/tap at different positions. The strike should descend from above and terminate at the input position.
2. Watch the leader shape: it should be a coherent jagged path with a constrained lateral walk, not evenly alternating zigzags.
3. Check asymmetric forks: most side branches should travel outward and downward, with varied lengths and segment counts.
4. Check timing: the leader reveals rapidly, a very short dark gap follows, then a weaker return flash and a short afterglow.
5. Confirm the white-hot core remains narrow, with blue/cyan aura around it rather than a uniformly thick neon tube.
6. Confirm the impact bloom and rings stay localized around the strike endpoint.
7. Trigger repeated strikes and check that geometry differs per seed, branches remain readable, and no effect persists after its lifetime.

## Quality and adaptive checks

- Press `0` to enable automatic quality adjustment.
- Press `1` for manual Low, `2` for manual Balanced, and `3` for manual High. Selecting a manual preset disables adaptive changes.
- Confirm newly spawned effects use the selected branch and layer budgets.
- Confirm telemetry displays approximate FPS, frame time, active effects, and quality mode.
- Stress test multiple simultaneous effects; verify active effect budgets reduce new effect complexity.

## Performance and regression checks

- Resize the desktop window and verify the background grid redraws to the new viewport.
- Trigger 5–10 strikes quickly and observe overlap, readability, and frame pacing.
- Confirm the lightning path geometry is generated once per effect; per-frame work should only reveal/draw existing paths.
- Confirm particle counts and branch/layer budgets remain bounded by quality presets.
- Verify no player, enemy, wave, score, upgrade, or progression logic is required by the lab.
- Run a long session and watch for errors, stuck effects, or steadily increasing active-effect counts.
- Record Godot version, renderer, device model, FPS range, and any errors before reporting a test result.
- Repeat on actual Android landscape hardware before making performance claims.

## Verification status

These steps are a manual test plan, not a passed test report. The lightning update has not been run in a local Godot executable as part of this change. Parser/runtime correctness and performance targets remain unverified until tested in Godot 4.7.x and measured on target Android hardware.
