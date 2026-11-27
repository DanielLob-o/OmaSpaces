# Testing

All checks live under `test/`, and `test/run.py` is the single entry point. No check changes the running shell, the bar, or the installed plugin.

## Run the checks

```sh
python3 test/run.py                          # portable checks
python3 test/run.py all                      # portable checks, then the QML compile and plugin validation
python3 test/run.py all --omarchy ~/omarchy  # the same, against an Omarchy checkout
```

Run `all` before you commit a change to QML or JavaScript. It needs Node 22 or later, Python 3, and, for the QML compile, `quickshell` and an installed Omarchy.

The script finds `test/unit/*.test.*` by file name, so a new test file joins the run automatically.

## What each check proves

| Check | File | What it proves | What it does not prove |
| --- | --- | --- | --- |
| Unit tests | `test/unit/` | The logic in the real QML and JS functions: settings, icon rules, profiles, status text | QML bindings, rendering, Hyprland |
| QML rules | `test/lint/qml-rules.py` | Plain-text sinks, `Style.duration()`, no Omarchy catalog keys, no hard-coded words | That the text reads well |
| i18n | `test/lint/i18n.py` | Every catalog key exists and is used, language codes, placeholders, plural forms | That a translation is correct |
| Manifest | `test/lint/manifest.py` | Versions agree with `CHANGELOG.md`, defaults agree with the schema, every setting is read and documented | That a setting works |
| Docs | `test/lint/docs.py` | Relative links and `#anchors` in Markdown resolve | That a document is true |
| Host API | `test/lint/host-api.py` | Every Omarchy module, type, property, singleton member, `bar` member and `omarchy-*` command the plugin uses exists | Behavior of those APIs |
| QML compile | `test/lint/compile-qml.py` | Every QML file compiles against the installed shell, and `PlainText` keeps markup as plain text | Rendering, runtime errors |
| Plugin validation | `omarchy-plugin-validate` | The exported plugin passes Omarchy's own validator | Anything at runtime |

Unit tests load the production functions out of `BarWidget.qml` and `IconRules.js` with `test/helpers/qml-functions.cjs`, and run them with fake inputs. Because they run the real function bodies, a change to the logic changes the test result.

## Continuous integration

`.github/workflows/checks.yml` runs on every pull request, on pushes to `main`, and every Monday. It has three jobs:

1. **Portable checks** runs `test/run.py`.
2. **Omarchy v4.5.0** runs `test/run.py all` against the oldest supported release.
3. **Omarchy quattro** runs `test/run.py all` against Omarchy's development branch.

The Omarchy jobs check out Omarchy's `shell/`, `bin/` and `default/i18n/` into `.omarchy/`. CI has no `quickshell`, so the QML compile is skipped there. Run `test/run.py all` locally before a release.

When the `quattro` job fails and the others pass, the next Omarchy release will break the plugin. Fix the plugin before that release ships.

When Omarchy drops support for an old release, or the plugin starts to need a newer one, change the oldest release in two places:

1. The `ref` list in `.github/workflows/checks.yml`.
2. The Requirements section in `README.md`.

## Manual checks

The checks do not open popups, click, or read the screen. Before a release:

1. Copy the plugin into `~/.config/omarchy/plugins/lobo.omaspaces` and wait for the reload.
2. Run `journalctl --user -b | grep lobo.omaspaces` and look for errors.
3. Open the profiles panel, the window menu, the workspace menu, and the icon rules editor. Check that they show words, not keys such as `rules.title`.
4. Scroll over the pills, and click a pill and an app icon.
