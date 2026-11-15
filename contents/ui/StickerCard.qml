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

Item {
    id: stickerSlot
    required property var modelData

    width: Math.min(210, Math.max(100, stickerTextMeasure.implicitWidth + 36))
    height: Math.max(82, stickerContentCol.implicitHeight + 20)

    Text {
        id: stickerTextMeasure
        visible: false
        text: modelData.title
        font.bold: true
        font.family: "Sans Serif"
        font.pixelSize: 16
    }

    // FLOATING EFFECT - DOUBLE SHADOW (AMBIENT + DIRECT)
    Rectangle {
        visible: root.stickerShadow
        anchors.fill: noteCardBg
        x: noteCardBg.x + 2
        y: noteCardBg.y + 6
        radius: noteCardBg.radius
        color: "#22000000"
        scale: 0.98
    }

    Rectangle {
        visible: root.stickerShadow
        anchors.fill: noteCardBg
        x: noteCardBg.x + 1
        y: noteCardBg.y + 3
        radius: noteCardBg.radius
        color: "#33000000"
    }

    Rectangle {
        id: noteCardBg
        anchors.fill: parent
        x: root.stickerOffsetX(modelData.id)
        y: root.stickerOffsetY(modelData.id)
        rotation: root.stickerRotation(modelData.id)
        transformOrigin: Item.Center
        antialiasing: true
        radius: root.stickerRadius

        // Use a gradient transition instead of a plain color:
        gradient: Gradient {
            GradientStop {
                position: 0.0;
                color: Qt.lighter(root.stickerColor(modelData.importance, modelData.id), 1.08)
            }
            GradientStop {
                position: 1.0;
                color: Qt.darker(root.stickerColor(modelData.importance, modelData.id), 1.12)
            }
        }

        border.width: root.selectedId === modelData.id ? 2 : 1
        border.color: root.selectedId === modelData.id ? root.accentColor : Qt.rgba(0, 0, 0, 0.16)
    }

    ColumnLayout {
        id: stickerContentCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 9
        spacing: 4
        rotation: 0

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Rectangle {
                width: 6
                height: 6
                radius: 3
                color: Number(modelData.importance) === 2 ? "#ffffff" : root.importanceColor(modelData.importance)
            }
            Controls.Label {
                text: root.importanceName(modelData.importance)
                color: root.stickerForegroundColor(modelData.importance)
                font.family: "Sans Serif"
                font.pixelSize: 8
                font.bold: true
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Rectangle {
                width: 20
                height: 20
                radius: 10
                color: modelData.done ? "#2e7d32" : Qt.rgba(0,0,0,0.12)
                border.width: 1
                border.color: modelData.done ? "#1b5e20" : Qt.rgba(0,0,0,0.25)

                Text {
                    anchors.centerIn: parent
                    text: "✓"
                    font.pixelSize: 11
                    font.bold: true
                    color: modelData.done ? "#ffffff" : "#444444"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!modelData.done) {
                            root.markDone(modelData.id)
                        }
                    }
                }
            }
        }

        Controls.Label {
            text: modelData.title
            Layout.fillWidth: true
            font.bold: true
            font.family: "Sans Serif"
            font.pixelSize: 16
            color: root.stickerForegroundColor(modelData.importance)
            wrapMode: Text.Wrap
            font.strikeout: modelData.done
        }

        Controls.Label {
            text: root.shortDateText(modelData.created)
            Layout.fillWidth: true
            font.family: "Sans Serif"
            font.pixelSize: 8
            color: root.stickerSecondaryTextColor(modelData.importance)
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.rightMargin: 24
        cursorShape: Qt.PointingHandCursor
        onClicked: root.openFloatingNote(modelData)
    }
}
