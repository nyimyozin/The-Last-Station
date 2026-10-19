"""Verify that original glTF palms and thumbs have anatomical hand orientation."""
import base64
import json
import struct
from pathlib import Path

model = json.loads((Path(__file__).resolve().parents[1] / "art/character/schoolgirl.gltf").read_text())
data = base64.b64decode(model["buffers"][0]["uri"].partition(",")[2])

for name, side in (("LeftElbow", -1), ("RightElbow", 1)):
    part = next(n for n in model["nodes"] if n["name"] == name)
    mesh = model["meshes"][part["mesh"]]
    skin = next(p for p in mesh["primitives"] if model["materials"][p["material"]]["name"] == "skin")
    accessor = model["accessors"][skin["attributes"]["POSITION"]]
    assert accessor["count"] == 624, f"{name}: unexpected palm/thumb vertex layout"
    start = model["bufferViews"][accessor["bufferView"]]["byteOffset"] + accessor.get("byteOffset", 0)
    coords = [struct.unpack_from("<fff", data, start + 12*i) for i in range(accessor["count"])]
    palm, thumb = coords[:312], coords[312:]
    palm_x = sum(v[0] for v in palm) / len(palm)
    thumb_x = sum(v[0] for v in thumb) / len(thumb)
    palm_z = sum(v[2] for v in palm) / len(palm)
    thumb_z = sum(v[2] for v in thumb) / len(thumb)
    assert side * (thumb_x - palm_x) > 0.025, f"{name}: thumb points toward torso"
    assert thumb_z < palm_z - 0.005, f"{name}: thumb should be slightly forward"
    print(f"{name}: lateral thumb={thumb_x:+.3f} m, forward={thumb_z:+.3f} m PASS")

print("HAND ORIENTATION PASS")
