& {
 Set-StrictMode -Version Latest
 $ErrorActionPreference='Stop'
 $PSNativeCommandUseErrorActionPreference=$false
 $wim='C:\work\E2E\BlueLite_Stage1_S31_26300.9711_OneDriveAMBER\install.wim'
 $wimSHA='F52389FA66F8B60D56661C8786EC99409FB95447403B3C6FCBB94121EF8E340B'
 $s34Log='C:\work\logs\BlueLite_Stage1_S34_26300.9711_AppInstaller_RegistryTopologyReadOnly.txt'
 $s34Json='C:\work\logs\BlueLite_Stage1_S34_26300.9711_AppInstaller_RegistrySnapshot.json'
 $s33Log='C:\work\logs\BlueLite_Stage1_S33_26300.9711_AppInstaller_NativeOwnerGate.txt'
 $mount='C:\BL35M'
 $evidence='C:\work\logs\BlueLite_Stage1_S35_26300.9711_Audit'
 $report='C:\work\logs\BlueLite_Stage1_S35_26300.9711_AppInstaller_ProviderTopologyReadOnly.txt'
 $snapshot='C:\work\logs\BlueLite_Stage1_S35_26300.9711_AppInstaller_ProviderSnapshot.json'
 $shadow=Join-Path $evidence 'SOFTWARE_disposable_copy.bin'
 $hive="HKLM\BL35SOFT_$PID"
 $alias="BL35SOFT_$PID"
 $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
 $reg=Join-Path $env:SystemRoot 'System32\reg.exe'
 $utf8=[Text.UTF8Encoding]::new($false)
 $family='Microsoft.DesktopAppInstaller_8wekyb3d8bbwe'
 $stagedPrefix='Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Staged'
 $cfgPrefix='Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Config'
 $providerFamilies=@(
   'Microsoft.UI.Xaml.2.8_8wekyb3d8bbwe',
   'Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe'
 )
 $providerNames=@('Microsoft.UI.Xaml.2.8','Microsoft.VCLibs.140.00.UWPDesktop')
 $ownRoots=@(
   'Microsoft.DesktopAppInstaller_1.21.10121.0_neutral_split.scale-100_8wekyb3d8bbwe',
   'Microsoft.DesktopAppInstaller_1.21.10121.0_neutral_split.scale-125_8wekyb3d8bbwe',
   'Microsoft.DesktopAppInstaller_1.21.10121.0_x64__8wekyb3d8bbwe',
   'Microsoft.DesktopAppInstaller_2024.401.617.0_neutral_~_8wekyb3d8bbwe'
 )
 $seenKeys=[System.Collections.Generic.List[object]]::new()
 $manifestDeps=[System.Collections.Generic.List[object]]::new()
 $providers=@()
 $loaded=$false;$mounted=$false;$released=$false;$sourceOK=$false;$complete=$false
 $result='HOLD_S35_APPINSTALLER_PROVIDER_DISCOVERY_READONLY'
 $administrator=[Security.Principal.WindowsPrincipal]::new(
  [Security.Principal.WindowsIdentity]::GetCurrent()
 ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
 if($PSVersionTable.PSVersion.Major -ne 7 -or -not $administrator){throw 'PS7_ADMIN_REQUIRED'}
 if(-not(Test-Path -LiteralPath 'C:\work\logs' -PathType Container)){throw 'BLUELITE_LOG_DIR_MISSING'}
 foreach($p in @($mount,$evidence,$report,$snapshot)){
  if(Test-Path -LiteralPath $p){throw "OWNED_S35_PATH_ALREADY_EXISTS=$p"}
 }
 [IO.File]::WriteAllText($report,'',$utf8)
 function Note([string]$value){
  $line=(Get-Date -Format 'HH:mm:ss')+' | '+$value
  Write-Host $line
  [IO.File]::AppendAllText($report,$line+[Environment]::NewLine,$utf8)
 }
 function Pin([string]$tag,[string]$file,[string]$expected){
  if(-not [IO.File]::Exists($file)){throw "PIN_MISSING=$tag"}
  $actual=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
  if($actual -cne $expected){throw "PIN_DRIFT=$tag;$actual"}
  Note "PIN_$tag=PASS"
 }
 function MountTable{
  $lines=@(& $dism /English /Get-MountedWimInfo 2>&1 | ForEach-Object {[string]$_})
  if($LASTEXITCODE -ne 0){throw 'DISM_MOUNT_TABLE_FAILED'}
  return $lines
 }
 function Owned([string[]]$lines){
  foreach($line in $lines){
   $m=[regex]::Match($line,'^\s*Mount Dir\s*:\s*(.*?)\s*$')
   if($m.Success -and $m.Groups[1].Value.Trim() -ieq $mount){return $true}
  }
  return $false
 }
 function NativeDism([string]$name,[string[]]$arguments){
  $lines=@(& $dism @arguments 2>&1 | ForEach-Object {[string]$_})
  $exit=[int]$LASTEXITCODE
  Note "DISM_$($name)_EXIT=$exit"
  if($exit -ne 0){throw "DISM_$($name)_FAILED=$exit;$($lines -join ' | ')"}
  return ($lines -join [Environment]::NewLine)
 }
 function ReadKey([string]$label,[string]$relative){
  $key=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("$alias\$relative",$false)
  [string[]]$children=@()
  [string[]]$values=@()
  $exists=$null -ne $key
  if($exists){
   try{
    $children=@($key.GetSubKeyNames() | Sort-Object)
    $values=@($key.GetValueNames() | Sort-Object)
   }finally{$key.Dispose()}
  }
  $row=[pscustomobject]@{Name=$label;RelativePath=$relative;Exists=$exists;
    Children=[string[]]$children;ValueNames=[string[]]$values}
  $seenKeys.Add($row)
  Note "REG=$label;EXISTS=$exists;CHILDREN=$($children.Count);VALUES=$($values.Count)"
  foreach($ch in $children){Note "CHILD=$label;$ch"}
  return $row
 }
 try{
  Note 'STAGE=S35_26300_9711_APPINSTALLER_PROVIDER_DISCOVERY'
  Note 'MODE=READONLY_WIM_AND_COPIED_OFFLINE_SOFTWARE'
  Note '[1/6] S34 HOLD, S33 PASS, WIM EXACT PIN'
  Pin 'S34_LOG' $s34Log '09B30C9308BEC3371AF11180476E4A4F73D7A1C7F3B42E48E0962BB19F85980B'
  Pin 'S34_JSON' $s34Json 'CD08E2CAD6AF97B2E9DD4BAFBEE28582F366C9B8FCE9AA3F15522C529AA6E0AF'
  Pin 'S33_LOG' $s33Log 'FDA524744AB0626DD7155DDA71490B365ED3C51E6770C1884470ADF4565A69BA'
  $old=[IO.File]::ReadAllText($s34Log)
  foreach($mark in @('RESULT=HOLD_S34_APPINSTALLER_REGISTRY_TOPOLOGY_READONLY',
    'REG=STAGED;EXISTS=True;CHILDREN=4;VALUES=0',
    'COPIED_SOFTWARE_UNLOAD_EXIT=0','OWNED_MOUNT_RELEASED=True',
    'S31_WIM_SHA256_UNCHANGED=True')){
   if(-not $old.Contains($mark)){throw "S34_ANCHOR_MISSING=$mark"}
  }
  $oldJson=Get-Content -LiteralPath $s34Json -Raw -Encoding utf8 | ConvertFrom-Json
  $prior=@($oldJson.RegistryScopes | Where-Object {$_.Label -eq 'STAGED'})
  if($prior.Count -ne 1 -or -not $prior[0].Exists){throw 'S34_STAGED_SNAPSHOT_UNEXPECTED'}
  $past=@($prior[0].Children)
  if($past.Count -ne 4 -or
     @($past | Where-Object {$ownRoots -cnotcontains $_}).Count -ne 0){
   throw 'S34_FOUR_ROOTS_DRIFT'
  }
  if(-not [IO.File]::Exists($wim) -or (Get-Item -LiteralPath $wim).Length -ne 6509216853L){
   throw 'S31_WIM_LENGTH_OR_IDENTITY_DRIFT'
  }
  Pin 'S31_WIM' $wim $wimSHA
  if(@(MountTable | Where-Object {$_ -match '^\s*Mount Dir\s*:'}).Count -ne 0){
   throw 'PREEXISTING_WIM_MOUNT'
  }
  $null=@(& $reg query $hive 2>&1)
  if($LASTEXITCODE -eq 0){throw 'TEMP_HIVE_ALIAS_ALREADY_PRESENT'}
  Note '[2/6] RO OWNED SHORT MOUNT'
  $null=New-Item -ItemType Directory -Path $mount
  $null=NativeDism 'MOUNT' @('/English','/Mount-Image',"/ImageFile:$wim",
    '/Index:1',"/MountDir:$mount",'/ReadOnly')
  $fields=@{}
  foreach($line in @(MountTable)){
   $m=[regex]::Match([string]$line,
     '^\s*(Mount Dir|Image File|Image Index|Mounted Read/Write|Status)\s*:\s*(.*?)\s*$')
   if($m.Success){
    $key=$m.Groups[1].Value
    if($fields.ContainsKey($key)){throw 'DUPLICATE_MOUNT_FIELD'}
    $fields[$key]=$m.Groups[2].Value.Trim()
   }
  }
  if($fields.Count -ne 5 -or $fields['Mount Dir'] -ine $mount -or
     $fields['Image File'] -ine $wim -or $fields['Image Index'] -ne '1' -or
     $fields['Mounted Read/Write'] -ine 'No' -or $fields['Status'] -ine 'Ok'){
   throw 'RO_MOUNT_OWNER_CONTRACT_FAILED'
  }
  $mounted=$true
  Note 'RO_MOUNT_OWNER=PASS_5_FIELDS'
  Note '[3/6] RETAINED PROVIDERS AND APPINSTALLER MANIFEST'
  $appx=NativeDism 'APPX' @('/English',"/Image:$mount",'/Get-ProvisionedAppxPackages')
  $names=@([regex]::Matches($appx,'(?im)^\s*DisplayName\s*:\s*(\S+)\s*$') |
    ForEach-Object {$_.Groups[1].Value})
  if($names.Count -ne 10 -or
     @($names | Where-Object {$_ -ceq 'Microsoft.DesktopAppInstaller'}).Count -ne 1){
   throw "PROVISIONED_APPX_STAGE_DRIFT=$($names.Count)"
  }
  foreach($name in $providerNames){
   if(@($names | Where-Object {$_ -ceq $name}).Count -ne 1){
    throw "PROVIDER_NOT_PROVISIONED=$name"
   }
   Note "PROVIDER_PROVISIONED=$name"
  }
  $provisionedPackageIds=@([regex]::Matches($appx,'(?im)^\s*PackageName\s*:\s*(\S+)\s*$') |
    ForEach-Object {$_.Groups[1].Value})
  foreach($name in $providerNames){
   $found=@($provisionedPackageIds | Where-Object {$_.StartsWith($name+'_',[StringComparison]::OrdinalIgnoreCase)})
   Note "PROVIDER_PACKAGE_IDS=$name;COUNT=$($found.Count)"
   foreach($v in $found){Note "PROVIDER_PACKAGE=$v"}
  }
  $manifest=Join-Path $mount ('Program Files\WindowsApps\' +
    'Microsoft.DesktopAppInstaller_1.21.10121.0_x64__8wekyb3d8bbwe\AppxManifest.xml')
  if(-not [IO.File]::Exists($manifest)){throw 'APPINSTALLER_X64_MANIFEST_MISSING'}
  [xml]$xml=[IO.File]::ReadAllText($manifest)
  $depNodes=@($xml.SelectNodes("//*[local-name()='PackageDependency']"))
  foreach($node in $depNodes){
   $item=[pscustomobject]@{
    Name=$node.GetAttribute('Name')
    MinVersion=$node.GetAttribute('MinVersion')
    Publisher=$node.GetAttribute('Publisher')
   }
   $manifestDeps.Add($item)
   Note "MANIFEST_DEP=$($item.Name);MIN=$($item.MinVersion)"
  }
  Note "MANIFEST_PACKAGE_DEPENDENCIES=$($manifestDeps.Count)"
  Note '[4/6] ONLY NAMED TARGET AND PROVIDER REGISTRY ROOTS'
  $null=New-Item -ItemType Directory -Path $evidence
  $offline=Join-Path $mount 'Windows\System32\config\SOFTWARE'
  Copy-Item -LiteralPath $offline -Destination $shadow -ErrorAction Stop
  if((Get-Item -LiteralPath $shadow).Length -lt 1MB){throw 'OFFLINE_SOFTWARE_COPY_TOO_SMALL'}
  Note "SOFTWARE_COPY_SHA256=$((Get-FileHash -LiteralPath $shadow -Algorithm SHA256).Hash)"
  $regOut=@(& $reg load $hive $shadow 2>&1 | ForEach-Object {[string]$_})
  $exit=[int]$LASTEXITCODE
  Note "COPIED_SOFTWARE_LOAD_EXIT=$exit"
  if($exit -ne 0){throw "COPIED_SOFTWARE_LOAD_FAILED=$exit;$($regOut -join ' | ')"}
  $loaded=$true
  $target=ReadKey 'APPINSTALLER_STAGED' "$stagedPrefix\$family"
  if(-not $target.Exists -or $target.Children.Count -ne 4 -or
    @($target.Children | Where-Object {$ownRoots -cnotcontains $_}).Count -ne 0){
   throw 'CURRENT_S35_APPINSTALLER_FOUR_ROOT_DRIFT'
  }
  for($i=0;$i -lt $providerFamilies.Count;$i++){
   $provider=$providerFamilies[$i]
   $null=ReadKey "PROVIDER_STAGED_$i" "$stagedPrefix\$provider"
   $null=ReadKey "PROVIDER_CONFIG_$i" "$cfgPrefix\$provider"
  }
  Note 'PROVIDER_STAGED_LOCATION=EVIDENCE_CAPTURED_NOT_REMOVAL_AUTHORITY'
  $complete=$true
 }catch{
  Note "ERROR=$($_.Exception.Message)"
 }finally{
  Note '[5/6] SNAPSHOT AND COPIED HIVE UNLOAD + RO DISCARD'
  $snapshotOK=$false
  try{
   $data=[pscustomobject]@{
    Stage='S35';Scope='READONLY_DISCOVERY_NOT_CERTIFICATION'
    WIM=$wim;WimSHA256=$wimSHA
    PriorS34LogSHA256='09B30C9308BEC3371AF11180476E4A4F73D7A1C7F3B42E48E0962BB19F85980B'
    ProvisionedNames=[string[]]$names
    ProvisionedPackageNames=[string[]]$provisionedPackageIds
    RegistryRoots=@($seenKeys.ToArray())
    ManifestDependencies=@($manifestDeps.ToArray())
   }
   [IO.File]::WriteAllText($snapshot,($data | ConvertTo-Json -Depth 10),$utf8)
   $snapshotOK=$true
   Note "PROVIDER_SNAPSHOT=$snapshot"
  }catch{Note "SNAPSHOT_ERROR=$($_.Exception.Message)"}
  try{
   if($loaded){
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    $lines=@(& $reg unload $hive 2>&1 | ForEach-Object {[string]$_})
    $exit=[int]$LASTEXITCODE
    Note "COPIED_HIVE_UNLOAD_EXIT=$exit"
    if($exit -ne 0){throw "COPY_HIVE_UNLOAD_FAILED=$exit;$($lines -join ' | ')"}
    $loaded=$false
   }
  }catch{Note "HIVE_UNLOAD_ERROR=$($_.Exception.Message)"}
  try{
   if(-not $loaded -and [IO.File]::Exists($shadow)){
    Remove-Item -LiteralPath $shadow -Force -ErrorAction Stop
    Note 'COPIED_SOFTWARE_DELETE=PASS'
   }
  }catch{Note "COPY_CLEANUP_ERROR=$($_.Exception.Message)"}
  try{
   if(-not $loaded -and (Owned @(MountTable))){
    $null=NativeDism 'DISCARD' @('/English','/Unmount-Image',"/MountDir:$mount",'/Discard')
    Note 'READONLY_DISCARD=PASS'
   }
   $released= -not(Owned @(MountTable))
   Note "OWNED_MOUNT_RELEASED=$released"
  }catch{Note "DISCARD_ERROR=$($_.Exception.Message)"}
  Note '[6/6] SOURCE HASH AND RESULT'
  try{
   if($released -and [IO.File]::Exists($wim) -and
     (Get-Item -LiteralPath $wim).Length -eq 6509216853L){
    $sourceOK=((Get-FileHash -LiteralPath $wim -Algorithm SHA256).Hash -ceq $wimSHA)
   }
  }catch{Note "POST_HASH_ERROR=$($_.Exception.Message)"}
  Note "S31_WIM_SHA_UNCHANGED=$sourceOK"
  if($complete -and $snapshotOK -and -not $loaded -and $released -and $sourceOK){
   $result='PASS_S35_9711_APPINSTALLER_PROVIDER_DISCOVERY_READONLY'
  }
  Note 'PROVIDER_OWNER_SEMANTICS=NOT_CERTIFIED'
  Note 'IMAGE_AND_REGISTRY_MUTATION=NOT_RUN'
  Note 'APPINSTALLER_R133_REMOVAL_AUTHORITY=NOT_GRANTED'
  Note "RESULT=$result"
  Write-Host "MAIN_LOG=$report"
  Write-Host "SNAPSHOT_JSON=$snapshot"
 }
}
