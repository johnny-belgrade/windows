# BlueLite R002-R24 v1: exact 26300.9807 URL-free filename-only candidate preview.
# PREPARED_NOT_RUN. No UUP URL, HTTP, aria2, converter, WIM, registry or OS servicing.
[CmdletBinding()]
param([string]$Authorization='')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($PSVersionTable.PSEdition -cne 'Core' -or $PSVersionTable.PSVersion.Major -lt 7){throw 'R24_PS7_REQUIRED'}
if($Authorization -cne 'I_APPROVE_R002R24_LOCAL_OUT_ONLY_PREVIEW_ONLY'){throw 'R24_AUTHORIZATION_REQUIRED'}
$base='C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package'
$inventoryPath=Join-Path $base '05_Evidence\R002R23_MetadataInventory_001\R002R23_SafeQueueInventory.json'
$g4='C:\work\scripts\BlueLite_Stage1_S06_26300_G4_AppsOnly'
$outdir=Join-Path $base '05_Evidence\R002R24_URLFreeSeedPreview_001'
$sourceSha='0058049376679F6011F9BD3C9D51FE49BD631E46D843E38CF09E15D7AFD1CDE6'
$policyPins=[ordered]@{
 'BlueLite_AppAllowPatterns.txt'='B099C3F688A8AEC7AF151E838E263DC713D05432F682117E002AD0BDC19B49DB'
 'BlueLite_AppAlwaysKeepPatterns.txt'='DA6638876F07453A3185F0EC420FA7FD52C615D9CA29702F9E89E6CCC72F8B5B'
 'BlueLite_RequiredStagingApps.txt'='3812FFA2EBE6085889F007D1522D2EC3F970A9C23E1457B8B2D73798FD252265'
 'BlueLite_FilterApps.ps1'='827CC9BAC9B8690AC05BDD45545138ABB9FDBD097AE47CD37AA51496157C8BD8'
 'BlueLite_ResolveAppDependencies.ps1'='D9835FC164FDC2C6684DF44798E9F41EDFC9961F889B112BE27CD984441015FF'
}
function AssertHash([string]$p,[string]$expect){
 if(-not [IO.File]::Exists($p)){throw 'R24_PINNED_INPUT_MISSING'}
 if((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash -cne $expect){throw 'R24_PINNED_INPUT_SHA_DRIFT'}
}
function ReadPatterns([string]$p){
 return @(Get-Content -LiteralPath $p | ForEach-Object {$_.Trim()} | Where-Object {$_ -and -not $_.StartsWith('#')})
}
function IsForeignLang([string]$s){
 $m=[regex]::Match($s,'(?i)(?:language[-_]|_language-)([a-z]{2,3}(?:-[a-z0-9]{2,8})*)')
 return ($m.Success -and $m.Groups[1].Value.ToLowerInvariant() -notin @('en','en-us'))
}
function IsForeignArch([string]$s){
 return [regex]::IsMatch($s,'(?i)(?:^|[._-])(x86|arm64|arm)(?:[._-]|$)')
}
function SelectPreviewCandidates([object[]]$records,[string[]]$allow,[string[]]$keep){
 $candidates=[Collections.Generic.List[object]]::new()
 $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 foreach($rec in $records){
  $name=[string]$rec.out
  if($rec.queue -cne 'Apps'){continue}
  if(-not $name -or $name -match '(?i)https?://|[/\\:*?"<>|]' -or $name -match '(?i)\.\.' -or $name -match '[\r\n]'){throw 'R24_INVALID_OUT_FILENAME'}
  if([string]$rec.checksum -cnotmatch '^sha-1=[A-Fa-f0-9]{40}$'){throw 'R24_INVALID_DIGEST'}
  if(-not $seen.Add($name)){throw 'R24_DUPLICATE_APPS_OUT'}
  $isAllow=$false
  foreach($pattern in $allow){if($name.IndexOf($pattern,[StringComparison]::OrdinalIgnoreCase) -ge 0){$isAllow=$true;break}}
  $isKeep=$false
  foreach($pattern in $keep){if($name.IndexOf($pattern,[StringComparison]::OrdinalIgnoreCase) -ge 0){$isKeep=$true;break}}
  if(-not ($isAllow -or $isKeep)){continue}
  if(IsForeignLang $name){continue}
  if(IsForeignArch $name){continue}
  $role=if($isAllow){'STAGING_APPX_CANDIDATE'}else{'RECONSTRUCTION_METADATA_CANDIDATE'}
  [void]$candidates.Add([pscustomobject][ordered]@{out=$name;checksum=[string]$rec.checksum;role=$role})
 }
 return $candidates.ToArray()
}
function NewExclusive([string]$p,[string]$body){
 $bytes=[Text.UTF8Encoding]::new($false).GetBytes($body)
 $f=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$f.Write($bytes,0,$bytes.Length)}finally{$f.Dispose()}
}
if(Test-Path -LiteralPath $outdir){throw 'R24_OUTPUT_COLLISION'}
AssertHash $inventoryPath $sourceSha
foreach($pair in $policyPins.GetEnumerator()){AssertHash (Join-Path $g4 $pair.Key) $pair.Value}
$j=Get-Content -LiteralPath $inventoryPath -Raw | ConvertFrom-Json
if($j.schema -cne 'BlueLite.R002R23.SafeQueueInventory.v1' -or $j.source_build -cne '26300.9807' -or $j.source_uuid -cne '687d1ced-aab1-4cd5-ad05-705189769731' -or $j.input_class -cne 'NEWLY_OBSERVED_R22_METADATA' -or $j.record_count -ne 2896){throw 'R24_INVENTORY_SCOPE_DRIFT'}
$all=@($j.records)
if($all.Count -ne 2896){throw 'R24_RECORD_COUNT_DRIFT'}
foreach($rec in $all){
 $keys=@($rec.PSObject.Properties | ForEach-Object {$_.Name} | Sort-Object)
 if($keys.Count -ne 3 -or ($keys -join '|') -cne 'checksum|out|queue'){throw 'R24_UNSAFE_RECORD_KEYS'}
 if($rec.queue -cnotin @('Apps','Windows')){throw 'R24_UNKNOWN_QUEUE'}
}
$apps=@($all | Where-Object {$_.queue -ceq 'Apps'})
$windows=@($all | Where-Object {$_.queue -ceq 'Windows'})
if($apps.Count -ne 2798 -or $windows.Count -ne 98){throw 'R24_SOURCE_QUEUE_COUNT_DRIFT'}
$allow=@(ReadPatterns (Join-Path $g4 'BlueLite_AppAllowPatterns.txt'))
$keep=@(ReadPatterns (Join-Path $g4 'BlueLite_AppAlwaysKeepPatterns.txt'))
$required=@(ReadPatterns (Join-Path $g4 'BlueLite_RequiredStagingApps.txt'))
if($required.Count -ne 5){throw 'R24_STAGING_POLICY_DRIFT'}
$staging=@('Microsoft.SecHealthUI','Microsoft.DesktopAppInstaller','Microsoft.WindowsCalculator','Microsoft.WindowsNotepad','Microsoft.Windows.Photos')
if((@($required | Sort-Object) -join '|') -cne (@($staging | Sort-Object) -join '|')){throw 'R24_STAGING_IDENTITY_DRIFT'}
$candidates=@(SelectPreviewCandidates $apps $allow $keep | Sort-Object out)
if($candidates.Count -ne 27){throw 'R24_PREVIEW_CANDIDATE_COUNT_DRIFT'}
$anchors=[Collections.Generic.List[object]]::new()
foreach($family in $staging){
 $prefix=[regex]::Escape($family)
 $items=@($candidates | Where-Object {$_.role -ceq 'STAGING_APPX_CANDIDATE' -and $_.out -match ('(?i)^'+$prefix+'_[A-Za-z0-9]+\.(appx|msix|appxbundle|msixbundle)$')})
 if($items.Count -ne 1){throw 'R24_MISSING_OR_AMBIGUOUS_STAGING_IDENTITY'}
 [void]$anchors.Add([pscustomobject][ordered]@{staging_identity=$family;candidate_out=$items[0].out;checksum=$items[0].checksum})
}
$meta=@($candidates | Where-Object {$_.role -ceq 'RECONSTRUCTION_METADATA_CANDIDATE'})
if($meta.Count -ne 1 -or $meta[0].out -cne '687d1ced-aab1-4cd5-ad05-705189769731.AggregatedMetadata.cab'){throw 'R24_METADATA_KEEP_DRIFT'}
$preview=[ordered]@{
 schema='BlueLite.R002R24.URLFreeOutOnlySeedPreview.v1'
 source_build='26300.9807';source_uuid='687d1ced-aab1-4cd5-ad05-705189769731'
 source_class='NEWLY_OBSERVED_R22_METADATA';r23_sha256=$sourceSha
 full_windows_entries=98;full_apps_entries=2798;preview_candidate_count=$candidates.Count
 staging_identity_count=$anchors.Count;reconstruction_metadata_count=$meta.Count
 url_record_filter_parity='UNPROVEN_URL_FIELDS_INTENTIONALLY_EXCLUDED'
 manifest_dependency_closure='NOT_EVALUATED';payload_sha_verified=$false
 runtime_execution_allowed=$false;http_requests=0;candidate_role='OUT_ONLY_DISCOVERY_NOT_DOWNLOAD_SELECTION'
 identities=$anchors.ToArray();candidates=$candidates
}
$body=($preview | ConvertTo-Json -Depth 8)+[Environment]::NewLine
if($body -match '(?i)https?://|"Url"\s*:'){throw 'R24_URL_PROJECTION_FAILURE'}
$check=$body | ConvertFrom-Json
if(@($check.candidates).Count -ne 27 -or @($check.identities).Count -ne 5){throw 'R24_OUTPUT_ROUNDTRIP_FAIL'}
AssertHash $inventoryPath $sourceSha
foreach($pair in $policyPins.GetEnumerator()){AssertHash (Join-Path $g4 $pair.Key) $pair.Value}
if(Test-Path -LiteralPath $outdir){throw 'R24_OUTPUT_COLLISION'}
[void][IO.Directory]::CreateDirectory($outdir)
try {
 $op=Join-Path $outdir 'R002R24_URLFree_SeedPreview.json'
 NewExclusive $op $body
 if([IO.File]::ReadAllText($op) -cne $body){throw 'R24_PREVIEW_READBACK_MISMATCH'}
 AssertHash $inventoryPath $sourceSha
 $receipt=[ordered]@{
  result='PASS_R002R24_OUT_ONLY_PREVIEW_NOT_CLOSURE';native_pid=$PID;ps_version=$PSVersionTable.PSVersion.ToString()
  script_sha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
  inventory_sha256=$sourceSha;preview_sha256=(Get-FileHash -LiteralPath $op -Algorithm SHA256).Hash
  preview_bytes=(Get-Item -LiteralPath $op).Length;preview_count=$candidates.Count
  identities=$anchors.Count;http_requests=0;manifest_dependency_closure='NOT_EVALUATED'
  runtime_execution_allowed=$false
 }
 NewExclusive (Join-Path $outdir 'R002R24_Native_Preview_Receipt.json') (($receipt | ConvertTo-Json -Depth 4)+[Environment]::NewLine)
 $receipt | ConvertTo-Json -Depth 4
} catch {
 Write-Output 'RESULT=HOLD_R002R24_LOCAL_OUTPUT;PRESERVE_PARTIAL'
 exit 88
}
