import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs
import qs.components

Item {
    id: root

    property var notification: null
    property bool isToast: false
    signal dismissed()

    implicitWidth: 320
    implicitHeight: root.naturalHeight
    height: root.naturalHeight

    property string displayAppName: "System"
    property string displaySummary: ""
    property string displayBody: ""
    property bool isCritical: false
    property var notificationActions: []

    function syncNotificationData() {
        if (!notification)
            return;
        try {
            if (notification.appName !== undefined)
                displayAppName = notification.appName ? String(notification.appName) : "System";
            if (notification.summary !== undefined)
                displaySummary = notification.summary ? String(notification.summary) : "";
            if (notification.body !== undefined)
                displayBody = notification.body ? String(notification.body) : "";
            if (notification.urgency !== undefined)
                isCritical = (notification.urgency === NotificationUrgency.Critical || notification.urgency === 2);
            if (notification.actions !== undefined)
                notificationActions = notification.actions ? notification.actions : [];
        } catch (e) {
            // Ignored during context destruction
        }
    }

    Component.onCompleted: syncNotificationData()
    onNotificationChanged: syncNotificationData()

    readonly property real naturalHeight: Math.max(76, contentCol.implicitHeight + 20)

    property real dragOffset: 0
    property real visualOpacity: 1.0
    property bool isExiting: false
    property int exitDirection: 1

    readonly property real liveOpacity: isExiting
        ? visualOpacity
        : Math.max(0.15, 1.0 - (Math.abs(dragOffset) / Math.max(1, width * 0.85)))

    function dismissCard(direction = 1) {
        if (isExiting)
            return;
        isExiting = true;
        exitDirection = direction >= 0 ? 1 : -1;
        exitAnimation.restart();
    }

    function dismissWithDelay(delayMs) {
        if (isExiting)
            return;
        isExiting = true;
        exitDirection = 1;
        cascadeTimer.interval = Math.max(0, delayMs);
        cascadeTimer.restart();
    }

    Timer {
        id: cascadeTimer
        repeat: false
        onTriggered: exitAnimation.restart()
    }

    NumberAnimation {
        id: snapAnim
        target: root
        property: "dragOffset"
        to: 0
        duration: Motion.durationFast
        easing.type: Motion.easingBounce
    }

    SequentialAnimation {
        id: exitAnimation

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "dragOffset"
                to: root.exitDirection > 0 ? (root.width + 50) : (-root.width - 50)
                duration: Motion.durationNormal
                easing.type: Motion.easingStandard
            }
            NumberAnimation {
                target: root
                property: "visualOpacity"
                to: 0
                duration: Motion.durationNormal
                easing.type: Motion.easingStandard
            }
        }

        ScriptAction {
            script: root.dismissed()
        }
    }

    Item {
        id: cardWrapper
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.naturalHeight
        opacity: root.liveOpacity
        transform: Translate {
            x: root.dragOffset
        }

        // Ambient drop shadow
        Rectangle {
            anchors.fill: cardSurface
            anchors.topMargin: 2
            anchors.bottomMargin: -1
            radius: cardSurface.radius
            color: root.isCritical ? Colors.criticalSoft : Colors.shadow
            opacity: (root.isCritical ? 0.40 : 0.60) * root.liveOpacity
            z: -1
        }

        Rectangle {
            id: cardSurface
            anchors.fill: parent
            radius: Decorations.cornerRadius
            color: root.isToast ? Colors.panel : Colors.surfaceSoft
            border.color: root.isCritical ? Colors.critical : Colors.border
            border.width: 1
            clip: true

            // Interactive horizontal swipe gesture detector
            MouseArea {
                id: swipeArea
                anchors.fill: parent
                z: 0
                hoverEnabled: true
                enabled: !root.isExiting

                property real startX: 0
                property real lastX: 0
                property real velocityX: 0
                property bool isDragging: false

                onPressed: mouse => {
                    startX = mouse.x;
                    lastX = mouse.x;
                    velocityX = 0;
                    isDragging = false;
                }

                onPositionChanged: mouse => {
                    if (pressed) {
                        const deltaX = mouse.x - startX;
                        if (!isDragging && Math.abs(deltaX) > 6) {
                            isDragging = true;
                        }
                        if (isDragging) {
                            velocityX = mouse.x - lastX;
                            lastX = mouse.x;
                            root.dragOffset = deltaX;
                        }
                    }
                }

                onReleased: mouse => {
                    if (isDragging) {
                        isDragging = false;
                        const threshold = 75;
                        const hasFling = Math.abs(velocityX) > 10;
                        if (Math.abs(root.dragOffset) > threshold || hasFling) {
                            const dir = (hasFling ? velocityX : root.dragOffset) >= 0 ? 1 : -1;
                            root.dismissCard(dir);
                        } else {
                            snapAnim.restart();
                        }
                    }
                }

                onCanceled: {
                    isDragging = false;
                    snapAnim.restart();
                }
            }

            // Critical urgency left accent bar
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: root.isCritical ? 3 : 0
                color: Colors.critical
                visible: root.isCritical
            }

            ColumnLayout {
                id: contentCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                anchors.leftMargin: root.isCritical ? 14 : 10
                spacing: 5

                // Header: [App Icon + App Name | Close Button]
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: root.isCritical ? "warning" : "notifications"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 14
                        color: root.isCritical ? Colors.critical : Colors.accent
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        text: root.displayAppName
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: Colors.textDim
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    // Close / Dismiss button
                    Item {
                        implicitWidth: 20
                        implicitHeight: 20

                        Text {
                            anchors.centerIn: parent
                            text: "close"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 14
                            color: closeMouse.containsMouse ? Colors.text : Colors.textFaint
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.dismissCard(1);
                            }
                        }
                    }
                }

                // Summary / Title
                Text {
                    text: root.displaySummary
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: Colors.text
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    maximumLineCount: root.isToast ? 2 : 3
                    elide: Text.ElideRight
                    visible: text !== ""
                }

                // Body text
                Text {
                    text: root.displayBody
                    font.pixelSize: 11
                    color: Colors.textDim
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    maximumLineCount: root.isToast ? 3 : 6
                    elide: Text.ElideRight
                    visible: text !== ""
                }

                // Optional Actions row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: root.notificationActions.length > 0

                    Repeater {
                        model: root.notificationActions

                        delegate: Item {
                            required property var modelData
                            implicitWidth: actionLabel.implicitWidth + 14
                            implicitHeight: 22

                            Rectangle {
                                anchors.fill: parent
                                radius: 11
                                color: actionMouse.containsMouse ? Colors.accentSoft : Colors.surfaceMuted

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Motion.durationFast
                                    }
                                }
                            }

                            Text {
                                id: actionLabel
                                anchors.centerIn: parent
                                text: modelData ? modelData.text : ""
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: actionMouse.containsMouse ? Colors.accent : Colors.text
                            }

                            MouseArea {
                                id: actionMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData && typeof modelData.invoke === "function") {
                                        modelData.invoke();
                                    }
                                    root.dismissCard(1);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
