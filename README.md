# The Last Station: Platform Zero

Version 0.1.0 — an original, offline third-person 3D mystery chapter for Android, made with Godot 4.5.1.

## Play

**[Download the Android APK and source](https://github.com/nyimyozin/The-Last-Station/releases/tag/v0.1.0)**

The publish workflow reassembles the original APK from the parts in `downloads/parts` and verifies its SHA-256 before attaching it to the release. If the release is not available yet, check the repository's Actions tab.

Install `The-Last-Station.apk` on an ARM64 Android 7.0+ device with OpenGL ES 3 support. When prompted, allow installation for the app opening the APK. No accounts, network access, ads or purchases are used. The APK is development-signed for direct installation, not a Play Store release. Native libraries support 16 KB memory pages.

Choose New journey. Use the left joystick to walk, drag open space on the right to orbit the camera, and tap Run to toggle faster movement. Jump is at the lower right. Approach glowing objects and tap the contextual prompt. Journal retains memories, objectives and clues. Pause opens settings and save/title options.

Progress saves after discoveries, puzzle completion, app suspension and returning to the title. Continue restores your journey. Starting over asks before replacing progress. After the ending, you can revisit the station to find the optional fourth memory.

Graphics presets: Low targets 30 FPS without shadows; Balanced targets 60 FPS with shadows; High adds 2× antialiasing. These are caps/settings, not verified mobile performance benchmarks. Music, world audio and camera sensitivity are adjustable.

Desktop controls: WASD/arrows to move; hold right mouse to look; Shift to run; Space to jump; E to interact; J for journal; Escape to pause.

## Open the complete project

Open `project.godot` in **Godot 4.5.1 stable**, let assets import, then press F5. No plugins or external asset downloads are needed to run the project. The station and original chibi traveler are constructed from the authored geometry code at runtime.

- `scripts/game.gd`: UI, progression, puzzles, cinematics, save/load and integration tests.
- `scripts/world.gd`: station, waiting room, garden, maintenance shed, signal walk, overlook, distant islands, vegetation, train and interaction points.
- `scripts/traveler.gd`: character, cel shader, acceleration, jumping, procedural animation and SpringArm camera collision.
- `scripts/geometry.gd`: reusable meshes and materials.
- `scripts/stick.gd`: touch joystick with finger tracking.
- `audio/`: 11 original synthesized WAV files, including a looping score and ambient wind.
- `audio/compose.py`: optional audio regeneration, requiring Python and NumPy; prebuilt audio is included.
- `export_presets.cfg`: ARM64 Android configuration.
- `tests/engine-results.txt`: results from the rebuilt project's integration run.

The story has an opening, linked power/signal puzzles, three required memories, one optional memory, a world reveal, train arrival and an ending. The next destination is a story tease, not a second playable chapter.

## Build another APK

1. Install Godot 4.5.1 and matching export templates (Editor → Manage Export Templates).
2. Install OpenJDK 17 and the Android SDK. Configure their paths in Editor Settings → Export → Android. Official instructions: https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_android.html
3. Open Project → Export → Android. Export with **Export With Debug** enabled. This uses the standard APK template and does not require a custom Gradle build.
4. Command-line equivalent: `godot --headless --path . --export-debug Android ../The-Last-Station.apk`

The included development key is configured in the preset: alias `androiddebugkey`, password `android`. It permits updates to this development build. It is deliberately public and must not be used as a production signing key. A store release needs private signing, current store settings and an AAB workflow; none of those publication steps were performed.

## Verification and scope

This is a compact first playable build, not a commercial-quality finished anime game. Character art uses original procedural low-poly geometry and articulated motion, scarf movement, blinking and landing compression. It does not contain a production skeletal animation library, voice acting or lip sync. Atmosphere uses inexpensive depth fog and shaders rather than true volumetric simulation.

Godot import, the integrated gameplay tests, desktop render inspection and Android package checks are documented in `TESTING.md`. The APK has **not** been installed on a physical phone or emulator here. Mobile frame rate, thermal behavior, simultaneous physical multitouch and speaker/headphone mixing remain unverified. The requested 15–30-minute play time has not been measured with users.

Original source, story, procedural art, shaders and synthesized audio: MIT license in `LICENSE`. DejaVu Sans and Godot dependencies retain their licenses in `licenses/`. In-game credits expose these notices. No commercial anime assets or music were used.
