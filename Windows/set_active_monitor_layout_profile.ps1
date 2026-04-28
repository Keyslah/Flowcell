Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$dialogScript = 'D:\Dev\workspace\Codex\flowcell\Windows\set_active_monitor_layout_profile_dialog.ps1'
if (-not (Test-Path -LiteralPath $dialogScript -PathType Leaf)) {
    throw "Monitor layout selection dialog script not found: $dialogScript"
}

Start-Process -FilePath 'powershell.exe' -ArgumentList @(
    '-NoProfile',
    '-ExecutionPolicy', 'Bypass',
    '-Sta',
    '-File', $dialogScript
) | Out-Null
