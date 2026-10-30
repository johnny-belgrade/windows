# BlueLite R003 P0 v1: original UUP ZIP universal 26300.x source audit / SMALL FIXTURE PREPARE ONLY.
# Does NOT download, run original launcher/converter, change WIM, or build ISO.
# Prepared workspace contains overlay *proposals*, not an executable conversion package.
[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$OriginalZipPath,
 [Parameter(Mandatory)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$ExpectedZipSha256,
 [Parameter(Mandatory)][ValidatePattern('^26300\.[0-9]+$')][string]$DeclaredBuild,
 [Parameter(Mandatory)][string]$ExpectedUuid,
 [ValidateSet('Audit','PrepareSmallFixture')][string]$Mode='Audit',
 [ValidateSet('PREISO','ISO')][string]$OutputMode='PREISO',
 [string]$FixturePath=''
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Guard([bool]$Good,[string]$Code) { if(-not $Good){throw ('R003_P0_HOLD_'+$Code)} }
function TextMember([IO.Compression.ZipArchive]$Arc,[string]$Name) {
 $hit=@($Arc.Entries | Where-Object {$_.FullName -ieq $Name})
 Guard ($hit.Count -eq 1) ('ZIP_MEMBER_'+$Name)
 $sr=[IO.StreamReader]::new($hit[0].Open(),[Text.UTF8Encoding]::new($false),$true)
 try{return $sr.ReadToEnd()}finally{$sr.Dispose()}
}
function Query([uri]$Uri,[string]$Key) {
 $v=@{}
 foreach($segment in $Uri.Query.TrimStart('?').Split('&')){
  $a=$segment.Split('=',2)
  if($a.Count -eq 2){if($v.ContainsKey($a[0])){throw 'R003_P0_HOLD_DUPLICATE_QUERY_KEY'};$v[$a[0]]=[uri]::UnescapeDataString($a[1])}
 }
 if($v.ContainsKey($Key)){return [string]$v[$Key]}
 return ''
}
function WriteNew([string]$Path,[string]$Value) {
 $b=[Text.UTF8Encoding]::new($false).GetBytes($Value)
 $fs=[IO.FileStream]::new($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$fs.Write($b,0,$b.Length);$fs.Flush($true)}finally{$fs.Dispose()}
}
Guard ($PSVersionTable.PSVersion.Major -ge 7) 'PS7_REQUIRED'
Guard ($ExpectedUuid -match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$') 'UUID_FORMAT'
$zipPath=[IO.Path]::GetFullPath($OriginalZipPath)
Guard ([IO.File]::Exists($zipPath)) 'ZIP_MISSING'
Guard (-not ((Get-Item -LiteralPath $zipPath).Attributes.HasFlag([IO.FileAttributes]::ReparsePoint))) 'ZIP_REPARSE'
$actual=(Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash
Guard ($actual -eq $ExpectedZipSha256.ToUpperInvariant()) 'ZIP_SHA_MISMATCH'
Add-Type -AssemblyName System.IO.Compression
$zip=[IO.Compression.ZipFile]::OpenRead($zipPath)
try {
 $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 foreach($entry in $zip.Entries){
  $name=$entry.FullName.Replace('\','/')
  Guard (-not [string]::IsNullOrWhiteSpace($name) -and -not $name.StartsWith('/') -and -not $name.Contains(':') -and -not ($name -match '(^|/)\.\.(/|$)') -and -not $name.StartsWith('./')) 'ZIP_TRAVERSAL'
  Guard ($seen.Add($name)) 'ZIP_DUPLICATE'
  $zipUnixType=($entry.ExternalAttributes -shr 16) -band 61440
  Guard ($zipUnixType -ne 40960) 'ZIP_SYMLINK'
 }
 $required=@('uup_download_windows.cmd','ConvertConfig.ini','CustomAppsList.txt','files/converter_windows','files/get_aria2.ps1')
 foreach($r in $required){Guard ($seen.Contains($r)) ('ZIP_REQUIRED_'+$r)}
 $launch=TextMember $zip 'uup_download_windows.cmd'
 $ini=TextMember $zip 'ConvertConfig.ini'
 $apps=TextMember $zip 'CustomAppsList.txt'
 $converter=TextMember $zip 'files/converter_windows'
 Guard ($launch -notmatch 'BlueLite v1\.0|BlueLite TEST|BlueLite Universal') 'SOURCE_LAUNCHER_MODIFIED'
 $links=@([regex]::Matches($launch,'https://uupdump\.net/get\.php\?[^"\s]+') | ForEach-Object {$_.Value} | Select-Object -Unique)
 $win=@($links | Where-Object {
  $u=[uri]$_
  $u.Scheme -eq 'https' -and $u.Host -eq 'uupdump.net' -and $u.AbsolutePath -eq '/get.php' -and
  (Query $u 'edition') -ieq 'professional' -and (Query $u 'pack') -ieq 'en-us' -and
  (Query $u 'id') -ieq $ExpectedUuid
 })
 Guard ($win.Count -eq 1) 'EXACT_ORIGINAL_WINDOWS_URI'
 Guard ((Query ([uri]$win[0]) 'aria2') -eq '2') 'UNSUPPORTED_SOURCE_ARIA2'
 $buildHint=[regex]::Match($launch,'(?<!\d)(26300\.[0-9]+)(?!\d)')
 if($buildHint.Success){Guard ($buildHint.Value -ceq $DeclaredBuild) 'BUILD_HINT_DISAGREES'}
 $cv=[regex]::Match($converter,'(?im)^https://uupdump\.net/misc/(uup-converter-wimlib-v[0-9]+[a-z]*\.7z)\s*$')
 Guard ($cv.Success) 'ORIGINAL_CONVERTER_URL'
 $blocks=@($converter -split '(?:\r?\n){2,}')
 $block=@($blocks|Where-Object {$_ -match [regex]::Escape($cv.Groups[1].Value)})
 Guard ($block.Count -eq 1) 'CONVERTER_BLOCK_AMBIGUOUS'
 $sha=[regex]::Match($block[0],'(?im)^\s*checksum=sha-256=([a-f0-9]{64})\s*$')
 Guard $sha.Success 'CONVERTER_SHA_MISSING'
 $mandatory=@('Microsoft.SecHealthUI_8wekyb3d8bbwe','Microsoft.DesktopAppInstaller_8wekyb3d8bbwe','Microsoft.WindowsCalculator_8wekyb3d8bbwe','Microsoft.WindowsNotepad_8wekyb3d8bbwe','Microsoft.Windows.Photos_8wekyb3d8bbwe')
 foreach($app in $mandatory){Guard ($apps -match ('(?im)^\s*#?\s*'+[regex]::Escape($app)+'\s*$')) ('REQUIRED_APP_NOT_DECLARED_'+$app)}
 $changes=@{'AutoStart'='1';'AddUpdates'='1';'Cleanup'='1';'ResetBase'='0';'NetFx3'='0';'SkipISO'=$(if($OutputMode -eq 'PREISO'){'1'}else{'0'});'SkipWinRE'='0';'wim2esd'='0';'wim2swm'='0';'SkipApps'='0';'StubAppsFull'='1';'CustomList'='1'}
 $seenKeys=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 $outputIni=[Collections.Generic.List[string]]::new()
 foreach($line in ($ini -split '\r?\n')){
  $m=[regex]::Match($line,'^\s*([a-zA-Z][a-zA-Z0-9]*)\s*=\s*[^;#]*$')
  if($m.Success -and $changes.ContainsKey($m.Groups[1].Value)){
   $k=$m.Groups[1].Value
   Guard ($seenKeys.Add($k)) ('INI_DUPLICATE_'+$k)
   $outputIni.Add(($k+'='+$changes[$k]))
  }else{$outputIni.Add($line)}
 }
 foreach($k in $changes.Keys){Guard ($seenKeys.Contains($k)) ('INI_KEY_MISSING_'+$k)}
 $active=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 $outputApps=[Collections.Generic.List[string]]::new()
 foreach($line in ($apps -split '\r?\n')){
  $m=[regex]::Match($line,'^\s*#?\s*([A-Za-z0-9.\-]+_[A-Za-z0-9]+)\s*$')
  if($m.Success){
   $name=$m.Groups[1].Value
   if($mandatory -contains $name){Guard ($active.Add($name)) 'DUPLICATE_REQUIRED_APP';$outputApps.Add($name)}
   else{$outputApps.Add(('# '+$name))}
  }else{$outputApps.Add($line)}
 }
 Guard ($active.Count -eq 5) 'STAGING_APPS_COUNT'
 $report=[ordered]@{
  schema='BlueLite.R003.P0.SourceAudit.v1';mode=$Mode;status='SOURCE_AUDIT_ONLY'
  original_zip_path=$zipPath;original_zip_sha256=$actual;declared_build=$DeclaredBuild
  build_verified_from_original_launcher=$buildHint.Success;exact_uuid=$ExpectedUuid
  source_architecture='amd64';source_language='en-us';source_edition='professional'
  upstream_zip_members=$seen.Count;vendor_converter=$cv.Groups[1].Value;vendor_archive_declared_sha256=$sha.Groups[1].Value.ToUpperInvariant()
  native_app_staging=5;output_mode=$OutputMode;installed_winre='PRESERVE_UNTIL_VERIFIED_SKIPWINRE_REVIEW'
  original_source_immutable=$true;network_allowed=$false;converter_execution_allowed=$false;wim_iso_mutation_allowed=$false
  exact_uuid_metadata_gate='PENDING_UNTIL_CURRENT_SOURCE_METADATA_VERIFIED';one_next='Review source/config proposal, then approved runtime integration lane'
 }
 if($Mode -eq 'PrepareSmallFixture'){
  Guard (-not [string]::IsNullOrWhiteSpace($FixturePath)) 'FIXTURE_PATH_MISSING'
  $base='C:\work\PREMAX-work\R003_Universal26300_P0_MVP\04_StaticTests\'
  $dest=[IO.Path]::GetFullPath($FixturePath).TrimEnd('\')
  Guard ($dest.StartsWith($base,[StringComparison]::OrdinalIgnoreCase)) 'FIXTURE_OUTSIDE_OWNED_ROOT'
  Guard (-not [IO.Directory]::Exists($dest) -and -not [IO.File]::Exists($dest)) 'FIXTURE_ALREADY_EXISTS'
  [IO.Directory]::CreateDirectory($dest) | Out-Null
  foreach($entry in $zip.Entries){
   $name=$entry.FullName.Replace('/','\')
   $target=[IO.Path]::GetFullPath((Join-Path $dest $name))
   Guard ($target.StartsWith(($dest+'\'),[StringComparison]::OrdinalIgnoreCase)) 'ZIP_DEST_OUTSIDE'
   if($entry.Name -eq ''){[IO.Directory]::CreateDirectory($target)|Out-Null;continue}
   [IO.Directory]::CreateDirectory(([IO.Path]::GetDirectoryName($target)))|Out-Null
   $input=$entry.Open()
   $output=[IO.FileStream]::new($target,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
   try{$input.CopyTo($output);$output.Flush($true)}finally{$output.Dispose();$input.Dispose()}
  }
  $overlay=Join-Path $dest 'BlueLite'
  [IO.Directory]::CreateDirectory($overlay)|Out-Null
  WriteNew (Join-Path $overlay 'ConvertConfig.BlueLite.proposed.ini') (($outputIni -join [Environment]::NewLine)+[Environment]::NewLine)
  WriteNew (Join-Path $overlay 'CustomAppsList.BlueLite.proposed.txt') (($outputApps -join [Environment]::NewLine)+[Environment]::NewLine)
  WriteNew (Join-Path $overlay 'SourceAudit.json') (($report|ConvertTo-Json -Depth 5)+[Environment]::NewLine)
  Guard ((Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash -eq $actual) 'ORIGINAL_ZIP_POST_SHA'
  Write-Output ('R003_SMALL_FIXTURE_PREPARED;MEMBERS='+$seen.Count+';NO_NETWORK=TRUE;NO_CONVERTER=TRUE')
 }else{Write-Output ('R003_P0_SOURCE_AUDIT=PASS;MEMBERS='+$seen.Count+';CONVERTER='+$cv.Groups[1].Value+';NO_NETWORK=TRUE;NO_WIM=TRUE')}
 Write-Output ($report|ConvertTo-Json -Compress -Depth 5)
}
finally{$zip.Dispose()}
