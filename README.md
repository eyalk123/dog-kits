# dog-kits

Parametric 3D-printable products for personalised dog kits (name tags, bowl stands and more),
plus a browser viewer for reviewing every model.

## Layout

| Path | What it is |
|---|---|
| `models/` | OpenSCAD models. Each one takes parameters such as `name`, `back_text` and sizes. |
| `assets/fonts/` | Fonts the models use, bundled so every machine renders the same text. |
| `assets/breeds/` | (coming) SVG line drawings of dog breeds. |
| `variants.json` | The examples the viewer shows: model, parameters and filament colours. |
| `scripts/build.py` | Renders every variant to STL and writes `viewer/out/manifest.json`. |
| `viewer/` | The 3D viewer (three.js). It reads `out/manifest.json`. |

## Models

### `bone_tag`: bone-shaped name tag
- 45 × 26.4 × 3.6 mm by default. A tab on top holds a 4 mm ring hole, so the whole bone is free for the name.
- Front: the name, centred, plus an outline 1.4 mm in from the edge. Both are **raised 0.6 mm (3 layers at 0.2 mm)** in a second colour.
- Back: phone number, mirrored and **inlaid flush**, because it rubs against the dog.
- **Bite** (`bite = true` by default): a row of overlapping round tooth marks cut from one lobe, like a cartoon bite out of a cookie.
  The outline is cut where the bite took it. `bite_corner` picks the lobe (`[1, 1]` = top right), `bite_angle` the spot on it,
  and `bites`, `bite_r`, `bite_spacing`, `bite_depth` and `bite_curve` set the marks. Slivers under `min_feature` (0.8 mm) are removed.
- Fonts (`font` parameter): `Rubik:style=Medium` (default), `Heebo:style=Medium`, `DK Round:style=Regular`.
- Hebrew is shaped right to left automatically. `build.py` measures the rendered text and picks the largest size that fits inside the outline, up to `max_text_height` (6.5 mm).

## Working locally

```bash
sudo apt install openscad          # macOS: brew install --cask openscad
python3 scripts/build.py           # all variants -> viewer/out/
python3 scripts/build.py --only bone-luna
cd viewer && python3 -m http.server 8000   # open http://localhost:8000
```

## Printing a two-colour tag (Bambu Studio / Orca)
1. Import `<id>-base.stl` and `<id>-inlay.stl` together, and answer **Yes** when asked to load them as a single object with multiple parts.
2. Assign one filament to the base and another to the inlay.
3. Use a 0.2 mm layer height so the inlay is exactly 3 layers.

## Publishing the viewer
Every push to `main` runs `.github/workflows/pages.yml`, which renders the models and publishes the viewer to GitHub Pages.
One-time setup: **Settings → Pages → Source: GitHub Actions**.

## Licences
All bundled fonts are under the SIL Open Font License (OFL-*.txt in `assets/fonts/`), which allows commercial products.
Each file merges the Hebrew and Latin subsets of the original font into one TTF.
"DK Round" is Varela Round under a different name: the OFL forbids keeping a Reserved Font Name on a modified font.
