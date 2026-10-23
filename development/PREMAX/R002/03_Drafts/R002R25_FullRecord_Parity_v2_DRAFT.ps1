# R002R25 v2: URL-bearing original S06 selection, read-only, sanitized report
param([ValidateSet('SelfTest','Verify')][string]$Mode='SelfTest')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$base='C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package'
$g='C:\work\scripts\BlueLite_Stage1_S06_26300_G4_AppsOnly'
function Pin($p,$h) {
 if(-not [IO.File]::Exists($p)){throw 'SOURCE_MISSING'}
 if((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash -ne $h){throw 'SOURCE_SHA_MISMATCH'}
}
function Patterns($p){return @(Get-Content -LiteralPath $p | ForEach-Object {$_.Trim()} | Where-Object {$_ -and -not $_.StartsWith('#')})}
function MatchAny($text,[string[]]$patterns) {
 foreach($p in $patterns){if($text.IndexOf($p,[StringComparison]::OrdinalIgnoreCase) -ge 0){return $true}}
 return $false
}
function ParseOne([string[]]$lines) {
 $o=@($lines | Where-Object {$_ -match '^\s*out='})
 $c=@($lines | Where-Object {$_ -match '^\s*checksum='})
 if($o.Count -ne 1 -or $c.Count -ne 1){throw 'MALFORMED_RECORD'}
 $name=($o[0] -replace '^\s*out=','').Trim().Trim('"')
 $sum=($c[0] -replace '^\s*checksum=','').Trim()
 if([string]::IsNullOrWhiteSpace($name) -or $name -match '[\\/:?*<>"|]' -or $sum -notmatch '^sha-1=[0-9A-Fa-f]{40}$'){throw 'BAD_RECORD_ID'}
 return [pscustomobject]@{Out=$name;Checksum=$sum;Text=($lines -join [char]10)}
}
function ParseAria([string[]]$lines) {
 $a=[Collections.Generic.List[object]]::new()
 $cur=[Collections.Generic.List[string]]::new()
 foreach($l in $lines){
  if($l -match '^\s*https?://'){
   if($cur.Count -gt 0){[void]$a.Add((ParseOne $cur.ToArray()));$cur.Clear()}
   [void]$cur.Add($l)
  } elseif($cur.Count -gt 0){[void]$cur.Add($l)}
 }
 if($cur.Count -gt 0){[void]$a.Add((ParseOne $cur.ToArray()))}
 return $a.ToArray()
}
function UniqueOut([object[]]$rows){
 $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 foreach($x in $rows){if(-not $seen.Add([string]$x.Out)){throw 'DUPLICATE_OUT'}}
}
function SelectG4([object[]]$rows,[string[]]$allow,[string[]]$always,[string[]]$required){
 $ret=[Collections.Generic.List[object]]::new()
 foreach($x in $rows){
  if(-not ((MatchAny $x.Text $allow) -or (MatchAny $x.Text $always))){continue}
  $n=[string]$x.Out
  $m=[regex]::Match($n,'(?i)(?:language[-_]|_language-)([a-z]{2,3}(?:-[a-z0-9]{2,8})*)')
  if($m.Success -and $m.Groups[1].Value.ToLowerInvariant() -notin @('en-us','en')){continue}
  if($n -match '(?i)(?:^|[._-])(x86|arm64|arm)(?:[._-]|$)'){continue}
  [void]$ret.Add($x)
 }
 if($ret.Count -lt 3){throw 'LESS_THAN_THREE'}
 foreach($r in $required){
  $found=$false
  foreach($x in $ret){if($x.Text.IndexOf($r,[StringComparison]::OrdinalIgnoreCase) -ge 0){$found=$true;break}}
  if(-not $found){throw 'MISSING_REQUIRED_STAGING'}
 }
 return $ret.ToArray()
}
function MustReject([scriptblock]$test){
 $caught=$false
 try{&$test | Out-Null}catch{$caught=$true}
 if(-not $caught){throw 'NEGATIVE_DID_NOT_FAIL'}
}
$tok=$null;$err=$null
$tree=[Management.Automation.Language.Parser]::ParseFile($PSCommandPath,[ref]$tok,[ref]$err)
if($err.Count -ne 0){throw 'AST_ERRORS'}
$forbidden=@('Invoke-WebRequest','Invoke-RestMethod','Start-BitsTransfer','Invoke-Expression','Start-Process','Remove-Item','Copy-Item','Move-Item','Set-ItemProperty','reg','dism','aria2c')
$bad=@($tree.FindAll({param($z) $z -is [Management.Automation.Language.CommandAst] -and $z.GetCommandName() -in $forbidden},$true))
if($bad.Count -gt 0){throw 'AST_FORBIDDEN_COMMAND'}
if($Mode -eq 'SelfTest'){
 $aa=' checksum=sha-1='+('A'*40);$bb=' checksum=sha-1='+('B'*40);$cc=' checksum=sha-1='+('C'*40);$dd=' checksum=sha-1='+('D'*40)
 $fixture=@('https://example.invalid/Keep/A',' out=Keep.A.msix',$aa,'https://example.invalid/Keep/B',' out=Keep.B.msix',$bb,'https://example.invalid/Keep/C',' out=Keep.C.msix',$cc,'https://example.invalid/Keep/URLonly',' out=Neutral.D.msix',$dd)
 $rr=@(ParseAria $fixture);UniqueOut $rr
 $sel=@(SelectG4 $rr @('Keep') @() @('Keep.A','Keep.B','Keep.C'))
 if($rr.Count -ne 4 -or $sel.Count -ne 4){throw 'FULL_URL_RECORD_POSITIVE_FAILED'}
 MustReject {ParseAria @('https://example.invalid/Bad',' out=Bad.msix')}
 MustReject {UniqueOut @(ParseAria @('https://example.invalid/A',' out=Same.msix',$aa,'https://example.invalid/B',' out=Same.msix',$bb))}
 MustReject {SelectG4 $rr @('Keep') @() @('NotPresent')}
 Write-Output 'PASS_R002R25_AST0_POSITIVE_AND_3_NEGATIVES'
 exit 0
}
$raw="$base\05_Evidence\R002R22_9807_NewQueue_001\AppsQueue.newly_observed.txt"
$r23="$base\05_Evidence\R002R23_MetadataInventory_001\R002R23_SafeQueueInventory.json"
$r24="$base\05_Evidence\R002R24_URLFreeSeedPreview_001\R002R24_URLFree_SeedPreview.json"
$folder="$base\05_Evidence\R002R25_FullRecordParity_002"
if(Test-Path -LiteralPath $folder){throw 'OUTPUT_COLLISION'}
Pin $raw '91A3542BDF027559EB8541C9841903613357894501D0FB392880A740E4D0F67A'
Pin $r23 '0058049376679F6011F9BD3C9D51FE49BD631E46D843E38CF09E15D7AFD1CDE6'
Pin $r24 '2D91B0C75970738DC2DC93A66C75AEA761BC02CB8452DF5B7055FFDE22029A82'
Pin "$g\BlueLite_FilterApps.ps1" '827CC9BAC9B8690AC05BDD45545138ABB9FDBD097AE47CD37AA51496157C8BD8'
Pin "$g\BlueLite_AppAllowPatterns.txt" 'B099C3F688A8AEC7AF151E838E263DC713D05432F682117E002AD0BDC19B49DB'
Pin "$g\BlueLite_AppAlwaysKeepPatterns.txt" 'DA6638876F07453A3185F0EC420FA7FD52C615D9CA29702F9E89E6CCC72F8B5B'
Pin "$g\BlueLite_RequiredStagingApps.txt" '3812FFA2EBE6085889F007D1522D2EC3F970A9C23E1457B8B2D73798FD252265'
$src=Get-Content -LiteralPath $r23 -Raw | ConvertFrom-Json
$pre=Get-Content -LiteralPath $r24 -Raw | ConvertFrom-Json
if($src.source_build -ne '26300.9807' -or $src.source_uuid -ne '687d1ced-aab1-4cd5-ad05-705189769731' -or $src.record_count -ne 2896 -or $pre.source_uuid -ne $src.source_uuid -or $pre.preview_candidate_count -ne 27){throw 'SOURCE_IDENTITY_DRIFT'}
$rows=@(ParseAria ([IO.File]::ReadAllLines($raw)));UniqueOut $rows
if($rows.Count -ne 2798){throw 'R22_COUNT'}
$expected=@($src.records | Where-Object {$_.queue -eq 'Apps'})
if($expected.Count -ne $rows.Count){throw 'R23_COUNT'}
$map=@{}
foreach($r in $expected){if($map.ContainsKey($r.out)){throw 'R23_DUPLICATE'};$map.Add([string]$r.out,[string]$r.checksum)}
foreach($r in $rows){if(-not $map.ContainsKey($r.Out) -or $map[$r.Out] -ne $r.Checksum){throw 'R22_R23_PAIR_MISMATCH'}}
$selected=@(SelectG4 $rows @(Patterns "$g\BlueLite_AppAllowPatterns.txt") @(Patterns "$g\BlueLite_AppAlwaysKeepPatterns.txt") @(Patterns "$g\BlueLite_RequiredStagingApps.txt"))
UniqueOut $selected
$pmap=@{}
foreach($r in $pre.candidates){if($pmap.ContainsKey($r.out)){throw 'R24_DUPLICATE'};$pmap.Add([string]$r.out,[string]$r.checksum)}
$now=@{}
foreach($r in $selected){$now.Add([string]$r.Out,[string]$r.Checksum)}
$extra=@($selected | Where-Object {-not $pmap.ContainsKey($_.Out) -or $pmap[$_.Out] -ne $_.Checksum})
$missing=@($pre.candidates | Where-Object {-not $now.ContainsKey($_.out) -or $now[$_.out] -ne $_.checksum})
$staging=0
foreach($identity in $pre.identities){if($now.ContainsKey([string]$identity.candidate_out)){$staging++}}
$meta=@($selected | Where-Object {$_.Out -match '(?i)AggregatedMetadata\.cab$'}).Count
$result=if($selected.Count -eq 27 -and $extra.Count -eq 0 -and $missing.Count -eq 0 -and $staging -eq 5 -and $meta -eq 1){'PASS_R002R25_FULL_RECORD_G4_FILTER_PARITY_NOT_CLOSURE'}else{'HOLD_R002R25_FULL_RECORD_G4_SELECTION_DELTA'}
$report=[ordered]@{schema='BlueLite.R002R25.SourceOnlyFullG4Parity.v1';result=$result;build='26300.9807';uuid=$src.source_uuid;raw_apps_records=$rows.Count;r23_pairs_verified=$rows.Count;r24_out_only_candidates=$pre.candidates.Count;full_g4_selected=$selected.Count;extra_vs_r24=$extra.Count;missing_vs_r24=$missing.Count;staging_identities=$staging;metadata_cab=$meta;sha1_hex_casefold=true;urls_emitted=0;http_requests=0;original_queue_mutated=$false;manifest_closure='NOT_EVALUATED';payload_sha_verified=$false;runtime_execution_allowed=$false}
[void](New-Item -Path $folder -ItemType Directory -ErrorAction Stop)
$target=Join-Path $folder 'R002R25_FullRecord_Parity.json'
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($report | ConvertTo-Json -Depth 5))
$stream=[IO.File]::Open($target,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
Write-Output "$result RAW=$($rows.Count) SELECTED=$($selected.Count) R24=$($pre.candidates.Count) EXTRA=$($extra.Count) MISSING=$($missing.Count) STAGING=$staging META=$meta HTTP=0"
