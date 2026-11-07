import QtQuick
import QtQuick.Layouts
import qs
import qs.components

Item {
    id: root

    property string activeStage: "themes" // "themes" or "wallpapers"
    property string infoText: ""

    signal backRequested()
    signal switchStageRequested(string stage)

    implicitWidth: 560
    implicitHeight: 28

    RowLayout {
        anchors.fill: parent
        spacing: 8

        // Breadcrumb Navigation
        RowLayout {
            spacing: 6

            Item {
                implicitWidth: hubLabel.implicitWidth
                implicitHeight: root.implicitHeight
                scale: hubMouse.pressed
                    ? Motion.scalePress
                    : (hubMouse.containsMouse ? Motion.scaleHover : Motion.scaleNormal)
                transformOrigin: Item.Center

                Behavior on scale {
                    NumberAnimation {
                        duration: hubMouse.pressed ? Motion.durationPressDown : Motion.durationPressRelease
                        easing.type: hubMouse.pressed ? Motion.easingPressDown : Motion.easingPressRelease
                    }
                }

                Text {
                    id: hubLabel
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Theme Studio"
                    color: hubMouse.containsMouse ? Colors.accent : Colors.textDim
                    font.pixelSize: 12
                    font.weight: Font.Medium

                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.durationInstant
                            easing.type: Motion.easingStandard
                        }
                    }
                }

                MouseArea {
                    id: hubMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.backRequested()
                }
            }

            Text {
                text: "/"
                color: Colors.textFaint
                font.pixelSize: 12
            }

            Text {
                text: root.activeStage === "themes" ? "Themes" : "Wallpapers"
                color: Colors.text
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
        }

        Item { Layout.fillWidth: true }

        // Minimal Right Metadata
        Text {
            visible: root.infoText !== ""
            text: root.infoText
            color: Colors.textDim
            font.pixelSize: 11
            font.weight: Font.Normal
        }
    }
}
