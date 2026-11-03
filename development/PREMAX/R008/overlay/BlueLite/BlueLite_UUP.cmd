@echo off
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0.."

if NOT "%cd%"=="%cd: =%" (
    echo [ERROR] Working path contains spaces. Use a short folder without spaces.
    rem Noninteractive: START.cmd collects evidence and exits.
    exit /b 1
)

if "[%1]"=="[49127c4b-02dc-482e-ac4f-ec4d659b7547]" goto :START_PROCESS
REG QUERY HKU\S-1-5-19\Environment >NUL 2>&1 && goto :START_PROCESS
set "command="""%~f0""" 49127c4b-02dc-482e-ac4f-ec4d659b7547"
setlocal EnableDelayedExpansion
set "command=!command:'=''!"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%COMSPEC%' -ArgumentList '/c """!command!"""' -Verb RunAs" 2>NUL
endlocal
exit /b

:START_PROCESS
setlocal EnableExtensions DisableDelayedExpansion
cd /d "%~dp0.."

if not exist "BlueLite_Logs" mkdir "BlueLite_Logs"
set "BL=BlueLite"
set "LOG=BlueLite_Logs"
set "aria2=files\aria2c.exe"
set "convReady=files\converter_ready"
set "appsScript=files\aria2_apps.%RANDOM%.txt"
set "uupScript=files\aria2_uup.%RANDOM%.txt"
set "ariaLog=%LOG%\aria2_download.log"

:: The untouched UUP Dump archive is the target authority.
for %%F in (
  "uup_download_windows.cmd"
  "files\get_aria2.ps1"
  "files\converter_windows"
  "files\converter_multi"
) do if not exist "%%~F" (
  echo [ERROR] Missing ORIGINAL UUP Dump file: %%~F
  goto :FAIL
)

:: Preserve original UUP-selected conversion/app metadata before BlueLite stages overwrite root files.
if not exist "%LOG%\OriginalUUP_ConvertConfig.ini" (
  if not exist "ConvertConfig.ini" (
    echo [ERROR] Original UUP ConvertConfig.ini is missing.
    goto :FAIL
  )
  copy /y "ConvertConfig.ini" "%LOG%\OriginalUUP_ConvertConfig.ini" >NUL || goto :FAIL
)
if not exist "%LOG%\OriginalUUP_CustomAppsList.txt" (
  if not exist "CustomAppsList.txt" (
    echo [ERROR] Original UUP CustomAppsList.txt is missing.
    goto :FAIL
  )
  copy /y "CustomAppsList.txt" "%LOG%\OriginalUUP_CustomAppsList.txt" >NUL || goto :FAIL
)
if not exist "%LOG%\OriginalUUP_uup_download_windows.cmd" copy /y "uup_download_windows.cmd" "%LOG%\OriginalUUP_uup_download_windows.cmd" >NUL

for %%F in (
  "%BL%\BlueLite_Profile.ini"
  "%BL%\ConvertConfig.ini"
  "%BL%\BlueLite_ResolveUUP.ps1"
  "%BL%\BlueLite_Bootstrap.ps1"
  "%BL%\BlueLite_GenerateCustomAppsList.ps1"
  "%BL%\BlueLite_FilterApps.ps1"
  "%BL%\BlueLite_ResolveAppDependencies.ps1"
  "%BL%\BlueLite_VerifySource.ps1"
  "%BL%\BlueLite_PatchConverter.ps1"
  "%BL%\BlueLite_PreDebloatWim.ps1"
  "%BL%\BlueLite_RequiredStagingApps.txt"
  "%BL%\BlueLite_RequiredFinalApps.txt"
  "%BL%\BlueLite_StagingOnlyAppPatterns.txt"
  "%BL%\BlueLite_ReleaseForbiddenAppPatterns.txt"
  "%BL%\BlueLite_OfflineHandoffPatterns.txt"
  "%BL%\BlueLite_AppAllowPatterns.txt"
  "%BL%\BlueLite_AppAlwaysKeepPatterns.txt"
  "%BL%\BlueLite_CapabilityRemovePatterns.txt"
  "%BL%\BlueLite_FeatureDisableOnly.txt"
  "%BL%\BlueLite_FeatureRemovePayload.txt"
  "%BL%\BlueLite_PackageRemovePatterns.txt"
  "%BL%\BlueLite_ComponentWatchlist.txt"
  "%BL%\BlueLite_ProtectedFloor.txt"
) do if not exist "%%~F" (
  echo [ERROR] Missing BlueLite file: %%~F
  goto :FAIL
)

:: Resolve/validate EXACTLY the UUID and URLs embedded by UUP Dump in the original launcher.
echo.
echo === Reading target from ORIGINAL UUP Dump archive . . .
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BL%\BlueLite_ResolveUUP.ps1" -OriginalLauncherPath ".\uup_download_windows.cmd" -OriginalConfigPath ".\%LOG%\OriginalUUP_ConvertConfig.ini" -EnvOutputPath ".\%LOG%\ResolvedUUP.env.cmd" -JsonOutputPath ".\%LOG%\ResolvedUUP.json" -ExistingCheckpointPath ".\%LOG%\ResolvedUUP.json"
if errorlevel 1 goto :FAIL
call ".\%LOG%\ResolvedUUP.env.cmd"
if not defined UUP_ID goto :FAIL
if not defined UUP_BUILD goto :FAIL
if not defined UUP_WINDOWS_URL goto :FAIL
if not defined UUP_APPS_URL goto :FAIL
if /i not "%UUP_PACK%"=="en-us" goto :FAIL
if /i not "%UUP_EDITION%"=="professional" goto :FAIL
if /i not "%UUP_ARCH%"=="amd64" goto :FAIL

title BlueLite v1.0 MAX_PRE 26300 Universal v6.1 %UUP_BUILD%
echo [INFO] ORIGINAL UUP target: %UUP_BUILD% / %UUP_ID%
echo [INFO] amd64 / en-us / professional / install.wim / NetFx3 OFF

set "BL_RESUME=0"
set "BL_RESUME_APP_CLOSURE=0"
if exist "UUPs\" (
    dir /b "UUPs" 2>NUL | findstr . >NUL
    if not errorlevel 1 (
        if exist ".\%LOG%\AppsQueue.filtered.txt" if exist ".\%LOG%\AppsQueue.original.txt" if exist ".\convert-UUP.cmd" if not exist ".\%LOG%\ConvertStart.marker" (
            if exist ".\%LOG%\WindowsQueue.original.txt" (
                set "BL_RESUME=1"
            ) else (
                set "BL_RESUME_APP_CLOSURE=1"
            )
        ) else (
            echo [ERROR] Non-empty UUPs is not a verified pre-conversion checkpoint for this original UUP archive.
            goto :FAIL
        )
    )
) else mkdir "UUPs"
if exist "ISOFOLDER\" (
    echo [ERROR] ISOFOLDER already exists. Use a fresh working folder or clean the failed conversion first.
    goto :FAIL
)
if "%BL_RESUME%"=="1" goto :RESUME_DOWNLOADED_SOURCE
if "%BL_RESUME_APP_CLOSURE%"=="1" goto :RESUME_APP_CLOSURE

:: Original UUP bootstrap/converter manifests only. No BlueLite build discovery and no converter-list refresh.
echo.
echo === Bootstrapping converter from ORIGINAL UUP files\ manifests . . .
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BL%\BlueLite_Bootstrap.ps1" -FilesDirectory ".\files" -PreparedConverterDirectory ".\files\converter_ready" -LogPath ".\%LOG%\Bootstrap.log" -AriaLogPath ".\%ariaLog%"
if errorlevel 1 goto :FAIL
if not exist "%aria2%" goto :FAIL
if not exist "%convReady%\convert-UUP.cmd" goto :FAIL

if exist "bin\" rmdir /s /q "bin" >NUL 2>&1
for %%F in (convert-UUP.cmd create_virtual_editions.cmd ConvertConfig.ini CustomAppsList.txt ReadMe.html README.md) do if exist "%%F" del /f /q "%%F" >NUL 2>&1
echo Staging converter pinned by original UUP archive...
xcopy "%convReady%\*" ".\" /E /I /H /Y >NUL
if errorlevel 2 goto :FAIL
if not exist "convert-UUP.cmd" goto :FAIL
if not exist "bin\wimlib-imagex.exe" goto :FAIL
copy /y "%BL%\ConvertConfig.ini" ".\ConvertConfig.ini" >NUL || goto :FAIL

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BL%\BlueLite_GenerateCustomAppsList.ps1" -TemplatePath ".\%LOG%\OriginalUUP_CustomAppsList.txt" -AllowPatternsFile "%BL%\BlueLite_AppAllowPatterns.txt" -RequiredAppIdentitiesFile "%BL%\BlueLite_RequiredStagingApps.txt" -OutputPath ".\CustomAppsList.txt" -LogPath ".\%LOG%\GenerateCustomAppsList.log"
if errorlevel 1 goto :FAIL

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BL%\BlueLite_PatchConverter.ps1" -ConverterPath ".\convert-UUP.cmd" -ConfigPath ".\ConvertConfig.ini" -LogPath ".\%LOG%\PatchConverter.log"
if errorlevel 1 goto :FAIL

:: Apps queue: MAX_PRE v2.0: minimal top-level seed + dynamic manifest dependency closure.
:: Keep five staging apps plus converter metadata; exact frameworks/runtimes are added only when manifests require them.
:: DesktopAppInstaller is staging-only and is removed from the final offline WIM.
echo.
echo === Retrieving Apps queue for EXACT original UUP UUID . . .
"%aria2%" --no-conf --async-dns=false --console-log-level=warn --log-level=info --log="%ariaLog%" -o"%appsScript%" --allow-overwrite=true --auto-file-renaming=false "%UUP_APPS_URL%"
if errorlevel 1 goto :DOWNLOAD_ERROR
call :CHECK_UUPDUMP_ERROR "%appsScript%"
if errorlevel 1 goto :FAIL
copy /y "%appsScript%" ".\%LOG%\AppsQueue.original.txt" >NUL

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BL%\BlueLite_FilterApps.ps1" -Aria2File "%appsScript%" -AppAllowPatternsFile "%BL%\BlueLite_AppAllowPatterns.txt" -AlwaysKeepPatternsFile "%BL%\BlueLite_AppAlwaysKeepPatterns.txt" -RequiredAppIdentitiesFile "%BL%\BlueLite_RequiredStagingApps.txt" -Language "%UUP_PACK%" -Architecture "%UUP_ARCH%" -LogPath ".\%LOG%\FilterApps.log"
if errorlevel 1 goto :FAIL
copy /y "%appsScript%" ".\%LOG%\AppsQueue.filtered.txt" >NUL

echo Downloading minimal retained Apps seed + converter metadata...
"%aria2%" --no-conf --async-dns=false --console-log-level=warn --log-level=info --log="%ariaLog%" -x16 -s16 -j12 -c -R -d"UUPs" -i"%appsScript%"
if errorlevel 1 (
    echo [INFO] Apps transfer failed. Refresh only signed URLs if original UUID/out/SHA1 is unchanged.
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BL%\BlueLite_RenewQueue.ps1" -Mode Apps -Url "%UUP_APPS_URL%" -ActiveQueueFile "%appsScript%" -OriginalQueueFile ".\%LOG%\AppsQueue.original.txt" -FrozenQueueFile ".\%LOG%\AppsQueue.frozen.txt" -LogPath ".\%LOG%\RenewApps.log"
    if errorlevel 1 goto :DOWNLOAD_ERROR
    "%aria2%" --no-conf --async-dns=false --console-log-level=warn --log-level=info --log="%ariaLog%" -x16 -s16 -j12 -c -R -d"UUPs" -i"%appsScript%"
    if errorlevel 1 goto :DOWNLOAD_ERROR
)

goto :APP_DEP_CLOSURE

:RESUME_APP_CLOSURE
echo.
echo === Resuming after pre-conversion Apps dependency-stage interruption . . .
set "appsScript=.\%LOG%\AppsQueue.filtered.txt"
if not exist "%aria2%" (
    echo [ERROR] aria2c.exe is missing from the verified Apps checkpoint.
    goto :FAIL
)
if not exist ".\convert-UUP.cmd" (
    echo [ERROR] Patched converter is missing from the verified Apps checkpoint.
    goto :FAIL
)

:APP_DEP_CLOSURE
echo.
echo === Resolving exact AppX/MSIX dependency closure from downloaded manifests . . .
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BL%\BlueLite_ResolveAppDependencies.ps1" -OriginalQueueFile ".\%LOG%\AppsQueue.original.txt" -ActiveQueueFile "%appsScript%" -UUPDirectory ".\UUPs" -Aria2Path "%aria2%" -Architecture "%UUP_ARCH%" -Language "%UUP_PACK%" -OriginalAppsUrl "%UUP_APPS_URL%" -FrozenAppsQueueFile ".\%LOG%\AppsQueue.frozen.txt" -AriaLogPath ".\%ariaLog%" -LogPath ".\%LOG%\ResolveAppDependencies.log"
if errorlevel 1 goto :FAIL
copy /y "%appsScript%" ".\%LOG%\AppsQueue.filtered.txt" >NUL

:: Windows source queue remains byte-for-byte intact for delta/reference reconstruction.
echo.
echo === Retrieving complete Windows queue from EXACT original UUP URL . . .
"%aria2%" --no-conf --async-dns=false --console-log-level=warn --log-level=info --log="%ariaLog%" -o"%uupScript%" --allow-overwrite=true --auto-file-renaming=false "%UUP_WINDOWS_URL%"
if errorlevel 1 goto :DOWNLOAD_ERROR
call :CHECK_UUPDUMP_ERROR "%uupScript%"
if errorlevel 1 goto :FAIL
copy /y "%uupScript%" ".\%LOG%\WindowsQueue.original.txt" >NUL

echo === Source triad / original Windows D4 identity gate ===
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BL%\BlueLite_SourceTriadGate.ps1" -UUPRoot "." -WindowsQueueFile "%uupScript%" -LogPath ".\%LOG%\SourceTriad.log"
if errorlevel 1 goto :FAIL

echo === Frozen D4 FoD/AppX precut decision and reconstruction-keep ledger ===
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BL%\BlueLite_SourcePrecutDecision.ps1" -UUPRoot "." -WindowsQueueFile "%uupScript%" -AppsQueueFile "%appsScript%" -SourceTriadLog ".\%LOG%\SourceTriad.log" -LogPath ".\%LOG%\SourcePrecutDecision.json"
if errorlevel 1 goto :FAIL
echo Downloading complete Windows reference/delta source...
"%aria2%" --no-conf --async-dns=false --console-log-level=warn --log-level=info --log="%ariaLog%" -x16 -s16 -j5 -c -R -d"UUPs" -i"%uupScript%"
if errorlevel 1 (
    echo [INFO] Windows transfer failed. Refresh only signed URLs if original UUID/out/SHA1 is unchanged.
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BL%\BlueLite_RenewQueue.ps1" -Mode Windows -Url "%UUP_WINDOWS_URL%" -ActiveQueueFile "%uupScript%" -OriginalQueueFile ".\%LOG%\WindowsQueue.original.txt" -FrozenQueueFile ".\%LOG%\WindowsQueue.frozen.txt" -LogPath ".\%LOG%\RenewWindows.log"
    if errorlevel 1 goto :DOWNLOAD_ERROR
    "%aria2%" --no-conf --async-dns=false --console-log-level=warn --log-level=info --log="%ariaLog%" -x16 -s16 -j5 -c -R -d"UUPs" -i"%uupScript%"
    if errorlevel 1 goto :DOWNLOAD_ERROR
)
goto :VERIFY_AND_CONVERT

:RESUME_DOWNLOADED_SOURCE
echo.
echo === Resuming verified checkpoint for original UUP %UUP_BUILD% . . .
set "appsScript=.\%LOG%\AppsQueue.filtered.txt"
set "uupScript=.\%LOG%\WindowsQueue.original.txt"

:VERIFY_AND_CONVERT
echo.
echo === Verifying source closure . . .
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BL%\BlueLite_VerifySource.ps1" -UUPDirectory ".\UUPs" -AppsQueueFile "%appsScript%" -AppsQueueOriginalFile ".\%LOG%\AppsQueue.original.txt" -WindowsQueueFile "%uupScript%" -WindowsQueueOriginalFile ".\%LOG%\WindowsQueue.original.txt" -ExpectedBuild "%UUP_BUILD%" -RequiredAppIdentitiesFile "%BL%\BlueLite_RequiredStagingApps.txt" -LogPath ".\%LOG%\VerifySource.log"
if errorlevel 1 goto :FAIL

echo === Verifying mandatory operator triad against frozen D4 identity ===
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BL%\BlueLite_SourceTriadGate.ps1" -UUPRoot "." -WindowsQueueFile "%uupScript%" -LogPath ".\%LOG%\SourceTriad.log"
if errorlevel 1 goto :FAIL

echo === Refreshing source-bound reconstruction ledger, including resume ===
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BL%\BlueLite_SourcePrecutDecision.ps1" -UUPRoot "." -WindowsQueueFile "%uupScript%" -AppsQueueFile "%appsScript%" -SourceTriadLog ".\%LOG%\SourceTriad.log" -LogPath ".\%LOG%\SourcePrecutDecision.json"
if errorlevel 1 goto :FAIL

echo === Verifying SHA-1 bytes of all queued Windows and AppX payloads ===
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BL%\BlueLite_VerifyDownloadedHashes.ps1" -UUPDirectory ".\UUPs" -AppsQueueFile "%appsScript%" -WindowsQueueFile "%uupScript%" -LogPath ".\%LOG%\ContentSHA1.log"
if errorlevel 1 goto :FAIL

echo.
echo === Starting UUP reconstruction for %UUP_BUILD% . . .
>".\%LOG%\ConvertStart.marker" echo BlueLite v1.0 conversion started %DATE% %TIME%
call ".\convert-UUP.cmd"
set "CONVERR=%ERRORLEVEL%"
if not "%CONVERR%"=="0" (
    echo [ERROR] convert-UUP.cmd returned exit code %CONVERR%.
    goto :FAIL
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$m=(Get-Item -LiteralPath '.\%LOG%\ConvertStart.marker').LastWriteTimeUtc; $iso=@(Get-ChildItem -LiteralPath . -File -Filter '*.iso' -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTimeUtc -gt $m } | Sort-Object LastWriteTimeUtc -Descending); if($iso.Count -lt 1){ exit 1 }; $best=@($iso | Where-Object { $_.Name -like '*%UUP_BUILD%*' } | Select-Object -First 1); if($best.Count -eq 0){ $best=@($iso | Select-Object -First 1) }; $best[0].FullName | Set-Content -LiteralPath '.\%LOG%\FinalISO.txt' -Encoding ASCII; Write-Host $best[0].FullName"
if errorlevel 1 goto :FAIL

call :COLLECT_LOGS
echo.
echo ================================================================
echo BlueLite v1.0 Custom UUP completed successfully.
echo Original UUP archive authority: %UUP_BUILD% / %UUP_ID%
echo Final app target: Security Health UI, Calculator, Notepad, Photos; inspect residue report for actual state.
echo Windows UUP reference/delta queue stayed intact.
echo Pre-debloated WIM passed AppX, pending, protected-floor and component-store health gates.
echo Release-forbidden AppX residues, if any, are reported for the later full offline script-debloat queue.
echo ================================================================
if exist ".\%LOG%\FinalISO.txt" type ".\%LOG%\FinalISO.txt"
rem Noninteractive: START.cmd collects evidence and exits.
exit /b 0

:CHECK_UUPDUMP_ERROR
set "DETECTED_ERROR="
for /F "tokens=2 delims=:" %%i in ('findstr #UUPDUMP_ERROR: "%~1" 2^>NUL') do set "DETECTED_ERROR=%%i"
if defined DETECTED_ERROR (
    echo [ERROR] UUP Dump: %DETECTED_ERROR%
    exit /b 1
)
exit /b 0

:COLLECT_LOGS
for %%F in (ErrorLog_*.txt *_Debug.log) do if exist "%%F" copy /y "%%F" ".\%LOG%\%%~nxF" >NUL 2>&1
exit /b 0

:DOWNLOAD_ERROR
echo [ERROR] Download failed. See %ariaLog%.
call :COLLECT_LOGS
goto :FAIL

:FAIL
echo.
echo [ERROR] BlueLite v1.0 stopped. A failed gate never force-commits a modified WIM.
echo Review %LOG% for the exact stage.
call :COLLECT_LOGS
rem Noninteractive: START.cmd collects evidence and exits.
exit /b 99
