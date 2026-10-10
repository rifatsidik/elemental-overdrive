# Neon Platformer Lab — Manual Test Plan

## Boot and rendering

1. Open the project in Godot 4.7.x and press F5.
2. Confirm the default scene is the neon platformer lab, not the old Engine Lab.
3. Confirm the player is drawn from glowing lines, arcs, and circles; no sprite textures are used.
4. Check that neon platform visuals align with their collision surfaces while the camera follows the player.

## Desktop controls

- Move: A/D or Left/Right.
- Jump: Space, W, or Up.
- Dash: Shift.
- Check running limb swing, airborne pose, short dash trail, and landing flash.
- Jump across the hand-built platforms and check collision alignment.

## Android touch prototype

- Landscape orientation is configured in project settings.
- Bottom-left screen zones move left/right; lower-right zones trigger jump/dash.
- Validate multi-touch, touch-zone sizing, safe areas, and framerate on an actual device before treating controls as production-ready.

## Current verification status

The files are committed to GitHub, but this environment did not have a Godot executable available to run the project. This is a manual test plan, not a passed runtime test report.
