Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-PythonExecutablePath {
    $pythonCandidates = @('py.exe', 'python.exe')

    foreach ($candidate in $pythonCandidates) {
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($command) {
            return [string]$command.Source
        }
    }

    throw 'Python was not found for the dummy monitor toggle. Install Python or add py.exe/python.exe to PATH.'
}

function Get-DummyMonitorToggleScriptPath {
    if (-not [string]::IsNullOrWhiteSpace($env:FLOWCELL_DUMMY_MONITOR_SCRIPT)) {
        return $env:FLOWCELL_DUMMY_MONITOR_SCRIPT
    }

    throw 'Set FLOWCELL_DUMMY_MONITOR_SCRIPT to the local dummy monitor helper script path.'
}

function Get-DummyMonitorTargetDisplay {
    if (-not [string]::IsNullOrWhiteSpace($env:FLOWCELL_DUMMY_MONITOR_TARGET_DISPLAY)) {
        return $env:FLOWCELL_DUMMY_MONITOR_TARGET_DISPLAY
    }

    return '\\.\DISPLAY4'
}

$pythonExe = Get-PythonExecutablePath
$toggleScript = Get-DummyMonitorToggleScriptPath
if (-not (Test-Path -LiteralPath $toggleScript -PathType Leaf)) {
    throw "Dummy monitor toggle script not found: $toggleScript"
}

$targetDisplay = Get-DummyMonitorTargetDisplay
& $pythonExe $toggleScript --toggle-once --target-display $targetDisplay
exit $LASTEXITCODE
