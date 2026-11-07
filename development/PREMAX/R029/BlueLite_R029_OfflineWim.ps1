# BlueLite R029 — native-DISM offline WIM servicing, SOURCE-BOUND and full UUP-root-local traces.
# Invoked by exact one-time stage converter hook. Never services host Windows or original Golden.
[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][string]$WimPath,
 [int]$Index=1,
 [string]$CapabilityPatternsFile='',
 [string]$FeatureDisableOnlyFile='',
 [string]$FeatureRemovePayloadFile='',
 [string]$PackagePatternsFile='',
 [string]$CustomAppsListPath='',
 [string]$ProfilePath='',
 [string]$ComponentWatchlistFile='',
 [string]$RequiredStagingAppIdentitiesFile='',
 [string]$RequiredFinalAppIdentitiesFile='',
 [string]$StagingOnlyAppPatternsFile='',
 [string]$ReleaseForbiddenAppPatternsFile='',
 [string]$OfflineHandoffPatternsFile='',
 [string]$ProtectedFloorFile='',
 [string]$ExpectedBuildFile='',
 [string]$WorkDirectory='.\BlueLite_FinalWim_Work',
 [string]$LogPath='.\BlueLite_Logs\FinalWimDebloat.log'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
function GateBL([bool]$yes,[string]$why){if(-not $yes){throw ('R029_OFFLINE_HOLD_'+$why)}}
function SHA([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()}
function WriteOnce([string]$p,$value) {
 $b=[Text.UTF8Encoding]::new($false).GetBytes(($value|ConvertTo-Json -Depth 15)+[Environment]::NewLine)
 $f=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$f.Write($b,0,$b.Length)}finally{$f.Dispose()}
}
function Trace([string]$message){$line='['+[DateTime]::UtcNow.ToString('o')+'] '+$message;Write-Host $line;[IO.File]::AppendAllText($script:tracePath,$line+[Environment]::NewLine,[Text.UTF8Encoding]::new($false))}
function NativeDism([string]$name,[string[]]$argv,[switch]$RequireHealthy){
 $script:seq++
 $safe=($name -replace '[^A-Za-z0-9_-]','_')
 $log=Join-Path $script:logs ('BlueLite_R029_DISM_{0:D3}_{1}.txt' -f $script:seq,$safe)
 Trace ('DISM_BEGIN '+$name+' '+($argv -join ' '))
 $lines=@(& dism.exe @argv 2>&1|ForEach-Object {$_.ToString()})
 $code=[int]$LASTEXITCODE
 $data=$lines -join [Environment]::NewLine
 [IO.File]::WriteAllText($log,$data+[Environment]::NewLine,[Text.UTF8Encoding]::new($false))
 Trace ('DISM_END '+$name+' exit='+$code+' stdout_bytes='+$data.Length+' '+$log)
 GateBL ($code -eq 0) ('DISM_'+$name+'_EXIT_'+$code+'_LOG_'+$log)
 if($RequireHealthy){GateBL ($data -match '(?i)No component store corruption detected') ('HEALTH_NOT_GREEN_'+$name)}
 return $data
}
function Patterns([string]$path) {
 if([string]::IsNullOrWhiteSpace($path)){return @()}
 GateBL (Test-Path -LiteralPath $path -PathType Leaf) ('PATTERN_FILE_NOT_FOUND_'+$path)
 return @((Get-Content -LiteralPath $path)|ForEach-Object {$_.Trim()}|Where-Object {$_ -and -not $_.StartsWith('#') -and -not $_.StartsWith(';')})
}
function CapRecords([string]$body) {
 $matches=[regex]::Matches($body,'(?ims)^\s*Capability Identity\s*:\s*(?<name>[^\r\n]+)\r?\n(?<attrs>.*?)(?=^\s*Capability Identity\s*:|\z)')
 GateBL ($matches.Count -ge 20) ('CAPABILITY_NATIVE_PARSE_COUNT_'+$matches.Count)
 $out=[Collections.Generic.List[object]]::new()
 foreach($m in $matches){$st=[regex]::Match($m.Groups['attrs'].Value,'(?im)^\s*State\s*:\s*(?<v>\S+)')
  GateBL $st.Success ('CAPABILITY_NO_STATE_'+$m.Groups['name'].Value)
  $out.Add([pscustomobject]@{Name=$m.Groups['name'].Value.Trim();State=$st.Groups['v'].Value.Trim()})
 }
 return @($out.ToArray())
}
function AppNames([string]$body) {
 $ms=[regex]::Matches($body,'(?im)^\s*DisplayName\s*:\s*([^\r\n]+)')
 GateBL ($ms.Count -gt 0 -and $ms.Count -le 400) ('APPX_NATIVE_PARSE_'+$ms.Count)
 return @($ms|ForEach-Object {$_.Groups[1].Value.Trim()})
}
function InstalledMatch($caps,[string]$rx){return @($caps|Where-Object {$_.State -eq 'Installed' -and $_.Name -match $rx})}
function RegValue([string]$key,[string]$value){
 $lines=@(& reg.exe query $key /v $value 2>&1|ForEach-Object{$_.ToString()});$code=$LASTEXITCODE
 GateBL ($code -eq 0) ('OFFLINE_HIVE_REG_QUERY_'+$value)
 $line=@($lines|Where-Object{$_ -match ('^\s*'+[regex]::Escape($value)+'\s+REG_\S+\s+(.+?)\s*$')})|Select-Object -First 1
 GateBL ($null -ne $line) ('OFFLINE_HIVE_VALUE_MISSING_'+$value)
 return ([regex]::Match([string]$line,('^\s*'+[regex]::Escape($value)+'\s+REG_\S+\s+(.+?)\s*$'))).Groups[1].Value
}
$wim=[IO.Path]::GetFullPath($WimPath)
$stage=[IO.Path]::GetDirectoryName([IO.Path]::GetDirectoryName([IO.Path]::GetDirectoryName($wim)))
$workParent=[IO.Path]::GetDirectoryName($stage)
$root=[IO.Path]::GetDirectoryName($workParent)
$logs=Join-Path $root 'BlueLite_Logs'
$tracePath=Join-Path $logs 'BlueLite_R029_OfflineTrace.log'
$result=Join-Path $logs 'BlueLite_R029_Offline_Result.json'
$mount=Join-Path $stage 'BlueLite_R029_Mount'
$compact=Join-Path $stage 'BlueLite_R029_install.compact.wim'
$backup=Join-Path $stage 'BlueLite_R029_install.precompact.wim'
$seq=0;$mounted=$false;$hiveLoaded=$false;$state='PRECONDITION'
$actualBuild='';$warn=[Collections.Generic.List[object]]::new();$removed=[Collections.Generic.List[string]]::new()
try{
 GateBL ($Index -eq 1) 'ONLY_SINGLE_INDEX_SUPPORTED'
 GateBL ($root.StartsWith('C:\work\',[StringComparison]::OrdinalIgnoreCase) -and $root -notmatch '\s') 'ROOT_OUTSIDE_C_WORK_OR_HAS_SPACES'
 GateBL (([IO.Path]::GetFileName($workParent)) -eq 'BlueLite_Work' -and ([IO.Path]::GetFileName($stage)) -match '^BlueLite_Stage_v11_3_26300_\d+_[a-f0-9]{8}_[a-f0-9]{8}$') 'UNOWNED_STAGE'
 GateBL ($wim -ieq (Join-Path $stage 'ISOFOLDER\sources\install.wim')) 'WIM_NOT_OWNED_SETUP'
 GateBL (Test-Path -LiteralPath $wim -PathType Leaf) 'INSTALL_WIM_NOT_FOUND'
 GateBL (Test-Path -LiteralPath $logs -PathType Container) 'ROOT_LOCAL_LOGS_MISSING'
 GateBL (-not(Test-Path -LiteralPath $result) -and -not(Test-Path -LiteralPath $tracePath) -and -not(Test-Path -LiteralPath $mount) -and -not(Test-Path -LiteralPath $compact)) 'PREVIOUS_STAGE_OFFLINE_ACTION_DETECTED'
 GateBL (-not(@(Get-WindowsImage -Mounted -ErrorAction Stop).Count)) 'WIM_ALREADY_MOUNTED'
 foreach($p in @($stage,$wim,$logs)){GateBL (([IO.File]::GetAttributes($p) -band [IO.FileAttributes]::ReparsePoint) -eq 0) ('REPARSE_'+$p)}
 $profile=@{};foreach($line in Patterns $ProfilePath){if($line -match '^\s*([^=]+)\s*=\s*(.*?)\s*$'){$profile[$Matches[1].Trim()]=$Matches[2].Trim()}}
 $sourceFull='';$sourceFamily='26300'
 if($ExpectedBuildFile -and (Test-Path $ExpectedBuildFile)){
  $sourceMeta=Get-Content -LiteralPath $ExpectedBuildFile -Raw -Encoding UTF8|ConvertFrom-Json
  $sourceFull=[string]$sourceMeta.UUP_BUILD
  if($sourceMeta.BUILD_FAMILY){$sourceFamily=[string]$sourceMeta.BUILD_FAMILY}
 }
 GateBL ($sourceFamily -eq '26300') 'SOURCE_NOT_GERMANIUM'
 $list=NativeDism 'WimInfo_before' @('/English','/Get-WimInfo',"/WimFile:$wim",'/Index:1')
 GateBL ($list -match '(?im)^\s*Version\s*:\s*10\.0\.26300\s*$' -and $list -match '(?im)^\s*Edition\s*:\s*Professional\s*$' -and $list -match '(?im)^\s*Architecture\s*:\s*x64\s*$') 'SOURCE_WIMINFO_MISMATCH'
 Trace ('R029_PRE_MOUNT_SOURCE_SHA256 '+(SHA $wim))
 $state='MOUNT'
 [void][IO.Directory]::CreateDirectory($mount)
 $null=NativeDism 'Mount' @('/English','/Mount-Image',"/ImageFile:$wim",'/Index:1',"/MountDir:$mount",'/CheckIntegrity')
 $mounted=$true
 GateBL (Test-Path -LiteralPath (Join-Path $mount 'Windows\System32\Config\SOFTWARE') -PathType Leaf) 'OFFLINE_SOFTWARE_MISSING'
 $soft=Join-Path $mount 'Windows\System32\Config\SOFTWARE'
 $hiveKey='HKLM\BlueLiteR029SOFTWARE'
 $out=@(& reg.exe load $hiveKey $soft 2>&1|ForEach-Object {$_.ToString()})
 GateBL ($LASTEXITCODE -eq 0) ('REG_LOAD_FAIL_'+($out -join ' '))
 $hiveLoaded=$true
 try{
  $cv=$hiveKey+'\Microsoft\Windows NT\CurrentVersion'
  $build=RegValue $cv 'CurrentBuildNumber'
  $raw=RegValue $cv 'UBR'
  $ubr=if($raw -match '^0x([0-9a-f]+)$'){[Convert]::ToInt32($Matches[1],16)}else{[int]$raw}
  $actualBuild=$build+'.'+$ubr
  GateBL ($build -eq '26300') ('UNEXPECTED_BUILD_FAMILY_'+$build)
  if($sourceFull){GateBL ($sourceFull -eq $actualBuild) ('SOURCE_BUILD_UUID_MISMATCH_'+$sourceFull+'_vs_'+$actualBuild)}
  Trace ('OFFLINE_IDENTITY_PASS '+$actualBuild)
 }finally{
  [GC]::Collect();[GC]::WaitForPendingFinalizers()
  $u=@(& reg.exe unload $hiveKey 2>&1|ForEach-Object {$_.ToString()})
  GateBL ($LASTEXITCODE -eq 0) ('REG_UNLOAD_HOLD_'+($u -join ' '))
  $hiveLoaded=$false
 }
 $state='INVENTORY_NATIVE'
 # Each native DISM query writes a numbered local log BEFORE any mutation.
 $beforeCaps=CapRecords (NativeDism 'BeforeCapabilities' @('/English',"/Image:$mount",'/Get-Capabilities'))
 $beforeApps=AppNames (NativeDism 'BeforeProvisionedApps' @('/English',"/Image:$mount",'/Get-ProvisionedAppxPackages'))
 $pkgs=NativeDism 'BeforePackages' @('/English',"/Image:$mount",'/Get-Packages')
 GateBL ($pkgs -match '(?im)^\s*Package Identity\s*:') 'PACKAGE_NATIVE_PARSE'
 GateBL ($pkgs -notmatch '(?im)^\s*State\s*:\s*Install Pending') 'PENDING_CBS_INSTALL'
 $features=NativeDism 'BeforeFeatures' @('/English',"/Image:$mount",'/Get-Features')
 GateBL ($features -match '(?im)^\s*Feature Name\s*:') 'FEATURE_NATIVE_PARSE'
 $required=Patterns $RequiredStagingAppIdentitiesFile
 foreach($app in $required){GateBL (@($beforeApps|Where-Object {$_ -like ('*'+$app+'*')}).Count -gt 0) ('REQUIRED_APP_MISSING_'+$app)}
 $protected=Patterns $ProtectedFloorFile
 foreach($f in $protected){GateBL (Test-Path (Join-Path $mount $f) -PathType Leaf) ('NETWORK_STORAGE_PROTECTED_FLOOR_'+$f)}
 $null=NativeDism 'InitialCheckHealth' @('/English',"/Image:$mount",'/Cleanup-Image','/CheckHealth') -RequireHealthy
 $state='OFFLINE_CAPABILITIES'
 $capRules=Patterns $CapabilityPatternsFile
 $rxNic='^Microsoft\.Windows\.(?:Wifi|Ethernet)\.Client\.'
 $rxSense='^Microsoft\.Windows\.Sense\.Client'
 $targets=@($beforeCaps|Where-Object{
   if($_.State -ne 'Installed'){return $false}
   if($_.Name -like 'Language.Basic~~~en-US~*'){return $false}
   if($_.Name -match $rxNic -or $_.Name -match $rxSense){return $true}
   foreach($pat in $capRules){if($_.Name.IndexOf($pat,[StringComparison]::OrdinalIgnoreCase) -ge 0){return $true}}
   return $false
 })
 Trace ('CAPABILITY_TARGETS_INSTALLED='+$targets.Count+' NIC='+@(InstalledMatch $beforeCaps $rxNic).Count+' SENSE='+@(InstalledMatch $beforeCaps $rxSense).Count)
 foreach($target in $targets){
  $name=[string]$target.Name
  if($name -match '(?i)Defender|SecHealthUI|Language\.Basic|ServicingStack|WindowsUpdate'){throw ('PROTECTED_CAPABILITY_TARGET_'+$name)}
  try{
   $null=NativeDism ('RemoveCapability_'+$removed.Count) @('/English',"/Image:$mount",'/Remove-Capability',"/CapabilityName:$name")
   $removed.Add($name)
  }catch{
   $warn.Add([pscustomobject]@{class='CAPABILITY_DEPENDENCY';name=$name;reason=$_.Exception.Message})
   Trace ('CAPABILITY_DEPENDENCY_HOLD '+$name+' '+$_.Exception.Message)
  }
 }
 $state='FEATURE_TRIM'
 $featureRemove=Patterns $FeatureRemovePayloadFile
 $featureDisable=Patterns $FeatureDisableOnlyFile
 foreach($name in @($featureRemove+$featureDisable|Sort-Object -Unique)){
  if($name -match '(?i)Defender|WindowsUpdate|Servicing|NetFx|NetTCP|VirtualMachinePlatform|Hyper-V|Storage'){continue}
  if($features -notmatch ('(?im)^\s*Feature Name\s*:\s*'+[regex]::Escape($name)+'\s*$')){continue}
  $argv=@('/English',"/Image:$mount",'/Disable-Feature',"/FeatureName:$name",'/NoRestart')
  if($featureRemove -contains $name){$argv+=('/Remove')}
  try{$null=NativeDism ('DisableFeature_'+$name) $argv}catch{
   $warn.Add([pscustomobject]@{class='FEATURE_DEPENDENCY';name=$name;reason=$_.Exception.Message})
  }
 }
 $state='APPX_DEPENDENCY'
 # Do not hallucinate AppInstaller removed; verify native post-inventory and label RELEASE_HOLD if present.
 # Package-level CBS and AppRepository hardlink surgeries are prohibited.
 $state='COMPONENT_CLEANUP'
 $null=NativeDism 'StartComponentCleanup' @('/English',"/Image:$mount",'/Cleanup-Image','/StartComponentCleanup')
 $null=NativeDism 'FinalCheckHealth' @('/English',"/Image:$mount",'/Cleanup-Image','/CheckHealth') -RequireHealthy
 $state='AFTER_INVENTORY'
 $afterCaps=CapRecords (NativeDism 'AfterCapabilities' @('/English',"/Image:$mount",'/Get-Capabilities'))
 $afterApps=AppNames (NativeDism 'AfterProvisionedApps' @('/English',"/Image:$mount",'/Get-ProvisionedAppxPackages'))
 $afterPkgs=NativeDism 'AfterPackages' @('/English',"/Image:$mount",'/Get-Packages')
 GateBL ($afterPkgs -notmatch '(?im)^\s*State\s*:\s*Install Pending') 'CBS_PENDING_AFTER'
 $lastRequired=Patterns $RequiredFinalAppIdentitiesFile
 foreach($app in $lastRequired){GateBL (@($afterApps|Where-Object {$_ -like ('*'+$app+'*')}).Count -gt 0) ('FINAL_REQUIRED_APP_MISSING_'+$app)}
 $leftNIC=@(InstalledMatch $afterCaps $rxNic)
 $leftSense=@(InstalledMatch $afterCaps $rxSense)
 $forbidden=Patterns $ReleaseForbiddenAppPatternsFile
 foreach($app in $afterApps){foreach($pat in $forbidden){if($app.IndexOf($pat,[StringComparison]::OrdinalIgnoreCase) -ge 0){
  $warn.Add([pscustomobject]@{class='FORBIDDEN_APP_REMAINS';name=$app;reason='F01/owner dependency not resolved'})
 }}}
 if($leftNIC.Count -gt 0){$warn.Add([pscustomobject]@{class='NIC_FOD_REMAINS';count=$leftNIC.Count;names=@($leftNIC|ForEach-Object{$_.Name})})}
 if($leftSense.Count -gt 0){$warn.Add([pscustomobject]@{class='SENSE_FOD_REMAINS';count=$leftSense.Count;names=@($leftSense|ForEach-Object{$_.Name})})}
 $basic=@($afterCaps|Where-Object {$_.State -eq 'Installed' -and $_.Name -like 'Language.Basic~~~en-US~*'})
 Trace ('INSTALLED_NIC_AFTER='+$leftNIC.Count+' SENSE_AFTER='+$leftSense.Count+' BASIC_PROTECTED='+$basic.Count+' APP_DEPENDENCIES='+$warn.Count)
 $state='COMMIT'
 $null=NativeDism 'UnmountCommit' @('/English','/Unmount-Image',"/MountDir:$mount",'/Commit')
 $mounted=$false
 $state='EXPORT'
 GateBL (-not(Test-Path -LiteralPath $compact) -and -not(Test-Path -LiteralPath $backup)) 'EXPORT_OUTPUT_ALREADY_EXISTS'
 $null=NativeDism 'ExportCompact' @('/English','/Export-Image',"/SourceImageFile:$wim",'/SourceIndex:1',"/DestinationImageFile:$compact",'/Compress:max','/CheckIntegrity')
 GateBL ((Get-Item -LiteralPath $compact).Length -gt 2000000000L) 'COMPACT_WIM_UNEXPECTEDLY_SMALL'
 $info=NativeDism 'WimInfo_after' @('/English','/Get-WimInfo',"/WimFile:$compact",'/Index:1')
 GateBL ($info -match '(?im)^\s*Version\s*:\s*10\.0\.26300\s*$' -and $info -match '(?im)^\s*Edition\s*:\s*Professional\s*$' -and $info -match '(?im)^\s*Architecture\s*:\s*x64\s*$') 'WIMINFO_POST_EXPORT_BUILD_FAMILY_EDITION_ARCH'
 $compactSha=SHA $compact
 $originalSha=SHA $wim
 $state='PROMOTION'
 [IO.File]::Move($wim,$backup)
 try{[IO.File]::Move($compact,$wim)}catch{[IO.File]::Move($backup,$wim);throw}
 GateBL ((SHA $wim) -eq $compactSha) 'PROMOTED_WIM_SHA_MISMATCH'
 $state='CANDIDATE_WIM_PRODUCED'
 $status=if($warn.Count -eq 0){'CANDIDATE_OFFLINE_COMPLETE_NOT_RELEASE_CERTIFIED'}else{'CANDIDATE_OFFLINE_COMPLETE_DEPENDENCY_HOLDS'}
 WriteOnce $result ([ordered]@{schema='BlueLite.R029.OfflineNativeDISM.v1';utc=[DateTime]::UtcNow.ToString('o');status=$status;build=$actualBuild;source_wim_sha256=$originalSha;promoted_wim_sha256=$compactSha;promoted_wim_bytes=(Get-Item $wim).Length;mounted_wim=$false;installed_driver_fod_before=@(InstalledMatch $beforeCaps $rxNic).Count;installed_driver_fod_after=$leftNIC.Count;installed_sense_before=@(InstalledMatch $beforeCaps $rxSense).Count;installed_sense_after=$leftSense.Count;removed_capabilities=@($removed.ToArray());warnings=@($warn.ToArray());appinstaller_provisioned_after=@($afterApps|Where-Object{$_ -like '*DesktopAppInstaller*'});basic_en_us_kept=$basic.Count;release_certified=$false;one_next='SETUP_BOOT_AND_ISO_CAPTURE'})
 Trace ('OFFLINE_WIM_PROMOTED '+$status+' BYTES='+((Get-Item $wim).Length)+' SHA256='+$compactSha)
 exit 0
}catch{
 $errorText=$_.Exception.ToString()
 try{if(Test-Path $logs){Trace ('OFFLINE_HOLD_AT_'+$state+' '+$errorText)}}catch{}
 if($hiveLoaded){try{& reg.exe unload 'HKLM\BlueLiteR029SOFTWARE'|Out-Null}catch{}}
 if($mounted){try{$null=NativeDism 'UnmountDiscardOnHold' @('/English','/Unmount-Image',"/MountDir:$mount",'/Discard')}catch{}}
 try{if((Test-Path -LiteralPath $logs) -and -not(Test-Path -LiteralPath $result)){WriteOnce $result ([ordered]@{status='HOLD';phase=$state;reason=$errorText;mounted_wim=$mounted;release_certified=$false;one_next='DO_NOT_RETRY_PRESERVE_STAGE_AND_RETURN_EVIDENCE'})}}catch{}
 Write-Host ('R029_OFFLINE_HOLD_AT_'+$state+' '+$errorText)
 exit 17
}
