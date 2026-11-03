[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
$base='C:\work\PREMAX-work\R007_26300_SourcePrecise_PreCut'
$root=Join-Path $base '02_Drafts\v6_OverlayRoot'
$receipt=Join-Path $base '04_Evidence\R007_OP05B_CodeDelta.json'
if(Test-Path -LiteralPath $receipt){throw 'R007_OP05B_IMMUTABLE_ALREADY_EXISTS'}
$original='C:\work\logs\BlueLite_UUP_MAXPRE_26300x_v5_20261103T192513569Z.zip'
$expected='0573CE971A3C956E37A2B100E56BA30EC1E6914D42AF31606AF19441F8495658'
if((Get-FileHash -LiteralPath $original -Algorithm SHA256).Hash -ne $expected){throw 'ORIGINAL_V5_ZIP_CHANGED'}
$manifest=Join-Path $root 'BlueLite_Package_SHA256.txt'
$before=@(Get-ChildItem -LiteralPath $root -File -Recurse|ForEach-Object{
 [pscustomobject]@{name=[IO.Path]::GetRelativePath($root,$_.FullName).Replace('\','/');sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}
})
if($before.Count -ne 38){throw ('SOURCE_EXPECTED_38_WITH_TWO_NEW_FILES '+$before.Count)}
function Change-Exact([string]$file,[string]$from,[string]$to) {
 $p=Join-Path $root $file
 $s=[IO.File]::ReadAllText($p)
 if(([regex]::Matches($s,[regex]::Escape($from))).Count -ne 1){throw ('PATCH_ANCHOR_NOT_UNIQUE '+$file)}
 [IO.File]::WriteAllText($p,$s.Replace($from,$to),[Text.UTF8Encoding]::new($false))
}
$nl=[Environment]::NewLine
$pre='BlueLite\BlueLite_Preflight.ps1'
$anchor='  $launcher=[IO.File]::ReadAllText((Join-Path $root ''uup_download_windows.cmd''))'
$check=@'
  # R007 source identity is mandatory BEFORE download; full 1:1:1 + D4 follows after URL queue retrieval.
  foreach($n in @('List of files UUP.txt','File_renaming_script.cmd','SHA-1 checksums file.txt')){
   $input=Join-Path $root $n
   if(-not(Test-Path -LiteralPath $input -PathType Leaf) -or (Get-Item -LiteralPath $input).Length -lt 100){
    throw ('SOURCE_TRIAD_REQUIRED_BEFORE_DOWNLOAD: '+$n)
   }
  }
'@
Change-Exact $pre $anchor ($check+$nl+$anchor)
$triad='BlueLite\BlueLite_SourceTriadGate.ps1'
$p=Join-Path $root $triad
$s=[IO.File]::ReadAllText($p)
$begin=$s.IndexOf(' if($present.Count -eq 0){',[StringComparison]::Ordinal)
$end=$s.IndexOf(' if($present.Count -ne 3){',[StringComparison]::Ordinal)
if($begin -lt 0 -or $end -le $begin){throw 'OPTIONAL_TRIAD_BRANCH_NOT_EXACT'}
$s=$s.Substring(0,$begin)+$s.Substring($end)
$s=$s.Replace('Incomplete source triad:','SOURCE_TRIAD_REQUIRED: incomplete source triad:')
[IO.File]::WriteAllText($p,$s,[Text.UTF8Encoding]::new($false))
$cmd='BlueLite\BlueLite_UUP.cmd'
$anchorCmd='echo Downloading complete Windows reference/delta source...'
$insert=@'
echo === Frozen D4 FoD/AppX precut decision and reconstruction-keep ledger ===
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BL%\BlueLite_SourcePrecutDecision.ps1" -WindowsQueueFile "%uupScript%" -AppsQueueFile "%appsScript%" -SourceTriadLog ".\%LOG%\SourceTriad.log" -LogPath ".\%LOG%\SourcePrecutDecision.json"
if errorlevel 1 goto :FAIL

'@
Change-Exact $cmd $anchorCmd ($insert+$anchorCmd)
$readme='README-FIRST.txt'
$p=Join-Path $root $readme
$s=[IO.File]::ReadAllText($p)
if($s.IndexOf('5) OPTIONAL:',[StringComparison]::Ordinal) -lt 0){throw 'README_OPTIONAL_MARKER_MISSING'}
$s=$s.Replace('5) OPTIONAL:','5) MANDATORY:')
$s=$s.Replace('Presence of any one requires all three. Hash+name+GUID+D4 exact compare.','All three are REQUIRED and tied to the chosen source; preflight refuses any missing file BEFORE download. Full 1:1:1 + D4 equality is checked before Windows payload transfer.')
$s=$s.Replace('OVERLAY v5','OVERLAY v6').Replace('MAX_PRE v5 ZIP','MAX_PRE v6 ZIP')
$s+=$nl+'R007 strict: required source triad, 98/98 native proof for 26300.9818, generic other 26300 sources require their OWN three metadata files. SourcePrecutDecision.json records candidate/KEEP before Windows transfer. No unsupported Windows FoD source omission; 62/62 current FoD candidates appear in selected CompDB, full converter owner graph still OPEN. Keep five AppX top-level staging identities + framework dependencies.'+$nl
$s+='RECOVERY-ON-DEMAND: SkipWinRE=1 is already effective; the bundled Recovery-on-Demand.txt is metadata only OUTSIDE base ISO. Preserve Setup sources/boot.wim; do not claim another 700MB or functional native recovery without separate VM test.'+$nl
[IO.File]::WriteAllText($p,$s,[Text.UTF8Encoding]::new($false))
$profile='BlueLite\BlueLite_Profile.ini'
Change-Exact $profile 'Profile=MAX_PRE_26300_V5' 'Profile=MAX_PRE_26300_V6'
foreach($doc in @('00-EXECUTION-ORDER.txt','INTEGRITY-AND-LIMITS.txt','MUTATION-SCOPE-REVIEW.txt')){
 $p=Join-Path $root $doc
 $s=[IO.File]::ReadAllText($p)
 if(-not $s.Contains('v5')){throw ('DOC_VERSION_MISSING '+$doc)}
 $s=$s.Replace('v5','v6')
 $s+=$nl+'R007 v6 = source contract first, triad required before network, full D4 equality before Windows payload. FoD candidates are classified but retained for reconstruction until approved converter dependency closure. Existing v5/v4 MAX_PRE WIM GREEN actions unchanged; F01 AppInstaller + F02 Basic CBS owner deferred. SkipWinRE=1 already enabled; Setup boot.wim preserved. Following stages offline PS -> NTLite Business -> VMware Workstation Pro.'+$nl
 [IO.File]::WriteAllText($p,$s,[Text.UTF8Encoding]::new($false))
}
$sourceCode=Join-Path $root 'BlueLite\BlueLite_SourcePrecutDecision.ps1'
$recovery=Join-Path $root 'Recovery-on-Demand.txt'
if(-not(Test-Path -LiteralPath $sourceCode -PathType Leaf) -or -not(Test-Path -LiteralPath $recovery -PathType Leaf)){throw 'NEW_FILES_MISSING'}
$all=@(Get-ChildItem -LiteralPath $root -File -Recurse)
if($all.Count -ne 38){throw ('SOURCE_AFTER_PATCH_NOT_38 '+$all.Count)}
$records=@(foreach($f in $all|Where-Object{$_.FullName -ne $manifest}){
 [pscustomobject]@{name=[IO.Path]::GetRelativePath($root,$f.FullName).Replace('\','/');sha256=(Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash}
})
$records=@($records|Sort-Object name)
if($records.Count -ne 37){throw 'MANIFEST_EXPECTED_37'}
$lines=@($records|ForEach-Object{$_.sha256+' *'+$_.name})
[IO.File]::WriteAllText($manifest,($lines -join $nl)+$nl,[Text.UTF8Encoding]::new($false))
$after=@(Get-ChildItem -LiteralPath $root -File -Recurse|ForEach-Object{
 [pscustomobject]@{name=[IO.Path]::GetRelativePath($root,$_.FullName).Replace('\','/');sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}
})
$changes=@(foreach($a in $after){
 $orig=@($before|Where-Object{$_.name -ceq $a.name})
 if($orig.Count -ne 1){throw ('UNEXPECTED_SOURCE_PATH '+$a.name)}
 if($orig[0].sha256 -ne $a.sha256){[pscustomobject]@{name=$a.name;before=$orig[0].sha256;after=$a.sha256}}
})
$expectedChanged=@('00-EXECUTION-ORDER.txt','BlueLite/BlueLite_Preflight.ps1','BlueLite/BlueLite_SourceTriadGate.ps1','BlueLite/BlueLite_UUP.cmd','BlueLite/BlueLite_Profile.ini','BlueLite_Package_SHA256.txt','README-FIRST.txt','INTEGRITY-AND-LIMITS.txt','MUTATION-SCOPE-REVIEW.txt')
if($changes.Count -ne 9 -or (@($changes.name|Sort-Object) -join '|') -cne (@($expectedChanged|Sort-Object) -join '|')){throw ('UNEXPECTED_PATCH_SET '+(@($changes.name) -join '|'))}
$r=[ordered]@{schema='BlueLite.R007.OP05B.v1';utc=[DateTime]::UtcNow.ToString('o');operation='MANDATORY_TRIAD_EARLY_GATE_AND_98_FOD_CLASSIFIER_PLUS_EXTERNAL_RECOVERY';original_v5_sha256=$expected;root=$root;package_files=$all.Count;sha_manifest_entries=$records.Count;modified_existing_count=$changes.Count;modified=$changes;added=@('BlueLite/BlueLite_SourcePrecutDecision.ps1','Recovery-on-Demand.txt');unchanged_existing_count=27;proven_WIM_MAX_PRE_script_modified=$false;UUP_converter_modified=$false;Windows_D4_queue_pruned=$false;WinRE_base_ISO_payload_added=$false;golden_image_modified=$false;verdict='SOURCE_DELTA_DONE_QA_PENDING';one_next='OP05C_NATIVE_PS7_PS51_AST_FIXTURE_POSITIVE_NEGATIVE_AND_SHA'}
$b=[Text.UTF8Encoding]::new($false).GetBytes(($r|ConvertTo-Json -Depth 10))
$f=[IO.File]::Open($receipt,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$f.Write($b,0,$b.Length)}finally{$f.Dispose()}
Write-Output ('R007_OP05B_NINE_CHANGED_TWO_ADDED_38_FILES_PASS sha='+(Get-FileHash -LiteralPath $receipt -Algorithm SHA256).Hash+' manifest='+$records.Count)
