@echo off
setlocal EnableExtensions DisableDelayedExpansion
title BlueLite v1.0 PRE_MAX R040 - 26300.x Universal DRAFT
set "BL_ROOT=%~dp0"
cd /d "%BL_ROOT%"
if errorlevel 1 (
 echo [R040 HOLD] Cannot open the selected directory.
 exit /b 17
)
if not exist "%BL_ROOT%BlueLite_R040_SourcePrepare.ps1" (
 echo [R040 HOLD] Extract the BlueLite PRE_MAX ZIP directly into the folder containing ONE untouched original UUP Dump *_convert.zip.
 exit /b 17
)
if not exist "%BL_ROOT%BlueLite_BUILD.cmd" (
 echo [R040 HOLD] R035-backed native UUP engine is missing.
 exit /b 17
)
where pwsh.exe >nul 2>&1
if errorlevel 1 (
 echo [R040 HOLD] PowerShell 7 pwsh.exe is required.
 exit /b 17
)
fltmc.exe >nul 2>&1
if errorlevel 1 (
 echo [R040 HOLD] Run PRE_MAX.cmd as Administrator.
 exit /b 17
)
echo.
echo ==================================================================
echo   BlueLite v1.0 PRE_MAX R040
echo   One untouched 26300.x amd64/en-us/Professional UUP Dump ZIP
echo   Source-anchored factory: untouched vendor, v128m bootstrap,
echo   five staging apps / dependency closure, SkipWinRE=1, Setup kept.
echo   Logs: C:\work\logs and BlueLite_Logs in this folder.
echo ==================================================================
echo.
echo [R040 1/3] Verify and prepare only missing original vendor ZIP members...
pwsh.exe -NoProfile -NonInteractive -File "%BL_ROOT%BlueLite_R040_SourcePrepare.ps1" -Mode Prepare -PackageRoot "%BL_ROOT%"
if errorlevel 1 goto :HOLD
echo [R040 2/3] Independent fresh-process SHA verification of original source...
pwsh.exe -NoProfile -NonInteractive -File "%BL_ROOT%BlueLite_R040_SourcePrepare.ps1" -Mode Verify -PackageRoot "%BL_ROOT%"
if errorlevel 1 goto :HOLD
echo [R040 3/3] Start previously native-executed source-bound PRE_MAX factory.
echo [R040] New owned BlueLite_Work stage only. Full download and build are enabled.
call "%BL_ROOT%BlueLite_BUILD.cmd"
set "BL_RESULT=%ERRORLEVEL%"
echo.
echo [R040] Native runner exit: %BL_RESULT%
echo [R040] Evidence: "%BL_ROOT%BlueLite_Logs"
echo [R040] Original untouched UUP ZIP remains in "%BL_ROOT%"
exit /b %BL_RESULT%
:HOLD
echo.
echo [R040 HOLD] Source verification or preparation failed. No factory build started.
echo [R040 HOLD] Inspect C:\work\logs and preserve all original ZIP files.
exit /b 17
