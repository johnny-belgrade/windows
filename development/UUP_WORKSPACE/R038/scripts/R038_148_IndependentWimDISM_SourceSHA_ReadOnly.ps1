# R038 OP148 independent R035 WIM SHA, DISM index metadata and WIM header; read-only.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$stage='C:\work\_UUP\R035_Universal_PREMAX_26300\BlueLite_Work\BlueLite_Stage_v11_3_26300_9818_6c7bf258_fc76f92b'
$install=Join-Path $stage 'BlueLite_R029_Outputs\install.wim'
$boot=Join-Path $stage 'BlueLite_R029_Outputs\boot.wim'
$wimlib=Join-Path $stage 'bin\wimlib-imagex.exe'
function Read-Command([string]$Executable,[string[]]$Args,[int]$Limit=14000){
 $p=[Diagnostics.Process]::new()
 $psi=[Diagnostics.ProcessStartInfo]::new()
 $psi.FileName=$Executable
 $psi.WorkingDirectory=Split-Path $Executable -Parent
 $psi.UseShellExecute=$false
 $psi.CreateNoWindow=$true
 $psi.RedirectStandardOutput=$true
 $psi.RedirectStandardError=$true
 foreach($arg in $Args){[void]$psi.ArgumentList.Add([string]$arg)}
 $p.StartInfo=$psi
 try {
  if(-not $p.Start()){throw 'PROCESS_START_FAILED'}
  $oTask=$p.StandardOutput.ReadToEndAsync()
  $eTask=$p.StandardError.ReadToEndAsync()
  if(-not $p.WaitForExit(30000)){try{$p.Kill($true)}catch{};throw 'PROCESS_TIMED_OUT'}
  $out=[string]$oTask.GetAwaiter().GetResult()
  $err=[string]$eTask.GetAwaiter().GetResult()
  if($out.Length -gt $Limit -or $err.Length -gt 2000){throw 'PROCESS_OUTPUT_TOO_LARGE'}
  return [pscustomobject]@{exit=$p.ExitCode;stdout=$out;stderr=$err}
 }finally{$p.Dispose()}
}
function Assert-Index([string]$Name,[object]$Result,[int]$Index,[string]$Display,[string]$Version,[string]$Sp,[long]$Logical,[int]$Files){
 if($Result.exit -ne 0){throw ($Name+'_DISM_EXIT_'+$Result.exit)}
 $s=[string]$Result.stdout
 foreach($pat in @(
  '(?im)^\s*Index\s*:\s*'+$Index+'\s*$',
  '(?im)^\s*Name\s*:\s*'+[regex]::Escape($Display)+'\s*$',
  '(?im)^\s*Version\s*:\s*'+[regex]::Escape($Version)+'\s*$',
  '(?im)^\s*ServicePack Build\s*:\s*'+[regex]::Escape($Sp)+'\s*$',
  '(?im)^\s*Architecture\s*:\s*x64\s*$',
  '(?im)^\s*Files\s*:\s*'+$Files+'\s*$'
  )){
  if($s -notmatch $pat){throw ($Name+'_DISM_INDEX_FIELD_MISSING: '+$pat)}
 }
 $m=[regex]::Match($s,'(?im)^\s*Size\s*:\s*([\d,]+)\s*bytes\s*$')
 if(-not $m.Success){throw ($Name+'_DISM_IMAGE_LOGICAL_SIZE_MISSING')}
 if(([long]($m.Groups[1].Value -replace ',','')) -ne $Logical){throw ($Name+'_DISM_IMAGE_LOGICAL_SIZE_CHANGED')}
 return [ordered]@{index=$Index;name=$Display;version=$Version;servicepack_build=$Sp;logical_bytes=$Logical;file_count=$Files;dism_bootable=([regex]::Match($s,'(?im)^\s*WIM Bootable\s*:\s*(\w+)\s*$')).Groups[1].Value;dism_exit=$Result.exit}
}
$r=[ordered]@{
 schema='BlueLite.R038.OP148.IndependentOriginalWimDISM.v1'
 utc=[DateTime]::UtcNow.ToString('o')
 status='HOLD'
 script_sha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
 original_install_sha256=$null;original_install_bytes=$null
 original_boot_sha256=$null;original_boot_bytes=$null
 index_details=@();wimlib_sha256=$null;wimlib_header_exit=$null;wimlib_header_text=$null
 mounted_wim_count=$null;baseline_guest=$null;control_guest=$null
 result_files_created=0;error=$null
}
try{
 foreach($x in @(
  [pscustomobject]@{name='install';path=$install;bytes=[long]5663629505;sha='1441B1900374A503DB9045236AEDF1C9604E56A78AA5F9CDCF394DEDC383AD67'},
  [pscustomobject]@{name='boot';path=$boot;bytes=[long]824384151;sha='F659254B86D7478B02A5D02204530CDA8805FE8EA58A4DFE69F69BB4C0144A26'}
  )){
  $f=Get-Item -LiteralPath $x.path -ErrorAction Stop
  if($f.Length -ne $x.bytes -or (($f.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)){throw ($x.name+'_FILE_SIZE_OR_LINK')}
  $sha=(Get-FileHash -LiteralPath $x.path -Algorithm SHA256).Hash
  if($sha -ne $x.sha){throw ($x.name+'_SHA_CHANGED')}
  if($x.name -eq 'install'){$r.original_install_sha256=$sha;$r.original_install_bytes=[long]$f.Length}
  else{$r.original_boot_sha256=$sha;$r.original_boot_bytes=[long]$f.Length}
 }
 $r.mounted_wim_count=@(Get-WindowsImage -Mounted -ErrorAction Stop).Count
 if($r.mounted_wim_count -ne 0){throw 'MOUNTED_IMAGE_PRESENT'}
 $base=Get-VM -Id 'c7536cc4-68f5-473a-9818-4053ba8794b2' -ErrorAction Stop
 $ctl=Get-VM -Id 'deb10ab5-3093-47a8-9a13-f3927446c606' -ErrorAction Stop
 $r.baseline_guest=([string]$base.State)+'/'+([string](Get-VMFirmware -VMName $base.Name).SecureBoot)
 $r.control_guest=([string]$ctl.State)+'/'+([string](Get-VMFirmware -VMName $ctl.Name).SecureBoot)
 if($base.Name -ne 'BlueLite-R038-UEFI-Baseline' -or $ctl.Name -ne 'BlueLite-R038-UEFI-SBOff-Control' -or $r.baseline_guest -ne 'Running/On' -or $r.control_guest -ne 'Off/Off'){throw 'VM_STATE_CHANGED'}
 $dism='C:\Windows\System32\dism.exe'
 foreach($q in @(
  [pscustomobject]@{tag='install_1';file=$install;index=1;name='Windows 11 Pro';ver='10.0.26300';sp='9818';logical=[long]21607933039;count=128981},
  [pscustomobject]@{tag='winpe_1';file=$boot;index=1;name='Microsoft Windows PE (x64)';ver='10.0.26100';sp='9818';logical=[long]2980777149;count=21402},
  [pscustomobject]@{tag='setup_2';file=$boot;index=2;name='Microsoft Windows Setup (x64)';ver='10.0.26100';sp='9818';logical=[long]3036038889;count=21546}
  )){
  $command=Read-Command $dism ([string[]]@('/English','/Get-WimInfo',('/WimFile:'+$q.file),('/Index:'+$q.index)))
  $r.index_details+=Assert-Index $q.tag $command $q.index $q.name $q.ver $q.sp $q.logical $q.count
 }
 $tool=Get-Item -LiteralPath $wimlib -ErrorAction Stop
 if($tool.Length -ne 149518 -or (($tool.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)){throw 'WIMLIB_TOOL_IDENTITY_CHANGED'}
 $r.wimlib_sha256=(Get-FileHash -LiteralPath $wimlib -Algorithm SHA256).Hash
 if($r.wimlib_sha256 -ne '01168A00FFC84EBFA1BD3B9C841214ED114B9AE4E9B23D555C0686448FD56BDE'){throw 'WIMLIB_TOOL_SHA_CHANGED'}
 $header=Read-Command $wimlib ([string[]]@('info',$boot)) 22000
 $r.wimlib_header_exit=$header.exit
 $r.wimlib_header_text=$header.stdout
 if($header.exit -ne 0){throw 'WIMLIB_FILE_HEADER_READ_FAILED'}
 if($r.wimlib_header_text.Length -lt 30){throw 'WIMLIB_HEADER_UNEXPECTED_EMPTY'}
 if(@(Get-WindowsImage -Mounted -ErrorAction Stop).Count -ne 0){throw 'POST_WIM_MOUNTED'}
 $r.status='INDEPENDENT_R035_INSTALL_BOOT_WIM_SHA_DISM_INDEX_AND_HEADER_PASS'
}catch{$r.error=$_.Exception.Message}
$r|ConvertTo-Json -Depth 7
if($r.status -ne 'INDEPENDENT_R035_INSTALL_BOOT_WIM_SHA_DISM_INDEX_AND_HEADER_PASS'){exit 2}
exit 0
