// Bone-shaped dog tag — parametric, two colours.
//
// Front: the dog's name and an outline that follows the bone's edge, both
//        raised above the surface in a second colour.
// Back:  optional text (phone number), mirrored, inlaid flush (it rubs
//        against the dog, so it stays flat).
// A tab with the ring hole sits on top of the bone, so the whole bone is
// free for the name, centred.
//
// Render one part at a time (part = "base" or "inlay") and load both STLs
// into Bambu Studio / Orca as parts of one object, one filament each.
//
//   openscad -o base.stl  -D 'name="רקסי"' -D 'part="base"'  models/bone_tag.scad
//   openscad -o inlay.stl -D 'name="רקסי"' -D 'part="inlay"' models/bone_tag.scad

use <../assets/fonts/Rubik-Medium.ttf>
use <../assets/fonts/Heebo-Medium.ttf>
use <../assets/fonts/DKRound-Regular.ttf>

/* [Text] */
name = "רקסי";
back_text = "050-1234567";

/* [Size, mm] */
length = 45;
width = 24;
thickness = 3.0;

/* [Ring tab] */
tab_d = 9;                // outer diameter of the tab
tab_rise = 3.2;           // how far the tab's centre sits above the bone's top edge
hole_d = 4;

/* [Front decoration] */
font = "Rubik:style=Medium";   // also: "Heebo:style=Medium", "DK Round:style=Regular"
relief = 0.6;             // how far the name and outline stand out (3 layers at 0.2 mm)
outline_gap = 1.4;        // distance from the bone's edge to the outline
outline_w = 0.9;          // outline line width (>= 2 extrusion widths)
text_margin = 1.2;        // space between the outline and the name
max_text_height = 6.5;    // cap on the name's size, mm
name_size = 0;            // exact size from scripts/build.py; 0 = rough estimate

/* [Back] */
back_font = "Rubik:style=Medium";
back_text_height = 4;
inlay_depth = 0.6;
back_size = 0;

char_width = 0.85;        // rough glyph width / size, only used when sizes are 0

/* [Output] */
part = "all";             // "base" | "inlay" | "all" | "probe_name" | "probe_back"

$fn = 96;

// ---- derived geometry ----
lobe_r = width * 0.29;
bar_h  = width * 0.56;
lobe_x = length / 2 - lobe_r;
lobe_y = width / 2 - lobe_r;
fillet = 2.4;

tab_y = bar_h / 2 + tab_rise;
inset = outline_gap + outline_w;

// The name sits in the bar, inside the outline, centred.
text_w = 2 * lobe_x - 2 * text_margin;
text_h = bar_h - 2 * inset - 2 * text_margin;

// The back has no outline, only a little margin.
back_w = 2 * lobe_x;
back_h = bar_h - 2 * 1.2;

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

// Tab joined to the bar with a smooth neck.
module tab_2d() {
    offset(delta = -fillet) offset(r = fillet)
    union() {
        hull() {
            translate([0, tab_y]) circle(d = tab_d);
            translate([0, bar_h / 2 - 1]) square([tab_d, 2], center = true);
        }
        bone_2d();
    }
}

module outline_2d() {
    difference() {
        offset(r = -outline_gap) bone_2d();
        offset(r = -inset) bone_2d();
    }
}

module name_2d() {
    text(name, size = name_size > 0 ? name_size : fit_size(name, text_w, text_h, max_text_height),
         font = font, halign = "center", valign = "center");
}

// Mirrored so it reads correctly when the tag is turned over sideways.
module back_2d() {
    if (len(back_text) > 0)
        mirror([1, 0])
            text(back_text, size = back_size > 0 ? back_size
                                 : fit_size(back_text, back_w, back_h, back_text_height),
                 font = back_font, halign = "center", valign = "center");
}

module base() {
    difference() {
        linear_extrude(thickness) difference() {
            tab_2d();
            translate([0, tab_y]) circle(d = hole_d);
        }
        translate([0, 0, -0.01]) linear_extrude(inlay_depth + 0.01) back_2d();
    }
}

module inlay() {
    translate([0, 0, thickness]) linear_extrude(relief) union() { name_2d(); outline_2d(); }
    linear_extrude(inlay_depth) back_2d();
}

// 2D text at size 10, used by scripts/build.py to measure and fit the text.
// FIT = the boxes the text must fit in: [width, height, max size], front then back.
if (part == "probe_name" || part == "probe_back")
    echo(FIT = [[text_w, text_h, max_text_height], [back_w, back_h, back_text_height]]);
if (part == "probe_name") text(name, size = 10, font = font, halign = "center", valign = "center");
if (part == "probe_back") text(back_text, size = 10, font = back_font, halign = "center", valign = "center");

if (part == "base")  base();
if (part == "inlay") inlay();
if (part == "all")  { color("#f2efe8") base(); color("#1f6f8b") inlay(); }
