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
        Kirigami.FormData.label: "Sticker palette:"
        model: ["Pastel", "Classic", "Grayscale", "Plasma theme", "Transparent stickers"]
        currentIndex: {
            var palettes = ["pastel", "classic", "gray", "plasma", "transparent"]
            var found = palettes.indexOf(plasmoid.configuration.stickerPalette)
            return found >= 0 ? found : 0
        }
        onActivated: {
            var palettes = ["pastel", "classic", "gray", "plasma", "transparent"]
            plasmoid.configuration.stickerPalette = palettes[currentIndex]
        }
    }

    Controls.ComboBox {
        Kirigami.FormData.label: "Sticker text color:"
        model: ["Default (automatic)", "Dark", "Light"]
        currentIndex: {
            var modes = ["default", "dark", "light"]
            var found = modes.indexOf(plasmoid.configuration.stickerTextColor)
            return found >= 0 ? found : 0
        }
        onActivated: {
            var modes = ["default", "dark", "light"]
            plasmoid.configuration.stickerTextColor = modes[currentIndex]
        }
    }

    Controls.SpinBox {
        Kirigami.FormData.label: "Corner radius:"
        from: 0
        to: 24
        value: plasmoid.configuration.stickerRadius
        onValueModified: plasmoid.configuration.stickerRadius = value
    }

    Controls.CheckBox {
        Kirigami.FormData.label: "Sticker effects:"
        text: "Subtle rotation"
        checked: plasmoid.configuration.stickerRotation
        onToggled: plasmoid.configuration.stickerRotation = checked
    }

    Controls.CheckBox {
        text: "Random sticker offset"
        checked: plasmoid.configuration.stickerRandomOffset
        onToggled: plasmoid.configuration.stickerRandomOffset = checked
    }

    Controls.CheckBox {
        text: "Sticker shadow"
        checked: plasmoid.configuration.stickerShadow
        onToggled: plasmoid.configuration.stickerShadow = checked
    }

    Controls.Label {
        text: "The Pastel and Classic palettes use vivid colors; Grayscale uses neutral tones; Plasma Theme uses colors from the active Plasma theme; Transparent Stickers have a subtly tinted, semi-transparent background. Changes apply to stickers with normal importance."
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        opacity: 0.75
    }
}
