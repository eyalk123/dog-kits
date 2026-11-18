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

/* [Bite] */
bite = true;              // a bite taken out of one lobe
bite_corner = [1, 1];     // which lobe: [x, y] signs, [1, 1] = top right
bite_angle = 38;          // where on the lobe, degrees from horizontal
bites = 3;                // number of round tooth marks
bite_r = 3.6;             // radius of each mark
bite_spacing = 1.45;      // distance between marks, in radii (< 2 so they overlap)
bite_depth = 1.15;       // how far each mark cuts in, in radii
bite_curve = -0.1;       // outer marks sit this much shallower, so the row follows a jaw
min_feature = 0.8;        // slivers thinner than about this are removed

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

module plain_bone_2d() {
    offset(delta = -fillet) offset(r = fillet)
    union() {
        square([2 * lobe_x, bar_h], center = true);
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx * lobe_x, sy * lobe_y]) circle(lobe_r);
    }
}

// A bite: a row of overlapping round marks along the lobe's edge, with
// pointed cusps between them, like a cartoon bite out of a cookie.
bite_dir = [bite_corner[0] * cos(bite_angle), bite_corner[1] * sin(bite_angle)];
bite_tan = [-bite_dir[1], bite_dir[0]];
bite_edge = [bite_corner[0] * lobe_x, bite_corner[1] * lobe_y] + bite_dir * lobe_r;
module bite_2d(grow = 0) {
    for (i = [0 : bites - 1]) {
        k = i - (bites - 1) / 2;
        c = bite_edge
            + bite_dir * bite_r * (1 - bite_depth + bite_curve * k * k)
            + bite_tan * k * bite_r * bite_spacing;
        translate(c) circle(bite_r + grow, $fn = 64);
    }
}

module bone_2d() {
    if (bite)
        offset(r = min_feature / 2) offset(r = -min_feature / 2)   // drop thin slivers
        difference() { plain_bone_2d(); bite_2d(); }
    else plain_bone_2d();
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

// The outline follows the plain bone and is simply cut where the bite took
// a piece, as if the line was bitten off with the rest.
module outline_2d() {
    difference() {
        offset(r = -outline_gap) plain_bone_2d();
        offset(r = -inset) plain_bone_2d();
        if (bite) bite_2d(outline_gap);
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
