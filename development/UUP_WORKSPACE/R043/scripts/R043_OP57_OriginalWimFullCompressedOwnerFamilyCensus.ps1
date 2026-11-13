# R043 OP57: source-only full original 26300.9974 WIM compressed resource SHA1 owner-family census.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$root='C:\work\_UUP\R043_PREMAX_P1_20261112'
$receipt=Join-Path $root 'BlueLite_Logs\R043_OP57_AllCompressedResourceOwnerFamilies_Producer.json'
if([IO.File]::Exists($receipt)){throw 'R043_OP57_UNIQUE_PRODUCER_ALREADY_EXISTS'}
$first='C:\work\logs\R043_OP09_9974_OriginalWimUniqueBlobAccounting_Producer.json'
$second=Join-Path $root 'BlueLite_Logs\R043_OP41_WimTop128OwnerPaths_IndependentVerify.json'
$previous=Join-Path $root 'BlueLite_Logs\R043_OP45_MetadataFlag_LegacyWinSxSBlobGroups_Producer.json'
$source='C:\work\logs\R043_OP07_P1_ActualRecipeAndOwnerCandidates_Producer.json'
$a=Get-Content -LiteralPath $first -Raw|ConvertFrom-Json
$b=Get-Content -LiteralPath $second -Raw|ConvertFrom-Json
$c=Get-Content -LiteralPath $previous -Raw|ConvertFrom-Json
$d=Get-Content -LiteralPath $source -Raw|ConvertFrom-Json
$wim=[string]$d.actualOriginalWIM
$exe=[string]$d.actualWimlibVendorExe
if($a.unique_blobs -ne 81351 -or [long]$a.compressed_bytes_unique -ne 5598902101 -or
 $a.metadata_blobs -ne 1 -or [long]$a.compressed_metadata_bytes -ne 7213982 -or
 [long]$a.regular_compressed_bytes -ne 5591688119 -or
 $b.status -notlike '*SECOND_NATIVE_ONE_EDGE_PATH_SHA_PASS_NO_REMOVAL' -or
 $c.status -notlike '*LEGACY_GROUPS_PRODUCER_PASS') {throw 'R043_OP57_REQUIRED_SOURCE_RECEIPTS_NOT_PASS'}
