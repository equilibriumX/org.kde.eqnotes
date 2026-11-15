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
import QtQuick.LocalStorage as LocalStorage
import org.kde.notification as KDENotification
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    preferredRepresentation: PlasmoidItem.FullRepresentation

    toolTipMainText: "EQ-Notes"
    toolTipSubText: "Notes and reminders"

    property var db: null
    property var notes: []
    property int selectedId: -1
    property string editorText: ""

    property bool reminderEnabled: false
    property int reminderDay: new Date().getDate()
    property int reminderMonth: new Date().getMonth() + 1
    property int reminderYear: new Date().getFullYear()
    property int reminderHour: 9
    property int reminderMinute: 0

    property bool dueEnabled: false
    property int dueDay: new Date().getDate()
    property int dueMonth: new Date().getMonth() + 1
    property int dueYear: new Date().getFullYear()
    property int dueHour: 23
    property int dueMinute: 59

    property int importance: 1

    property bool noteWindowOpen: false
    property bool editMode: false
    property var activeNote: null
    property var notifiedIds: ({})
    property string statusMessage: ""
    property bool databaseReady: false

    readonly property color accentColor: "#8295ff"
    readonly property color accentSoft: "#26345f"
    readonly property color surfaceColor: Kirigami.Theme.backgroundColor
    readonly property color cardColor: Kirigami.Theme.alternateBackgroundColor
    readonly property color subtleBorder: Qt.rgba(Kirigami.Theme.textColor.r,
                                                  Kirigami.Theme.textColor.g,
                                                  Kirigami.Theme.textColor.b, 0.10)
    readonly property int stickerRadius: Plasmoid.configuration.stickerRadius
    readonly property bool stickerShadow: Plasmoid.configuration.stickerShadow
    readonly property bool newNoteAlwaysOnTop: Plasmoid.configuration.newNoteAlwaysOnTop

    readonly property var activeReminders: {
        var arr = []
        for (var i = 0; i < notes.length; ++i) {
            if (notes[i].reminderEnabled && !notes[i].done)
                arr.push(notes[i])
        }
        return arr.sort(function(a, b) {
            return Number(a.reminderAt) - Number(b.reminderAt)
        })
    }
    readonly property var completedNotesCount: {
        var count = 0
        for (var i = 0; i < notes.length; ++i) {
            if (notes[i].done) count++
        }
        return count
    }

    readonly property var daysModel: ["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31"]
    readonly property var monthsModel: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    readonly property var yearsModel: ["2026", "2027", "2028", "2029", "2030"]
    readonly property var hoursModel: ["00","01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23"]
    readonly property var minutesModel: ["00","05","10","15","20","25","30","35","40","45","50","55"]

    function importanceName(level) {
        if (Number(level) === 2) return "HIGH"
        if (Number(level) === 0) return "LOW"
        return "NORMAL"
    }

    function importanceColor(level) {
        if (Number(level) === 2) return "#ffffff"
        if (Number(level) === 0) return "#69b9a0"
        return "#444444"
    }

    // Determines whether the active Plasma/Kirigami background is dark.
    // Used for automatic text contrast on Plasma stickers.
    function isDarkPlasmaTheme() {
        var c = Kirigami.Theme.backgroundColor
        var luminance = 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
        return luminance < 0.50
    }

    function stickerForegroundColor(importanceLevel) {
        var textMode = Plasmoid.configuration.stickerTextColor || "default"
        if (textMode === "dark") return "#202124"
        if (textMode === "light") return "#ffffff"

        // Default keeps the existing automatic contrast behavior.
        if (Number(importanceLevel) === 2) return "#ffffff"
        if (Plasmoid.configuration.stickerPalette === "plasma")
            return isDarkPlasmaTheme() ? "#ffffff" : "#202124"
        return Number(importanceLevel) === 0 ? "#333333" : "#1e1e1e"
    }

    function stickerSecondaryTextColor(importanceLevel) {
        var c = stickerForegroundColor(importanceLevel)
        if ((Plasmoid.configuration.stickerTextColor || "default") === "default" && Number(importanceLevel) === 2)
            return Qt.rgba(1, 1, 1, 0.82)
        return Qt.rgba(c.r, c.g, c.b, 0.72)
    }

    function pastelColor(index) {
        var pastel = ["#fff9c4", "#b3e5fc", "#c8e6c9", "#f8bbd0", "#e1bee7", "#ffe0b2"]
        var classic = ["#FFC107", "#03A9F4", "#4CAF50", "#E91E63", "#9C27B0", "#FF5722"]
        var gray = ["#eeeeee", "#d6d6d6", "#c2c2c2", "#aaaaaa", "#969696", "#e2e2e2"]

        // Colors from the active Plasma/Kirigami theme, including semantic accents.
        var plasma = [
            Kirigami.Theme.highlightColor,
            Kirigami.Theme.linkColor,
            Kirigami.Theme.positiveTextColor,
            Kirigami.Theme.neutralTextColor,
            Kirigami.Theme.visitedLinkColor,
            Kirigami.Theme.alternateBackgroundColor
        ]

        // Transparent but subtly tinted backgrounds; alpha is intentionally low.
        var transparent = [
            Qt.rgba(0.98, 0.78, 0.30, 0.34),
            Qt.rgba(0.28, 0.68, 0.92, 0.32),
            Qt.rgba(0.34, 0.72, 0.48, 0.32),
            Qt.rgba(0.91, 0.43, 0.63, 0.30),
            Qt.rgba(0.62, 0.48, 0.86, 0.32),
            Qt.rgba(0.94, 0.61, 0.34, 0.32)
        ]

        var paletteName = Plasmoid.configuration.stickerPalette
        var palette = pastel
        if (paletteName === "classic") palette = classic
        else if (paletteName === "gray") palette = gray
        else if (paletteName === "plasma") palette = plasma
        else if (paletteName === "transparent") palette = transparent

        var color = palette[Math.abs(Number(index)) % palette.length]
        // Plasma colors are softened to make them pleasant sticker backgrounds.
        if (paletteName === "plasma") return Qt.tint(root.cardColor, Qt.rgba(color.r, color.g, color.b, 0.24))
        return color
    }

    function stickerColor(importanceLevel, index) {
        var imp = Number(importanceLevel)
        if (imp === 2) return "#e53935"
        if (imp === 0) return root.cardColor
        return pastelColor(index)
    }

    function stickerOffsetX(id) {
        if (!Plasmoid.configuration.stickerRandomOffset) return 0
        var offsets = [-3, 4, -2, 5, 1, -4]
        return offsets[Math.abs(Number(id)) % offsets.length]
    }

    function stickerOffsetY(id) {
        if (!Plasmoid.configuration.stickerRandomOffset) return 0
        var offsets = [3, -4, 5, -2, 4, -3]
        return offsets[Math.abs(Number(id)) % offsets.length]
    }

    function stickerRotation(id) {
        if (!Plasmoid.configuration.stickerRotation) return 0
        var angles = [-2.0, 1.6, -1.1, 2.2, -1.5, 1.3]
        return angles[Math.abs(Number(id)) % angles.length]
    }

    function dateTimeText(ms) {
        var value = Number(ms)
        if (!value || value <= 0 || isNaN(value)) return ""
        return Qt.formatDateTime(new Date(value), "dd.MM.yyyy. HH:mm")
    }

    function shortDateText(ms) {
        var value = Number(ms)
        if (!value || value <= 0 || isNaN(value)) return ""
        return Qt.formatDate(new Date(value), "dd.MM.yyyy.")
    }

    function makeTimestamp(d, m, y, h, min) {
        var result = new Date(Number(y), Number(m) - 1, Number(d), Number(h), Number(min), 0, 0)
        return result.getTime()
    }

    function makeTitle(body) {
        var lines = String(body).trim().split(/\r?\n/)
        var first = ""
        for (var i = 0; i < lines.length; ++i) {
            if (lines[i].trim().length > 0) {
                first = lines[i].trim()
                break
            }
        }
        if (!first) return "New note"
        return first.length > 48 ? first.substring(0, 48).trim() + "…" : first
    }

    function openFloatingNote(noteItem) {
        root.activeNote = noteItem
        root.selectedId = noteItem.id
        root.editMode = false
        root.noteWindowOpen = true
    }

    function closeFloatingNote() {
        root.noteWindowOpen = false
        root.editMode = false
        loadNotes()
    }

    function openNewNoteWindow() {
        root.editorText = ""
        root.reminderEnabled = false
        root.dueEnabled = false
        root.importance = Plasmoid.configuration.defaultImportance

        var now = new Date()
        root.reminderDay = now.getDate()
        root.reminderMonth = now.getMonth() + 1
        root.reminderYear = now.getFullYear()
        root.reminderHour = 9
        root.reminderMinute = 0

        root.dueDay = now.getDate()
        root.dueMonth = now.getMonth() + 1
        root.dueYear = now.getFullYear()
        root.dueHour = 23
        root.dueMinute = 59

        newNoteDialogInstance.visible = true
        newNoteDialogInstance.requestActivate()
    }

    function clearCompletedNotes() {
        if (!db) return
        try {
            db.transaction(function(tx) {
                tx.executeSql("DELETE FROM notes WHERE done = 1")
            })
            loadNotes()
            statusMessage = "Completed items have been cleared"
        } catch (e) {
            statusMessage = "Error clearing completed items"
        }
    }

    function executeClearAllNotes() {
        if (!db) return
        try {
            db.transaction(function(tx) {
                tx.executeSql("DELETE FROM notes")
            })
            loadNotes()
            activeNote = null
            selectedId = -1
            statusMessage = "All notes have been deleted"
        } catch (e) {
            statusMessage = "Error deleting all notes"
        }
    }

    ReminderPopupDialog {
        id: reminderPopupDialog
    }

    onVisibleChanged: {
        if (visible && databaseReady) {
            loadNotes()
            checkReminders()
            checkExpiredDoneNotes()
        }
    }

    compactRepresentation: RowLayout {
        spacing: 2
        readonly property real largeIconSize: Kirigami.Units.iconSizes.small * 2

        Layout.minimumWidth: largeIconSize * 2 + spacing
        Layout.minimumHeight: largeIconSize

        Item {
            Layout.preferredWidth: parent.largeIconSize
            Layout.preferredHeight: parent.largeIconSize

            Kirigami.Icon {
                anchors.fill: parent
                source: "list-add"
                active: plusMouse.containsMouse
            }

            MouseArea {
                id: plusMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openNewNoteWindow()
            }
        }

            Item {
            Layout.preferredWidth: parent.largeIconSize
            Layout.preferredHeight: parent.largeIconSize

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: mainMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : "transparent"
                    border.color: mainMouse.containsMouse ? "#38BDF8" : "transparent"
                    border.width: 1

                    Image {
                        anchors.fill: parent
                        anchors.margins: 2
                        source: Qt.resolvedUrl("assets/eq-notes.svg")
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                }

                MouseArea {
                    id: mainMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.expanded = !root.expanded
                }
            }
    }

    NewNoteDialog {
        id: newNoteDialogInstance
    }

    fullRepresentation: Item {
        id: app
        implicitWidth: 1020
        implicitHeight: 620

        Rectangle {
            id: fullView
            anchors.fill: parent
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                // 1. LEFT SIDE: NOTES
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10

                    Rectangle {
                        id: notesColumn
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 14
                        color: "transparent"

                        Item {
                            anchors.fill: parent
                            anchors.margins: 12

                            // HEDER NA DNU
                            Item {
                                id: bottomNotesHeader
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: notesHeaderContent.implicitHeight

                                ColumnLayout {
                                    id: notesHeaderContent
                                    anchors.fill: parent
                                    spacing: 8

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 1
                                        color: root.subtleBorder
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 7

                                        Rectangle {
                                            width: 30
                                            height: 30
                                            radius: 9
                                            color: "#29365d"
                                            Kirigami.Icon {
                                                anchors.centerIn: parent
                                                source: "view-pim-notes"
                                                width: 17
                                                height: 17
                                                color: "#a9b7ff"
                                            }
                                        }

                                        ColumnLayout {
                                            spacing: 0
                                            Controls.Label {
                                                text: "Notes"
                                                font.bold: true
                                                font.pixelSize: 15
                                            }
                                            Controls.Label {
                                                text: root.notes.length + " total"
                                                opacity: 0.58
                                                font.pixelSize: 10
                                            }
                                        }

                                        Item { Layout.fillWidth: true }

                                        RowLayout {
                                            Layout.alignment: Qt.AlignRight
                                            spacing: 8

                                            Controls.Label {
                                                text: root.completedNotesCount > 0 ? "(" + root.completedNotesCount + ")" : ""
                                                color: Kirigami.Theme.disabledTextColor
                                                font.pixelSize: 16
                                                font.bold: true
                                                visible: root.completedNotesCount > 0
                                            }

                                            Controls.Button {
                                                icon.name: "edit-clear-list"
                                                flat: true
                                                Layout.preferredWidth: 28
                                                Layout.preferredHeight: 28
                                                icon.width: 28
                                                icon.height: 28
                                                Controls.ToolTip.visible: hovered
                                                Controls.ToolTip.text: "Remove completed notes/items"
                                                onClicked: root.clearCompletedNotes()
                                            }

                                            // BUTTON WITH MENU FOR DELETING ALL NOTES
                                            Controls.Button {
                                                id: deleteButton
                                                icon.name: "edit-delete"
                                                flat: true
                                                Layout.preferredWidth: 28
                                                Layout.preferredHeight: 28
                                                icon.width: 28
                                                icon.height: 28
                                                Controls.ToolTip.visible: hovered
                                                Controls.ToolTip.text: "Delete options"
                                                onClicked: deleteMenu.open()

                                                Controls.Menu {
                                                    id: deleteMenu
                                                    Controls.MenuItem {
                                                        text: "Delete all"
                                                        icon.name: "edit-delete"
                                                        onTriggered: {
                                                            root.executeClearAllNotes()
                                                        }
                                                    }
                                                }
                                            }

                                            Controls.Button {
                                                icon.name: "view-refresh"
                                                flat: true
                                                Layout.preferredWidth: 28
                                                Layout.preferredHeight: 28
                                                icon.width: 28
                                                icon.height: 28
                                                Controls.ToolTip.visible: hovered
                                                Controls.ToolTip.text: "Refresh notes from the database"
                                                onClicked: {
                                                    root.loadNotes()
                                                    root.checkReminders()
                                                    root.checkExpiredDoneNotes()
                                                    root.statusMessage = "Refreshed"
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // STIKERI IZNAD HEDERA
                            Flickable {
                                id: stickersFlick
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: bottomNotesHeader.top
                                anchors.bottomMargin: 10
                                clip: true
                                contentWidth: width
                                contentHeight: stickersFlow.implicitHeight + 30
                                boundsBehavior: Flickable.StopAtBounds

                                Flow {
                                    id: stickersFlow
                                    width: stickersFlick.width - 12
                                    x: 6
                                    y: 8
                                    spacing: 14

                                    Repeater {
                                        model: root.notes
                                        delegate: StickerCard {}
                                    }
                                }
                            }

                            // NAPOMENA (STATUSNA PORUKA) KAO STIKER IZNAD HEDERA
                            Rectangle {
                                id: statusSticker
                                visible: root.statusMessage.length > 0
                                anchors.left: parent.left
                                anchors.bottom: bottomNotesHeader.top
                                anchors.bottomMargin: 8
                                height: 26
                                width: statusText.implicitWidth + 20
                                radius: 8
                                color: root.statusMessage.indexOf("Error") === 0 ? "#ef777e" : "#26345f"
                                border.width: 1
                                border.color: root.accentColor
                                z: 9

                                Controls.Label {
                                    id: statusText
                                    anchors.centerIn: parent
                                    text: root.statusMessage
                                    color: root.statusMessage.indexOf("Error") === 0 ? "#ffffff" : "#a9b7ff"
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }

                            // PLUS DUGME U DONJEM LEVOM UGLU
                            Rectangle {
                                id: floatingPlusButton
                                width: 48
                                height: 48
                                radius: 14
                                color: plusMouseArea.containsMouse ? Qt.lighter("#29365d", 1.2) : "#29365d"
                                border.width: 1
                                border.color: root.accentColor

                                z: 10
                                anchors.left: parent.left
                                anchors.bottom: statusSticker.top
                                anchors.bottomMargin: 8
                                anchors.leftMargin: 0

                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    source: "list-add"
                                    width: 26
                                    height: 26
                                    color: "#a9b7ff"
                                }

                                MouseArea {
                                    id: plusMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.openNewNoteWindow()
                                }

                                Controls.ToolTip.visible: plusMouseArea.containsMouse
                                Controls.ToolTip.text: "New note"
                            }
                        }
                    }
                }

                // 2. DESNA STRANA: PODSETNICI
                Rectangle {
                    id: remindersColumn
                    visible: root.activeReminders.length > 0
                    Layout.preferredWidth: 200
                    Layout.minimumWidth: 180
                    Layout.fillHeight: true
                    radius: 14
                    color: "transparent"

                    Item {
                        anchors.fill: parent
                        anchors.margins: 12

                        // HEDER NA DNU
                        Item {
                            id: bottomHeaderContainer
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: headerColumnContent.implicitHeight

                            ColumnLayout {
                                id: headerColumnContent
                                anchors.fill: parent
                                spacing: 8

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: root.subtleBorder
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 7

                                    Rectangle {
                                        width: 30
                                        height: 30
                                        radius: 9
                                        color: "#29365d"
                                        Kirigami.Icon {
                                            anchors.centerIn: parent
                                            source: "appointment"
                                            width: 17
                                            height: 17
                                            color: "#a9b7ff"
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        Controls.Label {
                                            text: "Reminders"
                                            font.bold: true
                                            font.pixelSize: 15
                                        }
                                        Controls.Label {
                                            text: root.activeReminders.length + " active"
                                            opacity: 0.58
                                            font.pixelSize: 10
                                        }
                                    }

                                    Controls.Button {
                                        icon.name: "edit-clear-list"
                                        flat: true
                                        Layout.preferredWidth: 28
                                        Layout.preferredHeight: 28
                                        Controls.ToolTip.visible: hovered
                                        Controls.ToolTip.text: "Remove completed items"
                                        onClicked: root.clearCompletedNotes()
                                    }
                                }
                            }
                        }

                        // LISTA PODSETNIKA USIDRENA NA DNO
                        ListView {
                            id: reminderList
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: bottomHeaderContainer.top
                            anchors.bottomMargin: 10
                            height: Math.min(parent.height - bottomHeaderContainer.height - 10, contentHeight)
                            clip: true
                            spacing: 8
                            model: root.activeReminders
                            verticalLayoutDirection: ListView.TopToBottom

                            delegate: Rectangle {
                                id: reminderCard
                                required property var modelData
                                width: reminderList.width
                                height: reminderContent.implicitHeight + 18
                                radius: 10
                                color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.075)
                                border.width: 1
                                border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.22)

                                Rectangle {
                                    width: 3
                                    radius: 2
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    color: root.importanceColor(modelData.importance)
                                }

                                ColumnLayout {
                                    id: reminderContent
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 8
                                    anchors.topMargin: 8
                                    anchors.bottomMargin: 8
                                    spacing: 4

                                    Controls.Label {
                                        text: modelData.title
                                        Layout.fillWidth: true
                                        font.bold: true
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }
                                    Controls.Label {
                                        text: root.dateTimeText(modelData.reminderAt)
                                        Layout.fillWidth: true
                                        font.pixelSize: 10
                                        opacity: 0.7
                                    }
                                    Controls.Label {
                                        text: root.importanceName(modelData.importance)
                                        color: root.importanceColor(modelData.importance)
                                        font.pixelSize: 9
                                        font.bold: true
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.openFloatingNote(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }

        EditNoteDialog {}
    }

    function openDatabase() {
        try {
            db = LocalStorage.LocalStorage.openDatabaseSync("EQNotesProfil", "1.0", "EQ-Notes local notes", 2 * 1024 * 1024)
            db.transaction(function(tx) {
                tx.executeSql("CREATE TABLE IF NOT EXISTS notes (" +
                            "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                            "title TEXT, body TEXT, created INTEGER, updated INTEGER, " +
                            "done INTEGER DEFAULT 0, reminder_enabled INTEGER DEFAULT 0, " +
                            "reminder_at INTEGER DEFAULT 0, due_at INTEGER DEFAULT 0, " +
                            "importance INTEGER DEFAULT 1, completed_at INTEGER DEFAULT 0)")

                try {
                    tx.executeSql("ALTER TABLE notes ADD COLUMN completed_at INTEGER DEFAULT 0")
                } catch(e) {}
            })
            databaseReady = true
            statusMessage = ""
            loadNotes()
            checkReminders()
            checkExpiredDoneNotes()
        } catch (e) {
            databaseReady = false
            statusMessage = "Error: database is unavailable"
        }
    }

    function loadNotes() {
        if (!db) return
        try {
            var rows = []
            db.readTransaction(function(tx) {
                var rs = tx.executeSql("SELECT * FROM notes ORDER BY created DESC, id DESC")
                for (var i = 0; i < rs.rows.length; ++i) {
                    var r = rs.rows.item(i)
                    rows.push({
                        id: Number(r.id),
                        title: String(r.title || ""),
                        body: String(r.body || ""),
                        created: Number(r.created || 0),
                        updated: Number(r.updated || 0),
                        done: Number(r.done) === 1,
                        reminderEnabled: Number(r.reminder_enabled) === 1,
                        reminderAt: Number(r.reminder_at || 0),
                        dueAt: Number(r.due_at || 0),
                        importance: Number(r.importance || 1),
                        completedAt: Number(r.completed_at || 0)
                    })
                }
            })
            notes = rows
            if (selectedId >= 0) {
                for (var j = 0; j < notes.length; ++j) {
                    if (Number(notes[j].id) === Number(selectedId)) {
                        activeNote = notes[j]
                        break
                    }
                }
            }
        } catch (e) {
            statusMessage = "Error loading notes"
        }
    }

    function saveNewNote() {
        var body = editorText.trim()
        if (!body.length || !databaseReady || !db) return

        var now = Date.now()
        var reminderAt = reminderEnabled ? makeTimestamp(reminderDay, reminderMonth, reminderYear, reminderHour, reminderMinute) : 0
        var dueAt = dueEnabled ? makeTimestamp(dueDay, dueMonth, dueYear, dueHour, dueMinute) : 0

        if (reminderEnabled && reminderAt <= now) {
            statusMessage = "Error: reminder must be set in the future"
            return
        }

        try {
            db.transaction(function(tx) {
                tx.executeSql(
                    "INSERT INTO notes (title, body, created, updated, done, reminder_enabled, reminder_at, due_at, importance, completed_at) " +
                    "VALUES (?, ?, ?, ?, 0, ?, ?, ?, ?, 0)",
                    [makeTitle(body), body, now, now, reminderEnabled ? 1 : 0, reminderAt, dueAt, importance])
            })

            editorText = ""
            reminderEnabled = false
            dueEnabled = false
            statusMessage = "Note saved"
            loadNotes()
        } catch (e) {
            statusMessage = "Error saving note"
        }
    }

    function updateNoteDetails(id, body, remEnabled, remAt, dAt, imp) {
        if (!db) return false
        var cleanBody = String(body).trim()
        if (!cleanBody.length) {
            statusMessage = "A note cannot be empty"
            return false
        }

        var now = Date.now()
        var finalRemEnabled = remEnabled
        if (finalRemEnabled && remAt <= now) {
            finalRemEnabled = 0
        }

        try {
            db.transaction(function(tx) {
                tx.executeSql("UPDATE notes SET body=?, reminder_enabled=?, reminder_at=?, due_at=?, importance=?, updated=? WHERE id=?",
                              [cleanBody, finalRemEnabled ? 1 : 0, remAt, dAt, imp, now, Number(id)])
            })
            loadNotes()
            statusMessage = "Note updated successfully"
            return true
        } catch (e) {
            statusMessage = "Error saving changes"
            return false
        }
    }

    function deleteNote(id) {
        if (!db) return
        try {
            db.transaction(function(tx) {
                tx.executeSql("DELETE FROM notes WHERE id=?", [Number(id)])
            })
            closeFloatingNote()
            activeNote = null
            selectedId = -1
            loadNotes()
            statusMessage = "Note deleted"
        } catch (e) {
            statusMessage = "Error deleting note"
        }
    }

    function markDone(id) {
        if (!db) return
        var now = Date.now()
        try {
            db.transaction(function(tx) {
                tx.executeSql("UPDATE notes SET done=1, reminder_enabled=0, completed_at=? WHERE id=?", [now, Number(id)])
            })
            loadNotes()
            doneNotification.publish()
            statusMessage = "Note marked as completed"
        } catch (e) {
            statusMessage = "Error marking note as completed"
        }
    }

    function checkExpiredDoneNotes() {
        if (!db || !databaseReady) return
        var now = Date.now()
        var limitMs = 12 * 60 * 60 * 1000

        try {
            var changed = false
            db.transaction(function(tx) {
                var rs = tx.executeSql("SELECT id FROM notes WHERE done=1 AND completed_at > 0 AND (? - completed_at) >= ?", [now, limitMs])
                if (rs.rows.length > 0) {
                    tx.executeSql("DELETE FROM notes WHERE done=1 AND completed_at > 0 AND (? - completed_at) >= ?", [now, limitMs])
                    changed = true
                }
            })
            if (changed) loadNotes()
        } catch(e) {}
    }

    function checkReminders() {
        if (!db || !databaseReady) return
        var now = Date.now()

        for (var i = 0; i < notes.length; ++i) {
            var item = notes[i]
            if (item.reminderEnabled && !item.done && Number(item.reminderAt) > 0 && Number(item.reminderAt) <= now && notifiedIds[item.id] !== true) {
                notifiedIds[item.id] = true
                reminderPopupDialog.showReminder(item)
                break
            }
        }
    }

    function acknowledgeReminder(id) {
        if (!db) return
        try {
            db.transaction(function(tx) {
                tx.executeSql("UPDATE notes SET reminder_enabled=0 WHERE id=?", [Number(id)])
            })
            loadNotes()
            statusMessage = "Reminder acknowledged and closed"
        } catch (e) {
            statusMessage = "Error updating reminder"
        }
    }

    Component.onCompleted: openDatabase()

    KDENotification.Notification {
        id: reminderNotification
        componentName: "plasma_workspace"
        eventId: "notification"
        title: "EQ-Notes – reminder"
        text: ""
        iconName: "view-pim-tasks"
    }

    KDENotification.Notification {
        id: doneNotification
        componentName: "plasma_workspace"
        eventId: "notification"
        title: "EQ-Notes"
        text: "The item has been marked as completed (it will be automatically deleted in 12 hours)."
        iconName: "dialog-positive"
    }

    Timer {
        interval: 15000
        running: root.databaseReady
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.checkReminders()
            root.checkExpiredDoneNotes()
        }
    }
}
