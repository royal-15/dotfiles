import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs
import qs.components
import qs.feature.notifications

PanelWindow {
    id: root

    property var modelData
    property bool anyPanelOpen: false

    screen: modelData
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    anchors {
        top: true
        right: true
    }

    margins {
        top: Decorations.exclusiveZoneHeight
        right: Decorations.screenEdgePadding
    }

    implicitWidth: 320
    implicitHeight: 380
    color: Colors.clear
    visible: (NotificationService.activeToastListModel.count > 0 || panelFadeAnimation.running) && !anyPanelOpen

    mask: Region {
        Region {
            item: toastListView
        }
    }

    onAnyPanelOpenChanged: {
        if (anyPanelOpen && NotificationService.activeToastListModel.count > 0) {
            panelFadeAnimation.restart();
        }
    }

    SequentialAnimation {
        id: panelFadeAnimation
        NumberAnimation {
            target: toastContainer
            property: "opacity"
            to: 0.0
            duration: Motion.durationFast
            easing.type: Motion.easingStandard
        }
        ScriptAction {
            script: {
                NotificationService.clearToastsSilently();
                toastContainer.opacity = 1.0;
            }
        }
    }

    Item {
        id: toastContainer
        anchors.fill: parent

        ListView {
            id: toastListView
            anchors.fill: parent
            spacing: 8
            clip: false
            interactive: false
            model: NotificationService.activeToastListModel

            HoverHandler {
                id: toastStackHover
            }

            add: Transition {
                ParallelAnimation {
                    NumberAnimation {
                        property: "x"
                        from: root.implicitWidth
                        to: 0
                        duration: Motion.durationNormal
                        easing.type: Motion.easingStandard
                    }
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: Motion.durationNormal
                        easing.type: Motion.easingStandard
                    }
                    NumberAnimation {
                        property: "scale"
                        from: 0.94
                        to: 1.0
                        duration: Motion.durationNormal
                        easing.type: Motion.easingStandard
                    }
                }
            }

            addDisplaced: Transition {
                NumberAnimation {
                    property: "y"
                    duration: Motion.durationNormal
                    easing.type: Motion.easingStandard
                }
            }

            remove: Transition {
                ParallelAnimation {
                    NumberAnimation {
                        property: "x"
                        to: root.implicitWidth
                        duration: Motion.durationNormal
                        easing.type: Motion.easingStandard
                    }
                    NumberAnimation {
                        property: "opacity"
                        to: 0
                        duration: Motion.durationNormal
                        easing.type: Motion.easingStandard
                    }
                }
            }

            removeDisplaced: Transition {
                NumberAnimation {
                    property: "y"
                    duration: Motion.durationNormal
                    easing.type: Motion.easingStandard
                }
            }

            displaced: Transition {
                NumberAnimation {
                    property: "y"
                    duration: Motion.durationNormal
                    easing.type: Motion.easingStandard
                }
            }

            delegate: Item {
                id: toastDelegateItem
                required property var notifObj
                required property int toastId
                required property int index

                width: toastListView.width
                height: card.implicitHeight
                implicitHeight: card.implicitHeight

                property var cachedNotif: null
                property bool isCritical: false
                property bool isLow: false
                property bool isDestroyed: false
                readonly property bool isStackHovered: toastStackHover.hovered

                onIsStackHoveredChanged: {
                    if (isDestroyed || isCritical)
                        return;
                    if (isStackHovered) {
                        dismissTimer.stop();
                    } else {
                        dismissTimer.restart();
                    }
                }

                Component.onCompleted: {
                    cachedNotif = notifObj;
                    if (notifObj) {
                        try {
                            isCritical = (notifObj.urgency === NotificationUrgency.Critical || notifObj.urgency === 2);
                            isLow = (notifObj.urgency === NotificationUrgency.Low || notifObj.urgency === 0);
                        } catch (e) {}
                    }
                    if (!isCritical && !isStackHovered) {
                        dismissTimer.start();
                    }
                }

                Component.onDestruction: {
                    isDestroyed = true;
                    dismissTimer.stop();
                }

                Timer {
                    id: dismissTimer
                    interval: toastDelegateItem.isLow ? 3000 : 5000
                    repeat: false
                    onTriggered: {
                        NotificationService.removeToast(toastDelegateItem.toastId);
                    }
                }

                NotificationCard {
                    id: card
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    width: parent.width
                    isToast: true
                    notification: toastDelegateItem.cachedNotif
                    onDismissed: {
                        dismissTimer.stop();
                        NotificationService.removeToast(toastDelegateItem.toastId);
                    }
                }
            }
        }
    }
}
