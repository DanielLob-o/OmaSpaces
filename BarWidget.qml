import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Commons
import qs.Ui
import "IconRules.js" as IconRules

BarWidget {
  id: root
  moduleName: "lobo.omaspaces"

  // `omarchy bar set` without --json stores "false" as a string, which QML treats as true.
  function boolSetting(key, fallback) {
    var value = root.setting(key, fallback)
    if (typeof value === "boolean") return value
    var s = String(value).trim().toLowerCase()
    if (s === "true" || s === "1" || s === "yes" || s === "on") return true
    if (s === "false" || s === "0" || s === "no" || s === "off") return false
    return fallback
  }

  function objectSetting(key) {
    var value = root.setting(key, null)
    if (typeof value === "string") {
      try { value = JSON.parse(value) } catch (e) { value = null }
    }
    return value && typeof value === "object" && !Array.isArray(value) ? value : ({})
  }

  readonly property bool showIcons: root.boolSetting("showIcons", true)
  readonly property bool showNumbers: root.boolSetting("showNumbers", true)
  readonly property int workspaceCount: Util.clamp(Math.round(Number(root.setting("workspaceCount", 5))), 1, 10)
  readonly property int maxWorkspaceId: Math.max(root.workspaceCount, Util.clamp(Math.round(Number(root.setting("maxWorkspaceId", 10))), 1, 10))
  readonly property bool hideEmpty: root.boolSetting("hideEmpty", false)
  readonly property int iconLimit: Util.clamp(Math.round(Number(root.setting("iconLimit", 4))), 1, 8)
  readonly property string accentSource: root.setting("accentSource", "Accent")
  readonly property bool compact: root.boolSetting("compact", false)
  readonly property bool showTooltip: root.boolSetting("showTooltip", true)
  readonly property bool showSpecial: root.boolSetting("showSpecial", true)
  readonly property bool showProfiles: root.boolSetting("showProfiles", true)
  readonly property var workspaceNames: root.objectSetting("workspaceNames")
  readonly property string iconOverridesPath: String(root.setting("iconOverridesPath", "~/.config/omarchy/omaspaces-icons.json"))
  readonly property string profilesPath: String(root.setting("profilesPath", "~/.config/omarchy/omaspaces-profiles.json"))

  readonly property color fgColor: root.bar ? root.bar.barForeground : Color.foreground
  readonly property string fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
  readonly property color accentColor: {
    if (root.accentSource === "Urgent") return Color.urgent
    if (root.accentSource === "Foreground") return root.fgColor
    return Color.accent
  }

  // Hyprland doesn't push workspace membership changes, so refresh toplevels on window events.
  Timer {
    id: refreshToplevelsTimer
    interval: 40
    onTriggered: Hyprland.refreshToplevels()
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var name = event.name
      if (name === "openwindow") root.placePendingWindow(String(event.data || ""))
      if (name === "openwindow" || name === "closewindow" || name === "movewindowv2" || name === "windowtitlev2" || name === "activewindow" || name === "urgent")
        refreshToplevelsTimer.restart()
      if (name === "activespecialv2" || name === "activespecial" || name === "focusedmonv2")
        Hyprland.refreshMonitors()
    }
  }

  // This bar's monitor, not global focus, so each monitor highlights its own workspace.
  readonly property var barScreen: root.QsWindow.window ? root.QsWindow.window.screen : null
  readonly property var monitor: root.barScreen ? Hyprland.monitorFor(root.barScreen) : Hyprland.focusedMonitor
  readonly property int focusedId: {
    if (root.monitor && root.monitor.activeWorkspace) return root.monitor.activeWorkspace.id
    return Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1
  }
  readonly property string activeSpecialName: {
    var ipc = root.monitor ? root.monitor.lastIpcObject : null
    return ipc && ipc.specialWorkspace && ipc.specialWorkspace.name ? String(ipc.specialWorkspace.name) : ""
  }

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }
    return null
  }

  // ObjectModel.values isn't a real Array.
  function toArray(list) {
    return list ? Array.prototype.slice.call(list) : []
  }

  function allToplevels() {
    return root.toArray(Hyprland.toplevels ? Hyprland.toplevels.values : null)
  }

  function toplevelsOf(workspace) {
    return workspace && workspace.toplevels ? root.toArray(workspace.toplevels.values) : []
  }

  function visibleWorkspaceIds() {
    var ids = []
    for (var n = 1; n <= root.workspaceCount; n++) ids.push(n)

    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= root.maxWorkspaceId && ids.indexOf(id) === -1) ids.push(id)
    }
    ids.sort(function (a, b) { return a - b })

    if (!root.hideEmpty) return ids
    return ids.filter(function (id) {
      if (id <= root.workspaceCount || id === root.focusedId) return true
      return root.toplevelsOf(root.workspaceById(id)).length > 0
    })
  }

  function specialWorkspaces() {
    if (!root.showSpecial) return []
    var out = []
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      var ws = values[i]
      var name = String(ws.name || "")
      if (ws.id < 0 && name.indexOf("special:") === 0 && root.toplevelsOf(ws).length > 0) out.push(ws)
    }
    out.sort(function (a, b) { return String(a.name).localeCompare(String(b.name)) })
    return out
  }

  function dispatch(lua) {
    if (root.bar) root.bar.run("hyprctl dispatch " + Util.shellQuote(lua))
  }

  function luaString(value) {
    return JSON.stringify(String(value))
  }

  function windowAddress(toplevel) {
    var ipc = toplevel ? toplevel.lastIpcObject : null
    var address = String((toplevel && toplevel.address) || (ipc && ipc.address) || "")
    if (address === "") return ""
    return address.indexOf("0x") === 0 ? address : "0x" + address
  }

  function focusWorkspace(id) {
    root.dispatch("hl.dsp.focus({ workspace = " + root.luaString(id) + " })")
  }

  function focusWindow(toplevel) {
    var address = root.windowAddress(toplevel)
    if (address) root.dispatch("hl.dsp.focus({ window = " + root.luaString("address:" + address) + " })")
  }

  function moveWindowToWorkspace(address, workspaceId) {
    if (!address) return
    root.dispatch("hl.dsp.window.move({ window = " + root.luaString("address:" + address)
      + ", workspace = " + root.luaString(workspaceId) + ", follow = false })")
  }

  function closeWindow(toplevel) {
    var address = root.windowAddress(toplevel)
    if (address) root.dispatch("hl.dsp.window.close({ window = " + root.luaString("address:" + address) + " })")
  }

  function toggleSpecial(workspace) {
    var name = String(workspace.name || "").replace(/^special:/, "")
    root.dispatch("hl.dsp.workspace.toggle_special(" + root.luaString(name) + ")")
  }

  // Accumulate deltas so a touchpad steps one workspace per notch, not one per event.
  property real wheelAccum: 0

  Timer { id: wheelResetTimer; interval: 300; onTriggered: root.wheelAccum = 0 }
  Timer { id: wheelCooldown; interval: 140 }

  function handleWheel(delta) {
    if (!delta) return
    root.wheelAccum += delta
    wheelResetTimer.restart()
    if (Math.abs(root.wheelAccum) < 120 || wheelCooldown.running) return
    var step = root.wheelAccum > 0 ? 1 : -1
    root.wheelAccum = 0
    wheelCooldown.start()
    root.dispatch("hl.dsp.focus({ workspace = " + root.luaString(step > 0 ? "e+1" : "e-1") + " })")
  }

  readonly property string home: Quickshell.env("HOME") || ""

  function expandPath(path) {
    var value = String(path || "").trim()
    if (value === "") return ""
    if (value === "~") return root.home
    if (value.indexOf("~/") === 0) return root.home + value.substring(1)
    if (value.indexOf("$HOME/") === 0) return root.home + value.substring(5)
    if (value.charAt(0) !== "/") return root.home + "/" + value
    return value
  }

  // Kept apart from the compiled rules because RegExp objects can't be saved as JSON.
  property var iconOverrideEntries: []
  property var customIconRules: []
  property var iconCache: ({})

  function parseIconOverrideEntries(parsed) {
    if (!Array.isArray(parsed)) return []
    var out = []
    for (var i = 0; i < parsed.length; i++) {
      var entry = parsed[i]
      if (!entry || typeof entry !== "object") continue
      var pattern = entry.match || entry.pattern
      if (!pattern || !entry.icon) continue
      out.push({ match: String(pattern), icon: String(entry.icon) })
    }
    return out
  }

  function applyIconOverrideEntries(entries) {
    var compiled = []
    for (var i = 0; i < entries.length; i++) {
      try {
        compiled.push({ re: new RegExp(entries[i].match, "i"), icon: entries[i].icon })
      } catch (e) {
        console.warn("lobo.omaspaces: skipping invalid icon override pattern " + JSON.stringify(entries[i].match))
      }
    }
    root.iconOverrideEntries = entries
    root.customIconRules = compiled
    root.iconCache = {}
  }

  JsonFile {
    id: iconOverridesFile
    path: {
      var p = root.expandPath(root.iconOverridesPath)
      return p !== "" ? p : (root.home + "/.cache/omarchy/omaspaces-no-icon-overrides.json")
    }
    onChanged: root.applyIconOverrideEntries(root.parseIconOverrideEntries(value))
  }

  function addIconOverride(pattern, icon) {
    var p = String(pattern || "").trim()
    var i = String(icon || "").trim()
    if (p === "" || i === "") return false
    try {
      new RegExp(p, "i")
    } catch (e) {
      return false
    }
    iconOverridesFile.write(root.iconOverrideEntries.concat([{ match: p, icon: i }]))
    return true
  }

  function removeIconOverride(index) {
    var next = root.iconOverrideEntries.slice()
    if (index < 0 || index >= next.length) return
    next.splice(index, 1)
    iconOverridesFile.write(next)
  }

  function customIconFor(cls, title) {
    var rules = root.customIconRules
    for (var i = 0; i < rules.length; i++) {
      if (rules[i].re.test(title) || rules[i].re.test(cls)) return rules[i].icon
    }
    return ""
  }

  function toplevelClass(toplevel) {
    var ipc = toplevel ? toplevel.lastIpcObject : null
    if (ipc && ipc.class) return ipc.class
    if (toplevel && toplevel.appId) return toplevel.appId
    return ""
  }

  function toplevelTitle(toplevel) {
    if (toplevel && toplevel.title) return toplevel.title
    var ipc = toplevel ? toplevel.lastIpcObject : null
    return (ipc && ipc.title) || ""
  }

  // Cached by class only, since titles change constantly.
  function iconForClass(clsRaw, titleRaw) {
    var cls = String(clsRaw || "").toLowerCase()
    var title = String(titleRaw || "").toLowerCase()

    var custom = root.customIconFor(cls, title)
    if (custom) return custom

    var byTitle = IconRules.iconForTitle(title, cls)
    if (byTitle) return byTitle

    var cached = root.iconCache[cls]
    if (cached !== undefined) return cached

    var icon = IconRules.iconForClass(cls) || IconRules.DEFAULT_ICON
    root.iconCache[cls] = icon
    return icon
  }

  function iconForToplevel(toplevel) {
    return root.iconForClass(root.toplevelClass(toplevel), root.toplevelTitle(toplevel))
  }

  function windowTitles(workspace) {
    var tops = root.toplevelsOf(workspace)
    var titles = []
    for (var i = 0; i < tops.length; i++) {
      var t = root.toplevelTitle(tops[i])
      if (t) titles.push(t)
    }
    return titles.join("\n")
  }

  function openAppOptions() {
    var seen = {}
    var out = []
    var tops = root.allToplevels()
    for (var i = 0; i < tops.length; i++) {
      var cls = root.toplevelClass(tops[i])
      if (!cls || seen[cls]) continue
      seen[cls] = true
      out.push(cls)
    }
    out.sort()
    return out
  }

  function workspaceName(id) {
    var name = root.workspaceNames[String(id)]
    return name ? String(name) : ""
  }

  function numberLabel(id, occupied) {
    var parts = []
    // An empty pill with numbers off would otherwise be blank.
    if (root.showNumbers || !root.showIcons || !occupied) parts.push(id === 10 ? "0" : String(id))
    var name = root.workspaceName(id)
    if (name) parts.push(name)
    return parts.join(" ")
  }

  function workspaceTooltip(id, workspace) {
    if (!root.showTooltip) return ""
    var lines = []
    var name = root.workspaceName(id)
    lines.push("Workspace " + id + (name ? " · " + name : ""))
    var titles = root.windowTitles(workspace)
    if (titles) lines.push(titles)
    lines.push("Right-click: rename · icon rules")
    return lines.join("\n")
  }

  function setWorkspaceName(id, name) {
    var next = {}
    var current = root.workspaceNames
    for (var key in current) next[key] = current[key]
    var trimmed = String(name || "").trim()
    if (trimmed) next[String(id)] = trimmed
    else delete next[String(id)]
    if (root.bar) root.bar.run("omarchy-bar set " + Util.shellQuote(root.moduleName) + " workspaceNames "
      + Util.shellQuote(JSON.stringify(next)) + " --json")
  }

  // Each card is its own popout owner so the bar can close it when another panel opens.
  property string popupMode: ""
  property var popupAnchor: null
  property var menuToplevel: null
  property int menuWorkspaceId: -1
  property string rulesEditorPrefill: ""

  function openPopup(mode, anchor) {
    root.popupAnchor = anchor || root
    root.popupMode = mode
  }

  function closePopup(mode) {
    if (root.popupMode === mode) root.popupMode = ""
  }

  function openWindowMenu(toplevel, anchor) {
    root.menuToplevel = toplevel
    root.openPopup("window", anchor)
  }

  function openWorkspaceMenu(id, anchor) {
    root.menuWorkspaceId = id
    workspaceNameField.text = root.workspaceName(id)
    root.openPopup("workspace", anchor)
  }

  function openRulesEditor(cls) {
    root.rulesEditorPrefill = cls || ""
    // onOpenChanged doesn't fire if the editor is already open.
    if (root.popupMode === "rules") patternField.text = root.rulesEditorPrefill
    root.openPopup("rules", root)
  }

  property var profiles: []
  property string profileStatus: ""
  property bool capturing: false
  property var pendingPlacements: []

  function normalizeProfiles(value) {
    if (!Array.isArray(value)) return []
    var out = []
    for (var i = 0; i < value.length; i++) {
      var p = value[i]
      if (!p || typeof p !== "object") continue
      var apps = []
      var rawApps = Array.isArray(p.apps) ? p.apps : []
      for (var j = 0; j < rawApps.length; j++) {
        var a = rawApps[j]
        if (!a || !a.class) continue
        apps.push({
          class: String(a.class),
          workspace: Util.clamp(Math.round(Number(a.workspace) || 1), 1, 10),
          command: String(a.command || "")
        })
      }
      out.push({ name: String(p.name || ("Profile " + (out.length + 1))), apps: apps })
    }
    return out
  }

  JsonFile {
    id: profilesFile
    path: root.expandPath(root.profilesPath) || (root.home + "/.config/omarchy/omaspaces-profiles.json")
    onChanged: root.profiles = root.normalizeProfiles(value)
  }

  function saveProfiles(next) {
    profilesFile.write(next)
  }

  function cloneProfiles() {
    return JSON.parse(JSON.stringify(root.profiles))
  }

  function uniqueProfileName(base) {
    var names = root.profiles.map(function (p) { return p.name })
    for (var n = root.profiles.length + 1; ; n++) {
      var candidate = base + " " + n
      if (names.indexOf(candidate) === -1) return candidate
    }
  }

  function newEmptyProfile() {
    var next = root.cloneProfiles()
    next.push({ name: root.uniqueProfileName("Profile"), apps: [] })
    root.saveProfiles(next)
    return next.length - 1
  }

  function renameProfile(index, name) {
    var trimmed = String(name || "").trim()
    if (!trimmed || index < 0 || index >= root.profiles.length) return
    var next = root.cloneProfiles()
    next[index].name = trimmed
    root.saveProfiles(next)
  }

  function deleteProfile(index) {
    if (index < 0 || index >= root.profiles.length) return
    var next = root.cloneProfiles()
    next.splice(index, 1)
    root.saveProfiles(next)
  }

  function setProfileAppWorkspace(index, appIndex, workspace) {
    var next = root.cloneProfiles()
    if (!next[index] || !next[index].apps[appIndex]) return
    next[index].apps[appIndex].workspace = Util.clamp(workspace, 1, 10)
    root.saveProfiles(next)
  }

  function removeProfileApp(index, appIndex) {
    var next = root.cloneProfiles()
    if (!next[index] || !next[index].apps[appIndex]) return
    next[index].apps.splice(appIndex, 1)
    root.saveProfiles(next)
  }

  function addProfileApp(index, cls) {
    var tops = root.allToplevels()
    for (var i = 0; i < tops.length; i++) {
      if (root.toplevelClass(tops[i]) !== cls) continue
      root.resolveApps([tops[i]], function (apps) {
        var next = root.cloneProfiles()
        if (!next[index]) return
        next[index].apps = next[index].apps.concat(apps)
        root.saveProfiles(next)
      })
      return
    }
  }

  function captureNewProfile(onCreated) {
    root.resolveApps(root.layoutToplevels(), function (apps) {
      var next = root.cloneProfiles()
      next.push({ name: root.uniqueProfileName("Layout"), apps: apps })
      root.saveProfiles(next)
      root.profileStatus = "Captured " + apps.length + " app" + (apps.length === 1 ? "" : "s") + " into " + next[next.length - 1].name
      if (onCreated) onCreated(next.length - 1)
    })
  }

  function recaptureProfile(index) {
    root.resolveApps(root.layoutToplevels(), function (apps) {
      var next = root.cloneProfiles()
      if (!next[index]) return
      next[index].apps = apps
      root.saveProfiles(next)
      root.profileStatus = "Recaptured " + next[index].name + " · " + apps.length + " apps"
    })
  }

  function layoutToplevels() {
    var tops = root.allToplevels()
    tops = tops.filter(function (t) { return t.workspace && t.workspace.id > 0 && root.toplevelClass(t) !== "" })
    tops.sort(function (a, b) {
      if (a.workspace.id !== b.workspace.id) return a.workspace.id - b.workspace.id
      var ax = a.lastIpcObject && a.lastIpcObject.at ? a.lastIpcObject.at[0] : 0
      var bx = b.lastIpcObject && b.lastIpcObject.at ? b.lastIpcObject.at[0] : 0
      return ax - bx
    })
    return tops
  }

  // Chromium web app classes look like "brave-web.whatsapp.com__path-Default" ("/" in the path becomes "_").
  function parseWebApp(cls) {
    var m = /^(?:chrome|chromium|brave|msedge|microsoft-edge|vivaldi|helium|opera|thorium)-(.+?)__(.*)-[^-]+$/i.exec(String(cls || ""))
    if (!m) return null
    var path = m[2].replace(/_/g, "/")
    return { host: m[1], path: path, url: "https://" + m[1] + "/" + path }
  }

  function desktopEntryFor(cls) {
    var web = root.parseWebApp(cls)
    if (web) {
      var needle = web.path ? web.host + "/" + web.path : web.host
      var values = DesktopEntries.applications.values || []
      for (var i = 0; i < values.length; i++) {
        var exec = String(values[i].execString || "")
        if (exec.indexOf(needle) !== -1 && /omarchy-launch-webapp|--app=/.test(exec)) return values[i]
      }
      return null
    }
    return cls ? DesktopEntries.heuristicLookup(cls) : null
  }

  function appIconSource(cls) {
    var entry = root.desktopEntryFor(cls)
    var icon = entry ? String(entry.icon || "") : ""
    if (!icon) return ""
    if (icon.charAt(0) === "/") return "file://" + icon
    return Quickshell.iconPath(icon, true)
  }

  function displayClass(cls) {
    var web = root.parseWebApp(cls)
    if (web) return web.host + (web.path ? "/" + web.path : "")
    var entry = root.desktopEntryFor(cls)
    return entry && entry.name ? entry.name : cls
  }

  function launchCommandFor(cls) {
    var entry = root.desktopEntryFor(cls)
    if (entry && entry.id) return "uwsm-app -- gtk-launch " + Util.shellQuote(entry.id + ".desktop")
    var web = root.parseWebApp(cls)
    if (web) return "omarchy-launch-webapp " + Util.shellQuote(web.url)
    return ""
  }

  // Apps without a desktop entry fall back to their command line from /proc.
  property var resolveQueue: []

  function resolveApps(tops, callback) {
    var apps = []
    var unresolved = []
    for (var i = 0; i < tops.length; i++) {
      var cls = root.toplevelClass(tops[i])
      var app = { class: cls, workspace: tops[i].workspace ? Math.max(1, tops[i].workspace.id) : 1, command: root.launchCommandFor(cls) }
      apps.push(app)
      var pid = tops[i].lastIpcObject ? tops[i].lastIpcObject.pid : 0
      if (!app.command && pid > 0) unresolved.push({ app: app, pid: pid })
    }

    if (unresolved.length === 0) {
      callback(apps)
      return
    }
    root.resolveQueue = root.resolveQueue.concat([{ apps: apps, unresolved: unresolved, callback: callback }])
    root.runNextResolve()
  }

  function runNextResolve() {
    if (cmdlineProc.running || root.resolveQueue.length === 0) return
    var job = root.resolveQueue[0]
    root.capturing = true
    cmdlineProc.command = ["bash", "-c",
      "for pid in \"$@\"; do tr '\\0' '\\037' < /proc/$pid/cmdline 2>/dev/null; echo; done",
      "omaspaces"].concat(job.unresolved.map(function (u) { return String(u.pid) }))
    cmdlineProc.running = true
  }

  Process {
    id: cmdlineProc
    stdout: StdioCollector {
      onStreamFinished: {
        var job = root.resolveQueue[0]
        root.resolveQueue = root.resolveQueue.slice(1)
        root.capturing = root.resolveQueue.length > 0
        if (job) {
          var lines = String(this.text || "").split("\n")
          for (var i = 0; i < job.unresolved.length; i++) {
            var args = String(lines[i] || "").split("\x1f").filter(function (a) { return a !== "" })
            if (args.length > 0) job.unresolved[i].app.command = "uwsm-app -- " + args.map(function (a) { return Util.shellQuote(a) }).join(" ")
          }
          job.callback(job.apps.filter(function (a) { return a.command !== "" }))
        }
        root.runNextResolve()
      }
    }
  }

  function applyProfile(index) {
    var profile = root.profiles[index]
    if (!profile) return

    // Match same-workspace windows first so a later entry can't take them.
    var open = []
    var tops = root.allToplevels()
    for (var i = 0; i < tops.length; i++) {
      if (!tops[i].workspace || tops[i].workspace.id <= 0) continue
      open.push({ cls: root.toplevelClass(tops[i]).toLowerCase(), ws: tops[i].workspace.id, claimed: false })
    }

    var satisfied = profile.apps.map(function () { return false })
    function claim(sameWorkspace) {
      for (var a = 0; a < profile.apps.length; a++) {
        if (satisfied[a]) continue
        var cls = profile.apps[a].class.toLowerCase()
        for (var w = 0; w < open.length; w++) {
          if (open[w].claimed || open[w].cls !== cls) continue
          if (sameWorkspace && open[w].ws !== profile.apps[a].workspace) continue
          open[w].claimed = true
          satisfied[a] = true
          break
        }
      }
    }
    claim(true)
    claim(false)

    var launched = 0
    var skipped = 0
    var expires = Date.now() + 30000
    var pending = root.pendingPlacements.filter(function (p) { return p.expires > Date.now() })
    for (var k = 0; k < profile.apps.length; k++) {
      if (satisfied[k]) continue
      var app = profile.apps[k]
      if (!app.command) { skipped++; continue }
      pending.push({ cls: app.class.toLowerCase(), workspace: app.workspace, expires: expires })
      if (root.bar) root.bar.run(app.command)
      launched++
    }
    root.pendingPlacements = pending

    var status = profile.name + " ready · " + (launched > 0 ? launched + " opened" : "everything already open")
    if (skipped > 0) status += " · " + skipped + " without a launch command"
    root.profileStatus = status
  }

  // Payload is "ADDRESS,WORKSPACE,CLASS,TITLE"; only the title can contain commas.
  function placePendingWindow(data) {
    if (root.pendingPlacements.length === 0) return
    var parts = data.split(",")
    if (parts.length < 3) return
    var address = parts[0].indexOf("0x") === 0 ? parts[0] : "0x" + parts[0]
    var workspaceName = parts[1]
    var cls = parts[2].toLowerCase()

    var now = Date.now()
    var remaining = []
    var placed = false
    for (var i = 0; i < root.pendingPlacements.length; i++) {
      var p = root.pendingPlacements[i]
      if (p.expires <= now) continue
      if (!placed && p.cls === cls) {
        placed = true
        if (workspaceName !== String(p.workspace)) root.moveWindowToWorkspace(address, p.workspace)
        continue
      }
      remaining.push(p)
    }
    root.pendingPlacements = remaining
  }

  readonly property int pillGap: root.compact ? Style.space(2) : Style.space(4)
  readonly property int pillHeight: root.barSize - Style.space(4)
  readonly property real numberMargin: root.compact ? 5 : 7
  readonly property real iconMargin: root.compact ? 2 : 3

  implicitWidth: root.vertical ? root.barSize : pills.implicitWidth
  implicitHeight: root.vertical ? pills.implicitHeight : root.barSize

  Grid {
    id: pills
    anchors.centerIn: parent
    columns: root.vertical ? 1 : 64
    columnSpacing: root.pillGap
    rowSpacing: root.pillGap
    verticalItemAlignment: Grid.AlignVCenter
    horizontalItemAlignment: Grid.AlignHCenter

    Repeater {
      model: root.visibleWorkspaceIds()

      Rectangle {
        id: pill
        required property int modelData

        readonly property var workspace: root.workspaceById(pill.modelData)
        readonly property var tops: root.toplevelsOf(pill.workspace)
        readonly property bool occupied: pill.tops.length > 0
        readonly property bool focused: root.focusedId === pill.modelData
        readonly property bool urgent: pill.workspace !== null && pill.workspace.urgent === true
        readonly property var shownTops: root.showIcons ? pill.tops.slice(0, root.iconLimit) : []
        readonly property int extra: root.showIcons ? Math.max(0, pill.tops.length - root.iconLimit) : 0

        implicitWidth: root.vertical ? root.pillHeight : pillContent.implicitWidth
        implicitHeight: root.vertical ? pillContent.implicitHeight : root.pillHeight

        radius: root.compact ? Style.space(6) : Style.space(8)
        color: {
          if (pill.urgent) return Util.alpha(Color.urgent, 0.35)
          if (pill.focused) return Util.alpha(root.accentColor, 0.22)
          return pillHover.hovered ? Util.alpha(root.fgColor, 0.08) : "transparent"
        }

        Behavior on color { ColorAnimation { duration: 120 } }

        HoverHandler { id: pillHover }

        Grid {
          id: pillContent
          anchors.centerIn: parent
          columns: root.vertical ? 1 : 64
          verticalItemAlignment: Grid.AlignVCenter
          horizontalItemAlignment: Grid.AlignHCenter

          WidgetButton {
            bar: root.bar
            visible: text !== ""
            text: root.numberLabel(pill.modelData, pill.occupied)
            fontSize: root.vertical ? Style.font.icon : Style.font.body
            horizontalMargin: root.numberMargin
            fixedHeight: root.vertical ? -1 : root.pillHeight
            fixedWidth: root.vertical ? root.pillHeight : -1
            active: pill.focused && !pill.urgent
            activeColor: root.accentColor
            dimmed: !pill.occupied && !pill.focused
            tooltipText: root.workspaceTooltip(pill.modelData, pill.workspace)
            onPressed: function (button) {
              if (button === Qt.RightButton) root.openWorkspaceMenu(pill.modelData, pill)
              else root.focusWorkspace(pill.modelData)
            }
            onWheelMoved: function (delta) { root.handleWheel(delta) }
          }

          Repeater {
            model: pill.shownTops

            WidgetButton {
              id: iconButton
              required property var modelData

              bar: root.bar
              text: root.iconForToplevel(iconButton.modelData)
              fontSize: root.vertical ? Style.font.icon : Style.font.body
              horizontalMargin: root.iconMargin
              fixedHeight: root.vertical ? -1 : root.pillHeight
              fixedWidth: root.vertical ? root.pillHeight : -1
              active: pill.focused && !pill.urgent
              activeColor: root.accentColor
              tooltipText: root.showTooltip ? root.toplevelTitle(iconButton.modelData) + "\nClick: focus · Right-click: move / close" : ""
              onPressed: function (button) {
                if (button === Qt.RightButton) root.openWindowMenu(iconButton.modelData, iconButton)
                else if (button === Qt.MiddleButton) root.closeWindow(iconButton.modelData)
                else root.focusWindow(iconButton.modelData)
              }
              onWheelMoved: function (delta) { root.handleWheel(delta) }
            }
          }

          WidgetButton {
            bar: root.bar
            visible: pill.extra > 0
            text: "+" + pill.extra
            fontSize: Style.font.caption
            horizontalMargin: root.iconMargin
            fixedHeight: root.vertical ? -1 : root.pillHeight
            fixedWidth: root.vertical ? root.pillHeight : -1
            active: pill.focused && !pill.urgent
            activeColor: root.accentColor
            onPressed: function (button) { root.focusWorkspace(pill.modelData) }
            onWheelMoved: function (delta) { root.handleWheel(delta) }
          }

          Item {
            visible: pill.shownTops.length > 0 && !root.vertical
            width: Style.space(3)
            height: 1
          }
        }
      }
    }

    Repeater {
      model: root.specialWorkspaces()

      Rectangle {
        id: specialPill
        required property var modelData

        readonly property bool shown: root.activeSpecialName === String(specialPill.modelData.name)
        readonly property string label: String(specialPill.modelData.name).replace(/^special:/, "")
        readonly property int count: root.toplevelsOf(specialPill.modelData).length

        implicitWidth: root.vertical ? root.pillHeight : specialButton.implicitWidth
        implicitHeight: root.vertical ? specialButton.implicitHeight : root.pillHeight
        radius: root.compact ? Style.space(6) : Style.space(8)
        color: specialPill.shown ? Util.alpha(root.accentColor, 0.22) : (specialHover.hovered ? Util.alpha(root.fgColor, 0.08) : "transparent")
        border.color: Util.alpha(root.fgColor, specialPill.shown ? 0 : 0.18)
        border.width: 1

        Behavior on color { ColorAnimation { duration: 120 } }

        HoverHandler { id: specialHover }

        WidgetButton {
          id: specialButton
          anchors.centerIn: parent
          bar: root.bar
          text: "󰌨 " + specialPill.count
          fontSize: root.vertical ? Style.font.caption : Style.font.body
          horizontalMargin: root.numberMargin
          fixedHeight: root.vertical ? -1 : root.pillHeight
          fixedWidth: root.vertical ? root.pillHeight : -1
          active: specialPill.shown
          activeColor: root.accentColor
          tooltipText: root.showTooltip ? "Special workspace: " + specialPill.label + "\n" + root.windowTitles(specialPill.modelData) + "\nClick: show / hide" : ""
          onPressed: function (button) { root.toggleSpecial(specialPill.modelData) }
        }
      }
    }

    WidgetButton {
      id: profilesButton
      visible: root.showProfiles
      bar: root.bar
      text: "󰕰"
      fontSize: Style.font.icon
      horizontalMargin: root.numberMargin
      fixedHeight: root.vertical ? -1 : root.pillHeight
      fixedWidth: root.vertical ? root.pillHeight : -1
      active: root.popupMode === "profiles"
      activeColor: root.accentColor
      tooltipText: root.showTooltip ? "Workspace profiles" : ""
      onPressed: function (button) {
        if (root.popupMode === "profiles") root.closePopup("profiles")
        else {
          profilesPanel.reset()
          root.openPopup("profiles", profilesButton)
        }
      }
    }
  }

  PopupCard {
    id: profilesPopup
    anchorItem: root.popupMode === "profiles" && root.popupAnchor ? root.popupAnchor : root
    bar: root.bar
    open: root.popupMode === "profiles"
    contentWidth: fittedContentWidth(Style.space(340))
    contentHeight: fittedContentHeight(profilesPanel.implicitHeight, Style.space(560))

    function close() { root.closePopup("profiles") }

    Flickable {
      anchors.fill: parent
      contentHeight: profilesPanel.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      ProfilesPanel {
        id: profilesPanel
        width: parent.width
        widget: root
      }
    }
  }

  PopupCard {
    id: windowMenu
    anchorItem: root.popupMode === "window" && root.popupAnchor ? root.popupAnchor : root
    bar: root.bar
    open: root.popupMode === "window" && root.menuToplevel !== null
    contentWidth: fittedContentWidth(Style.space(260))
    contentHeight: fittedContentHeight(windowMenuColumn.implicitHeight, Style.space(420))

    function close() { root.closePopup("window") }

    readonly property var toplevel: root.menuToplevel
    readonly property int currentWorkspace: toplevel && toplevel.workspace ? toplevel.workspace.id : -1

    Column {
      id: windowMenuColumn
      anchors.fill: parent
      spacing: Style.spacing.sm

      Text {
        width: parent.width
        text: windowMenu.toplevel ? root.iconForToplevel(windowMenu.toplevel) + "  " + root.toplevelTitle(windowMenu.toplevel) : ""
        color: root.fgColor
        font.family: root.fontFamily
        font.pixelSize: Style.font.subtitle
        font.bold: true
        elide: Text.ElideRight
      }

      Text {
        width: parent.width
        text: windowMenu.toplevel ? root.toplevelClass(windowMenu.toplevel) : ""
        color: Util.alpha(root.fgColor, 0.6)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
      }

      PanelSeparator { width: parent.width; foreground: root.fgColor }

      Text {
        text: "Move to workspace"
        color: Util.alpha(root.fgColor, 0.6)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      Flow {
        width: parent.width
        spacing: Style.space(4)

        Repeater {
          model: root.maxWorkspaceId

          Button {
            required property int index
            readonly property int targetId: index + 1
            text: targetId === 10 ? "0" : String(targetId)
            bordered: true
            selected: targetId === windowMenu.currentWorkspace
            foreground: root.fgColor
            enabled: targetId !== windowMenu.currentWorkspace
            onClicked: {
              root.moveWindowToWorkspace(root.windowAddress(windowMenu.toplevel), targetId)
              root.closePopup("window")
            }
          }
        }
      }

      PanelSeparator { width: parent.width; foreground: root.fgColor }

      Button {
        width: parent.width
        leftAlign: true
        iconText: "󰁕"
        text: "Focus window"
        foreground: root.fgColor
        onClicked: { root.focusWindow(windowMenu.toplevel); root.closePopup("window") }
      }

      Button {
        width: parent.width
        leftAlign: true
        iconText: "󰏫"
        text: "Icon rule for this app…"
        foreground: root.fgColor
        onClicked: root.openRulesEditor(root.toplevelClass(windowMenu.toplevel))
      }

      Button {
        width: parent.width
        leftAlign: true
        iconText: "󰅖"
        text: "Close window"
        foreground: Color.urgent
        onClicked: { root.closeWindow(windowMenu.toplevel); root.closePopup("window") }
      }
    }
  }

  PopupCard {
    id: workspaceMenu
    anchorItem: root.popupMode === "workspace" && root.popupAnchor ? root.popupAnchor : root
    bar: root.bar
    open: root.popupMode === "workspace"
    contentWidth: fittedContentWidth(Style.space(260))
    contentHeight: fittedContentHeight(workspaceMenuColumn.implicitHeight, Style.space(320))

    function close() { root.closePopup("workspace") }

    Column {
      id: workspaceMenuColumn
      anchors.fill: parent
      spacing: Style.spacing.md

      Text {
        text: "WORKSPACE " + (root.menuWorkspaceId === 10 ? 0 : root.menuWorkspaceId)
        color: root.fgColor
        font.family: root.fontFamily
        font.pixelSize: Style.font.subtitle
        font.bold: true
      }

      Row {
        width: parent.width
        spacing: Style.spacing.controlGap

        TextField {
          id: workspaceNameField
          width: parent.width - saveNameButton.width - parent.spacing
          placeholderText: "Name, e.g. web"
          foreground: root.fgColor
          onAccepted: { root.setWorkspaceName(root.menuWorkspaceId, text); root.closePopup("workspace") }
        }

        Button {
          id: saveNameButton
          text: "Save"
          bordered: true
          foreground: root.fgColor
          onClicked: { root.setWorkspaceName(root.menuWorkspaceId, workspaceNameField.text); root.closePopup("workspace") }
        }
      }

      Button {
        visible: root.workspaceName(root.menuWorkspaceId) !== ""
        width: parent.width
        leftAlign: true
        iconText: "󰅖"
        text: "Clear name"
        foreground: root.fgColor
        onClicked: { root.setWorkspaceName(root.menuWorkspaceId, ""); root.closePopup("workspace") }
      }

      Button {
        width: parent.width
        leftAlign: true
        iconText: "󰏫"
        text: "Icon rules…"
        foreground: root.fgColor
        onClicked: {
          var tops = root.toplevelsOf(root.workspaceById(root.menuWorkspaceId))
          root.openRulesEditor(tops.length > 0 ? root.toplevelClass(tops[0]) : "")
        }
      }
    }
  }

  PopupCard {
    id: rulesPopup
    anchorItem: root
    bar: root.bar
    open: root.popupMode === "rules"
    contentWidth: fittedContentWidth(Style.space(320))
    contentHeight: fittedContentHeight(rulesColumn.implicitHeight, Style.space(420))

    function close() { root.closePopup("rules") }

    onOpenChanged: if (open) {
      patternField.text = root.rulesEditorPrefill
      iconField.text = ""
      appPicker.value = ""
    }

    Column {
      id: rulesColumn
      anchors.fill: parent
      spacing: Style.spacing.lg

      Text {
        text: "ICON RULES"
        color: root.fgColor
        font.family: root.fontFamily
        font.pixelSize: Style.font.subtitle
        font.bold: true
      }

      Text {
        width: parent.width
        text: "Pick an open app (or type your own pattern below), paste an icon, and add it. Saved to " + iconOverridesFile.path + " and applied immediately."
        color: Util.alpha(root.fgColor, 0.6)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }

      Dropdown {
        id: appPicker
        width: parent.width
        showLabel: false
        options: root.popupMode === "rules" ? root.openAppOptions() : []
        onChanged: function (v) { patternField.text = v }
      }

      TextField {
        id: patternField
        width: parent.width
        placeholderText: "app pattern (regex), e.g. firefox|zen"
      }

      Row {
        width: parent.width
        spacing: Style.spacing.controlGap

        TextField {
          id: iconField
          width: parent.width - addButton.width - parent.spacing
          placeholderText: "icon glyph"
        }

        Button {
          id: addButton
          text: "Add"
          bordered: true
          foreground: root.fgColor
          onClicked: {
            if (root.addIconOverride(patternField.text, iconField.text)) {
              patternField.text = ""
              iconField.text = ""
              appPicker.value = ""
            }
          }
        }
      }

      PanelSeparator {
        foreground: root.fgColor
      }

      Text {
        visible: root.iconOverrideEntries.length === 0
        text: "No custom rules yet."
        color: Util.alpha(root.fgColor, 0.6)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      Column {
        width: parent.width
        spacing: Style.spacing.xs

        Repeater {
          model: root.iconOverrideEntries

          Row {
            required property var modelData
            required property int index
            width: rulesColumn.width
            spacing: Style.spacing.controlGap

            Text {
              width: parent.width - removeButton.width - parent.spacing
              text: modelData.icon + "  " + modelData.match
              color: root.fgColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              elide: Text.ElideRight
            }

            Button {
              id: removeButton
              text: "✕"
              foreground: root.fgColor
              onClicked: root.removeIconOverride(index)
            }
          }
        }
      }
    }
  }
}
