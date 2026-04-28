$ErrorActionPreference = 'Stop'
& 'D:\Dev\workspace\Codex\flowcell\Blender\FlowCellButtons\Invoke-BlenderFlowCellAction.ps1' -Action 'render_active_object_png_to_images' -Label 'save png'
exit $LASTEXITCODE