if((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -ne '01168A00FFC84EBFA1BD3B9C841214ED114B9AE4E9B23D555C0686448FD56BDE' -or
 [IO.FileInfo]::new($wim).Length -ne 5602983183 -or @(Get-WindowsImage -Mounted).Count -ne 0 -or
 @((Get-VM)|Where-Object {$_.State -ne 'Off'}).Count -ne 0 -or [long](Get-PSDrive C).Free -lt [long](60GB)) {
 throw 'R043_OP57_ORIGINAL_WIM_OR_HOST_PREFLIGHT_HOLD'
}
$items=[Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
$report=[ordered]@{
 schema='BlueLite.R043.OP57.Original9974FullUniqueCompressedBlobOwnerFamilies.v1'
 utc=[DateTime]::UtcNow.ToString('o')
 status='HOLD'
 originalWIM=$wim
 sourceWimBytes=5602983183
 vendorSHA256=(Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash
 originalOP09SHA256=(Get-FileHash -LiteralPath $first -Algorithm SHA256).Hash
 priorOP41IndependentSHA256=(Get-FileHash -LiteralPath $second -Algorithm SHA256).Hash
 priorOP45LegacySourceSHA256=(Get-FileHash -LiteralPath $previous -Algorithm SHA256).Hash
 nativeVendorExit=$null
 nativeStderr=''
 elapsedSeconds=0
 detailedPaths=[long]0
 detailedHashLines=[long]0
 directoryLines=[long]0
 directoryChars=[long]0
 zeroCompressedPathStreams=[long]0
 uniquePhysicalFileResourceSHA1=0
 uniqueFileResourceCompressedSumBytes=[long]0
 uniqueFileResourceReferenceSum=[long]0
 uniqueFileResourceRefCountOne=0
 uniqueFileResourceRefCountShared=0
 matchedSourcePhysicalResourceCount=$false
 matchedSourcePhysicalCompressedBytes=$false
 topWinSxSAssemblyGroups=@()
 topNonWinSxSOwnerGroups=@()
 oldEdgeAllPositiveRefCountOneGroup=@()
 oldOneDriveAllPositiveRefCountOneGroup=@()
 legacyTop128_7_SourceSHAsReconciled=0
 legacyTop128_7_OriginalCompressedBytes=[long]0
 potentialUniqueSourceBytesOnly=[long]0
 actuallyRemovableCompressedWimBytes=[long]0
 noWimOrHostMutation=$true
 sourceOwnerCBSDecision='DEPENDENCY_HOLD'
 CfreeAfterBytes=[long]0
 mountCountAfter=$null
 VMsOffAfter=$null
 error=''
}
function Find-OwnerFamily([string]$p){
 $m=[regex]::Match($p,'^\\Windows\\WinSxS\\([^\\]+)\\',[Text.RegularExpressions.RegexOptions]::IgnoreCase)
 if($m.Success){return ('WinSxS:'+$m.Groups[1].Value.ToLowerInvariant())}
 $m=[regex]::Match($p,'^\\Windows\\SystemApps\\([^\\]+)\\',[Text.RegularExpressions.RegexOptions]::IgnoreCase)
 if($m.Success){return ('SystemApps:'+$m.Groups[1].Value.ToLowerInvariant())}
 $m=[regex]::Match($p,'^\\Program Files\\WindowsApps\\([^\\]+)\\',[Text.RegularExpressions.RegexOptions]::IgnoreCase)
 if($m.Success){return ('WindowsApps:'+$m.Groups[1].Value.ToLowerInvariant())}
 $m=[regex]::Match($p,'^\\Windows\\System32\\DriverStore\\FileRepository\\([^\\]+)\\',[Text.RegularExpressions.RegexOptions]::IgnoreCase)
 if($m.Success){return ('DriverStore:'+$m.Groups[1].Value.ToLowerInvariant())}
 $m=[regex]::Match($p,'^\\Program Files(?: \(x86\))?\\([^\\]+)\\',[Text.RegularExpressions.RegexOptions]::IgnoreCase)
 if($m.Success){return ('ProgramFiles:'+$m.Groups[1].Value.ToLowerInvariant())}
 $m=[regex]::Match($p,'^\\Windows\\([^\\]+)\\',[Text.RegularExpressions.RegexOptions]::IgnoreCase)
 if($m.Success){return ('WindowsFolder:'+$m.Groups[1].Value.ToLowerInvariant())}
 $m=[regex]::Match($p,'^\\([^\\]+)\\',[Text.RegularExpressions.RegexOptions]::IgnoreCase)
 if($m.Success){return ('Root:'+$m.Groups[1].Value.ToLowerInvariant())}
 return 'Other'
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
 foreach($arg in @('dir',$wim,'1','--path=/','--detailed')){[void]$psi.ArgumentList.Add([string]$arg)}
 $proc=[Diagnostics.Process]::new()
 $proc.StartInfo=$psi
 if(-not $proc.Start()){throw 'WIMLIB_DIR_NOT_STARTED'}
 $stderrTask=$proc.StandardError.ReadToEndAsync()
 $clock=[Diagnostics.Stopwatch]::StartNew()
 $activePath=''
 $activeSha=''
 $activeCompressed=[long]-1
 foreach($line in @()){}
 while($null -ne ($line=$proc.StandardOutput.ReadLine())){
  $report.directoryLines++
  $report.directoryChars+=[long]$line.Length
  if($report.directoryLines -gt 4000000 -or $report.directoryChars -gt 600000000 -or $clock.Elapsed.TotalSeconds -gt 180){
   throw 'R043_OP57_FULL_ROOT_STREAM_BOUND_EXCEEDED'
  }
  $m=[regex]::Match($line,'^Full Path\s*=\s*"([^"]+)"\s*$')
  if($m.Success){
   $activePath=$m.Groups[1].Value
   $activeSha=''
   $activeCompressed=[long]-1
   $report.detailedPaths++
   continue
  }
  $m=[regex]::Match($line,'^\s*Hash\s*=\s*0x([A-Fa-f0-9]{40})\s*$')
  if($m.Success){
   if(-not $activePath){throw 'WIMLIB_HASH_WITHOUT_FILENAME'}
   $activeSha=$m.Groups[1].Value.ToLowerInvariant()
   $report.detailedHashLines++
   continue
  }
  $m=[regex]::Match($line,'^\s*Compressed size\s*=\s*(\d+)\s*bytes\s*$')
  if($m.Success){
   $activeCompressed=[long]::Parse($m.Groups[1].Value,[Globalization.CultureInfo]::InvariantCulture)
   continue
  }
  $m=[regex]::Match($line,'^\s*Reference Count\s*=\s*(\d+)\s*$')
  if($m.Success -and $activeSha){
   if($activeCompressed -lt 0){throw 'WIMLIB_HASH_REF_WITHOUT_COMPRESSED_SIZE'}
   $ref=[int]::Parse($m.Groups[1].Value,[Globalization.CultureInfo]::InvariantCulture)
   if($activeCompressed -eq 0){$report.zeroCompressedPathStreams++;continue}
   if($ref -le 0){throw 'WIMLIB_POSITIVE_COMPRESSED_ZERO_REFCOUNT'}
   $rec=$null
   if($items.TryGetValue($activeSha,[ref]$rec)){
    if($rec.compressedBytes -ne $activeCompressed -or $rec.refCount -ne $ref){throw 'WIMLIB_SAME_SHA_DIFFERENT_RESOURCE_METADATA'}
    $rec.pathCount++
    if($rec.pathCount -eq 2){$rec.secondPath=$activePath}
   }else{
    $items.Add($activeSha,[pscustomobject]@{sha1=('0x'+$activeSha);compressedBytes=$activeCompressed;refCount=$ref;pathCount=1;firstPath=$activePath;secondPath=''})
   }
   $activeSha=''
  }
 }
 if(-not $proc.WaitForExit(5000)){throw 'WIMLIB_DIR_CHILD_EXIT_TIMEOUT'}
 $report.nativeVendorExit=[int]$proc.ExitCode
 $report.elapsedSeconds=[math]::Round($clock.Elapsed.TotalSeconds,2)
 $stderr=[string]$stderrTask.GetAwaiter().GetResult()
 if($stderr.Length -gt 10000){throw 'WIMLIB_DIR_STDERR_TOO_LARGE'}
 $report.nativeStderr=$stderr
 if($proc.ExitCode -ne 0 -or $stderr.Trim()){throw ('WIMLIB_DIR_NATIVE_EXIT_OR_STDERR_'+$proc.ExitCode)}
 $report.uniquePhysicalFileResourceSHA1=$items.Count
 $sum=[long]0;$refs=[long]0;$ones=0;$shared=0
 foreach($entry in $items.Values){
  $sum+=[long]$entry.compressedBytes
  $refs+=[long]$entry.refCount
  if($entry.refCount -eq 1){$ones++}else{$shared++}
 }
 $report.uniqueFileResourceCompressedSumBytes=$sum
 $report.uniqueFileResourceReferenceSum=$refs
 $report.uniqueFileResourceRefCountOne=$ones
 $report.uniqueFileResourceRefCountShared=$shared
 $report.matchedSourcePhysicalResourceCount=($items.Count -eq ([int]$a.unique_blobs-[int]$a.metadata_blobs))
 $report.matchedSourcePhysicalCompressedBytes=($sum -eq [long]$a.regular_compressed_bytes)
 $groups=[Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
 foreach($entry in $items.Values){
  if($entry.refCount -ne 1 -or $entry.pathCount -ne 1){continue}
  $group=Find-OwnerFamily $entry.firstPath
  $g=$null
  if(-not $groups.TryGetValue($group,[ref]$g)){
   $g=[pscustomobject]@{family=$group;uniqueCompressedBytes=[long]0;distinctSha1Count=0;samplePaths=[Collections.Generic.List[string]]::new()}
   $groups.Add($group,$g)
  }
  $g.uniqueCompressedBytes += [long]$entry.compressedBytes
  $g.distinctSha1Count++
  if($g.samplePaths.Count -lt 4){$g.samplePaths.Add($entry.firstPath)}
 }
 $wimGroup=@($groups.Values|Where-Object{$_.family.StartsWith('WinSxS:',[StringComparison]::OrdinalIgnoreCase)}|Sort-Object uniqueCompressedBytes -Descending)
 $notWinGroup=@($groups.Values|Where-Object{-not $_.family.StartsWith('WinSxS:',[StringComparison]::OrdinalIgnoreCase)}|Sort-Object uniqueCompressedBytes -Descending)
 $report.topWinSxSAssemblyGroups=@($wimGroup|Select-Object -First 80|ForEach-Object{[pscustomobject]@{family=$_.family;uniqueCompressedBytes=$_.uniqueCompressedBytes;distinctSha1Count=$_.distinctSha1Count;samplePaths=@($_.samplePaths)}})
 $report.topNonWinSxSOwnerGroups=@($notWinGroup|Select-Object -First 80|ForEach-Object{[pscustomobject]@{family=$_.family;uniqueCompressedBytes=$_.uniqueCompressedBytes;distinctSha1Count=$_.distinctSha1Count;samplePaths=@($_.samplePaths)}})
 $report.oldEdgeAllPositiveRefCountOneGroup=@($wimGroup|Where-Object{$_.family -match '^WinSxS:amd64_microsoft-edge-webview_[^\\]+_10\.0\.26100\.1_' }|Select-Object family,uniqueCompressedBytes,distinctSha1Count)
 $report.oldOneDriveAllPositiveRefCountOneGroup=@($wimGroup|Where-Object{$_.family -match '^WinSxS:amd64_microsoft-windows-onedrive-setup_[^\\]+_10\.0\.26100\.1_'}|Select-Object family,uniqueCompressedBytes,distinctSha1Count)
 $verified=0; $verifiedBytes=[long]0
 foreach($legacy in @($c.legacyEdgeOld26100_1SourceRows)+@($c.legacyOneDriveOld26100_1SourceRows)){
  $key=([string]$legacy.sha1) -replace '^(?i:0x)',''
  $hit=$null
  if(-not $items.TryGetValue($key,[ref]$hit)){throw 'PRIOR_LEGACY_SOURCE_SHA_NOT_IN_EXHAUSTIVE_ROOT_SCAN'}
  if($hit.compressedBytes -ne [long]$legacy.compressedBytes -or $hit.refCount -ne 1 -or $hit.pathCount -ne 1){throw 'PRIOR_LEGACY_SHA_COMPRESSED_OR_REFCOUNT_MISMATCH'}
  $verified++
  $verifiedBytes+=[long]$hit.compressedBytes
 }
 $report.legacyTop128_7_SourceSHAsReconciled=$verified
 $report.legacyTop128_7_OriginalCompressedBytes=$verifiedBytes
 $report.mountCountAfter=@(Get-WindowsImage -Mounted).Count
 $report.VMsOffAfter=@(Get-VM|Where-Object State -eq 'Off').Count
 $report.CfreeAfterBytes=[long](Get-PSDrive C).Free
 if($report.nativeVendorExit -ne 0 -or $report.detailedPaths -ne 159707 -or $report.detailedHashLines -ne 159707 -or
  $verified -ne 7 -or $verifiedBytes -ne 230453904 -or
  -not $report.matchedSourcePhysicalResourceCount -or -not $report.matchedSourcePhysicalCompressedBytes -or
  $report.mountCountAfter -ne 0 -or @((Get-VM)|Where-Object State -ne 'Off').Count -ne 0 -or
  $report.CfreeAfterBytes -lt [long](60GB)){
  throw 'FULL_ROOT_PHYSICAL_81350_COMPRESSED_WIM_RESOURCE_RECONCILIATION_HOLD'
 }
 $report.status='R043_OP57_ALL_81350_FILE_CONTENT_COMPRESSED_SHA1_SOURCE_OWNER_FAMILIES_NATIVE_PASS_PENDING_SECOND_QA'
}catch{
 $report.error=$_.Exception.Message
 if($null -ne $proc -and -not $proc.HasExited){try{$proc.Kill($true)}catch{}}
}finally{if($null -ne $proc){$proc.Dispose()}}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($report|ConvertTo-Json -Depth 9)+[Environment]::NewLine)
$f=[IO.File]::Open($receipt,[IO.FileMode]::CreateNew)
try{$f.Write($bytes,0,$bytes.Length)}finally{$f.Dispose()}
[pscustomobject]@{
 status=$report.status
 error=$report.error
 fileSHA1s=$report.uniquePhysicalFileResourceSHA1
 fileCompressedSum=$report.uniqueFileResourceCompressedSumBytes
 paths=$report.detailedPaths
 resourceHashes=$report.detailedHashLines
 legacy7SHAconfirmed=$report.legacyTop128_7_SourceSHAsReconciled
 legacy7Bytes=$report.legacyTop128_7_OriginalCompressedBytes
 top10WinSxS=@($report.topWinSxSAssemblyGroups|Select-Object -First 10)
 top10NonWinSxS=@($report.topNonWinSxSOwnerGroups|Select-Object -First 10)
 receiptSHA=(Get-FileHash -LiteralPath $receipt -Algorithm SHA256).Hash
}|ConvertTo-Json -Depth 8 -Compress
if($report.status -ne 'R043_OP57_ALL_81350_FILE_CONTENT_COMPRESSED_SHA1_SOURCE_OWNER_FAMILIES_NATIVE_PASS_PENDING_SECOND_QA'){exit 2}
exit 0
