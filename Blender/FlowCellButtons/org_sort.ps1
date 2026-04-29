$ErrorActionPreference = 'Stop'
$dispatcherPath = Join-Path $PSScriptRoot 'Invoke-BlenderFlowCellAction.ps1'
& $dispatcherPath -Action 'sort' -Label 'sort'
exit $LASTEXITCODE

