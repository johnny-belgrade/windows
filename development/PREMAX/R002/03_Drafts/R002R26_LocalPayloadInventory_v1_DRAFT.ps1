# BlueLite R002-R26 v1: exact 9807 candidates vs scoped on-disk names; NO payload validation
param([ValidateSet('SelfTest','Inventory')][string]$Mode='SelfTest')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$b='C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package'
$ref9807='C:\work\UUP_Source\26300.9807_687d1ced'
$ref9711='C:\work\E2E\BlueLite_Stage1_S06_26300_9711_2b22470a\UUPs'
$r24=Join-Path $b '05_Evidence\R002R24_URLFreeSeedPreview_001\R002R24_URLFree_SeedPreview.json'
$r25=Join-Path $b '05_Evidence\R002R25_FullRecordParity_003\R002R25_FullRecord_Parity.json'
$outdir=Join-Path $b '05_Evidence\R002R26_LocalPayloadInventory_001'
function AssertSha([string]$Path,[string]$Expected) {
 if(-not [IO.File]::Exists($Path)) {throw 'PIN_INPUT_MISSING'}
 if((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash -ne $Expected) {throw 'PIN_SHA_MISMATCH'}
}
function Leaf([string]$Name) {
 if([string]::IsNullOrWhiteSpace($Name) -or $Name.Length -gt 240 -or $Name -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._-]+$' -or $Name.Contains('..') -or $Name -ne [IO.Path]::GetFileName($Name)){throw 'UNSAFE_CANDIDATE_NAME'}
 return $Name
}
function EnsureUnique([string[]]$names) {
 $set=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 foreach($n in $names){[void](Leaf $n);if(-not $set.Add($n)){throw 'DUPLICATE_CANDIDATE_NAME'}}
}
function InventoryFiles([string]$dir) {
 if(-not [IO.Directory]::Exists($dir)){throw 'SCOPED_DIRECTORY_MISSING'}
 $map=[Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
 foreach($f in Get-ChildItem -LiteralPath $dir -File) {
  if($map.ContainsKey($f.Name)){throw 'DIRECTORY_DUPLICATE_NAME'}
  $map.Add($f.Name,[long]$f.Length)
 }
 return $map
}
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($PSCommandPath,[ref]$tokens,[ref]$errors)
if($errors.Count -ne 0){throw 'SCRIPT_AST_INVALID'}
$blocked=@('Invoke-WebRequest','Invoke-RestMethod','Start-BitsTransfer','Invoke-Expression','Start-Process','Remove-Item','Copy-Item','Move-Item','Set-ItemProperty','Expand-Archive','aria2c','dism','reg')
$hits=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.CommandAst] -and $node.GetCommandName() -in $blocked},$true))
if($hits.Count -gt 0){throw 'SCRIPT_FORBIDDEN_COMMAND'}
if($Mode -eq 'SelfTest'){
 EnsureUnique @('AppA_1.msix','AppB_2.msix')
 $failed=0
 foreach($test in @('..\bad.msix','BAD/child.msix','AppA..msix')){try{[void](Leaf $test)}catch{$failed++}}
 try{EnsureUnique @('Same.msix','same.msix')}catch{$failed++}
 if($failed -ne 4){throw 'NEGATIVE_FOUR_FAILURE'}
 $fake=[Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
 $fake.Add('Present.msix',[long]123)
 if(-not $fake.ContainsKey('PRESENT.msix') -or $fake.ContainsKey('Missing.msix')){throw 'POSITIVE_LOOKUP_FAILURE'}
 Write-Output 'PASS_R002R26_AST0_POSITIVE_LOOKUP_NEGATIVE4_OF_4'
 exit 0
}
if([IO.Directory]::Exists($outdir)){throw 'OWNED_OUTPUT_COLLISION'}
AssertSha $r24 '2D91B0C75970738DC2DC93A66C75AEA761BC02CB8452DF5B7055FFDE22029A82'
AssertSha $r25 'E7DAD5C864CF9724AD8790C92888F5EA13A60696639D40F1E8F54B6EC476B518'
$seed=Get-Content -LiteralPath $r24 -Raw | ConvertFrom-Json
$prior=Get-Content -LiteralPath $r25 -Raw | ConvertFrom-Json
if($seed.source_build -ne '26300.9807' -or $seed.source_uuid -ne '687d1ced-aab1-4cd5-ad05-705189769731' -or $seed.preview_candidate_count -ne 27 -or $prior.result -ne 'PASS_R002R25_FULL_RECORD_G4_FILTER_PARITY_NOT_CLOSURE' -or $prior.full_g4_selected -ne 27){throw 'SOURCE_RECEIPT_CONTRACT'}
$names=@($seed.candidates | ForEach-Object {[string]$_.out})
if($names.Count -ne 27){throw 'CANDIDATE_COUNT'}
EnsureUnique $names
$files9807=InventoryFiles $ref9807
$files9711=InventoryFiles $ref9711
$rows=[Collections.Generic.List[object]]::new()
$direct=0;$historic=0;$notObserved=0;$metadata=0
foreach($rec in $seed.candidates){
 $name=Leaf ([string]$rec.out)
 if($name -match '(?i)AggregatedMetadata\.cab$'){$metadata++}
 $has9807=$files9807.ContainsKey($name)
 $has9711=$files9711.ContainsKey($name)
 if($has9807){$direct++}
 if($has9711){$historic++}
 if(-not $has9807 -and -not $has9711){$notObserved++}
 [void]$rows.Add([ordered]@{
  out=$name;role=[string]$rec.role
  exact_9807_root_present=$has9807
  exact_9807_length=if($has9807){$files9807[$name]}else{$null}
  historic_9711_name_present=$has9711
  historic_9711_length=if($has9711){$files9711[$name]}else{$null}
  payload_sha_verified=$false
  provider_manifest_verified=$false
 })
}
$report=[ordered]@{
 schema='BlueLite.R002R26.LocalPayloadInventory.v1';result='PASS_R002R26_LOCAL_FILENAME_REUSE_INVENTORY_NOT_PAYLOAD_CLOSURE'
 target_build='26300.9807';target_uuid=$seed.source_uuid;source_type='R25_SOURCE_BOUND_LOCAL_ONLY'
 source_r24_sha256='2D91B0C75970738DC2DC93A66C75AEA761BC02CB8452DF5B7055FFDE22029A82'
 source_r25_sha256='E7DAD5C864CF9724AD8790C92888F5EA13A60696639D40F1E8F54B6EC476B518'
 candidates_checked=$rows.Count;target9807_exact_root_present=$direct;historic9711_filename_matches=$historic
 absent_from_both_exact_roots=$notObserved;reconstruction_metadata_candidates=$metadata
 historic_9711_total_files=$files9711.Count;target9807_root_total_files=$files9807.Count
 rows=$rows.ToArray();package_content_sha_verified=$false;appx_manifest_provider_closure='NOT_EVALUATED'
 urls_serialized=0;network_requests=0;original_queue_modified=$false;runtime_execution_allowed=$false
}
[void](New-Item -Path $outdir -ItemType Directory -ErrorAction Stop)
$file=Join-Path $outdir 'R002R26_LocalPayloadInventory.json'
$utf=[Text.UTF8Encoding]::new($false)
$content=$utf.GetBytes(($report | ConvertTo-Json -Depth 8))
$stream=[IO.File]::Open($file,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$stream.Write($content,0,$content.Length)}finally{$stream.Dispose()}
Write-Output "PASS_R002R26_LOCAL_FILENAME_REUSE_INVENTORY_NOT_PAYLOAD_CLOSURE candidates=$($rows.Count) local9807=$direct historic9711=$historic absentBoth=$notObserved metadata=$metadata http=0"
