import QtQuick
import Quickshell.Io

Item {
  id: store

  property string path: ""
  property var value: null
  property string pendingText: ""

  signal changed()

  function parse(text) {
    var trimmed = String(text || "").trim()
    if (trimmed === "") return null
    try {
      return JSON.parse(trimmed)
    } catch (e) {
      console.warn("lobo.omaspaces: " + store.path + " is not valid JSON: " + e)
      return null
    }
  }

  function setValue(next) {
    store.value = next
    store.changed()
  }

  function write(next) {
    store.setValue(next)
    store.pendingText = JSON.stringify(next, null, 2) + "\n"
    var slash = store.path.lastIndexOf("/")
    // FileView.setText() doesn't create parent directories.
    mkdir.command = ["mkdir", "-p", slash > 0 ? store.path.substring(0, slash) : store.path]
    // A running mkdir flushes the latest pendingText when it exits.
    if (!mkdir.running) mkdir.running = true
  }

  Process {
    id: mkdir
    onExited: file.setText(store.pendingText)
  }

  FileView {
    id: file
    path: store.path
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: store.setValue(store.parse(file.text()))
    onFileChanged: reload()
    onLoadFailed: store.setValue(null)
  }
}
