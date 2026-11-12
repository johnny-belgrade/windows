# R043 OP06: second candidate-specific source-only original 9974 WIM exact paths, P1 size-first, no mount/export/copy/delete.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$cycle='C:\work\_UUP\R043_PREMAX_P1_20261112'
$logs=Join-Path $cycle 'BlueLite_Logs'
$receipt=Join-Path $logs 'R043_OP06_OneDrive_AI_InstalledTargets_Producer.json'
if([IO.File]::Exists($receipt)){throw 'R043_OP06_PRODUCER_ALREADY_EXISTS'}
$native='C:\work\_UUP\R042_FULL_ONECMD_9974_20261111'
$nativeReceipt=Join-Path $native 'BlueLite_Logs\BlueLite_R029_RESULT.json'
$r=Get-Content -LiteralPath $nativeReceipt -Raw|ConvertFrom-Json
if($r.build -ne '26300.9974' -or $r.install_wim_sha256 -ne '61AA38CD52B85962C52E4A8F9D14C4F7C4D0699D9A57446261D26EB723C0AEC2' -or [long]$r.install_wim_bytes -ne 5602983183){throw 'ORIGINAL_NATIVE_SOURCE_9974_RECEIPT_NOT_EXACT'}
$wim=[string]$r.install_wim
$folder=Split-Path (Split-Path $wim -Parent) -Parent
$exe=Join-Path $folder 'bin\wimlib-imagex.exe'
$dll=Join-Path $folder 'bin\libwim-15.dll'
if(-not [IO.File]::Exists($wim) -or ([IO.FileInfo]::new($wim)).Length -ne 5602983183){throw 'ORIGINAL_WIM_PHYSICAL_SOURCE_MISSING_OR_SIZE_CHANGED'}
if((Get-FileHash $exe -Algorithm SHA256).Hash -ne '01168A00FFC84EBFA1BD3B9C841214ED114B9AE4E9B23D555C0686448FD56BDE'){throw 'NATIVE_WIMLIB_EXE_SHA_CHANGED'}
if((Get-FileHash $dll -Algorithm SHA256).Hash -ne 'E1B005C0F1391B30357E64885A08A09A2D41DE93B38ACAA25ED7A355F74F56B4'){throw 'NATIVE_WIMLIB_DLL_SHA_CHANGED'}
if(@(Get-VM|Where-Object{$_.State -ne 'Off'}).Count){throw 'R043_P1_NO_GUEST_MAY_RUN'}
if(@(Get-WindowsImage -Mounted).Count){throw 'R043_P1_CANNOT_INSPECT_WITH_MOUNT'}
if(([IO.DriveInfo]::new('C')).AvailableFreeSpace -lt 60GB){throw 'R043_P1_LOW_SPACE_BELOW_60G'}
if(-not (Get-Disk -Number 0).IsBoot -or @(Get-Disk).Count -ne 1){throw 'R043_HOST_DISKS_CHANGED'}
function NativeList([string]$name,[string[]]$arguments){
 $file=Join-Path $logs ('R043_OP06_'+$name+'.txt')
 if([IO.File]::Exists($file)){throw ('R043_NATIVE_LOG_ALREADY_EXISTS_'+$file)}
 $psi=[Diagnostics.ProcessStartInfo]::new()
 $psi.FileName=$exe
 $psi.WorkingDirectory=Split-Path $exe -Parent
 $psi.UseShellExecute=$false
 $psi.CreateNoWindow=$true
 $psi.RedirectStandardOutput=$true
 $psi.RedirectStandardError=$true
 foreach($a in $arguments){[void]$psi.ArgumentList.Add([string]$a)}
 $p=[Diagnostics.Process]::new()
 $p.StartInfo=$psi
 if(-not $p.Start()){throw ('WIMLIB_CANNOT_START_'+$name)}
 try {
  $stdoutTask=$p.StandardOutput.ReadToEndAsync()
  $stderrTask=$p.StandardError.ReadToEndAsync()
  if(-not $p.WaitForExit(15000)){try{$p.Kill($true)}catch{};throw ('WIMLIB_TIMEOUT_'+$name)}
  $stdout=$stdoutTask.GetAwaiter().GetResult()
  $stderr=$stderrTask.GetAwaiter().GetResult()
  if($stdout.Length -gt 600000 -or $stderr.Length -gt 10000){throw ('WIMLIB_OUTPUT_EXCEEDS_BOUNDED_LIMIT_'+$name)}
  $content="COMMAND: "+($arguments -join ' ') + [Environment]::NewLine +"NATIVE_EXIT: "+$p.ExitCode+[Environment]::NewLine+"STDOUT:"+[Environment]::NewLine+$stdout+[Environment]::NewLine+"STDERR:"+[Environment]::NewLine+$stderr
  [IO.File]::WriteAllText($file,$content,[Text.UTF8Encoding]::new($false))
  return [pscustomobject]@{name=$name;arguments=$arguments;nativeExit=[int]$p.ExitCode;stdoutChars=$stdout.Length;stderrChars=$stderr.Length;log=$file;logSHA=(Get-FileHash $file -Algorithm SHA256).Hash;lines=($stdout -split '\r?\n').Length;singleFileSHA1=if($stdout -match '(?m)^Hash\s+=\s+0x([0-9a-fA-F]{40})'){$Matches[1]}else{''};referenceCounts=@([regex]::Matches($stdout,'(?m)^Reference Count\s+=\s+(\d+)')|ForEach-Object{[int]$_.Groups[1].Value});compressedBytes=@([regex]::Matches($stdout,'(?m)^Compressed size\s+=\s+(\d+) bytes')|ForEach-Object{[long]$_.Groups[1].Value});tail=($stdout -split '\r?\n'|Select-Object -Last 6)-join ' | ';error=if($stderr.Length){$stderr.Substring(0,[math]::Min(340,$stderr.Length))}else{''}}
 } finally {$p.Dispose()}
}
[void][IO.Directory]::CreateDirectory($logs)
$all=[Collections.Generic.List[object]]::new()
$all.Add((NativeList 'CLI_help' @('dir','--help')))
$targets=[ordered]@{
 'OneDriveSetupSysWOW64'='\Windows\SysWOW64\OneDriveSetup.exe'
 'OneDriveSetupSystem32'='\Windows\System32\OneDriveSetup.exe'
 'OneDriveSettingsSync'='\Windows\System32\OneDriveSettingSyncProvider.dll'
 'EdgeUpdateX86'='\Program Files (x86)\Microsoft\EdgeUpdate'
 'RecallAPI'='\Windows\System32\RecallAPI.dll'
 'AIxHost'='\Windows\System32\AIXHost.exe'
 'CBSsearchHost'='\Windows\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\SearchHost.exe'
 'ExactWinREPayload'='\Windows\System32\Recovery\winre.wim'
}
foreach($name in $targets.Keys){
 $args=@('dir',$wim,'1','--detailed',('--path='+[string]$targets[$name]))
 $all.Add((NativeList $name $args))
}
$health=[ordered]@{
 schema='BlueLite.R043.OP06.OriginalWimOneDriveAISourceP1OwnershipTriage.v1'
 utc=[DateTime]::UtcNow.ToString('o')
 status='R043_OP06_ORIGINAL_R042_9974_WIM_P1_BOUNDED_FILE_PATH_METADATA_ONLY_PRODUCER_PASS'
 noMountCopyOrImageMutation=$true
 originalWim=$wim
 originalWimBytes=([IO.FileInfo]::new($wim)).Length
 sourcePinnedWimPhysicalSha256=$r.install_wim_sha256
 sourceR029ReceiptSHA256=(Get-FileHash $nativeReceipt -Algorithm SHA256).Hash
 exactVendorWimlibExeSHA=(Get-FileHash $exe -Algorithm SHA256).Hash
 originalVendorDLLsha=(Get-FileHash $dll -Algorithm SHA256).Hash
 results=$all.ToArray()
 r029NativeDismLogFilenames=@(Get-ChildItem -LiteralPath (Join-Path $native 'BlueLite_Logs') -File -Filter 'BlueLite_R029_DISM_*.txt'|Sort-Object Name|ForEach-Object{[pscustomobject]@{name=$_.Name;bytes=$_.Length}})
 historicalP1PathTriageProducerSHA=(Get-FileHash (Join-Path $logs 'R043_OP02_SourceWim_P1_DirTargets_Producer.json') -Algorithm SHA256).Hash
 freeHostC_GiB=[math]::Round(([IO.DriveInfo]::new('C')).AvailableFreeSpace/1GB,3)
 hostWimMounts=@(Get-WindowsImage -Mounted).Count
 allHyperVGuestsOff=(@(Get-VM|Where-Object{$_.State -ne 'Off'}).Count -eq 0)
 outputFilesCount=9
 largestPhysicalP1GainStillUnproven=$true
}
[IO.File]::WriteAllText($receipt,(($health|ConvertTo-Json -Depth 9)+[Environment]::NewLine),[Text.UTF8Encoding]::new($false))
[pscustomobject]@{status=$health.status;scope=$health.originalWim;results=@($all|ForEach-Object{[pscustomobject]@{name=$_.name;exit=$_.nativeExit;lines=$_.lines;error=$_.error;tail=$_.tail}});receipt=$receipt;receiptSHA=(Get-FileHash $receipt -Algorithm SHA256).Hash;hostFreeGiB=$health.freeHostC_GiB}|ConvertTo-Json -Depth 7 -Compress
