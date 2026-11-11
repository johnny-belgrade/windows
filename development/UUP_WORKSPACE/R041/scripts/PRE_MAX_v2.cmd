@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "BL_ROOT=%~dp0"
if "%BL_ROOT:~-1%"=="\" set "BL_ROOT=%BL_ROOT:~0,-1%"
set "BL_LOGS=%BL_ROOT%\BlueLite_Logs"
if not exist "%BL_LOGS%\" mkdir "%BL_LOGS%" >nul 2>&1
if not exist "%BL_LOGS%\" (
 echo [R041 HOLD] Cannot create BlueLite_Logs in the selected UUP root.
 exit /b 17
)
set "BL_BOOT=%BL_LOGS%\BlueLite_R041_CMD_Bootstrap.log"
if exist "%BL_BOOT%" (
 echo [R041 HOLD] Previous cycle log exists. DO NOT blindly rerun or overwrite.
 echo [R041 HOLD] Preserve BlueLite_Logs and create a fresh UUP cycle.
 exit /b 17
)
>"%BL_BOOT%" echo [%DATE% %TIME%] R041_CMD_STARTED ROOT="%BL_ROOT%"
>>"%BL_BOOT%" echo [%DATE% %TIME%] PRIMARY_LOGS="%BL_LOGS%"
>>"%BL_BOOT%" echo [%DATE% %TIME%] GENUINE_ORIGINAL_UUP_ZIP_AND_ALL_11_VENDOR_FILES_ALREADY_EXTRACTED_REQUIRED
set "BL_ARG="
if /i "%~1"=="--inspect" set "BL_ARG=--inspect"
if not "%~1"=="" if not defined BL_ARG (
 >>"%BL_BOOT%" echo [%DATE% %TIME%] HOLD_UNSUPPORTED_ARGUMENT
 goto :EARLY_HOLD
)
echo.
echo ============================================================
echo  BlueLite PRE_MAX R041 - EXTRACT ORIGINAL UUP AND BlueLite
echo  Source: one untouched original UUP ZIP + all 11 files
echo  Logs: "%BL_LOGS%"
echo  Original source is NEVER auto-extracted or overwritten.
echo ============================================================
echo.
set "BL_PS="
for /f "delims=" %%G in ('where pwsh.exe 2^>nul') do if not defined BL_PS set "BL_PS=%%G"
if not defined BL_PS if exist "%ProgramFiles%\PowerShell\7\pwsh.exe" set "BL_PS=%ProgramFiles%\PowerShell\7\pwsh.exe"
if defined BL_PS (
 if not exist "%BL_ROOT%\BlueLite_R031_Mirror.ps1" (
  >>"%BL_BOOT%" echo [%DATE% %TIME%] HOLD_EARLY_MIRROR_MODULE_MISSING
  goto :EARLY_HOLD
 )
 >>"%BL_BOOT%" echo [%DATE% %TIME%] STARTUP_SHA_MIRROR_ATTEMPT
 "%BL_PS%" -NoLogo -NoProfile -NonInteractive -File "%BL_ROOT%\BlueLite_R031_Mirror.ps1" -CycleRoot "%BL_ROOT%"
 if errorlevel 1 (
  >>"%BL_BOOT%" echo [%DATE% %TIME%] HOLD_STARTUP_SHA_MIRROR_FAILED
  goto :EARLY_HOLD
 )
) else (
 >>"%BL_BOOT%" echo [%DATE% %TIME%] EARLY_MIRROR_NOT_RUN_NO_POWERSHELL7
)
if not exist "%BL_ROOT%\BlueLite_R035_RUN.cmd" (
 >>"%BL_BOOT%" echo [%DATE% %TIME%] HOLD_NATIVE_R035_CMD_MISSING
 goto :EARLY_HOLD
)
if not exist "%BL_ROOT%\BlueLite_R031_Manifest.sha256" (
 >>"%BL_BOOT%" echo [%DATE% %TIME%] HOLD_SOURCE_SHA_MANIFEST_MISSING
 goto :EARLY_HOLD
)
if not exist "%BL_ROOT%\BlueLite_R041_FinalEvidence.ps1" (
 >>"%BL_BOOT%" echo [%DATE% %TIME%] HOLD_R041_FINAL_EVIDENCE_MODULE_MISSING
 goto :EARLY_HOLD
)
>>"%BL_BOOT%" echo [%DATE% %TIME%] NATIVE_ENGINE_DELEGATE_START MODE=%BL_ARG%
rem R035's own last PAUSE is deferred until after R041 final evidence and SHA mirror.
set "BLUELITE_R035_QA_NO_PAUSE=1"
call "%BL_ROOT%\BlueLite_R035_RUN.cmd" %BL_ARG%
set "BL_RC=%ERRORLEVEL%"
set "BL_FINAL=NOT_RUN"
if defined BL_PS (
 echo [R041] Final archive from CLOSED native logs...
 "%BL_PS%" -NoLogo -NoProfile -NonInteractive -File "%BL_ROOT%\BlueLite_R041_FinalEvidence.ps1" -Mode Pack -CycleRoot "%BL_ROOT%" -NativeExit %BL_RC%
 if errorlevel 1 (
  set "BL_FINAL=PACK_HOLD"
  echo [R041 WARN] Final evidence Pack HOLD; native result is preserved.
 ) else (
  "%BL_PS%" -NoLogo -NoProfile -NonInteractive -File "%BL_ROOT%\BlueLite_R041_FinalEvidence.ps1" -Mode Verify -CycleRoot "%BL_ROOT%"
  if errorlevel 1 (
   set "BL_FINAL=VERIFY_HOLD"
   echo [R041 WARN] Final evidence independent Verify HOLD.
  ) else (
   set "BL_FINAL=INDEPENDENT_EVIDENCE_PASS"
  )
 )
 echo [R041] Final SHA history mirror after all native CMD and evidence logs closed...
 "%BL_PS%" -NoLogo -NoProfile -NonInteractive -File "%BL_ROOT%\BlueLite_R031_Mirror.ps1" -CycleRoot "%BL_ROOT%"
 if errorlevel 1 (
  set "BL_FINAL=HISTORY_MIRROR_HOLD"
  echo [R041 WARN] Final history mirror HOLD; native exit preserved.
 )
)
echo.
echo ============================================================
echo  R041 NATIVE EXIT: %BL_RC%
echo  R041 FINAL EVIDENCE: %BL_FINAL%
echo  PRIMARY LOGS: "%BL_LOGS%"
echo  FINAL INFO: "%BL_LOGS%\UUP_post-debloat_info.txt"
echo  SEND EVIDENCE: "%BL_LOGS%\BlueLite_R041_EVIDENCE.zip"
echo ============================================================
if /i not "%BLUELITE_R041_QA_NO_PAUSE%"=="1" pause
exit /b %BL_RC%
:EARLY_HOLD
>>"%BL_BOOT%" echo [%DATE% %TIME%] FINAL_EARLY_HOLD_NATIVE_NOT_RUN
if not exist "%BL_LOGS%\UUP_post-debloat_info.txt" (
 >"%BL_LOGS%\UUP_post-debloat_info.txt" echo R041 FINAL EARLY-HOLD REPORT
 >>"%BL_LOGS%\UUP_post-debloat_info.txt" echo BUILD_AND_IMAGE=NOT_RUN
 >>"%BL_LOGS%\UUP_post-debloat_info.txt" echo REASON=SEE_BlueLite_R041_CMD_Bootstrap.log
)
if defined BL_PS if exist "%BL_ROOT%\BlueLite_R031_Mirror.ps1" (
 "%BL_PS%" -NoLogo -NoProfile -NonInteractive -File "%BL_ROOT%\BlueLite_R031_Mirror.ps1" -CycleRoot "%BL_ROOT%"
)
echo [R041 HOLD] PRIMARY LOGS: "%BL_LOGS%"
if /i not "%BLUELITE_R041_QA_NO_PAUSE%"=="1" pause
exit /b 17
