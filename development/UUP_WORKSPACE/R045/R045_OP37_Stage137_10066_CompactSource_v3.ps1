# R045 OP37 ATTEMPT3 compact original 26300.10066 signed137 copy ONLY
[CmdletBinding()]param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$manifest='C:\work\_UUP\temp\R043_OP211_WimOnlyManifest_20261117\R043_OP211_ProposedSource137Stage.json'
$zip='C:\work\_UUP\_UUP_Originals\26300.10066_amd64_en-us_professional_0344497f_convert.zip'
$stage='C:\work\_UUP\R045_OP37_Stage137_10066_20261121'
$receipts='C:\work\logs\R045_OP37_Stage137_SourceReceipts_v3'
$report='C:\work\logs\R045_OP37_Stage137_Producer_v3.json'
$trace='C:\work\logs\R045_OP37_Stage137_v3_Trace.log'
$utf8=[Text.UTF8Encoding]::new($false)
if((Test-Path -LiteralPath $trace) -or (Test-Path -LiteralPath $stage) -or (Test-Path -LiteralPath $receipts) -or (Test-Path -LiteralPath $report)){throw 'EXACT_FRESH_OWNER_OR_RECEIPT_EXISTS'}
[IO.File]::WriteAllText($trace,([DateTime]::UtcNow.ToString('o')+' SCRIPT_START'+[Environment]::NewLine),$utf8)
function Mark([string]$s){[IO.File]::AppendAllText($trace,([DateTime]::UtcNow.ToString('o')+' '+$s+[Environment]::NewLine),$utf8);Write-Output $s}
function NewBytes([string]$p,[byte[]]$b){$f=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$f.Write($b,0,$b.Length);$f.Flush($true)}finally{$f.Dispose()}}
$r=[ordered]@{Op='R045_OP37';Attempt=3;UTCStart=[DateTime]::UtcNow.ToString('o');Status='PENDING';GitPre='2dc0c886344e51a49305f3b6c886905bf6a2a063';SourceManifest=$manifest;ManifestSHA='';OriginalZip=$zip;OriginalZipSHA='';StageRoot=$stage;ReceiptRoot=$receipts;Count=0;Bytes=[long]0;WindowsCount=0;AppsCount=0;Rows=@();VMOffCount=-1;MountedWIMCount=-1;InitialCFreeB=[long]0;AfterCFreeB=[long]0;ConverterExecution='NOT_RUN';ISOorWIMCreated=$false;Error='';UTCEnd=''}
$expected=[long]9119622618
$floor=[long]64424509440+[long]7384383716+[long]6442450944
$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
try{
 Mark '01_CHECK_SOURCE_SHA'
 $r.ManifestSHA=(Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash
 $r.OriginalZipSHA=(Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
 if($r.ManifestSHA -ne 'FA831096050A74AF5DF58B8C61DDF19BFD8487D34FACD75551F440FBB425DD75' -or $r.OriginalZipSHA -ne '8FE361765967DA0651078C324B21E6C6D7595081DBACBB26049EC53AB59DE404'){throw 'PINNED_ORIGINAL_SOURCE_SHA_HOLD'}
 $m=Get-Content -LiteralPath $manifest -Raw|ConvertFrom-Json -Depth 20
 if(@($m.sourceFiles).Count -ne 137 -or [long]$m.stageBytes -ne $expected -or $m.targetRoot -ne 'C:\work\_UUP\temp\R043_OP213_10066_WimOnly_20261117'){throw 'SIGNED137_MANIFEST_SCOPE_HOLD'}
 Mark '02_CHECK_DISK_VM_WIM'
 $r.InitialCFreeB=[long](Get-PSDrive C).Free
 if($r.InitialCFreeB -lt ($floor+$expected)){throw 'C_FREE_60GIB_PLUS_WIM_SCRATCH_AND_137_SOURCE_HOLD'}
 $vms=@(Get-VM)
 $r.VMOffCount=@($vms|Where-Object{$_.State -eq 'Off'}).Count
 $r.MountedWIMCount=@(Get-WindowsImage -Mounted).Count
 if($vms.Count -ne 3 -or $r.VMOffCount -ne 3 -or $r.MountedWIMCount -ne 0 -or @(Get-Process -Name 'dism','dismhost','wimlib-imagex','aria2c' -ErrorAction SilentlyContinue).Count -gt 0){throw 'HOST_BUSY_OR_HYPERV_3OFF_MOUNT0_HOLD'}
 Mark '03_CREATE_SINGLE_OWNED_STAGE_AND_RECEIPTS'
 [IO.Directory]::CreateDirectory((Join-Path $stage 'UUPs'))|Out-Null
 [IO.Directory]::CreateDirectory($receipts)|Out-Null
 $buffer=[byte[]]::new(4194304)
 foreach($entry in @($m.sourceFiles)){
  $rel=[string]$entry.stagingRelative
  $src=[string]$entry.sourcePath
  if(-not $rel.StartsWith('UUPs\', [StringComparison]::OrdinalIgnoreCase) -or $rel.Contains('..') -or -not $seen.Add($rel) -or -not $src.StartsWith('C:\work\_UUP\', [StringComparison]::OrdinalIgnoreCase)){throw ('BAD_SOURCE_OR_DESTINATION_'+$rel)}
  $fi=[IO.FileInfo]::new($src)
  if(-not $fi.Exists -or $fi.Length -ne [long]$entry.bytes -or ($fi.Attributes -band [IO.FileAttributes]::ReparsePoint)){throw ('SOURCE_BYTES_OR_REPARSE_HOLD_'+$rel)}
  if([long](Get-PSDrive C).Free -lt ($floor+$expected-$r.Bytes)){throw ('DISK_FLOOR_HOLD_'+$r.Count)}
  $dest=Join-Path $stage $rel
  $parent=[IO.Path]::GetDirectoryName($dest)
  if(-not [IO.Directory]::Exists($parent)){[IO.Directory]::CreateDirectory($parent)|Out-Null}
  Mark ('FILE_BEGIN_'+($r.Count+1)+'/137 '+$rel)
  $input=[IO.File]::Open($src,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
  $output=[IO.File]::Open($dest,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
  $h1=[Security.Cryptography.IncrementalHash]::CreateHash([Security.Cryptography.HashAlgorithmName]::SHA1)
  $h256=[Security.Cryptography.IncrementalHash]::CreateHash([Security.Cryptography.HashAlgorithmName]::SHA256)
  $n=[long]0
  try{
   while(($size=$input.Read($buffer,0,$buffer.Length)) -gt 0){$h1.AppendData($buffer,0,$size);$h256.AppendData($buffer,0,$size);$output.Write($buffer,0,$size);$n+=$size;if($n -gt [long]$entry.bytes){throw 'SOURCE_LENGTH_CHANGED_DURING_READ'}}
   $output.Flush($true);$sha1=[Convert]::ToHexString($h1.GetHashAndReset());$sh256=[Convert]::ToHexString($h256.GetHashAndReset())
  }finally{$h1.Dispose();$h256.Dispose();$output.Dispose();$input.Dispose()}
  if($n -ne [long]$entry.bytes -or $sha1 -ne [string]$entry.sourceSHA1 -or (Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash -ne $sh256){throw ('STAGE_FILE_SHA_HOLD_'+$rel)}
  $row=[ordered]@{source=$src;relative=$rel;bytes=$n;sourceSHA1=$sha1;physicalCopySHA256=$sh256;stage=$dest}
  $file=Join-Path $receipts ('{0:D3}.json' -f ($r.Count+1))
  NewBytes $file ($utf8.GetBytes(($row|ConvertTo-Json -Depth 8)+[Environment]::NewLine))
  $r.Rows+=,$row;$r.Count++;$r.Bytes+=$n
  if([string]$entry.role -like 'Windows*'){$r.WindowsCount++}else{$r.AppsCount++}
  Mark ('FILE_DONE_'+$r.Count+'/137 BYTES_TOTAL='+$r.Bytes)
 }
 if($r.Count -ne 137 -or $r.Bytes -ne $expected -or $r.WindowsCount -ne 98 -or $r.AppsCount -ne 39){throw 'FINAL137_ORIGINAL_CLOSURE_COUNT_HOLD'}
 if(@(Get-VM|Where-Object {$_.State -ne 'Off'}).Count -ne 0 -or @(Get-WindowsImage -Mounted).Count -ne 0){throw 'POSTCOPY_HOST_OCCUPANCY_HOLD'}
 $r.Status='NATIVE_ORIGINAL_10066_OWNED_137_SIGNED_SOURCE_COPY_PASS_PENDING_INDEPENDENT'
 Mark '137_STREAM_SOURCE_COPY_COMPLETE_PASS'
}catch{
 $r.Status='NATIVE_137_SOURCE_COPY_DEPENDENCY_HOLD';$r.Error=[string]$_.Exception.Message
 Mark ('FAIL_'+$r.Error)
}
$r.AfterCFreeB=[long](Get-PSDrive C).Free;$r.UTCEnd=[DateTime]::UtcNow.ToString('o')
NewBytes $report ($utf8.GetBytes(($r|ConvertTo-Json -Depth 15)+[Environment]::NewLine))
Mark ('NATIVE_RESULT='+$r.Status+' COUNT='+$r.Count+' BYTES='+$r.Bytes+' RECEIPT_SHA='+(Get-FileHash -LiteralPath $report -Algorithm SHA256).Hash)
if($r.Status -ne 'NATIVE_ORIGINAL_10066_OWNED_137_SIGNED_SOURCE_COPY_PASS_PENDING_INDEPENDENT'){exit 17}
exit 0
