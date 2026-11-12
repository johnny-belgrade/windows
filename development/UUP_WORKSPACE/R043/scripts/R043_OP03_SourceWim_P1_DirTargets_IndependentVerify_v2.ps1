# R043 OP03 second native bounded read-only WIM path evidence, v2 (first inline verifier invalid regex, no mutations/receipt).
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$logs='C:\work\_UUP\R043_PREMAX_P1_20261112\BlueLite_Logs'
$src=Join-Path $logs 'R043_OP02_SourceWim_P1_DirTargets_Producer.json'
$out=Join-Path $logs 'R043_OP03_SourceWim_P1_DirTargets_IndependentVerify.json'
if([IO.File]::Exists($out)){throw 'OP03_SECOND_QA_ALREADY_EXISTS'}
$p=Get-Content -LiteralPath $src -Raw|ConvertFrom-Json
if($p.status -ne 'R043_OP02_ORIGINAL_R042_9974_WIM_P1_BOUNDED_FILE_PATH_METADATA_ONLY_PRODUCER_PASS' -or @($p.results).Count -ne 9){throw 'P1_FIRST_SCOPED_WIM_RESULT_INCOMPLETE'}
$native=Get-Content 'C:\work\_UUP\R042_FULL_ONECMD_9974_20261111\BlueLite_Logs\BlueLite_R029_RESULT.json' -Raw|ConvertFrom-Json
if($native.build -ne '26300.9974' -or $native.install_wim -ne $p.originalWim -or $native.install_wim_sha256 -ne $p.sourcePinnedWimPhysicalSha256 -or [IO.FileInfo]::new($p.originalWim).Length -ne $p.originalWimBytes){throw 'P1_ORIGINAL_WIM_SOURCE_R029_NOT_BOUND'}
$expectedAbsent=@('Edge','EdgeWebView','OneDriveProgramFiles','OneDriveX86','RecallSystemApp','EdgePlatformSystemApp')
$present=@('CLI_help','WinREinstalled','AIXSystemApp')
$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$names=@()
$bytes=0L
foreach($item in $p.results){
 if(-not $seen.Add([string]$item.name)){throw 'P1_DUPLICATE_NATIVE_PATH_OBSERVATION'}
 $f=[IO.FileInfo]::new([string]$item.log)
 if(-not $f.Exists -or $f.Length -gt 1000000 -or (Get-FileHash $f.FullName -Algorithm SHA256).Hash -ne $item.logSHA){throw ('P1_NATIVE_LOG_SHA_MISSING_'+$item.name)}
 $body=[IO.File]::ReadAllText($f.FullName)
 if(-not $body.Contains('NATIVE_EXIT: '+[string]$item.nativeExit)){throw ('NATIVE_EXIT_LOG_DISAGREEMENT_'+$item.name)}
 if($item.name -in $expectedAbsent){
  if($item.nativeExit -ne 49 -or -not $body.Contains('The path does not exist in the WIM image.')){throw ('PATH_ABSENCE_NOT_PROVEN_'+$item.name)}
 } elseif($item.name -in $present){
  if($item.nativeExit -ne 0){throw ('EXISTING_PATH_OR_HELP_NATIVE_NOT_ZERO_'+$item.name)}
 }else{throw ('UNEXPECTED_P1_SCOPE_'+$item.name)}
 $names+=[pscustomobject]@{target=$item.name;nativeExit=$item.nativeExit;logSHA=$item.logSHA;bytes=$f.Length}
 $bytes+=$f.Length
}
$winre=[IO.File]::ReadAllText((Join-Path $logs 'R043_OP02_WinREinstalled.txt'))
if(-not $winre.Contains('ReAgent.xml') -or $winre.Contains('\winre.wim')){throw 'SOURCE_WINRE_NOT_ONLY_NON_WIM_RECOVERY_FILES'}
$aix=[IO.File]::ReadAllText((Join-Path $logs 'R043_OP02_AIXSystemApp.txt'))
if(-not $aix.Contains('MicrosoftWindows.Client.AIX_cw5n1h2txyewy') -or -not $aix.Contains('Reference Count   = 21') -or -not $aix.Contains('Uncompressed size = ')){throw 'AIX_PRESENCE_AND_SHARED_RESOURCE_NOT_CONFIRMED'}
$zip='C:\work\_UUP\R042_PREMAX_Delivery_20261111\BlueLite_PREMAX_R042_Universal26300x_NoPrompt_DRAFT.zip'
if((Get-FileHash $zip -Algorithm SHA256).Hash -ne '99BAF4E3407CF5F964DB2418F00A010C485F2622392ACE27C132D3BF0C2A21E1'){throw 'SOURCE_PORTABLE_ZIP_DRIFT'}
$vms=@(Get-VM)
if($vms.Count -ne 3 -or @($vms|Where-Object{$_.State -ne 'Off'}).Count -or @(Get-WindowsImage -Mounted).Count -or @(Get-Disk).Count -ne 1 -or ([IO.DriveInfo]::new('C')).AvailableFreeSpace -lt 60GB){throw 'HOST_SAFETY_OR_DISK_BUDGET_DRIFT'}
$r=[ordered]@{
 utc=[DateTime]::UtcNow.ToString('o')
 status='R043_OP03_ORIGINAL_9974_WIM_P1_SCOPED_PATHS_SIX_ABSENT_AIX_SHARED_WINRE_OMITTED_SECOND_NATIVE_PASS'
 firstProducerSHA=(Get-FileHash $src -Algorithm SHA256).Hash
 nativeLogs=$names
 sourceWIM=$p.originalWim
 sourceWIMBytes=$p.originalWimBytes
 sourceWIMpinnedSHA=$p.sourcePinnedWimPhysicalSha256
 numberOfExistingScopedPaths=2
 missingScopedPaths=$expectedAbsent
 sourceP1WinREwinreWimAbsent=$true
 sourceAIxaixDirectoryPresentWithSharedReferences=$true
 originalUserPortableZipSHA=(Get-FileHash $zip -Algorithm SHA256).Hash
 allVmsOff=$true
 WIMmounted=0
 hostMountedExtraVHD=0
 totalBoundedTextBytes=$bytes
 CfreeGiB=[math]::Round(([IO.DriveInfo]::new('C')).AvailableFreeSpace/1GB,3)
 largeP1PhysicalGainByOwner='NOT_PROVEN_YET'
 furtherP1NativeOwnerAnalysisRequired=$true
}
[IO.File]::WriteAllText($out,(($r|ConvertTo-Json -Depth 8)+[Environment]::NewLine),[Text.UTF8Encoding]::new($false))
[pscustomobject]@{status=$r.status;checkedPaths=$names.Count;smallLogsBytes=$bytes;CfreeGiB=$r.CfreeGiB;sourceSHA=$p.sourcePinnedWimPhysicalSha256;receiptSHA=(Get-FileHash $out -Algorithm SHA256).Hash}|ConvertTo-Json -Compress
