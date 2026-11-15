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
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmaCore.Dialog {
    id: newNoteDialog
    visible: false
    flags: Qt.Window | (root.newNoteAlwaysOnTop ? Qt.WindowStaysOnTopHint : 0)
    location: PlasmaCore.Types.Floating
    type: PlasmaCore.Dialog.Dialog

    x: (Screen.width - width) / 2
    y: (Screen.height - height) / 2

    onVisibleChanged: {
        if (visible) {
            focusTimer.restart()
        }
    }

    mainItem: Rectangle {
        implicitWidth: 620
        implicitHeight: 460
        color: "transparent"

        // The timer is placed inside the visual element (the mainItem root)
        Timer {
            id: focusTimer
            interval: 50
            repeat: false
            onTriggered: {
                standaloneEditor.forceActiveFocus()
                standaloneEditor.cursorPosition = standaloneEditor.length
            }
        }

        Item {
            anchors.fill: parent

            // Compact title and pencil icon at the upper-left corner.
            Kirigami.Icon {
                x: 3
                y: 3
                width: 16
                height: 16
                source: "document-edit"
                color: Kirigami.Theme.textColor
            }

            Controls.Label {
                x: 23
                y: 0
                text: "New note"
                color: Kirigami.Theme.textColor
                font.bold: true
                font.pixelSize: 14
            }

            // Large close control, fixed to the extreme upper-right corner.
            Controls.Button {
                anchors.top: parent.top
                anchors.right: parent.right
                width: 44
                height: 44
                contentItem: Text {
                        text: "×"
                        color: Kirigami.Theme.textColor
                        font.pixelSize: 40
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                flat: true
                padding: 0
                font.pixelSize: 36
                font.bold: false
                palette.buttonText: Kirigami.Theme.textColor
                background: Item {}
                onClicked: newNoteDialog.visible = false
            }

            // The writing surface is completely transparent and has no border.
            Item {
                id: editorSurface
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 44
                anchors.bottom: optionsContainer.top
                anchors.bottomMargin: 5

                Controls.TextArea {
                    id: standaloneEditor
                    anchors.fill: parent
                    anchors.rightMargin: 44
                    anchors.bottomMargin: 38
                    placeholderText: "Start typing here... (Enter to save, ESC to close)"
                    wrapMode: TextEdit.Wrap
                    selectByMouse: true
                    text: root.editorText
                    onTextChanged: root.editorText = text
                    background: Item {}
                    font.family: "Sans Serif"
                    font.pixelSize: 20
                    focus: true

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (root.editorText.trim().length > 0 && root.databaseReady) {
                                root.saveNewNote();
                                newNoteDialog.visible = false;
                                event.accepted = true;
                            }
                        } else if (event.key === Qt.Key_Escape) {
                            if (root.editorText.trim().length === 0) {
                                newNoteDialog.visible = false;
                                event.accepted = true;
                            }
                        }
                    }
                }

                // Bare plus sign directly on the transparent writing surface.
                Controls.Button {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    width: 60
                    height: 60
                    flat: true
                    padding: 0

                    background: Item {}

                    contentItem: Text {
                        text: "+"
                        color: Kirigami.Theme.textColor
                        font.pixelSize: 60
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    enabled: root.editorText.trim().length > 0 && root.databaseReady

                    Controls.ToolTip.visible: hovered
                    Controls.ToolTip.text: "Save note"

                    onClicked: {
                        root.saveNewNote()
                        newNoteDialog.visible = false
                    }
                }
            }

            // Keep the reminder, due-date and importance controls close to the bottom edge.
            Item {
                id: optionsContainer
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 3
                height: newNoteOptCol.implicitHeight

                                ColumnLayout {
                    id: newNoteOptCol
                    anchors.fill: parent
                    spacing: 8



                    RowLayout {
                        visible: root.reminderEnabled
                        Layout.fillWidth: true
                        spacing: 6

                        Controls.Label { text: "Notify:"; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: 65 }

                        Controls.ComboBox {
                            model: root.daysModel
                            currentIndex: Math.max(0, root.daysModel.indexOf(String(root.reminderDay)))
                            onActivated: root.reminderDay = Number(root.daysModel[currentIndex])
                            Layout.preferredWidth: 60
                            font.pixelSize: 11
                            contentItem: Text {
                                text: parent.displayText
                                color: Kirigami.Theme.textColor
                                font.pixelSize: parent.font.pixelSize
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                        Controls.ComboBox {
                            model: root.monthsModel
                            currentIndex: Math.max(0, root.reminderMonth - 1)
                            onActivated: root.reminderMonth = currentIndex + 1
                            Layout.preferredWidth: 70
                            font.pixelSize: 11
                            contentItem: Text {
                                text: parent.displayText
                                color: Kirigami.Theme.textColor
                                font.pixelSize: parent.font.pixelSize
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                        Controls.ComboBox {
                            model: root.yearsModel
                            currentIndex: Math.max(0, root.yearsModel.indexOf(String(root.reminderYear)))
                            onActivated: root.reminderYear = Number(root.yearsModel[currentIndex])
                            Layout.preferredWidth: 75
                            font.pixelSize: 11
                            contentItem: Text {
                                text: parent.displayText
                                color: Kirigami.Theme.textColor
                                font.pixelSize: parent.font.pixelSize
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                        Item { Layout.preferredWidth: 8 }
                        Controls.ComboBox {
                            model: root.hoursModel
                            currentIndex: Math.max(0, root.reminderHour)
                            onActivated: root.reminderHour = currentIndex
                            Layout.preferredWidth: 60
                            font.pixelSize: 11
                            contentItem: Text {
                                text: parent.displayText
                                color: Kirigami.Theme.textColor
                                font.pixelSize: parent.font.pixelSize
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                        Controls.Label { text: ":"; font.pixelSize: 11; font.bold: true }
                        Controls.ComboBox {
                            model: root.minutesModel
                            currentIndex: Math.max(0, Math.floor(root.reminderMinute / 5))
                            onActivated: root.reminderMinute = currentIndex * 5
                            Layout.preferredWidth: 60
                            font.pixelSize: 11
                            contentItem: Text {
                                text: parent.displayText
                                color: Kirigami.Theme.textColor
                                font.pixelSize: parent.font.pixelSize
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    RowLayout {
                        visible: root.dueEnabled
                        Layout.fillWidth: true
                        spacing: 6

                        Controls.Label { text: "Due:"; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: 65 }

                        Controls.ComboBox {
                            model: root.daysModel
                            currentIndex: Math.max(0, root.daysModel.indexOf(String(root.dueDay)))
                            onActivated: root.dueDay = Number(root.daysModel[currentIndex])
                            Layout.preferredWidth: 60
                            font.pixelSize: 11
                            contentItem: Text {
                                text: parent.displayText
                                color: Kirigami.Theme.textColor
                                font.pixelSize: parent.font.pixelSize
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                        Controls.ComboBox {
                            model: root.monthsModel
                            currentIndex: Math.max(0, root.dueMonth - 1)
                            onActivated: root.dueMonth = currentIndex + 1
                            Layout.preferredWidth: 70
                            font.pixelSize: 11
                            contentItem: Text {
                                text: parent.displayText
                                color: Kirigami.Theme.textColor
                                font.pixelSize: parent.font.pixelSize
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                        Controls.ComboBox {
                            model: root.yearsModel
                            currentIndex: Math.max(0, root.yearsModel.indexOf(String(root.dueYear)))
                            onActivated: root.dueYear = Number(root.yearsModel[currentIndex])
                            Layout.preferredWidth: 75
                            font.pixelSize: 11
                            contentItem: Text {
                                text: parent.displayText
                                color: Kirigami.Theme.textColor
                                font.pixelSize: parent.font.pixelSize
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                        Item { Layout.preferredWidth: 8 }
                        Controls.ComboBox {
                            model: root.hoursModel
                            currentIndex: Math.max(0, root.dueHour)
                            onActivated: root.dueHour = currentIndex
                            Layout.preferredWidth: 60
                            font.pixelSize: 11
                            contentItem: Text {
                                text: parent.displayText
                                color: Kirigami.Theme.textColor
                                font.pixelSize: parent.font.pixelSize
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                        Controls.Label { text: ":"; font.pixelSize: 11; font.bold: true }
                        Controls.ComboBox {
                            model: root.minutesModel
                            currentIndex: Math.max(0, Math.floor(root.dueMinute / 5))
                            onActivated: root.dueMinute = currentIndex * 5
                            Layout.preferredWidth: 60
                            font.pixelSize: 11
                            contentItem: Text {
                                text: parent.displayText
                                color: Kirigami.Theme.textColor
                                font.pixelSize: parent.font.pixelSize
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Controls.CheckBox {
                            text: "Enable reminder"
                            checked: root.reminderEnabled
                            onToggled: root.reminderEnabled = checked
                            font.pixelSize: 11
                        }

                        Controls.CheckBox {
                            text: "Set due date"
                            checked: root.dueEnabled
                            onToggled: root.dueEnabled = checked
                            font.pixelSize: 11
                        }

                        Item { Layout.fillWidth: true }

                        Controls.Label { text: "Importance:"; font.pixelSize: 11 }
                        Controls.ComboBox {
                            model: ["Low", "Normal", "High"]
                            currentIndex: root.importance
                            onActivated: root.importance = currentIndex
                            Layout.preferredWidth: 110
                            font.pixelSize: 11
                            contentItem: Text {
                                text: parent.displayText
                                color: Kirigami.Theme.textColor
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
    }
}
