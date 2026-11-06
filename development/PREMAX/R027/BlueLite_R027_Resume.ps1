# BlueLite R027 — source-bound resume for EXISTING v11.3 downloaded 26300.9818. DRAFT.
[CmdletBinding()]
param([ValidateSet('Preflight','Build','Verify')][string]$Mode='Preflight',[string]$UUPRoot='',[string]$Receipt='',[string]$Sha='')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
function Require([bool]$v,[string]$why){if(-not $v){throw ('R027_HOLD_'+$why)}}
function H([string]$p,[string]$alg='SHA256'){(Get-FileHash -LiteralPath $p -Algorithm $alg -ErrorAction Stop).Hash.ToUpperInvariant()}
function J([string]$p){Get-Content -LiteralPath $p -Raw -Encoding utf8|ConvertFrom-Json}
function F([string]$p){[IO.Path]::GetFullPath($p).TrimEnd([char]'\')}
function Put([string]$p,$o){$b=[Text.UTF8Encoding]::new($false).GetBytes(($o|ConvertTo-Json -Depth 15)+[Environment]::NewLine);$s=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$s.Write($b,0,$b.Length)}finally{$s.Dispose()}}
function Reparse([string]$p){$q=F $p;while([IO.Directory]::Exists($q)){Require (-not (([IO.File]::GetAttributes($q) -band [IO.FileAttributes]::ReparsePoint) -ne 0)) ('REPARSE_'+$q);$pa=[IO.Directory]::GetParent($q);if($null -eq $pa){break};$q=$pa.FullName}}
function Queue([string]$p,[int]$expected){
 Require (Test-Path -LiteralPath $p -PathType Leaf) ('QUEUE_MISSING_'+$p)
 $matches=[regex]::Matches([IO.File]::ReadAllText($p),'(?im)^\s*out=([^\r\n]+)\r?\n\s*checksum=sha-1=([a-f0-9]{40})\s*$')
 Require ($matches.Count -eq $expected) ('QUEUE_ROWS_'+$matches.Count+'_'+$expected)
 $result=@{};foreach($m in $matches){$name=$m.Groups[1].Value.Trim();Require ($name -match '^[^\\/:*?"<>|]+$' -and -not $name.Contains('..')) ('QUEUE_NAME_'+$name);Require (-not $result.ContainsKey($name)) ('DUPLICATE_QUEUE_'+$name);$result[$name]=$m.Groups[2].Value.ToUpperInvariant()}
 return $result
}
function CheckOriginal([string]$root){
 $files=@(Get-ChildItem -LiteralPath $root -File -Filter '*_convert.zip');Require ($files.Count -eq 1) 'ONE_ORIGINAL_ARCHIVE_REQUIRED'
 $zip=[IO.Compression.ZipFile]::OpenRead($files[0].FullName)
 try{$n=0;foreach($e in $zip.Entries){if($e.FullName.EndsWith('/')){continue};$rel=$e.FullName.Replace('/','\');Require ($rel -match '^[A-Za-z0-9_.\\-]+$' -and -not $rel.Contains('..')) 'UNSAFE_ORIGINAL_ZIP';$p=Join-Path $root $rel;Require (Test-Path -LiteralPath $p -PathType Leaf) ('VENDOR_MEMBER_MISSING_'+$rel);$s=$e.Open();try{$sha=[Security.Cryptography.SHA256]::Create();try{$v=[Convert]::ToHexString($sha.ComputeHash($s))}finally{$sha.Dispose()}}finally{$s.Dispose()};Require ($v -eq (H $p)) ('VENDOR_HASH_'+$rel);$n++};Require ($n -eq 11) ('VENDOR_COUNT_'+$n)}finally{$zip.Dispose()}
 return (H $files[0].FullName)
}
function Inspect([string]$root,[string]$logs){
 Require ($root.StartsWith('C:\work\',[StringComparison]::OrdinalIgnoreCase) -and -not ($root -match '\s')) 'UUP_ROOT_OUTSIDE_C_WORK_OR_SPACES'
 Reparse $root
 $rp=@(Get-ChildItem -LiteralPath $logs -File -Filter 'BlueLite_v11_3_FullDownload_*_OPDL_Report.json' | Where-Object {(J $_.FullName).status -eq 'DOWNLOADED_SHA1_PASS'})
 Require ($rp.Count -eq 1) ('OPDL_PASS_REPORT_COUNT_'+$rp.Count)
 $r=J $rp[0].FullName;$st=F ([string]$r.stage)
 Require ($r.build -eq '26300.9818' -and $r.payload_files -eq 130 -and $r.payload_bytes -eq 9143081111 -and $r.converter_started -eq $false) 'OPDL_WRONG_BUILD_OR_COUNT'
 Require ($st.StartsWith((F (Join-Path $root 'BlueLite_Work'))+'\',[StringComparison]::OrdinalIgnoreCase)) 'STAGE_OWNERSHIP'
 Require ((Split-Path $st -Leaf) -match '^BlueLite_Stage_v11_3_26300_9818_6c7bf258_[a-f0-9]{8}$') 'STAGE_NAME'
 Require (Test-Path -LiteralPath $st -PathType Container) 'STAGE_MISSING'
 Reparse $st
 $rec=Join-Path $logs ([string]$r.run_id+'_OPDL_Receipt.json')
 $ver=Join-Path $logs ([string]$r.run_id+'_OPDL_Verify.json')
 Require ((Test-Path $rec) -and (Test-Path $ver)) 'OPDL_CHAIN_MISSING'
 $a=J $rec;$v=J $ver
 Require ($a.status -eq 'PASS' -and $v.status -eq 'PASS' -and $a.run_id -eq $r.run_id -and $v.run_id -eq $r.run_id) 'OPDL_STATUS_CHAIN'
 Require ($a.report_sha256 -eq (H $rp[0].FullName) -and $v.report_sha256 -eq (H $rp[0].FullName) -and $v.receipt_sha256 -eq (H $rec)) 'OPDL_HASH_CHAIN'
 Require (-not (Test-Path (Join-Path $st 'ISOFOLDER')) -and -not (Test-Path (Join-Path $st 'BlueLite_Logs\ConvertStart.marker'))) 'CONVERSION_ALREADY_STARTED'
 Require (@(Get-ChildItem -LiteralPath $st -File -Filter '*.ISO').Count -eq 0) 'ISO_ALREADY_EXISTS'
 $conv=Join-Path $st 'convert-UUP.cmd'
 Require ((H $conv) -eq '32878E09B87C87FE25CC31AAAEA12D29A0FF18582A54EE69EBCDB0F2D6B36163') 'CONVERTER_SHA'
 Require ((H (Join-Path $st 'BlueLite\BlueLite_UUP.cmd')) -eq '37E18E6273ADF74176CFE6795CD52C39036CFCC056726E957F05081DA4A4AF18') 'ENGINE_SHA'
 $mf=Get-Content -LiteralPath (Join-Path $st 'BlueLite_Package_SHA256.txt')
 Require ($mf.Count -eq 55) 'STAGE_MANIFEST_COUNT'
 foreach($line in $mf){$m=[regex]::Match($line,'^([0-9A-Fa-f]{64}) \*(.+)$');Require $m.Success 'STAGE_MANIFEST_SYNTAX';$rel=$m.Groups[2].Value.Replace('/','\');Require ($rel -match '^[A-Za-z0-9_.\\-]+$' -and -not $rel.Contains('..')) 'STAGE_MANIFEST_PATH';Require ((H (Join-Path $st $rel)) -eq $m.Groups[1].Value.ToUpperInvariant()) ('STAGE_MANIFEST_SHA_'+$rel)}
 $cfg=Get-Content -LiteralPath (Join-Path $st 'ConvertConfig.ini') -Raw
 foreach($kv in @('AutoStart=1','AddUpdates=1','wim2esd=0','SkipISO=0','SkipWinRE=1','NetFx3=0')){$parts=$kv.Split('=');Require ($cfg -match ('(?m)^\s*'+$parts[0]+'\s*=\s*'+$parts[1]+'\s*$')) ('CONFIG_'+$kv)}
 Require ((J (Join-Path $st 'BlueLite_Logs\ResolvedUUP.json')).UUP_ID -eq '6c7bf258-2632-47dd-83ee-c23945978da1') 'SOURCE_UUID'
 $original=CheckOriginal $root
 $dir=Join-Path $st 'UUPs';$files=@(Get-ChildItem -LiteralPath $dir -File)
 $sum=[long]0;foreach($file in $files){$sum+=$file.Length}
 Require ($files.Count -eq 130 -and $sum -eq 9143081111) ('PAYLOAD_COUNT_BYTES_'+$files.Count+'_'+$sum)
 $windows=Queue (Join-Path $st 'BlueLite_Logs\WindowsQueue.original.txt') 98
 $apps=Queue (Join-Path $st 'BlueLite_Logs\AppsQueue.filtered.txt') 32
 foreach($key in $apps.Keys){if($windows.ContainsKey($key)){Require ($windows[$key] -eq $apps[$key]) 'CROSS_QUEUE_SHA_MISMATCH'}else{$windows[$key]=$apps[$key]}}
 Require ($windows.Count -eq 129) ('UNIQUE_SHA_ROWS_'+$windows.Count)
 $total=[long]0;foreach($key in $windows.Keys){$p=Join-Path $dir $key;Require (Test-Path -LiteralPath $p -PathType Leaf) ('PAYLOAD_MISSING_'+$key);Require ((H $p 'SHA1') -eq $windows[$key]) ('PAYLOAD_SHA1_'+$key);$total+=(Get-Item $p).Length}
 Require ($total -eq 9143080977) 'UNIQUE_SHA1_TOTAL'
 Require (@(Get-WindowsImage -Mounted -ErrorAction Stop).Count -eq 0) 'DISM_MOUNTS_PRESENT'
 Require (@(Get-Process -Name 'aria2c','dism','NTLite' -ErrorAction SilentlyContinue).Count -eq 0) 'PROCESS_CONFLICT'
 $free=[IO.DriveInfo]::new($st.Substring(0,3)).AvailableFreeSpace
 Require ($free -ge 25GB) ('DISK_FREE_LT_25GIB_'+$free)
 return [pscustomobject]@{stage=$st;run_id=$r.run_id;vendor_zip_sha256=$original;converter_sha256=(H $conv);files=130;bytes=$sum;unique_sha1=129;unique_bytes=$total;free_bytes=$free}
}
if($Mode -eq 'Verify'){
 Require ((H $Receipt) -eq $Sha.ToUpperInvariant()) 'RECEIPT_SHA'
 $j=J $Receipt
 Require ($j.status -eq 'PREFLIGHT_PASS' -and $j.source.unique_sha1 -eq 129) 'RECEIPT_STATUS'
 Write-Host 'R027_INDEPENDENT_RECEIPT_VERIFY_PASS'
 exit 0
}
if(-not $UUPRoot){$UUPRoot=$PSScriptRoot}
$root=F $UUPRoot;$logs=Join-Path $root 'BlueLite_Logs'
Require (Test-Path -LiteralPath $logs -PathType Container) 'ROOT_LOG_FOLDER_MISSING'
$tag='BlueLite_R027_'+[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffffffZ')+'_'+[Guid]::NewGuid().ToString('N').Substring(0,8)
$report=Join-Path $logs ($tag+'_PREFLIGHT.json')
$receipt=Join-Path $logs ($tag+'_RECEIPT.json')
$started=$false;$success=$false
try{
 $source=Inspect $root $logs
 Put $report ([ordered]@{schema='BlueLite.R027.Preflight.v1';status='PREFLIGHT_PASS';mode=$Mode;utc=[DateTime]::UtcNow.ToString('o');source=$source;one_next='FRESH_PS7_VERIFY'})
 Put $receipt ([ordered]@{schema='BlueLite.R027.Receipt.v1';status='PREFLIGHT_PASS';utc=[DateTime]::UtcNow.ToString('o');source=$source;report_sha256=(H $report);one_next='FRESH_PS7_VERIFY'})
 & pwsh.exe -NoProfile -NonInteractive -File $PSCommandPath -Mode Verify -Receipt $receipt -Sha (H $receipt)
 Require ($LASTEXITCODE -eq 0) 'INDEPENDENT_RECEIPT_VERIFY'
 Write-Host ('R027_PREFLIGHT_PASS '+$source.stage)
 if($Mode -eq 'Build'){
  $helper=Join-Path $root 'BlueLite_R027_CaptureImages.ps1'
  Require (Test-Path -LiteralPath $helper -PathType Leaf) 'CAPTURE_HELPER_MISSING'
  $staged=Join-Path $source.stage 'BlueLite\BlueLite_R027_CaptureImages.ps1'
  Require (-not (Test-Path -LiteralPath $staged)) 'CAPTURE_HELPER_ALREADY_INSTALLED'
  Copy-Item -LiteralPath $helper -Destination $staged -ErrorAction Stop
  Require ((H $staged) -eq (H $helper)) 'CAPTURE_HELPER_SHA_COPY'
  $converter=Join-Path $source.stage 'convert-UUP.cmd'
  $backup=Join-Path $logs ($tag+'_ORIGINAL_CONVERTER.cmd')
  Copy-Item -LiteralPath $converter -Destination $backup -ErrorAction Stop
  Require ((H $backup) -eq $source.converter_sha256) 'CONVERTER_BACKUP_SHA'
  $enc=[Text.Encoding]::GetEncoding(1252);$body=[IO.File]::ReadAllText($converter,$enc)
  $tail=$body.IndexOf(':finISO')
  Require ($tail -ge 0) 'FINISO_MISSING'
  $before=$body.Substring(0,$tail);$after=$body.Substring($tail)
  $rx='(?m)(\s*exit /b 92\s*\)\s*)(if %SkipISO% neq 0 \()'
  $matches=[regex]::Matches($after,$rx)
  Require ($matches.Count -eq 1) ('CAPTURE_ANCHOR_COUNT_'+$matches.Count)
  $nl=[Environment]::NewLine
  $hook='powershell -NoProfile -ExecutionPolicy Bypass -File "BlueLite\BlueLite_R027_CaptureImages.ps1" -StageRoot "."'+$nl+'if errorlevel 1 ('+$nl+'  echo [BlueLite ERROR] image capture failed; ISO stopped.'+$nl+'  exit /b 93'+$nl+')'+$nl
  $patched=$before+[regex]::Replace($after,$rx,('$1'+$hook+'$2'),1)
  [IO.File]::WriteAllText($converter,$patched,$enc)
  Require ((H $converter) -ne $source.converter_sha256) 'PATCH_NOT_APPLIED'
  Require ([IO.File]::ReadAllText($converter,$enc).Contains('BlueLite_R027_CaptureImages.ps1')) 'PATCH_READBACK_FAIL'
  Put (Join-Path $logs ($tag+'_PATCH.json')) ([ordered]@{status='PASS';source_converter_sha256=$source.converter_sha256;patched_sha256=(H $converter);helper_sha256=(H $staged);backup_sha256=(H $backup);one_next='ORIGINAL_CONVERTER_ONCE'})
  $started=$true
  Push-Location $source.stage
  try{$env:BLUELITE_DOWNLOAD_ONLY='';$env:BLUELITE_V7_IMAGE_AUTH='RUNTIME_USER_APPROVED'; & $env:ComSpec /d /c 'START-ENGINE-APPROVED.cmd';$exit=$LASTEXITCODE}
  finally{$env:BLUELITE_V7_IMAGE_AUTH='';Pop-Location}
  Require ($exit -eq 0) ('CONVERTER_EXIT_'+$exit)
  $images=Join-Path $source.stage 'BlueLite_FinalImages'
  $wim=Join-Path $images 'install.wim';$boot=Join-Path $images 'boot.wim'
  Require ((Test-Path $wim -PathType Leaf) -and (Test-Path $boot -PathType Leaf)) 'FINAL_WIMS_MISSING'
  $isos=@(Get-ChildItem -LiteralPath $source.stage -File -Filter '*.ISO')
  Require ($isos.Count -eq 1) ('ISO_COUNT_'+$isos.Count)
  Put (Join-Path $logs ($tag+'_BUILT.json')) ([ordered]@{status='IMAGE_BUILT_NOT_RELEASE';iso=$isos[0].FullName;iso_bytes=$isos[0].Length;iso_sha256=(H $isos[0].FullName);install_wim=$wim;install_wim_bytes=(Get-Item $wim).Length;install_wim_sha256=(H $wim);setup_boot_wim=$boot;boot_wim_sha256=(H $boot);release_certified=$false;one_next='RETURN_EVIDENCE'})
  Write-Host ('R027_IMAGE_BUILT_NOT_RELEASE_ISO_BYTES '+$isos[0].Length)
 }
 $success=$true
}catch{
 Put (Join-Path $logs ($tag+'_HOLD.json')) ([ordered]@{status='HOLD';reason=$_.Exception.Message;converter_started=$started;one_next='DO_NOT_RERUN_RETURN_EVIDENCE'})
 Write-Host ('R027_HOLD '+$_.Exception.Message)
}finally{
 try{$ev=Join-Path $logs ($tag+'_EVIDENCE.zip');$files=@(Get-ChildItem -LiteralPath $logs -File -Filter ($tag+'*') | Where-Object {$_.FullName -ne $ev});if($files.Count){Compress-Archive -LiteralPath @($files.FullName) -DestinationPath $ev -CompressionLevel Optimal};Write-Host ('R027_EVIDENCE '+$ev)}catch{Write-Host ('R027_EVIDENCE_PACK_HOLD '+$_.Exception.Message)}
}
if(-not $success){exit 17}
exit 0
