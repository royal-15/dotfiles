#!/usr/bin/env python3
"""Skycut C24 HPGL exporter for Inkscape.

This exporter is intentionally based on Inkscape's HPGL encoder, but applies
three C24-specific rules:

1. Preserve the Inkscape page coordinate system instead of auto-aligning the
   drawing to its bounding box.
2. Pre-rotate the generated HPGL 90 degrees counter-clockwise. The C24's
   observed machine coordinate system rotates the result 90 degrees clockwise,
   so this cancels the machine rotation and restores the document orientation.
3. Split batched PD coordinate lists into one PD command per point because the
   C24 firmware accepts the resulting form more reliably.

The default geometry modifiers that change the document position (tool offset,
overcut, precut, centering, auto-align) are disabled. This makes the default
output a document-faithful export rather than a drawing-bounds export.
"""

from __future__ import print_function

import re

import inkex
from inkex.localization import inkex_gettext as _

import hpgl_encoder


_PD_RE = re.compile(r"PD([^;]*);", re.IGNORECASE)
_COORD_RE = re.compile(r"[-+]?\d+(?:\.\d+)?")


def _first_coordinate(hpgl):
    """Return the first PU/PD coordinate pair emitted by the encoder."""
    command_re = re.compile(r"(?:PU|PD)([^;]*);", re.IGNORECASE)
    for match in command_re.finditer(hpgl):
        numbers = _COORD_RE.findall(match.group(1))
        if len(numbers) >= 2:
            return int(round(float(numbers[0]))), int(round(float(numbers[1])))
    return None


def split_pd_commands(hpgl):
    """Expand PDx1,y1,x2,y2,...; into individual PD commands."""

    def replace(match):
        body = match.group(1)
        numbers = _COORD_RE.findall(body)

        if not numbers or len(numbers) % 2:
            return match.group(0)

        return "".join(
            "PD{},{};".format(numbers[i], numbers[i + 1])
            for i in range(0, len(numbers), 2)
        )

    return _PD_RE.sub(replace, hpgl)


def transform_c24_coordinates(hpgl, page_width, page_height):
    """Pre-rotate HPGL 90 degrees CCW to cancel the C24's observed CW rotation.

    Input coordinates are normal Inkscape HPGL coordinates.

        X = page_height - y
        Y = x

    This deliberately transforms every PU/PD coordinate while preserving the
    command order. No bounding-box translation is applied, because the user's
    document coordinate system must remain authoritative.
    """
    command_re = re.compile(r"(PU|PD)([^;]*);", re.IGNORECASE)

    def replace(match):
        command = match.group(1).upper()
        body = match.group(2)
        numbers = _COORD_RE.findall(body)

        if not numbers or len(numbers) % 2:
            return match.group(0)

        result = []
        for i in range(0, len(numbers), 2):
            x = float(numbers[i])
            y = float(numbers[i + 1])
            new_x = page_height - y
            new_y = x
            result.append("{}{},{};".format(
                command, int(round(new_x)), int(round(new_y))
            ))

        return "".join(result)

    return command_re.sub(replace, hpgl)


class SkycutC24HpglOutput(inkex.OutputExtension):
    """Export document-faithful HPGL for the Skycut C24."""

    def add_arguments(self, pars):
        pars.add_argument("--tab")
        pars.add_argument(
            "--resolutionX", type=float, default=1016.0,
            help="Resolution X (dpi)"
        )
        pars.add_argument(
            "--resolutionY", type=float, default=1016.0,
            help="Resolution Y (dpi)"
        )
        pars.add_argument("--pen", type=int, default=1, help="Pen number")
        pars.add_argument("--force", type=int, default=0, help="Pen force (g)")
        pars.add_argument(
            "--speed", type=int, default=0,
            help="Pen speed (cm/s)"
        )

        # Kept for compatibility with Inkscape's HPGL encoder. The dedicated
        # C24 exporter performs its own fixed orientation compensation below.
        pars.add_argument(
            "--orientation", type=str, default="0",
            help="Internal encoder rotation (leave at 0; C24 compensation is automatic)"
        )
        pars.add_argument("--mirrorX", type=inkex.Boolean, default=False)
        pars.add_argument("--mirrorY", type=inkex.Boolean, default=False)

        # These are deliberately zero/false by default because they change the
        # relationship between the SVG document and the physical cut.
        pars.add_argument("--center", type=inkex.Boolean, default=False)
        pars.add_argument("--autoAlign", type=inkex.Boolean, default=False)
        pars.add_argument("--precut", type=inkex.Boolean, default=False)
        pars.add_argument("--overcut", type=float, default=0.0)
        pars.add_argument("--toolOffset", type=float, default=0.0)
        pars.add_argument(
            "--flat", type=float, default=1.2,
            help="Curve flatness"
        )

    def save(self, stream):
        self.options.debug = False

        if len(self.svg.xpath("//svg:use|//svg:flowRoot|//svg:text")) > 0:
            self.preprocess(["flowRoot", "text"])

        # IMPORTANT: orientation=0, autoAlign=false, center=false, and
        # toolOffset=0 make hpgl_encoder emit page-space coordinates rather than
        # drawing-bounds coordinates. We then apply the C24 transform ourselves.
        self.options.orientation = "0"
        self.options.autoAlign = False
        self.options.center = False
        self.options.precut = False
        self.options.overcut = 0.0
        self.options.toolOffset = 0.0

        encoder = hpgl_encoder.hpglEncoder(self)
        try:
            hpgl = encoder.getHpgl()
        except hpgl_encoder.NoPathError:
            raise inkex.AbortExtension(_("No convertible objects were found"))

        # Match the scale used internally by hpgl_encoder. viewBox transforms
        # matter when the SVG has a viewBox that differs from its page size.
        scale_x = self.options.resolutionX / self.svg.viewport_to_unit("1.0in")
        scale_y = self.options.resolutionY / self.svg.viewport_to_unit("1.0in")
        viewbox = self.svg.get_viewbox()
        viewbox_x = 1.0
        viewbox_y = 1.0
        if viewbox and viewbox[2] and viewbox[3]:
            viewbox_x = self.svg.viewbox_width / self.svg.viewport_to_unit(
                self.svg.add_unit(viewbox[2])
            )
            viewbox_y = self.svg.viewbox_height / self.svg.viewport_to_unit(
                self.svg.add_unit(viewbox[3])
            )

        page_width = self.svg.viewbox_width * scale_x * viewbox_x
        page_height = self.svg.viewbox_height * scale_y * viewbox_y

        # Capture the first actual drawing coordinate before transformation.
        # This is the point to which the carriage will return after cutting.
        start_point = _first_coordinate(hpgl)

        hpgl = "IN" + hpgl

        # First cancel the C24's observed 90-degree clockwise orientation.
        hpgl = transform_c24_coordinates(hpgl, page_width, page_height)

        # Then apply the firmware compatibility workaround already validated
        # against the user's C24: one coordinate pair per PD command.
        hpgl = split_pd_commands(hpgl)

        # IMPORTANT: return to the exact transformed starting coordinate.
        # Do not use PU0,0 here: that would make the carriage finish at the
        # machine origin rather than where the first cut began.
        if start_point is not None:
            start_x, start_y = start_point
            return_x = int(round(page_height - start_y))
            return_y = int(round(start_x))
            hpgl += "PU{},{};SP0;".format(return_x, return_y)
        else:
            hpgl += "SP0;"

        stream.write(hpgl.encode("utf-8"))


if __name__ == "__main__":
    SkycutC24HpglOutput().run()
