import QtQuick
import qs.Commons
import qs.Ui

// Profiles popup body. All state and mutations live on `widget` (BarWidget);
// this file is layout only.
Column {
  id: panel

  property var widget: null
  property int editingIndex: -1

  readonly property color foreground: widget ? widget.fgColor : Color.foreground
  readonly property color muted: Util.alpha(foreground, 0.6)
  readonly property string fontFamily: widget ? widget.fontFamily : Style.font.family
  readonly property var profiles: widget ? widget.profiles : []

  spacing: Style.spacing.md

  function reset() {
    panel.editingIndex = -1
  }

  // ------------------------------------------------------------------ header
  Item {
    width: panel.width
    height: Math.max(title.implicitHeight, addButton.implicitHeight)

    Text {
      id: title
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: "󰕰  OmaSpaces"
      color: panel.foreground
      font.family: panel.fontFamily
      font.pixelSize: Style.font.title
      font.bold: true
    }

    Button {
      id: addButton
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: "+"
      fontSize: Style.font.heading
      foreground: panel.foreground
      tooltipText: "New empty profile"
      onClicked: panel.editingIndex = panel.widget.newEmptyProfile()
    }
  }

  Text {
    visible: panel.profiles.length === 0
    width: panel.width
    text: "No profiles yet. Arrange your apps across workspaces, then capture the layout below."
    color: panel.muted
    font.family: panel.fontFamily
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }

  // ----------------------------------------------------------------- profiles
  Repeater {
    model: panel.profiles

    Column {
      id: entry

      required property var modelData
      required property int index
      readonly property bool editing: panel.editingIndex === entry.index

      width: panel.width
      spacing: Style.spacing.sm

      Rectangle {
        width: parent.width
        height: rowContent.implicitHeight + Style.space(12)
        radius: Style.space(8)
        color: rowHover.hovered || entry.editing ? Util.alpha(panel.foreground, 0.07) : "transparent"

        Behavior on color { ColorAnimation { duration: 120 } }

        HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }

        MouseArea {
          anchors.fill: parent
          onClicked: panel.widget.applyProfile(entry.index)
        }

        Column {
          id: rowContent
          anchors.left: parent.left
          anchors.right: gear.left
          anchors.leftMargin: Style.space(10)
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(4)

          Row {
            width: parent.width
            spacing: Style.space(8)

            Text {
              id: indexLabel
              text: String(entry.index + 1)
              color: panel.muted
              font.family: panel.fontFamily
              font.pixelSize: Style.font.subtitle
            }

            Text {
              width: parent.width - indexLabel.width - parent.spacing
              text: entry.modelData.name
              color: panel.foreground
              font.family: panel.fontFamily
              font.pixelSize: Style.font.subtitle
              elide: Text.ElideRight
            }
          }

          Flow {
            width: parent.width
            spacing: Style.space(2)
            visible: entry.modelData.apps.length > 0

            Repeater {
              model: entry.modelData.apps
              ProfileChip {
                required property var modelData
                widget: panel.widget
                app: modelData
              }
            }
          }

          Text {
            visible: entry.modelData.apps.length === 0
            text: "Empty. Open the gear to add apps."
            color: panel.muted
            font.family: panel.fontFamily
            font.pixelSize: Style.font.caption
          }
        }

        Button {
          id: gear
          anchors.right: parent.right
          anchors.rightMargin: Style.space(6)
          anchors.verticalCenter: parent.verticalCenter
          text: "\uf013"
          fontSize: Style.font.icon
          foreground: entry.editing ? Color.accent : panel.muted
          tooltipText: "Edit profile"
          onClicked: panel.editingIndex = entry.editing ? -1 : entry.index
        }
      }

      Loader {
        active: entry.editing
        visible: active
        width: parent.width
        sourceComponent: ProfileEditor {
          widget: panel.widget
          profileIndex: entry.index
          profile: entry.modelData
          onDeleted: panel.editingIndex = -1
        }
      }
    }
  }

  PanelSeparator {
    width: panel.width
    foreground: panel.foreground
  }

  Button {
    width: panel.width
    leftAlign: true
    text: panel.widget && panel.widget.capturing ? "Capturing…" : "Capture the current layout"
    iconText: "󰄀"
    foreground: panel.foreground
    enabled: !(panel.widget && panel.widget.capturing)
    onClicked: panel.widget.captureNewProfile(function(index) { panel.editingIndex = index })
  }

  Text {
    visible: text !== ""
    width: panel.width
    text: panel.widget ? panel.widget.profileStatus : ""
    color: panel.muted
    font.family: panel.fontFamily
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }
}
