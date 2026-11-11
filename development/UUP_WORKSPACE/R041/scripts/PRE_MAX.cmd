@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "BL_ROOT=%~dp0"
if "%BL_ROOT:~-1%"=="\" set "BL_ROOT=%BL_ROOT:~0,-1%"
set "BL_LOGS=%BL_ROOT%\BlueLite_Logs"
if not exist "%BL_LOGS%\" mkdir "%BL_LOGS%" >nul 2>&1
if not exist "%BL_LOGS%\" (
 echo [R041 HOLD] Cannot create BlueLite_Logs next to PRE_MAX.cmd.
 exit /b 17
)
set "BL_BOOT=%BL_LOGS%\BlueLite_R041_CMD_Bootstrap.log"
if exist "%BL_BOOT%" (
 echo [R041 HOLD] This cycle already has an early bootstrap log.
 echo [R041 HOLD] Preserve the cycle; do not blindly rerun. Use a new UUP cycle.
 exit /b 17
)
>"%BL_BOOT%" echo [%DATE% %TIME%] R041_CMD_STARTED ROOT="%BL_ROOT%"
>>"%BL_BOOT%" echo [%DATE% %TIME%] PRIMARY_LOGS="%BL_LOGS%"
>>"%BL_BOOT%" echo [%DATE% %TIME%] ORIGINAL_UUP_ZIP_AND_ALL_11_VENDOR_FILES_MUST_ALREADY_BE_EXTRACTED
set "BL_ARG="
if /i "%~1"=="--inspect" set "BL_ARG=--inspect"
if not "%~1"=="" if not defined BL_ARG (
 >>"%BL_BOOT%" echo [%DATE% %TIME%] HOLD_UNSUPPORTED_ARGUMENT
 goto :EARLY_HOLD
)
echo.
echo ============================================================
echo  BlueLite PRE_MAX R041 - ORIGINAL UUP MUST BE EXTRACTED
echo  Primary logs: "%BL_LOGS%"
echo  ONE original vendor convert ZIP plus its 11 extracted files
echo  NO vendor extraction is performed by this package.
echo ============================================================
echo.
set "BL_PS="
for /f "delims=" %%G in ('where pwsh.exe 2^>nul') do if not defined BL_PS set "BL_PS=%%G"
if not defined BL_PS if exist "%ProgramFiles%\PowerShell\7\pwsh.exe" set "BL_PS=%ProgramFiles%\PowerShell\7\pwsh.exe"
if defined BL_PS if exist "%BL_ROOT%\BlueLite_R031_Mirror.ps1" (
 >>"%BL_BOOT%" echo [%DATE% %TIME%] STARTUP_SHA_MIRROR_ATTEMPT
 "%BL_PS%" -NoLogo -NoProfile -NonInteractive -File "%BL_ROOT%\BlueLite_R031_Mirror.ps1" -CycleRoot "%BL_ROOT%"
 if errorlevel 1 (
  >>"%BL_BOOT%" echo [%DATE% %TIME%] HOLD_STARTUP_MIRROR_FAILED
  goto :EARLY_HOLD
 )
) else (
 >>"%BL_BOOT%" echo [%DATE% %TIME%] EARLY_MIRROR_NOT_RUN_MISSING_PWSH_OR_SOURCE
)
if not exist "%BL_ROOT%\BlueLite_R035_RUN.cmd" (
 >>"%BL_BOOT%" echo [%DATE% %TIME%] HOLD_R035_ENTRY_MISSING
 goto :EARLY_HOLD
)
if not exist "%BL_ROOT%\BlueLite_R031_Manifest.sha256" (
 >>"%BL_BOOT%" echo [%DATE% %TIME%] HOLD_ENGINE_MANIFEST_MISSING
 goto :EARLY_HOLD
)
>>"%BL_BOOT%" echo [%DATE% %TIME%] DELEGATE_SHA_SEALED_R035_ENGINE mode=%BL_ARG%
call "%BL_ROOT%\BlueLite_R035_RUN.cmd" %BL_ARG%
set "BL_RC=%ERRORLEVEL%"
echo.
echo [R041] Native engine exit: %BL_RC%
echo [R041] Logs: "%BL_LOGS%"
echo [R041] Return ONE evidence ZIP:
echo [R041] "%BL_LOGS%\BlueLite_R035_EVIDENCE.zip"
exit /b %BL_RC%
:EARLY_HOLD
>>"%BL_BOOT%" echo [%DATE% %TIME%] R041_EARLY_HOLD_NO_ENGINE_RUN
if not exist "%BL_LOGS%\UUP_post-debloat_info.txt" (
 >"%BL_LOGS%\UUP_post-debloat_info.txt" echo BlueLite PRE_MAX R041 FINAL EARLY-HOLD REPORT
 >>"%BL_LOGS%\UUP_post-debloat_info.txt" echo NATIVE_EXIT=NOT_RUN
 >>"%BL_LOGS%\UUP_post-debloat_info.txt" echo BUILD=NOT_RUN
 >>"%BL_LOGS%\UUP_post-debloat_info.txt" echo WIM_ISO=NOT_RUN
 >>"%BL_LOGS%\UUP_post-debloat_info.txt" echo REASON=SEE_BLUE_LITE_R041_CMD_BOOTSTRAP_LOG
)
if defined BL_PS if exist "%BL_ROOT%\BlueLite_R031_Mirror.ps1" (
 "%BL_PS%" -NoLogo -NoProfile -NonInteractive -File "%BL_ROOT%\BlueLite_R031_Mirror.ps1" -CycleRoot "%BL_ROOT%"
)
echo [R041 HOLD] Exact bootstrap log: "%BL_BOOT%"
echo [R041 HOLD] Exact final report: "%BL_LOGS%\UUP_post-debloat_info.txt"
exit /b 17
