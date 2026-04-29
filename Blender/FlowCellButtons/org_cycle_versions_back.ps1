$ErrorActionPreference = 'Stop'
$dispatcherPath = Join-Path $PSScriptRoot 'Invoke-BlenderFlowCellAction.ps1'
& $dispatcherPath -Action 'cycle_live_versions' -Label 'cycle versions <' -Direction 'backward'
exit $LASTEXITCODE

