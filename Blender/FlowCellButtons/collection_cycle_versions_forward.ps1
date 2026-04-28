$ErrorActionPreference = 'Stop'
& 'D:\Dev\workspace\Codex\flowcell\Blender\FlowCellButtons\Invoke-BlenderFlowCellAction.ps1' -Action 'cycle_live_versions' -Label 'cycle versions >' -Direction 'forward'
exit $LASTEXITCODE

