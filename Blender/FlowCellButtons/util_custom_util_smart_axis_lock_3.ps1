# Description: Smart Axis Lock stores selected object bounds, cycles pinned axis sides, and can run live while scaling.

# Source Python File: D:\Dev\workspace\Codex\flowcell\Blender\ManagedActions\custom_util_smart_axis_lock_3.py

# Source Action Function: run_flowcell_action
# Source Action Start Line: 260

# Source Action Logic:

# def run_flowcell_action(context=None, data=None):
#     data = data or {}
#     action = str(data.get("action", "toggle_live")).lower().strip()
#     routes = {
#         "baseline": perform_set_baseline,
#         "set_baseline": perform_set_baseline,
#         "toggle_axis": perform_toggle_axis,
#         "x": perform_toggle_x,
#         "toggle_x": perform_toggle_x,
#         "y": perform_toggle_y,
#         "toggle_y": perform_toggle_y,
#         "z": perform_toggle_z,
#         "toggle_z": perform_toggle_z,
#         "pin": perform_pin_armed_axes,
#         "clear": perform_clear_axis_locks,
#         "live": perform_toggle_live,
#         "toggle_live": perform_toggle_live,
#         "start_live": perform_start_live,
#         "stop_live": perform_stop_live,
#         "status": perform_status,
#     }
#     return routes.get(action, perform_toggle_live)(context, data)
# 
# 

$ErrorActionPreference = 'Stop'
$supportRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'SupportScripts'
$dispatcherPath = Join-Path $supportRoot 'Invoke-BlenderFlowCellAction.ps1'
& $dispatcherPath -Action 'custom_util_smart_axis_lock_3' -Label 'util_smart_axis_lock'
exit $LASTEXITCODE


