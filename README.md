# FlowCell

FlowCell is a Windows desktop automation shell for creative and system workflows. It uses a PowerShell WPF UI and an AutoHotkey v2 backend to manage program tabs, editable panels, launcher buttons, hotkeys, macros, popout layouts, and Blender bridge actions.

This repository is structured for public source control. Publishable source stays in the repo. User state, bindings, popout layouts, saved panels, logs, generated temp files, private local settings, build output, and EXE artifacts live under `FlowCell/local/`, which is ignored by Git.

## Repository Layout

- `FlowCell/`: main app code, launcher scripts, helpers, and vendored dependencies.
- `Blender/`: preserved Blender integration area, including `FlowCellButtons/` and `config.json`.
- `Illustrator/`: user-facing Illustrator scripts live directly in this folder.
- `Illustrator/HelperScripts/`: internal Illustrator helper scripts that are not meant to become user-facing buttons.
- `Windows/`: user-facing Windows scripts live directly in this folder.
- `Photoshop/`: public Photoshop script area for repo-safe defaults.
- `docs/`: repository and maintenance documentation.
- `examples/`: public example configs with safe placeholders.
- `tools/`: source-only tooling, including the optional C# launcher source.
- `releases/`: release process notes. Built EXEs are not committed here.

## Local State Model

FlowCell now keeps mutable runtime data in `FlowCell/local/`:

- `bindings.ini`
- `flowcell_state.json`
- `scan_state.ini`
- `layouts/`
- `panel_saves/`
- `recorded_actions/`
- `logs/`
- `private/local.settings.json`
- `temp/`
- `bin/`

GitHub pulls should not overwrite panel configuration, hotkeys, bindings, popout layouts, saved panels, or other user changes because those files are local-only.

Blender can also use a local override config at `FlowCell/local/private/blender.config.local.json`. The tracked `Blender/config.json` is now a sanitized public default.

Some Windows helper scripts also use local environment overrides for machine-specific tooling. See `examples/Windows/windows.env.example`.

## Script Folder Rules

- Blender keeps its current structured area.
- Illustrator user-facing scripts stay directly in `Illustrator/`.
- Windows user-facing scripts stay directly in `Windows/`.
- Preferred filename prefixes are `file_`, `util_`, and `org_`.
- These prefixes are only a file-organization convention. They do not route scripts to panels or change execution behavior.
- `Illustrator/HelperScripts/` is reserved for internal helper scripts.

Preferred usage:
- `org_` for Illustrator layer-style scripts and Blender collections-style scripts
- `file_` for file-panel scripts
- `util_` for utility-style scripts

When a script is added through FlowCell's panel UI, the `Add Script` button opens in the current program folder, supports multi-select, adds one button per selected script, and writes those buttons only into the currently selected panel. Default button labels strip `file_`, `util_`, or `org_` from the displayed name only.

## Running FlowCell

- `run.cmd` at the repo root delegates to `FlowCell/run.cmd`.
- `FlowCell/run.cmd` launches the PowerShell UI or the AutoHotkey backend.
- Launcher logs are written to `FlowCell/local/logs/`.

## Releases

This repository does not commit built EXEs. The optional launcher source is kept in `tools/launcher/FlowCellLauncher.cs`. Build outputs belong in ignored local storage during development and should be distributed later through GitHub Releases.
