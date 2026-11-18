#!/usr/bin/env python3
"""Package viewer/ + viewer/out/ for hosts that refuse .stl files (e.g. a Claude artifact).

Each variant's STL parts are base64-encoded into out/<id>.json, and the manifest
points at "<id>.json#<part>"; viewer/index.html understands both forms.

Usage: python3 scripts/build.py && python3 scripts/bundle_artifact.py [--dest dist/artifact]
"""
import argparse
import base64
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default=str(ROOT / "viewer"))
    ap.add_argument("--dest", default=str(ROOT / "dist" / "artifact"))
    args = ap.parse_args()
    src, dest = Path(args.src), Path(args.dest)

    shutil.rmtree(dest, ignore_errors=True)
    (dest / "out").mkdir(parents=True)
    shutil.copy(src / "index.html", dest / "index.html")

    manifest = json.loads((src / "out" / "manifest.json").read_text(encoding="utf-8"))
    for v in manifest["variants"]:
        bundle = {part: base64.b64encode((src / "out" / f).read_bytes()).decode()
                  for part, f in v["files"].items()}
        (dest / "out" / f"{v['id']}.json").write_text(json.dumps(bundle))
        v["files"] = {part: f"{v['id']}.json#{part}" for part in bundle}
    (dest / "out" / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Bundled {len(manifest['variants'])} variant(s) -> {dest}")


if __name__ == "__main__":
    main()
