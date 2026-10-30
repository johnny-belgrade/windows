# BlueLite R003-S03: Bounded original UUP ZIP fixture extraction.
# Standalone v3; no converter, downloader, WIM/ISO, registry or v2 source mutation.
[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$OriginalZipPath,
  [Parameter(Mandatory)][ValidatePattern('^[0-9a-fA-F]{64}$')][string]$ExpectedZipSha256,
  [Parameter(Mandatory)][ValidatePattern('^26300\.[0-9]+$')][string]$DeclaredBuild,
  [Parameter(Mandatory)][ValidatePattern('^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$')][string]$ExpectedUuid,
  [ValidateSet('Audit','PrepareSmallFixture')][string]$Mode='Audit',
  [string]$FixturePath=''
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Guard([bool]$Ok,[string]$Code) {
  if (-not $Ok) { throw ('R003_V3_HOLD_'+$Code) }
}
function FileHash([string]$Path) {
  (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()
}
function WriteNew([string]$Path,[string]$Text) {
  $bytes=[Text.UTF8Encoding]::new($false).GetBytes($Text)
  $fs=[IO.FileStream]::new($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
  try { $fs.Write($bytes,0,$bytes.Length);$fs.Flush($true) } finally { $fs.Dispose() }
}
Guard ($PSVersionTable.PSVersion.Major -ge 7) 'PS7_REQUIRED'
$root='C:\work\PREMAX-work\R003_Universal26300_P0_MVP'
$v2=Join-Path $root '03_Drafts\R003_P0_UniversalUUP_v2_DRAFT.ps1'
Guard ([IO.File]::Exists($v2)) 'PINNED_V2_MISSING'
Guard ((FileHash $v2) -eq '6FD8A3A511CA161967E20749FDDB47CC63E3E5AD0E049BECAADD048A0ACE933C') 'PINNED_V2_SHA_DRIFT'
$original=[IO.Path]::GetFullPath($OriginalZipPath)
Guard ([IO.File]::Exists($original)) 'SOURCE_ZIP_MISSING'
Guard (-not ((Get-Item -LiteralPath $original).Attributes.HasFlag([IO.FileAttributes]::ReparsePoint))) 'SOURCE_ZIP_REPARSE'
$zipBytes=(Get-Item -LiteralPath $original).Length
Guard ($zipBytes -gt 0 -and $zipBytes -le 2097152) 'SOURCE_COMPRESSED_SIZE_LIMIT'
$zipSha=FileHash $original
Guard ($zipSha -eq $ExpectedZipSha256.ToUpperInvariant()) 'SOURCE_ZIP_SHA_MISMATCH'
# Always delegate the exact source, UUID, native converter and app-list semantics to the SHA-pinned v2 Audit.
$prior=@(& $v2 -OriginalZipPath $original -ExpectedZipSha256 $zipSha -DeclaredBuild $DeclaredBuild -ExpectedUuid $ExpectedUuid -Mode Audit -OutputMode PREISO)
Guard (@($prior | Where-Object {$_ -like 'R003_P0_SOURCE_AUDIT=PASS*'}).Count -eq 1) 'V2_SOURCE_AUDIT_NOT_PASS'
$priorReport=$prior[-1] | ConvertFrom-Json -ErrorAction Stop
Guard ($priorReport.schema -ceq 'BlueLite.R003.P0.SourceAudit.v1' -and
       $priorReport.original_zip_sha256 -ceq $zipSha -and
       $priorReport.declared_build -ceq $DeclaredBuild -and
       $priorReport.build_verified_from_original_launcher -eq $true -and
       $priorReport.exact_uuid -ceq $ExpectedUuid -and
       $priorReport.converter_execution_allowed -eq $false) 'SOURCE_REPORT_DRIFT'
Add-Type -AssemblyName System.IO.Compression
$archive=[IO.Compression.ZipFile]::OpenRead($original)
try {
  $entries=@($archive.Entries)
  Guard ($entries.Count -ge 5 -and $entries.Count -le 64) 'ZIP_ENTRY_COUNT_LIMIT'
  $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  $files=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  $dirs=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  $sum=0L
  foreach($entry in $entries) {
    $name=$entry.FullName
    Guard (-not [string]::IsNullOrWhiteSpace($name) -and -not $name.Contains('\') -and
           -not $name.StartsWith('/') -and -not $name.Contains('//') -and
           -not $name.Contains(':') -and -not $name.Contains([char]0)) 'ZIP_UNSAFE_NAME'
    Guard ($seen.Add($name.TrimEnd('/'))) 'ZIP_DUPLICATE_ALIAS'
    $isDir=$name.EndsWith('/')
    $parts=@($name.TrimEnd('/').Split('/'))
    foreach($piece in $parts) {
      Guard (-not [string]::IsNullOrWhiteSpace($piece) -and $piece -ne '.' -and $piece -ne '..' -and
             $piece -notmatch '[<>:"|?*\x00-\x1f]' -and
             $piece -notmatch '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|$)' -and
             $piece -notmatch '[. ]$') 'ZIP_WINDOWS_ALIAS_OR_DEVICE'
    }
    $type=($entry.ExternalAttributes -shr 16) -band 61440
    Guard ($type -ne 40960) 'ZIP_UNIX_SYMLINK'
    Guard ($entry.Length -ge 0 -and $entry.Length -le 2097152 -and $entry.CompressedLength -ge 0) 'ZIP_ENTRY_SIZE'
    Guard ($entry.Length -eq 0 -or ($entry.CompressedLength -gt 0 -and
            ($entry.Length / [double]$entry.CompressedLength) -le 200)) 'ZIP_COMPRESSION_RATIO'
    if($isDir) { Guard ($entry.Length -eq 0) 'ZIP_NONEMPTY_DIRECTORY' }
    $sum += $entry.Length
    Guard ($sum -le 8388608) 'ZIP_EXPANDED_TOTAL_LIMIT'
    $key=$name.TrimEnd('/')
    if($isDir) { $null=$dirs.Add($key) } else { $null=$files.Add($key) }
    if($parts.Count -gt 1) {
      for($n=1;$n -lt $parts.Count;$n++) {
        $parentPath=($parts[0..($n-1)] -join '/')
        Guard (-not $files.Contains($parentPath)) 'ZIP_PARENT_FILE_COLLISION'
        $null=$dirs.Add($parentPath)
      }
    }
  }
  foreach($file in $files) { Guard (-not $dirs.Contains($file)) 'ZIP_FILE_DIR_COLLISION' }
  $report=[ordered]@{
    schema='BlueLite.R003.P0.BoundedFixture.v3'
    status='SOURCE_AND_BOUNDS_AUDIT_ONLY'
    original_zip_sha256=$zipSha
    source_build=$DeclaredBuild
    uuid=$ExpectedUuid
    original_zip_bytes=$zipBytes
    member_count=$entries.Count
    uncompressed_bytes=$sum
    mode=$Mode
    extraction_executed=$false
    original_immutable=$true
    network=$false
    vendor_converter=$false
    wim_iso_mutation=$false
  }
  if($Mode -eq 'PrepareSmallFixture') {
    Guard (-not [string]::IsNullOrWhiteSpace($FixturePath)) 'FIXTURE_PATH_MISSING'
    $base=Join-Path $root '04_StaticTests'
    foreach($parent in @('C:\work','C:\work\PREMAX-work',$root,$base)) {
      Guard ([IO.Directory]::Exists($parent)) 'OWNED_PARENT_MISSING'
      Guard (-not ((Get-Item -LiteralPath $parent).Attributes.HasFlag([IO.FileAttributes]::ReparsePoint))) 'OWNED_PARENT_REPARSE'
    }
    $dest=[IO.Path]::GetFullPath($FixturePath).TrimEnd('\')
    Guard ([IO.Path]::GetDirectoryName($dest) -ieq $base.TrimEnd('\')) 'FIXTURE_NOT_DIRECT_CHILD'
    Guard (-not [IO.Directory]::Exists($dest) -and -not [IO.File]::Exists($dest)) 'FIXTURE_ALREADY_EXISTS'
    [IO.Directory]::CreateDirectory($dest) | Out-Null
    $actualTotal=0L
    foreach($entry in $entries) {
      $name=$entry.FullName.Replace('/','\')
      $target=[IO.Path]::GetFullPath((Join-Path $dest $name))
      Guard ($target.StartsWith(($dest+'\'),[StringComparison]::OrdinalIgnoreCase)) 'ZIP_TARGET_OUTSIDE'
      if($entry.FullName.EndsWith('/')) {
        [IO.Directory]::CreateDirectory($target) | Out-Null
        continue
      }
      [IO.Directory]::CreateDirectory(([IO.Path]::GetDirectoryName($target))) | Out-Null
      $input=$entry.Open()
      $output=[IO.FileStream]::new($target,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
      try {
        $buf=[byte[]]::new(32768)
        $written=0L
        while(($got=$input.Read($buf,0,$buf.Length)) -gt 0) {
          $written += $got
          $actualTotal += $got
          Guard ($written -le $entry.Length -and $written -le 2097152 -and $actualTotal -le 8388608) 'ZIP_REALTIME_EXPANSION_LIMIT'
          $output.Write($buf,0,$got)
        }
        Guard ($written -eq $entry.Length) 'ZIP_EXTRACTED_LENGTH_MISMATCH'
        $output.Flush($true)
      }
      finally { $output.Dispose();$input.Dispose() }
      $sourceStream=$entry.Open()
      try { $memberHash=(Get-FileHash -InputStream $sourceStream -Algorithm SHA256).Hash }
      finally { $sourceStream.Dispose() }
      Guard ((FileHash $target) -eq $memberHash) 'ZIP_EXTRACTED_SHA_MISMATCH'
    }
    Guard ((FileHash $original) -eq $zipSha) 'SOURCE_ZIP_CHANGED_POST'
    $overlay=Join-Path $dest 'BlueLite'
    [IO.Directory]::CreateDirectory($overlay) | Out-Null
    $report.status='SMALL_FIXTURE_BYTES_VERIFIED'
    $report.extraction_executed=$true
    $report.destination=$dest
    $report.actual_uncompressed_bytes=$actualTotal
    WriteNew (Join-Path $overlay 'SourceAudit.json') (($report | ConvertTo-Json -Depth 5)+[Environment]::NewLine)
    Write-Output ('R003_V3_FIXTURE_PASS;MEMBERS='+$entries.Count+';BYTES='+$actualTotal+';NO_NETWORK=TRUE')
  } else {
    Write-Output ('R003_V3_BOUNDS_AUDIT_PASS;MEMBERS='+$entries.Count+';BYTES='+$sum+';NO_NETWORK=TRUE')
  }
  Write-Output ($report | ConvertTo-Json -Compress -Depth 5)
}
finally { $archive.Dispose() }
