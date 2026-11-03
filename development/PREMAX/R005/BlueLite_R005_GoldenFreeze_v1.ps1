[CmdletBinding()]
param([ValidateSet('Run','VerifyHash','VerifyMedia','VerifyZip')][string]$Mode='Run',[string]$ReceiptPath='')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root='C:\work\26300.9818-UUP-MAX_PRE_26300_v4'
$logs='C:\work\logs'
$pwsh=(Get-Command pwsh.exe -ErrorAction Stop).Source
function New-Json([string]$path,[object]$obj) {
 if(Test-Path -LiteralPath $path){throw "IMMUTABLE_EXISTS $path"}
 $bytes=[Text.UTF8Encoding]::new($false).GetBytes(($obj|ConvertTo-Json -Depth 16))
 $f=[IO.File]::Open($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$f.Write($bytes,0,$bytes.Length)}finally{$f.Dispose()}
}
function Verify-Child([string]$mode,[string]$path) {
 & $pwsh -NoProfile -NonInteractive -File $PSCommandPath -Mode $mode -ReceiptPath $path
 if($LASTEXITCODE -ne 0){throw ("INDEPENDENT_VERIFY_HOLD "+$mode+" "+$path)}
}
function Check-Scope([string]$path,[string]$base) {
 $p=[IO.Path]::GetFullPath($path)
 $prefix=[IO.Path]::GetFullPath($base).TrimEnd('\')+'\'
 if(-not $p.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw "PATH_SCOPE_HOLD $path"}
}
if($Mode -eq 'VerifyHash') {
 $r=Get-Content -LiteralPath $ReceiptPath -Raw|ConvertFrom-Json
 if($r.schema -ne 'BlueLite.R005.Hash.v1' -or $r.verdict -ne 'PASS'){throw 'INVALID_HASH_RECEIPT'}
 Check-Scope ([string]$r.path) $root
 $f=Get-Item -LiteralPath ([string]$r.path) -ErrorAction Stop
 $h=(Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
 if($f.Length -ne [long]$r.bytes -or $h -ne [string]$r.sha256){throw "INDEPENDENT_HASH_OR_SIZE_MISMATCH $($r.name)"}
 if($r.expected -and $h -ne [string]$r.expected){throw 'KNOWN_SHA_MISMATCH'}
 New-Json ($ReceiptPath+'.verify.json') ([ordered]@{schema='BlueLite.R005.Verify.v1';operation='INDEPENDENT_HASH';verified_utc=[DateTime]::UtcNow.ToString('o');name=$r.name;sha256=$h;bytes=$f.Length;verdict='PASS'})
 Write-Output ("INDEPENDENT_HASH_PASS "+$r.name+" "+$h)
 exit 0
}
$isoName='26300.9818.261025-0959.26H2_GE_RELEASE_SVC_PROD3_CLIENTPRO_OEMRET_X64FRE_EN-US.ISO'
$iso=Join-Path $root $isoName
$wim=Join-Path $root 'install.wim'
$seven=Join-Path $root 'bin\7z.exe'
$wimlib=Join-Path $root 'bin\wimlib-imagex.exe'
function Get-Media {
 $x=@(& $seven l -ba $iso 2>&1);if($LASTEXITCODE -ne 0){throw 'ISO_7Z_LIST_FAILED'}
 $rows=@($x|ForEach-Object{[string]$_})
 $i=@($rows|Where-Object{$_ -match '\s+sources\\install\.wim\s*$'})
 $b=@($rows|Where-Object{$_ -match '\s+sources\\boot\.wim\s*$'})
 if($i.Count -ne 1 -or $b.Count -ne 1){throw 'BOOT_INSTALL_WIM_MEMBER_COUNT'}
 if($i[0] -notmatch '\s(\d+)\s+\d+\s+sources\\install\.wim\s*$'){throw 'INSTALL_SIZE_PARSE'}
 $in=[long]$Matches[1]
 if($b[0] -notmatch '\s(\d+)\s+\d+\s+sources\\boot\.wim\s*$'){throw 'BOOT_SIZE_PARSE'}
 $bo=[long]$Matches[1]
 $info=@(& $wimlib info $wim 1 2>&1);if($LASTEXITCODE -ne 0){throw 'WIMLIB_INFO_EXIT'}
 $text=($info|ForEach-Object{[string]$_}) -join [Environment]::NewLine
 if($text -notmatch 'Edition ID:\s+Professional' -or $text -notmatch 'Index:\s+1' -or $text -notmatch 'Architecture:\s+x86_64'){throw 'WIM_INDEX_EDITION_ARCH'}
 if($in -ne (Get-Item -LiteralPath $wim).Length -or $in -ne 5736092221 -or $bo -ne 824426219){throw 'ISO_WIM_IMAGE_BYTES'}
 return [ordered]@{index=1;edition='Professional';architecture='x86_64';install_bytes=$in;boot_bytes=$bo;iso_bytes=(Get-Item -LiteralPath $iso).Length;method='7z_list_and_wimlib_info';verdict='PASS'}
}
if($Mode -eq 'VerifyMedia') {
 $r=Get-Content -LiteralPath $ReceiptPath -Raw|ConvertFrom-Json
 if($r.schema -ne 'BlueLite.R005.Media.v1'){throw 'MEDIA_RECEIPT_SCHEMA'}
 $m=Get-Media
 if($m.install_bytes -ne [long]$r.media.install_bytes -or $m.boot_bytes -ne [long]$r.media.boot_bytes -or $m.iso_bytes -ne [long]$r.media.iso_bytes){throw 'INDEPENDENT_MEDIA_MISMATCH'}
 New-Json ($ReceiptPath+'.verify.json') ([ordered]@{schema='BlueLite.R005.Verify.v1';operation='INDEPENDENT_MEDIA';verified_utc=[DateTime]::UtcNow.ToString('o');media=$m;verdict='PASS'})
 Write-Output 'INDEPENDENT_MEDIA_BOOT_WIM_INDEX_PASS'
 exit 0
}
if($Mode -eq 'VerifyZip') {
 Add-Type -AssemblyName System.IO.Compression
 Check-Scope $ReceiptPath $logs
 $z=[IO.Compression.ZipFile]::OpenRead($ReceiptPath)
 try {
  $entry=$z.GetEntry('MANIFEST.sha256')
  if(-not $entry){throw 'ZIP_HASH_MANIFEST_ABSENT'}
  $rd=[IO.StreamReader]::new($entry.Open())
  try{$m=$rd.ReadToEnd()}finally{$rd.Dispose()}
  $known=@{}
  foreach($line in [regex]::Split($m,'\r?\n')){
   if(-not $line){continue}
   if($line -notmatch '^([0-9A-F]{64}) \*(.+)$'){throw 'BAD_MANIFEST_LINE'}
   $known[$Matches[2]]=$Matches[1]
  }
  $num=0
  foreach($e in $z.Entries){
   if($e.FullName -eq 'MANIFEST.sha256'){continue}
   if(-not $known.ContainsKey($e.FullName)){throw "UNKNOWN_MEMBER $($e.FullName)"}
   $sha=[Security.Cryptography.SHA256]::Create();$stream=$e.Open()
   try{$h=[Convert]::ToHexString($sha.ComputeHash($stream))}finally{$stream.Dispose();$sha.Dispose()}
   if($h -ne $known[$e.FullName]){throw "ZIP_MEMBER_SHA_MISMATCH $($e.FullName)"}
   $num++
  }
  if($num -ne $known.Count -or $num -lt 21){throw "ZIP_MEMBERS_HOLD $num"}
  Write-Output ("INDEPENDENT_ZIP_MEMBER_SHA_PASS count={0} sha256={1}" -f $num,(Get-FileHash -LiteralPath $ReceiptPath -Algorithm SHA256).Hash)
 } finally{$z.Dispose()}
 exit 0
}
if($Mode -ne 'Run'){throw 'UNKNOWN_MODE'}
if(-not(Test-Path -LiteralPath $root -PathType Container)){throw 'GOLDEN_ROOT_NOT_FOUND'}
if(-not(Test-Path -LiteralPath $logs -PathType Container)){throw 'LOGS_FOLDER_NOT_FOUND'}
$utc=[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
$run='BlueLite_R005_GoldenFreeze_'+$utc+'_'+[Guid]::NewGuid().ToString('N').Substring(0,8)
$work=Join-Path $logs $run
New-Item -ItemType Directory -Path $work -ErrorAction Stop|Out-Null
$items=[ordered]@{
 '01_UUP_ZIP'=@('26300.9818_amd64_en-us_professional_6c7bf258_convert.zip','8117C725C1EF9C8F5C73C5A22887DB38C222C373ED601C94D24DC9109AFEDEF8',8218)
 '02_UUP_LAUNCHER'=@('uup_download_windows.cmd','838619DB9AEC53A1D0F111967FE04965852BD7A28F58611C6236FCE086C2D42D',0)
 '03_BL_V4_OVERLAY'=@('BlueLite_MAXPRE_26300_Universal_v4_20261103.zip','0CBA819F2F1A88659DD884633920E6D3F8FFF9C7E1AE8D3C89CC724183C88922',56784)
 '04_RUNTIME_EVIDENCE'=@('BlueLite_EVIDENCE_20261103T160115024Z.zip','D64DAD834847DE4CD4FA577D51ED25158085B29D3A81BF073697B673A14D3905',584084)
 '05_ORIGINAL_CONVERTER'=@('convert-UUP.cmd.prebluelite-v1.bak','',0)
 '06_PATCHED_CONVERTER'=@('convert-UUP.cmd','',0)
 '07_CONVERTER_CONFIG'=@('ConvertConfig.ini','',0)
 '08_BL_PROFILE'=@('BlueLite\BlueLite_Profile.ini','',0)
 '09_FINAL_INSTALL_WIM'=@('install.wim','3D606513D9C1D2B157AAFD6925FF1655C9A48520CE5D4219AF2ED654C82753E4',5736092221)
 '10_FINAL_ISO'=@($isoName,'',6822354944)
}
$errorText=''
try {
 foreach($key in $items.Keys){
  $props=$items[$key];$p=Join-Path $root ([string]$props[0])
  Check-Scope $p $root
  $f=Get-Item -LiteralPath $p -ErrorAction Stop
  $sha=(Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
  if($props[1] -and $sha -ne [string]$props[1]){throw "KNOWN_SHA_MISMATCH $key"}
  if([long]$props[2] -gt 0 -and $f.Length -ne [long]$props[2]){throw "KNOWN_SIZE_MISMATCH $key"}
  $r=Join-Path $work ($key+'.json')
  New-Json $r ([ordered]@{schema='BlueLite.R005.Hash.v1';utc=[DateTime]::UtcNow.ToString('o');operation='HASH';name=$key;path=$f.FullName;bytes=$f.Length;sha256=$sha;expected=[string]$props[1];readonly=$true;verdict='PASS';one_next='fresh_process_verify'})
  Verify-Child 'VerifyHash' $r
 }
 $media=Get-Media
 $r=Join-Path $work '11_WIM_ISO_LAYOUT.json'
 New-Json $r ([ordered]@{schema='BlueLite.R005.Media.v1';utc=[DateTime]::UtcNow.ToString('o');operation='MEDIA';media=$media;verdict='PASS';one_next='fresh_process_verify'})
 Verify-Child 'VerifyMedia' $r
 $result=@(& $seven t $iso 2>&1)
 if($LASTEXITCODE -ne 0){throw '7Z_FULL_ISO_TEST_EXIT_NONZERO'}
 if(-not (($result|ForEach-Object{[string]$_}) -join [Environment]::NewLine).Contains('Everything is Ok')){throw '7Z_FULL_ISO_TEST_NO_OK'}
 New-Json (Join-Path $work '12_ISO_FULL_READ_TEST.json') ([ordered]@{schema='BlueLite.R005.Test.v1';utc=[DateTime]::UtcNow.ToString('o');operation='ISO_FULL_7Z_TEST';native_exit=0;native_marker='Everything is Ok';iso_sha256=(Get-Content -LiteralPath (Join-Path $work '10_FINAL_ISO.json') -Raw|ConvertFrom-Json).sha256;verdict='PASS'})
}catch{
 $errorText=$_.Exception.Message
 New-Json (Join-Path $work '99_HOLD.json') ([ordered]@{schema='BlueLite.R005.Hold.v1';utc=[DateTime]::UtcNow.ToString('o');reason=$errorText;verdict='HOLD'})
}
$contents=@(Get-ChildItem -LiteralPath $work -File|Sort-Object Name)
$manifestPath=Join-Path $work 'MANIFEST.sha256'
$lines=@($contents|ForEach-Object{('{0} *{1}' -f (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash,$_.Name)})
[IO.File]::WriteAllLines($manifestPath,$lines,[Text.UTF8Encoding]::new($false))
$contents=@(Get-ChildItem -LiteralPath $work -File)
$zip=Join-Path $logs ($run+'.zip')
Compress-Archive -LiteralPath @($contents.FullName) -DestinationPath $zip -CompressionLevel Optimal
Verify-Child 'VerifyZip' $zip
if($errorText){Write-Output ("R005_GOLDEN_HOLD ZIP={0} SHA256={1} ERROR={2}" -f $zip,(Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash,$errorText);exit 30}
Remove-Item -LiteralPath $work -Recurse -Force
Write-Output ("R005_GOLDEN_FREEZE_PASS ZIP={0} SHA256={1}" -f $zip,(Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash)
