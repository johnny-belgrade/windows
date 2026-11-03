@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"
set "BL_BASE=%CD%"
set "BL_RET=99"

if not exist "uup_download_windows.cmd" (
 echo [BLUELITE HOLD] Original untouched UUP Dump launcher missing in this folder.
 goto :PACKAGE_HOLD
)
if not exist "BlueLite\BlueLite_UUP.cmd" (
 echo [BLUELITE HOLD] BlueLite engine missing beside START.cmd.
 goto :PACKAGE_HOLD
)
where pwsh.exe >NUL 2>&1
if errorlevel 1 (
 echo [BLUELITE HOLD] PowerShell 7 pwsh.exe is required in PATH.
 goto :PACKAGE_HOLD
)
fltmc.exe >NUL 2>&1
if errorlevel 1 (
 echo [BLUELITE HOLD] Run START.cmd as Administrator. No downloads started.
 goto :PACKAGE_HOLD
)

echo.
echo ===== BLUE LITE 26300 MAX_PRE - ORIGINAL VENDOR SOURCE =====
echo Root: "%BL_BASE%"
echo.

pwsh.exe -NoLogo -NoProfile -NonInteractive -File "BlueLite\BlueLite_RestoreEvidence.ps1" -UUPRoot "%BL_BASE%"
if errorlevel 1 goto :PACKAGE_HOLD

pwsh.exe -NoLogo -NoProfile -NonInteractive -File "BlueLite\BlueLite_Preflight.ps1" -UUPRoot "%BL_BASE%"
if errorlevel 1 goto :PACKAGE_HOLD

call "BlueLite\BlueLite_UUP.cmd"
set "BL_RET=%ERRORLEVEL%"
goto :PACK

:PACKAGE_HOLD
set "BL_RET=99"

:PACK
echo.
echo === Assembling ONE last-timestamp verified BlueLite evidence ZIP ===
pwsh.exe -NoLogo -NoProfile -NonInteractive -File "BlueLite\BlueLite_PackEvidence.ps1" -UUPRoot "%BL_BASE%" -EngineExitCode %BL_RET%
if errorlevel 1 (
 echo [BLUELITE HOLD] Evidence archive not verified. Original logs retained.
 exit /b 98
)
if "%BL_RET%"=="0" (
 echo [BLUELITE ENGINE EXIT 0] Native conversion process returned success.
 exit /b 0
)
echo [BLUELITE HOLD] Engine exit code %BL_RET%. See ONE BlueLite_EVIDENCE_timestamp.zip in this folder.
exit /b %BL_RET%
