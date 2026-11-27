# Changelog

All notable changes to Omaspaces. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the version numbers follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Checks: `python3 test/run.py` runs unit tests and lint checks, and GitHub Actions runs them on every push and pull request. CI also checks the plugin against the oldest supported Omarchy release and against Omarchy's development branch. See [docs/testing.md](docs/testing.md).

## [1.3.0] - 2026-11-27

Requires Omarchy 4.5 or later.

### Changed

- The default bar section is now `left`, next to the built-in workspaces widget, so the clock stays centered. The install steps in the README changed to match.
- Animations follow `omarchy toggle animations`.
- Scrolling uses Omarchy's shared wheel helper.

### Added

- Translations. The plugin follows the language set under Setup > Language. English is in `i18n/en.json`.
- The workspace arrows in the profile editor swap in right-to-left languages.

### Security

- All plugin text is plain text. Before, markup in a window title (for example from a web page) could be read as rich text.

### Known issues

- Omaspaces does not follow Omarchy's per-monitor workspaces. With more than one monitor, every bar shows workspaces 1–10.

## [1.2.0] - 2026-09-29

### Added

- Workspace profiles: save which apps go on which workspace, and relaunch the layout in one click.
- Workspace names.
- A window menu on each app icon: focus, move to a workspace, add an icon rule, or close.
- Pills for special workspaces such as the scratchpad.
- Real app icons from desktop entries, with Nerd Font glyphs as the fallback.

## [1.1.0] - 2026-08-15

### Added

- An icon rules editor in the bar.

### Fixed

- Boolean settings written without `--json` work.
- The rules editor fills in the pattern when you open it again while it is open.

## [1.0.0] - 2026-08-14

### Added

- First release: workspace pills with an icon for each open window.

[Unreleased]: https://github.com/DanielLob-o/Omaspaces/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/DanielLob-o/Omaspaces/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/DanielLob-o/Omaspaces/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/DanielLob-o/Omaspaces/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/DanielLob-o/Omaspaces/releases/tag/v1.0.0
