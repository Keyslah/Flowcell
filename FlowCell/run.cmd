:: Description: Runs run.
@echo off
setlocal

set "ROOT=%~dp0"
set "UI_SCRIPT=%ROOT%FlowCellUI.ps1"
set "RESTORE_SCRIPT=%ROOT%helpers\Restore-FlowCellWindow.ps1"
set "LOG_DIR=%ROOT%local\logs"
set "LAUNCH_LOG=%LOG_DIR%\launcher.log"
set "UI_LAUNCH_LOG=%LOG_DIR%\ui-launcher.log"
set "BACKEND_LAUNCH_LOG=%LOG_DIR%\backend-launcher.log"
set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "AHK_EXE="

if exist "%ROOT%runtime\AutoHotkey64.exe" set "AHK_EXE=%ROOT%runtime\AutoHotkey64.exe"
if not defined AHK_EXE if exist "%ROOT%runtime\AutoHotkey.exe" set "AHK_EXE=%ROOT%runtime\AutoHotkey.exe"
if not defined AHK_EXE if exist "%ROOT%local\bin\AutoHotkey64.exe" set "AHK_EXE=%ROOT%local\bin\AutoHotkey64.exe"
if not defined AHK_EXE if exist "%ROOT%local\bin\AutoHotkey.exe" set "AHK_EXE=%ROOT%local\bin\AutoHotkey.exe"
if not defined AHK_EXE if exist "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" set "AHK_EXE=C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
if not defined AHK_EXE if exist "C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" set "AHK_EXE=C:\Program Files\AutoHotkey\v2\AutoHotkey.exe"

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
if exist "%RESTORE_SCRIPT%" (
    "%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%RESTORE_SCRIPT%" >nul 2>&1
    if "%ERRORLEVEL%"=="0" exit /b 0
)

pushd "%ROOT%"
"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -STA -File "%UI_SCRIPT%" 1>>"%UI_LAUNCH_LOG%" 2>&1
set "EXIT_CODE=%ERRORLEVEL%"
popd

exit /b %EXIT_CODE%

:launch_backend
if not defined AHK_EXE (
    echo AutoHotkey v2 was not found.
    echo Expected a bundled runtime in one of:
    echo   %ROOT%runtime\AutoHotkey64.exe
    echo   %ROOT%runtime\AutoHotkey.exe
    echo   %ROOT%local\bin\AutoHotkey64.exe
    echo   %ROOT%local\bin\AutoHotkey.exe
    echo Or a system install in:
    echo   C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe
    echo   C:\Program Files\AutoHotkey\v2\AutoHotkey.exe
    echo.
    echo Release ZIPs should include AutoHotkey v2 under FlowCell\runtime.
    pause
    exit /b 1
)

pushd "%ROOT%"
"%AHK_EXE%" /ErrorStdOut "%ROOT%FlowCellBackend.ahk" %* 1>"%BACKEND_LAUNCH_LOG%" 2>&1
set "EXIT_CODE=%ERRORLEVEL%"
popd

exit /b %EXIT_CODE%
