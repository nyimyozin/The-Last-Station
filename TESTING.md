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
