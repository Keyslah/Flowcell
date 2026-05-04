# Description: Dispatch Smart Axis Lock bridge actions through the FlowCell Blender bridge.

param(
    [Parameter(Mandatory = $true)]
    [string]$ToolCommand,
    [string]$ConfigPath = '',
    [string]$StatusPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$normalizedCommand = $ToolCommand.Trim().ToLowerInvariant()
$action = switch ($normalizedCommand) {
    'baseline' { 'baseline' }
    'set_baseline' { 'set_baseline' }
    'live' { 'toggle_live' }
    'toggle_live' { 'toggle_live' }
    'start_live' { 'start_live' }
    'stop_live' { 'stop_live' }
    'x' { 'toggle_x' }
    'toggle_x' { 'toggle_x' }
    'y' { 'toggle_y' }
    'toggle_y' { 'toggle_y' }
    'z' { 'toggle_z' }
    'toggle_z' { 'toggle_z' }
    'status' { 'status' }
    default { throw "Unsupported Smart Axis Lock command: $ToolCommand" }
}

$label = switch ($action) {
    'baseline' { 'Baseline' }
    'set_baseline' { 'Baseline' }
    'toggle_live' { 'Live' }
    'start_live' { 'Live' }
    'stop_live' { 'Live' }
    'toggle_x' { 'X' }
    'toggle_y' { 'Y' }
    'toggle_z' { 'Z' }
    'status' { 'Smart Axis Lock' }
    default { 'Smart Axis Lock' }
}

$supportRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'SupportScripts'
$dispatcherPath = Join-Path $supportRoot 'Invoke-BlenderFlowCellAction.ps1'
$dataJson = (@{ action = $action } | ConvertTo-Json -Compress)

$invokeArgs = @{
    Action = 'custom_util_smart_axis_lock'
    Label = $label
    DataJson = $dataJson
}
if (-not [string]::IsNullOrWhiteSpace($ConfigPath)) {
    $invokeArgs.ConfigPath = $ConfigPath
}
if (-not [string]::IsNullOrWhiteSpace($StatusPath)) {
    $invokeArgs.StatusPath = $StatusPath
}

& $dispatcherPath @invokeArgs
exit $LASTEXITCODE
