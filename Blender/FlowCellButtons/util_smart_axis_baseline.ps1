# Description: Smart Axis Lock Baseline stores the current selected object bounds on X/Y/Z.
$ErrorActionPreference = 'Stop'
$runner = Join-Path $PSScriptRoot 'util_smart_axis_lock.ps1'
& $runner -ToolCommand 'baseline'
exit $LASTEXITCODE
