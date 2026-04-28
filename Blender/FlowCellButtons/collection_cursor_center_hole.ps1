$ErrorActionPreference = 'Stop'
& 'D:\Dev\workspace\Codex\flowcell\Blender\FlowCellButtons\Invoke-BlenderFlowCellAction.ps1' -Action 'alignment_tools' -Label 'Cursor Center Hole' -DataJson '{"command":"cursor_center_hole"}'
exit $LASTEXITCODE

