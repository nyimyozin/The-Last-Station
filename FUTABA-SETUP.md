# Futaba-chan animation prototype (experimental branch)

This is an **unmerged experiment**, not an official game release. The branch adds a native Godot skeletal AnimationTree and a local-only VRM-to-GLB converter, without putting the third-party avatar on public GitHub.

## Build and test with your own licensed model

1. Download your copy of **ふたばちゃん ver1.01** from its creator. Extract the original `.vrm` file from the ZIP.
2. Check out the `feat/futaba-skeletal-animation` branch (not `main`) and open a terminal in the project root.
3. Generate the private animation asset:

   ```sh
   python3 tools/prepare_futaba.py "/path/to/ふたばちゃん(VRM0.0).vrm" art/character/futaba_animated.glb
   ```

4. Open `project.godot` in **Godot 4.5.1**, allow the new GLB to import, and run the game. It should find the imported `AnimationPlayer`, attach a six-state `AnimationTree` and use the existing movement, jumping, camera and save systems.
5. Remove `art/character/futaba_animated.glb` to test the original schoolgirl fallback.

The local GLB includes the author's original embedded textures and six original **in-place** skeletal animation clips: `idle` (breathing), `walk`, `run`, `jump`, `fall` and `land`. The AnimationTree crossfades between states based on character speed and grounded state. It does not yet implement VRM spring-bone hair simulation, detailed facial expressions, root-motion correction, or motion-captured animation.

You can run the generator's binary/glTF invariants without the licensed avatar:

```sh
python3 tools/prepare_futaba.py --self-test
```

## Licensing and publishing

The ZIP's `Readme.txt` allows modification, commercial use and usage in games/apps, but **prohibits redistribution of the VRM/model and modified copies** without permission. Do not commit `.vrm`, `.vroid` or `futaba_animated.glb` into this public repository or attach them to public releases. The generated asset is excluded in `.gitignore`. The repository's normal CI build intentionally uses the existing schoolgirl fallback because it does not have the licensed asset.

If you want to distribute an APK with Futaba included publicly, clarify permitted embedding/redistribution conditions with the model's creator first. Keep artist attribution in the eventual game's credits as a courtesy (the Readme requests it although not mandatory).

## Current verification limits

The Python converter has been run against the provided VRM file and writes a well-formed GLB containing six animation clips and the original skeleton. Godot editor/render and Android device tests with the private asset are still required to confirm import compatibility, animation playback, face orientation, clipping, shading and mobile performance. Please treat this as a **prototype**, not a polished/verified playable release.

Nothing in this branch changes `main`; do not merge until rendering and motion quality are reviewed.
