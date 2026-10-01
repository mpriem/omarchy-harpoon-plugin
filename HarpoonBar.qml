import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "HarpoonModel.js" as HarpoonModel

// The bar button: the harpoon mark in the bar's foreground colour, a small
// count of bookmarked windows, lit while one of them is harpooned onto the
// screen. A click opens the list (SUPER+H, Space). Optional -- the overlay
// and the keybindings work without it; `omarchy plugin enable harpoon
// right` places it.
BarWidget {
  id: root
  moduleName: "harpoon"

  readonly property string statePath: Quickshell.env("HOME") + "/.local/state/omarchy/harpoon/list.json"
  property var slots: [null, null, null, null, null, null, null, null, null, null]
  readonly property int count: slots.filter(function(s) { return s }).length
  readonly property bool anyOverlaid: slots.some(function(s) { return s && s.overlaid })
  readonly property color fg: bar ? bar.barForeground : Color.foreground

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  FileView {
    path: root.statePath
    watchChanges: true
    printErrors: false
    onLoaded: root.slots = HarpoonModel.parseSlots(text())
    onLoadFailed: root.slots = [null, null, null, null, null, null, null, null, null, null]
    onFileChanged: reload()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    active: root.anyOverlaid
    tooltipText: root.count === 0 ? "Harpoon — nothing bookmarked (SUPER+H, A)"
      : "Harpoon — " + root.count + (root.count === 1 ? " window" : " windows") + (root.anyOverlaid ? ", one on screen" : "")
    onPressed: function(b) { Util.execArgv(["omarchy-shell", "shell", "toggle", "harpoon"]) }

    iconComponent: Component {
      HarpoonMark {
        anchors.fill: parent
        anchors.margins: Math.round(height * 0.08)
        tint: button.active ? Color.accent : root.fg
      }
    }
  }

  // how many are bookmarked, tucked into the corner
  Rectangle {
    visible: root.count > 0
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.rightMargin: Math.max(0, Style.space(1))
    anchors.bottomMargin: Math.max(0, Style.space(2))
    width: Math.max(badge.implicitWidth + Style.space(3), Style.space(9))
    height: Style.space(9)
    radius: height / 2
    color: root.fg
    Text {
      id: badge
      anchors.centerIn: parent
      textFormat: Text.PlainText
      text: root.count
      color: root.bar ? root.bar.background : Color.background
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Math.max(7, Style.font.caption - 3)
      font.bold: true
    }
  }
}
