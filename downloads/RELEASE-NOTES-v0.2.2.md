# Platform Zero — Futaba-chan animation (v0.2.2 release candidate)

**Status: release candidate only. The public v0.2.2 release has not been published.**

- Optional character swap to Futaba-chan (VRM 0.x) with original embedded textures.
- Six original keyframed humanoid animation clips: idle, walk, run, jump, fall, and land.
- Godot AnimationTree switches/crossfades between grounded locomotion and airborne states.
- Existing camera, controls, puzzles, story and save data preserved.
- Safe fallback to the existing v0.2.1 character when the licensed Futaba model is absent.
- Increment app version to 0.2.2, Android version code 5, retaining package identifier and development signing key.

**Licensing and release blocker:** Creator mingshop authorizes use of Futaba-chan in games/apps but forbids redistribution of the avatar model and its internal files. Accordingly, the new asset is **not in the public repository or source archive**. The public GitHub Actions release job intentionally fails if the complete private character asset is unavailable; otherwise it would produce an APK with the old character under a new version number. A compliant asset-supply/build path and an end-to-end runtime check are needed before publishing.

Model credit (as requested by creator for embedded game usage): Futaba-chan by mingshop, https://booth.pm/en/items/8605568

Run locally following FUTABA-SETUP.md. Public CI tests cover the generator, AnimationTree controller, Godot engine, and fallback build; visuals of the proprietary model remain unverified on Android.
