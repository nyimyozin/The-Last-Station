#!/usr/bin/env python3
"""Compile locally owned VRM0 humanoid into animated glTF for Godot.

The artist forbids redistribution of this avatar. Generated .glb must stay
local and is gitignored. Python standard library only.
"""
import argparse
import json
import math
import struct
from pathlib import Path

BONES = {
    "hips", "spine", "chest", "upperChest", "neck", "head",
    "leftShoulder", "rightShoulder", "leftUpperArm", "rightUpperArm",
    "leftLowerArm", "rightLowerArm", "leftHand", "rightHand",
    "leftUpperLeg", "rightUpperLeg", "leftLowerLeg", "rightLowerLeg",
    "leftFoot", "rightFoot", "leftToes", "rightToes",
}
DURATIONS = {"idle": 2.4, "walk": 0.8, "run": 0.58, "jump": 0.42, "fall": 0.5, "land": 0.34}
FPS = 30


def quat(x=0.0, y=0.0, z=0.0):
    """XYZ Euler radians -> normalized glTF xyzw quaternion."""
    cx, sx = math.cos(x / 2), math.sin(x / 2)
    cy, sy = math.cos(y / 2), math.sin(y / 2)
    cz, sz = math.cos(z / 2), math.sin(z / 2)
    return (sx * cy * cz - cx * sy * sz,
            cx * sy * cz + sx * cy * sz,
            cx * cy * sz - sx * sy * cz,
            cx * cy * cz + sx * sy * sz)


def smooth(a, b, t):
    x = max(0.0, min(1.0, (t - a) / (b - a)))
    return x * x * (3 - 2 * x)


def pose(clip, t):
    """In-place stylized locomotion based on the VRoid humanoid rest pose."""
    cycle = t / DURATIONS[clip]
    wave = math.sin(cycle * 2 * math.pi)
    bounce = 0.0
    arm = leg = knee = 0.0
    if clip in ("walk", "run"):
        running = clip == "run"
        leg = (0.73 if running else 0.44) * wave
        arm = (0.62 if running else 0.36) * wave
        knee = 0.12 if not running else 0.22
        bounce = (0.034 if running else 0.016) * (1 - math.cos(cycle * 4 * math.pi)) / 2
    elif clip == "idle":
        bounce = 0.006 * math.sin(cycle * 2 * math.pi)
    elif clip == "jump":
        anticipation = 1.0 - smooth(0.00, 0.19, cycle)
        airborne = smooth(0.15, 0.52, cycle)
        knee = 0.44 * anticipation + 0.20 * airborne
        bounce = -0.07 * anticipation + 0.025 * airborne
        arm = 0.21 * airborne
    elif clip == "fall":
        knee = 0.28
        arm = 0.12
    elif clip == "land":
        landing = 1.0 - smooth(0.08, 1.0, cycle)
        knee = 0.46 * landing
        bounce = -0.065 * landing
        arm = 0.14 * landing
    rotations = {
        "spine": quat(x=0.018 if clip == "run" else 0.005),
        "chest": quat(y=0.02 * wave if clip in ("walk", "run") else 0),
        "head": quat(x=-0.012 * wave if clip in ("walk", "run") else 0),
    }
    for side in ("left", "right"):
        s = -1 if side == "left" else 1
        rotations[side + "UpperArm"] = quat(x=s * arm, z=-s * (1.24 if clip != "run" else 1.15))
        rotations[side + "LowerArm"] = quat(x=-0.10, z=-s * 0.12)
        rotations[side + "UpperLeg"] = quat(x=-s * leg - knee * 0.38)
        stagger = max(0.0, s * wave)
        rotations[side + "LowerLeg"] = quat(x=knee + stagger * (0.64 if clip == "run" else 0.31))
        rotations[side + "Foot"] = quat(x=-0.18 * stagger - knee * 0.2)
    return rotations, bounce


def decode_glb(data):
    magic, version, length = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF" or version != 2 or length != len(data):
        raise ValueError("Expected valid VRM0/GLB v2 file")
    chunks = []
    pos = 12
    while pos < len(data):
        size, typ = struct.unpack_from("<I4s", data, pos)
        pos += 8
        if pos + size > len(data):
            raise ValueError("Truncated GLB chunk")
        chunks.append((typ, data[pos:pos + size]))
        pos += size
    if len(chunks) != 2 or chunks[0][0] != b"JSON" or chunks[1][0] != b"BIN\x00":
        raise ValueError("Expected JSON + embedded binary GLB chunks")
    return json.loads(chunks[0][1]), bytearray(chunks[1][1])


