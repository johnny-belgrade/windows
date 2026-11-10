# R038 OP170: independently parse original WIM unique-resource listing by field labels, read-only.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$stage='C:\work\_UUP\R035_Universal_PREMAX_26300\BlueLite_Work\BlueLite_Stage_v11_3_26300_9818_6c7bf258_fc76f92b'
$wim=Join-Path $stage 'BlueLite_R029_Outputs\install.wim'
$exe=Join-Path $stage 'bin\wimlib-imagex.exe'
$dll=Join-Path $stage 'bin\libwim-15.dll'
function Get-HeaderValue([string]$Header,[string]$Name){
 $m=[regex]::Match($Header,('(?im)^\s*'+[regex]::Escape($Name)+'\s*=\s*(\d+)\s*$'))
 if(-not $m.Success){throw ('WIM_HEADER_MISSING_'+$Name)}
 return [long]::Parse($m.Groups[1].Value)
}
function Start-Wimlib([string[]]$Arguments){
 $s=[Diagnostics.ProcessStartInfo]::new()
 $s.FileName=$exe
 $s.WorkingDirectory=Split-Path -Path $exe -Parent
 $s.UseShellExecute=$false
 $s.CreateNoWindow=$true
 $s.RedirectStandardOutput=$true
 $s.RedirectStandardError=$true
 foreach($arg in $Arguments){[void]$s.ArgumentList.Add([string]$arg)}
 $p=[Diagnostics.Process]::new()
 $p.StartInfo=$s
 if(-not $p.Start()){throw 'VENDOR_START_FAILED'}
 return $p
}
$answer=[ordered]@{
 schema='BlueLite.R038.OP170.IndependentWimResourceLabelAudit.v2'
 utc=[DateTime]::UtcNow.ToString('o')
 status='HOLD'
 source_auditor_sha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
 original_wim_bytes=$null
 vendor_exe_sha256=$null
 vendor_dll_sha256=$null
 header_bytes_total=$null
 blob_table_bytes=$null
 xml_bytes=$null
 integrity_bytes=$null
 header_boot_index=$null
 total_stream_lines=[long]0
 total_stream_chars=[long]0
 unique_blobs=[long]0
 compressed_bytes_unique=[long]0
 uncompressed_bytes_unique=[long]0
 metadata_blobs=[long]0
 compressed_metadata_bytes=[long]0
 regular_compressed_bytes=[long]0
 refcount_zero_blobs=[long]0
 refcount_one_blobs=[long]0
 refcount_shared_blobs=[long]0
 refcount_shared_compressed_bytes=[long]0
 sum_reference_counts=[long]0
 accounted_overhead_bytes=$null
 header_and_resource_reconcile=$null
 mounted_wim_count=$null
 baseline_guest=$null
 control_guest=$null
 output_files_created=0
 error=$null
}
$child=$null
try {
 foreach($q in @(
  [pscustomobject]@{path=$wim;bytes=[long]5663629505;label='WIM'},
  [pscustomobject]@{path=$exe;bytes=[long]149518;label='EXE'},
  [pscustomobject]@{path=$dll;bytes=[long]525838;label='DLL'}
  )){
  $fi=Get-Item -LiteralPath $q.path -ErrorAction Stop
  if($fi.Length -ne $q.bytes -or (($fi.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)){throw ($q.label+'_SIZE_OR_REPARSE_DRIFT')}
 }
 $answer.original_wim_bytes=[long]5663629505
 $answer.vendor_exe_sha256=(Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash
 $answer.vendor_dll_sha256=(Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash
 if($answer.vendor_exe_sha256 -ne '01168A00FFC84EBFA1BD3B9C841214ED114B9AE4E9B23D555C0686448FD56BDE'){throw 'EXE_SHA_DRIFT'}
 if($answer.vendor_dll_sha256 -ne 'E1B005C0F1391B30357E64885A08A09A2D41DE93B38ACAA25ED7A355F74F56B4'){throw 'DLL_SHA_DRIFT'}
 $answer.mounted_wim_count=@(Get-WindowsImage -Mounted -ErrorAction Stop).Count
 if($answer.mounted_wim_count -ne 0){throw 'WIM_MOUNT_PRESENT'}
 $a=Get-VM -Id 'c7536cc4-68f5-473a-9818-4053ba8794b2' -ErrorAction Stop
 $b=Get-VM -Id 'deb10ab5-3093-47a8-9a13-f3927446c606' -ErrorAction Stop
 $answer.baseline_guest=([string]$a.State)+'/'+([string](Get-VMFirmware -VMName $a.Name).SecureBoot)
 $answer.control_guest=([string]$b.State)+'/'+([string](Get-VMFirmware -VMName $b.Name).SecureBoot)
 if($a.Name -ne 'BlueLite-R038-UEFI-Baseline' -or $b.Name -ne 'BlueLite-R038-UEFI-SBOff-Control' -or $answer.baseline_guest -ne 'Running/On' -or $answer.control_guest -ne 'Off/Off'){throw 'VM_STATE_DRIFT'}
 $child=Start-Wimlib -Arguments ([string[]]@('info',$wim,'--header'))
 $headOut=$child.StandardOutput.ReadToEndAsync()
 $headErr=$child.StandardError.ReadToEndAsync()
 if(-not $child.WaitForExit(15000)){throw 'WIM_HEADER_READ_TIMEOUT'}
 $header=[string]$headOut.GetAwaiter().GetResult()
 $stderr=[string]$headErr.GetAwaiter().GetResult()
 if($child.ExitCode -ne 0 -or $stderr.Trim() -or $header.Length -gt 10000){throw 'WIM_HEADER_SOURCE_HOLD'}
 $answer.header_bytes_total=Get-HeaderValue $header 'Header Size'
 $answer.blob_table_bytes=Get-HeaderValue $header 'Blob Table Size'
 $answer.xml_bytes=Get-HeaderValue $header 'XML Data Size'
 $answer.integrity_bytes=Get-HeaderValue $header 'Integrity Size'
 $answer.header_boot_index=Get-HeaderValue $header 'Boot Index'
 $child.Dispose();$child=$null
 $child=Start-Wimlib -Arguments ([string[]]@('info',$wim,'--blobs'))
 $errTask=$child.StandardError.ReadToEndAsync()
 $clock=[Diagnostics.Stopwatch]::StartNew()
 $resource=@{}
 $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 $mandatory=@('Hash','Uncompressed size','Compressed size','Offset in WIM','Part Number','Reference Count','Flags')
 while($null -ne ($line=$child.StandardOutput.ReadLine())){
  $answer.total_stream_lines++
  $answer.total_stream_chars+=[long]$line.Length
  if($answer.total_stream_lines -gt 1000000 -or $answer.total_stream_chars -gt 70000000 -or $clock.Elapsed.TotalSeconds -gt 45){throw 'BLOB_STREAM_BOUNDS_EXCEEDED'}
  if([string]::IsNullOrWhiteSpace($line)){
   if($resource.Count -ne 7){throw ('RESOURCE_INCOMPLETE_FIELDS_LINE_'+$answer.total_stream_lines)}
   foreach($key in $mandatory){if(-not $resource.ContainsKey($key)){throw ('RESOURCE_MISSING_'+$key)}}
   $sha=[string]$resource['Hash']
   if($sha -notmatch '^0x[a-fA-F0-9]{40}$'){throw 'RESOURCE_HASH_INVALID'}
   if(-not $seen.Add($sha)){throw 'DUPLICATE_RESOURCE_SHA'}
   $u=[regex]::Match([string]$resource['Uncompressed size'],'^([0-9]+)\s+bytes$')
   $c=[regex]::Match([string]$resource['Compressed size'],'^([0-9]+)\s+bytes$')
   $off=[regex]::Match([string]$resource['Offset in WIM'],'^([0-9]+)\s+bytes$')
   if(-not $u.Success -or -not $c.Success -or -not $off.Success){throw 'RESOURCE_SIZE_FIELD_INVALID'}
   $raw=[long]::Parse($u.Groups[1].Value)
   $compressed=[long]::Parse($c.Groups[1].Value)
   $offset=[long]::Parse($off.Groups[1].Value)
   $part=[int]::Parse([string]$resource['Part Number'])
   $refs=[long]::Parse([string]$resource['Reference Count'])
   if($part -ne 1 -or $offset -ge $answer.original_wim_bytes -or $compressed -gt $answer.original_wim_bytes){throw 'RESOURCE_PART_OR_PHYSICAL_BOUNDS'}
   $answer.unique_blobs++
   $answer.compressed_bytes_unique+=$compressed
   $answer.uncompressed_bytes_unique+=$raw
   $answer.sum_reference_counts+=$refs
   if(([string]$resource['Flags']) -match 'WIM_RESHDR_FLAG_METADATA'){$answer.metadata_blobs++;$answer.compressed_metadata_bytes+=$compressed}
   else{$answer.regular_compressed_bytes+=$compressed}
   if($refs -eq 0){$answer.refcount_zero_blobs++}
   elseif($refs -eq 1){$answer.refcount_one_blobs++}
   else{$answer.refcount_shared_blobs++;$answer.refcount_shared_compressed_bytes+=$compressed}
   $resource=@{}
  }else{
   $match=[regex]::Match($line,'^\s*(Hash|Uncompressed size|Compressed size|Offset in WIM|Part Number|Reference Count|Flags)\s*=\s*(.*?)\s*$')
   if(-not $match.Success){throw ('RESOURCE_LABEL_NOT_RECOGNIZED_LINE_'+$answer.total_stream_lines)}
   $key=$match.Groups[1].Value
   if($resource.ContainsKey($key)){throw ('RESOURCE_FIELD_DUPLICATE_'+$key)}
   $resource[$key]=[string]$match.Groups[2].Value.Trim()
  }
 }
 if($resource.Count -ne 0){throw 'TRUNCATED_FINAL_RESOURCE'}
 if(-not $child.WaitForExit(5000)){throw 'BLOB_CHILD_TIMEOUT'}
 $err=[string]$errTask.GetAwaiter().GetResult()
 if($child.ExitCode -ne 0 -or $err.Trim()){throw 'BLOB_VENDOR_EXIT_OR_STDERR_HOLD'}
 if($answer.total_stream_lines -ne 653096 -or $answer.total_stream_chars -ne 19333601 -or $answer.unique_blobs -ne 81637){throw 'BLOB_OUTPUT_SOURCE_COUNTS_DRIFT'}
 if($answer.compressed_bytes_unique -ne 5659534003 -or $answer.uncompressed_bytes_unique -ne 12166151076 -or $answer.refcount_shared_compressed_bytes -ne 3291145779 -or $answer.refcount_one_blobs -ne 50879 -or $answer.refcount_shared_blobs -ne 30758 -or $answer.metadata_blobs -ne 1 -or $answer.compressed_metadata_bytes -ne 7106798){throw 'INDEPENDENT_BLOB_TOTAL_NOT_MATCH_PRODUCER'}
 $answer.accounted_overhead_bytes=$answer.original_wim_bytes-$answer.compressed_bytes_unique
 $answer.header_and_resource_reconcile=($answer.accounted_overhead_bytes -eq $answer.header_bytes_total+$answer.blob_table_bytes+$answer.xml_bytes+$answer.integrity_bytes)
 if(-not $answer.header_and_resource_reconcile -or $answer.header_boot_index -ne 0){throw 'INDEPENDENT_WIM_PHYSICAL_RECONCILE_HOLD'}
 if(@(Get-WindowsImage -Mounted -ErrorAction Stop).Count -ne 0){throw 'POST_WIM_MOUNT_CHANGED'}
 $answer.status='INDEPENDENT_SECOND_SOURCE_ONLY_UNIQUE_BLOB_PHYSICAL_BYTES_PASS'
}catch{$answer.error=$_.Exception.Message;if($null -ne $child -and -not $child.HasExited){try{$child.Kill($true)}catch{}}}
finally{if($null -ne $child){$child.Dispose()}}
$answer|ConvertTo-Json -Depth 5
if($answer.status -ne 'INDEPENDENT_SECOND_SOURCE_ONLY_UNIQUE_BLOB_PHYSICAL_BYTES_PASS'){exit 2}
exit 0
