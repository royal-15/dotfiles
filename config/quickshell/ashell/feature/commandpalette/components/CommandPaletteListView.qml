import QtQuick
import qs
import qs.components

Item {
    id: root

    property var modelData: []
    property int currentIndex: 0
    property var expandedIds: ({})

    signal itemActivated(var item)
    signal itemCopyRequested(var item)
    signal itemEditRequested(var item)
    signal itemDeleteRequested(var item)

    readonly property int count: modelData ? modelData.length : 0

    function moveSelection(delta) {
        if (!modelData || modelData.length === 0)
            return;

        const count = modelData.length;
        currentIndex = (currentIndex + delta + count) % count;
        listView.positionViewAtIndex(currentIndex, ListView.Contain);
    }

    function toggleExpandCurrent() {
        if (!modelData || modelData.length === 0)
            return;
        if (currentIndex >= 0 && currentIndex < modelData.length) {
            const item = modelData[currentIndex];
            if (!item || !item.id)
                return;
            const updated = Object.assign({}, root.expandedIds);
            updated[item.id] = !updated[item.id];
            root.expandedIds = updated;
        }
    }

    function toggleExpandItem(item) {
        if (!item || !item.id)
            return;
        const updated = Object.assign({}, root.expandedIds);
        updated[item.id] = !updated[item.id];
        root.expandedIds = updated;
    }

    function activateCurrent() {
        if (!modelData || modelData.length === 0)
            return;
        if (currentIndex >= 0 && currentIndex < modelData.length) {
            root.itemActivated(modelData[currentIndex]);
        }
    }

    function editCurrent() {
        if (!modelData || modelData.length === 0)
            return;
        if (currentIndex >= 0 && currentIndex < modelData.length) {
            root.itemEditRequested(modelData[currentIndex]);
        }
    }

    function deleteCurrent() {
        if (!modelData || modelData.length === 0)
            return;
        if (currentIndex >= 0 && currentIndex < modelData.length) {
            root.itemDeleteRequested(modelData[currentIndex]);
        }
    }

    function resetSelection() {
        currentIndex = 0;
        root.expandedIds = ({});
        if (modelData && modelData.length > 0) {
            listView.positionViewAtIndex(0, ListView.Beginning);
        }
    }

    onModelDataChanged: {
        currentIndex = 0;
        if (modelData && modelData.length > 0) {
            listView.positionViewAtIndex(0, ListView.Beginning);
        }
    }

    ListView {
        id: listView
        anchors.fill: parent
        topMargin: 2
        bottomMargin: 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        spacing: 4
        model: root.modelData

        delegate: CommandPaletteItemDelegate {
            itemData: modelData
            isCurrent: index === root.currentIndex
            isExpanded: Boolean(root.expandedIds[modelData.id])

            onClicked: {
                root.currentIndex = index;
                root.itemActivated(modelData);
            }
            onCopyRequested: {
                root.currentIndex = index;
                root.itemActivated(modelData);
            }
            onEditRequested: {
                root.currentIndex = index;
                root.itemEditRequested(modelData);
            }
            onDeleteRequested: {
                root.itemDeleteRequested(modelData);
            }
            onToggleExpandRequested: {
                root.currentIndex = index;
                root.toggleExpandItem(modelData);
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
            text: "search_off"
            font.family: "Material Symbols Rounded"
            font.pixelSize: 40
            color: Colors.textDim
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "No matching commands found"
            font.pixelSize: 13
            font.weight: Font.Medium
            color: Colors.text
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Press Ctrl+N or '+' above to add a new snippet"
            font.pixelSize: 11
            color: Colors.textFaint
        }
    }
}
