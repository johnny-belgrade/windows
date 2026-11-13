# R043 OP41: independent PowerShell 7 only, source-only targeted native wimlib QA of OP39 original 26300.9974 WIM top128 owner map.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$root='C:\work\_UUP\R043_PREMAX_P1_20261112'
$receipt=Join-Path $root 'BlueLite_Logs\R043_OP41_WimTop128OwnerPaths_IndependentVerify.json'
if([IO.File]::Exists($receipt)){throw 'R043_OP41_IMMUTABLE_INDEPENDENT_RECEIPT_ALREADY_EXISTS'}
$first='C:\work\logs\R043_OP09_9974_OriginalWimUniqueBlobAccounting_Producer.json'
$producer=Join-Path $root 'BlueLite_Logs\R043_OP39_WimTop128OwnerPaths_Producer.json'
$source='C:\work\logs\R043_OP07_P1_ActualRecipeAndOwnerCandidates_Producer.json'
$report=[ordered]@{
 schema='BlueLite.R043.OP41.SourceOnlyIndependentTargetedWimDirectoryQA.v1'
 utc=[DateTime]::UtcNow.ToString('o')
 status='HOLD'
 producerSHA=''
 originalWim=''
 originalWimBytes=0
 nativeWimlibSha=''
 originalTop128Count=0
 actualMappedCount=0
 originalDirectoryPaths=0
 originalDirectoryHashes=0
 top128SourceDrift=@()
 top128Unmapped=@()
 mappedIncomplete=@()
 truncatedOwners=@()
 oneDriveRefPaths=@()
 oneDriveTargetNativeExit=$null
 edgeTargetNativeExit=$null
 oneDriveTargetedSHAconfirmed=$false
 edgeTargetedSHAconfirmed=$false
 oneDriveTargetedOutput=@()
 edgeTargetedOutput=@()
 protectedWinSxSCandidateRows=@()
 wimMounts=$null
 VMsOff=$null
 CfreeBytes=0
 physicalSavingsProven=0
 imageMutated=$false
 newIsolatedSpaceCreated=$false
 error=''
}
try {
 $a=Get-Content -LiteralPath $first -Raw|ConvertFrom-Json
 $r=Get-Content -LiteralPath $producer -Raw|ConvertFrom-Json
 $d=Get-Content -LiteralPath $source -Raw|ConvertFrom-Json
 $wim=[string]$d.actualOriginalWIM
 $exe=[string]$d.actualWimlibVendorExe
 $report.originalWim=$wim
 $report.originalWimBytes=[IO.FileInfo]::new($wim).Length
 $report.nativeWimlibSha=(Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash
 $report.producerSHA=(Get-FileHash -LiteralPath $producer -Algorithm SHA256).Hash
 $report.originalTop128Count=@($a.largestCompressedBlobs).Count
 $report.actualMappedCount=[int]$r.uniqueTopResourcesWithAtLeastOnePath
 $report.originalDirectoryPaths=[long]$r.detailedFilePaths
 $report.originalDirectoryHashes=[long]$r.detailedStreamHashes
 $top=@{}
 foreach($entry in @($a.largestCompressedBlobs)){$top[[string]$entry.sha1]=$entry}
 $report.top128SourceDrift=@(foreach($x in @($r.topResourceFileOwners)){
  $match=$top[[string]$x.sha1]
  if($null -eq $match -or [long]$match.compressedBytes -ne [long]$x.compressedBytes -or [long]$match.uncompressedBytes -ne [long]$x.uncompressedBytes -or [int]$match.refCount -ne [int]$x.refCount){[string]$x.sha1}
 })
 $report.top128Unmapped=@($r.topResourceFileOwners|Where-Object {$_.matchedPathCount -eq 0}|Select-Object sha1,compressedBytes,refCount)
 $report.mappedIncomplete=@($r.topResourceFileOwners|Where-Object {$_.matchedPathCount -gt 0 -and -not $_.allSourceWimReferencesAccounted}|Select-Object sha1,compressedBytes,refCount,matchedPathCount)
 $report.truncatedOwners=@($r.topResourceFileOwners|Where-Object {$_.truncatedPathCount -gt 0}|Select-Object sha1,truncatedPathCount)
 $one=@($r.topResourceFileOwners|Where-Object sha1 -eq '0x054ff47240288181f2f472c9dc4a04c9c194d083')
 $edge=@($r.topResourceFileOwners|Where-Object sha1 -eq '0x996901b9df12d46326e040404c50cfd66c7fca4a')
 if($one.Count -eq 1){$report.oneDriveRefPaths=@($one[0].filePaths)}
 $report.protectedWinSxSCandidateRows=@($r.topResourceFileOwners|
  Where-Object {$_.refCount -eq 1 -and @($_.filePaths|Where-Object {$_ -like '\Windows\WinSxS\*' -and ($_ -match '(?i)onedrive-setup|edge-webview')}).Count -gt 0}|
  Select-Object -First 16 sha1,compressedBytes,refCount,filePaths)
 if($report.originalWimBytes -ne 5602983183 -or $report.nativeWimlibSha -ne '01168A00FFC84EBFA1BD3B9C841214ED114B9AE4E9B23D555C0686448FD56BDE' -or $report.producerSHA -ne 'CA4CFC28F25AEFB1DC25F7624956D2DB043B0DB7479363687C7B10B52224B7B8'){throw 'SOURCE_OR_PRODUCER_SHA_MISMATCH'}
 if($a.unique_blobs -ne 81351 -or @($a.largestCompressedBlobs).Count -ne 128 -or $r.nativeWimlibExit -ne 0 -or -not $r.rootTraversalExhaustive -or $r.detailedFilePaths -ne 159707 -or $r.detailedStreamHashes -ne 159707){throw 'SOURCE_WIM_ROOT_DETAIL_NOT_PROVEN'}
 if(@($r.topResourceFileOwners).Count -ne 128 -or $report.actualMappedCount -ne 127 -or @($report.top128SourceDrift).Count -ne 0 -or @($report.top128Unmapped).Count -ne 1 -or @($report.mappedIncomplete).Count -ne 0 -or @($report.truncatedOwners).Count -ne 0){throw 'TOP128_OWNER_GRAPH_NOT_RECONCILED'}
 if($one.Count -ne 1 -or $edge.Count -ne 1 -or $one[0].matchedPathCount -ne 2 -or $edge[0].matchedPathCount -ne 2){throw 'ONEDRIVE_OR_EDGE_REAL_RESOURCE_REFCOUNT_UNMATCHED'}
 $oneEntries=@(& $exe dir $wim 1 '--path=/Windows/System32/OneDriveSetup.exe' '--detailed' 2>&1)
 $report.oneDriveTargetNativeExit=[int]$LASTEXITCODE
 $edgeEntries=@(& $exe dir $wim 1 '--path=/Windows/System32/Microsoft-Edge-WebView/msedge.dll' '--detailed' 2>&1)
 $report.edgeTargetNativeExit=[int]$LASTEXITCODE
 $report.oneDriveTargetedOutput=@($oneEntries | Select-Object -First 30 | ForEach-Object {[string]$_})
 $report.edgeTargetedOutput=@($edgeEntries | Select-Object -First 30 | ForEach-Object {[string]$_})
 $ot=$oneEntries -join [Environment]::NewLine
 $et=$edgeEntries -join [Environment]::NewLine
 $report.oneDriveTargetedSHAconfirmed=($ot -match '054ff47240288181f2f472c9dc4a04c9c194d083' -and $ot -match '(?i)OneDriveSetup.exe')
 $report.edgeTargetedSHAconfirmed=($et -match '996901b9df12d46326e040404c50cfd66c7fca4a' -and $et -match '(?i)msedge.dll')
 if($report.oneDriveTargetNativeExit -ne 0 -or $report.edgeTargetNativeExit -ne 0 -or -not $report.oneDriveTargetedSHAconfirmed -or -not $report.edgeTargetedSHAconfirmed){throw 'SECOND_NATIVE_TARGETED_RESOURCE_SHA_OR_EXIT_HOLD'}
 $report.wimMounts=@(Get-WindowsImage -Mounted).Count
 $vm=@(Get-VM|Where-Object Name -Like 'BlueLite*')
 $report.VMsOff=@($vm|Where-Object State -eq 'Off').Count
 $report.CfreeBytes=[long](Get-PSDrive C).Free
 if($report.wimMounts -ne 0 -or $vm.Count -ne 3 -or $report.VMsOff -ne 3 -or $report.CfreeBytes -lt [long](60GB)){throw 'HOST_WIM_VM_CFREE_GUARD_HOLD'}
 $report.status='R043_OP41_ORIGINAL_9974_TOP128_MAPPED127_UNMAPPED1_SECOND_NATIVE_ONE_EDGE_PATH_SHA_PASS_NO_REMOVAL'
}catch{
 $report.error=$_.Exception.Message
}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($report|ConvertTo-Json -Depth 8)+[Environment]::NewLine)
$f=[IO.File]::Open($receipt,[IO.FileMode]::CreateNew)
try{$f.Write($bytes,0,$bytes.Length)}finally{$f.Dispose()}
[pscustomobject]@{
 status=$report.status
 error=$report.error
 topMapped=$report.actualMappedCount
 topUnmapped=$report.top128Unmapped
 onedrive=$report.oneDriveRefPaths
 targetExits=@($report.oneDriveTargetNativeExit,$report.edgeTargetNativeExit)
 protectedCandidate=@($report.protectedWinSxSCandidateRows|Select-Object -First 6)
 receiptSHA=(Get-FileHash -LiteralPath $receipt -Algorithm SHA256).Hash
}|ConvertTo-Json -Depth 8 -Compress
if($report.status -notlike 'R043_OP41_ORIGINAL_9974_TOP128_MAPPED127_UNMAPPED1_SECOND_NATIVE_ONE_EDGE_PATH_SHA_PASS_NO_REMOVAL'){exit 2}
exit 0
