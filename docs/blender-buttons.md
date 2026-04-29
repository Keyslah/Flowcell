# Blender Buttons

## Overview

Blender buttons in FlowCell are launchers for Blender-side actions. A FlowCell Blender button is not meant to carry the main tool logic by itself.

The small `.ps1` file behind the button is a wrapper. Its job is to point to one named action and send that action through the FlowCell-to-Blender bridge.

The real tool logic lives in the installed Blender add-on as Python. That means Blender behavior changes usually belong in the add-on action code, not in the wrapper.

## Folder Roles

- `Blender/FlowCellButtons/`: user-facing `.ps1` wrappers that FlowCell shows as Blender buttons.
- `Blender/SupportScripts/`: shared bridge and sync helpers such as `Invoke-BlenderFlowCellAction.ps1`, `Install-BlenderFlowCellButtons.ps1`, and `Sync-BlenderButtonsToFlowCell.ps1`.
- `Blender/ManagedActions/`: repo-managed Python action files installed or copied for custom Blender actions.
- Blender add-on: the live Python runtime that receives bridge requests and executes the real action logic.
- `FlowCell/local/`: private runtime state such as local settings, layouts, logs, and other machine-specific data.
- `ScriptDump/`: rough, old, downloaded, or testing storage that should not be treated as the normal button source of truth.

## Wrapper vs. Real Logic

What the wrapper does:

- names one Blender action
- calls the bridge dispatcher
- exits with the bridge result

What the wrapper does not do:

- hold the real Blender tool logic
- replace the add-on action implementation
- act as the long-term source of truth for Blender behavior

In this repo, wrappers are intentionally small. The Blender add-on is where the Python action actually runs.

## Bridge Model

The bridge is the connection between FlowCell and Blender. FlowCell launches a wrapper, the wrapper calls a support script, and the support script sends a named action request to the Blender add-on runtime.

The main support pieces are:

- `Blender/SupportScripts/Invoke-BlenderFlowCellAction.ps1`: sends one named action through the bridge.
- `Blender/SupportScripts/Install-BlenderFlowCellButtons.ps1`: installs or registers custom actions, creates wrappers, updates config, and reports reload requirements.
- `Blender/SupportScripts/Sync-BlenderButtonsToFlowCell.ps1`: syncs or regenerates wrapper metadata and button state.

## Adding a Blender Button

The intended install path is:

1. Install or register the Python action with the Blender-side registry or managed action area.
2. Create or update the matching wrapper in `Blender/FlowCellButtons/`.
3. Place the button in the selected FlowCell panel.
4. Sync button metadata back into FlowCell state/config.
5. Report whether Blender needs an add-on reload or full restart before the new action is callable.

On the Blender tab, FlowCell's `Add Button` flow is therefore different from a normal `Add Script` import. It is an installer-and-registration path, not just a loose file picker.

## Reload and Rescan Expectations

If the Blender add-on action list changed, Blender may need to reload the add-on or restart before a new action works. FlowCell should say that explicitly after install.

If only wrapper metadata changed, a Blender restart may not be necessary, but the wrapper still is not the authoritative Blender logic. The add-on remains the thing that actually performs the work.

## Practical Rules

- Put normal Blender button wrappers in `Blender/FlowCellButtons/`.
- Put bridge helpers in `Blender/SupportScripts/`.
- Put real Blender action logic in the installed add-on as Python.
- Keep private settings, layouts, and logs in `FlowCell/local/`.
- Put rough, testing, and old files in `ScriptDump/`, not in the normal button folders.
- When behavior changes, update the add-on action first, then make sure the wrapper and button registration still match it.
