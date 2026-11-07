# BlueLite R029 — complete one-root original UUPdump + BlueLite MAX_PRE automated workflow.
# Never close Explorer or Total Commander. ONLY root BlueLite_R029_RUN.cmd is operator entry.
[CmdletBinding()]
param([ValidateSet('Inspect','Build')][string]$Mode='Inspect',[string]$SelectedRoot='')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
function Gate([bool]$yes,[string]$why){if(-not $yes){throw ('R029_HOLD_'+$why)}}
function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()}
function JSON([string]$p){Get-Content -LiteralPath $p -Raw -Encoding UTF8|ConvertFrom-Json}
function Save([string]$p,$obj){
 $b=[Text.UTF8Encoding]::new($false).GetBytes(($obj|ConvertTo-Json -Depth 16)+[Environment]::NewLine)
 $f=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$f.Write($b,0,$b.Length)}finally{$f.Dispose()}
}
function Manifest([string]$root) {
 $p=Join-Path $root 'BlueLite_R029_Manifest.sha256'
 Gate (Test-Path -LiteralPath $p -PathType Leaf) 'COMPLETE_BLUE_LITE_SOURCE_MANIFEST_MISSING'
 $rows=@(Get-Content -LiteralPath $p|Where-Object{$_.Trim()})
 Gate ($rows.Count -eq 62) ('R029_EXPECTED_62_MANIFEST_MEMBERS_GOT_'+$rows.Count)
 $names=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 foreach($row in $rows) {
  $m=[regex]::Match($row,'^([a-fA-F0-9]{64}) \*(.+)$')
  Gate $m.Success 'R029_MALFORMED_MANIFEST'
  $name=$m.Groups[2].Value.Replace('/','\')
  Gate ($name -match '^[A-Za-z0-9_.\\-]+$' -and -not $name.Contains('..') -and $names.Add($name)) ('R029_UNSAFE_DUPLICATE_MANIFEST_'+$name)
  $full=[IO.Path]::GetFullPath((Join-Path $root $name))
  Gate ($full.StartsWith($root+'\',[StringComparison]::OrdinalIgnoreCase)) ('R029_MANIFEST_ESCAPE_'+$name)
  Gate (Test-Path -LiteralPath $full -PathType Leaf) ('R029_MODULE_MISSING_'+$name)
  Gate (([IO.File]::GetAttributes($full) -band [IO.FileAttributes]::ReparsePoint) -eq 0) ('R029_MODULE_REPARSE_'+$name)
  Gate ((Sha $full) -eq $m.Groups[1].Value.ToUpperInvariant()) ('R029_SOURCE_CHANGED_'+$name)
 }
 foreach($name in @('BlueLite_R029_RUN.cmd','BlueLite_R029_Run.ps1','BlueLite_R029_Prepare.ps1','BlueLite_R029_OfflineWim.ps1','BlueLite_R029_Capture.ps1','BlueLite_R029_ReadMe.txt','BlueLite_PREMAX_Factory_v11_3.ps1','BlueLite_Run_v11_3.ps1','BlueLite_Package_SHA256.txt','BlueLite\BlueLite_PreDebloatWim.ps1')) {
  Gate ($names.Contains($name)) ('R029_REQUIRED_SOURCE_NOT_MANIFESTED_'+$name)
 }
 Write-Host ('R029_SOURCE_MANIFEST_SHA256_PASS '+$rows.Count+'/62')
}
function Vendor([string]$root){
 $archives=@(Get-ChildItem -LiteralPath $root -File -Filter '*_convert.zip')
 Gate ($archives.Count -eq 1) ('R029_NEED_ONE_GENUINE_UUPDUMP_CONVERT_ZIP_FOUND_'+$archives.Count)
 $z=[IO.Compression.ZipFile]::OpenRead($archives[0].FullName)
 try{
  $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  $count=0
  foreach($e in $z.Entries){
   if($e.FullName.EndsWith('/')){continue}
   $rel=$e.FullName.Replace('/','\')
   Gate ($rel -match '^[A-Za-z0-9_.\\ -]+$' -and -not $rel.Contains('..') -and $seen.Add($rel)) ('R029_VENDOR_ZIP_UNSAFE_MEMBER_'+$rel)
   $path=[IO.Path]::GetFullPath((Join-Path $root $rel))
   Gate ($path.StartsWith($root+'\',[StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $path -PathType Leaf)) ('R029_VENDOR_NOT_EXTRACTED_'+$rel)
   $str=$e.Open();$alg=[Security.Cryptography.SHA256]::Create()
   try{$digest=[Convert]::ToHexString($alg.ComputeHash($str))}finally{$str.Dispose();$alg.Dispose()}
   Gate ($digest -eq (Sha $path)) ('R029_ORIGINAL_VENDOR_SHA_MISMATCH_'+$rel)
   $count++
  }
  Gate ($count -eq 11) ('R029_VENDOR_MEMBER_COUNT_'+$count)
 }finally{$z.Dispose()}
 $body=[IO.File]::ReadAllText((Join-Path $root 'uup_download_windows.cmd'))
 $build=[regex]::Matches($body,'(?im)^\s*title\s+(26300\.\d+)_(amd64|x64)_en-us_professional(?=[_\s]|$)')
 Gate ($build.Count -eq 1) 'R029_ONLY_SOURCE_26300X_AMD64_ENUS_PRO'
 $uids=@([regex]::Matches($body,'(?i)[?&]id=([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})')|ForEach-Object{$_.Groups[1].Value.ToLowerInvariant()}|Sort-Object -Unique)
 Gate ($uids.Count -eq 1) 'R029_VENDOR_UUID_NOT_UNIQUE'
 return [pscustomobject]@{build=$build[0].Groups[1].Value;uuid=$uids[0];zip=$archives[0].FullName;zip_sha256=(Sha $archives[0].FullName);member_count=11}
}
function Stage([string]$root,$vendor) {
 $logs=Join-Path $root 'BlueLite_Logs'
 $all=@(Get-ChildItem -LiteralPath $logs -File -Filter 'BlueLite_v11_3_FullDownload_*_OPDL_Report.json' -ErrorAction SilentlyContinue)
 $valid=[Collections.Generic.List[object]]::new()
 foreach($file in $all){
  try{
   $r=JSON $file.FullName
   if($r.status -ne 'DOWNLOADED_SHA1_PASS' -or $r.build -ne $vendor.build -or [int]$r.payload_files -lt 20 -or [long]$r.payload_bytes -lt 1000000000L){continue}
   $st=[IO.Path]::GetFullPath([string]$r.stage).TrimEnd('\')
   if(-not $st.StartsWith((Join-Path $root 'BlueLite_Work')+'\',[StringComparison]::OrdinalIgnoreCase)){continue}
   $meta=JSON (Join-Path $st 'BlueLite_Logs\ResolvedUUP.json')
   if([string]$meta.UUP_ID -ne $vendor.uuid -or [string]$meta.UUP_BUILD -ne $vendor.build){continue}
   $rec=Join-Path $logs ($r.run_id+'_OPDL_Receipt.json')
   $ver=Join-Path $logs ($r.run_id+'_OPDL_Verify.json')
   if(-not(Test-Path $rec -PathType Leaf) -or -not(Test-Path $ver -PathType Leaf)){continue}
   $a=JSON $rec;$b=JSON $ver
   if($a.status -ne 'PASS' -or $b.status -ne 'PASS' -or $a.report_sha256 -ne (Sha $file.FullName) -or $b.receipt_sha256 -ne (Sha $rec) -or $b.report_sha256 -ne (Sha $file.FullName)){continue}
   $valid.Add([pscustomobject]@{stage=$st;report=$file.FullName;source_bytes=[long]$r.payload_bytes;source_files=[int]$r.payload_files})
  }catch{continue}
 }
 Gate ($valid.Count -le 1) ('R029_AMBIGUOUS_VERIFIED_STAGE_COUNT_'+$valid.Count)
 if($valid.Count){return $valid[0]}
 return $null
}
function Evidence([string]$logs,[string]$stage,[string]$report,[string]$output) {
 $used=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 $zip=[IO.Compression.ZipFile]::Open($output,[IO.Compression.ZipArchiveMode]::Create)
 try{
  foreach($f in @(Get-ChildItem -LiteralPath $logs -File -ErrorAction Stop)){
   if($f.FullName -eq $output -or $f.Length -ge 20MB){continue}
   $name='UUP_ROOT/'+$f.Name
   Gate ($used.Add($name)) 'EVIDENCE_DUPLICATE'
   [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$f.FullName,$name,[IO.Compression.CompressionLevel]::Optimal)
  }
  if($stage -and (Test-Path -LiteralPath (Join-Path $stage 'BlueLite_Logs') -PathType Container)){
   foreach($f in @(Get-ChildItem -LiteralPath (Join-Path $stage 'BlueLite_Logs') -File)){
    if($f.Length -gt 20MB){continue}
    $name='NATIVE_STAGE/'+$f.Name
    if($used.Add($name)){[void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$f.FullName,$name,[IO.Compression.CompressionLevel]::Optimal)}
   }
  }
 }finally{$zip.Dispose()}
 $z=[IO.Compression.ZipFile]::OpenRead($output)
 try{
  Gate ($z.Entries.Count -ge 2) 'EVIDENCE_ZIP_EMPTY'
  foreach($e in $z.Entries) {
   Gate ($e.FullName.StartsWith('UUP_ROOT/') -or $e.FullName.StartsWith('NATIVE_STAGE/')) 'EVIDENCE_UNSAFE_NAME'
   $p=if($e.FullName.StartsWith('UUP_ROOT/')){Join-Path $logs ($e.FullName.Substring(9))}else{Join-Path (Join-Path $stage 'BlueLite_Logs') ($e.FullName.Substring(13))}
   $stream=$e.Open();$alg=[Security.Cryptography.SHA256]::Create()
   try{$v=[Convert]::ToHexString($alg.ComputeHash($stream))}finally{$stream.Dispose();$alg.Dispose()}
   Gate ($v -eq (Sha $p)) ('EVIDENCE_SHA_FAILURE_'+$e.FullName)
  }
 }finally{$z.Dispose()}
 Write-Host ('R029_COMPLETE_EVIDENCE_ZIP_SHA_PASS FILE='+$output+' SHA256='+(Sha $output))
}
if(-not $SelectedRoot){$SelectedRoot=$PSScriptRoot}
$root=[IO.Path]::GetFullPath($SelectedRoot).TrimEnd('\')
$logs=Join-Path $root 'BlueLite_Logs'
$work=Join-Path $root 'BlueLite_Work'
$result=Join-Path $logs 'BlueLite_R029_RESULT.json'
$evidenceZip=Join-Path $logs 'BlueLite_R029_EVIDENCE.zip'
$console=Join-Path $logs 'BlueLite_R029_Controller.log'
$state='PRECONDITION';$modeChosen='NONE';$stage=$null;$vendor=$null;$success=$false
try{
 Gate ($root.StartsWith('C:\work\',[StringComparison]::OrdinalIgnoreCase) -and -not $root.Contains(' ')) 'PORTABLE_ROOT_MUST_BE_C_WORK_NO_SPACES'
 Gate (Test-Path -LiteralPath $root -PathType Container) 'UUP_SELECTED_FOLDER_MISSING'
 foreach($p in @($root,(Split-Path $root -Parent))){Gate (([IO.File]::GetAttributes($p) -band [IO.FileAttributes]::ReparsePoint) -eq 0) 'UUP_ROOT_REPARSE'}
 if($Mode -eq 'Build'){
  Gate (-not(Test-Path $result) -and -not(Test-Path $evidenceZip) -and -not(Test-Path $console)) 'PREVIOUS_RUN_EVIDENCE_EXISTS_NO_BLIND_RERUN'
  [void][IO.Directory]::CreateDirectory($logs)
  [void][IO.Directory]::CreateDirectory($work)
 }
 Manifest $root
 $vendor=Vendor $root
 $stage=Stage $root $vendor
 $label=if($null -eq $stage){'NONE'}else{$stage.stage}
 Write-Host ('R029_VENDOR_AND_MANIFEST_PASS build='+$vendor.build+' uuid='+$vendor.uuid+' stage='+$label)
 if($Mode -eq 'Inspect') {
  if($null -eq $stage){Write-Host 'R029_INSPECT_PASS FRESH_SOURCE_WILL_DOWNLOAD'}
  else{Write-Host ('R029_INSPECT_PASS stage='+$stage.stage+' started='+(Test-Path (Join-Path $stage.stage 'BlueLite_Logs\ConvertStart.marker')))}
  exit 0
 }
 & fltmc.exe *> $null
 Gate ($LASTEXITCODE -eq 0) 'RUN_ADMINISTRATOR_CMD'
 Gate (@(Get-WindowsImage -Mounted -ErrorAction Stop).Count -eq 0) 'OTHER_WIM_MOUNTED'
 Gate (@(Get-Process -Name 'dism','dismhost','aria2c','NTLite' -ErrorAction SilentlyContinue).Count -eq 0) 'COMPETING_DISM_DOWNLOAD_PROCESS'
 [IO.File]::WriteAllText($console,('R029 BUILD START '+[DateTime]::UtcNow.ToString('o')+' root='+$root+[Environment]::NewLine),[Text.UTF8Encoding]::new($false))
 $state='SOURCE'
 if($null -eq $stage){
  $modeChosen='NEW_FULL_UUP_DOWNLOAD'
  & pwsh.exe -NoLogo -NoProfile -NonInteractive -File (Join-Path $root 'BlueLite_Run_v11_3.ps1') -Mode Download
  Gate ($LASTEXITCODE -eq 0) ('NATIVE_FULL_DOWNLOAD_EXIT_'+$LASTEXITCODE)
  $stage=Stage $root $vendor
  Gate ($null -ne $stage) 'FULL_DOWNLOAD_SHA_RECEIPTS_NOT_COMPLETE'
 }else{$modeChosen='EXISTING_RECEIPT_VERIFIED_SOURCE'}
 $sourceStage=$stage.stage
 Gate (-not(Test-Path (Join-Path $sourceStage 'BlueLite_Logs\ConvertStart.marker'))) 'CONVERTER_PREVIOUSLY_STARTED_DO_NOT_RERUN'
 Gate (-not(Test-Path (Join-Path $sourceStage 'ISOFOLDER'))) 'EXISTING_ISOFOLDER_DO_NOT_RECONVERT'
 $state='PREPARE'
 & pwsh.exe -NoLogo -NoProfile -NonInteractive -File (Join-Path $root 'BlueLite_R029_Prepare.ps1') -Mode Inspect -Stage $sourceStage -SelectedRoot $root
 Gate ($LASTEXITCODE -eq 0) 'PATCH_STATIC_IDENTITY_ANCHOR_HOLD'
 & pwsh.exe -NoLogo -NoProfile -NonInteractive -File (Join-Path $root 'BlueLite_R029_Prepare.ps1') -Mode Prepare -Stage $sourceStage -SelectedRoot $root
 Gate ($LASTEXITCODE -eq 0) 'PATCH_NATIVE_PREPARE_HOLD'
 $env:BLUELITE_DOWNLOAD_ONLY=''
 $env:BLUELITE_V7_IMAGE_AUTH='RUNTIME_USER_APPROVED'
 $env:BLUELITE_UUP_ROOT=$root
 $state='CONVERSION'
 Push-Location -LiteralPath $sourceStage
 try{
  & $env:ComSpec /d /c 'START-ENGINE-APPROVED.cmd'
  $nativeExit=[int]$LASTEXITCODE
 }finally{
  Pop-Location
  $env:BLUELITE_V7_IMAGE_AUTH=''
  $env:BLUELITE_UUP_ROOT=''
 }
 Gate ($nativeExit -eq 0) ('NATIVE_CONVERTER_EXIT_'+$nativeExit)
 $state='POST_ISO_VERIFY'
 $out=Join-Path $sourceStage 'BlueLite_R029_Outputs'
 Gate (Test-Path -LiteralPath (Join-Path $out 'install.wim') -PathType Leaf) 'NO_CAPTURED_INSTALL_WIM'
 Gate (Test-Path -LiteralPath (Join-Path $out 'boot.wim') -PathType Leaf) 'NO_CAPTURED_SETUP_BOOT'
 $isoSource=@(Get-ChildItem -LiteralPath $sourceStage -File -Filter '*.ISO')
 Gate ($isoSource.Count -eq 1) ('PROVIDER_ISO_NOT_ONE_'+$isoSource.Count)
 $iso=Join-Path $out $isoSource[0].Name
 Move-Item -LiteralPath $isoSource[0].FullName -Destination $iso -ErrorAction Stop
 $seven=Join-Path $sourceStage 'bin\7z.exe'
 Gate (Test-Path -LiteralPath $seven -PathType Leaf) '7ZIP_FROM_STAGED_CONVERTER_MISSING'
 & $seven t '-bd' $iso *> $null
 Gate ($LASTEXITCODE -eq 0) ('ISO_CRC_FAIL_'+$LASTEXITCODE)
 $offline=JSON (Join-Path $logs 'BlueLite_R029_Offline_Result.json')
 Gate ([string]$offline.status -like 'CANDIDATE_OFFLINE_COMPLETE*') 'OFFLINE_NATIVE_RESULT_NOT_COMPLETE'
 $capture=JSON (Join-Path $logs 'BlueLite_R029_Capture_Result.json')
 Gate ($capture.status -eq 'NATIVE_WIM_BOOT_HARDLINK_SHA_PASS') 'SETUP_WIM_NOT_CAPTURED'
 $wim=Join-Path $out 'install.wim'
 $boot=Join-Path $out 'boot.wim'
 Gate ((Sha $wim) -eq [string]$offline.promoted_wim_sha256 -and (Sha $boot) -eq [string]$capture.setup_boot_sha256) 'FINAL_WIM_BOOT_SOURCE_SHA'
 Gate ((Get-Item -LiteralPath $iso).Length -gt (Get-Item -LiteralPath $wim).Length) 'ISO_SMALLER_THAN_WIM'
 # The exact precompact WIM is a disposable OWNED intermediate. Delete only AFTER SHA+7z ISO.
 $rollback=Join-Path $sourceStage 'BlueLite_R029_install.precompact.wim'
 $discardedBytes=0L
 if(Test-Path -LiteralPath $rollback -PathType Leaf){
  $discardedBytes=(Get-Item -LiteralPath $rollback).Length
  [IO.File]::Delete($rollback)
 }
 $state='IMAGE_CANDIDATE_BUILT_NOT_RELEASE_CERTIFIED'
 $success=$true
 $data=[ordered]@{schema='BlueLite.R029.Controller.v1';utc=[DateTime]::UtcNow.ToString('o');status=$state;build=$vendor.build;uuid=$vendor.uuid;mode=$modeChosen;root=$root;stage=$sourceStage;original_source_zip_sha256=$vendor.zip_sha256;install_wim=$wim;install_wim_bytes=(Get-Item $wim).Length;install_wim_sha256=(Sha $wim);boot_wim=$boot;boot_wim_sha256=(Sha $boot);iso=$iso;iso_bytes=(Get-Item $iso).Length;iso_sha256=(Sha $iso);offline_status=$offline.status;offline_foD_remainder=$offline.installed_driver_fod_after;appinstaller_provisioned=$offline.appinstaller_provisioned_after;owned_precompact_intermediate_deleted_bytes=$discardedBytes;release_certified=$false;one_next='RETURN_THIS_ROOT_EVIDENCE_AND_VERIFY_NATIVE_WIM_ISO_FOD_APPX_SETUP_VM'}
 Save $result $data
 Write-Host ('R029_IMAGE_CANDIDATE_PASS ISO_BYTES='+$data.iso_bytes+' WIM_BYTES='+$data.install_wim_bytes+' RELEASE_NOT_CERTIFIED')
}catch{
 if($Mode -eq 'Inspect'){Write-Host ('R029_INSPECT_HOLD '+$_.Exception.Message);exit 17}
 $message=$_.Exception.ToString()
 Write-Host ('R029_CONTROLLER_HOLD '+$message)
 $stagePath=if($null -ne $stage){$stage.stage}else{''}
 try{if(-not(Test-Path -LiteralPath $result)){Save $result ([ordered]@{schema='BlueLite.R029.Controller.v1';utc=[DateTime]::UtcNow.ToString('o');status='HOLD';phase=$state;reason=$message;selected_mode=$modeChosen;root=$root;stage=$stagePath;release_certified=$false;one_next='DO_NOT_BLIND_RETRY_RETURN_EXACT_EVIDENCE'})}}catch{}
}finally{
 if($Mode -eq 'Build' -and (Test-Path -LiteralPath $logs -PathType Container)){
  try{
   $sourceStage=if($null -ne $stage){$stage.stage}else{''}
   Evidence $logs $sourceStage $result $evidenceZip
   Write-Host ('R029_RETURN_EXACT_FILE '+$evidenceZip)
  }catch{Write-Host ('R029_EVIDENCE_HOLD '+$_.Exception.Message)}
 }
}
if($success){exit 0}
exit 17
