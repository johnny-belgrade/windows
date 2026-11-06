@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0"
if not "%CD: =%"=="%CD%" (
 echo [HOLD] BlueLite UUP folder path must not contain spaces.
 exit /b 17
)
if not exist "BlueLite_R027_Resume.ps1" (
 echo [HOLD] R027 Resume controller missing from this folder.
 exit /b 17
)
if not exist "BlueLite_R027_CaptureImages.ps1" (
 echo [HOLD] R027 WIM capture helper missing from this folder.
 exit /b 17
)
where pwsh.exe >NUL 2>&1
if errorlevel 1 (
 echo [HOLD] PowerShell 7 required.
 exit /b 17
)
fltmc.exe >NUL 2>&1
if errorlevel 1 (
 echo [HOLD] Launch this CMD as Administrator.
 exit /b 17
)
echo.
echo === BlueLite R027 SOURCE-BOUND V11.3 SAME-STAGE CONVERTER RESUME ===
echo No aria2 redownload, no original UUP vendor changes, no deletion.
echo.
pwsh.exe -NoLogo -NoProfile -NonInteractive -File "%~dp0BlueLite_R027_Resume.ps1" -Mode Build
set "RC=%ERRORLEVEL%"
echo.
echo Return newest BlueLite_Logs\BlueLite_R027_*_EVIDENCE.zip
echo Original UUP files and stage remain unchanged on HOLD.
exit /b %RC%
