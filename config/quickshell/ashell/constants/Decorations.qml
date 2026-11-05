pragma Singleton

import QtQuick

QtObject {
    id: root

    // ─── Bar Geometry ─────────────────────────────────────────────────────────
    readonly property int barTopOffset: 0
    // Screen top gap above the bar capsule.

    readonly property int barLeftRightMargin: 7
    // Horizontal margin around the bar window edges.

    readonly property int barCapsuleHeight: 37
    // Rendered pixel height of the status bar capsule strip.

    readonly property int barBottomOffset: 0
    // Gap between the bar and application windows (exclusive zone boundary).

    // Derived boundary where application windows stop and floating panels align
    readonly property int exclusiveZoneHeight: barTopOffset + barCapsuleHeight + barBottomOffset

    // ─── Pill & Island Geometry / Margins ────────────────────────────────────
    readonly property int pillHeight: 25
    // Canonical height for pills and compact dynamic island capsules.

    readonly property int barItemMarginVertical: 5
    // Vertical margin centering pills and islands within the bar capsule ((35 - 25) / 2).

    readonly property int barItemMarginHorizontal: 0
    // Horizontal inset of pill groups from the bar capsule edges.

    // ─── Unified Surface Rounding ────────────────────────────────────────────
    readonly property int cornerRadius: 20
    // Canonical corner radius for all shell surfaces (islands, sidebar, modals, cards).
    // Clamps automatically to height / 2 (12.5px) on 25px pills and compact capsules.

    // ─── Screen Edge Gaps ─────────────────────────────────────────────────────
    readonly property int screenEdgePadding: 5
    // Breathing room between floating panels and screen edges (right, bottom).
}