def encode_glb(data, binary):
    j = json.dumps(data, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    j += b" " * (-len(j) % 4)
    binary += b"\x00" * (-len(binary) % 4)
    return (struct.pack("<4sII", b"glTF", 2, 12 + 8 + len(j) + 8 + len(binary))
            + struct.pack("<I4s", len(j), b"JSON") + j
            + struct.pack("<I4s", len(binary), b"BIN\x00") + binary)


def append_accessor(model, binary, vectors, width):
    binary += b"\x00" * (-len(binary) % 4)
    offset = len(binary)
    for v in vectors:
        binary.extend(struct.pack("<" + "f" * width, *v))
    vi = len(model["bufferViews"])
    model["bufferViews"].append({"buffer": 0, "byteOffset": offset,
                                  "byteLength": len(binary) - offset})
    ai = len(model["accessors"])
    rec = {"bufferView": vi, "componentType": 5126, "count": len(vectors),
           "type": "VEC4" if width == 4 else "SCALAR" if width == 1 else "VEC3"}
    if width == 1:
        rec["min"] = [min(v[0] for v in vectors)]
        rec["max"] = [max(v[0] for v in vectors)]
    model["accessors"].append(rec)
    return ai


def animate(original):
    model, binary = decode_glb(original)
    vrm = model.get("extensions", {}).get("VRM")
    if not vrm or "humanoid" not in vrm:
        raise ValueError("Expected VRM 0.x humanoid, not VRM 1.x")
    bones = {b["bone"]: b["node"] for b in vrm["humanoid"]["humanBones"]}
    missing = BONES - bones.keys()
    if missing:
        raise ValueError("Missing humanoid joints: " + ", ".join(sorted(missing)))
    del model["extensions"]["VRM"]
    if not model["extensions"]:
        del model["extensions"]
    for key in ("extensionsUsed", "extensionsRequired"):
        model[key] = [v for v in model.get(key, []) if v != "VRM"]
        if not model[key]:
            del model[key]
    model["asset"]["generator"] = "The Last Station Futaba motion compiler"
    model["animations"] = []
    for clip, duration in DURATIONS.items():
        steps = round(duration * FPS)
        tid = append_accessor(model, binary, [(i * duration / steps,) for i in range(steps + 1)], 1)
        frames = [pose(clip, i / steps) for i in range(steps + 1)]
        anim = {"name": clip, "samplers": [], "channels": []}
        for name in sorted(BONES):
            values = [p[0][name] for p in frames if name in p[0]]
            if not values:
                continue
            ai = append_accessor(model, binary, values, 4)
            si = len(anim["samplers"])
            anim["samplers"].append({"input": tid, "output": ai, "interpolation": "LINEAR"})
            anim["channels"].append({"sampler": si,
                                     "target": {"node": bones[name], "path": "rotation"}})
        hips = bones["hips"]
        base = model["nodes"][hips].get("translation", [0, 0, 0])
        values = [(base[0], base[1] + p[1], base[2]) for p in frames]
        ai = append_accessor(model, binary, values, 3)
        si = len(anim["samplers"])
        anim["samplers"].append({"input": tid, "output": ai, "interpolation": "LINEAR"})
        anim["channels"].append({"sampler": si,
                                 "target": {"node": hips, "path": "translation"}})
        model["animations"].append(anim)
    model["buffers"][0]["byteLength"] = len(binary)
    return encode_glb(model, binary)


def self_test():
    names = sorted(BONES)
    tiny = {"asset": {"version": "2.0"}, "nodes": [{"name": n} for n in names],
            "scenes": [{"nodes": [0]}], "scene": 0,
            "bufferViews": [], "accessors": [], "buffers": [{"byteLength": 0}],
            "extensions": {"VRM": {"humanoid": {"humanBones": [
                {"bone": name, "node": i} for i, name in enumerate(names)]}}},
            "extensionsUsed": ["VRM"]}
    converted, buf = decode_glb(animate(encode_glb(tiny, bytearray())))
    assert [a["name"] for a in converted["animations"]] == list(DURATIONS)
    assert "VRM" not in converted.get("extensionsUsed", [])
    assert converted["buffers"][0]["byteLength"] <= len(buf)
    for clip in converted["animations"]:
        assert len(clip["channels"]) >= 14, clip["name"]
        for channel in clip["channels"]:
            assert 0 <= channel["target"]["node"] < len(names)
    for clip in DURATIONS:
        rotations, dy = pose(clip, DURATIONS[clip] / 3)
        assert -0.09 < dy < 0.1
        for q in rotations.values():
            assert abs(sum(v*v for v in q) - 1.0) < 1e-5
    print("FUTABA ANIMATION GENERATOR PASS", ", ".join(DURATIONS))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path, nargs="?", help="User's local .vrm file")
    parser.add_argument("output", type=Path, nargs="?", default=Path("art/character/futaba_animated.glb"))
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return
    if args.input is None:
        parser.error("Provide your downloaded VRM avatar")
    output = animate(args.input.read_bytes())
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(output)
    print(f"Wrote {args.output}: {len(output):,} bytes with {len(DURATIONS)} clips")


if __name__ == "__main__":
    main()
