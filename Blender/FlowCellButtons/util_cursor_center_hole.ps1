$ErrorActionPreference = 'Stop'
$dispatcherPath = Join-Path $PSScriptRoot 'Invoke-BlenderFlowCellAction.ps1'
& $dispatcherPath -Action 'alignment_tools' -Label 'Cursor Center Hole' -DataJson '{"command":"cursor_center_hole"}'
exit $LASTEXITCODE

