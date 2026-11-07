# R029: SHA-pinned, stage-ONLY converter hook. Never edits vendor ZIP or its extracted files.
[CmdletBinding()]
param([ValidateSet('Inspect','Prepare')][string]$Mode='Inspect',
 [Parameter(Mandatory=$true)][string]$Stage,
 [Parameter(Mandatory=$true)][string]$SelectedRoot)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
function Gate([bool]$ok,[string]$why){if(-not $ok){throw ('R029_PATCH_HOLD_'+$why)}}
function Sha([string]$path){(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToUpperInvariant()}
function Save([string]$p,$obj){$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($obj|ConvertTo-Json -Depth 12)+[Environment]::NewLine);$f=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$f.Write($bytes,0,$bytes.Length)}finally{$f.Dispose()}}
$root=[IO.Path]::GetFullPath($SelectedRoot).TrimEnd('\')
$stage=[IO.Path]::GetFullPath($Stage).TrimEnd('\')
$logs=Join-Path $root 'BlueLite_Logs'
$converter=Join-Path $stage 'convert-UUP.cmd'
$baseline=Join-Path $stage 'BlueLite\BlueLite_PreDebloatWim.ps1'
$helper=Join-Path $root 'BlueLite_R029_OfflineWim.ps1'
$capture=Join-Path $root 'BlueLite_R029_Capture.ps1'
$targetHelper=Join-Path $stage 'BlueLite\BlueLite_R029_OfflineWim.ps1'
$targetCapture=Join-Path $stage 'BlueLite\BlueLite_R029_Capture.ps1'
$backup=Join-Path $logs 'BlueLite_R029_Prepare_ConverterOriginal.cmd'
$report=Join-Path $logs 'BlueLite_R029_Prepare_Result.json'
try{
 Gate ($root.StartsWith('C:\work\',[StringComparison]::OrdinalIgnoreCase) -and $root -notmatch '\s') 'SELECTED_ROOT'
 Gate ($stage.StartsWith((Join-Path $root 'BlueLite_Work')+'\',[StringComparison]::OrdinalIgnoreCase)) 'STAGE_OUTSIDE_SELECTED_UUP_WORK'
 Gate ((Split-Path $stage -Leaf) -match '^BlueLite_Stage_v11_3_26300_\d+_[a-f0-9]{8}_[a-f0-9]{8}$') 'STAGE_NAME_NOT_SOURCE_BOUND'
 Gate ((Test-Path -LiteralPath $logs -PathType Container) -and (Test-Path -LiteralPath $baseline -PathType Leaf) -and (Test-Path -LiteralPath $converter -PathType Leaf)) 'STAGED_SOURCE_MISSING'
 Gate ((Sha $baseline) -eq '70B137758AB8CF7741DB84BB15E02C7544097DA58B492AB6DE2551FDBAD46DA5') 'V11_3_OLD_MODULE_SHA_NOT_PINNED'
 Gate ((Test-Path -LiteralPath $helper -PathType Leaf) -and (Test-Path -LiteralPath $capture -PathType Leaf)) 'R029_MODULES_MISSING'
 Gate (-not(Test-Path -LiteralPath (Join-Path $stage 'BlueLite_Logs\ConvertStart.marker')) -and -not(Test-Path -LiteralPath (Join-Path $stage 'ISOFOLDER'))) 'CONVERTER_ALREADY_USED_DO_NOT_RETRY'
 Gate (-not(Test-Path -LiteralPath $report) -and -not(Test-Path -LiteralPath $backup) -and -not(Test-Path -LiteralPath $targetHelper) -and -not(Test-Path -LiteralPath $targetCapture)) 'PATCH_ALREADY_STARTED'
 foreach($p in @($root,$stage,$helper,$converter,$baseline)){
  Gate (([IO.File]::GetAttributes($p) -band [IO.FileAttributes]::ReparsePoint) -eq 0) ('REPARSE_'+$p)
 }
 $oldCall='BlueLite\BlueLite_PreDebloatWim.ps1'
 $raw=[IO.File]::ReadAllText($converter,[Text.Encoding]::GetEncoding(1252))
 Gate ($raw.Split([string[]]@($oldCall),[StringSplitOptions]::None).Count -eq 2) 'ONE_OLD_MODULE_CALL_REQUIRED'
 Gate (-not($raw.Contains('BlueLite_R029_OfflineWim.ps1'))) 'ALREADY_R029_PATCHED'
 $patched=$raw.Replace($oldCall,'BlueLite\BlueLite_R029_OfflineWim.ps1')
 $oldShell='powershell -NoProfile -ExecutionPolicy Bypass -File "BlueLite\BlueLite_R029_OfflineWim.ps1"'
 Gate ($patched.Split([string[]]@($oldShell),[StringSplitOptions]::None).Count -eq 2) 'ONE_ORIGINAL_POWERSHELL5_OFFLINE_INVOCATION_REQUIRED'
 $patched=$patched.Replace($oldShell,'pwsh.exe -NoProfile -NonInteractive -File "BlueLite\BlueLite_R029_OfflineWim.ps1"')

 $hookRx='(?m)(\s*exit /b 92\s*\)\s*)(if %SkipISO% neq 0 \()'
 $match=[regex]::Matches($patched,$hookRx)
 Gate ($match.Count -eq 1) ('SINGLE_CAPTURE_ANCHOR_EXPECTED_FOUND_'+$match.Count)
 $m=$match[0]
 $inject='pwsh.exe -NoProfile -NonInteractive -File "BlueLite\BlueLite_R029_Capture.ps1" -StageRoot "."'+[Environment]::NewLine+
  'if errorlevel 1 ('+[Environment]::NewLine+
  ' echo [R029 ERROR] SHA/WinRE/Setup capture HOLD'+[Environment]::NewLine+
  ' exit /b 93'+[Environment]::NewLine+
  ')'+[Environment]::NewLine
 $patched=$patched.Substring(0,$m.Index)+$m.Groups[1].Value+$inject+$m.Groups[2].Value+$patched.Substring($m.Index+$m.Length)
 Gate ($patched.Contains('BlueLite_R029_Capture.ps1') -and $patched.Contains('BlueLite_R029_OfflineWim.ps1')) 'PATCH_INTERCEPT_MISSING'
 foreach($p in @($helper,$capture)) {
  $tokens=$null;$parse=$null;[void][Management.Automation.Language.Parser]::ParseFile($p,[ref]$tokens,[ref]$parse)
  if($parse.Count){throw ('R029_AST_HOLD_'+$p+'_'+$parse[0].Message)}
 }
 if($Mode -eq 'Inspect'){
  Write-Host ('R029_PATCH_INSPECT_PASS source='+[IO.Path]::GetFileName($converter)+' oldsha='+(Sha $converter)+' uniquehook=1 nativehelper_ast=0')
  exit 0
 }
 # The original converter is protected by a new exact SHA backup and all mutations are STAGE-ONLY.
 [IO.File]::Copy($converter,$backup,$false)
 Gate ((Sha $backup) -eq (Sha $converter)) 'BACKUP_SHA_MISMATCH'
 [IO.File]::Copy($helper,$targetHelper,$false)
 [IO.File]::Copy($capture,$targetCapture,$false)
 Gate ((Sha $targetHelper) -eq (Sha $helper) -and (Sha $targetCapture) -eq (Sha $capture)) 'MODULE_COPY_SHA'
 [IO.File]::WriteAllText($converter,$patched,[Text.Encoding]::GetEncoding(1252))
 Gate ([IO.File]::ReadAllText($converter,[Text.Encoding]::GetEncoding(1252)) -ceq $patched) 'CONVERTER_TEXT_READBACK'
 Save $report ([ordered]@{schema='BlueLite.R029.ConverterPatch.v1';status='PREPARED';source_stage=$stage;original_converter_sha256=(Sha $backup);patched_converter_sha256=(Sha $converter);donor_module_sha256=(Sha $baseline);new_offline_sha256=(Sha $targetHelper);new_capture_sha256=(Sha $targetCapture);native_anchor_count=1;original_vendor_zip_modified=$false;only_stage_source_changed=$true;one_next='NATIVE_SINGLE_CONVERSION'})
 Write-Host ('R029_PATCH_PREPARED_SHA_PASS '+$report)
 exit 0
}catch{
 Write-Host ('R029_PATCH_HOLD '+$_.Exception.Message)
 exit 17
}
