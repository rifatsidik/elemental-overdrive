# Engine Lab — Manual Test Plan

## Baseline boot

1. Open the repository in Godot Engine 4.7.x.
2. Wait for the filesystem scan to finish.
3. Press F5.
4. Confirm the Engine Lab opens with a dark grid, title, FPS, quality label, and an initial energy burst.

## Input and quality budgets

1. Click or tap different points on the canvas.
2. Confirm a short-lived lightning shape and expanding rings appear at the selected point.
3. Press `1`, then trigger an effect; the effect should use the smallest branch/layer budget.
4. Press `2` and trigger an effect; the Balanced budget should be used.
6. Press `3` and trigger an effect; the High budget should be used.
7. Confirm effects expire and the active effect count falls back toward zero.

## Regression checks

- Resize the desktop window and verify the background grid redraws to the new viewport.
- Verify no player, enemy, wave, score, upgrade, or progression logic is required by the lab.
- Record Godot version, renderer, device model, FPS range, and any errors before reporting a test result.

## Current verification status

This checklist is a manual procedure. The repository changes have not been run in a local Godot executable as part of this commit sequence; do not treat the checklist as a passed test report.
