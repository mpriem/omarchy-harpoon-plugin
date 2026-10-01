import QtQuick
import qs.Commons

// Key hints as keycaps.
Item {
  id: root
  property var hints: []

  readonly property color foreground: Color.menu.text
  readonly property string fontFamily: Style.font.menuFamily

  clip: true

  Row {
    anchors.centerIn: parent
    spacing: Style.space(14)

    Repeater {
      model: root.hints

      Row {
        required property var modelData
        spacing: Style.space(5)

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: capText.implicitWidth + Style.space(10)
          height: capText.implicitHeight + Style.space(6)
          radius: Math.min(Style.cornerRadius, Style.space(4))
          color: Util.alpha(root.foreground, 0.07)
          border.width: 1
          border.color: Util.alpha(root.foreground, 0.14)

          Text {
            id: capText
            textFormat: Text.PlainText
            anchors.centerIn: parent
            text: modelData.key
            color: root.foreground
            opacity: 0.85
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }
        }

        Text {
          textFormat: Text.PlainText
          anchors.verticalCenter: parent.verticalCenter
          text: modelData.label
          color: Util.alpha(root.foreground, 0.62)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
