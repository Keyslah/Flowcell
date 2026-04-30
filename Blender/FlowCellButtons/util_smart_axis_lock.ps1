# Description: Open Smart Axis Lock controls for Baseline, Live, and X/Y/Z side toggles.

param(
    [string]$ConfigPath = '',
    [string]$StatusPath = '',
    [ValidateSet('', 'baseline', 'toggle_live', 'toggle_x', 'toggle_y', 'toggle_z')]
    [string]$ToolCommand = '',
    [switch]$SelfTest
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

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class FlowCellWindowNative {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
}
'@

function New-SolidBrush([byte]$R, [byte]$G, [byte]$B) {
    return New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb($R, $G, $B))
}

function Write-Status([string]$Message) {
    try {
        $folder = Split-Path -Parent $StatusPath
        if (-not [string]::IsNullOrWhiteSpace($folder)) { New-Item -ItemType Directory -Path $folder -Force | Out-Null }
        Set-Content -LiteralPath $StatusPath -Value $Message -Encoding UTF8
    } catch {}
}

function Invoke-SmartAxisCommand([string]$Command) {
    $dispatcherPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'SupportScripts\Invoke-BlenderFlowCellAction.ps1'
    $data = @{ action = $Command } | ConvertTo-Json -Compress
    & $dispatcherPath -Action 'smart_axis_lock' -Label 'Smart Axis Lock' -DataJson $data -SuppressToast
    if ($LASTEXITCODE -ne 0) { throw "Smart Axis Lock command failed: $Command" }
}

if (-not [string]::IsNullOrWhiteSpace($ToolCommand)) {
    try {
        Invoke-SmartAxisCommand -Command $ToolCommand
        Write-Status "Smart Axis Lock: $ToolCommand"
        exit 0
    } catch {
        Write-Status $_.Exception.Message
        Write-Error $_.Exception.Message
        exit 1
    }
}

try {
    $normalBrush = New-SolidBrush 64 70 78
    $foregroundBrush = New-SolidBrush 242 242 242

    $window = New-Object System.Windows.Window
    $window.Title = 'Smart Axis Lock'
    $window.Width = 332
    $window.Height = 76
    $window.MinWidth = 332
    $window.MinHeight = 76
    $window.WindowStartupLocation = 'CenterScreen'
    $window.WindowStyle = 'None'
    $window.ResizeMode = 'NoResize'
    $window.Background = New-SolidBrush 29 35 43
    $window.Foreground = $foregroundBrush
    $window.ShowActivated = $true

    $border = New-Object System.Windows.Controls.Border
    $border.Padding = '6'
    $border.Background = New-SolidBrush 38 45 54
    $window.Content = $border

    $grid = New-Object System.Windows.Controls.Grid
    $border.Child = $grid
    foreach ($h in @('Auto')) {
        $row = New-Object System.Windows.Controls.RowDefinition
        $row.Height = [System.Windows.GridLength]::Auto
        [void]$grid.RowDefinitions.Add($row)
    }
    foreach ($w in @(92, 58, 58, 58, 58)) {
        [void]$grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = (New-Object System.Windows.GridLength $w) }))
    }

    function New-ToolButton([string]$Text, [string]$Command, [int]$Column) {
        $button = New-Object System.Windows.Controls.Button
        $button.Content = $Text
        $button.Height = 27
        $button.Margin = if ($Column -eq 0) { '0' } else { '3,0,0,0' }
        $button.Padding = '4,1'
        $button.FontSize = 13
        $button.Background = $normalBrush
        $button.Foreground = $foregroundBrush
        $button.BorderBrush = New-SolidBrush 95 105 118
        $button.BorderThickness = '1'
        [System.Windows.Controls.Grid]::SetColumn($button, $Column)
        [void]$grid.Children.Add($button)
        $commandValue = [string]$Command
        $button.Add_Click({
            try {
                Invoke-SmartAxisCommand -Command $commandValue
                Write-Status "Smart Axis Lock: $commandValue"
            } catch {
                Write-Status $_.Exception.Message
                [System.Windows.MessageBox]::Show($window, $_.Exception.Message, 'Smart Axis Lock') | Out-Null
            }
        }.GetNewClosure())
    }

    New-ToolButton 'Baseline' 'baseline' 0
    New-ToolButton 'Live' 'toggle_live' 1
    New-ToolButton 'X' 'toggle_x' 2
    New-ToolButton 'Y' 'toggle_y' 3
    New-ToolButton 'Z' 'toggle_z' 4

    $border.Add_PreviewMouseLeftButtonDown({
        param($sender, $eventArgs)
        if ($eventArgs.OriginalSource -is [System.Windows.Controls.Button]) { return }
        try { $window.DragMove(); $eventArgs.Handled = $true } catch {}
    })
    $window.Add_SourceInitialized({
        $helper = New-Object System.Windows.Interop.WindowInteropHelper($window)
        if ($helper.Handle -ne [IntPtr]::Zero) {
            [FlowCellWindowNative]::ShowWindowAsync($helper.Handle, 5) | Out-Null
            [FlowCellWindowNative]::SetForegroundWindow($helper.Handle) | Out-Null
        }
    })
    $window.Add_KeyDown({
        param($sender, $eventArgs)
        if ($eventArgs.Key -eq [System.Windows.Input.Key]::Escape) { $sender.Close() }
    })

    if ($SelfTest) {
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromMilliseconds(100)
        $timer.Add_Tick({ $timer.Stop(); $window.Close() }.GetNewClosure())
        $timer.Start()
    }

    [void]$window.ShowDialog()
    if ($SelfTest) { Write-Output 'Smart Axis Lock UI self-test OK' }
    exit 0
} catch {
    Write-Status $_.Exception.Message
    try { [System.Windows.MessageBox]::Show($_.Exception.Message, 'Smart Axis Lock') | Out-Null } catch {}
    exit 1
}
