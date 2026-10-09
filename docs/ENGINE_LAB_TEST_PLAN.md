# Engine Lab — Manual Test Plan

## Baseline boot

1. Open the repository in Godot Engine 4.7.x.
2. Wait for the filesystem scan to finish.
3. Press F5.
4. Confirm the Engine Lab opens with a dark grid, title, FPS, quality label, and an initial energy burst.
5. Confirm no script parse errors appear in the debugger.

## Visual strike checks

1. Click or tap several points across the canvas.
2. Confirm each strike has a fast bolt reveal, branching filaments, a white-hot core, cyan/blue aura, expanding impact rings, and small particle streaks.
3. Confirm the effect fades and frees itself without leaving persistent particles.
4. Trigger 5–10 strikes quickly and observe overlap, readability, and frame pacing.

## Quality and adaptive checks

- Press `0` to enable automatic quality adjustment.
- Press `1` for manual Low, `2` for manual Balanced, and `3` for manual High. Selecting a manual preset disables adaptive changes.
- Confirm newly spawned effects use the selected branch and layer budgets.
- Confirm telemetry displays approximate FPS, frame time, active effects, and quality mode.
- Stress test multiple simultaneous effects; verify active effect budgets reduce new effect complexity.

## Regression checks

- Resize the desktop window and verify the background grid redraws to the new viewport.
- Verify no player, enemy, wave, score, upgrade, or progression logic is required by the lab.
- Run a long session and watch for errors, stuck effects, or steadily increasing active-effect counts.
- Record Godot version, renderer, device model, FPS range, and any errors before reporting a test result.
- Repeat on actual Android landscape hardware before making performance claims.

## Verification status

These steps are a manual test plan, not a passed test report. The changes in this branch have not been run in a local Godot executable as part of this update. Performance targets remain unverified until measured on target hardware.
