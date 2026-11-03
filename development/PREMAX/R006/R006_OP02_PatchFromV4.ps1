[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
$base='C:\work\PREMAX-work\R006_26300_MAXPRE_v5_Package'
$root=Join-Path $base '02_Drafts\PackageRoot'
$receipt=Join-Path $base '04_Receipts\R006_OP02_PolicyDelta.json'
if(Test-Path -LiteralPath $receipt){throw 'R006_OP02_IMMUTABLE_RECEIPT_EXISTS'}
$source=Get-Content -LiteralPath (Join-Path $base '04_Receipts\R006_OP01_SourceExtraction.json') -Raw|ConvertFrom-Json
if($source.verdict -ne 'PASS'){throw 'SOURCE_NOT_VERIFIED'}
$originalManifest=Join-Path $root 'BlueLite_Package_SHA256.txt'
if((Get-ChildItem -LiteralPath $root -Recurse -File).Count -ne 36){throw 'SOURCE_36_EXPECTED'}
$before=@(Get-ChildItem -LiteralPath $root -Recurse -File|ForEach-Object{
 $rel=[IO.Path]::GetRelativePath($root,$_.FullName).Replace('\','/')
 [pscustomobject]@{path=$rel;sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}
})
$cap=Join-Path $root 'BlueLite\BlueLite_CapabilityRemovePatterns.txt'
$s=[IO.File]::ReadAllText($cap)
$target='Language.Basic~~~en-US~0.0.1.0'
if(([regex]::Matches($s,'(?m)^'+[regex]::Escape($target)+'\r?$')).Count -ne 1){throw 'EXPECTED_EXACT_BASIC_GREEN_LINE_NOT_FOUND_ONCE'}
$s=[regex]::Replace($s,'(?m)^'+[regex]::Escape($target)+'\r?$','# F02: Language.Basic en-US retained for offline CBS owner/dependency gate; native 26300.9818 0x800F0825')
[IO.File]::WriteAllText($cap,$s,[Text.UTF8Encoding]::new($false))
$prof=Join-Path $root 'BlueLite\BlueLite_Profile.ini'
$s=[IO.File]::ReadAllText($prof)
if(-not $s.Contains('Profile=MAX_PRE_26300_V4')){throw 'PROFILE_PRESTATE_UNEXPECTED'}
[IO.File]::WriteAllText($prof,$s.Replace('Profile=MAX_PRE_26300_V4','Profile=MAX_PRE_26300_V5'),[Text.UTF8Encoding]::new($false))
$readme=Join-Path $root 'README-FIRST.txt'
$s=[IO.File]::ReadAllText($readme)
if(-not $s.Contains('OVERLAY v4') -or -not $s.Contains('BlueLite MAX_PRE v4 ZIP')){throw 'README_OLD_VERSION_MISSING'}
$s=$s.Replace('OVERLAY v4','OVERLAY v5').Replace('BlueLite MAX_PRE v4 ZIP','BlueLite MAX_PRE v5 ZIP')
$s=$s.Replace('true 26300 CBS MAX_PRE/ISO has NOT been operator runtime-tested for this v4.','true 26300.9818 v4 WIM/ISO was operator-runtime PASS; this v5 policy-delta is not yet downloaded/built natively.')
$s+=[Environment]::NewLine+'V5 STRICT DEPENDENCY HANDOFF: The proven v4 engine and converter/reconstruction flow are unchanged. Only the failed Basic en-US GREEN removal attempt is deferred; AppInstaller (F01), Basic CBS owner (F02), WMIC exceptions (F03), and post-debloat/NTLite/VM require later dedicated work. BlueLite may emit warnings for these. Do not claim ISO <=5GB or installed <=15.5GB until validated.'+[Environment]::NewLine
[IO.File]::WriteAllText($readme,$s,[Text.UTF8Encoding]::new($false))
$mut=Join-Path $root 'MUTATION-SCOPE-REVIEW.txt'
$s=[IO.File]::ReadAllText($mut)
if(-not $s.Contains('v4') -or -not $s.Contains('GA 26300 WIM/CBS/ISO native execution is NOT YET CERTIFIED for this v4.')){throw 'MUTATION_DOC_PRESTATE_UNEXPECTED'}
$s=$s.Replace('v4','v5')
$s=$s.Replace('GA 26300 WIM/CBS/ISO native execution is NOT YET CERTIFIED for this v5.','Proven 26300.9818 v4 conversion and MAX_PRE native run produced install.wim/ISO. V5 policy-only delta has NOT yet been runtime run.')
$s+=[Environment]::NewLine+'F01 DesktopAppInstaller original native remove refused: later owned offline/AppX dependency phase. F02 Language.Basic en-US original 0x800F0825: retained in UUP v5 and deferred for future scoped CBS owner proof; no forced package/registry removal. F03 WMIC invalid selectors remain native guarded Superseded-only SKIP; post-script can revisit. NTLite then VMware Workstation Pro follow after the current UUP phase.'+[Environment]::NewLine
[IO.File]::WriteAllText($mut,$s,[Text.UTF8Encoding]::new($false))
$integrity=Join-Path $root 'INTEGRITY-AND-LIMITS.txt'
$s=@'
v5 SOURCE-BOUND QA / EVIDENCE LIMITS (2026-11-03)
================================================
R004 v4 proven operator native 26300.9818 MAX_PRE: real download/
source SHA1 verification, original converter WIM reconstruction, protected
WIM mutation, native export and ISO created, health and poststate evidence.
Golden WIM SHA256 3D606513D9C1D2B157AAFD6925FF1655C9A48520CE5D4219AF2ED654C82753E4
Golden ISO SHA256 570BD12E9DBBBB51CACFB3B9A403326AA5000FAC1D2F7E44482EFCC154CB3736
This v5 source is a conservative policy-only v4 successor: failed
Language.Basic en-US 0x800F0825 removal attempt excluded from GREEN.
DesktopAppInstaller 1->1 and WMIC Superseded rejects remain later stage.
Original manufacturer UUP Dump launcher, source UUID, converter flow, apps
dependency resolution, FoD input and WinRE/boot media remain untouched.
V5 native static AST/preflight and manifest PASS is NOT proof of v5 full
download/ISO/VM; unknown 26300 converters are strictly fail-closed.
Original v4 native ISO was 6822354944 B, above project ~5GB ISO goal;
actual installed footprint, speed and future update servicing NOT measured
or release-certified by this package. Continue offline PS -> NTLite ->
VMware Workstation Pro only after next-run native evidence.
Generated logs are compacted to exactly one last-timestamp verified
BlueLite_EVIDENCE_*.zip in the operator-selected UUP root.
'@
[IO.File]::WriteAllText($integrity,$s,[Text.UTF8Encoding]::new($false))
$order=Join-Path $root '00-EXECUTION-ORDER.txt'
$s=[IO.File]::ReadAllText($order)
if(-not $s.Contains('BlueLite MAX_PRE v4 26300.x')){throw 'ORDER_VERSION_PRESTATE'}
$s=$s.Replace('BlueLite MAX_PRE v4 26300.x','BlueLite MAX_PRE v5 26300.x')
$s+=[Environment]::NewLine+'V5 SOURCE-BOUND DELTA: original v4 engine and 26300 reconstruction unchanged; Language.Basic en-US 0x800F0825 excluded from unconditional GREEN attempt (retained for offline dependency gate). F01 AppInstaller, F03 WMIC, full post-debloat/NTLite/VM remain subsequent phases, not invented pre-download pruning.'+[Environment]::NewLine
[IO.File]::WriteAllText($order,$s,[Text.UTF8Encoding]::new($false))
# SHA list for all packaged members except the manifest itself; no external dependency.
$files=@(Get-ChildItem -LiteralPath $root -Recurse -File|Where-Object{$_.FullName -ne $originalManifest})
$hashLines=@($files|ForEach-Object{
 $rel=[IO.Path]::GetRelativePath($root,$_.FullName).Replace('\','/')
 [pscustomobject]@{rel=$rel;sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}
}|Sort-Object rel|ForEach-Object{$_.sha256+' *'+$_.rel})
if($hashLines.Count -ne 35){throw 'PACKAGE_MANIFEST_MUST_HAVE_35_MEMBERS'}
[IO.File]::WriteAllText($originalManifest,($hashLines -join [Environment]::NewLine)+[Environment]::NewLine,[Text.UTF8Encoding]::new($false))
$after=@(Get-ChildItem -LiteralPath $root -Recurse -File|ForEach-Object{
 $rel=[IO.Path]::GetRelativePath($root,$_.FullName).Replace('\','/')
 [pscustomobject]@{path=$rel;sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}
})
if($after.Count -ne 36){throw 'FINAL_SOURCE_FILE_COUNT_NOT_36'}
$changes=@(foreach($a in $after){
 $b=@($before|Where-Object{$_.path -ceq $a.path})
 if($b.Count -ne 1){throw ('UNEXPECTED_ADDED_FILE '+$a.path)}
 if($b[0].sha256 -cne $a.sha256){[pscustomobject]@{file=$a.path;before=$b[0].sha256;after=$a.sha256}}
})
$expectedChanged=@('00-EXECUTION-ORDER.txt','BlueLite/BlueLite_CapabilityRemovePatterns.txt','BlueLite/BlueLite_Profile.ini','BlueLite_Package_SHA256.txt','INTEGRITY-AND-LIMITS.txt','MUTATION-SCOPE-REVIEW.txt','README-FIRST.txt')
if($changes.Count -ne 7 -or (@($changes.file|Sort-Object) -join '|') -cne (@($expectedChanged|Sort-Object) -join '|')){throw ('UNEXPECTED_SOURCE_DELTA '+(@($changes.file) -join '|'))}
$o=[pscustomobject]@{schema='BlueLite.R006.OP02.v1';utc=[DateTime]::UtcNow.ToString('o');operation='ONLY_SEVEN_DELIBERATE_V5_SOURCE_AND_DOCUMENT_CHANGES';root=$root;file_count=36;modified_count=$changes.Count;changed=$changes;unmodified_count=29;original_PowerShell_and_CMD_engine_unchanged=$true;original_ConvertConfig_unchanged=$true;UUP_Windows_queue_filter_unchanged=$true;Basic_Green_removed=$true;golden_image_mutation=$false;status='PASS';next='native independent verify all 35 package manifest rows, all PS7 AST, isolated vendor UUP preflight'}
$b=[Text.UTF8Encoding]::new($false).GetBytes(($o|ConvertTo-Json -Depth 9))
$f=[IO.File]::Open($receipt,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$f.Write($b,0,$b.Length)}finally{$f.Dispose()}
Write-Output ('R006_OP02_DELIBERATE_7_FILE_DELTA_PASS SHA256='+(Get-FileHash -LiteralPath $receipt -Algorithm SHA256).Hash+' BasicRemoved=true NonchangedEngine=29')
