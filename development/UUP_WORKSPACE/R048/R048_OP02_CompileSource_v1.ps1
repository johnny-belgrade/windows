# R048 independently versioned compiler. Never mutate protected OP47.
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root='C:\work\_UUP'
$old=Join-Path $root 'R046_PRE_MAX_26300x\BlueLite_PRE_MAX_26300x_OP47.zip'
$qa=Join-Path $root 'temp\R048_OP02_SourceRepair_QA_20261121'
$src=Join-Path $qa 'Source'
$delivery=Join-Path $root 'R048_PREMAX_Universal_26300x'
$final=Join-Path $delivery 'BlueLite_PRE_MAX_26300x_R048_v1.zip'
$history=Join-Path $root 'UUP-history\R048_PREMAX_Repair_20261121'
if((Get-FileHash -LiteralPath $old -Algorithm SHA256).Hash -ne 'C3226AFE1A637C7245D1FD0CFFC89616C77CCAD9681D7B7B21927809A81F4304' -or (Get-Item -LiteralPath $old).Length -ne 109995){throw 'ORIGINAL_MISMATCH'}
foreach($p in @($qa,$delivery)){
 if(Test-Path -LiteralPath $p) {throw "CYCLE_PATH_ALREADY_EXISTS:$p"}
}
[IO.Directory]::CreateDirectory($src)|Out-Null
[IO.Compression.ZipFile]::ExtractToDirectory($old,$src)
function ReplaceOnce([string]$relative,[string]$before,[string]$after){
 $p=Join-Path $src $relative
 $t=[IO.File]::ReadAllText($p)
 if(-not $t.Contains($before) -or $t.IndexOf($before) -ne $t.LastIndexOf($before)){throw "ANCHOR_NOT_EXACTLY_ONE:$relative"}
 [IO.File]::WriteAllText($p,$t.Replace($before,$after),[Text.UTF8Encoding]::new($false))
}
# CMD starts a durable bootstrap before PowerShell preflight; fallback to PATH for valid PS7 installations.
$cmd=@'
@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "BROOT=%~dp0"
if not exist "%BROOT%BlueLite_Logs" mkdir "%BROOT%BlueLite_Logs"
if not exist "%BROOT%BlueLite_Logs" (echo [HOLD] Cannot create bootstrap directory.&exit /b 17)
set "BOOT=%BROOT%BlueLite_Logs\PRE_MAX_Bootstrap_%RANDOM%_%RANDOM%.txt"
if exist "%BOOT%" (echo [HOLD] Bootstrap filename collision.&exit /b 17)
> "%BOOT%" echo BlueLite PRE_MAX bootstrap started %DATE% %TIME% root=%BROOT%
if errorlevel 1 (echo [HOLD] Cannot persist bootstrap.&exit /b 17)
set "BLUELITE_BOOTSTRAP_LOG=%BOOT%"
set "PS7=%ProgramFiles%\PowerShell\7\pwsh.exe"
if exist "%PS7%" goto pwshfound
set "PS7="
for /f "delims=" %%P in ('where pwsh.exe 2^>nul') do if not defined PS7 set "PS7=%%P"
if not defined PS7 (
 >> "%BOOT%" echo HOLD no PowerShell 7
 echo [HOLD] PowerShell 7.5 or later required
 exit /b 17
)
:pwshfound
>> "%BOOT%" echo PS7=%PS7%
if /i "%~1"=="--inspect" goto inspect
if /i "%~1"=="--plan-build" goto plan
if /i "%~1"=="--build" goto build
goto usage
:usage
>> "%BOOT%" echo HOLD invalid mode/arguments
echo [HOLD] Use --inspect, --plan-build or separately approved --build
exit /b 17
:inspect
if not "%~2"=="" goto usage
set "mode=Inspect"
goto run
:plan
set "mode=PlanBuild"
goto run
:build
set "mode=Build"
:run
if not "%~4"=="" goto usage
"%PS7%" -NoLogo -NoProfile -NonInteractive -File "%~dp0Run.ps1" -Mode %mode% -CacheManifest "%~2" -AppsCatalog "%~3"
set "rc=%ERRORLEVEL%"
>> "%BOOT%" echo ChildExit=%rc%
exit /b %rc%
'@
[IO.File]::WriteAllText((Join-Path $src 'PRE_MAX.cmd'),$cmd.Replace([string][char]10,[Environment]::NewLine),[Text.UTF8Encoding]::new($false))
ReplaceOnce 'Run.ps1' '[void][IO.Directory]::CreateDirectory($run)' @'
[void][IO.Directory]::CreateDirectory($run)
  if($env:BLUELITE_BOOTSTRAP_LOG -and [IO.File]::Exists($env:BLUELITE_BOOTSTRAP_LOG)){
    [IO.File]::Copy($env:BLUELITE_BOOTSTRAP_LOG,(Join-Path $run 'Bootstrap.cmd.log'),$false)
  }
