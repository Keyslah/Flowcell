## How Blender buttons work

When you click Add Button in the Blender tab, FlowCell asks for a Blender .py script.
That script can be either:
single action = one FlowCell button / one Blender function
tool set = one script that defines multiple related FlowCell buttons/functions
The script should be clean Blender Python, usually using bpy. It should run from the current scene, selection, or active object. It should not be a full Blender add-on, installer, Blender UI panel, Blender menu/button creator, modal tool, blocking popup workflow, or something that only works from Blender’s Text Editor.
FlowCell copies the selected script’s code into this exact live Blender file:
...\scripts\addons\blender_layers_bridge\flowcell_actions.py
That file is the Python file Blender uses for FlowCell button logic. The inserted code becomes one or more named functions inside flowcell_actions.py, so Blender has real functions to run.
FlowCell also creates matching .ps1 wrappers in:
Blender\FlowCellButtons
A wrapper is the FlowCell-side button launcher. One wrapper equals one FlowCell button. It stores the button description, shows where the Python function was inserted, and calls:
Blender\SupportScripts\Invoke-BlenderFlowCellAction.ps1
Click path:
FlowCell button → .ps1 wrapper → Invoke-BlenderFlowCellAction.ps1 → flowcell_bridge.py → flowcell_actions.py → Blender runs the inserted function.
ScriptDump is private storage for rough/testing/old/downloaded files and is not GitHub-updated.
