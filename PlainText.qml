import QtQuick

// Window titles, class names, and file contents are untrusted. AutoText would
// read markup such as <img src="..."> in them as rich text and load it.
Text {
  textFormat: Text.PlainText
}
