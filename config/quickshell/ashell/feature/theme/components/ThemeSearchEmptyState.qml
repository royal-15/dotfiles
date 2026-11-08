import QtQuick
import QtQuick.Layouts
import qs
import qs.components

Item {
    id: root

    property string searchQuery: ""

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: "search_off"
            font.family: "Material Symbols Rounded"
            font.pixelSize: 32
            color: Colors.textDim
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: root.searchQuery ? ("No themes matching \"" + root.searchQuery + "\"") : "No themes found"
            color: Colors.text
            font.pixelSize: 13
            font.weight: Font.Medium
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: "Press Esc or Backspace to clear"
            color: Colors.textFaint
            font.pixelSize: 11
            font.weight: Font.Normal
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
