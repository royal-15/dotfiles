import QtQuick
import QtQuick.Controls
import qs
import qs.components

Item {
    id: root

    property var modelData: []
    property int currentIndex: 0

    signal itemActivated(var item)
    signal itemDeleteRequested(var item)

    readonly property int count: modelData ? modelData.length : 0

    function moveSelection(delta) {
        if (!modelData || modelData.length === 0)
            return;

        const maxIdx = modelData.length - 1;
        let next = currentIndex + delta;
        if (next < 0)
            next = 0;
        else if (next > maxIdx)
            next = maxIdx;

        currentIndex = next;
        listView.positionViewAtIndex(currentIndex, ListView.Contain);
    }

    function activateCurrent() {
        if (!modelData || modelData.length === 0)
            return;
        if (currentIndex >= 0 && currentIndex < modelData.length) {
            root.itemActivated(modelData[currentIndex]);
        }
    }

    function deleteCurrent() {
        if (!modelData || modelData.length === 0)
            return;
        if (currentIndex >= 0 && currentIndex < modelData.length) {
            root.itemDeleteRequested(modelData[currentIndex]);
        }
    }

    onModelDataChanged: {
        if (!modelData || modelData.length === 0) {
            currentIndex = 0;
        } else if (currentIndex >= modelData.length) {
            currentIndex = modelData.length - 1;
        }
    }

    ListView {
        id: listView
        anchors.fill: parent
        anchors.rightMargin: 6
        topMargin: 2
        bottomMargin: 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        spacing: 4
        model: root.modelData

        delegate: ClipboardItemDelegate {
            itemData: modelData
            isCurrent: index === root.currentIndex
            onClicked: {
                root.currentIndex = index;
                root.itemActivated(modelData);
            }
            onDeleteRequested: {
                root.itemDeleteRequested(modelData);
            }
        }

        ScrollBar.vertical: ScrollBar {
            id: verticalScrollBar
            active: listView.moving || listView.flocking || root.count > 6
            policy: root.count > 6 ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
            width: 4

            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: Colors.accent
                opacity: verticalScrollBar.active ? 0.8 : 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.durationFast
                        easing.type: Motion.easingStandard
                    }
                }
            }

            background: Rectangle {
                implicitWidth: 4
                radius: 2
                color: Colors.surfaceMuted
            }
        }
    }

    // Empty state container
    Column {
        anchors.centerIn: parent
        spacing: 8
        visible: root.count === 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "content_paste_off"
            font.family: "Material Symbols Rounded"
            font.pixelSize: 40
            color: Colors.textDim
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "No clipboard history found"
            font.pixelSize: 13
            font.weight: Font.Medium
            color: Colors.text
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Copied items will automatically appear here"
            font.pixelSize: 11
            color: Colors.textFaint
        }
    }
}
