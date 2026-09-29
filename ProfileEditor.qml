import QtQuick
import qs.Commons
import qs.Ui

// Inline editor shown under a profile row when its gear is toggled.
Rectangle {
  id: editor

  property var widget: null
  property int profileIndex: -1
  property var profile: ({ name: "", apps: [] })

  signal deleted()

  readonly property color foreground: widget ? widget.fgColor : Color.foreground
  readonly property color muted: Util.alpha(foreground, 0.6)
  readonly property string fontFamily: widget ? widget.fontFamily : Style.font.family

  implicitHeight: body.implicitHeight + Style.space(20)
  radius: Style.space(8)
  color: "transparent"
  border.color: Util.alpha(foreground, 0.14)
  border.width: 1

  Component.onCompleted: nameField.text = editor.profile.name

  Column {
    id: body
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Style.space(10)
    spacing: Style.spacing.md

    Row {
      width: parent.width
      spacing: Style.spacing.controlGap

      TextField {
        id: nameField
        width: parent.width - renameButton.width - parent.spacing
        placeholderText: "Profile name"
        foreground: editor.foreground
        onAccepted: editor.widget.renameProfile(editor.profileIndex, text)
      }

      Button {
        id: renameButton
        text: "Rename"
        bordered: true
        foreground: editor.foreground
        onClicked: editor.widget.renameProfile(editor.profileIndex, nameField.text)
      }
    }

    // One line per app: glyph, class, workspace stepper, remove.
    Column {
      width: parent.width
      spacing: Style.spacing.xs

      Repeater {
        model: editor.profile.apps

        Item {
          id: appRow
          required property var modelData
          required property int index

          width: parent.width
          height: Math.max(appLabel.implicitHeight, removeButton.implicitHeight)

          Text {
            id: appLabel
            anchors.left: parent.left
            anchors.right: stepper.left
            anchors.rightMargin: Style.spacing.controlGap
            anchors.verticalCenter: parent.verticalCenter
            text: editor.widget.iconForClass(appRow.modelData.class) + "  " + editor.widget.displayClass(appRow.modelData.class)
            color: editor.foreground
            font.family: editor.fontFamily
            font.pixelSize: Style.font.body
            elide: Text.ElideRight
          }

          Row {
            id: stepper
            anchors.right: removeButton.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Button {
              text: "‹"
              foreground: editor.muted
              tooltipText: "Previous workspace"
              onClicked: editor.widget.setProfileAppWorkspace(editor.profileIndex, appRow.index, appRow.modelData.workspace - 1)
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              width: Style.space(22)
              horizontalAlignment: Text.AlignHCenter
              text: "󰍹 " + appRow.modelData.workspace
              color: editor.foreground
              font.family: editor.fontFamily
              font.pixelSize: Style.font.caption
            }

            Button {
              text: "›"
              foreground: editor.muted
              tooltipText: "Next workspace"
              onClicked: editor.widget.setProfileAppWorkspace(editor.profileIndex, appRow.index, appRow.modelData.workspace + 1)
            }
          }

          Button {
            id: removeButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "✕"
            foreground: editor.muted
            tooltipText: "Remove from profile"
            onClicked: editor.widget.removeProfileApp(editor.profileIndex, appRow.index)
          }
        }
      }
    }

    // Add an app that's open right now; its launch command is resolved the
    // same way a capture does.
    Row {
      width: parent.width
      spacing: Style.spacing.controlGap

      Dropdown {
        id: appPicker
        width: parent.width - addButton.width - parent.spacing
        showLabel: false
        options: editor.widget ? editor.widget.openAppOptions() : []
      }

      Button {
        id: addButton
        text: "Add"
        bordered: true
        foreground: editor.foreground
        enabled: appPicker.value !== ""
        onClicked: {
          editor.widget.addProfileApp(editor.profileIndex, appPicker.value)
          appPicker.value = ""
        }
      }
    }

    Text {
      width: parent.width
      text: "Adds the open app on its current workspace; use ‹ › to change it."
      color: editor.muted
      font.family: editor.fontFamily
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }

    Row {
      spacing: Style.spacing.controlGap

      Button {
        text: "Recapture layout"
        iconText: "󰑐"
        bordered: true
        foreground: editor.foreground
        tooltipText: "Replace this profile's apps with what's open now"
        onClicked: editor.widget.recaptureProfile(editor.profileIndex)
      }

      Button {
        text: "Delete"
        iconText: "󰆴"
        bordered: true
        foreground: Color.urgent
        onClicked: {
          editor.widget.deleteProfile(editor.profileIndex)
          editor.deleted()
        }
      }
    }
  }
}
