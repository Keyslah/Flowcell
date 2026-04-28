$ErrorActionPreference = 'Stop'
& 'D:\Dev\workspace\Codex\flowcell\Blender\FlowCellButtons\Invoke-BlenderFlowCellAction.ps1' -Action 'save_selected_stl_to_assets' -Label 'save stl'
exit $LASTEXITCODE

