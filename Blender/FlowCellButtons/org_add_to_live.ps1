$ErrorActionPreference = 'Stop'
$dispatcherPath = Join-Path $PSScriptRoot 'Invoke-BlenderFlowCellAction.ps1'
& $dispatcherPath -Action 'add_to_live' -Label 'add to live'
exit $LASTEXITCODE

