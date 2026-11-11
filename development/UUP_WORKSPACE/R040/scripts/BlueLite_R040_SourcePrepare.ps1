# BlueLite R040 portable original-UUP source adapter. Version 1.0.
# Purpose: SHA-verify ONE genuine adjacent 26300.x UUP Dump ZIP and extract only missing
# untouched vendor bootstrap files. Never executes source launcher or renaming CMD.
[CmdletBinding()]
param(
 [ValidateSet('Check','Prepare','Verify')][string]$Mode='Prepare',
 [string]$PackageRoot=$PSScriptRoot,
 [string]$OriginalArchive=''
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression
$Root=[IO.Path]::GetFullPath($PackageRoot).TrimEnd([char]92,[char]47)
$LogRoot='C:\work\logs'
function Need([bool]$OK,[string]$Message){if(-not $OK){throw $Message}}
function Sha([string]$P){(Get-FileHash -LiteralPath $P -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()}
function HashStream([IO.Stream]$S){[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($S))}
function CheckOverlay {
 $manifest=Join-Path $Root 'BlueLite_Package_SHA256.txt'
 Need ([IO.File]::Exists($manifest)) 'MISSING_BL_PACKAGE_SHA256_MANIFEST'
 $count=0
 $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 foreach($line in [IO.File]::ReadAllLines($manifest)){
  if(-not $line.Trim()){continue}
  $m=[regex]::Match($line,'^([A-Fa-f0-9]{64}) \*(.+)$')
  Need $m.Success 'BAD_PACKAGE_MANIFEST_ROW'
  $n=$m.Groups[2].Value.Replace('/','\')
  Need ($n -match '^[A-Za-z0-9_.+\\-]+$' -and -not $n.Contains('..') -and -not [IO.Path]::IsPathRooted($n) -and $seen.Add($n)) ('BAD_MANIFEST_PATH '+$n)
  $p=[IO.Path]::GetFullPath((Join-Path $Root $n))
  Need ($p.StartsWith(($Root+'\'),[StringComparison]::OrdinalIgnoreCase) -and [IO.File]::Exists($p)) ('MISSING_MANIFEST_FILE '+$n)
  Need ((Sha $p) -eq $m.Groups[1].Value.ToUpperInvariant()) ('OVERLAY_HASH_MISMATCH '+$n)
  $count++
 }
 Need ($count -ge 45 -and $seen.Contains('PRE_MAX.cmd') -and $seen.Contains('BlueLite_R040_SourcePrepare.ps1')) 'R040_MANIFEST_INCOMPLETE'
 return $count
}
function FindVendor {
 if($OriginalArchive){
  $p=[IO.Path]::GetFullPath($OriginalArchive)
  Need ([IO.File]::Exists($p) -and [IO.Path]::GetDirectoryName($p) -ieq $Root) 'VENDOR_ZIP_MUST_BE_ADJACENT'
  $c=@([IO.FileInfo]::new($p))
 } else {
  $c=@(Get-ChildItem -LiteralPath $Root -File -Filter '*_convert.zip' |
    Where-Object { $_.Name -match '^26300\.\d+_(?:amd64|x64)_en-us_professional_[a-f0-9]{8}_convert\.zip$' })
 }
 Need ($c.Count -eq 1) ('EXACTLY_ONE_ADJACENT_26300_UUP_ORIGINAL_REQUIRED_FOUND_'+$c.Count)
 $zip=[IO.FileInfo]$c[0]
 Need ($zip.Length -gt 2000 -and $zip.Length -lt 20971520) 'VENDOR_ZIP_UNEXPECTED_BYTES'
 return $zip.FullName
}
function AnalyzeVendor([string]$Archive){
 $z=[IO.Compression.ZipFile]::OpenRead($Archive)
 try{
  Need ($z.Entries.Count -ge 11 -and $z.Entries.Count -le 100) 'VENDOR_MEMBER_COUNT_OUTSIDE_EXPECTED_RANGE'
  $members=[Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
  $total=0L
  $body=''
  foreach($e in $z.Entries){
   Need (-not $e.FullName.EndsWith('/')) 'VENDOR_DIRECTORY_ENTRIES_UNEXPECTED'
   $name=$e.FullName.Replace('\','/')
   Need ($name -match '^[A-Za-z0-9_.+/-]+$' -and -not $name.Contains('..') -and -not $name.StartsWith('/') -and -not $members.ContainsKey($name)) ('UNSAFE_OR_DUPLICATE_VENDOR_ENTRY '+$name)
   $total+=[long]$e.Length
   Need ($total -le 104857600 -and $e.Length -le 10485760) 'VENDOR_EXPANDED_SIZE_LIMIT'
   $fmode=($e.ExternalAttributes -shr 16) -band 61440
   Need ($fmode -ne 40960) 'VENDOR_SYMLINK_NOT_SUPPORTED'
   $s=$e.Open()
   try{$digest=HashStream $s}finally{$s.Dispose()}
   $members.Add($name,[pscustomobject]@{entry=$e;bytes=[long]$e.Length;sha256=$digest})
  }
  foreach($required in @('uup_download_windows.cmd','uup_download_linux.sh','uup_download_macos.sh','ConvertConfig.ini','CustomAppsList.txt','files/get_aria2.ps1','files/converter_windows','files/converter_multi')){
   Need ($members.ContainsKey($required)) ('REQUIRED_ORIGINAL_MEMBER_MISSING '+$required)
  }
  $sr=[IO.StreamReader]::new($members['uup_download_windows.cmd'].entry.Open())
  try{$body=$sr.ReadToEnd()}finally{$sr.Dispose()}
  Need ($body -notmatch '(?i)BlueLite') 'ALREADY_MUTATED_VENDOR_LAUNCHER'
  $title=[regex]::Match($body,'(?im)^\s*title\s+(26300\.\d+)_(?:amd64|x64)_en-us_professional(?=[_\s]|$)')
  Need $title.Success 'VENDOR_BUILD_TITLE_NOT_PROVEN'
  $zipName=[IO.Path]::GetFileName($Archive)
  Need ($zipName.StartsWith(($title.Groups[1].Value+'_'),[StringComparison]::OrdinalIgnoreCase)) 'VENDOR_BUILD_TITLE_FILENAME_MISMATCH'
  $urls=[regex]::Matches($body,'(?i)https://uupdump\.net/get\.php\?[^"\r\n]+')
  Need ($urls.Count -ge 2) 'SOURCE_GETPHP_URLS_MISSING'
  $ids=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  foreach($match in $urls){
   $m=[regex]::Match($match.Value,'(?i)[?&]id=([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})(?:_rev\.\d+)?(?:&|$)')
   Need $m.Success 'SOURCE_UUID_NOT_PROVEN'
   [void]$ids.Add($m.Groups[1].Value)
  }
  Need ($ids.Count -eq 1) 'WINDOWS_APPS_SOURCE_UUID_CONFLICT'
  $uuid=@($ids)[0].ToLowerInvariant()
  $suffix=[regex]::Match($zipName,'(?i)_([a-f0-9]{8})_convert\.zip$')
  Need ($suffix.Success -and $uuid.StartsWith($suffix.Groups[1].Value,[StringComparison]::OrdinalIgnoreCase)) 'ZIP_UUID_PREFIX_CONFLICT'
  return [pscustomobject]@{members=$members;build=$title.Groups[1].Value;uuid=$uuid;memberCount=$members.Count}
 }finally{$z.Dispose()}
}
function ValidateOnDisk([string]$Archive,$Data,[bool]$WriteMissing){
 $pending=[Collections.Generic.List[string]]::new()
 foreach($name in @($Data.members.Keys)){
  $expected=$Data.members[$name]
  $p=[IO.Path]::GetFullPath((Join-Path $Root ($name.Replace('/','\'))))
  Need ($p.StartsWith(($Root+'\'),[StringComparison]::OrdinalIgnoreCase)) ('VENDOR_DEST_ESCAPE '+$name)
  if([IO.File]::Exists($p)){
   Need (([IO.FileInfo]::new($p)).Length -eq $expected.bytes -and (Sha $p) -eq $expected.sha256) ('EXTRACTED_VENDOR_CONFLICT_NEVER_OVERWRITE '+$name)
  }else{
   [void]$pending.Add($name)
  }
 }
 if($WriteMissing -and $pending.Count -gt 0){
  $z=[IO.Compression.ZipFile]::OpenRead($Archive)
  try{
   foreach($name in $pending){
    $entry=@($z.Entries|Where-Object {$_.FullName.Replace('\','/') -ieq $name})
    Need ($entry.Count -eq 1) ('VENDOR_ENTRY_MISSING_ON_FRESH_READ '+$name)
    $p=[IO.Path]::GetFullPath((Join-Path $Root ($name.Replace('/','\'))))
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($p))|Out-Null
    $stream=$entry[0].Open();$f=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try{$stream.CopyTo($f)}finally{$f.Dispose();$stream.Dispose()}
    Need ((Sha $p) -eq $Data.members[$name].sha256) ('POST_EXTRACT_HASH_MISMATCH '+$name)
   }
  }finally{$z.Dispose()}
 }
 return $pending.Count
}
try{
 Need ($PSVersionTable.PSVersion.Major -ge 7) 'POWERSHELL7_REQUIRED'
 Need ([IO.Directory]::Exists($Root)) 'PACKAGE_ROOT_MISSING'
 Need (-not $Root.Contains(' ')) 'ORIGINAL_CONVERTER_REQUIRES_PATH_WITHOUT_SPACES'
 $overlayCount=CheckOverlay
 $archive=FindVendor
 $data=AnalyzeVendor $archive
 $pending=ValidateOnDisk $archive $data ($Mode -eq 'Prepare')
 if($Mode -eq 'Verify'){Need ($pending -eq 0) ('VENDOR_NOT_FULLY_EXTRACTED_'+$pending)}
 $status=if($Mode -eq 'Prepare'){'R040_VENDOR_SOURCE_PREPARED_SHA_PASS'}elseif($Mode -eq 'Verify'){'R040_INDEPENDENT_FRESH_SOURCE_VERIFY_PASS'}else{'R040_VENDOR_BOOTSTRAP_CHECK_PASS'}
 $receipt=[ordered]@{
  schema='BlueLite.R040.PortableVendorPrepare.v1';utc=[datetime]::UtcNow.ToString('o');status=$status;mode=$Mode
  original_archive=$archive;original_zip_sha256=(Sha $archive);build=$data.build;uuid=$data.uuid
  members=$data.memberCount;new_members_to_extract=$pending;overlay_manifest_members=$overlayCount
  source_contract='ORIGINAL_UUP_VENDOR_PLUS_OPTIONAL_D4_DERIVED_NOT_INDEPENDENT'
  new_windows_uup_payload_downloaded=$false;original_zip_mutated=$false
  one_next=if($Mode -eq 'Prepare'){'SEPARATE_FRESH_VERIFY_BEFORE_ENGINE_BUILD'}else{'FACTORY_STAGE_OR_OPERATOR_DECISION'}
 }
 if($Mode -ne 'Check'){
  [IO.Directory]::CreateDirectory($LogRoot)|Out-Null
  $p=Join-Path $LogRoot ('R040_VENDOR_'+$Mode+'_'+[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffffffZ')+'_'+[Guid]::NewGuid().ToString('N').Substring(0,8)+'.json')
  $json=($receipt|ConvertTo-Json -Depth 7)+"`n"
  $b=[Text.UTF8Encoding]::new($false).GetBytes($json)
  $stream=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
  try{$stream.Write($b,0,$b.Length)}finally{$stream.Dispose()}
  $receipt['receipt_path']=$p
 }
 Write-Output ($receipt|ConvertTo-Json -Compress -Depth 7)
 exit 0
}catch{
 [Console]::Error.WriteLine('R040_VENDOR_SOURCE_HOLD: '+$_.Exception.Message)
 exit 17
}
