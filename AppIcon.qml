import QtQuick
import qs.Commons

Item {
  id: icon

  property var widget: null
  property string appClass: ""
  property string title: ""
  property int size: Style.space(18)
  property color color: widget ? widget.fgColor : Color.foreground

  readonly property string source: widget && widget.useAppIcons ? widget.appIconSource(icon.appClass) : ""

  implicitWidth: size
  implicitHeight: size

  Image {
    id: image
    anchors.fill: parent
    visible: status === Image.Ready
    source: icon.source
    sourceSize.width: icon.size * 2
    sourceSize.height: icon.size * 2
    fillMode: Image.PreserveAspectFit
    asynchronous: true
    smooth: true
    mipmap: true
  }

  Text {
    anchors.fill: parent
    visible: !image.visible
    text: icon.widget ? icon.widget.iconForClass(icon.appClass, icon.title) : ""
    color: icon.color
    font.family: icon.widget ? icon.widget.fontFamily : Style.font.family
    font.pixelSize: Math.round(icon.size * 0.8)
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }
}
