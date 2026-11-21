# R054 OP04 source-approved run once: only new LAB copy of genuine 26300.10066 install.wim
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$base='C:\work\_UUP'
$lab=Join-Path $base 'temp\R054_Lab_20261121'
$bl=Join-Path $lab 'BlueLite'
$hist=Join-Path $base 'UUP-history\R054_20261121'
$originalSource=Join-Path $base 'temp\R052\BlueLite_Work\OP45_SourceOnly_26300_10066_0344497f_0fce93d5\BlueLite_Work\BlueLite_Stage_v11_3_26300_10066_0344497f_24422d89\ISOFOLDER\sources\install.wim'
$labWim=Join-Path $lab 'ISOFOLDER\sources\install.wim'
$labBoot=Join-Path $lab 'ISOFOLDER\sources\boot.wim'
$targetBeforeSHA='99407C0AA99EC0A06355D8F5C23DBEEAD6E1A1D5F147771026AF48D4AD638916'
$targetBootSHA='465AA39E91C94009225A79FD582976D9FDB654EEC75D314C100ADFB6984CEA8A'
$work=Join-Path $lab 'W'
$log=Join-Path $lab 'BlueLite_Logs\FinalWimDebloat.log'
$stdout=Join-Path $hist 'R054_OP04_OfflineWimNative.stdout.log'
$stderr=Join-Path $hist 'R054_OP04_OfflineWimNative.stderr.log'
$started=Join-Path $hist 'R054_OP04_Started.json'
$out=Join-Path $hist 'R054_OP04_NativeOutcome.json'
function SHA([string]$file){return (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToUpperInvariant()}
function SaveNewJson([string]$p,[object]$data){
 $bytes=[Text.UTF8Encoding]::new($false).GetBytes(($data|ConvertTo-Json -Depth 11)+[Environment]::NewLine)
 $f=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$f.Write($bytes,0,$bytes.Length)}finally{$f.Dispose()}
}
foreach($p in @($started,$out,$stdout,$stderr,$log,$work)){if(Test-Path -LiteralPath $p){throw ('NON_UNIQUE_IMAGE_LAB_OUTPUT '+$p)}}
if((SHA $labWim) -cne $targetBeforeSHA -or (Get-Item $labWim).Length -ne 7414889686){throw 'LAB_SOURCE_INSTALL_WIM_CHANGED_BEFORE_RUN'}
if((SHA $originalSource) -cne $targetBeforeSHA){throw 'ORIGINAL_PROTECTED_R052_WIM_CHANGED'}
if((SHA $labBoot) -cne $targetBootSHA){throw 'LAB_SOURCE_SETUP_BOOT_CHANGED'}
if((SHA (Join-Path $base 'R054_PREMAX_Universal_26300x\BlueLite_PRE_MAX_26300x_R054_v1.zip')) -cne '627B1696C832C69E7379269D1632D5D1A79D3BC6EB595C0FCFF4337100DD8423'){throw 'R054_SOURCE_ZIP_CHANGED'}
if((SHA (Join-Path $bl 'BlueLite_PreDebloatWim.ps1')) -cne (SHA (Join-Path $base 'temp\R054_OP01_Src_20261121\Source\Engine\BlueLite\BlueLite_PreDebloatWim.ps1'))){throw 'REAL_LAB_MODIFIED_SOURCE_SCRIPT_DIFF'}
if(@(Get-VM|Where-Object {$_.State -ne 'Off'}).Count -ne 0){throw 'VM_CURRENTLY_ACTIVE'}
$mounted=(& dism.exe /English /Get-MountedWimInfo 2>&1|Out-String)
if($LASTEXITCODE -ne 0 -or -not $mounted.Contains('No mounted images found.')){throw 'EXISTING_DISM_MOUNT_HOLD'}
if([IO.DriveInfo]::new('C').AvailableFreeSpace -lt 53687091200){throw 'C_FREE_LT50GIB'}
$original=Get-Content (Join-Path $lab 'BlueLite_Logs\ResolvedUUP.json') -Raw|ConvertFrom-Json
if($original.UUP_BUILD -ne '26300.10066'){throw 'EXPECTED_ORIGINAL_UUP_BUILD_MISMATCH'}
$pwsh=Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'
if(-not [IO.File]::Exists($pwsh)){throw 'REQUIRED_PSH7_X64_ABSENT'}
$script=Join-Path $bl 'BlueLite_PreDebloatWim.ps1'
$argList=@('-NoLogo','-NoProfile','-NonInteractive','-File',$script,
'-WimPath',$labWim,'-Index','1',
'-CapabilityPatternsFile',(Join-Path $bl 'BlueLite_CapabilityRemovePatterns.txt'),
'-FeatureDisableOnlyFile',(Join-Path $bl 'BlueLite_FeatureDisableOnly.txt'),
'-FeatureRemovePayloadFile',(Join-Path $bl 'BlueLite_FeatureRemovePayload.txt'),
'-PackagePatternsFile',(Join-Path $bl 'BlueLite_PackageRemovePatterns.txt'),
'-CustomAppsListPath',(Join-Path $lab 'CustomAppsList.txt'),
'-ProfilePath',(Join-Path $bl 'BlueLite_Profile.ini'),
'-ComponentWatchlistFile',(Join-Path $bl 'BlueLite_ComponentWatchlist.txt'),
'-RequiredStagingAppIdentitiesFile',(Join-Path $bl 'BlueLite_RequiredStagingApps.txt'),
'-RequiredFinalAppIdentitiesFile',(Join-Path $bl 'BlueLite_RequiredFinalApps.txt'),
'-StagingOnlyAppPatternsFile',(Join-Path $bl 'BlueLite_StagingOnlyAppPatterns.txt'),
'-ReleaseForbiddenAppPatternsFile',(Join-Path $bl 'BlueLite_ReleaseForbiddenAppPatterns.txt'),
'-OfflineHandoffPatternsFile',(Join-Path $bl 'BlueLite_OfflineHandoffPatterns.txt'),
'-ProtectedFloorFile',(Join-Path $bl 'BlueLite_ProtectedFloor.txt'),
'-ExpectedBuildFile',(Join-Path $lab 'BlueLite_Logs\ResolvedUUP.json'),
'-MaxInstallWimBytes','5500000000',
'-WorkDirectory',$work,'-LogPath',$log)
$begin=[DateTime]::UtcNow
SaveNewJson $started ([ordered]@{
 Schema='BlueLite.R054.OP04.LiveOfflineWimStarted.v1';UTC=$begin.ToString('o');PID=$PID;ActualBuild='26300.10066'
 OriginalInputWimSHA=$targetBeforeSHA;ActualLabInputWim=$labWim;ActualNewPS7WIMScriptSHA=(SHA $script)
 AbsoluteX64PowerShell7=$pwsh;ShortMountWorkRoot=$work;AbsoluteRealArguments=$argList
 TargetMaxInstallWimDecimalBytes=5500000000;NativeSourceWinRESkip=1
 FirstBootVM='NOT_RUN';OneNext='ACTUAL_NATIVE_CHILD_CODE_AND_DISM_UNMOUNT_OUTCOME'
})
$code=999;$message=''
Push-Location -LiteralPath $lab
try{
 try{
  & $pwsh @argList 1> $stdout 2> $stderr
  $code=$LASTEXITCODE
 }catch{
  $message=$_.Exception.ToString()
  if($null -ne $LASTEXITCODE){$code=[int]$LASTEXITCODE}
 }
}finally{Pop-Location}
$end=[DateTime]::UtcNow
$wimBytes=$(if([IO.File]::Exists($labWim)){(Get-Item $labWim).Length}else{0})
$wimSHA=$(if([IO.File]::Exists($labWim)){SHA $labWim}else{''})
$bootSHA=$(if([IO.File]::Exists($labBoot)){SHA $labBoot}else{''})
$logSHA=$(if([IO.File]::Exists($log)){SHA $log}else{''})
$result=[ordered]@{
 Schema='BlueLite.R054.OP04.RealGenuine10066LABOfflineWIMOutcome.v1';UTC=$end.ToString('o');PID=$PID
 NativePS7ChildExit=$code;ActualError=$message;ElapsedSeconds=[math]::Round(($end-$begin).TotalSeconds,3)
 OriginalProtectedR052ImagePath=$originalSource;OriginalProtectedR052ExpectedSHA=$targetBeforeSHA
 RealLABRoot=$lab;OfflineScriptSourceSHA=(SHA $script);SelectedUUPBuild='26300.10066'
 RealLabWimPath=$labWim;LABWimBytes=$wimBytes;LABWimSHA256=$wimSHA
 OriginalLABBootWimSHA256=$bootSHA;TargetMaxWimDecimalBytes=5500000000
 WIMLessOrEqualTarget=($wimBytes -le 5500000000)
 NativeWimScriptLogPath=$log;NativeWimScriptLogSHA256=$logSHA
 NativePS7Stdout=$stdout;NativePS7StdoutSHA256=$(if(Test-Path $stdout){SHA $stdout}else{''})
 NativePS7Stderr=$stderr;NativePS7StderrSHA256=$(if(Test-Path $stderr){SHA $stderr}else{''})
 NativeShortMountWorkDirectory=$work;LiveVMFirstBoot='NOT_RUN'
 ImageResult=$(if($code -eq 0 -and $wimBytes -le 5500000000){'NATIVE_WIM_SCRIPT_EXIT0_OWNER_SIZE_GATE_PASSED_NEEDS_INDEPENDENT_IMAGE_QA'}else{'NATIVE_WIM_OR_SIZE_GATE_HOLD_NO_ISO_OR_VM_CERTIFICATION'})
}
SaveNewJson $out $result
Write-Host ('R054_OP04_REAL_WIM_NATIVE_CHILD_EXIT='+$code+' SECONDS='+$result.ElapsedSeconds+' FINAL_BYTES='+$wimBytes+' SIZE_LE_5500000000='+$result.WIMLessOrEqualTarget+' SCRIPTLOG_SHA='+$logSHA+' PRODUCER_SHA='+(SHA $out))
exit $code
