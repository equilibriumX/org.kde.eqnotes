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
    Controls.ComboBox {
        Kirigami.FormData.label: "Default importance for new notes:"
        model: ["Low", "Normal", "High"]
        currentIndex: Math.max(0, Math.min(2, plasmoid.configuration.defaultImportance))
        onActivated: plasmoid.configuration.defaultImportance = currentIndex
    }

    Controls.Label {
        Kirigami.FormData.label: "Global shortcut:"
        text: "A separate shortcut for opening a new note requires an additional KDE action. It is not linked to activating the panel."
        wrapMode: Text.WordWrap
        Layout.maximumWidth: 460
    }
}
