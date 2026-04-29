# Blender Buttons

## Overview

When you click `Add Button` in the Blender tab, FlowCell asks for a Blender `.py` script.

That script can be either:

- single action = one FlowCell button / one Blender function
- tool set = one script that defines multiple related FlowCell buttons/functions

The script should be clean Blender Python, usually using `bpy`. It should run from the current scene, selection, or active object. It should not be a full Blender add-on, installer, Blender UI panel, Blender menu/button creator, modal tool, blocking popup workflow, or something that only works from Blender's Text Editor.

The Python file must expose one callable FlowCell action entrypoint:

- `run_flowcell_action`
- `main`
- a function named `perform_*`

If the file is only a listener/bootstrap script or exposes unrelated helpers like `handle`/`server`, FlowCell now rejects it instead of creating a dead button.

## How To Structure The Script

This is the part that matters most.

FlowCell does not want a full Blender add-on. It wants one normal Python file that exposes one callable action function. That callable is what the button actually runs.

Good mental model:

- one file
- one real action entrypoint
- optional helper functions under it
- action code that uses the current Blender scene, selection, mode, or active object
- return a short result back to FlowCell

Bad mental model:

- a background server
- a socket listener
- a one-time installer
- a Blender panel/menu registration script
- a script that only works when manually pressed from Blender's Text Editor

### Required Entrypoint Names

Your file must expose one of these top-level functions:

- `run_flowcell_action`
- `main`
- any function whose name starts with `perform_`

FlowCell looks for those names on purpose. If your file only contains helpers like `handle`, `server`, `bootstrap`, or `register`, it is the wrong shape for `Add Button`.

### Recommended File Shape

Use this structure:

```python
import bpy


def perform_my_tool(context, data):
    # Validate selection/state first.
    active = context.view_layer.objects.active
    if active is None:
        raise ValueError("Select one active object first.")

    # Do the Blender work here.
    active.location.x += 10.0

    # Return a short status message.
    return "Moved the active object 10 units on X."
```

That is the simplest reliable shape.

### What FlowCell Passes To Your Function

FlowCell tries these call patterns in this order:

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
- use `context` instead of reaching for global state first
- read optional values from `data` only if your action needs inputs beyond the current Blender state

### What Your Function Should Return

The action can return:

- a string
- a dict
- `None`

Recommended return types:

1. Simple success message:

```python
return "Created the support rim."
```

2. Structured result:

```python
return {
    "message": "Created the support rim.",
    "display": "Support rim added",
}
```

How FlowCell uses those:

- `message` is the main completion text
- `display` is optional extra UI text
- any additional dict fields are passed through as payload

If you return `None`, FlowCell falls back to a generic completion message. That works, but it is worse for usability.

### How To Signal Failure

Raise an exception with a clear message:

```python
if context.mode != "OBJECT":
    raise ValueError("Switch to Object Mode first.")
```

Good failures are:

- specific
- user-facing
- about the actual missing precondition

Examples:

- `"Select exactly one mesh object."`
- `"Open or save the .blend file first."`
- `"Active object must be a mesh."`

Avoid vague errors like:

- `"Failed"`
- `"Error running tool"`
- `"Bad state"`

### Keep Helpers, But Keep One Real Entrypoint

This is good:

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

This is bad:

```python
def server():
    ...


def handle(conn, addr):
    ...
```

That kind of file is infrastructure, not a button action.

### Use Top-Level Functions Only

Define the action entrypoint at the top level of the file.

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

### Keep The Script Focused On The Scene

Good Blender button scripts usually do one of these:

- modify the selected objects
- inspect or clean the active mesh
- create geometry
- organize collections or names
- export from the current scene
- prepare scene data for another app

They usually do not:

- stay resident forever
- open their own persistent network service
- manage Blender add-on installation
- build a whole new UI system
- depend on a manual operator being clicked elsewhere first

### Minimal Template

Use this as the default starter:

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

### Checklist Before You Add The Button

Before using `Add Button`, make sure the file:

- imports what it needs, usually `bpy`
- has one top-level entrypoint named `run_flowcell_action`, `main`, or `perform_*`
- raises clear `ValueError` messages for bad selection/state
- returns a useful message or dict
- does real Blender work directly, instead of starting a background system
- can run from the current Blender scene without manual Text Editor steps

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

## Add Button Flow

1. FlowCell asks for a Blender `.py` script from the Blender tab's `Add Button` flow.
2. That script is treated as either a single action or a small tool set.
3. FlowCell validates that the script exposes a supported FlowCell action entrypoint, then installs or registers the Blender-side action data so Blender has a callable function for the new button.
4. FlowCell copies the selected script's code into this exact live Blender file:
   `...\scripts\addons\blender_bridge\flowcell_actions.py`
5. FlowCell creates matching `.ps1` wrappers in `Blender\FlowCellButtons`.
6. Each wrapper launches the dispatcher at `Blender\SupportScripts\Invoke-BlenderFlowCellAction.ps1`.
7. FlowCell adds the new button to the selected panel and reports whether Blender needs a reload or restart.

## Click Path

FlowCell button

- `Blender\FlowCellButtons\<wrapper>.ps1`
- `Blender\SupportScripts\Invoke-BlenderFlowCellAction.ps1`
- `flowcell_bridge.py` in the configured Blender add-on location
- `flowcell_actions.py` in the configured Blender add-on location
- Blender runs the inserted function

## ScriptDump

`ScriptDump` is private storage for rough, testing, old, or downloaded files. It is not the normal GitHub-updated button source.
