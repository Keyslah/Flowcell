Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName Microsoft.VisualBasic

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$projectRoot = Join-Path $repoRoot 'Blender'
$localRoot = Join-Path $repoRoot 'FlowCell\local'
$localConfigPath = Join-Path $localRoot 'private\blender.config.local.json'
$configPath = if (Test-Path -LiteralPath $localConfigPath -PathType Leaf) { $localConfigPath } else { Join-Path $projectRoot 'config.json' }
$flowCellStatePath = Join-Path $localRoot 'flowcell_state.json'
$flowCellLayoutsRoot = Join-Path $localRoot 'layouts'
$wrapperRoot = Join-Path $projectRoot 'FlowCellButtons'
$dispatcherPath = Join-Path $wrapperRoot 'Invoke-BlenderFlowCellAction.ps1'
$renameSelectedPath = Join-Path $wrapperRoot 'org_rename_selected_objects.ps1'
$legacyAddonPattern = Join-Path (Join-Path ([Environment]::GetFolderPath('ApplicationData')) 'Blender Foundation\Blender') '*\scripts\addons\flowcell_*.py'

function Get-SafeName([string]$Value) {
    $safe = ($Value -replace '[^A-Za-z0-9]+', '_').Trim('_')
    if ([string]::IsNullOrWhiteSpace($safe)) {
        return 'button'
    }
    return $safe.ToLowerInvariant()
}

function Get-FlowCellButtonPrefix([string]$PanelName) {
    $normalizedPanelName = if ($null -ne $PanelName) { [string]$PanelName } else { '' }
    switch ($normalizedPanelName.Trim().ToLowerInvariant()) {
        'collections' { return 'org_' }
        'layers' { return 'org_' }
        'files' { return 'file_' }
        default { return 'util_' }
    }
}

function Get-WrapperFileName([string]$PanelName, [string]$Name) {
    return ('{0}{1}.ps1' -f (Get-FlowCellButtonPrefix -PanelName $PanelName), (Get-SafeName -Value $Name))
}

function New-WrapperContent([string]$DispatcherPath, [string]$Action, [string]$Label, [string]$Direction) {
    $lines = @(
        '$ErrorActionPreference = ''Stop'''
    )
    $command = "& '{0}' -Action '{1}' -Label '{2}'" -f ($DispatcherPath -replace "'", "''"), ($Action -replace "'", "''"), ($Label -replace "'", "''")
    if (-not [string]::IsNullOrWhiteSpace($Direction)) {
        $command += " -Direction '{0}'" -f ($Direction -replace "'", "''")
    }
    $lines += $command
    $lines += 'exit $LASTEXITCODE'
    return ($lines -join "`r`n") + "`r`n"
}

function Move-FileToRecycleBin([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return
    }

    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
        $Path,
        [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
        [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
    )
}

if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    throw "Blender config not found: $configPath"
}

if (-not (Test-Path -LiteralPath $flowCellStatePath -PathType Leaf)) {
    throw "FlowCell state not found: $flowCellStatePath"
}

New-Item -ItemType Directory -Path $wrapperRoot -Force | Out-Null

$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$customProtectedNames = @(
    foreach ($button in @($config.buttons)) {
        if (-not ($button.PSObject.Properties['scriptPath'])) { continue }
        $scriptPath = [string]$button.scriptPath
        if ([string]::IsNullOrWhiteSpace($scriptPath)) { continue }
        try {
            $resolved = Resolve-Path -LiteralPath $scriptPath -ErrorAction SilentlyContinue
            $fullPath = if ($resolved) { [string]$resolved.Path } else { $scriptPath }
            if ((Split-Path -Parent $fullPath) -ieq $wrapperRoot) {
                Split-Path -Leaf $fullPath
            }
        }
        catch {
        }
    }
)

$protectedNames = @(
    'Invoke-BlenderFlowCellAction.ps1',
    'Sync-BlenderButtonsToFlowCell.ps1',
    'org_rename_selected_objects.ps1'
) + @($customProtectedNames)
Get-ChildItem -LiteralPath $wrapperRoot -Filter '*.ps1' -File -ErrorAction SilentlyContinue |
    Where-Object { $protectedNames -notcontains $_.Name } |
    ForEach-Object { Move-FileToRecycleBin -Path $_.FullName }
