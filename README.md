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
- 45 × 24 × 3.2 mm by default, with a 4.5 mm ring hole.
- The front has the name and the back has a phone number (mirrored, so it reads correctly when the tag is turned over).
- Both are **inlaid flush, 0.6 mm deep (3 layers at 0.2 mm)**, in a second colour. They don't wear like raised text.
- Hebrew is shaped right to left automatically. `build.py` measures the rendered text and picks the largest size that fits.

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
Open Sans (bundled in `assets/fonts/`) is under the SIL Open Font License, so it may be used in commercial products. See `assets/fonts/OFL-OpenSans.txt`.
