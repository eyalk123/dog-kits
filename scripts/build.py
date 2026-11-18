#!/usr/bin/env python3
"""Render every variant in variants.json to STL files plus a manifest for the viewer.

For each variant:
  1. Measures the name and back text at size 10 (OpenSCAD's own rendering, so
     Hebrew shaping and the real font metrics are taken into account) and picks
     the largest size that fits the box the model reports.
  2. Renders each printable part (base, inlay) to <out>/<id>-<part>.stl.
  3. Writes <out>/manifest.json, which viewer/index.html reads.

Usage:
  python3 scripts/build.py                 # all variants -> viewer/out
  python3 scripts/build.py --only bone-luna
  python3 scripts/build.py --out /tmp/out
"""
import argparse
import datetime as dt
import json
import os
import re
import struct
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PARTS = ["base", "inlay"]
PROBE_SIZE = 10.0


def scad_defs(params):
    args = []
    for key, value in params.items():
        if isinstance(value, str):
            literal = json.dumps(value, ensure_ascii=False)
        elif isinstance(value, bool):
            literal = "true" if value else "false"
        else:
            literal = repr(value)
        args += ["-D", f"{key}={literal}"]
    return args


def openscad(model, out_file, params):
    cmd = ["openscad", "-o", str(out_file), *scad_defs(params), str(ROOT / "models" / f"{model}.scad")]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0 or "ERROR" in res.stderr:
        sys.exit(f"openscad failed for {out_file.name}:\n{res.stderr}")
    return res.stderr


def to_binary_stl(path):
    """OpenSCAD 2021 writes ASCII STL; binary is ~5x smaller and loads faster."""
    data = path.read_text()
    if not data.lstrip().startswith("solid"):
        return
    floats = re.findall(r"vertex\s+(\S+)\s+(\S+)\s+(\S+)", data)
    normals = re.findall(r"facet normal\s+(\S+)\s+(\S+)\s+(\S+)", data)
    out = bytearray(b"dog-kits".ljust(80, b" "))
    out += struct.pack("<I", len(normals))
    for i, n in enumerate(normals):
        out += struct.pack("<3f", *map(float, n))
        for v in floats[i * 3:i * 3 + 3]:
            out += struct.pack("<3f", *map(float, v))
        out += b"\0\0"
    path.write_bytes(bytes(out))


def svg_bbox(svg_text):
    xs, ys = [], []
    for d in re.findall(r'\sd="([^"]+)"', svg_text):
        nums = [float(n) for n in re.findall(r"-?\d+(?:\.\d+)?(?:e-?\d+)?", d)]
        xs += nums[0::2]
        ys += nums[1::2]
    if not xs:
        return None
    return max(xs) - min(xs), max(ys) - min(ys)


def fit_text(model, params, which):
    """Return the text size that fills the model's box for 'name' or 'back'."""
    with tempfile.TemporaryDirectory() as tmp:
        svg = Path(tmp) / "probe.svg"
        log = openscad(model, svg, {**params, "part": f"probe_{which}"})
        bbox = svg_bbox(svg.read_text()) if svg.exists() else None
    m = re.search(r"FIT = \[\[([^\]]+)\], \[([^\]]+)\]\]", log)
    if not m or not bbox:
        return 0
    box = [float(v) for v in m.group(1 if which == "name" else 2).split(",")]
    avail_w, avail_h, cap = box
    w, h = bbox
    size = min(cap, PROBE_SIZE * avail_w / w, PROBE_SIZE * avail_h / h)
    return round(int(size * 20) / 20, 2)  # round down to 0.05 mm


def build_variant(v, out_dir):
    model, params = v["model"], dict(v["params"])
    sizes = {"name_size": fit_text(model, params, "name")}
    if params.get("back_text", ""):
        sizes["back_size"] = fit_text(model, params, "back")
    files = {}
    for part in PARTS:
        name = f"{v['id']}-{part}.stl"
        openscad(model, out_dir / name, {**params, **sizes, "part": part})
        to_binary_stl(out_dir / name)
        files[part] = name
    print(f"  {v['id']}: name {sizes['name_size']} mm, back {sizes.get('back_size', '-')} mm")
    return {**v, "sizes": sizes, "files": files}


def git_commit():
    sha = os.environ.get("GITHUB_SHA")
    if sha:
        return sha[:7]
    try:
        return subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=ROOT,
                              capture_output=True, text=True).stdout.strip() or None
    except OSError:
        return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(ROOT / "viewer" / "out"))
    ap.add_argument("--only", help="build a single variant id")
    args = ap.parse_args()

    variants = json.loads((ROOT / "variants.json").read_text(encoding="utf-8"))
    if args.only:
        variants = [v for v in variants if v["id"] == args.only]
        if not variants:
            sys.exit(f"no variant with id {args.only}")

    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    print(f"Building {len(variants)} variant(s) -> {out_dir}")
    with ThreadPoolExecutor(max_workers=os.cpu_count() or 2) as pool:
        built = list(pool.map(lambda v: build_variant(v, out_dir), variants))

    manifest = {
        "generated_at": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
        "commit": git_commit(),
        "variants": built,
    }
    (out_dir / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    print("Wrote manifest.json")


if __name__ == "__main__":
    main()
