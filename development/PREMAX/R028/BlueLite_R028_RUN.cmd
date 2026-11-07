@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"
if not "%CD: =%"=="%CD%" (
 echo [R028 HOLD] Selected UUP path contains spaces.
 exit /b 17
)
if not exist "uup_download_windows.cmd" (
 echo [R028 HOLD] Extract original UUP Dump vendor ZIP into this same folder.
 exit /b 17
)
if not exist "BlueLite_R028_Run.ps1" (
 echo [R028 HOLD] Extract full BlueLite R028 ZIP DIRECTLY into the same folder.
 exit /b 17
)
where pwsh.exe >NUL 2>&1
if errorlevel 1 (
 echo [R028 HOLD] PowerShell 7 is required.
 exit /b 17
)
fltmc.exe >NUL 2>&1
if errorlevel 1 (
 echo [R028 HOLD] Right-click this CMD and choose Run as Administrator.
 exit /b 17
)
echo ==========================================================
echo BlueLite R028 universal UUP MAX_PRE
echo Folder: %CD%
echo One invocation: reuse verified stage OR genuine full UUP source
echo ==========================================================
pwsh.exe -NoLogo -NoProfile -NonInteractive -File "%~dp0BlueLite_R028_Run.ps1" -Mode Build
set "BL_EXIT=%ERRORLEVEL%"
echo.
echo [R028] Return newest BlueLite_Logs\BlueLite_R028_*_EVIDENCE.zip
echo [R028] Exit: %BL_EXIT%
exit /b %BL_EXIT%
