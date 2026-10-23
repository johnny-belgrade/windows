# R002-R26 F v1 DRAFT -- exact 26300.9807 sha-1 vs historic .9711 cache; no downloads
param([ValidateSet('SelfTest','Verify')][string]$Mode='SelfTest')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$base='C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package'
$cache='C:\work\E2E\BlueLite_Stage1_S06_26300_9711_2b22470a\UUPs'
$r24=Join-Path $base '05_Evidence\R002R24_URLFreeSeedPreview_001\R002R24_URLFree_SeedPreview.json'
$r26=Join-Path $base '05_Evidence\R002R26_LocalPayloadInventory_001\R002R26_LocalPayloadInventory.json'
$outdir=Join-Path $base '05_Evidence\R002R26_F_HistoricCache_SHA1_001'
function MustPin([string]$path,[string]$expected) {
 if(-not [IO.File]::Exists($path)){throw 'FROZEN_INPUT_NOT_FOUND'}
 if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $expected){throw 'FROZEN_INPUT_SHA_MISMATCH'}
}
function SafeLeaf([string]$name) {
 if([string]::IsNullOrWhiteSpace($name) -or $name.Length -gt 240 -or $name -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$' -or $name.Contains('..') -or $name -cne [IO.Path]::GetFileName($name)){throw 'UNSAFE_LEAF'}
 return $name
}
function ReadSha1([string]$checksum) {
 $m=[regex]::Match($checksum,'(?i)^sha-1=([a-f0-9]{40})$')
 if(-not $m.Success){throw 'EXPECTED_SHA1_TOKEN_INVALID'}
 return $m.Groups[1].Value.ToUpperInvariant()
}
function MustReject([scriptblock]$test){
 $caught=$false
 try{&$test | Out-Null}catch{$caught=$true}
 if(-not $caught){throw 'NEGATIVE_NOT_REJECTED'}
}
$tok=$null;$errs=$null
$tree=[Management.Automation.Language.Parser]::ParseFile($PSCommandPath,[ref]$tok,[ref]$errs)
if($errs.Count -gt 0){throw 'SOURCE_AST_ERRORS'}
$blocked=@('Invoke-WebRequest','Invoke-RestMethod','Start-BitsTransfer','Start-Process','Invoke-Expression','Remove-Item','Move-Item','Copy-Item','Expand-Archive','Set-ItemProperty','reg','dism','aria2c')
if(@($tree.FindAll({param($node) $node -is [Management.Automation.Language.CommandAst] -and $node.GetCommandName() -in $blocked},$true)).Count -gt 0){throw 'FORBIDDEN_SOURCE_COMMAND'}
if($Mode -eq 'SelfTest') {
 [void](SafeLeaf 'Microsoft.VCLibs.x64.14.00.appx')
 if((ReadSha1 ('sha-1='+('a'*40))) -cne ('A'*40)){throw 'CASEFOLD_POSITIVE_FAILED'}
 MustReject {SafeLeaf '..\escape.msix'}
 MustReject {SafeLeaf 'bad/inner.msix'}
 MustReject {SafeLeaf 'evil..msix'}
 MustReject {ReadSha1 'sha-256=AAAAAAAA'}
 MustReject {ReadSha1 ('sha-1='+('f'*39))}
 Write-Output 'PASS_R002R26_F_SOURCE_AST0_SHA1_CASEFOLD_5_NEGATIVES'
 exit 0
}
if([IO.Directory]::Exists($outdir)){throw 'OWNED_OUTPUT_COLLISION'}
MustPin $r24 '2D91B0C75970738DC2DC93A66C75AEA761BC02CB8452DF5B7055FFDE22029A82'
MustPin $r26 '24DD6D74DB006A7DC9D39190CD3044A62F43DB23863D5CCEEEEF8423D004EDED'
$preview=Get-Content -LiteralPath $r24 -Raw | ConvertFrom-Json
$inventory=Get-Content -LiteralPath $r26 -Raw | ConvertFrom-Json
if($preview.source_build -ne '26300.9807' -or $preview.source_uuid -ne '687d1ced-aab1-4cd5-ad05-705189769731' -or $preview.preview_candidate_count -ne 27 -or $inventory.target_build -ne '26300.9807' -or $inventory.target_uuid -ne $preview.source_uuid -or $inventory.candidates_checked -ne 27){throw 'FROZEN_SOURCE_IDENTITY_MISMATCH'}
if(-not [IO.Directory]::Exists($cache)){throw 'HISTORIC_CACHE_MISSING'}
$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$inventoryNames=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($row in @($inventory.rows)){[void]$inventoryNames.Add((SafeLeaf ([string]$row.out)))}
if($inventoryNames.Count -ne 27){throw 'INVENTORY_IDENTITY_COUNT'}
$records=[Collections.Generic.List[object]]::new()
$checked=0;$matched=0;$diff=0;$missing=0;$totalBytes=[long]0;$cab=0
$root=[IO.Path]::GetFullPath($cache).TrimEnd('\')+'\'
foreach($candidate in @($preview.candidates)){
 $name=SafeLeaf ([string]$candidate.out)
 if(-not $seen.Add($name) -or -not $inventoryNames.Contains($name)){throw 'CANDIDATE_DUP_OR_R26_MISMATCH'}
 $expected=ReadSha1 ([string]$candidate.checksum)
 if($candidate.role -eq 'RECONSTRUCTION_METADATA_CANDIDATE'){
  if($name -notmatch '(?i)AggregatedMetadata\.cab$'){throw 'SOURCE_CAB_UNEXPECTED'}
  $cab++
  continue
 }
 if($candidate.role -ne 'STAGING_APPX_CANDIDATE' -or $name -notmatch '(?i)\.(appx|msix|appxbundle|msixbundle)$'){throw 'NON_APPX_STAGING_RECORD'}
 $checked++
 $path=[IO.Path]::GetFullPath((Join-Path $cache $name))
 if(-not $path.StartsWith($root,[StringComparison]::OrdinalIgnoreCase)){throw 'PATH_NOT_WITHIN_CACHE'}
 if(-not [IO.File]::Exists($path)) {
  $missing++
  [void]$records.Add([ordered]@{out=$name;expected_sha1=$expected;observed_sha1=$null;bytes=$null;status='MISSING_HISTORIC_CACHE'})
  continue
 }
 $fi=Get-Item -LiteralPath $path -ErrorAction Stop
 if(-not $fi.PSIsContainer -and ($fi.Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'HISTORIC_SYMLINK_DISALLOWED'}
 if($fi.PSIsContainer -or $fi.Length -le 0){throw 'HISTORIC_FILE_INVALID'}
 $hash=(Get-FileHash -LiteralPath $path -Algorithm SHA1).Hash.ToUpperInvariant()
 $totalBytes+=[long]$fi.Length
 $status=if($hash -ceq $expected){$matched++;'EXACT_SHA1_REUSABLE_BYTES'}else{$diff++;'DIFFERENT_SHA1_NOT_REUSABLE'}
 [void]$records.Add([ordered]@{out=$name;expected_sha1=$expected;observed_sha1=$hash;bytes=[long]$fi.Length;status=$status})
}
if($seen.Count -ne 27 -or $checked -ne 26 -or $cab -ne 1 -or $records.Count -ne 26 -or ($matched+$diff+$missing) -ne 26){throw 'COUNT_CONTRACT_FAILED'}
$report=[ordered]@{
 schema='BlueLite.R002R26.F.HistoricCacheSha1.v1'
 result='PASS_R002R26_F_HISTORIC_CACHE_SHA1_CLASSIFICATION_NOT_MANIFEST_CLOSURE'
 target_build='26300.9807';target_uuid=$preview.source_uuid
 historic_source='26300.9711';cache_owner='HISTORIC_ONLY'
 r24_sha256='2D91B0C75970738DC2DC93A66C75AEA761BC02CB8452DF5B7055FFDE22029A82'
 r26_sha256='24DD6D74DB006A7DC9D39190CD3044A62F43DB23863D5CCEEEEF8423D004EDED'
 staging_candidates=26;metadata_cab_excluded=1;exact_sha1_reusable=$matched;sha1_different=$diff;missing_in_cache=$missing
 historic_cache_bytes_read=$totalBytes;files=$records.ToArray()
 appx_manifest_provider_closure='NOT_EVALUATED';payload_sha1_compared=$true
 urls_emitted=0;network_requests=0;original_cache_modified=$false;runtime_execution_allowed=$false
}
[void](New-Item -Path $outdir -ItemType Directory -ErrorAction Stop)
$dest=Join-Path $outdir 'R002R26_F_ReuseGate.json'
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($report|ConvertTo-Json -Depth 7))
$stream=[IO.File]::Open($dest,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
Write-Output "PASS_R002R26_F_SHA1_CACHE_GATE_NOT_MANIFEST_CLOSURE selected=26 matched=$matched changed=$diff missing=$missing metadataExcluded=$cab bytesRead=$totalBytes http=0"
