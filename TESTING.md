# Validation report

The source was reconstructed after automatic scratch cleanup, then freshly imported and tested with Godot 4.5.1. Prior test results were not substituted for this rebuild.

## Executed integration test

Run `godot --headless --path . --editor --import --quit`, then `godot --headless --path . -- --smoke-test`.

Passed: scene creation; all 13 interaction points; reserve-cell collection; rejection/acceptance of relay combinations; gate opening; all four memories; rejection/acceptance of signal sequences; train arrival and boarding availability; actual disk save/load; synthetic joystick press/release; grounded physics; movement and jump over physics frames; timed ending cinematic and reload of a completed save. The test uses a separate save file and removes it on success. See `tests/engine-results.txt`.

## Render inspection

Actual Godot Compatibility/OpenGL frames at 1280×720 were inspected for the platform, title, garden/character, overlook, memory panel and settings. These were rendered with software Mesa, not a mobile GPU. The source includes a `--capture` QA path, which uses a separate save file and writes screenshots in Godot's user data directory.

## Android package verification

ARM64 debug APK exported with matching Godot 4.5.1 templates. Signature verified using Android apksigner. Package/SDK/architecture inspected with aapt. Native ELF load segments checked for 16 KB alignment. Package contains license notices and requests no Internet permission.

## Remaining verification

No physical Android or emulator installation/launch test was possible here. Sustained 60 FPS, thermals, battery draw, touch ergonomics, all screen ratios/cutouts, OEM-specific behavior and long-running audio/save durability remain unverified. Synthetic tests are not a complete manual playthrough. No user-timed claim of 15–30 minutes is made.

## Mobile control regression checklist (changes after v0.1.0)

The current source smoke test now exercises two independent touch IDs (joystick
then jump, and jump then joystick), release isolation, and the analog
walk-to-run speed curve. These new assertions have **not** yet been executed
in Godot; run the commands above against the updated source before merging.

On a physical Android device, also verify:

- Hold the left stick while repeatedly tapping Jump with a second finger;
  keep moving during the jump, then reverse the finger order.
- Hold the right side to orbit the camera while tapping Jump, and confirm
  neither touch takes control of the other gesture.
- Tilt the stick slightly to walk, and push to the edge to run. Releasing it
  must stop motion; a gentle return must slow down without a run toggle.
- Tap Jump briefly near a ledge and immediately before landing, including
  at both 30 FPS and 60 FPS quality presets.
- Open Pause, Journal, and a puzzle while touching the movement controls;
  gameplay input should not remain stuck after dismissing the overlay.

The v0.1.0 APK published from the original commit is not rebuilt by these
source-only changes. A new APK must be exported and tested separately.

## v0.2.0 character verification

- Godot 4.5.1 imported the original embedded-buffer glTF successfully.
- Gameplay smoke tests passed with the new character, including movement, jump,
  concurrent touch IDs, puzzles, ending and save/reload.
- Animation target assertions cover arms, legs, knees, elbows, eyes, hair, skirt,
  ribbon and head. Character geometry is 23,998 triangles across 15 articulated
  meshes (material surfaces are merged per joint).
- Front, three-quarter, back and running-pose frames were rendered with Godot's
  OpenGL Compatibility renderer on Mesa software rendering. Collar clipping was
  corrected during inspection. Reproduce with:
  `godot --path . --script tests/character_preview.gd` (writes `/tmp/character-*.png`).
- Physical Android performance and cloth clearance during all camera/movement
  combinations remain manual device checks. Clothing motion is procedural,
  not a cloth physics simulation.
