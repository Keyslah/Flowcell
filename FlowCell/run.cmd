@echo off
setlocal

set "ROOT=%~dp0"
set "UI_SCRIPT=%ROOT%FlowCellUI.ps1"
set "AHK_EXE=C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
set "LOG_DIR=%ROOT%local\logs"
set "LAUNCH_LOG=%LOG_DIR%\launcher.log"
set "UI_LAUNCH_LOG=%LOG_DIR%\ui-launcher.log"
set "BACKEND_LAUNCH_LOG=%LOG_DIR%\backend-launcher.log"
set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"

if not exist "%AHK_EXE%" set "AHK_EXE=C:\Program Files\AutoHotkey\v2\AutoHotkey.exe"

if not exist "%PS_EXE%" (
    echo Windows PowerShell was not found in the default install path.
    exit /b 1
)

if not exist "%UI_SCRIPT%" (
    echo FlowCell UI script was not found:
    echo   %UI_SCRIPT%
    pause
    exit /b 1
)

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

if "%~1"=="" goto launch_ui
goto launch_backend

:launch_ui
pushd "%ROOT%"
"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -STA -File "%UI_SCRIPT%" 1>>"%UI_LAUNCH_LOG%" 2>&1
set "EXIT_CODE=%ERRORLEVEL%"
popd

exit /b %EXIT_CODE%

:launch_backend
if not exist "%AHK_EXE%" (
    echo AutoHotkey v2 was not found in the default install path.
    echo Expected one of:
    echo   C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe
    echo   C:\Program Files\AutoHotkey\v2\AutoHotkey.exe
    pause
    exit /b 1
)

pushd "%ROOT%"
"%AHK_EXE%" /ErrorStdOut "%ROOT%FlowCellBackend.ahk" %* 1>"%BACKEND_LAUNCH_LOG%" 2>&1
set "EXIT_CODE=%ERRORLEVEL%"
popd

exit /b %EXIT_CODE%
