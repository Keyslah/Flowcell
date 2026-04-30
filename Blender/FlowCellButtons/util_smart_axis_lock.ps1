# Description: Run one Smart Axis Lock command through the FlowCell Blender bridge.

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('baseline', 'toggle_live', 'toggle_x', 'toggle_y', 'toggle_z')]
    [string]$ToolCommand,
    [string]$ConfigPath = '',
    [string]$StatusPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$flowCellLocalRoot = Join-Path $repoRoot 'FlowCell\local'
$localConfigPath = Join-Path $flowCellLocalRoot 'private\blender.config.local.json'
if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = if (Test-Path -LiteralPath $localConfigPath -PathType Leaf) { $localConfigPath } else { Join-Path $repoRoot 'Blender\config.json' }
}
if ([string]::IsNullOrWhiteSpace($StatusPath)) {
    $StatusPath = Join-Path $flowCellLocalRoot 'logs\last_action_status.txt'
}

function Write-Status([string]$Message) {
    try {
        $folder = Split-Path -Parent $StatusPath
        if (-not [string]::IsNullOrWhiteSpace($folder)) { New-Item -ItemType Directory -Path $folder -Force | Out-Null }
        Set-Content -LiteralPath $StatusPath -Value $Message -Encoding UTF8
    } catch {}
}

function Ensure-SmartAxisBridgeAction {
    if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) { throw "Blender config not found: $ConfigPath" }
    $config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
    $bridgeFolder = if ($config.automation -and $config.automation.PSObject.Properties['bridgeFolder']) { [string]$config.automation.bridgeFolder } else { '' }
    if ([string]::IsNullOrWhiteSpace($bridgeFolder)) { throw 'Blender config is missing automation.bridgeFolder.' }

    $sourcePythonPath = Join-Path $repoRoot 'Blender\ScriptBank\Utilities\util_smart_axis_lock.py'
    if (-not (Test-Path -LiteralPath $sourcePythonPath -PathType Leaf)) { throw "Smart Axis source file not found: $sourcePythonPath" }

    $registryPath = Join-Path $bridgeFolder 'flowcell_custom_actions.json'
    New-Item -ItemType Directory -Path $bridgeFolder -Force | Out-Null
    $registry = [pscustomobject]@{ actions = @() }
    if (Test-Path -LiteralPath $registryPath -PathType Leaf) {
        try {
            $registry = Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json
            if ($null -eq $registry.actions) { $registry | Add-Member -MemberType NoteProperty -Name actions -Value @() -Force }
        } catch { $registry = [pscustomobject]@{ actions = @() } }
    }

    $kept = @($registry.actions | Where-Object { [string]$_.action -ne 'smart_axis_lock' })
    $entry = [pscustomobject]@{
        action = 'smart_axis_lock'
        sourcePythonPath = $sourcePythonPath
        sourceFunctionName = 'run_flowcell_action'
        label = 'Smart Axis Lock'
        tooltip = 'Run Smart Axis Lock Baseline, Live, X, Y, and Z commands.'
    }
    $registry.actions = @($kept + $entry)
    Set-Content -LiteralPath $registryPath -Value ($registry | ConvertTo-Json -Depth 8) -Encoding UTF8

    $syncPath = Join-Path $repoRoot 'Blender\SupportScripts\Sync-BlenderCustomActionCode.ps1'
    if (-not (Test-Path -LiteralPath $syncPath -PathType Leaf)) { throw "Custom action sync script not found: $syncPath" }
    & $syncPath -ConfigPath $ConfigPath -BridgeFolder $bridgeFolder | Out-Null
}

try {
    Ensure-SmartAxisBridgeAction
    $dispatcherPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'SupportScripts\Invoke-BlenderFlowCellAction.ps1'
    $data = @{ action = $ToolCommand } | ConvertTo-Json -Compress
    & $dispatcherPath -Action 'smart_axis_lock' -Label 'Smart Axis Lock' -DataJson $data -SuppressToast
    if ($LASTEXITCODE -ne 0) { throw "Smart Axis Lock command failed: $ToolCommand" }
    Write-Status "Smart Axis Lock: $ToolCommand"
    exit 0
} catch {
    Write-Status $_.Exception.Message
    Write-Error $_.Exception.Message
    exit 1
}
