# R043 OP21: source-only original 26300.9974 WIM detailed root traversal; map top128 compressed SHA1 to original file paths, no WIM mount.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$first='C:\work\logs\R043_OP09_9974_OriginalWimUniqueBlobAccounting_Producer.json'
$second='C:\work\logs\R043_OP09_9974_OriginalWimUniqueBlobAccounting_IndependentVerify_v5.json'
$owner='C:\work\logs\R043_OP19_WimlibKnownAndCandidatePath_IndependentVerify.json'
$source='C:\work\logs\R043_OP07_P1_ActualRecipeAndOwnerCandidates_Producer.json'
$receipt='C:\work\logs\R043_OP21_Top128Blob_SHA1ToPaths_Producer.json'
if(Test-Path -LiteralPath $receipt){throw 'R043_OP21_UNIQUE_WIM_OWNER_PRODUCER_ALREADY_EXISTS'}
$a=Get-Content -LiteralPath $first -Raw|ConvertFrom-Json
$b=Get-Content -LiteralPath $second -Raw|ConvertFrom-Json
$c=Get-Content -LiteralPath $owner -Raw|ConvertFrom-Json
$d=Get-Content -LiteralPath $source -Raw|ConvertFrom-Json
if($a.status -ne 'R043_OP09_ORIGINAL_9974_WIM_UNIQUE_COMPRESSED_PHYSICAL_BLOBS_NATIVE_PASS_PENDING_SECOND_QA' -or
 $b.status -ne 'R043_OP09_ORIGINAL_9974_81351_COMPRESSED_RESOURCES_THIRD_INDEPENDENT_FULL_NATIVE_QA_PASS' -or
 $c.status -ne 'R043_OP19_ORIGINAL_WIM_9974_NTOSKRNL_ONEDRIVE_PATH_TO_SHA1_COMPRESSED_BYTES_SECOND_NATIVE_PASS_DEPENDENCY_PENDING'){
 throw 'R043_OP21_REQUIRED_INDEPENDENT_SOURCE_QA_NOT_PASS'
}
$wim=[string]$d.actualOriginalWIM
$exe=[string]$d.actualWimlibVendorExe
if((Get-FileHash $exe -Algorithm SHA256).Hash -ne '01168A00FFC84EBFA1BD3B9C841214ED114B9AE4E9B23D555C0686448FD56BDE' -or
 [IO.FileInfo]::new($wim).Length -ne 5602983183 -or @(Get-WindowsImage -Mounted).Count -ne 0 -or
 @((Get-VM)|Where-Object{$_.State -ne 'Off'}).Count -ne 0){throw 'R043_OP21_NATIVE_SOURCE_OR_MOUNT_GUARD_HOLD'}
