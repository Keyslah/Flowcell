# Description: Smart Axis Lock Z cycles Z between none, minus side, plus side.
$ErrorActionPreference = 'Stop'
$runner = Join-Path $PSScriptRoot 'util_smart_axis_lock.ps1'
& $runner -ToolCommand 'toggle_z'
exit $LASTEXITCODE