'@.TrimEnd()
ReplaceOnce 'Run.ps1' 'if (-not [IO.Directory]::Exists($run)) {exit 17}' 'if (-not [IO.Directory]::Exists($run)) {throw "Run log folder was not created"}'
ReplaceOnce 'Run.ps1' '} catch {Write-Host "[HOLD] Evidence: $($_.Exception.Message)";exit 17}' @'
} catch {
 $e=$_.Exception.Message
 Write-Host "[EVIDENCE_HOLD] Secondary archive/mirror failure: $e; native child exit=$exitCode"
 try {
  [void][IO.Directory]::CreateDirectory($logs)
  $er=[ordered]@{UTC=[DateTime]::UtcNow.ToString('o');RunId=$id;NativeChildExit=$exitCode;SecondaryEvidenceHOLD=$e}
  $ep=Join-Path $logs ("Evidence_HOLD_"+$id+".json")
  $data=[Text.UTF8Encoding]::new($false).GetBytes(($er|ConvertTo-Json -Depth 4)+[Environment]::NewLine)
  $stream=[IO.File]::Open($ep,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
  try {$stream.Write($data,0,$data.Length)} finally {$stream.Dispose()}
 } catch {Write-Host "[EVIDENCE_HOLD] Secondary report also unavailable: $($_.Exception.Message)"}
}
'@.TrimEnd()
$wim='Engine\BlueLite\BlueLite_PreDebloatWim.ps1'
ReplaceOnce $wim @'
    Move-Item -LiteralPath $exportWim -Destination $WimPath -Force
    $finalHash=(Get-FileHash -LiteralPath $WimPath -Algorithm SHA256).Hash.ToUpperInvariant()
'@.TrimEnd() @'
    # Atomic same-volume swap with explicit exact SHA+identity proof and retained rollback backup.
    $newHash=(Get-FileHash -LiteralPath $exportWim -Algorithm SHA256).Hash.ToUpperInvariant()
    $priorHash=(Get-FileHash -LiteralPath $WimPath -Algorithm SHA256).Hash.ToUpperInvariant()
    if([IO.Path]::GetPathRoot($exportWim) -ine [IO.Path]::GetPathRoot($WimPath)){throw 'CROSS_VOLUME_PROMOTION_REFUSED'}
    foreach($p in @($exportWim,$WimPath,$WorkDirectory)){
      if((Get-Item -LiteralPath $p).Attributes -band [IO.FileAttributes]::ReparsePoint){throw "REPARSE_PROMOTION_REFUSED $p"}
    }
    $backupWim=Join-Path $WorkDirectory 'install.prepromotion.rollback.wim'
    $rejectedWim=Join-Path $WorkDirectory 'install.rejected.postrollback.wim'
    if((Test-Path -LiteralPath $backupWim) -or (Test-Path -LiteralPath $rejectedWim)){throw 'EXISTING_BACKUP_REFUSED'}
    $swapped=$false
    try{
      [IO.File]::Replace($exportWim,$WimPath,$backupWim,$true)
      $swapped=$true
      $finalHash=(Get-FileHash -LiteralPath $WimPath -Algorithm SHA256).Hash.ToUpperInvariant()
      if($finalHash -cne $newHash -or (Get-Item -LiteralPath $WimPath).Length -ne $newSize){throw 'PROMOTED_SHA_OR_SIZE_MISMATCH'}
      $verifyWim=Invoke-DismCapture @('/English','/Get-WimInfo',"/WimFile:$WimPath","/Index:$Index") 'Verify promoted WIM identity'
      if(($verifyWim -join ' ') -notmatch [regex]::Escape($actualBuild)){throw 'PROMOTED_BUILD_IDENTITY_MISMATCH'}
      if((Get-FileHash -LiteralPath $backupWim -Algorithm SHA256).Hash.ToUpperInvariant() -cne $priorHash){throw 'BACKUP_SHA_MISMATCH'}
      [void]$actions.Add("ATOMIC_PROMOTION_PASS SHA256=$finalHash")
    }catch{
      $failure=$_.Exception.Message
      if($swapped -and (Test-Path -LiteralPath $backupWim)){
       try {
         [IO.File]::Replace($backupWim,$WimPath,$rejectedWim,$true)
         if((Get-FileHash -LiteralPath $WimPath -Algorithm SHA256).Hash.ToUpperInvariant() -cne $priorHash){throw 'RESTORE_SHA_MISMATCH'}
       }catch{throw "PROMOTION_ROLLBACK_HOLD (preserve images): $failure; $($_.Exception.Message)"}
       throw "PROMOTION_REJECTED_ROLLED_BACK: $failure"
      }
      throw "PROMOTION_HOLD_SOURCE_PRESERVED: $failure"
    }
'@.TrimEnd()
# Preserve same F01 handoff policy; do not expand risky removals by changing data.
$unreachable=Join-Path $src 'README.txt'
if(-not (Test-Path -LiteralPath $unreachable)){throw 'README_EXPECTED'}
foreach($f in @(Get-ChildItem -LiteralPath $src -File -Recurse)){
 if($f.FullName -ne $unreachable -and $f.Name -ne 'SHA256SUMS.txt' -and $f.Extension -in @('.ps1','.cmd','.ini','.txt')){
  if([IO.File]::ReadAllText($f.FullName).Contains('README.txt')){throw "README_REFERENCED $($f.FullName)"}
 }
}
[IO.File]::Delete($unreachable)
$manifest=Join-Path $src 'SHA256SUMS.txt'
[IO.File]::Delete($manifest)
$entries=@(Get-ChildItem -LiteralPath $src -File -Recurse | Sort-Object FullName)
$lines=@(foreach($f in $entries){$name=$f.FullName.Substring($src.Length+1).Replace('\','/');'{0} *{1}' -f (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash.ToUpperInvariant(),$name})
[IO.File]::WriteAllLines($manifest,$lines,[Text.UTF8Encoding]::new($false))
[IO.Directory]::CreateDirectory($delivery)|Out-Null
[IO.Compression.ZipFile]::CreateFromDirectory($src,$final,[IO.Compression.CompressionLevel]::Optimal,$false)
$z=[IO.Compression.ZipFile]::OpenRead($final)
try{
 if($z.Entries.Count -ne ($lines.Count+1)){throw 'ZIP_COUNT'}
 foreach($line in $lines){
  if($line -notmatch '^([A-F0-9]{64}) \*(.+)$'){throw 'HASH_LINE'}
  $sha=$Matches[1];$entry=$z.GetEntry($Matches[2])
  if($null -eq $entry){throw 'ZIP_MEMBER_NOT_FOUND'}
  $s=$entry.Open();$hasher=[Security.Cryptography.SHA256]::Create()
  try{$digest=[Convert]::ToHexString($hasher.ComputeHash($s))}finally{$s.Dispose();$hasher.Dispose()}
  if($digest -cne $sha){throw 'ZIP_MEMBER_SHA'}
 }
}finally{$z.Dispose()}
[IO.Directory]::CreateDirectory($history)|Out-Null
$receipt=[ordered]@{Schema='BlueLite.R048.OP02.Compile.v1';UTC=[DateTime]::UtcNow.ToString('o');SourceSHA256=(Get-FileHash -LiteralPath $old).Hash;Output=$final;OutputSHA256=(Get-FileHash -LiteralPath $final).Hash;Bytes=(Get-Item -LiteralPath $final).Length;Entries=$lines.Count+1;Manifest=$lines.Count;Changed=@('PRE_MAX.cmd','Run.ps1','Engine/BlueLite/BlueLite_PreDebloatWim.ps1','SHA256SUMS.txt');Removed=@('README.txt');FullBuild='NOT_RUN';Next='INDEPENDENT_NATIVE_QA'}
$rp=Join-Path $history 'R048_OP02_SourceCompile.json'
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($receipt|ConvertTo-Json -Depth 7)+[Environment]::NewLine)
$fs=[IO.File]::Open($rp,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$fs.Write($bytes,0,$bytes.Length)}finally{$fs.Dispose()}
Write-Host "R048_OP02_COMPILED_SHA=$($receipt.OutputSHA256) SIZE=$($receipt.Bytes) ENTRIES=$($receipt.Entries) RECEIPT_SHA=$((Get-FileHash -LiteralPath $rp).Hash)"
