$ErrorActionPreference = 'Stop'
$dispatcherPath = Join-Path $PSScriptRoot 'Invoke-BlenderFlowCellAction.ps1'
& $dispatcherPath -Action 'save_selected_stl_to_assets' -Label 'save stl'
exit $LASTEXITCODE

