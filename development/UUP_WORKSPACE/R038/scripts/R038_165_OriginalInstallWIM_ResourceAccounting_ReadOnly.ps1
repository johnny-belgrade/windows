# R038 OP165 strict streamed unique WIM blob physical byte accounting, source/read-only, no outputs.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$stage='C:\work\_UUP\R035_Universal_PREMAX_26300\BlueLite_Work\BlueLite_Stage_v11_3_26300_9818_6c7bf258_fc76f92b'
$wim=Join-Path $stage 'BlueLite_R029_Outputs\install.wim'
$vendor=Join-Path $stage 'bin\wimlib-imagex.exe'
$dll=Join-Path $stage 'bin\libwim-15.dll'
$report=[ordered]@{
 schema='BlueLite.R038.OP165.WimUniquePhysicalBytes.v1'
 utc=[DateTime]::UtcNow.ToString('o')
 status='HOLD'
 script_sha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
 original_install_bytes=$null
 vendor_exe_sha256=$null
 vendor_dll_sha256=$null
 stream_exit=$null
 stream_lines=0
 stream_chars=0
 blob_count=0
 blob_metadata_count=0
 blob_zero_ref_count=0
 blob_single_ref_count=0
 blob_shared_ref_count=0
 compressed_unique_total_bytes=[long]0
 uncompressed_unique_total_bytes=[long]0
 compressed_metadata_bytes=[long]0
 compressed_regular_bytes=[long]0
 compressed_shared_ref_bytes=[long]0
 compressed_zero_ref_bytes=[long]0
 sum_reference_counts=[long]0
 max_compressed_blob_bytes=[long]0
 overhead_nonblob_bytes=$null
 top_compressed_blobs=@()
 mounted_wim_count=$null
 baseline_guest=$null
 control_guest=$null
 emitted_result_files=0
 error=$null
}
$proc=$null
try {
 foreach($item in @(
  [pscustomobject]@{path=$wim;bytes=[long]5663629505;name='SOURCE_WIM'},
  [pscustomobject]@{path=$vendor;bytes=[long]149518;name='WIMLIB_EXE'},
  [pscustomobject]@{path=$dll;bytes=[long]525838;name='WIMLIB_DLL'}
  )){
  $f=Get-Item -LiteralPath $item.path -ErrorAction Stop
  if($f.Length -ne $item.bytes -or (($f.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)){throw ($item.name+'_BYTES_OR_REPARSE')}
 }
 $report.original_install_bytes=[long]5663629505
 $report.vendor_exe_sha256=(Get-FileHash -LiteralPath $vendor -Algorithm SHA256).Hash
 $report.vendor_dll_sha256=(Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash
 if($report.vendor_exe_sha256 -ne '01168A00FFC84EBFA1BD3B9C841214ED114B9AE4E9B23D555C0686448FD56BDE'){throw 'VENDOR_EXE_SHA_DRIFT'}
 if($report.vendor_dll_sha256 -ne 'E1B005C0F1391B30357E64885A08A09A2D41DE93B38ACAA25ED7A355F74F56B4'){throw 'VENDOR_DLL_SHA_DRIFT'}
 $report.mounted_wim_count=@(Get-WindowsImage -Mounted -ErrorAction Stop).Count
 if($report.mounted_wim_count -ne 0){throw 'WIM_MOUNTED'}
 $a=Get-VM -Id 'c7536cc4-68f5-473a-9818-4053ba8794b2' -ErrorAction Stop
 $b=Get-VM -Id 'deb10ab5-3093-47a8-9a13-f3927446c606' -ErrorAction Stop
 $report.baseline_guest=([string]$a.State)+'/'+([string](Get-VMFirmware -VMName $a.Name).SecureBoot)
 $report.control_guest=([string]$b.State)+'/'+([string](Get-VMFirmware -VMName $b.Name).SecureBoot)
 if($a.Name -ne 'BlueLite-R038-UEFI-Baseline' -or $b.Name -ne 'BlueLite-R038-UEFI-SBOff-Control' -or $report.baseline_guest -ne 'Running/On' -or $report.control_guest -ne 'Off/Off'){throw 'DEVELOPMENT_VM_STATE_DRIFT'}
 $psi=[Diagnostics.ProcessStartInfo]::new()
 $psi.FileName=$vendor
 $psi.WorkingDirectory=Split-Path -Path $vendor -Parent
 $psi.CreateNoWindow=$true
 $psi.UseShellExecute=$false
 $psi.RedirectStandardOutput=$true
 $psi.RedirectStandardError=$true
 foreach($arg in @('info',$wim,'--blobs')){[void]$psi.ArgumentList.Add([string]$arg)}
 $proc=[Diagnostics.Process]::new()
 $proc.StartInfo=$psi
 if(-not $proc.Start()){throw 'WIMLIB_CHILD_NOT_STARTED'}
 $stderrTask=$proc.StandardError.ReadToEndAsync()
 $timer=[Diagnostics.Stopwatch]::StartNew()
 $pos=0
 $block=[ordered]@{}
 $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 $top=[Collections.Generic.List[object]]::new()
 while($null -ne ($line=$proc.StandardOutput.ReadLine())){
  $report.stream_lines++
  $report.stream_chars+=[long]$line.Length
  if($report.stream_lines -gt 1000000 -or $report.stream_chars -gt 70000000 -or $timer.Elapsed.TotalSeconds -gt 45){throw 'WIMLIB_STREAM_BOUND_EXCEEDED'}
  switch($pos){
   0 {
    if($line -notmatch '^Hash\s*=\s*0x([a-fA-F0-9]{40})\s*$'){throw ('RESOURCE_HASH_MALFORMED_LINE_'+$report.stream_lines)}
    $block=[ordered]@{sha1=$Matches[1].ToUpperInvariant()}
    if(-not $seen.Add($block.sha1)){throw 'RESOURCE_SHA_DUPLICATED'}
   }
   1 {
    if($line -notmatch '^Uncompressed size\s*=\s*([0-9]+) bytes\s*$'){throw ('RESOURCE_RAW_SIZE_MALFORMED_LINE_'+$report.stream_lines)}
    $block.raw=[long]::Parse($Matches[1])
   }
   2 {
    if($line -notmatch '^Compressed size\s*=\s*([0-9]+) bytes\s*$'){throw ('RESOURCE_COMPRESSED_SIZE_MALFORMED_LINE_'+$report.stream_lines)}
    $block.compressed=[long]::Parse($Matches[1])
   }
   3 {
    if($line -notmatch '^Offset in WIM\s*=\s*([0-9]+) bytes\s*$'){throw ('RESOURCE_OFFSET_MALFORMED_LINE_'+$report.stream_lines)}
    $block.offset=[long]::Parse($Matches[1])
   }
   4 {
    if($line -notmatch '^Part Number\s*=\s*([0-9]+)\s*$'){throw ('RESOURCE_PART_MALFORMED_LINE_'+$report.stream_lines)}
    $block.part=[int]::Parse($Matches[1])
   }
   5 {
    if($line -notmatch '^Reference Count\s*=\s*([0-9]+)\s*$'){throw ('RESOURCE_REFERENCE_MALFORMED_LINE_'+$report.stream_lines)}
    $block.references=[long]::Parse($Matches[1])
   }
   6 {
    if($line -notmatch '^Flags\s*=\s*(.*)$'){throw ('RESOURCE_FLAGS_MALFORMED_LINE_'+$report.stream_lines)}
    $block.flags=[string]$Matches[1]
   }
   7 {
    if($line.Trim().Length -ne 0){throw ('RESOURCE_SEPARATOR_NOT_EMPTY_LINE_'+$report.stream_lines)}
    if($block.part -ne 1 -or $block.raw -lt 0 -or $block.compressed -lt 0 -or $block.compressed -gt $report.original_install_bytes -or $block.offset -lt 0 -or $block.offset -ge $report.original_install_bytes){throw 'RESOURCE_BOUNDS_INVALID'}
    $report.blob_count++
    $report.compressed_unique_total_bytes+=[long]$block.compressed
    $report.uncompressed_unique_total_bytes+=[long]$block.raw
    $report.sum_reference_counts+=[long]$block.references
    if($block.flags -match 'WIM_RESHDR_FLAG_METADATA'){
     $report.blob_metadata_count++
     $report.compressed_metadata_bytes+=[long]$block.compressed
    }else{$report.compressed_regular_bytes+=[long]$block.compressed}
    if($block.references -eq 0){$report.blob_zero_ref_count++;$report.compressed_zero_ref_bytes+=[long]$block.compressed}
    elseif($block.references -eq 1){$report.blob_single_ref_count++}
    else{$report.blob_shared_ref_count++;$report.compressed_shared_ref_bytes+=[long]$block.compressed}
    if($block.compressed -gt $report.max_compressed_blob_bytes){$report.max_compressed_blob_bytes=[long]$block.compressed}
    $candidate=[pscustomobject]@{sha1=$block.sha1;compressed_bytes=[long]$block.compressed;uncompressed_bytes=[long]$block.raw;refs=[long]$block.references;metadata=($block.flags -match 'WIM_RESHDR_FLAG_METADATA')}
    if($top.Count -lt 12){[void]$top.Add($candidate)}
    else{
     $minIndex=0
     for($ix=1;$ix -lt $top.Count;$ix++){if($top[$ix].compressed_bytes -lt $top[$minIndex].compressed_bytes){$minIndex=$ix}}
     if($candidate.compressed_bytes -gt $top[$minIndex].compressed_bytes){$top[$minIndex]=$candidate}
    }
   }
  }
  $pos=($pos+1)%8
 }
 if(-not $proc.WaitForExit(5000)){throw 'WIMLIB_CHILD_EXIT_TIMEOUT'}
 $report.stream_exit=$proc.ExitCode
 $err=[string]$stderrTask.GetAwaiter().GetResult()
 if($proc.ExitCode -ne 0 -or $err.Trim()){throw ('WIMLIB_CHILD_NONZERO_OR_STDERR:'+ $proc.ExitCode+' '+$err.Substring(0,[Math]::Min($err.Length,180)))}
 if($pos -ne 0){throw 'TRUNCATED_RESOURCE_GROUP'}
 if($report.stream_lines -ne 653096 -or $report.stream_chars -ne 19333601 -or $report.blob_count -ne 81637){throw 'BLOB_TOTAL_DIFFERS_FROM_PREVIOUS_NATIVE_SOURCE'}
 if($report.compressed_unique_total_bytes -gt $report.original_install_bytes){throw 'COMPRESSED_RESOURCE_SUM_EXCEEDS_ORIGINAL_WIM'}
 $report.overhead_nonblob_bytes=$report.original_install_bytes-$report.compressed_unique_total_bytes
 $report.top_compressed_blobs=@($top|Sort-Object -Property compressed_bytes -Descending)
 if(@(Get-WindowsImage -Mounted -ErrorAction Stop).Count -ne 0){throw 'POST_WIM_MOUNTED'}
 $report.status='ORIGINAL_R035_UNIQUE_BLOB_COMPRESSED_BYTES_PRODUCER_READONLY_PASS'
}catch{$report.error=$_.Exception.Message;if($null -ne $proc -and -not $proc.HasExited){try{$proc.Kill($true)}catch{}}}
finally{if($null -ne $proc){$proc.Dispose()}}
$report|ConvertTo-Json -Depth 8
if($report.status -ne 'ORIGINAL_R035_UNIQUE_BLOB_COMPRESSED_BYTES_PRODUCER_READONLY_PASS'){exit 2}
exit 0
