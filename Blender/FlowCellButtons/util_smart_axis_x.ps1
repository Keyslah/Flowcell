# Description: Smart Axis Lock X cycles X between none, minus side, plus side.
$ErrorActionPreference = 'Stop'
$runner = Join-Path $PSScriptRoot 'util_smart_axis_lock.ps1'
& $runner -ToolCommand 'toggle_x'
exit $LASTEXITCODE
