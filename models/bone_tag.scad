// Bone-shaped dog tag — parametric, two colours.
//
// Front: the dog's name, inlaid flush in a second colour.
// Back:  optional text (phone number), mirrored, inlaid flush.
//
// Render one part at a time (part = "base" or "inlay") and load both
// STLs into Bambu Studio / Orca as parts of one object, one filament each.
//
// Example:
//   openscad -o base.stl  -D 'name="רקסי"' -D 'part="base"'  models/bone_tag.scad
//   openscad -o inlay.stl -D 'name="רקסי"' -D 'part="inlay"' models/bone_tag.scad

use <../assets/fonts/OpenSans-ExtraBold.ttf>

/* [Text] */
name = "רקסי";
back_text = "050-1234567";

/* [Size, mm] */
length = 45;
width = 24;
thickness = 3.2;
hole_d = 4.5;

/* [Text style] */
font = "Open Sans ExtraBold";
max_text_height = 9;      // cap on the name's size, mm
back_text_height = 4.2;   // cap on the back text's size, mm
name_size = 0;            // exact size from scripts/build.py; 0 = rough estimate
back_size = 0;
inlay_depth = 0.6;        // 3 layers at 0.2 mm
char_width = 0.9;         // rough glyph width / size, used only when sizes are 0

/* [Output] */
part = "all";             // "base" | "inlay" | "all" | "probe_name" | "probe_back"

$fn = 96;

// ---- derived geometry ----
lobe_r = width * 0.29;
bar_h  = width * 0.56;
lobe_x = length / 2 - lobe_r;
lobe_y = width / 2 - lobe_r;
fillet = 1.6;

hole_x = -lobe_x;
margin = 1.3;

// Area the name may occupy: from just right of the hole to the right end.
text_x0 = hole_x + hole_d / 2 + margin;
text_x1 = length / 2 - 2.2;
text_w  = text_x1 - text_x0;
text_h  = bar_h - 2 * margin;
text_cx = (text_x0 + text_x1) / 2;

// Back text gets the full bar, minus the hole.
back_w = text_w;

function fit_size(s, avail_w, avail_h, cap) =
    min(cap, avail_h / 0.95, avail_w / (char_width * max(len(s), 1)));

module bone_2d() {
    offset(delta = -fillet) offset(r = fillet)
    union() {
        square([2 * lobe_x, bar_h], center = true);
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx * lobe_x, sy * lobe_y]) circle(lobe_r);
    }
}

module name_2d() {
    translate([text_cx, 0])
        text(name, size = name_size > 0 ? name_size
                                : fit_size(name, text_w, text_h, max_text_height),
             font = font, halign = "center", valign = "center");
}

// Mirrored so it reads correctly when the tag is flipped over.
module back_2d() {
    if (len(back_text) > 0)
        translate([text_cx, 0]) mirror([1, 0])
            text(back_text, size = back_size > 0 ? back_size
                                     : fit_size(back_text, back_w, text_h, back_text_height),
                 font = font, halign = "center", valign = "center");
}

module hole_2d() { translate([hole_x, 0]) circle(d = hole_d); }

module front_inlay() {
    translate([0, 0, thickness - inlay_depth])
        linear_extrude(inlay_depth) name_2d();
}

module back_inlay() {
    linear_extrude(inlay_depth) back_2d();
}

module base() {
    difference() {
        linear_extrude(thickness) difference() { bone_2d(); hole_2d(); }
        translate([0, 0, thickness - inlay_depth])
            linear_extrude(inlay_depth + 0.01) name_2d();
        translate([0, 0, -0.01])
            linear_extrude(inlay_depth + 0.01) back_2d();
    }
}

module inlay() { front_inlay(); back_inlay(); }

// 2D text at size 10, used by scripts/build.py to measure and fit the text.
// The boxes the text must fit in: [width, height, max size] for front and back.
if (part == "probe_name" || part == "probe_back")
    echo(FIT = [[text_w, text_h, max_text_height], [back_w, text_h, back_text_height]]);
if (part == "probe_name") text(name, size = 10, font = font, halign = "center", valign = "center");
if (part == "probe_back") text(back_text, size = 10, font = font, halign = "center", valign = "center");

if (part == "base")  base();
if (part == "inlay") inlay();
if (part == "all")  { color("#f2efe8") base(); color("#1f6f8b") inlay(); }
