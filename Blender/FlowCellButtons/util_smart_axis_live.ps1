# Description: Smart Axis Lock Live toggles live pinning while scaling.
$ErrorActionPreference = 'Stop'
$runner = Join-Path $PSScriptRoot 'util_smart_axis_lock.ps1'
& $runner -ToolCommand 'toggle_live'
exit $LASTEXITCODE
