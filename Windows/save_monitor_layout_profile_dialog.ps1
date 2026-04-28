Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms

function Get-PythonExecutablePath {
    $pythonCandidates = @('py.exe', 'python.exe')

    foreach ($candidate in $pythonCandidates) {
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($command) {
            return [string]$command.Source
        }
    }

    throw 'Python was not found for monitor layout save. Install Python or add py.exe/python.exe to PATH.'
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

$defaultName = 'Layout ' + (Get-Date -Format 'yyyy-MM-dd HHmm')
$layoutName = [Microsoft.VisualBasic.Interaction]::InputBox(
    'Enter a name for the current monitor layout. Saving it also makes it the active layout used for restore.',
    'Save Monitor Layout',
    $defaultName
)

if ([string]::IsNullOrWhiteSpace($layoutName)) {
    exit 0
}

$output = & $pythonExe $toggleScript --save-layout $layoutName --target-display $targetDisplay
if ($LASTEXITCODE -ne 0) {
    throw "Saving monitor layout failed with exit code $LASTEXITCODE."
}

$result = $output | ConvertFrom-Json
[System.Windows.Forms.MessageBox]::Show(
    "Saved layout '$($result.name)' and made it active for future restores.",
    'Save Monitor Layout',
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
) | Out-Null
