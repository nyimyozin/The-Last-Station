# Platform Zero — hand orientation fix (v0.2.1)

A focused patch for the schoolgirl character introduced in v0.2.0.

- Corrected mirrored thumb placement on both hands, so thumbs point outward from the torso and slightly forward in the rest pose.
- Updated both the authored Python character builder and the bundled offline glTF mesh.
- Added a glTF geometry regression check to the Android build workflow.
- Gameplay, animation controls, world, story and saved progress are unchanged.

Version 0.2.1 / Android version code 4. Same package ID and development signing key as v0.2.0, so this debug APK can be installed over v0.2.0.

GitHub Actions checks the model orientation and runs Godot smoke tests, Android export and signature verification before publishing. Physical-device appearance remains to be checked.
