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
    id: reminderPopup
    visible: false
    // Keep the window on top and prevent it from closing when clicking outside
    flags: Qt.Window | Qt.WindowStaysOnTopHint | Qt.CustomizeWindowHint | Qt.WindowTitleHint
    location: PlasmaCore.Types.Floating
    type: PlasmaCore.Dialog.Dialog

    x: (Screen.width - width) / 2
    y: (Screen.height - height) / 2

    property var currentReminder: null

    function showReminder(note) {
        currentReminder = note
        visible = true
        requestActivate()
    }

    mainItem: Rectangle {
        implicitWidth: 420
        implicitHeight: 260
        color: Kirigami.Theme.backgroundColor
        radius: 12
        border.width: 1
        border.color: root.subtleBorder

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    width: 32
                    height: 32
                    radius: 10
                    color: "#e53935"
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        source: "appointment"
                        width: 18
                        height: 18
                        color: "#ffffff"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Controls.Label {
                        text: "Reminder!"
                        font.bold: true
                        font.pixelSize: 15
                        color: "#e53935"
                    }
                    Controls.Label {
                        text: reminderPopup.currentReminder ? root.dateTimeText(reminderPopup.currentReminder.reminderAt) : ""
                        font.pixelSize: 10
                        opacity: 0.6
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.subtleBorder
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: reminderTextLabel.implicitHeight + 10
                clip: true

                Controls.Label {
                    id: reminderTextLabel
                    width: parent.width
                    text: reminderPopup.currentReminder ? reminderPopup.currentReminder.body : ""
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.subtleBorder
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Controls.CheckBox {
                    id: ackCheck
                    text: "I have read this"
                    font.pixelSize: 12
                }

                Item { Layout.fillWidth: true }

                Controls.Button {
                    text: "Close"
                    enabled: ackCheck.checked
                    highlighted: true
                    onClicked: {
                        if (reminderPopup.currentReminder) {
                            root.acknowledgeReminder(reminderPopup.currentReminder.id)
                        }
                        ackCheck.checked = false
                        reminderPopup.visible = false
                    }
                }
            }
        }
    }
}
