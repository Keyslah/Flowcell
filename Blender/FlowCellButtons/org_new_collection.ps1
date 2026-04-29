$ErrorActionPreference = 'Stop'
$dispatcherPath = Join-Path $PSScriptRoot 'Invoke-BlenderFlowCellAction.ps1'
& $dispatcherPath -Action 'new_collection' -Label 'new collection'
exit $LASTEXITCODE

