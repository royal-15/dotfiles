import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.components

Item {
    id: root

    property var monitor: null
    property var workspaceIds: []

    property color activeStartColor: Colors.accent
    property color activeEndColor: Colors.accentAlt
    property color inactiveColor: Colors.surfaceMuted
    // property color inactiveColor: Colors.accentSoft
    property int spacing: 6
    property bool interactive: true

    signal workspaceActivated(int workspaceId)
    signal activeWorkspaceClicked()

    implicitWidth: row.implicitWidth
    implicitHeight: 25

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: root.spacing

        Repeater {
            model: root.workspaceIds

            delegate: Item {
                id: wsDelegate
                required property int modelData

                readonly property bool isActive:
                    !!root.monitor
                    && !!root.monitor.activeWorkspace
                    && root.monitor.activeWorkspace.id === modelData

                readonly property real indicatorWidth: isActive ? 24 : 16

                implicitWidth: indicatorWidth + 2
                implicitHeight: 25

                scale: wsHover.hovered ? Motion.scaleHover : Motion.scaleNormal
                transformOrigin: Item.Center

                Behavior on scale {
                    NumberAnimation {
                        duration: Motion.durationFast
                        easing.type: Motion.easingStandard
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.indicatorWidth
                    height: 8
                    radius: height / 2
                    color: wsHover.hovered && !parent.isActive ? Colors.surfaceSoft : root.inactiveColor
                    opacity: wsHover.hovered && !parent.isActive ? 1.0 : 0.85

                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.durationFast
                            easing.type: Motion.easingStandard
                        }
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: Motion.durationNormal
                            easing.type: Motion.easingStandard
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Motion.durationFast
                            easing.type: Motion.easingStandard
                        }
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.indicatorWidth
                    height: 8
                    radius: height / 2
                    opacity: parent.isActive ? 1 : 0
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: root.activeStartColor
                        }

                        GradientStop {
                            position: 1
                            color: root.activeEndColor
                        }
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: Motion.durationNormal
                            easing.type: Motion.easingStandard
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Motion.durationFast
                            easing.type: Motion.easingStandard
                        }
                    }
                }

                HoverHandler {
                    id: wsHover
                    enabled: root.interactive
                    cursorShape: Qt.PointingHandCursor
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.interactive
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        if (parent.isActive) {
                            root.activeWorkspaceClicked();
                        } else {
                            if (Hyprland.usingLua) {
                                Hyprland.dispatch(`hl.dsp.focus({ workspace = "${modelData}" })`);
                            } else {
                                Hyprland.dispatch(`workspace ${modelData}`);
                            }
                            root.workspaceActivated(modelData);
                        }
                    }
                }
            }
        }
    }
}
