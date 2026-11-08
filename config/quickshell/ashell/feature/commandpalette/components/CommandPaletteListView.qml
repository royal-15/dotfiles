import QtQuick
import qs
import qs.components

Item {
    id: root

    property var modelData: []
    property int currentIndex: 0
    property string selectedItemId: ""
    property string confirmingDeleteId: ""
    property var expandedIds: ({})

    signal itemActivated(var item)
    signal itemCopyRequested(var item)
    signal itemEditRequested(var item)
    signal itemDeleteRequested(var item)

    readonly property int count: modelData ? modelData.length : 0

    Timer {
        id: confirmDeleteResetTimer
        interval: 3000
        repeat: false
        onTriggered: root.confirmingDeleteId = ""
    }

    function cancelDeleteConfirmation() {
        confirmingDeleteId = "";
        confirmDeleteResetTimer.stop();
    }

    function updateSelection(newIndex) {
        if (confirmingDeleteId !== "") {
            cancelDeleteConfirmation();
        }
        if (!modelData || modelData.length === 0) {
            currentIndex = 0;
            selectedItemId = "";
            return;
        }
        const count = modelData.length;
        currentIndex = Math.max(0, Math.min(newIndex, count - 1));
        const current = modelData[currentIndex];
        selectedItemId = (current && current.id) ? String(current.id) : "";
        listView.positionViewAtIndex(currentIndex, ListView.Contain);
    }

    function selectItemById(id) {
        if (!id || !modelData || modelData.length === 0)
            return;
        const targetId = String(id);
        const idx = modelData.findIndex(item => item && String(item.id) === targetId);
        if (idx !== -1) {
            currentIndex = idx;
            selectedItemId = targetId;
            listView.positionViewAtIndex(currentIndex, ListView.Contain);
        }
    }

    function moveSelection(delta) {
        if (!modelData || modelData.length === 0)
            return;

        const count = modelData.length;
        const next = (currentIndex + delta + count) % count;
        updateSelection(next);
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

    function requestDelete(item) {
        if (!item || !item.id)
            return;
        const itemId = String(item.id);
        if (root.confirmingDeleteId === itemId) {
            confirmDeleteResetTimer.stop();
            root.confirmingDeleteId = "";
            root.itemDeleteRequested(item);
        } else {
            root.confirmingDeleteId = itemId;
            confirmDeleteResetTimer.restart();
        }
    }

    function deleteCurrent() {
        if (!modelData || modelData.length === 0)
            return;
        if (currentIndex >= 0 && currentIndex < modelData.length) {
            requestDelete(modelData[currentIndex]);
        }
    }

    function resetSelection() {
        cancelDeleteConfirmation();
        root.expandedIds = ({});
        updateSelection(0);
        if (modelData && modelData.length > 0) {
            listView.positionViewAtIndex(0, ListView.Beginning);
        }
    }

    onModelDataChanged: {
        if (!modelData || modelData.length === 0) {
            currentIndex = 0;
            selectedItemId = "";
            cancelDeleteConfirmation();
            return;
        }
        if (selectedItemId !== "") {
            const idx = modelData.findIndex(item => item && String(item.id) === selectedItemId);
            if (idx !== -1) {
                currentIndex = idx;
                listView.positionViewAtIndex(currentIndex, ListView.Contain);
                return;
            }
        }
        cancelDeleteConfirmation();
        updateSelection(Math.min(currentIndex, modelData.length - 1));
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
            isConfirmingDelete: root.confirmingDeleteId !== "" && String(modelData.id) === root.confirmingDeleteId

            onClicked: {
                root.updateSelection(index);
                root.itemActivated(modelData);
            }
            onCopyRequested: {
                root.updateSelection(index);
                root.itemActivated(modelData);
            }
            onEditRequested: {
                root.updateSelection(index);
                root.itemEditRequested(modelData);
            }
            onDeleteRequested: {
                root.requestDelete(modelData);
            }
            onCancelDeleteRequested: {
                root.cancelDeleteConfirmation();
            }
            onToggleExpandRequested: {
                root.updateSelection(index);
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
