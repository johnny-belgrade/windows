@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"
if errorlevel 1 (
  echo [R029 HOLD] Cannot enter selected UUP folder.
  exit /b 17
)
if not "%CD: =%"=="%CD%" (
  echo [R029 HOLD] Select an original UUP root without spaces.
  exit /b 17
)
if not exist "BlueLite_R029_Run.ps1" (
  echo [R029 HOLD] Extract BlueLite R029 ZIP directly into this SAME folder.
  exit /b 17
)
if not exist "uup_download_windows.cmd" (
  echo [R029 HOLD] Extract the original UUPdump *_convert.zip into this SAME folder.
  exit /b 17
)
where pwsh.exe >NUL 2>&1
if errorlevel 1 (
  echo [R029 HOLD] Install PowerShell 7.
  exit /b 17
)
fltmc.exe >NUL 2>&1
if errorlevel 1 (
  echo [R029 HOLD] Run this CMD as Administrator (Total Commander may remain OPEN).
  exit /b 17
)
echo ==========================================================
echo BlueLite R029 UUP PRE_MAX — ROOT-LOCAL ONE CMD
echo Folder: %CD%
echo Original vendor intact; no Explorer / Total Commander shutdown.
echo Logs and evidence: %CD%\BlueLite_Logs
echo Stage and images: %CD%\BlueLite_Work
echo ==========================================================
pwsh.exe -NoLogo -NoProfile -NonInteractive -File "%~dp0BlueLite_R029_Run.ps1" -Mode Build -SelectedRoot "%~dp0"
set "R029_EXIT=%ERRORLEVEL%"
echo.
echo ==========================================================
echo Result: %R029_EXIT%
echo Return EXACT file:
echo %CD%\BlueLite_Logs\BlueLite_R029_EVIDENCE.zip
echo If HOLD, do NOT rerun. Preserve logs and stage.
echo ==========================================================
exit /b %R029_EXIT%
