# Description: Smart Axis Lock Baseline stores selected object bounds.
$ErrorActionPreference = 'Stop'
$runner = Join-Path $PSScriptRoot 'util_smart_axis_lock.ps1'
& $runner -ToolCommand 'baseline'
exit $LASTEXITCODE
