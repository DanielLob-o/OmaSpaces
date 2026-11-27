import QtQuick
import qs.Commons
import qs.Ui

Column {
  id: panel

  property var widget: null
  property int editingIndex: -1

  readonly property color foreground: widget ? widget.fgColor : Color.foreground
  readonly property color muted: Util.alpha(foreground, 0.6)
  readonly property string fontFamily: widget ? widget.fontFamily : Style.font.family
  readonly property var profiles: widget ? widget.profiles : []

  spacing: Style.spacing.md

  function tr(key) {
    return panel.widget ? panel.widget.tr(key) : key
  }

  function reset() {
    panel.editingIndex = -1
  }

  Item {
    width: panel.width
    height: Math.max(title.implicitHeight, addButton.implicitHeight)

    PlainText {
      id: title
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: "󰕰  OmaSpaces" // i18n-ignore: brand name
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
      tooltipText: panel.tr("profiles.newEmpty")
      onClicked: panel.editingIndex = panel.widget.newEmptyProfile()
    }
  }

  PlainText {
    visible: panel.profiles.length === 0
    width: panel.width
    text: panel.tr("profiles.empty")
    color: panel.muted
    font.family: panel.fontFamily
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }

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

        Behavior on color { ColorAnimation { duration: Style.duration(120) } }

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

            PlainText {
              id: indexLabel
              text: String(entry.index + 1)
              color: panel.muted
              font.family: panel.fontFamily
              font.pixelSize: Style.font.subtitle
            }

            PlainText {
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

          PlainText {
            visible: entry.modelData.apps.length === 0
            text: panel.tr("profiles.profileEmpty")
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
          tooltipText: panel.tr("profiles.edit")
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
    text: panel.widget && panel.widget.capturing ? panel.tr("profiles.capturing") : panel.tr("profiles.capture")
    iconText: "󰄀"
    foreground: panel.foreground
    enabled: !(panel.widget && panel.widget.capturing)
    onClicked: panel.widget.captureNewProfile(function(index) { panel.editingIndex = index })
  }

  PlainText {
    visible: text !== ""
    width: panel.width
    text: panel.widget ? panel.widget.profileStatusText() : ""
    color: panel.muted
    font.family: panel.fontFamily
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }
}