$buttonSpecs = New-Object System.Collections.Generic.List[object]

foreach ($button in @($config.buttons)) {
    $hasLocalAction = ($button.PSObject.Properties['localAction'] -and -not [string]::IsNullOrWhiteSpace([string]$button.localAction))
    $action = if ($button.PSObject.Properties['action']) { [string]$button.action } else { '' }
    $scriptPath = if ($button.PSObject.Properties['scriptPath']) { [string]$button.scriptPath } else { '' }
    $panel = if ($button.PSObject.Properties['panel'] -and -not [string]::IsNullOrWhiteSpace([string]$button.panel)) { [string]$button.panel } else { 'collections' }
    $tooltip = if ($button.PSObject.Properties['tooltip']) { [string]$button.tooltip } else { '' }
    if ($hasLocalAction) {
        continue
    }

    if (-not [string]::IsNullOrWhiteSpace($scriptPath)) {
        $safeName = Get-SafeName -Value ([string]$button.label)
        $buttonSpecs.Add([pscustomobject]@{
            Id        = ('button_blender_flowcell_{0}' -f $safeName)
            Label     = [string]$button.label
            Target    = $scriptPath
            Tooltip   = $tooltip
            Action    = ''
            Direction = ''
            Panel     = $panel
        }) | Out-Null
        continue
    }

    if ([string]::IsNullOrWhiteSpace($action)) {
        continue
    }

    if (($button.PSObject.Properties['showCycleArrows']) -and [bool]$button.showCycleArrows -and $action -eq 'cycle_live_versions') {
        $buttonSpecs.Add([pscustomobject]@{
            Id        = 'button_blender_flowcell_cycle_versions_back'
            Label     = 'cycle versions <'
            Target    = (Join-Path $wrapperRoot (Get-WrapperFileName -PanelName $panel -Name 'cycle_versions_back'))
            Tooltip   = $tooltip
            Action    = $action
            Direction = 'backward'
            Panel     = $panel
        }) | Out-Null
        $buttonSpecs.Add([pscustomobject]@{
            Id        = 'button_blender_flowcell_cycle_versions_forward'
            Label     = 'cycle versions >'
            Target    = (Join-Path $wrapperRoot (Get-WrapperFileName -PanelName $panel -Name 'cycle_versions_forward'))
            Tooltip   = $tooltip
            Action    = $action
            Direction = 'forward'
            Panel     = $panel
        }) | Out-Null
        continue
    }

    $safeName = Get-SafeName -Value $action
    $buttonSpecs.Add([pscustomobject]@{
        Id        = ('button_blender_flowcell_{0}' -f $safeName)
        Label     = [string]$button.label
        Target    = (Join-Path $wrapperRoot (Get-WrapperFileName -PanelName $panel -Name $safeName))
        Tooltip   = $tooltip
        Action    = $action
        Direction = ''
        Panel     = $panel
    }) | Out-Null
}

$buttonSpecs.Add([pscustomobject]@{
    Id        = 'button_blender_flowcell_rename_selected_objects'
    Label     = 'rename selected'
    Target    = $renameSelectedPath
    Tooltip   = 'Rename all selected Blender objects in one prompt.'
    Action    = ''
    Direction = ''
    Panel     = 'collections'
}) | Out-Null

foreach ($spec in $buttonSpecs) {
    if (-not [string]::IsNullOrWhiteSpace([string]$spec.Action)) {
        $wrapperContent = New-WrapperContent -DispatcherPath $dispatcherPath -Action ([string]$spec.Action) -Label ([string]$spec.Label) -Direction ([string]$spec.Direction)
        Set-Content -LiteralPath ([string]$spec.Target) -Value $wrapperContent -Encoding ASCII
    }
}

$flowState = Get-Content -LiteralPath $flowCellStatePath -Raw | ConvertFrom-Json
$blenderProgram = @($flowState.Programs | Where-Object { [int]$_.ProgramTabId -eq 3 } | Select-Object -First 1)
if (@($blenderProgram).Count -eq 0) {
    throw 'Blender FlowCell program was not found.'
}
$blenderProgram = $blenderProgram[0]

