import QtQuick
import QtQuick.Layouts
import qs
import qs.components

Item {
    id: root

    property var viewingDate: new Date()
    property var selectedDate: new Date()
    readonly property var today: new Date()

    signal dayClicked(var date)

    implicitWidth: 320
    implicitHeight: dayHeadersRow.implicitHeight + gridContainer.implicitHeight + 8

    readonly property var dayLabels: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    function computeDays(year, month) {
        const days = [];
        const firstDay = new Date(year, month, 1);
        // ISO 8601: Monday is 0, Sunday is 6
        const startDay = (firstDay.getDay() + 6) % 7;
        const daysInMonth = new Date(year, month + 1, 0).getDate();
        const daysInPrevMonth = new Date(year, month, 0).getDate();

        const todayObj = root.today;
        const selObj = root.selectedDate;

        for (let i = 0; i < 42; i++) {
            let cellDay = 0;
            let cellMonth = month;
            let cellYear = year;
            let isCurrentMonth = false;

            if (i < startDay) {
                cellDay = daysInPrevMonth - startDay + 1 + i;
                cellMonth = month - 1;
                if (cellMonth < 0) {
                    cellMonth = 11;
                    cellYear = year - 1;
                }
            } else if (i < startDay + daysInMonth) {
                cellDay = i - startDay + 1;
                isCurrentMonth = true;
            } else {
                cellDay = i - (startDay + daysInMonth) + 1;
                cellMonth = month + 1;
                if (cellMonth > 11) {
                    cellMonth = 0;
                    cellYear = year + 1;
                }
            }

            const isToday = (cellYear === todayObj.getFullYear() &&
                             cellMonth === todayObj.getMonth() &&
                             cellDay === todayObj.getDate());

            const isSelected = selObj ? (cellYear === selObj.getFullYear() &&
                                         cellMonth === selObj.getMonth() &&
                                         cellDay === selObj.getDate()) : false;

            days.push({
                day: cellDay,
                month: cellMonth,
                year: cellYear,
                isCurrentMonth: isCurrentMonth,
                isToday: isToday,
                isSelected: isSelected
            });
        }
        return days;
    }

    property var calendarDays: computeDays(viewingDate.getFullYear(), viewingDate.getMonth())

    function refreshDays() {
        calendarDays = computeDays(viewingDate.getFullYear(), viewingDate.getMonth());
    }

    onViewingDateChanged: refreshDays()
    onSelectedDateChanged: refreshDays()

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        // Day of week headers (Mo, Tu, We, Th, Fr, Sa, Su)
        RowLayout {
            id: dayHeadersRow
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: root.dayLabels

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 22

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: Colors.textDim
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }
            }
        }

        // 6 rows x 7 columns date matrix
        Grid {
            id: gridContainer
            Layout.fillWidth: true
            columns: 7
            columnSpacing: 4
            rowSpacing: 4

            readonly property real cellWidth: Math.floor((width - (columnSpacing * 6)) / 7)
            readonly property real cellHeight: 32

            Repeater {
                model: root.calendarDays

                Rectangle {
                    id: dayCell
                    width: gridContainer.cellWidth
                    height: gridContainer.cellHeight
                    radius: Math.round(Decorations.cornerRadius / 2)

                    readonly property bool isToday: modelData.isToday
                    readonly property bool isSelected: modelData.isSelected
                    readonly property bool isCurrentMonth: modelData.isCurrentMonth
                    readonly property bool isHovered: cellMouseArea.containsMouse

                    color: isToday
                        ? Colors.accent
                        : (isSelected
                            ? Colors.accentSoft
                            : (isHovered ? Colors.surfaceSoft : Colors.clear))

                    border.color: isSelected && !isToday
                        ? Colors.accent
                        : Colors.clear
                    border.width: isSelected && !isToday ? 1 : 0

                    scale: cellMouseArea.pressed ? Motion.scalePress : (isHovered ? Motion.scaleHover : Motion.scaleNormal)

                    Behavior on scale {
                        NumberAnimation {
                            duration: Motion.durationFast
                            easing.type: Motion.easingStandard
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.durationFast
                            easing.type: Motion.easingStandard
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.day
                        color: dayCell.isToday
                            ? Colors.textAccent
                            : (dayCell.isSelected
                                ? Colors.accent
                                : (dayCell.isCurrentMonth ? Colors.text : Colors.textFaint))
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.weight: (dayCell.isToday || dayCell.isSelected) ? Font.Bold : Font.Normal

                        Behavior on color {
                            ColorAnimation {
                                duration: Motion.durationFast
                                easing.type: Motion.easingStandard
                            }
                        }
                    }

                    MouseArea {
                        id: cellMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const clickedDate = new Date(modelData.year, modelData.month, modelData.day);
                            root.dayClicked(clickedDate);
                        }
                    }
                }
            }
        }
    }
}
