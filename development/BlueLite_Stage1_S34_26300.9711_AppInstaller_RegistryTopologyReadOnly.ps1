& {
 Set-StrictMode -Version Latest
 $ErrorActionPreference='Stop'
 $PSNativeCommandUseErrorActionPreference=$false
 $wim='C:\work\E2E\BlueLite_Stage1_S31_26300.9711_OneDriveAMBER\install.wim'
 $wimSHA='F52389FA66F8B60D56661C8786EC99409FB95447403B3C6FCBB94121EF8E340B'
 $s33='C:\work\logs\BlueLite_Stage1_S33_26300.9711_AppInstaller_NativeOwnerGate.txt'
 $s32='C:\work\logs\BlueLite_Stage1_S32_26300.9711_AppInstaller_ReadOnlyGate.txt'
 $mount='C:\BL34M'
 $work='C:\work\logs\BlueLite_Stage1_S34_26300.9711_RegistryAudit'
 $report='C:\work\logs\BlueLite_Stage1_S34_26300.9711_AppInstaller_RegistryTopologyReadOnly.txt'
 $snapshot='C:\work\logs\BlueLite_Stage1_S34_26300.9711_AppInstaller_RegistrySnapshot.json'
 $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
 $reg=Join-Path $env:SystemRoot 'System32\reg.exe'
 $shadow=Join-Path $work 'SOFTWARE_readonly_evidence_copy.bin'
 $alias="BL34_$PID"
 $hive="HKLM\$alias"
 $prefix='Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore'
 $family='Microsoft.DesktopAppInstaller_8wekyb3d8bbwe'
 $bundle='Microsoft.DesktopAppInstaller_2024.401.617.0_neutral_~_8wekyb3d8bbwe'
 $expectedStaged=@(
  'Microsoft.DesktopAppInstaller_1.21.10121.0_neutral_split.scale-100_8wekyb3d8bbwe',
  'Microsoft.DesktopAppInstaller_1.21.10121.0_neutral_split.scale-125_8wekyb3d8bbwe',
  'Microsoft.DesktopAppInstaller_1.21.10121.0_x64__8wekyb3d8bbwe',
  'Microsoft.DesktopAppInstaller_2024.401.617.0_neutral_~_8wekyb3d8bbwe',
  'Microsoft.UI.Xaml.2.8_8.2310.30001.0_x64__8wekyb3d8bbwe',
  'Microsoft.VCLibs.140.00.UWPDesktop_14.0.30704.0_x64__8wekyb3d8bbwe'
 )
 $desiredApps=@(
  'Microsoft.DesktopAppInstaller','Microsoft.SecHealthUI',
  'Microsoft.WindowsCalculator','Microsoft.WindowsNotepad','Microsoft.Windows.Photos',
  'Microsoft.NET.Native.Framework.2.2','Microsoft.NET.Native.Runtime.2.2',
  'Microsoft.UI.Xaml.2.8','Microsoft.VCLibs.140.00',
  'Microsoft.VCLibs.140.00.UWPDesktop'
 )
 $utf8=[Text.UTF8Encoding]::new($false)
 $loaded=$false;$mounted=$false;$released=$false;$sourceOK=$false;$gate=$false
 $result='HOLD_S34_APPINSTALLER_REGISTRY_TOPOLOGY_READONLY'
 $rows=[System.Collections.Generic.List[object]]::new()
 $win=[Security.Principal.WindowsPrincipal]::new(
  [Security.Principal.WindowsIdentity]::GetCurrent()
 )
 if($PSVersionTable.PSVersion.Major -ne 7 -or
    -not $win.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
  throw 'PS7_ADMIN_REQUIRED'
 }
 if(-not(Test-Path -LiteralPath 'C:\work\logs' -PathType Container)){
  throw 'LOGS_ROOT_MISSING'
 }
 foreach($p in @($mount,$work,$report,$snapshot)){
  if(Test-Path -LiteralPath $p){throw "S34_PREEXISTING_OUTPUT=$p"}
 }
 [IO.File]::WriteAllText($report,'',$utf8)
 function Note([string]$v){
  $line="$(Get-Date -Format 'HH:mm:ss') | $v"
  Write-Host $line
  [IO.File]::AppendAllText($report,$line+[Environment]::NewLine,$utf8)
 }
 function Pin([string]$label,[string]$p,[string]$sha){
  if(-not [IO.File]::Exists($p)){throw "PIN_MISSING=$label"}
  $got=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash
  if($got -cne $sha){throw "PIN_MISMATCH=$label;$got"}
  Note "PIN_$label=PASS"
 }
 function MountTable{
  $out=@(& $dism /English /Get-MountedWimInfo 2>&1 |
   ForEach-Object {[string]$_})
  if($LASTEXITCODE -ne 0){throw 'DISM_TABLE_FAILED'}
  return $out
 }
 function Ours([string[]]$out){
  foreach($line in $out){
   $m=[regex]::Match($line,'^\s*Mount Dir\s*:\s*(.*?)\s*$')
   if($m.Success -and $m.Groups[1].Value.Trim() -ieq $mount){return $true}
  }
  return $false
 }
 function Dism([string]$label,[string[]]$arguments){
  $out=@(& $dism @arguments 2>&1 | ForEach-Object {[string]$_})
  $ec=[int]$LASTEXITCODE
  Note "DISM_$($label)_EXIT=$ec"
  if($ec -ne 0){throw "DISM_$($label)_FAILED=$ec;$($out -join ' | ')"}
  return ($out -join [Environment]::NewLine)
 }
 function ReadKey([string]$label,[string]$relative){
  $path="$alias\$relative"
  $key=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($path,$false)
  $names=@();$values=@()
  if($null -ne $key){
   try{
    $names=@($key.GetSubKeyNames() | Sort-Object)
    $values=@($key.GetValueNames() | Sort-Object)
   }finally{$key.Dispose()}
  }
  $entry=[pscustomobject]@{
   Label=$label
   RelativePath=$relative
   Exists=($null -ne $key)
   Children=[string[]]$names
   ValueNames=[string[]]$values
  }
  $rows.Add($entry)
  Note "REG=$label;EXISTS=$($entry.Exists);CHILDREN=$($names.Count);VALUES=$($values.Count)"
  return $entry
 }
 function RequireScope([object]$entry,[bool]$expected){
  if([bool]$entry.Exists -ne $expected){throw "REG_SCOPE_DRIFT=$($entry.Label);EXPECTED=$expected"}
 }
 function UnloadCopy{
  if(-not $loaded){return}
  [GC]::Collect()
  [GC]::WaitForPendingFinalizers()
  $lines=@(& $reg unload $hive 2>&1 | ForEach-Object {[string]$_})
  $ec=[int]$LASTEXITCODE
  Note "COPIED_SOFTWARE_UNLOAD_EXIT=$ec"
  if($ec -ne 0){throw "COPIED_SOFTWARE_UNLOAD_FAILED=$ec;$($lines -join ' | ')"}
 }

 try{
  Note 'STAGE=S34_26300_9711_APPINSTALLER_REGISTRY_PRESTATE'
  Note 'MODE=READONLY_WIM_COPIED_SOFTWARE_READONLY_REGISTRY_API'
  Note '[1/6] VERIFY S33 S32 AND CURRENT S31 WIM'
  Pin 'S33_REPORT' $s33 'FDA524744AB0626DD7155DDA71490B365ED3C51E6770C1884470ADF4565A69BA'
  Pin 'S32_REPORT' $s32 '0F8501CAE72CEDBE7450E0F4025F6E6E22C3564EBEC3751E03149BB6A750D5E2'
  foreach($anchor in @('RESULT=PASS_S33_9711_READONLY_APPINSTALLER_NATIVE_OWNER_740',
     'OWNER_QUERIES=740;OWNER_ANOMALIES=0',
     'S31_WIM_SHA256_UNCHANGED=True')){
   if(-not [IO.File]::ReadAllText($s33).Contains($anchor)){
    throw "S33_PROOF_MISSING=$anchor"
   }
  }
  if(-not [IO.File]::Exists($wim) -or (Get-Item -LiteralPath $wim).Length -ne 6509216853L){
   throw 'SOURCE_WIM_SIZE_DRIFT'
  }
  Pin 'S31_WIM' $wim $wimSHA
  $before=@(MountTable)
  if(@($before | Where-Object {$_ -match '^\s*Mount Dir\s*:'}).Count -ne 0){
   throw 'EXISTING_MOUNT_NO_ACTION'
  }
  $exists=@(& $reg query $hive 2>&1)
  if($LASTEXITCODE -eq 0){throw 'S34_HIVE_ALIAS_ALREADY_PRESENT'}
  Note '[2/6] SHORT READONLY WIM MOUNT'
  $null=New-Item -ItemType Directory -Path $mount
  $null=Dism 'MOUNT' @('/English','/Mount-Image',"/ImageFile:$wim",
    '/Index:1',"/MountDir:$mount",'/ReadOnly')
  $fields=@{}
  foreach($line in @(MountTable)){
   $m=[regex]::Match([string]$line,
    '^\s*(Mount Dir|Image File|Image Index|Mounted Read/Write|Status)\s*:\s*(.*?)\s*$')
   if($m.Success){
    $key=$m.Groups[1].Value
    if($fields.ContainsKey($key)){throw 'MOUNT_FIELD_DUPLICATE'}
    $fields[$key]=$m.Groups[2].Value.Trim()
   }
  }
  if($fields.Count -ne 5 -or $fields['Mount Dir'] -ine $mount -or
    $fields['Image File'] -ine $wim -or $fields['Image Index'] -ne '1' -or
    $fields['Mounted Read/Write'] -ine 'No' -or $fields['Status'] -ine 'Ok'){
   throw 'RO_MOUNT_OWNER_NOT_PROVEN'
  }
  $mounted=$true
  Note 'MOUNT_OWNER_READONLY=PASS_5_FIELDS'
  Note '[3/6] APPX PROVISIONED TEN AND COPY OFFLINE SOFTWARE'
  $appx=Dism 'APPX' @('/English',"/Image:$mount",'/Get-ProvisionedAppxPackages')
  $names=@([regex]::Matches($appx,'(?im)^\s*DisplayName\s*:\s*(\S+)\s*$') |
     ForEach-Object {$_.Groups[1].Value})
  if($names.Count -ne 10){throw "APPX_COUNT_NOT_TEN=$($names.Count)"}
  foreach($app in $desiredApps){
   if(@($names | Where-Object {$_ -ceq $app}).Count -ne 1){
    throw "STAGING_OR_FRAMEWORK_MISSING=$app"
   }
  }
  if(@($names | Where-Object {$desiredApps -cnotcontains $_}).Count -ne 0){
   throw "UNKNOWN_PROVISIONED_APPX=$($names -join ';')"
  }
  Note 'FIVE_STAGING_PLUS_FIVE_FRAMEWORKS=PASS_10'
  $software=Join-Path $mount 'Windows\System32\config\SOFTWARE'
  $null=New-Item -ItemType Directory -Path $work
  Copy-Item -LiteralPath $software -Destination $shadow -ErrorAction Stop
  if((Get-Item -LiteralPath $shadow).Length -lt 1MB){throw 'COPIED_SOFTWARE_SIZE_TOO_SMALL'}
  $shadowSHA=(Get-FileHash -LiteralPath $shadow -Algorithm SHA256).Hash
  Note "OFFLINE_SOFTWARE_COPY_SHA256=$shadowSHA"
  $out=@(& $reg load $hive $shadow 2>&1 | ForEach-Object {[string]$_})
  $ec=[int]$LASTEXITCODE
  Note "COPY_REG_LOAD_EXIT=$ec"
  if($ec -ne 0){throw "OFFLINE_HIVE_COPY_LOAD_FAILED=$ec;$($out -join ' | ')"}
  $loaded=$true
  Note '[4/6] TARGET-ONLY OFFLINE REGISTRY API TOPOLOGY'
  $apps=ReadKey 'APPLICATIONS' "$prefix\Applications\$bundle"
  $cfg=ReadKey 'CONFIG' "$prefix\Config\$family"
  $stage=ReadKey 'STAGED' "$prefix\Staged\$family"
  $wow=ReadKey 'WOW_CONFIG' "WOW6432Node\$prefix\Config\$family"
  $broad=ReadKey 'BROAD_FS' "Microsoft\Windows\CurrentVersion\CapabilityAccessManager\Capabilities\broadFilesystemAccess\Apps\$family"
  $deprov=ReadKey 'DEPROVISIONED' "$prefix\Deprovisioned\$family"
  foreach($entry in @($apps,$cfg,$stage,$wow,$broad)){
   RequireScope $entry $true
  }
  RequireScope $deprov $false
  $children=@($stage.Children)
  $unexpected=@($children | Where-Object {$expectedStaged -cnotcontains $_})
  $missing=@($expectedStaged | Where-Object {$children -cnotcontains $_})
  foreach($child in $children){Note "STAGED_CHILD=$child"}
  if($children.Count -ne 6 -or $unexpected.Count -gt 0 -or $missing.Count -gt 0){
   throw "STAGED_SIX_CHILD_VARIANT_DRIFT=ACTUAL_$($children.Count);MISSING_$($missing -join ';');EXTRA_$($unexpected -join ';')"
  }
  Note 'APPINSTALLER_STAGED=PASS_4_OWN_2_PROVIDER_ASSOCIATIONS'
  Note 'PROTECTED_PROVIDER_OWN_KEYS=NOT_MODIFIED'
  Note 'APPX_REGISTRY_PRESTATE=PASS_EXACT_TARGET_SCOPES'
  $gate=$true
 }catch{
  Note "ERROR=$($_.Exception.Message)"
 }finally{
  Note '[5/6] SNAPSHOT, HIVE UNLOAD, WIM DISCARD'
  try{
   $data=[pscustomobject]@{
    Stage='S34';ResultScope='READONLY_OFFLINE_COPY'
    WIM=$wim;WimSHA256=$wimSHA
    SourceS33SHA256='FDA524744AB0626DD7155DDA71490B365ED3C51E6770C1884470ADF4565A69BA'
    CopiedSoftwarePath=$shadow
    RegistryScopes=@($rows.ToArray())
    ExpectedStagedChildren=$expectedStaged
   }
   $json=$data | ConvertTo-Json -Depth 8
   [IO.File]::WriteAllText($snapshot,$json,$utf8)
   Note "REGISTRY_SNAPSHOT=$snapshot"
  }catch{Note "SNAPSHOT_ERROR=$($_.Exception.Message)";$gate=$false}
  try{
   if($loaded){UnloadCopy; $loaded=$false}
  }catch{Note "HIVE_UNLOAD_ERROR=$($_.Exception.Message)";$gate=$false}
  try{
   if(-not $loaded -and [IO.File]::Exists($shadow)){
    Remove-Item -LiteralPath $shadow -Force -ErrorAction Stop
    Note 'DISPOSABLE_HIVE_COPY_REMOVED=PASS'
   }
  }catch{Note "SHADOW_DELETE_ERROR=$($_.Exception.Message)"}
  try{
   if(-not $loaded -and (Ours @(MountTable))){
    $null=Dism 'DISCARD' @('/English','/Unmount-Image',"/MountDir:$mount",'/Discard')
    Note 'READONLY_DISCARD=PASS'
   }
   $released= -not(Ours @(MountTable))
   Note "OWNED_MOUNT_RELEASED=$released"
  }catch{Note "FINAL_MOUNT_ERROR=$($_.Exception.Message)"}
  Note '[6/6] VERIFY SOURCE UNCHANGED AND TERMINAL'
  try{
   if($released -and [IO.File]::Exists($wim) -and
     (Get-Item -LiteralPath $wim).Length -eq 6509216853L){
    $sourceOK=((Get-FileHash -LiteralPath $wim -Algorithm SHA256).Hash -ceq $wimSHA)
   }
  }catch{Note "SOURCE_FINAL_HASH_ERROR=$($_.Exception.Message)"}
  Note "S31_WIM_SHA256_UNCHANGED=$sourceOK"
  if($gate -and -not $loaded -and $released -and $sourceOK){
   $result='PASS_S34_9711_APPINSTALLER_REGISTRY_PRESTATE_READONLY'
  }
  Note 'NO_OFFLINE_WIM_REGISTRY_OR_APPX_MUTATION=TRUE'
  Note 'APPINSTALLER_R133_MUTATION_AUTHORITY=NOT_GRANTED'
  Note "RESULT=$result"
  Write-Host "MAIN_LOG=$report"
  Write-Host "REGISTRY_JSON=$snapshot"
 }
}
