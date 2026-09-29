import QtQuick
import qs.Commons

// One app in a profile: its desktop icon (or glyph fallback) with the target
// workspace number as a badge in the corner.
Item {
  id: chip

  property var widget: null
  property var app: ({})
  property int size: Style.space(22)

  readonly property string iconSource: widget ? widget.appIconSource(app.class) : ""
  readonly property color foreground: widget ? widget.fgColor : Color.foreground

  implicitWidth: size + Style.space(4)
  implicitHeight: size + Style.space(2)

  Image {
    id: image
    visible: status === Image.Ready
    width: chip.size
    height: chip.size
    source: chip.iconSource
    sourceSize.width: chip.size * 2
    sourceSize.height: chip.size * 2
    fillMode: Image.PreserveAspectFit
    asynchronous: true
    smooth: true
  }

  Text {
    visible: !image.visible
    width: chip.size
    height: chip.size
    text: chip.widget ? chip.widget.iconForClass(chip.app.class) : ""
    color: chip.foreground
    font.family: chip.widget ? chip.widget.fontFamily : Style.font.family
    font.pixelSize: Math.round(chip.size * 0.72)
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
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
