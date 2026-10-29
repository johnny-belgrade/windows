# BlueLite G3O isolated fixture harness v1 DRAFT.
# Default is source-only. Run ONE group per invocation, then independent native QA.
# Imports only SHA-pinned function definitions, NEVER the complete G3O script.
[CmdletBinding()]
param(
 [ValidateSet('DesignOnly','Run')][string]$Mode='DesignOnly',
 [ValidateSet('P01','P02','P03','P04','P05','N01','N02','N03','N04','N05','N06','N07','N08','N09','N10','N11','N12','N13','I01','I02')][string]$Case
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($Mode -eq 'DesignOnly'){
 Write-Output 'G3O_HARNESS_V1_SOURCE_ONLY|FIXTURES=NOT_RUN|REAL31=NOT_RUN'
 return
}
if([string]::IsNullOrWhiteSpace($Case)){throw 'HARNESS_CASE_REQUIRED'}
if($PSVersionTable.PSVersion.Major -ne 7){throw 'HARNESS_PS7_REQUIRED'}
$cycle='C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package'
$source=Join-Path $cycle '04_StaticTests\R002R26_G3O_ResourceBundleIdentity_v1_DRAFT.ps1'
$sourceSha='76143B517333442072016D968DC560F4E1FBD28C39B576761DAA91091C496BA0'
$allow=@('Hold','Assert-Root','Pinned-Sha256','Compute-Crc32','Read-Entry','Parse-Manifest','Get-OneEntry','Check-EntryNames','Identity-Info','Classify-Bundle','Inspect-Package')
$runId='G3OH1_'+$Case+'_'+[guid]::NewGuid().ToString('N')
$runRoot=Join-Path (Join-Path $cycle '04_StaticTests') $runId
$evidenceDir=Join-Path (Join-Path $cycle '05_Evidence') $runId
$checks=[Collections.Generic.List[object]]::new()
$observations=[Collections.Generic.List[object]]::new()
$coverageGaps=[Collections.Generic.List[string]]::new()
$utf8=[Text.UTF8Encoding]::new($false,$true)
function Assert-ProjectPath([string]$Path){
 $full=[IO.Path]::GetFullPath($Path)
 if(-not $full.StartsWith('C:\work\',[StringComparison]::OrdinalIgnoreCase)){throw 'HARNESS_PROJECT_SCOPE'}
 $walk=$full
 while($walk -and $walk.Length -ge 7){
  if(Test-Path -LiteralPath $walk){
   if(((Get-Item -LiteralPath $walk -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'HARNESS_REPARSE'}
  }
  if($walk.Equals('C:\work',[StringComparison]::OrdinalIgnoreCase)){return}
  $walk=[IO.Path]::GetDirectoryName($walk)
 }
 throw 'HARNESS_PROJECT_ROOT'
}
function Assert-OwnedOutput([string]$Path){
 $full=[IO.Path]::GetFullPath($Path)
 if(-not ($full.StartsWith($runRoot+'\',[StringComparison]::OrdinalIgnoreCase) -or $full.StartsWith($evidenceDir+'\',[StringComparison]::OrdinalIgnoreCase))){throw 'HARNESS_OUTPUT_SCOPE'}
 Assert-ProjectPath $full
}
function Write-NewBytes([string]$Path,[byte[]]$Bytes){
 Assert-OwnedOutput $Path
 if($Bytes.Length -gt 8388608){throw 'HARNESS_BYTE_BUDGET'}
 $s=[IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$s.Write($Bytes,0,$Bytes.Length);$s.Flush($true)}finally{$s.Dispose()}
}
function Write-NewJson([string]$Path,[object]$Value){
 Write-NewBytes $Path ($utf8.GetBytes(($Value|ConvertTo-Json -Depth 24)))
}
function Check([bool]$Condition,[string]$Label){
 $checks.Add([ordered]@{label=$Label;passed=$Condition})
 if(-not $Condition){throw ('HARNESS_ASSERT_'+$Label)}
}
function Expect-Reject([scriptblock]$Body,[string]$Token,[string[]]$Types=@()){
 $caught=$null
 try{& $Body|Out-Null}catch{$caught=$_}
 Check ($null -ne $caught) 'expected_rejection'
 $ok=$false
 $ex=$caught.Exception
 if($Token -and $ex.Message.Contains($Token)){$ok=$true}
 $chain=[Collections.Generic.List[string]]::new()
 while($null -ne $ex){
  $chain.Add($ex.GetType().FullName)
  if($Types -contains $ex.GetType().FullName){$ok=$true}
  $ex=$ex.InnerException
 }
 $observations.Add([ordered]@{rejected=$true;expected_token=$Token;exception_types=@($chain.ToArray());message=$caught.Exception.Message})
 Check $ok 'expected_rejection_kind'
}
function Failure-State([System.Management.Automation.ErrorRecord]$Record){
 return [ordered]@{
  outcome=if($Record.Exception.Message -ceq 'KNOWN_F02_CHILDREN_SHAPE_DEFECT'){'HOLD'}else{'FAIL'}
  failure=[ordered]@{message=$Record.Exception.Message;type=$Record.Exception.GetType().FullName;position=$Record.InvocationInfo.PositionMessage}
 }
}
function Get-PinnedDefinitions([string]$Path){
 Assert-ProjectPath $Path
 $s=[IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
 try{
  if((Get-FileHash -InputStream $s -Algorithm SHA256).Hash -cne $sourceSha){throw 'HARNESS_SOURCE_SHA'}
  $s.Position=0
  $reader=[IO.StreamReader]::new($s,$utf8,$true,4096,$true)
  try{$text=$reader.ReadToEnd()}finally{$reader.Dispose()}
 }finally{$s.Dispose()}
 $tok=$null;$err=$null
 $tree=[System.Management.Automation.Language.Parser]::ParseInput($text,$Path,[ref]$tok,[ref]$err)
 if(@($err).Count -ne 0){throw 'HARNESS_SOURCE_AST'}
 $defs=@($tree.EndBlock.Statements|Where-Object{$_ -is [System.Management.Automation.Language.FunctionDefinitionAst]})
 $allDefs=@($tree.FindAll({param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst]},$true))
 if($defs.Count -ne 11 -or $allDefs.Count -ne 11){throw 'HARNESS_DEFINITION_COUNT'}
 if((@($defs.Name|Sort-Object) -join '|') -cne (@($allow|Sort-Object) -join '|')){throw 'HARNESS_DEFINITION_NAMES'}
 return (($defs|ForEach-Object{$_.Extent.Text}) -join [Environment]::NewLine)
}
function Bytes([string]$Text){return ,$utf8.GetBytes($Text)}
function Entry([string]$Name,[byte[]]$Data){return @{name=$Name;data=$Data}}
function New-Zip([string]$Label,[object[]]$Entries,[bool]$Compress=$false){
 $p=Join-Path $runRoot ($Label+'.zip');Assert-OwnedOutput $p
 if($Entries.Count -gt 4097){throw 'HARNESS_ENTRY_BUDGET'}
 [long]$total=0;foreach($item in $Entries){$total+=$item.data.Length}
 if($total -gt 8388608){throw 'HARNESS_ZIP_BUDGET'}
 $f=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
 try{
  $z=[IO.Compression.ZipArchive]::new($f,[IO.Compression.ZipArchiveMode]::Create,$true)
  try{
   foreach($item in $Entries){
    $level=if($Compress){[IO.Compression.CompressionLevel]::Optimal}else{[IO.Compression.CompressionLevel]::NoCompression}
    $e=$z.CreateEntry($item.name,$level);$es=$e.Open()
    try{$es.Write($item.data,0,$item.data.Length)}finally{$es.Dispose()}
   }
  }finally{$z.Dispose()}
 }finally{$f.Dispose()}
 return $p
}
function With-Zip([string]$Path,[scriptblock]$Body){
 Assert-OwnedOutput $Path
 $f=[IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
 try{
  $z=[IO.Compression.ZipArchive]::new($f,[IO.Compression.ZipArchiveMode]::Read,$true)
  try{& $Body $z}finally{$z.Dispose()}
 }finally{$f.Dispose()}
}
function Package-Xml([string]$Arch='x64',[string]$Properties=''){
 return '<Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"><Identity Name="BlueLite.Fixture" Publisher="CN=BlueLiteFixture" Version="1.0.0.0" ProcessorArchitecture="'+$Arch+'"/>'+ $Properties+'</Package>'
}
function Bundle-Xml([string]$Children){
 return '<Bundle xmlns="http://schemas.microsoft.com/appx/2013/bundle"><Identity Name="BlueLite.Fixture" Publisher="CN=BlueLiteFixture" Version="1.0.0.0"/><Packages>'+$Children+'</Packages></Bundle>'
}
function Find-ZipSignature([byte[]]$Data,[uint32]$Signature){
 $positions=@(for($i=0;$i -le $Data.Length-4;$i++){if([BitConverter]::ToUInt32($Data,$i) -eq $Signature){$i}})
 if($positions.Count -ne 1){throw 'HARNESS_SYNTHETIC_ZIP_LAYOUT'}
 return [int]$positions[0]
}
# Create only new owned run roots; preserve all evidence on failure, no auto-cleanup.
foreach($p in @($source,$runRoot,$evidenceDir)){Assert-ProjectPath $p}
if((Test-Path -LiteralPath $runRoot) -or (Test-Path -LiteralPath $evidenceDir)){throw 'HARNESS_RUN_COLLISION'}
$null=New-Item -ItemType Directory -Path $runRoot -ErrorAction Stop
$null=New-Item -ItemType Directory -Path $evidenceDir -ErrorAction Stop
$state='NOT_RUN';$failure=$null;$started=[DateTime]::UtcNow.ToString('o')
try{
 if($Case -in @('I01','I02')){
  $observations.Add(@{integration=$Case;status='DEFERRED';reason='Requires separately reviewed testable source/output transaction; no production orchestration is imported.'})
 }else{
  Add-Type -AssemblyName System.IO.Compression
  $definitions=Get-PinnedDefinitions $source
  # Only the exact eleven pinned FunctionDefinitionAst texts, not G3O top-level code.
  . ([scriptblock]::Create($definitions))
  $base=$runRoot
  switch($Case){
   'P01' {
    Check ((Compute-Crc32 (Bytes '123456789')) -eq [uint32]3421780262) 'crc_known_vector'
    Check ((Compute-Crc32 ([byte[]]::new(0))) -eq [uint32]0) 'crc_empty'
    Check ($null -ne [IO.Compression.ZipArchiveEntry].GetProperty('Crc32')) 'crc_property_available'
   }
   'P02' {
    foreach($a in @('x64','')){
     $props=if($a -eq ''){'<Properties><ResourcePackage>true</ResourcePackage></Properties>'}else{''}
     $p=New-Zip ('package_'+$a) @((Entry 'AppxManifest.xml' (Bytes (Package-Xml $a $props))))
     $r=Inspect-Package $p 'synthetic'
     Check ($r.kind -ceq 'Package' -and $r.identity.architecture -ceq $a -and $r.children.Count -eq 0) 'package_observation'
     if($a -eq ''){Check ($r.identity.resource_package_indicator -ceq 'true') 'resource_indicator'}
    }
   }
   'P03' {
    $bad=0
    foreach($n in @(0,1,2)){
     $nodes='';$entries=[Collections.Generic.List[object]]::new()
     for($i=0;$i -lt $n;$i++){
      $name='child'+$i+'.appx';$nodes+='<Package FileName="'+$name+'" Type="application" Architecture="x64"/>'
      $entries.Add((Entry $name (Bytes 'synthetic-not-installable')))
     }
     $entries.Add((Entry 'AppxMetadata/AppxBundleManifest.xml' (Bytes (Bundle-Xml $nodes))))
     $p=New-Zip ('shape_'+$n) $entries.ToArray()
     $r=Inspect-Package $p 'synthetic'
     $j=$r|ConvertTo-Json -Depth 20;$round=$j|ConvertFrom-Json -Depth 20
     $nested=@($r.children|Where-Object{$_ -is [array]}).Count
     $jsonNested=@($round.children|Where-Object{$_ -is [array]}).Count
     $flat=($r.children.Count -eq $n -and @($round.children).Count -eq $n -and $nested -eq 0 -and $jsonNested -eq 0)
     $observations.Add(@{expected_children=$n;native_count=$r.children.Count;nested=$nested;json_nested=$jsonNested;flat=$flat;json=$j})
     if(-not $flat){$bad++}
    }
    if($bad -gt 0){throw 'KNOWN_F02_CHILDREN_SHAPE_DEFECT'}
    Check ($bad -eq 0) 'flat_children_all_cardinalities'
   }
   'P04' {
    $p=New-Zip 'classes' @((Entry 'exact.appx' (Bytes 'x')),(Entry 'dir/prefix.appx' (Bytes 'x')),(Entry 'dup.appx' (Bytes 'x')),(Entry 'DUP.appx' (Bytes 'x')))
    $doc=Parse-Manifest (Bytes (Bundle-Xml '<Package FileName="EXACT.appx"/><Package FileName="prefix.appx"/><Package FileName="absent.appx"/><Package FileName="dup.appx"/>'))
    With-Zip $p {param($z)
     $rows=Classify-Bundle $z $doc
     Check ($rows.Count -eq 4) 'classification_count'
     $want=@('EXACT_CASEFOLD_MATCH','BASENAME_WITH_PREFIX_CANDIDATE','NO_EXACT_EMBEDDED_MATCH','DUPLICATE_CASEFOLD')
     for($i=0;$i -lt 4;$i++){Check ($rows[$i].match_class -ceq $want[$i] -and $rows[$i].external_or_missing -ceq 'UNDETERMINED') ('class_'+$i)}
     Check ($rows[0].exact_count -eq 1 -and $rows[1].prefixed_candidate_count -eq 1 -and $rows[2].exact_count -eq 0 -and $rows[3].exact_count -eq 2) 'classification_counts'
    }
   }
   'P05' {
    $d=Parse-Manifest (Bytes '<Package xmlns="urn:bluelite:synthetic"><Identity/><Identity Name="second"/></Package>')
    $r=Identity-Info $d.DocumentElement
    Check ($r.name -ceq '' -and $r.architecture -ceq '' -and $r.publisher_present -eq $false) 'diagnostic_not_validation'
    $observations.Add(@{namespace_validation='NOT_IMPLEMENTED_BY_G3O';first_identity_only=$true;dependency_graph='NOT_CERTIFIED'})
   }
   'N01' {
    foreach($x in @('<Package>','<!DOCTYPE Package [<!ENTITY x "fixture">]><Package>&x;</Package>','<!DOCTYPE Package SYSTEM "urn:bluelite:no-external-resolver"><Package/>')){
     Expect-Reject {Parse-Manifest (Bytes $x)} '' @('System.Xml.XmlException')
    }
   }
   'N02' {
    Expect-Reject {Parse-Manifest ([byte[]]::new(0))} 'G3O_HOLD_XML_BOUNDS'
    Expect-Reject {Parse-Manifest ([byte[]]::new(4194305))} 'G3O_HOLD_XML_BOUNDS'
   }
   'N03' {
    $vectors=@(
     @{label='missing';entries=@((Entry 'other.txt' (Bytes 'x')));token='APPX_MANIFEST_MISSING'},
     @{label='identity';entries=@((Entry 'AppxManifest.xml' (Bytes '<Package/>')));token='IDENTITY_MISSING'},
     @{label='root';entries=@((Entry 'AppxManifest.xml' (Bytes '<Wrong/>')));token='APPX_ROOT'},
     @{label='bundleroot';entries=@((Entry 'AppxMetadata/AppxBundleManifest.xml' (Bytes '<Wrong/>')));token='BUNDLE_ROOT'},
     @{label='ambiguous';entries=@((Entry 'AppxManifest.xml' (Bytes (Package-Xml))),(Entry 'AppxMetadata/AppxBundleManifest.xml' (Bytes (Bundle-Xml ''))));token='AMBIGUOUS_MANIFEST_KIND'}
    )
    foreach($v in $vectors){$p=New-Zip $v.label $v.entries;Expect-Reject {Inspect-Package $p 'synthetic'} ('G3O_HOLD_'+$v.token)}
   }
   'N04' {
    $p=New-Zip 'empty' @();Expect-Reject {With-Zip $p {param($z) Check-EntryNames $z}} 'G3O_HOLD_ZIP_ENTRY_COUNT'
    $items=@(for($i=0;$i -lt 4097;$i++){Entry ('e'+$i) ([byte[]]::new(0))})
    $p=New-Zip 'too_many' $items;Expect-Reject {With-Zip $p {param($z) Check-EntryNames $z}} 'G3O_HOLD_ZIP_ENTRY_COUNT'
   }
   'N05' {
    $k=0
    foreach($name in @('../a','x/../a','x\a','/a','a:b',('x'*1025))){
     $p=New-Zip ('unsafe_'+$k) @((Entry $name (Bytes 'x')));$k++
     Expect-Reject {With-Zip $p {param($z) Check-EntryNames $z}} 'G3O_HOLD_ZIP_ENTRY_NAME_UNSAFE'
    }
    $coverageGaps.Add('Empty entry name: requires a separately reviewed malformed-ZIP builder; not exercised through ZipArchive.CreateEntry.')
   }
   'N06' {
    $p=New-Zip 'duplicate_manifest' @((Entry 'AppxManifest.xml' (Bytes (Package-Xml))),(Entry 'APPXMANIFEST.XML' (Bytes (Package-Xml))))
    Expect-Reject {Inspect-Package $p 'synthetic'} 'G3O_HOLD_ZIP_CASEFOLD_DUPLICATE'
   }
   'N07' {
    $p=New-Zip 'zero' @((Entry 'AppxManifest.xml' ([byte[]]::new(0))))
    Expect-Reject {With-Zip $p {param($z) Read-Entry $z.Entries[0] 4194304L}} 'G3O_HOLD_ENTRY_BOUNDS'
    $p=New-Zip 'large' @((Entry 'AppxManifest.xml' ([byte[]]::new(4194305)))) $true
    Expect-Reject {With-Zip $p {param($z) Read-Entry $z.Entries[0] 4194304L}} 'G3O_HOLD_ENTRY_BOUNDS'
    $p=New-Zip 'ratio' @((Entry 'AppxManifest.xml' ([byte[]]::new(1048576)))) $true
    With-Zip $p {param($z) Check (($z.Entries[0].Length/$z.Entries[0].CompressedLength) -gt 1000) 'fixture_ratio_precondition'}
    Expect-Reject {With-Zip $p {param($z) Read-Entry $z.Entries[0] 4194304L}} 'G3O_HOLD_ENTRY_EXPANSION_RATIO'
    $coverageGaps.Add('Stream length/expansion-limit branches: malformed-metadata seams not implemented or claimed tested.')
   }
   'N08' {
    $p=New-Zip 'crc_base' @((Entry 'AppxManifest.xml' (Bytes (Package-Xml))))
    $b=[IO.File]::ReadAllBytes($p);$cd=Find-ZipSignature $b 0x02014b50
    $b[$cd+16]=$b[$cd+16] -bxor 1
    $bad=Join-Path $runRoot 'bad_crc.zip';Write-NewBytes $bad $b
    Expect-Reject {Inspect-Package $bad 'synthetic'} 'G3O_HOLD_ENTRY_CRC32' @('System.IO.InvalidDataException')
    $trunc=Join-Path $runRoot 'truncated.zip';Write-NewBytes $trunc ([byte[]]$b[0..($b.Length-12)])
    Expect-Reject {Inspect-Package $trunc 'synthetic'} '' @('System.IO.InvalidDataException')
    $p=New-Zip 'deflate_base' @((Entry 'AppxManifest.xml' (Bytes (Package-Xml)))) $true
    $b=[IO.File]::ReadAllBytes($p);$lh=Find-ZipSignature $b 0x04034b50
    Check ([BitConverter]::ToUInt16($b,$lh+8) -eq 8) 'fixture_deflate_method'
    $offset=$lh+30+[BitConverter]::ToUInt16($b,$lh+26)+[BitConverter]::ToUInt16($b,$lh+28)
    $b[$offset]=7
    $bad=Join-Path $runRoot 'bad_deflate.zip';Write-NewBytes $bad $b
    Expect-Reject {Inspect-Package $bad 'synthetic'} '' @('System.IO.InvalidDataException')
   }
   'N09' {
    $p=New-Zip 'children' @((Entry 'placeholder' (Bytes 'x')))
    $nodes=('<Package FileName="x.appx"/>'*257);$d=Parse-Manifest (Bytes (Bundle-Xml $nodes))
    Expect-Reject {With-Zip $p {param($z) Classify-Bundle $z $d}} 'G3O_HOLD_BUNDLE_CHILD_COUNT'
    foreach($name in @('../x.appx','x.APPX')){
     $d=Parse-Manifest (Bytes (Bundle-Xml ('<Package FileName="'+$name+'"/>')))
     Expect-Reject {With-Zip $p {param($z) Classify-Bundle $z $d}} 'G3O_HOLD_BUNDLE_CHILD_NAME_UNSAFE'
    }
   }
   'N10' {
    $p=Join-Path $runRoot 'inside.txt';Write-NewBytes $p (Bytes 'owned')
    Assert-Root $p;Check $true 'owned_path_accepted'
    $sibling=[IO.Path]::GetDirectoryName($runRoot)
    Expect-Reject {Assert-Root $sibling} 'G3O_HOLD_OUTSIDE_CWORK'
    Expect-Reject {Assert-Root (Join-Path $runRoot 'missing.txt')} '' @('System.Management.Automation.ItemNotFoundException')
    $coverageGaps.Add('Reparse/race: no junction/symlink creation or unapproved path reads; separate containment validation remains pending.')
   }
   'N11' {
    $p=Join-Path $runRoot 'pin.txt';Write-NewBytes $p (Bytes 'pin fixture')
    $hash=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash
    Pinned-Sha256 $p $hash;Check $true 'matching_fixture_sha'
    Expect-Reject {Pinned-Sha256 $p ('0'*64)} 'G3O_HOLD_SOURCE_SHA256_MISMATCH'
   }
   'N12' {
    $p=Join-Path $runRoot 'altered_source.ps1'
    $b=[IO.File]::ReadAllBytes($source);$changed=[byte[]]::new($b.Length+1)
    [Array]::Copy($b,$changed,$b.Length);$changed[$changed.Length-1]=32
    Write-NewBytes $p $changed
    Expect-Reject {Get-PinnedDefinitions $p} 'HARNESS_SOURCE_SHA'
    Check ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ceq $sourceSha) 'original_source_unchanged'
   }
   'N13' {
    $p=Join-Path $runRoot 'recorder_sample.json'
    $sample=$null
    try{throw 'SYNTHETIC_UNEXPECTED_EXCEPTION'}catch{$sample=Failure-State $_}
    Check ($sample.outcome -ceq 'FAIL' -and $sample.failure.message -ceq 'SYNTHETIC_UNEXPECTED_EXCEPTION') 'unexpected_exception_is_fail'
    Write-NewJson $p $sample
    $before=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash
    Expect-Reject {Write-NewJson $p @{outcome='PASS'}} '' @('System.IO.IOException')
    Check ((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash -ceq $before) 'collision_keeps_original'
    $r=Get-Content -LiteralPath $p -Raw|ConvertFrom-Json
    Check ($r.outcome -ceq 'FAIL' -and $r.failure.message -ceq 'SYNTHETIC_UNEXPECTED_EXCEPTION') 'failure_sample_retained'
    try{throw 'KNOWN_F02_CHILDREN_SHAPE_DEFECT'}catch{$sample=Failure-State $_}
    Check ($sample.outcome -ceq 'HOLD') 'known_defect_not_pass'
    Expect-Reject {throw 'SYNTHETIC_EXPECTED_EXCEPTION'} 'SYNTHETIC_EXPECTED_EXCEPTION'
   }
  }
  $state=if($coverageGaps.Count -eq 0){'PASS'}else{'HOLD'}
 }
}catch{
 $captured=Failure-State $_
 $failure=$captured.failure;$state=$captured.outcome
}finally{
 $out=Join-Path $evidenceDir 'FixtureReceipt.json'
 $record=[ordered]@{
  schema='BlueLite.G3O.IsolatedFixture.v1';operation_id=$runId;case=$Case
  started_utc=$started;completed_utc=[DateTime]::UtcNow.ToString('o');outcome=$state
  source_path=$source;source_sha256=$sourceSha
  harness_path=$PSCommandPath;harness_sha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
  powershell=$PSVersionTable.PSVersion.ToString();dotnet=[Environment]::Version.ToString()
  run_root=$runRoot;evidence_root=$evidenceDir
  checks=@($checks.ToArray());observations=@($observations.ToArray());failure=$failure
  coverage_gaps=@($coverageGaps.ToArray());complete_group_coverage=($coverageGaps.Count -eq 0 -and $state -eq 'PASS')
  g3o_full_script_executed=$false;original_cache_accessed=$false;real31_inspect='NOT_RUN';image_mutation=$false
  integration_I01='NOT_RUN';integration_I02='NOT_RUN';qa='PENDING_SEPARATE_NATIVE_VERIFICATION'
  one_next='Independently verify this exact receipt SHA, fields and owned fixture evidence in a fresh process; no next group before verification.'
 }
 Write-NewJson $out $record
 $outSha=(Get-FileHash -LiteralPath $out -Algorithm SHA256).Hash
 Write-Output "G3O_FIXTURE_RECORDED|CASE=$Case|OUTCOME=$state|PATH=$out|SHA256=$outSha|QA=PENDING"
}
if($state -eq 'FAIL'){exit 1}
if($state -eq 'HOLD' -or $state -eq 'NOT_RUN'){exit 2}
exit 0
