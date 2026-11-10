# R038 OP144 source-only original R035 WIM metadata/index/physical SHA, NO WIM mounts or outputs.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$stage='C:\work\_UUP\R035_Universal_PREMAX_26300\BlueLite_Work\BlueLite_Stage_v11_3_26300_9818_6c7bf258_fc76f92b'
$out=Join-Path $stage 'BlueLite_R029_Outputs'
$install=Join-Path $out 'install.wim'
$boot=Join-Path $out 'boot.wim'
$exe=Join-Path $stage 'bin\wimlib-imagex.exe'
$dll=Join-Path $stage 'bin\libwim-15.dll'
function Invoke-CapturedReadOnly([string]$Executable,[string[]]$Arguments,[int]$MaxChars=24000) {
 $psi=[Diagnostics.ProcessStartInfo]::new()
 $psi.FileName=$Executable
 $psi.WorkingDirectory=Split-Path -Parent $Executable
 $psi.UseShellExecute=$false;$psi.CreateNoWindow=$true
 $psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
 foreach($a in $Arguments){[void]$psi.ArgumentList.Add([string]$a)}
 $child=[Diagnostics.Process]::new()
 $child.StartInfo=$psi
 try {
  if(-not $child.Start()){throw 'CHILD_START_FALSE'}
  $outTask=$child.StandardOutput.ReadToEndAsync()
  $errTask=$child.StandardError.ReadToEndAsync()
  if(-not $child.WaitForExit(30000)){
   try{$child.Kill($true)}catch{}
   throw 'CHILD_30SECOND_TIMEOUT'
  }
  $stdout=[string]$outTask.GetAwaiter().GetResult()
  $stderr=[string]$errTask.GetAwaiter().GetResult()
  if($stdout.Length -gt $MaxChars -or $stderr.Length -gt 3000){throw 'CHILD_METADATA_OUTPUT_EXCEEDS_BOUND'}
  return [pscustomobject]@{exit=$child.ExitCode;stdout=$stdout;stderr=$stderr}
 }finally{$child.Dispose()}
}
$report=[ordered]@{
 schema='BlueLite.R038.OP144.WimIndexCompressionReadOnly.v1'
 utc=[DateTime]::UtcNow.ToUniversalTime().ToString('o')
 status='HOLD'
 script_sha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
 original_install_bytes=$null;original_install_sha256=$null
 original_boot_bytes=$null;original_boot_sha256=$null
 wimlib_exe_bytes=$null;wimlib_exe_sha256=$null;wimlib_dll_bytes=$null;wimlib_dll_sha256=$null
 wimlib_install_index1=$null;wimlib_boot_index1=$null;wimlib_boot_index2=$null
 dism_install_index1=$null;dism_boot_index1=$null;dism_boot_index2=$null
 mounted_wim_count=$null;baseline_guest=$null;control_guest=$null
 created_result_files=0;error=$null
}
try{
 foreach($item in @(
   [pscustomobject]@{path=$install;bytes=[long]5663629505;sha='1441B1900374A503DB9045236AEDF1C9604E56A78AA5F9CDCF394DEDC383AD67';name='install'},
   [pscustomobject]@{path=$boot;bytes=[long]824384151;sha='F659254B86D7478B02A5D02204530CDA8805FE8EA58A4DFE69F69BB4C0144A26';name='boot'}
 )){
  $fi=Get-Item -LiteralPath $item.path -ErrorAction Stop
  if($fi.Length -ne $item.bytes -or (($fi.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)){throw ($item.name+'_FILE_SIZE_OR_REPARSE_CHANGED')}
  $sha=(Get-FileHash -LiteralPath $item.path -Algorithm SHA256).Hash
  if($sha -ne $item.sha){throw ($item.name+'_ORIGINAL_FULL_SHA_CHANGED')}
  if($item.name -eq 'install'){$report.original_install_bytes=[long]$fi.Length;$report.original_install_sha256=$sha}
  else{$report.original_boot_bytes=[long]$fi.Length;$report.original_boot_sha256=$sha}
 }
 foreach($entry in @(
  [pscustomobject]@{path=$exe;name='exe'},
  [pscustomobject]@{path=$dll;name='dll'}
 )){
  $t=Get-Item -LiteralPath $entry.path -ErrorAction Stop
  if(($t.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'WIMLIB_TOOL_REPARSE'}
  $sha=(Get-FileHash -LiteralPath $entry.path -Algorithm SHA256).Hash
  if($entry.name -eq 'exe'){$report.wimlib_exe_bytes=[long]$t.Length;$report.wimlib_exe_sha256=$sha}
  else{$report.wimlib_dll_bytes=[long]$t.Length;$report.wimlib_dll_sha256=$sha}
 }
 $report.mounted_wim_count=@(Get-WindowsImage -Mounted -ErrorAction Stop).Count
 if($report.mounted_wim_count -ne 0){throw 'PREEXISTING_WIM_MOUNT_PRESENT'}
 $base=Get-VM -Id 'c7536cc4-68f5-473a-9818-4053ba8794b2' -ErrorAction Stop
 $control=Get-VM -Id 'deb10ab5-3093-47a8-9a13-f3927446c606' -ErrorAction Stop
 $report.baseline_guest=([string]$base.State)+'/'+([string](Get-VMFirmware -VMName $base.Name).SecureBoot)
 $report.control_guest=([string]$control.State)+'/'+([string](Get-VMFirmware -VMName $control.Name).SecureBoot)
 if($base.Name -ne 'BlueLite-R038-UEFI-Baseline' -or $control.Name -ne 'BlueLite-R038-UEFI-SBOff-Control' -or $report.baseline_guest -ne 'Running/On' -or $report.control_guest -ne 'Off/Off'){throw 'VM_STATE_DRIFT'}
 $queries=@(
  [pscustomobject]@{tag='wimlib_install_index1';exec=$exe;args=@('info',$install,'1')},
  [pscustomobject]@{tag='wimlib_boot_index1';exec=$exe;args=@('info',$boot,'1')},
  [pscustomobject]@{tag='wimlib_boot_index2';exec=$exe;args=@('info',$boot,'2')},
  [pscustomobject]@{tag='dism_install_index1';exec='C:\Windows\System32\dism.exe';args=@('/English','/Get-WimInfo',("/WimFile:"+$install),'/Index:1')},
  [pscustomobject]@{tag='dism_boot_index1';exec='C:\Windows\System32\dism.exe';args=@('/English','/Get-WimInfo',("/WimFile:"+$boot),'/Index:1')},
  [pscustomobject]@{tag='dism_boot_index2';exec='C:\Windows\System32\dism.exe';args=@('/English','/Get-WimInfo',("/WimFile:"+$boot),'/Index:2')}
 )
 foreach($q in $queries){
  $result=Invoke-CapturedReadOnly $q.exec ([string[]]$q.args)
  $report[$q.tag]=[ordered]@{exit=$result.exit;stdout=$result.stdout;stderr=$result.stderr}
  if($result.exit -ne 0){throw ('READONLY_METADATA_FAILED_'+$q.tag)}
 }
 $after=@(Get-WindowsImage -Mounted -ErrorAction Stop).Count
 if($after -ne 0){throw 'POST_METADATA_WIM_MOUNT_UNEXPECTED'}
 $report.status='ORIGINAL_R035_WIM_INDEX_METADATA_FULL_SHA_READONLY_PASS'
}catch{$report.error=$_.Exception.Message}
$report|ConvertTo-Json -Depth 9
if($report.status -ne 'ORIGINAL_R035_WIM_INDEX_METADATA_FULL_SHA_READONLY_PASS'){exit 2}
exit 0
