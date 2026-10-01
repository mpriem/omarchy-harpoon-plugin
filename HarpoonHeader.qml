import QtQuick
import qs.Commons
import qs.Ui

// The list's header: the mark, title and status line with the preview-mode
// pill -- or, while renaming, the mark and the rename field.
Item {
  id: root
  property int count: 0
  property string previewLabel: ""
  property bool renameOpen: false
  property string renameText: ""
  property string renameSlot: ""
  property int iconSize: Style.font.display + Style.space(4)

  signal renameEdited(string text)
  signal renameAccepted()
  signal renameCancelled()

  function focusRename() {
    renameField.forceActiveFocus()
    renameField.selectAll()
  }

  readonly property color foreground: Color.menu.text
  readonly property color selectedText: Color.menu.selectedText
  readonly property color dim: Util.alpha(foreground, 0.62)
  readonly property string fontFamily: Style.font.menuFamily
  readonly property int softRadius: Math.min(Style.cornerRadius, Style.space(6))

  Row {
    visible: !root.renameOpen
    anchors.left: parent.left
    anchors.right: previewPill.left
    anchors.rightMargin: Style.space(12)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(12)

    HarpoonMark {
      anchors.verticalCenter: parent.verticalCenter
      size: root.iconSize
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(3)

      Text {
        textFormat: Text.PlainText
        text: "Harpoon"
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.heading
        font.bold: true
        font.letterSpacing: 0.6
      }

      Text {
        textFormat: Text.PlainText
        text: (root.count === 0 ? "No bookmarks" : root.count + " of 10 slots") + "  ·  SUPER+H to bookmark or jump"
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
        font.letterSpacing: 1.2
        font.capitalization: Font.AllUppercase
      }
    }
  }

  BorderSurface {
    id: previewPill
    visible: !root.renameOpen
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: pillText.implicitWidth + Style.space(14)
    implicitHeight: pillText.implicitHeight + Style.space(8)
    color: "transparent"
    borderSpec: Border.controlSpec("normal", root.foreground, root.selectedText)
    radius: root.softRadius

    Text {
      id: pillText
      textFormat: Text.PlainText
      anchors.centerIn: parent
      text: "Preview · " + root.previewLabel
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 1
      font.capitalization: Font.AllUppercase
    }
  }

  // One top-level rename field rather than a TextInput per row: a
  // per-delegate `focus: row.isRenaming` binding didn't reliably win
  // activeFocus from the key catcher across the ListView boundary.
  Row {
    visible: root.renameOpen
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(12)

    HarpoonMark {
      anchors.verticalCenter: parent.verticalCenter
      size: root.iconSize
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - root.iconSize - Style.space(12)
      spacing: Style.space(4)

      Text {
        textFormat: Text.PlainText
        text: "Rename slot " + root.renameSlot + "  ·  Enter to save, Esc to cancel"
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
        font.letterSpacing: 1.2
        font.capitalization: Font.AllUppercase
      }

      BorderSurface {
        width: parent.width
        height: renameField.implicitHeight + Style.space(10)
        color: Util.alpha(root.foreground, 0.05)
        borderSpec: Border.controlSpec("normal", root.foreground, root.selectedText)
        radius: root.softRadius

        TextInput {
          id: renameField
          anchors.fill: parent
          anchors.leftMargin: Style.space(10)
          anchors.rightMargin: Style.space(10)
          verticalAlignment: TextInput.AlignVCenter
          text: root.renameText
          color: root.foreground
          selectionColor: Util.alpha(root.selectedText, 0.35)
          selectedTextColor: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          selectByMouse: true
          clip: true
          onTextChanged: root.renameEdited(text)
          onAccepted: root.renameAccepted()
          Keys.onEscapePressed: root.renameCancelled()
        }
      }
    }
  }
}
