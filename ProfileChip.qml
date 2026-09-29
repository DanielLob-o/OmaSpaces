import QtQuick
import qs.Commons

Item {
  id: chip

  property var widget: null
  property var app: ({})
  property int size: Style.space(22)

  readonly property color foreground: widget ? widget.fgColor : Color.foreground

  implicitWidth: size + Style.space(4)
  implicitHeight: size + Style.space(2)

  AppIcon {
    widget: chip.widget
    appClass: chip.app.class
    size: chip.size
  }

  Rectangle {
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    width: Math.max(height, badge.implicitWidth + Style.space(4))
    height: Style.space(12)
    radius: height / 2
    color: Color.popups.background
    border.color: Util.alpha(chip.foreground, 0.35)
    border.width: 1

    Text {
      id: badge
      anchors.centerIn: parent
      text: String(chip.app.workspace === 10 ? 0 : chip.app.workspace)
      color: chip.foreground
      font.family: chip.widget ? chip.widget.fontFamily : Style.font.family
      font.pixelSize: Style.font.caption - 1
      font.bold: true
    }
  }
}
