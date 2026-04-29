# Blender Buttons

## User Flow

This is the sequence the user follows:

1. Open the Blender tab in FlowCell.
2. Click `Add Button`.
3. Choose one Blender `.py` script.
4. FlowCell validates the script immediately.
5. If the script is valid, FlowCell installs the Blender-side action, creates the wrapper button, adds it to the selected panel, and tells you whether Blender needs a reload or restart.

The important part is step 3. The script needs to already follow the contract below.

## The Script Contract

FlowCell does not want a full Blender add-on. It wants one normal Python file with one callable action entrypoint.

Your file should:

- use normal Blender Python, usually importing `bpy`
- work from the current scene, selection, mode, or active object
- expose one top-level entrypoint named `run_flowcell_action`, `main`, or `perform_*`
- return a short result or raise a clear error

Your file should not be:

- a background server
- a socket listener
- an installer
- a Blender panel or menu registration script
- a modal tool framework
- a script that only works from Blender's Text Editor

If the file only exposes helpers like `handle`, `server`, `bootstrap`, or `register`, FlowCell rejects it.

## Start With This Shape

Use this unless you have a specific reason not to:

```python
import bpy


def perform_my_tool(context, data):
    active = context.view_layer.objects.active
    if active is None:
        raise ValueError("Select one active object first.")

    if active.type != "MESH":
        raise ValueError("Active object must be a mesh.")

    # Replace this block with your actual logic.
    active.location.z += 1.0

    return {
        "message": f"Raised {active.name} by 1 unit.",
        "display": "Object updated",
    }
```

That is the safest default pattern.

## What FlowCell Calls

FlowCell tries your function in this order:

- `callback(context, data)`
- `callback(context)`
- `callback(data)`
- `callback()`

That means these are all valid:

```python
def perform_my_tool(context, data):
    ...
```

```python
def perform_my_tool(context):
    ...
```

```python
def perform_my_tool():
    ...
```

Best practice:

- prefer `def perform_my_tool(context, data):`
- use `context` first
- use `data` only for optional inputs beyond the current Blender state

## What To Return

The action can return:

- a string
- a dict
- `None`

Recommended:

```python
return "Created the support rim."
```

or:

```python
return {
    "message": "Created the support rim.",
    "display": "Support rim added",
}
```

Meaning:

- `message` is the main completion text
- `display` is optional extra UI text
- any extra dict fields are passed through as payload

If you return `None`, FlowCell falls back to a generic completion message.

## How To Fail Cleanly

Raise a clear exception:

```python
if context.mode != "OBJECT":
    raise ValueError("Switch to Object Mode first.")
```

Good error messages:

- `"Select exactly one mesh object."`
- `"Open or save the .blend file first."`
- `"Active object must be a mesh."`

Bad error messages:

- `"Failed"`
- `"Error running tool"`
- `"Bad state"`

## Keep One Real Entrypoint

Helpers are fine. One clear top-level action is required.

Good:

```python
import bpy


def _get_active_mesh(context):
    obj = context.view_layer.objects.active
    if obj is None or obj.type != "MESH":
        raise ValueError("Active object must be a mesh.")
    return obj


def _apply_operation(obj):
    obj.location.z += 2.0


def perform_raise_active_mesh(context, data):
    obj = _get_active_mesh(context)
    _apply_operation(obj)
    return f"Raised {obj.name} by 2 units."
```

Bad:

```python
def server():
    ...


def handle(conn, addr):
    ...
```

That is infrastructure, not a button action.

## Top-Level Only

Define the action entrypoint at file scope.

Do not hide it inside:

- a class
- an `if __name__ == "__main__":` block
- a registration function
- nested helper functions that FlowCell cannot discover directly

Good:

```python
def perform_my_tool(context, data):
    ...
```

Bad:

```python
class MyTool:
    def perform_my_tool(self, context, data):
        ...
```

## What Good Button Scripts Usually Do

Most good Blender button scripts do one focused scene task:

- modify selected objects
- inspect or clean the active mesh
- create geometry
- organize names or collections
- export from the current scene
- prepare scene data for another app

They usually do not:

- stay resident forever
- open a network service
- install or register add-ons
- build a separate UI system
- depend on a separate manual Blender workflow outside the normal scene state

## What Happens After Add Button

If the script is valid, FlowCell:

1. registers or installs the Blender-side action
2. copies the action code into the live Blender runtime
3. creates a matching `.ps1` wrapper in `Blender\FlowCellButtons`
4. adds the new button to the selected FlowCell panel
5. reports whether Blender must reload the add-on or restart

## What FlowCell Generates

One wrapper equals one FlowCell button.

That wrapper:

- lives in `Blender\FlowCellButtons`
- stores the button description
- records where the Python source function came from
- dispatches through `Blender\SupportScripts\Invoke-BlenderFlowCellAction.ps1`

Click path:

FlowCell button -> `.ps1` wrapper -> `Invoke-BlenderFlowCellAction.ps1` -> `flowcell_bridge.py` -> `flowcell_actions.py` -> Blender runs the action

## Full Path Map

All paths below are written from the FlowCell repo root. They do not include machine-specific user folders.

Repo-side button wrappers:

- `Blender\FlowCellButtons`

Repo-side bridge helper scripts:

- `Blender\SupportScripts\Invoke-BlenderFlowCellAction.ps1`
- `Blender\SupportScripts\Install-BlenderFlowCellButtons.ps1`
- `Blender\SupportScripts\Sync-BlenderButtonsToFlowCell.ps1`

Repo-side managed custom action source area:

- `Blender\ManagedActions`

Repo-side FlowCell Blender config files:

- `Blender\config.json`
- `FlowCell\local\private\blender.config.local.json`

Repo-side FlowCell UI entry point for the Blender Add Button flow:

- `FlowCell\FlowCellUI.ps1`

Live Blender add-on location source:

- `FlowCell\local\private\blender.config.local.json`
- `Blender\config.json`

Live Blender bridge folder name:

- `blender_bridge`

Live Blender runtime file names:

- `flowcell_bridge.py`
- `flowcell_actions.py`
- `flowcell_custom_actions.json`
- `flowcell_bridge_setup.json`

Private rough/testing storage:

- `Blender\ScriptDump`
- `Blender\FlowCellButtons\ScriptDump`

## Quick Checklist

Before you click `Add Button`, make sure the file:

- imports what it needs, usually `bpy`
- has one top-level entrypoint named `run_flowcell_action`, `main`, or `perform_*`
- raises clear `ValueError` messages for invalid state
- returns a useful message or dict
- does direct Blender scene work
- does not try to be a background service or add-on package

## ScriptDump

`ScriptDump` is private storage for rough, testing, old, or downloaded files. It is not the normal GitHub-updated button source.
