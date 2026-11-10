# R038 OP157: bounded read-only wimlib header/blob metadata sample, NO original media modifications.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$stage='C:\work\_UUP\R035_Universal_PREMAX_26300\BlueLite_Work\BlueLite_Stage_v11_3_26300_9818_6c7bf258_fc76f92b'
$wim=Join-Path $stage 'BlueLite_R029_Outputs\install.wim'
$boot=Join-Path $stage 'BlueLite_R029_Outputs\boot.wim'
$exe=Join-Path $stage 'bin\wimlib-imagex.exe'
$dll=Join-Path $stage 'bin\libwim-15.dll'
function Get-WimInfoStream([string[]]$Arguments,[bool]$BlobMode){
 $psi=[Diagnostics.ProcessStartInfo]::new()
 $psi.FileName=$exe
 $psi.WorkingDirectory=Split-Path -Path $exe -Parent
 $psi.UseShellExecute=$false;$psi.CreateNoWindow=$true
 $psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
 foreach($arg in $Arguments){[void]$psi.ArgumentList.Add([string]$arg)}
 $proc=[Diagnostics.Process]::new()
 $proc.StartInfo=$psi
 $clock=[Diagnostics.Stopwatch]::StartNew()
 try {
  if(-not $proc.Start()){throw 'WIMLIB_START_FAILED'}
  $errorTask=$proc.StandardError.ReadToEndAsync()
  $first=[Collections.Generic.List[string]]::new()
  [long]$chars=0
  [long]$lines=0
  $maxLines=if($BlobMode){500000}else{1000}
  $maxChars=if($BlobMode){60000000}else{40000}
  while($null -ne ($line=$proc.StandardOutput.ReadLine())){
   $lines++
   $chars+=[long]$line.Length
   if($first.Count -lt $(if($BlobMode){20}else{120})){[void]$first.Add($line)}
   if($lines -gt $maxLines -or $chars -gt $maxChars -or $clock.Elapsed.TotalSeconds -gt 45){throw 'WIMLIB_STDOUT_BOUNDS_OR_DEADLINE_EXCEEDED'}
  }
  if(-not $proc.WaitForExit(5000)){throw 'WIMLIB_EXIT_TIMEOUT'}
  $errorOut=[string]$errorTask.GetAwaiter().GetResult()
  if($errorOut.Length -gt 2500){throw 'WIMLIB_STDERR_TOO_LARGE'}
  if($proc.ExitCode -ne 0){throw ('WIMLIB_READONLY_EXIT_'+$proc.ExitCode+':'+$errorOut)}
  return [ordered]@{exit=$proc.ExitCode;lines=$lines;characters=$chars;first_lines=@($first.ToArray());stderr=$errorOut;seconds=[math]::Round($clock.Elapsed.TotalSeconds,2)}
 }catch {
  if(-not $proc.HasExited){try{$proc.Kill($true)}catch{}}
  throw
 }finally{$clock.Stop();$proc.Dispose()}
}
$report=[ordered]@{
 schema='BlueLite.R038.OP157.BoundedWIMHeaderBlobsReadOnly.v1'
 utc=[DateTime]::UtcNow.ToString('o')
 status='HOLD'
 script_sha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
 install_bytes=$null
 boot_bytes=$null
 vendor_exe_sha256=$null
 vendor_dll_sha256=$null
 install_header=$null
 boot_header=$null
 install_blobs_format=$null
 mounted_wim_count=$null
 baseline_guest=$null
 control_guest=$null
 output_files_created=0
 error=$null
}
try {
 foreach($q in @(
  [pscustomobject]@{path=$wim;bytes=[long]5663629505;tag='install'},
  [pscustomobject]@{path=$boot;bytes=[long]824384151;tag='boot'},
  [pscustomobject]@{path=$exe;bytes=[long]149518;tag='exe'},
  [pscustomobject]@{path=$dll;bytes=[long]525838;tag='dll'}
  )){
  $i=Get-Item -LiteralPath $q.path -ErrorAction Stop
  if($i.Length -ne $q.bytes -or (($i.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)){throw ('SOURCE_FILE_CHANGED_'+$q.tag)}
 }
 $report.install_bytes=[long]5663629505
 $report.boot_bytes=[long]824384151
 $report.vendor_exe_sha256=(Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash
 $report.vendor_dll_sha256=(Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash
 if($report.vendor_exe_sha256 -ne '01168A00FFC84EBFA1BD3B9C841214ED114B9AE4E9B23D555C0686448FD56BDE'){throw 'VENDOR_EXE_SHA_DRIFT'}
 if($report.vendor_dll_sha256 -ne 'E1B005C0F1391B30357E64885A08A09A2D41DE93B38ACAA25ED7A355F74F56B4'){throw 'VENDOR_DLL_SHA_DRIFT'}
 $report.mounted_wim_count=@(Get-WindowsImage -Mounted -ErrorAction Stop).Count
 if($report.mounted_wim_count -ne 0){throw 'WIM_MOUNT_PREEXISTING'}
 $base=Get-VM -Id 'c7536cc4-68f5-473a-9818-4053ba8794b2' -ErrorAction Stop
 $control=Get-VM -Id 'deb10ab5-3093-47a8-9a13-f3927446c606' -ErrorAction Stop
 $report.baseline_guest=([string]$base.State)+'/'+([string](Get-VMFirmware -VMName $base.Name).SecureBoot)
 $report.control_guest=([string]$control.State)+'/'+([string](Get-VMFirmware -VMName $control.Name).SecureBoot)
 if($base.Name -ne 'BlueLite-R038-UEFI-Baseline' -or $control.Name -ne 'BlueLite-R038-UEFI-SBOff-Control' -or $report.baseline_guest -ne 'Running/On' -or $report.control_guest -ne 'Off/Off'){throw 'DEV_VM_STATE_DRIFT'}
 $report.install_header=Get-WimInfoStream @('info',$wim,'--header') $false
 $report.boot_header=Get-WimInfoStream @('info',$boot,'--header') $false
 $report.install_blobs_format=Get-WimInfoStream @('info',$wim,'--blobs') $true
 if(@(Get-WindowsImage -Mounted -ErrorAction Stop).Count -ne 0){throw 'WIM_MOUNT_POST'}
 $report.status='SOURCE_ONLY_R035_WIM_HEADER_AND_BLOB_FORMAT_PASS'
}catch{$report.error=$_.Exception.Message}
$report|ConvertTo-Json -Depth 7
if($report.status -ne 'SOURCE_ONLY_R035_WIM_HEADER_AND_BLOB_FORMAT_PASS'){exit 2}
exit 0
