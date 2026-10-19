# The Last Station: Platform Zero — v0.1.1

A mobile controls update to the original offline Godot 4.5.1 Android chapter.

## Improvements
- **Multitouch jump:** a larger, independent Jump touch target can be pressed while holding the movement joystick or dragging the camera with another finger.
- **Analog running:** remove the unintuitive Run toggle. Push the left stick partway to walk, and to its outer edge to run smoothly.
- **More forgiving jumping:** short jump input buffer and ledge grace window.
- **Stability:** joystick and jump touches track separate fingers; input resets on menus and interruptions.
- **Testing:** expanded automated synthetic two-finger regression checks.

## Install
Download `The-Last-Station.apk` for ARM64 Android 7.0+ with OpenGL ES 3 support. It uses the same package name and development signing key as v0.1.0 and increments Android version code to 2, so it should install over the prior build without deleting saves.

This is an offline, debug/development-signed release, not a Play Store build. Physical-device multitouch performance and ergonomics are still awaiting validation. The source archive is included.
