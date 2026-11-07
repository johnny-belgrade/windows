# BlueLite R028 universal one-folder workflow. Operators run only BlueLite_R028_RUN.cmd.
# Fresh: original vendor ZIP + original extracted 11 + whole R028 ZIP in user-selected C:\work subfolder.
# Old exact downloaded source: R027 false WIM identity HOLD is eligible for single-use salvage, no redownload.
[CmdletBinding()]
param([ValidateSet('Inspect','Build')][string]$Mode='Inspect',[string]$SelectedRoot='')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
function AssertBL([bool]$b,[string]$m){if(-not $b){throw ('R028_HOLD_'+$m)}}
function HashBL([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()}
function ObjBL([string]$p){Get-Content -LiteralPath $p -Raw -Encoding UTF8|ConvertFrom-Json}
function EmitBL([string]$p,$o){$b=[Text.UTF8Encoding]::new($false).GetBytes(($o|ConvertTo-Json -Depth 16)+[Environment]::NewLine);$f=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$f.Write($b,0,$b.Length)}finally{$f.Dispose()}}
function OriginalBL([string]$p) {
 $archives=@(Get-ChildItem -LiteralPath $p -File -Filter '*_convert.zip')
 AssertBL ($archives.Count -eq 1) ('ORIGINAL_ZIP_COUNT_'+$archives.Count)
 $z=[IO.Compression.ZipFile]::OpenRead($archives[0].FullName)
 try{
  $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  $n=0
  foreach($e in $z.Entries){
   if($e.FullName.EndsWith('/')){continue}
   $name=$e.FullName.Replace('/','\')
   AssertBL ($name -match '^[A-Za-z0-9_.\\-]+$' -and -not $name.Contains('..') -and $seen.Add($name)) ('UNSAFE_OR_DUP_VENDOR_MEMBER_'+$name)
   $local=Join-Path $p $name
   AssertBL (Test-Path -LiteralPath $local -PathType Leaf) ('VENDOR_NOT_EXTRACTED_'+$name)
   $stream=$e.Open();$sha=[Security.Cryptography.SHA256]::Create()
   try{$digest=[Convert]::ToHexString($sha.ComputeHash($stream))}finally{$stream.Dispose();$sha.Dispose()}
   AssertBL ($digest -eq (HashBL $local)) ('ORIGINAL_VENDOR_SHA_MISMATCH_'+$name)
   $n++
  }
  AssertBL ($n -eq 11) ('EXACT_VENDOR_11_REQUIRED_'+$n)
 }finally{$z.Dispose()}
 $launcher=[IO.File]::ReadAllText((Join-Path $p 'uup_download_windows.cmd'))
 $buildRx=[regex]::Matches($launcher,'(?im)^[ \t]*title[ \t]+(26300\.\d+)_(amd64|x64)_en-us_professional(?=[_\s]|$)')
 AssertBL ($buildRx.Count -eq 1) 'ORIGINAL_VENDOR_TITLE_NOT_SUPPORTED'
 $all=[regex]::Matches($launcher,'(?i)[?&]id=([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})')
 AssertBL ($all.Count -ge 2) 'ORIGINAL_UUID_MISSING'
 $uids=@($all|ForEach-Object {$_.Groups[1].Value.ToLowerInvariant()}|Sort-Object -Unique)
 AssertBL ($uids.Count -eq 1) 'ORIGINAL_UUID_NOT_UNIQUE'
 return [pscustomobject]@{build=$buildRx[0].Groups[1].Value;uuid=$uids[0];zip=$archives[0].FullName;zip_sha256=(HashBL $archives[0].FullName);vendor_members=11}
}
function StageBL([string]$root,$source) {
 $logs=Join-Path $root 'BlueLite_Logs'
 $reps=@(Get-ChildItem -LiteralPath $logs -File -Filter 'BlueLite_v11_3_FullDownload_*_OPDL_Report.json' -ErrorAction SilentlyContinue)
 $matches=[Collections.Generic.List[object]]::new()
 foreach($f in $reps) {
  try{
   $d=ObjBL $f.FullName
   if($d.status -ne 'DOWNLOADED_SHA1_PASS' -or $d.build -ne $source.build -or $d.payload_files -ne 130 -or $d.payload_bytes -ne 9143081111){continue}
   $stage=[IO.Path]::GetFullPath([string]$d.stage).TrimEnd([char]'\')
   if(-not $stage.StartsWith((Join-Path $root 'BlueLite_Work')+'\',[StringComparison]::OrdinalIgnoreCase)){continue}
   $meta=ObjBL (Join-Path $stage 'BlueLite_Logs\ResolvedUUP.json')
   if($meta.UUP_ID -ne $source.uuid -or $meta.UUP_BUILD -ne $source.build){continue}
   $rec=Join-Path $logs ([string]$d.run_id+'_OPDL_Receipt.json')
   $verify=Join-Path $logs ([string]$d.run_id+'_OPDL_Verify.json')
   if(-not ((Test-Path $rec) -and (Test-Path $verify))){continue}
   $a=ObjBL $rec;$b=ObjBL $verify
   if($a.status -ne 'PASS' -or $b.status -ne 'PASS' -or $a.report_sha256 -ne (HashBL $f.FullName) -or $b.receipt_sha256 -ne (HashBL $rec) -or $b.report_sha256 -ne (HashBL $f.FullName)){continue}
   $matches.Add([pscustomobject]@{stage=$stage;run_id=$d.run_id;download_report=$f.FullName;build=$source.build})
  }catch{continue}
 }
 AssertBL ($matches.Count -le 1) ('MULTIPLE_VERIFIED_STAGES_'+$matches.Count)
 if($matches.Count -eq 0){return $null}
 return $matches[0]
}
if(-not $SelectedRoot){$SelectedRoot=$PSScriptRoot}
$root=[IO.Path]::GetFullPath($SelectedRoot).TrimEnd([char]'\')
$logs=Join-Path $root 'BlueLite_Logs'
AssertBL ($root.StartsWith('C:\work\',[StringComparison]::OrdinalIgnoreCase) -and -not($root -match '\s')) 'BAD_USER_SELECTED_UUP_ROOT'
AssertBL (Test-Path -LiteralPath $root -PathType Container) 'MISSING_UUP_FOLDER'
foreach($dir in @($root,(Split-Path $root -Parent))) {
 AssertBL (([IO.File]::GetAttributes($dir) -band [IO.FileAttributes]::ReparsePoint) -eq 0) 'REPARSE_OWNER'
}
if($Mode -eq 'Build'){[void][IO.Directory]::CreateDirectory($logs)}
$run='BlueLite_R028_'+[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffffffZ')+'_'+[Guid]::NewGuid().ToString('N').Substring(0,8)
$runReport=Join-Path $logs ($run+'_REPORT.json')
$evidence=Join-Path $logs ($run+'_EVIDENCE.zip')
$stage=$null;$status='NOT_STARTED';$modeSelected='NONE'
try{
 $vendor=OriginalBL $root
 $stage=StageBL $root $vendor
 $stageLabel='NONE'; if($null -ne $stage){$stageLabel=$stage.stage}
 Write-Host ('R028_ORIGINAL_VENDOR_SHA_PASS build='+$vendor.build+' uuid='+$vendor.uuid+' stage='+$stageLabel)
 if($Mode -eq 'Inspect'){
  if($null -ne $stage) {
   $marker=Test-Path (Join-Path $stage.stage 'BlueLite_Logs\ConvertStart.marker')
   $compact=Test-Path (Join-Path $stage.stage 'BlueLite_FinalWim_Work\install.compact.wim')
   Write-Host ('R028_INSPECT_PASS stage='+$stage.stage+' converter_started='+$marker+' compact_wim='+$compact)
  }else{Write-Host 'R028_INSPECT_PASS new source folder: FULL_DOWNLOAD_REQUIRED_ON_BUILD'}
  exit 0
 }
 & fltmc.exe *> $null;AssertBL ($LASTEXITCODE -eq 0) 'ADMIN_REQUIRED'
 if($null -eq $stage) {
  $modeSelected='FRESH_DOWNLOAD'
  Write-Host 'R028_FRESH: native validated full 26300.x source download; NO existing stage will be overwritten.'
  $sourceLauncher=Join-Path $root 'BlueLite_Run_v11_3.ps1'
  AssertBL (Test-Path -LiteralPath $sourceLauncher -PathType Leaf) 'FULL_DONOR_RUNNER_MISSING'
  & pwsh.exe -NoLogo -NoProfile -NonInteractive -File $sourceLauncher -Mode Download
  AssertBL ($LASTEXITCODE -eq 0) ('NEW_DOWNLOAD_FAILED_'+$LASTEXITCODE)
  $stage=StageBL $root $vendor
  AssertBL ($null -ne $stage) 'NEW_DOWNLOAD_OPDL_SHA_CHAIN_NOT_VALID'
 }
 $where=$stage.stage
 $startMarker=Join-Path $where 'BlueLite_Logs\ConvertStart.marker'
 $compact=Join-Path $where 'BlueLite_FinalWim_Work\install.compact.wim'
 if(Test-Path -LiteralPath $startMarker) {
  $modeSelected='RECOVER_R027_FAILED_COMPACT'
  AssertBL (Test-Path -LiteralPath $compact -PathType Leaf) 'CONVERT_STARTED_BUT_NO_COMPACT_EXPORT_DO_NOT_RERUN'
  Write-Host 'R028_RECOVERY: preserving completed source; continue from prior committed compact WIM.'
  & pwsh.exe -NoLogo -NoProfile -NonInteractive -File (Join-Path $root 'BlueLite_R028_Recovery.ps1') -Stage $where -SelectedRoot $root -ExpectedBuild $vendor.build
  AssertBL ($LASTEXITCODE -eq 0) ('R027_RECOVERY_FAILED_'+$LASTEXITCODE)
 } else {
  $modeSelected='SOURCE_RESUME_NATIVE_CONVERTER'
  AssertBL (-not(Test-Path (Join-Path $where 'ISOFOLDER'))) 'UNVERIFIED_ISO_FOLDER'
  & pwsh.exe -NoLogo -NoProfile -NonInteractive -File (Join-Path $root 'BlueLite_R028_PatchEngine.ps1') -Stage $where -SelectedRoot $root -Mode Inspect
  AssertBL ($LASTEXITCODE -eq 0) 'NATIVE_PATCH_STATIC_HOLD'
  & pwsh.exe -NoLogo -NoProfile -NonInteractive -File (Join-Path $root 'BlueLite_R028_PatchEngine.ps1') -Stage $where -SelectedRoot $root -Mode Prepare
  AssertBL ($LASTEXITCODE -eq 0) 'NATIVE_PATCH_PREPARE_HOLD'
  $env:BLUELITE_DOWNLOAD_ONLY=''
  $env:BLUELITE_V7_IMAGE_AUTH='RUNTIME_USER_APPROVED'
  Push-Location -LiteralPath $where
  try{& $env:ComSpec /d /c 'START-ENGINE-APPROVED.cmd';$exit=[int]$LASTEXITCODE}
  finally{$env:BLUELITE_V7_IMAGE_AUTH='';Pop-Location}
  AssertBL ($exit -eq 0) ('NATIVE_CONVERTER_EXIT_'+$exit)
  $dest=Join-Path $where 'BlueLite_R028_Outputs'
  AssertBL (Test-Path (Join-Path $dest 'install.wim') -PathType Leaf) 'FINAL_WIM_NOT_CAPTURED'
  AssertBL (Test-Path (Join-Path $dest 'boot.wim') -PathType Leaf) 'SETUP_BOOT_NOT_CAPTURED'
  $isos=@(Get-ChildItem -LiteralPath $where -File -Filter '*.ISO')
  AssertBL ($isos.Count -eq 1) ('CONVERTER_ISO_COUNT_'+$isos.Count)
  $isoTarget=Join-Path $dest $isos[0].Name
  Move-Item -LiteralPath $isos[0].FullName -Destination $isoTarget
  $seven=Join-Path $where 'bin\7z.exe'
  & $seven t '-bd' $isoTarget *> $null
  AssertBL ($LASTEXITCODE -eq 0) 'NATIVE_ISO_CRC'
 }
 $outputs=Join-Path $where 'BlueLite_R028_Outputs'
 $iso=@(Get-ChildItem -LiteralPath $outputs -File -Filter '*.ISO')
 AssertBL ($iso.Count -eq 1) 'OUTPUT_ISO_COUNT'
 $wim=Join-Path $outputs 'install.wim';$boot=Join-Path $outputs 'boot.wim'
 $status='IMAGE_CANDIDATE_NOT_RELEASE'
 EmitBL $runReport ([ordered]@{schema='BlueLite.R028.Controller.v1';utc=[DateTime]::UtcNow.ToString('o');status=$status;mode=$modeSelected;source_build=$vendor.build;source_uuid=$vendor.uuid;stage=$where;source_original_zip_sha256=$vendor.zip_sha256;install_wim=$wim;install_bytes=(Get-Item $wim).Length;install_sha256=(HashBL $wim);boot_wim_sha256=(HashBL $boot);iso=$iso[0].FullName;iso_bytes=$iso[0].Length;iso_sha256=(HashBL $iso[0].FullName);release_certified=$false;one_next='RETURN_EVIDENCE_INDEPENDENTLY_VERIFY_FOD_WINRE_APPX_VM_SETUP'})
 Write-Host ('R028_IMAGE_CANDIDATE_PASS ISO_BYTES='+$iso[0].Length+' WIM_BYTES='+((Get-Item $wim).Length))
}catch{
 $status='HOLD';Write-Host ('R028_CONTROLLER_HOLD '+$_.Exception.Message)
 try{if(-not(Test-Path $runReport)){EmitBL $runReport ([ordered]@{schema='BlueLite.R028.Controller.v1';status='HOLD';reason=$_.Exception.Message;mode=$modeSelected;stage=if($null -ne $stage){$stage.stage}else{''};one_next='RETURN_EVIDENCE_NO_BLIND_RERUN'})}}catch{}
}finally{
 if($Mode -eq 'Build'){
  try{
   $z=[IO.Compression.ZipFile]::Open($evidence,[IO.Compression.ZipArchiveMode]::Create)
   try {
    $all=@(Get-ChildItem -LiteralPath $logs -File | Where-Object {$_.Name -like 'BlueLite_R028_*' -and $_.FullName -ne $evidence -and $_.Length -lt 33554432})
    foreach($f in $all){[void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($z,$f.FullName,$f.Name,[IO.Compression.CompressionLevel]::Optimal)}
    if($null -ne $stage){
     $native=Join-Path $stage.stage 'BlueLite_Logs'
     foreach($n in @('FinalWimDebloat.log','Health-26300.9818.txt','Inventory-26300.9818-after.json','ReleaseForbiddenAppResidues-26300.9818.txt','OfflineScript-Handoff-26300.9818.txt')){
      $f=Join-Path $native $n
      if(Test-Path -LiteralPath $f -PathType Leaf){[void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($z,$f,('native_stage/'+$n),[IO.Compression.CompressionLevel]::Optimal)}
     }
    }
   }finally{$z.Dispose()}
   Write-Host ('R028_EVIDENCE '+$evidence+' SHA256='+(HashBL $evidence))
  }catch{Write-Host ('R028_EVIDENCE_HOLD '+$_.Exception.Message)}
 }
}
if($status -eq 'HOLD'){exit 17}
exit 0
