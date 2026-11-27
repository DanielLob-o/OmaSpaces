import QtQuick
import qs.Commons
import qs.Ui

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

  // The popup mirrors the stepper in right-to-left languages, so the arrows swap to keep pointing outward.
  readonly property string previousGlyph: I18n.rightToLeft ? "›" : "‹"
  readonly property string nextGlyph: I18n.rightToLeft ? "‹" : "›"

  function tr(key) {
    return editor.widget ? editor.widget.tr(key) : key
  }

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
        placeholderText: editor.tr("editor.namePlaceholder")
        foreground: editor.foreground
        onAccepted: editor.widget.renameProfile(editor.profileIndex, text)
      }

      Button {
        id: renameButton
        text: editor.tr("editor.rename")
        bordered: true
        foreground: editor.foreground
        onClicked: editor.widget.renameProfile(editor.profileIndex, nameField.text)
      }
    }

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

          AppIcon {
            id: appRowIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            widget: editor.widget
            appClass: appRow.modelData.class
            size: Style.space(18)
          }

          PlainText {
            id: appLabel
            anchors.left: appRowIcon.right
            anchors.leftMargin: Style.space(8)
            anchors.right: stepper.left
            anchors.rightMargin: Style.spacing.controlGap
            anchors.verticalCenter: parent.verticalCenter
            text: editor.widget.displayClass(appRow.modelData.class)
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
              text: editor.previousGlyph
              foreground: editor.muted
              tooltipText: editor.tr("editor.previousWorkspace")
              onClicked: editor.widget.setProfileAppWorkspace(editor.profileIndex, appRow.index, appRow.modelData.workspace - 1)
            }

            PlainText {
              anchors.verticalCenter: parent.verticalCenter
              width: Style.space(22)
              horizontalAlignment: Text.AlignHCenter
              text: "󰍹 " + appRow.modelData.workspace
              color: editor.foreground
              font.family: editor.fontFamily
              font.pixelSize: Style.font.caption
            }

            Button {
              text: editor.nextGlyph
              foreground: editor.muted
              tooltipText: editor.tr("editor.nextWorkspace")
              onClicked: editor.widget.setProfileAppWorkspace(editor.profileIndex, appRow.index, appRow.modelData.workspace + 1)
            }
          }

          Button {
            id: removeButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "✕"
            foreground: editor.muted
            tooltipText: editor.tr("editor.removeApp")
            onClicked: editor.widget.removeProfileApp(editor.profileIndex, appRow.index)
          }
        }
      }
    }

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
        text: editor.tr("editor.add")
        bordered: true
        foreground: editor.foreground
        enabled: appPicker.value !== ""
        onClicked: {
          editor.widget.addProfileApp(editor.profileIndex, appPicker.value)
          appPicker.value = ""
        }
      }
    }

    PlainText {
      width: parent.width
      text: editor.tr("editor.addHelp")
      color: editor.muted
      font.family: editor.fontFamily
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }

    Row {
      spacing: Style.spacing.controlGap

      Button {
        text: editor.tr("editor.recapture")
        iconText: "󰑐"
        bordered: true
        foreground: editor.foreground
        tooltipText: editor.tr("editor.recaptureTooltip")
        onClicked: editor.widget.recaptureProfile(editor.profileIndex)
      }

      Button {
        text: editor.tr("editor.delete")
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
