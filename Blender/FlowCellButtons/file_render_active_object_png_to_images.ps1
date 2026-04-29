$ErrorActionPreference = 'Stop'
$supportRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'SupportScripts'
$dispatcherPath = Join-Path $supportRoot 'Invoke-BlenderFlowCellAction.ps1'
& $dispatcherPath -Action 'render_active_object_png_to_images' -Label 'save png'
exit $LASTEXITCODE

