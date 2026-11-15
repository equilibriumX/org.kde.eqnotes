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

Kirigami.FormLayout {
    Controls.CheckBox {
        Kirigami.FormData.label: "New note window:"
        text: "Always keep the window above other windows"
        checked: plasmoid.configuration.newNoteAlwaysOnTop
        onToggled: plasmoid.configuration.newNoteAlwaysOnTop = checked
    }

    Controls.Label {
        text: "Additional options for notes, floating cards, and reminders can be added to this category."
        wrapMode: Text.WordWrap
        Layout.maximumWidth: 480
        opacity: 0.75
    }
}
