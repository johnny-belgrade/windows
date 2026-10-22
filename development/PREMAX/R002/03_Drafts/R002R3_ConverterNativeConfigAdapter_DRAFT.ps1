# R002R3: Source-pinned original UUP converter v126 template adapter. STATIC DEVELOPMENT ONLY.
# Reads original templates from tiny owned previous ZIP fixture; never runs converter, UUP, DISM or WIM.
[CmdletBinding()]
param(
 [ValidateSet('Audit','SmallFixture')][string]$Mode='Audit',
 [string]$ContractPath='C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package\01_Inputs\R002R3_ConverterNative_9711_Contract.json',
 [string]$OutputDirectory='',
 [string]$Authorization=''
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Halt([string]$Code){throw ('R002R3_HOLD='+$Code)}
function Gate([bool]$Good,[string]$Code){if(-not $Good){Halt $Code}}
function FileSHA([string]$Path) {
 Gate (Test-Path -LiteralPath $Path -PathType Leaf) 'SOURCE_FILE_MISSING'
 (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()
}
$root='C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package'
$c=Get-Content -LiteralPath $ContractPath -Raw -ErrorAction Stop|ConvertFrom-Json -ErrorAction Stop
Gate ($c.schema -ceq 'BlueLite.R002R3.ConverterNativeTemplateContract.v1' -and $c.runtime_allowed -eq $false) 'CONTRACT_SCHEMA_OR_RUNTIME'
Gate ($c.mode -ceq 'STATIC_ONLY_NO_VENDOR_BINARY_EXECUTION' -and $c.source_build -ceq '26300.9711') 'UNREVIEWED_BUILD_OR_MODE'
$src='C:\work\26300.9711-UUP\26300.9711_amd64_en-us_professional_2b22470a_convert.zip'
Gate ((FileSHA $src) -ceq $c.source_zip_sha256) 'SOURCE_ZIP_SHA_DRIFT'
$orig=[IO.Path]::GetFullPath([string]$c.original_zip_fixture).TrimEnd('\')
Gate ($orig -ceq (Join-Path $root '04_StaticTests\R002R2_Fixture_001')) 'SOURCE_FIXTURE_NOT_FROZEN_OWNER'
$cfg=Join-Path $orig 'ConvertConfig.ini'
$apps=Join-Path $orig 'CustomAppsList.txt'
$metadata=Join-Path $orig 'files\converter_windows'
Gate ((FileSHA $cfg) -ceq $c.original_config_sha256) 'SOURCE_INI_SHA_DRIFT'
Gate ((FileSHA $apps) -ceq $c.original_app_list_sha256) 'SOURCE_APP_LIST_SHA_DRIFT'
Gate ((FileSHA $metadata) -ceq $c.original_converter_metadata_sha256) 'SOURCE_CONVERTER_METADATA_SHA_DRIFT'
$metadataText=[IO.File]::ReadAllText($metadata)
$version=[string]$c.converter_declared
Gate ($version -ceq 'uup-converter-wimlib-v126.7z') 'CONVERTER_VERSION_NOT_IN_REVIEWED_MATRIX'
Gate ($metadataText -match '(?im)^https://uupdump\.net/misc/(uup-converter-wimlib-v[0-9a-z.]+\.7z)\s*$') 'CONVERTER_METADATA_ENDPOINT_MISMATCH'
Gate ($Matches[1] -ceq $version) 'CONVERTER_SOURCE_VERSION_DRIFT'
Gate ($metadataText -match '(?im)^\s+checksum=sha-256=([0-9a-f]{64})\s*$') 'CONVERTER_METADATA_CHECKSUM_MISSING'
# The metadata contains two checksum lines: above regex matches the first one!
# Resolve the archive digest specifically from the surrounding converter block, never 7zr.
$blocks=@($metadataText -split '(?:\r?\n){2,}')
$conv=@($blocks|Where-Object {$_ -match [regex]::Escape($version)})
Gate ($conv.Count -eq 1 -and $conv[0] -match '(?im)^\s+checksum=sha-256=([0-9a-f]{64})\s*$') 'CONVERTER_ARCHIVE_PIN_UNRESOLVED'
Gate ($Matches[1].ToUpperInvariant() -ceq $c.converter_declared_sha256) 'CONVERTER_ARCHIVE_DIGEST_DRIFT'
# Read Windows INI; refuse duplicated section/key and unexpected target values.
$cfgLines=[IO.File]::ReadAllLines($cfg)
$section=''
$keys=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
$sectionHits=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
for($n=0;$n -lt $cfgLines.Length;$n++){
 $line=$cfgLines[$n]
 if($line -match '^\s*\[([A-Za-z0-9_-]+)\]\s*$') {
  $section=$Matches[1]
  Gate ($sectionHits.Add($section)) 'DUPLICATE_INI_SECTION'
  continue
 }
 if($line -match '^\s*([A-Za-z0-9_]+)\s*=\s*(.*?)\s*$'){
  Gate (-not [string]::IsNullOrWhiteSpace($section)) 'INI_KEY_OUTSIDE_SECTION'
  $k=$section+'|'+$Matches[1]
  Gate (-not $keys.ContainsKey($k)) 'DUPLICATE_INI_KEY'
  $keys.Add($k,$Matches[2].Trim())
 }elseif($line.Trim().Length -gt 0 -and -not $line.TrimStart().StartsWith('#') -and -not $line.TrimStart().StartsWith(';')){
  Halt 'UNKNOWN_INI_TOKEN'
 }
}
foreach($s in @('convert-UUP','Store_Apps','create_virtual_editions')){Gate ($sectionHits.Contains($s)) 'EXPECTED_SOURCE_INI_SECTION_MISSING'}
foreach($s in @('convert-UUP','Store_Apps')) {
 $expected=$c.settings_pinned_expected.$s
 foreach($prop in $expected.PSObject.Properties){
  $key=$s+'|'+$prop.Name
  Gate ($keys.ContainsKey($key) -and $keys[$key] -ceq [string]$prop.Value) ('INI_ORIGINAL_PREDICATE_'+$prop.Name)
 }
}
Gate ($c.settings_only_changes.'convert-UUP'.AutoStart -ceq '0' -and $c.settings_only_changes.Store_Apps.CustomList -ceq '1' -and $c.settings_only_changes.Store_Apps.StubAppsFull -ceq '1') 'CHANGE_SET_UNREVIEWED'
$proposedIni=[Collections.Generic.List[string]]::new()
$section=''
$changed=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($line in $cfgLines){
 $next=$line
 if($line -match '^\s*\[([A-Za-z0-9_-]+)\]\s*$'){$section=$Matches[1]}
 elseif($line -match '^(\s*([A-Za-z0-9_]+)\s*=\s*)(.*?)(\s*)$') {
  $key=$Matches[2]
  $change=$null
  if($null -ne $c.settings_only_changes.PSObject.Properties[$section]){$change=$c.settings_only_changes.$section}
  if($null -ne $change -and $null -ne $change.PSObject.Properties[$key]) {
   $next=$Matches[1]+[string]$change.$key+$Matches[4]
   Gate ($changed.Add($section+'|'+$key)) 'DUPLICATE_REWRITE_INI'
  }
 }
 $proposedIni.Add($next)
}
Gate ($changed.Count -eq 3) 'INI_EXPECTED_THREE_MODIFICATIONS'
Gate ($keys['convert-UUP|SkipWinRE'] -ceq '0' -and $keys['convert-UUP|ResetBase'] -ceq '0' -and $keys['Store_Apps|SkipApps'] -ceq '0') 'RECOVERY_OR_RECONSTRUCTION_POLICY'
# Actual native CustomAppsList package-family syntax, NOT AppX queue filename or package manifest.
$sourceLines=[IO.File]::ReadAllLines($apps)
$wanted=@($c.required_staging_families)
Gate ($wanted.Count -eq 5 -and @($wanted|Select-Object -Unique).Count -eq 5) 'REQUIRED_FIVE_FAMILY_CONTRACT'
$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$selected=[Collections.Generic.List[string]]::new()
$revised=[Collections.Generic.List[string]]::new()
foreach($line in $sourceLines){
 $trim=$line.Trim()
 if($trim -match '^(?:#\s*)?([A-Za-z][A-Za-z0-9.]+_[A-Za-z0-9]+)$'){
  $identity=$Matches[1]
  Gate ($seen.Add($identity)) 'DUPLICATE_APP_FAMILY_IN_TEMPLATE'
  if($identity -in $wanted){
   $selected.Add($identity)
   $revised.Add($identity)
  } else {
   $revised.Add('# '+$identity)
  }
 }else{
  Gate (-not ($trim -match '^[A-Za-z][A-Za-z0-9.]+_[A-Za-z0-9]+')) 'UNRECOGNIZED_ACTIVE_APP_ROW'
  $revised.Add($line)
 }
}
Gate ($selected.Count -eq 5) 'STAGING_FIVE_NOT_PRESENT_IN_NATIVE_TEMPLATE'
foreach($w in $wanted){Gate ($w -cin $selected) 'STAGING_TARGET_MISSING'}
$active=@($revised|Where-Object {$_ -match '^\s*[A-Za-z][A-Za-z0-9.]+_[A-Za-z0-9]+\s*$'})
Gate ($active.Count -eq 5) 'EXACT_FIVE_ACTIVE_APP_FAMILIES_REQUIRED'
foreach($x in @($c.forbidden_active_non_staging)){Gate ($x -cnotin $active) 'FORBIDDEN_STORE_FAMILY_ACTIVE'}
Gate ([int]$c.source_g4_staging_count -eq 32) 'HISTORIC_G4_CLOSURE_NOT_BOUND'
Write-Output ('R002R3_AUDIT_PASS;CONVERTER=v126;ORIGINAL_INI_KEYS='+$keys.Count+';INI_CHANGES=3;STAGING_FAMILIES='+$active.Count+';G4_PRIOR_CLOSURE=32;NO_NETWORK=TRUE')
if($Mode -eq 'Audit'){
 Write-Output 'R002R3_AUDIT_NO_WRITES=TRUE;VENDOR_CONVERTER_SOURCE_NOT_EXECUTED=TRUE'
 return
}
Gate ($Authorization -ceq 'I_APPROVE_R002R3_TINY_CONFIG_FIXTURE_ONLY') 'SMALL_FIXTURE_AUTH_REQUIRED'
$parent=Join-Path $root '04_StaticTests'
Gate (-not [string]::IsNullOrWhiteSpace($OutputDirectory)) 'OUTPUT_DIR_REQUIRED'
$dest=[IO.Path]::GetFullPath($OutputDirectory).TrimEnd('\')
Gate ((Split-Path -Path $dest -Parent) -ceq $parent) 'OUTPUT_NOT_OWNED_DIRECT_CHILD'
Gate (-not (Test-Path -LiteralPath $dest)) 'OUTPUT_ALREADY_EXISTS'
$null=[IO.Directory]::CreateDirectory($dest)
[IO.File]::WriteAllLines((Join-Path $dest 'ConvertConfig.ini'),$proposedIni.ToArray(),[Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllLines((Join-Path $dest 'CustomAppsList.txt'),$revised.ToArray(),[Text.UTF8Encoding]::new($false))
$report=[ordered]@{
 schema='BlueLite.R002R3.ConverterConfigFixture.v1';status='PASS_STATIC_ONLY'
 frozen_build=[string]$c.source_build;converter_declared='v126';source_zip_sha256=[string]$c.source_zip_sha256
 originals_preserved=$true;changed_keys=@('convert-UUP/AutoStart','Store_Apps/StubAppsFull','Store_Apps/CustomList')
 active_app_families=$active;reused_g4_subset=32
 original_config_sha256=[string]$c.original_config_sha256;original_app_list_sha256=[string]$c.original_app_list_sha256
 no_vendor_archive_download=$true;no_converter_runtime=$true;no_wim_mutation=$true
 vendor_binary_actual_version_verified=$false
 note='Native template semantics verified; converter implementation not acquired or executed. Upgradeability decision deferred.'
}
[IO.File]::WriteAllText((Join-Path $dest 'R002R3_ConfigReceipt.json'),($report|ConvertTo-Json -Depth 6),[Text.UTF8Encoding]::new($false))
Gate ((FileSHA $cfg) -ceq $c.original_config_sha256 -and (FileSHA $apps) -ceq $c.original_app_list_sha256) 'ORIGINAL_TEMPLATES_CHANGED'
Write-Output 'R002R3_SMALL_CONFIG_FIXTURE_PASS;FAMILIES=5;CHANGES=3;ORIGINALS_UNCHANGED=TRUE;NO_CONVERTER=TRUE'