$filesPanel = @($blenderProgram.Panels | Where-Object { [string]$_.Id -eq 'panel_files' -or [string]$_.Name -ieq 'Files' } | Select-Object -First 1)
$utilityPanel = @($blenderProgram.Panels | Where-Object { [string]$_.Id -eq 'panel_utility' -or [string]$_.Name -ieq 'Utility' } | Select-Object -First 1)
$collectionsPanel = @($blenderProgram.Panels | Where-Object { [string]$_.Name -ieq 'Collections' } | Select-Object -First 1)
$editPanel = @($blenderProgram.Panels | Where-Object { [string]$_.Id -eq 'panel_edit' -or [string]$_.Name -ieq 'Edit' } | Select-Object -First 1)
if (@($filesPanel).Count -eq 0) {
    throw 'Blender Files panel was not found.'
}
if (@($utilityPanel).Count -eq 0) {
    throw 'Blender Utility panel was not found.'
}
if (@($collectionsPanel).Count -eq 0) {
    throw 'Blender Collections panel was not found.'
}
$filesPanel = $filesPanel[0]
$utilityPanel = $utilityPanel[0]
$collectionsPanel = $collectionsPanel[0]
if (@($editPanel).Count -eq 0) {
    $editPanel = [pscustomobject]@{
        Id = 'panel_edit'
        Name = 'Edit'
        IsPoppedOut = $false
        PopoutBounds = $null
        Buttons = @()
    }
    $blenderProgram.Panels += $editPanel
}
else {
    $editPanel = $editPanel[0]
}

$preservedFileButtons = @(
    @($filesPanel.Buttons) | Where-Object {
        -not ([string]$_.Id -like 'button_blender_flowcell_*') -and
        -not ([string]$_.Target -like (Join-Path $wrapperRoot '*')) -and
        -not ([string]$_.Target -like $legacyAddonPattern)
    }
)
$preservedCollectionButtons = @(
    @($collectionsPanel.Buttons) | Where-Object {
        -not ([string]$_.Id -like 'button_blender_flowcell_*') -and
        -not ([string]$_.Target -like (Join-Path $wrapperRoot '*')) -and
        -not ([string]$_.Target -like $legacyAddonPattern)
    }
)
$preservedUtilityButtons = @(
    @($utilityPanel.Buttons) | Where-Object {
        -not ([string]$_.Id -like 'button_blender_flowcell_*') -and
        -not ([string]$_.Target -like (Join-Path $wrapperRoot '*')) -and
        -not ([string]$_.Target -like $legacyAddonPattern)
    }
)
$preservedEditButtons = @(
    @($editPanel.Buttons) | Where-Object {
        -not ([string]$_.Id -like 'button_blender_flowcell_*') -and
        -not ([string]$_.Target -like (Join-Path $wrapperRoot '*')) -and
        -not ([string]$_.Target -like $legacyAddonPattern)
    }
)

$importedButtons = @(
    foreach ($spec in $buttonSpecs) {
        [pscustomobject]@{
            Id        = [string]$spec.Id
            Kind      = 'script'
            Label     = [string]$spec.Label
            Target    = [string]$spec.Target
            Tooltip   = [string]$spec.Tooltip
            Shortcut  = ''
            BindingId = 0
            Panel     = [string]$spec.Panel
        }
    }
)