$lookup=[Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($entry in @($a.largestCompressedBlobs)){
 $key=([string]$entry.sha1) -replace '^(?i:0x)',''
 if($key -notmatch '^[A-Fa-f0-9]{40}$' -or $lookup.ContainsKey($key)){throw 'TOP128_RESOURCE_SHA_NOT_UNIQUE'}
 $lookup.Add($key,[pscustomobject]@{
  sha1=('0x'+$key.ToLowerInvariant())
  compressedBytes=[long]$entry.compressedBytes
  uncompressedBytes=[long]$entry.uncompressedBytes
  refCount=[int]$entry.refCount
  matchedPaths=[Collections.Generic.List[string]]::new()
  excessPathCount=0
 })
}
if($lookup.Count -ne 128){throw 'TOP128_RESOURCE_COUNT_MISSING'}
$report=[ordered]@{
 schema='BlueLite.R043.OP21.WimRootDirectoryTop128SHA1PathOwner.v1'
 utc=[DateTime]::UtcNow.ToString('o')
 status='HOLD'
 sourceOriginalWim=$wim
 sourceWimBytes=([IO.FileInfo]::new($wim)).Length
 sourceVendorSHA=(Get-FileHash $exe -Algorithm SHA256).Hash
 originalBlobsProducerSHA=(Get-FileHash $first -Algorithm SHA256).Hash
 sourceIndependentBlobQA_SHA=(Get-FileHash $second -Algorithm SHA256).Hash
 sourceOneDriveIndependentPathSHA=(Get-FileHash $owner -Algorithm SHA256).Hash
 nativeDirectoryArgs=@('dir',$wim,'1','--path=/','--detailed')
 nativeWimlibExit=$null
 nativeStandardError=''
 directoryOutputLines=[long]0
 directoryOutputChars=[long]0
 detailedFilePaths=[long]0
 detailedStreamHashes=[long]0
 uniqueTopResourcesWithAtLeastOnePath=0
 sourceOneDrivePaths=@()
 sourceOneDrivePathCount=0
 topResourceFileOwners=@()
 rootTraversalExhaustive=$false
 actualQualifiedRemovableUniqueCompressedBytes=[long]0
 mutationPerformed=$false
 activeVMsBeforeOrAfter=0
 WIMmountsBeforeOrAfter=0
 error=''
}
$proc=$null
try {
 $psi=[Diagnostics.ProcessStartInfo]::new()
 $psi.FileName=$exe
 $psi.WorkingDirectory=Split-Path -Path $exe -Parent
 $psi.UseShellExecute=$false
 $psi.CreateNoWindow=$true
 $psi.RedirectStandardOutput=$true
 $psi.RedirectStandardError=$true
 foreach($arg in $report.nativeDirectoryArgs){[void]$psi.ArgumentList.Add([string]$arg)}
 $proc=[Diagnostics.Process]::new()
 $proc.StartInfo=$psi
 if(-not $proc.Start()){throw 'WIMLIB_ROOT_DIR_PROCESS_NOT_STARTED'}
 $stderrTask=$proc.StandardError.ReadToEndAsync()
 $clock=[Diagnostics.Stopwatch]::StartNew()
 $activePath=''
 while($null -ne ($line=$proc.StandardOutput.ReadLine())){
  $report.directoryOutputLines++
  $report.directoryOutputChars+=[long]$line.Length
  if($report.directoryOutputLines -gt 4000000 -or $report.directoryOutputChars -gt 500000000 -or $clock.Elapsed.TotalSeconds -gt 120){
   throw 'WIMLIB_ROOT_DIR_STREAM_BOUNDS_4M_LINES_500M_CHARS_120SEC_EXCEEDED'
  }
  $pathMatch=[regex]::Match($line,'^Full Path\s*=\s*"([^"]+)"\s*$')
  if($pathMatch.Success){
   $activePath=$pathMatch.Groups[1].Value
   $report.detailedFilePaths++
   continue
  }
  $hashMatch=[regex]::Match($line,'^\s*Hash\s*=\s*0x([A-Fa-f0-9]{40})\s*$')
  if($hashMatch.Success){
   $report.detailedStreamHashes++
   if(-not $activePath){throw 'WIMLIB_STREAM_HASH_HAS_NO_PRECEDING_ACTUAL_PATH'}
   $key=$hashMatch.Groups[1].Value
   $found=$null
   if($lookup.TryGetValue($key,[ref]$found)){
    if(-not $found.matchedPaths.Contains($activePath)){
     if($found.matchedPaths.Count -lt 64){$found.matchedPaths.Add($activePath)}
     else{$found.excessPathCount++}
    }
   }
  }
 }
 if(-not $proc.WaitForExit(5000)){throw 'ROOT_DIR_WIMLIB_PROCESS_EXIT_TIMEOUT'}
 $report.nativeWimlibExit=[int]$proc.ExitCode
 $stdErr=[string]$stderrTask.GetAwaiter().GetResult()
 if($stdErr.Length -gt 10000){throw 'WIMLIB_DIRECTORY_STDERR_EXCEEDS_BOUND'}
 $report.nativeStandardError=$stdErr
 if($proc.ExitCode -ne 0 -or $stdErr.Trim()){throw ('ROOT_DIRECTORY_NATIVE_EXIT_OR_STDERR_'+$proc.ExitCode)}
 if($report.detailedFilePaths -lt 1000 -or $report.detailedStreamHashes -lt 1000){throw 'WIMLIB_DIR_ROOT_NOT_RECURSIVE_OR_FILES_NOT_FOUND'}
 $owners=@($lookup.Values|Sort-Object compressedBytes -Descending)
 $report.uniqueTopResourcesWithAtLeastOnePath=@($owners|Where-Object{$_.matchedPaths.Count -gt 0}).Count
 $report.topResourceFileOwners=@($owners|ForEach-Object{
  [pscustomobject]@{
   sha1=$_.sha1;compressedBytes=$_.compressedBytes;uncompressedBytes=$_.uncompressedBytes;refCount=$_.refCount
   matchedPathCount=$_.matchedPaths.Count;truncatedPathCount=$_.excessPathCount;filePaths=@($_.matchedPaths)
   allSourceWimReferencesAccounted=($_.matchedPaths.Count -ge $_.refCount -and $_.excessPathCount -eq 0)
  }
 })
 $one=@($report.topResourceFileOwners|Where-Object{$_.sha1 -eq '0x054ff47240288181f2f472c9dc4a04c9c194d083'})
 if($one.Count -ne 1){throw 'ONEDRIVE_TOP128_RESOURCE_MISSING'}
 $report.sourceOneDrivePaths=@($one[0].filePaths)
 $report.sourceOneDrivePathCount=$one[0].matchedPathCount
 if(-not @($report.sourceOneDrivePaths|Where-Object{$_ -ieq '\Windows\System32\OneDriveSetup.exe'}).Count){
  throw 'PREVIOUS_NATIVE_ONEDRIVE_REAL_FILE_NOT_PRESENT_IN_FULL_ROOT_SCAN'
 }
 $report.rootTraversalExhaustive=$true
 $report.status='R043_OP21_ORIGINAL_9974_FULL_WIM_DIR_METADATA_TOP128_SHA1_FILE_PATHS_SOURCE_SCAN_PASS_DEPENDENCY_PENDING'
 if(@(Get-WindowsImage -Mounted).Count -ne 0 -or @((Get-VM)|Where-Object{$_.State -ne 'Off'}).Count -ne 0){throw 'POST_ROOT_SCAN_WIM_MOUNT_OR_VM_STATE_DRIFT'}
}catch{$report.error=$_.Exception.Message;if($null -ne $proc -and -not $proc.HasExited){try{$proc.Kill($true)}catch{}}}
finally{if($null -ne $proc){$proc.Dispose()}}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($report|ConvertTo-Json -Depth 9)+[Environment]::NewLine)
$fs=[IO.File]::Open($receipt,[IO.FileMode]::CreateNew)
try{$fs.Write($bytes,0,$bytes.Length)}finally{$fs.Dispose()}
[pscustomobject]@{
 status=$report.status;error=$report.error;nativeExit=$report.nativeWimlibExit
 directoryFilePaths=$report.detailedFilePaths;resourceStreams=$report.detailedStreamHashes
 top128WithOwners=$report.uniqueTopResourcesWithAtLeastOnePath
 oneDrivePaths=$report.sourceOneDrivePaths
 top16=@($report.topResourceFileOwners|Select-Object -First 16)
 receiptSHA=(Get-FileHash $receipt -Algorithm SHA256).Hash
}|ConvertTo-Json -Depth 8 -Compress
if($report.status -ne 'R043_OP21_ORIGINAL_9974_FULL_WIM_DIR_METADATA_TOP128_SHA1_FILE_PATHS_SOURCE_SCAN_PASS_DEPENDENCY_PENDING'){exit 2}
exit 0
