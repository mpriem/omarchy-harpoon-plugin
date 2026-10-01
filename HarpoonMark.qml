import QtQuick
import QtQuick.Effects
import qs.Commons

// The harpoon mark, tinted at render time -- an SVG can't read the theme's
// colors itself, so the asset is plain white.
Item {
  id: root
  property real size: Style.font.display + Style.space(4)
  property color tint: Color.menu.selectedText

  width: size
  height: size

  Image {
    id: mark
    anchors.fill: parent
    source: Qt.resolvedUrl("assets/harpoon.svg")
    sourceSize: Qt.size(Math.round(width * 2), Math.round(height * 2))
    fillMode: Image.PreserveAspectFit
    smooth: true
    visible: false
  }

  MultiEffect {
    anchors.fill: mark
    source: mark
    colorization: 1.0
    colorizationColor: root.tint
  }
}
