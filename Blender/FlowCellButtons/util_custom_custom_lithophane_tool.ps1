# Description: Prompt for an image, build a DPI-sized plane, and turn it into a lithophane in one FlowCell action.

# Source Python File: D:\Dev\workspace\Codex\flowcell\Blender\ManagedActions\custom_custom_lithophane_tool.py

# Source Action Function: run_flowcell_action
# Source Action Start Line: 405

# Source Action Logic:

# def run_flowcell_action(context=None, data=None):
#     return perform_create_lithophane_from_image(context, data)

$ErrorActionPreference = 'Stop'
$supportRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'SupportScripts'
$dispatcherPath = Join-Path $supportRoot 'Invoke-BlenderFlowCellAction.ps1'
& $dispatcherPath -Action 'custom_custom_lithophane_tool' -Label 'custom_lithophane_tool'
exit $LASTEXITCODE


