import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects

// A separate process gives each reservation its own normal, tiled surface.
// Launched tiled on a hidden special workspace, then swapped into the tile.
FloatingWindow {
  id: window
  title: Quickshell.env("HARPOON_PLACEHOLDER_TITLE") || "Harpoon reservation"
  visible: true
  implicitWidth: 640
  implicitHeight: 420
  minimumSize: Qt.size(1, 1)
  color: background
  property var palette: ({})
  readonly property color background: palette.background || "#101315"
  readonly property color foreground: palette.foreground || "#cacccc"
  readonly property color accent: palette.accent || foreground
  readonly property color muted: palette.muted || palette.dark_foreground || foreground
  readonly property string menuFont: Quickshell.env("OMARCHY_MENU_FONT") || "monospace"
  readonly property bool compact: width < 360 || height < 380
  readonly property real inset: Math.min(28, width * 0.06)
  readonly property string appLabel: Quickshell.env("HARPOON_PLACEHOLDER_LABEL") || "Your window"
  property string quip: ""
  readonly property var quips: [
    "Gone fishing. Back in a byte.",
    "This berth be taken, matey.",
    "Your window has shore leave.",
    "Aye, I'm saving yer seat.",
    "No mutiny. The window returns.",
    "The captain borrowed this one.",
    "Window overboard. Rope attached.",
    "Out plundering pixels.",
    "Not lost. Just at sea.",
    "This spot is under pirate protection.",
    "A little voyage. Same home port.",
    "Keeping the barnacles off yer tile."
  ]
  Component.onCompleted: quip = quips[Math.floor(Math.random() * quips.length)]

  function wash(c, alpha) { return Qt.rgba(c.r, c.g, c.b, alpha); }

  FileView {
    id: theme
    path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state")
      + "/omarchy/current/theme/colors.toml"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      var colors = {};
      var lines = text().split("\n");
      for (var i = 0; i < lines.length; i++) {
        var match = lines[i].match(/^\s*([a-z_]+)\s*=\s*["'](#[0-9a-fA-F]{6})["']/);
        if (match) colors[match[1]] = match[2];
      }
      if (colors.background && colors.foreground) window.palette = colors;
    }
  }
  // The shell receives theme changes over IPC; this standalone window doesn't.
  // Re-open the path too, so replacing the theme directory/symlink is detected.
  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: theme.reload()
  }
  onVisibleChanged: { if (!visible) Qt.quit(); }
  property int bookmarkSlot: -1
  readonly property bool managed: title.indexOf("Harpoon-reservation-") === 0

  FileView {
    id: state
    path: Quickshell.env("HOME") + "/.local/state/omarchy/harpoon/list.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        var slots = JSON.parse(text()).slots || [];
        window.bookmarkSlot = slots.findIndex(e => e && e.placeholderTitle === window.title) + 1;
      } catch (e) { window.bookmarkSlot = -1; }
    }
  }
  // Also clean up after a cancelled launch, config reload, or removed bookmark.
  Timer {
    interval: 10000
    running: window.managed
    repeat: true
    onTriggered: { if (window.bookmarkSlot === 0) Qt.quit(); }
  }
  Process {
    id: restore
    command: ["hyprctl", "dispatch", "Harpoon.restore(" + window.bookmarkSlot + ")"]
  }
  // Match the menu/plugin vocabulary: monospace, straight rules and key hints.
  // The existing SVG is only a low-contrast watermark, never a badge or card.
  Item {
    anchors.fill: parent
    clip: true
    Image {
      id: watermark
      anchors.centerIn: parent
      anchors.horizontalCenterOffset: window.width * 0.10
      width: Math.min(window.width * 0.80, window.height * 0.90, 520)
      height: width
      source: "assets/harpoon.svg"
      sourceSize: Qt.size(width * 2, height * 2)
      visible: false
    }
    MultiEffect {
      anchors.fill: watermark
      source: watermark
      colorization: 1
      colorizationColor: window.accent
      opacity: interaction.containsMouse ? 0.12 : 0.075
      Behavior on opacity { NumberAnimation { duration: 150 } }
    }
  }

  Item {
    id: header
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: window.inset
    height: 36
    visible: window.height > 220
    Text {
      text: "Harpoon"
      font.family: window.menuFont
      font.pixelSize: 16
      font.bold: true
      font.letterSpacing: 0.6
      color: window.foreground
    }
    Text {
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.topMargin: 3
      visible: window.bookmarkSlot > 0 && window.width > 200
      text: "SLOT " + String(window.bookmarkSlot).padStart(2, "0")
      font.family: window.menuFont
      font.pixelSize: 10
      font.bold: true
      font.letterSpacing: 1.2
      color: window.muted
    }
    Rectangle {
      anchors.bottom: parent.bottom
      width: parent.width
      height: 1
      color: window.wash(window.foreground, 0.14)
    }
  }

  Column {
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: window.inset
    width: Math.max(1, Math.min(440, window.width - window.inset * 2))
    spacing: 12
    transformOrigin: Item.Left
    scale: Math.min(1, Math.max(0, window.height - (window.height > 220 ? 150 : 24)) / Math.max(1, implicitHeight))
    Text {
      width: parent.width
      text: window.appLabel.toUpperCase() + " / AWAY"
      textFormat: Text.PlainText
      elide: Text.ElideRight
      color: window.accent
      font.family: window.menuFont
      font.pixelSize: 10
      font.bold: true
      font.letterSpacing: 1.2
    }
    Text {
      width: parent.width
      text: window.quip
      textFormat: Text.PlainText
      wrapMode: Text.WordWrap
      color: window.foreground
      font.family: window.menuFont
      font.pixelSize: window.compact ? 18 : 24
      font.bold: true
      lineHeight: 1.15
    }
    Text {
      width: parent.width
      visible: window.height > 160
      text: "Your place is reserved."
      color: window.muted
      font.family: window.menuFont
      font.pixelSize: 12
    }
  }

  Item {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: window.inset
    height: 36
    visible: window.managed && window.height > 220
    Rectangle {
      width: parent.width
      height: 1
      color: window.wash(window.foreground, 0.14)
    }
    Row {
      anchors.bottom: parent.bottom
      spacing: 8
      Rectangle {
        width: clickText.implicitWidth + 10
        height: clickText.implicitHeight + 6
        color: window.wash(window.foreground, interaction.containsMouse ? 0.12 : 0.05)
        border.width: 1
        border.color: window.wash(window.accent, interaction.containsMouse ? 0.7 : 0.32)
        Text {
          id: clickText
          anchors.centerIn: parent
          text: "CLICK"
          color: window.accent
          font.family: window.menuFont
          font.pixelSize: 10
          font.bold: true
        }
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "Reel it back in"
        color: interaction.containsMouse ? window.foreground : window.muted
        font.family: window.menuFont
        font.pixelSize: 10
      }
    }
  }

  MouseArea {
    id: interaction
    anchors.fill: parent
    enabled: window.managed && window.bookmarkSlot > 0
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: restore.running = true
  }
}
