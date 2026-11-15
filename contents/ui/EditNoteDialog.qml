/***************************************************************************
 *   EQ-Notes           *
 *   Copyright 2026 by Barnak Zlatko <saradnja.barnak@gmail.com>           *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 3 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   *   WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Rectangle {
    id: modalBackdrop
    anchors.fill: parent
    z: 9999
    visible: root.noteWindowOpen && root.activeNote !== null
    radius: 16
    color: Qt.rgba(0, 0, 0, 0.58)

    MouseArea {
        anchors.fill: parent
        onClicked: root.closeFloatingNote()
    }

    Rectangle {
        id: floatingCard
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.78, 640)
        height: Math.min(parent.height * 0.90, 560)

        // Prati zakrivljenost stikera iz podešavanja
        radius: root.stickerRadius !== undefined ? root.stickerRadius : 12

        // Automatski povlači boju stikera na osnovu važnosti i ID-ja
        color: root.activeNote ? root.stickerColor(root.editMode ? popupImportanceBox.currentIndex : root.activeNote.importance, root.activeNote.id) : root.surfaceColor

        border.width: 1
        border.color: root.accentColor

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    width: 34
                    height: 34
                    radius: 11
                    color: "#29365d"
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        source: root.editMode ? "document-edit" : "view-pim-notes"
                        width: 18
                        height: 18
                        color: "#a9b7ff"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Controls.Label {

                        font.bold: true
                        font.family: "Sans Serif"
                        font.pixelSize: 17
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        // Kontrastna boja naslova
                        color: root.activeNote ? root.stickerForegroundColor(root.editMode ? popupImportanceBox.currentIndex : root.activeNote.importance) : Kirigami.Theme.textColor
                    }
                    Controls.Label {
                        text: root.activeNote
                              ? root.importanceName(root.editMode ? popupImportanceBox.currentIndex : root.activeNote.importance) +
                                (root.activeNote.done ? "  •  COMPLETED" : "  •  ACTIVE") +
                                (root.activeNote.reminderEnabled && !root.editMode
                                 ? "  •  Reminder: " + root.dateTimeText(root.activeNote.reminderAt)
                                 : "")
                              : ""
                        font.family: "Sans Serif"
                        font.pixelSize: 12
                        // Kontrastna boja podteksta
                        color: root.activeNote
                               ? root.stickerSecondaryTextColor(root.editMode ? popupImportanceBox.currentIndex : root.activeNote.importance)
                               : Kirigami.Theme.textColor
                    }
                }

                Controls.ToolButton {
                    icon.name: "document-edit"
                    flat: !root.editMode
                    highlighted: root.editMode
                    Controls.ToolTip.visible: hovered
                    Controls.ToolTip.text: root.editMode ? "Cancel editing" : "Edit note and reminder"
                    onClicked: {
                        root.editMode = !root.editMode
                        if (root.editMode && root.activeNote) {
                            popupBodyText.text = root.activeNote.body
                            popupReminderCheck.checked = root.activeNote.reminderEnabled
                            popupDueCheck.checked = root.activeNote.dueAt > 0
                            popupImportanceBox.currentIndex = root.activeNote.importance

                            if (root.activeNote.reminderAt > 0) {
                                var d = new Date(root.activeNote.reminderAt)
                                popupRemDay.currentIndex = Math.max(0, root.daysModel.indexOf(String(d.getDate())))
                                popupRemMon.currentIndex = d.getMonth()
                                popupRemYear.currentIndex = Math.max(0, root.yearsModel.indexOf(String(d.getFullYear())))
                                popupRemHour.currentIndex = d.getHours()
                                popupRemMin.currentIndex = Math.floor(d.getMinutes() / 5)
                            }

                            if (root.activeNote.dueAt > 0) {
                                var dd = new Date(root.activeNote.dueAt)
                                popupDueDay.currentIndex = Math.max(0, root.daysModel.indexOf(String(dd.getDate())))
                                popupDueMon.currentIndex = dd.getMonth()
                                popupDueYear.currentIndex = Math.max(0, root.yearsModel.indexOf(String(dd.getFullYear())))
                                popupDueHour.currentIndex = dd.getHours()
                                popupDueMin.currentIndex = Math.floor(dd.getMinutes() / 5)
                            }
                        }
                    }
                }

                Controls.ToolButton {
                    text: "✕"
                    flat: true
                    onClicked: root.closeFloatingNote()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.subtleBorder
            }

            Rectangle {
                visible: !root.editMode
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 2
                color: "transparent"
                border.width: 0

                Controls.ScrollView {
                    anchors.fill: parent
                    anchors.margins: 4

                    Controls.TextArea {
                        text: root.activeNote ? root.activeNote.body : ""
                        wrapMode: TextEdit.Wrap
                        readOnly: true
                        selectByMouse: true
                        font.family: "Sans Serif"
                        font.pixelSize: 20
                        // Garancija čitljivosti: automatski kontrastna boja teksta
                        color: root.activeNote ? root.stickerForegroundColor(root.activeNote.importance) : Kirigami.Theme.textColor
                        background: Item {}
                        padding: 10
                    }
                }
            }

            // UREĐIVANJE BELEŠKE
            ColumnLayout {
                visible: root.editMode
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 2
                    color: root.surfaceColor
                    border.width: 1
                    border.color: root.accentColor

                    Controls.TextArea {
                        id: popupBodyText
                        anchors.fill: parent
                        anchors.margins: 8
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                        font.family: "Sans Serif"
                        font.pixelSize: 16
                        color: Kirigami.Theme.textColor
                        background: Item {}
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: editOptCol.implicitHeight + 16
                    radius: 10
                    color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.075)
                    border.width: 1
                    border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.20)

                    ColumnLayout {
                        id: editOptCol
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            Controls.CheckBox {
                                id: popupReminderCheck
                                text: "Enable reminder"
                                font.pixelSize: 11
                                contentItem: Text {
                                    text: parent.text
                                    color: floatingCard.currentFgColor
                                    font.pixelSize: parent.font.pixelSize
                                    leftPadding: parent.indicator.width + parent.spacing
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                            Controls.CheckBox {
                                id: popupDueCheck
                                text: "Set due date"
                                font.pixelSize: 11
                                contentItem: Text {
                                    text: parent.text
                                    color: floatingCard.currentFgColor
                                    font.pixelSize: parent.font.pixelSize
                                    leftPadding: parent.indicator.width + parent.spacing
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                            Item { Layout.fillWidth: true }
                            Controls.Label { text: "Importance:"; font.pixelSize: 11; color: floatingCard.currentFgColor }
                            Controls.ComboBox {
                                id: popupImportanceBox
                                model: ["Low", "Normal", "High"]
                                Layout.preferredWidth: 110
                                font.pixelSize: 11
                                contentItem: Text {
                                    text: parent.displayText
                                    color: floatingCard.currentFgColor
                                    font.pixelSize: parent.font.pixelSize
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }

                        RowLayout {
                            visible: popupReminderCheck.checked
                            Layout.fillWidth: true
                            spacing: 6
                            Controls.Label { text: "Notify:"; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: 65; color: floatingCard.currentFgColor }

                            Controls.ComboBox {
                                id: popupRemDay;
                                model: root.daysModel;
                                Layout.preferredWidth: 60;
                                font.pixelSize: 11;
                                contentItem: Text {
                                    text: parent.displayText
                                    color: floatingCard.currentFgColor
                                    font.pixelSize: parent.font.pixelSize
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                            Controls.ComboBox {
                                id: popupRemMon;
                                model: root.monthsModel;
                                Layout.preferredWidth: 70;
                                font.pixelSize: 11;
                                contentItem: Text {
                                    text: parent.displayText
                                    color: floatingCard.currentFgColor
                                    font.pixelSize: parent.font.pixelSize
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                            Controls.ComboBox {
                                id: popupRemYear;
                                model: root.yearsModel;
                                Layout.preferredWidth: 75;
                                font.pixelSize: 11;
                                contentItem: Text {
                                    text: parent.displayText
                                    color: floatingCard.currentFgColor
                                    font.pixelSize: parent.font.pixelSize
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                            Item { Layout.preferredWidth: 8 }
                            Controls.ComboBox {
                                id: popupRemHour;
                                model: root.hoursModel;
                                Layout.preferredWidth: 60;
                                font.pixelSize: 11;
                                contentItem: Text {
                                    text: parent.displayText
                                    color: floatingCard.currentFgColor
                                    font.pixelSize: parent.font.pixelSize
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                            Controls.Label { text: ":"; font.pixelSize: 11; font.bold: true; color: floatingCard.currentFgColor }
                            Controls.ComboBox {
                                id: popupRemMin;
                                model: root.minutesModel;
                                Layout.preferredWidth: 60;
                                font.pixelSize: 11;
                                contentItem: Text {
                                    text: parent.displayText
                                    color: floatingCard.currentFgColor
                                    font.pixelSize: parent.font.pixelSize
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }

                        RowLayout {
                            visible: popupDueCheck.checked
                            Layout.fillWidth: true
                            spacing: 6
                            Controls.Label { text: "Due:"; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: 65; color: floatingCard.currentFgColor }

                            Controls.ComboBox {
                                id: popupDueDay;
                                model: root.daysModel;
                                Layout.preferredWidth: 60;
                                font.pixelSize: 11;
                                contentItem: Text {
                                    text: parent.displayText
                                    color: floatingCard.currentFgColor
                                    font.pixelSize: parent.font.pixelSize
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                            Controls.ComboBox {
                                id: popupDueMon;
                                model: root.monthsModel;
                                Layout.preferredWidth: 70;
                                font.pixelSize: 11;
                                contentItem: Text {
                                    text: parent.displayText
                                    color: floatingCard.currentFgColor
                                    font.pixelSize: parent.font.pixelSize
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                            Controls.ComboBox {
                                id: popupDueYear;
                                model: root.yearsModel;
                                Layout.preferredWidth: 75;
                                font.pixelSize: 11;
                                contentItem: Text {
                                    text: parent.displayText
                                    color: floatingCard.currentFgColor
                                    font.pixelSize: parent.font.pixelSize
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                            Item { Layout.preferredWidth: 8 }
                            Controls.ComboBox {
                                id: popupDueHour;
                                model: root.hoursModel;
                                Layout.preferredWidth: 60;
                                font.pixelSize: 11;
                                contentItem: Text {
                                    text: parent.displayText
                                    color: floatingCard.currentFgColor
                                    font.pixelSize: parent.font.pixelSize
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                            Controls.Label { text: ":"; font.pixelSize: 11; font.bold: true; color: floatingCard.currentFgColor }
                            Controls.ComboBox {
                                id: popupDueMin;
                                model: root.minutesModel;
                                Layout.preferredWidth: 60;
                                font.pixelSize: 11;
                                contentItem: Text {
                                    text: parent.displayText
                                    color: floatingCard.currentFgColor
                                    font.pixelSize: parent.font.pixelSize
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 7

                Controls.Button {
                    text: "✓ Completed"
                    enabled: root.activeNote && !root.activeNote.done
                    contentItem: Text {
                        text: "✓ Completed"
                        color: floatingCard.currentFgColor
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered ? Qt.rgba(floatingCard.currentFgColor.r, floatingCard.currentFgColor.g, floatingCard.currentFgColor.b, 0.15) : "transparent"
                        radius: 6
                        border.width: 1
                        border.color: Qt.rgba(floatingCard.currentFgColor.r, floatingCard.currentFgColor.g, floatingCard.currentFgColor.b, 0.3)
                    }
                    onClicked: {
                        if (root.activeNote) root.markDone(root.activeNote.id)
                        root.closeFloatingNote()
                    }
                }

                Controls.Button {
                    text: "Delete"
                    flat: true
                    contentItem: Text {
                        text: "Delete"
                        color: floatingCard.currentFgColor
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered ? Qt.rgba(floatingCard.currentFgColor.r, floatingCard.currentFgColor.g, floatingCard.currentFgColor.b, 0.15) : "transparent"
                        radius: 6
                        border.width: 1
                        border.color: Qt.rgba(floatingCard.currentFgColor.r, floatingCard.currentFgColor.g, floatingCard.currentFgColor.b, 0.3)
                    }
                    onClicked: {
                        if (root.activeNote) root.deleteNote(root.activeNote.id)
                        root.closeFloatingNote()
                    }
                }

                Item { Layout.fillWidth: true }

                Controls.ToolButton {
                    text: root.editMode ? "Save changes" : "Close"
                    highlighted: root.editMode
                    contentItem: Text {
                        text: root.editMode ? "Save changes" : "Close"
                        color: floatingCard.currentFgColor
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered ? Qt.rgba(floatingCard.currentFgColor.r, floatingCard.currentFgColor.g, floatingCard.currentFgColor.b, 0.2) : Qt.rgba(floatingCard.currentFgColor.r, floatingCard.currentFgColor.g, floatingCard.currentFgColor.b, 0.1)
                        radius: 6
                        border.width: 1
                        border.color: Qt.rgba(floatingCard.currentFgColor.r, floatingCard.currentFgColor.g, floatingCard.currentFgColor.b, 0.4)
                    }
                    onClicked: {
                        if (root.editMode && root.activeNote) {
                            var dDay = Number(root.daysModel[popupRemDay.currentIndex])
                            var dMon = popupRemMon.currentIndex + 1
                            var dYear = Number(root.yearsModel[popupRemYear.currentIndex])
                            var dHour = Number(root.hoursModel[popupRemHour.currentIndex])
                            var dMin = Number(root.minutesModel[popupRemMin.currentIndex])

                            var remAt = popupReminderCheck.checked ? makeTimestamp(dDay, dMon, dYear, dHour, dMin) : 0

                            var dueDayVal = Number(root.daysModel[popupDueDay.currentIndex])
                            var dueMonVal = popupDueMon.currentIndex + 1
                            var dueYearVal = Number(root.yearsModel[popupDueYear.currentIndex])
                            var dueHourVal = Number(root.hoursModel[popupDueHour.currentIndex])
                            var dueMinVal = Number(root.minutesModel[popupDueMin.currentIndex])

                            var dAt = popupDueCheck.checked ? makeTimestamp(dueDayVal, dueMonVal, dueYearVal, dueHourVal, dueMinVal) : 0

                            var success = root.updateNoteDetails(
                                root.activeNote.id,
                                popupBodyText.text,
                                popupReminderCheck.checked,
                                remAt,
                                dAt,
                                popupImportanceBox.currentIndex
                            )

                            if (success) {
                                root.closeFloatingNote()
                            }
                        } else {
                            root.closeFloatingNote()
                        }
                    }
                }
            }
        }
    }
}