$importedFileButtons = @($importedButtons | Where-Object { [string]$_.Panel -ieq 'files' } | ForEach-Object {
    [pscustomobject]@{
        Id        = [string]$_.Id
        Kind      = [string]$_.Kind
        Label     = [string]$_.Label
        Target    = [string]$_.Target
        Tooltip   = [string]$_.Tooltip
        Shortcut  = [string]$_.Shortcut
        BindingId = [int]$_.BindingId
    }
})
$importedUtilityButtons = @($importedButtons | Where-Object { [string]$_.Panel -ieq 'utility' } | ForEach-Object {
    [pscustomobject]@{
        Id        = [string]$_.Id
        Kind      = [string]$_.Kind
        Label     = [string]$_.Label
        Target    = [string]$_.Target
        Tooltip   = [string]$_.Tooltip
        Shortcut  = [string]$_.Shortcut
        BindingId = [int]$_.BindingId
    }
})
$importedEditButtons = @($importedButtons | Where-Object { [string]$_.Panel -ieq 'edit' } | ForEach-Object {
    [pscustomobject]@{
        Id        = [string]$_.Id
        Kind      = [string]$_.Kind
        Label     = [string]$_.Label
        Target    = [string]$_.Target
        Tooltip   = [string]$_.Tooltip
        Shortcut  = [string]$_.Shortcut
        BindingId = [int]$_.BindingId
    }
})
$importedCollectionButtons = @($importedButtons | Where-Object { [string]$_.Panel -ine 'files' -and [string]$_.Panel -ine 'utility' -and [string]$_.Panel -ine 'edit' } | ForEach-Object {
    [pscustomobject]@{
        Id        = [string]$_.Id
        Kind      = [string]$_.Kind
        Label     = [string]$_.Label
        Target    = [string]$_.Target
        Tooltip   = [string]$_.Tooltip
        Shortcut  = [string]$_.Shortcut
        BindingId = [int]$_.BindingId
    }
})

$filesPanel.Buttons = @($preservedFileButtons + $importedFileButtons)
$filesPanel.IsPoppedOut = $false
$utilityPanel.Buttons = @($preservedUtilityButtons + $importedUtilityButtons)
$editPanel.Buttons = @($preservedEditButtons + $importedEditButtons)
$collectionsPanel.Buttons = @($preservedCollectionButtons + $importedCollectionButtons)
$collectionsPanel.IsPoppedOut = $false
$blenderProgram.SelectedPanelId = if (@($importedEditButtons).Count -gt 0) { [string]$editPanel.Id } elseif (@($importedUtilityButtons).Count -gt 0) { [string]$utilityPanel.Id } elseif (@($importedFileButtons).Count -gt 0) { [string]$filesPanel.Id } else { [string]$collectionsPanel.Id }

$json = $flowState | ConvertTo-Json -Depth 8
Set-Content -LiteralPath $flowCellStatePath -Value $json -Encoding UTF8

$layoutPaths = @(
    Join-Path $flowCellLayoutsRoot 'main.flowlayout.json'
    Join-Path $flowCellLayoutsRoot 'last_layout.json'
)

foreach ($layoutPath in $layoutPaths) {
    if (-not (Test-Path -LiteralPath $layoutPath -PathType Leaf)) {
        continue
    }

    try {
        $layoutPayload = Get-Content -LiteralPath $layoutPath -Raw | ConvertFrom-Json
        $layoutState = if ($layoutPayload.PSObject.Properties['FlowCellState'] -and $layoutPayload.FlowCellState) {
            $layoutPayload.FlowCellState
        }
        else {
            $layoutPayload
        }

        $layoutBlenderProgram = @($layoutState.Programs | Where-Object { [int]$_.ProgramTabId -eq 3 } | Select-Object -First 1)
        if (@($layoutBlenderProgram).Count -eq 0) {
            continue
        }
        $layoutBlenderProgram = $layoutBlenderProgram[0]

        foreach ($sourcePanel in @($blenderProgram.Panels)) {
            $targetPanel = @($layoutBlenderProgram.Panels | Where-Object {
                [string]$_.Id -eq [string]$sourcePanel.Id -or [string]$_.Name -ieq [string]$sourcePanel.Name
            } | Select-Object -First 1)
            if (@($targetPanel).Count -eq 0) {
                continue
            }
            $targetPanel[0].Buttons = @($sourcePanel.Buttons)
        }

        Set-Content -LiteralPath $layoutPath -Value ($layoutPayload | ConvertTo-Json -Depth 12) -Encoding UTF8
    }
    catch {
        Write-Warning ('Could not update layout {0}: {1}' -f $layoutPath, $_.Exception.Message)
    }
}

Write-Output ('Imported {0} Blender buttons into FlowCell. Files={1}; Utility={2}; Edit={3}; Collections={4}' -f @($importedButtons).Count, @($importedFileButtons).Count, @($importedUtilityButtons).Count, @($importedEditButtons).Count, @($importedCollectionButtons).Count)

