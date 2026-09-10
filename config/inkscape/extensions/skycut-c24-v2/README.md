# Skycut C24 — Document-faithful HPGL exporter

This is a dedicated Inkscape output extension for the Skycut C24.

## What it fixes

1. **C24 90° orientation** — the generated HPGL is pre-rotated 90° counter-clockwise to cancel the C24's observed 90° clockwise plotting orientation.
2. **Document placement** — the exporter disables Inkscape HPGL auto-alignment, centering, tool offset, overcut and precut by default. Coordinates remain tied to the Inkscape document rather than being cropped to the drawing's bounding box.
3. **C24 PD compatibility** — batched `PDx1,y1,x2,y2,...;` commands are expanded into `PDx1,y1;PDx2,y2;...;`, which was experimentally verified with the C24.

## Important physical limitation

A `.plt` file cannot detect where material was physically placed on the C24 bed. The exporter can preserve the document coordinate system, but the machine's origin still has to correspond to the intended material origin. If the material is placed at a different physical origin, the same PLT will move with that origin; it cannot automatically discover the material edge.

## Install

Copy the four files into Inkscape's user extension directory, normally:

`~/.config/inkscape/extensions/`

Then completely restart Inkscape.

The exporter appears as:

**Skycut C24 — Document-faithful HPGL**

and outputs `.plt` files.

## Recommended first test

Use a small document with a rectangle or circle deliberately offset from the page edges. Export it and verify that:

- the final cut has the same orientation as the document;
- the object's offset from the document origin is preserved;
- there is no automatic top/bottom drawing-bounds offset;
- the C24 still cuts the geometry correctly.

Force and speed are left at zero in the file by default; use the C24's own controls for those values.


## Return-to-start behavior

The exporter records the first actual PU/PD coordinate emitted by Inkscape. After
all cutting paths are complete, it lifts the pen and moves back to that same
physical C24 coordinate. The final `PU` is therefore not a hard-coded machine
origin move. This preserves the cut start position and makes repeated jobs more
predictable.
