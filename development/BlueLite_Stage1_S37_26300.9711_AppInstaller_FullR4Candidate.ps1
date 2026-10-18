& {
 Set-StrictMode -Version Latest
 $ErrorActionPreference='Stop'
 $PSNativeCommandUseErrorActionPreference=$false
 $source='C:\work\E2E\BlueLite_Stage1_S31_26300.9711_OneDriveAMBER\install.wim'
 $sourceSHA='F52389FA66F8B60D56661C8786EC99409FB95447403B3C6FCBB94121EF8E340B'
 $s35Log='C:\work\logs\BlueLite_Stage1_S35_26300.9711_AppInstaller_ProviderTopologyReadOnly.txt'
 $s35Json='C:\work\logs\BlueLite_Stage1_S35_26300.9711_AppInstaller_ProviderSnapshot.json'
 $s34Log='C:\work\logs\BlueLite_Stage1_S34_26300.9711_AppInstaller_RegistryTopologyReadOnly.txt'
 $s33Log='C:\work\logs\BlueLite_Stage1_S33_26300.9711_AppInstaller_NativeOwnerGate.txt'
 $work='C:\work\E2E\BlueLite_Stage1_S37_26300.9711_FullR4Candidate'
 $clone=Join-Path $work 'install.disposable.wim'
 $mount='C:\BL37M'
 $report='C:\work\logs\BlueLite_Stage1_S37_26300.9711_AppInstaller_FullR4Candidate.txt'
 $snapshot='C:\work\logs\BlueLite_Stage1_S37_26300.9711_AppInstaller_FullR4Evidence.json'
 $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
 $reg=Join-Path $env:SystemRoot 'System32\reg.exe'
 $alias='BL37SOFT_'+$PID
 $hive='HKLM\'+$alias
 $prefix='Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore'
 $family='Microsoft.DesktopAppInstaller_8wekyb3d8bbwe'
 $bundle='Microsoft.DesktopAppInstaller_2024.401.617.0_neutral_~_8wekyb3d8bbwe'
 $roots=@(
 'Microsoft.DesktopAppInstaller_1.21.10121.0_neutral_split.scale-100_8wekyb3d8bbwe',
 'Microsoft.DesktopAppInstaller_1.21.10121.0_neutral_split.scale-125_8wekyb3d8bbwe',
 'Microsoft.DesktopAppInstaller_1.21.10121.0_x64__8wekyb3d8bbwe',
 'Microsoft.DesktopAppInstaller_2024.401.617.0_neutral_~_8wekyb3d8bbwe'
 )
 $count=@(28,28,681,3)
 $sizes=@(36084L,39330L,148010477L,51837L)
 $keep=@(
 'Microsoft.NET.Native.Framework.2.2_2.2.29512.0_x64__8wekyb3d8bbwe',
 'Microsoft.NET.Native.Runtime.2.2_2.2.28604.0_x64__8wekyb3d8bbwe',
 'Microsoft.SecHealthUI_1000.26100.1.0_x64__8wekyb3d8bbwe',
 'Microsoft.UI.Xaml.2.8_8.2310.30001.0_x64__8wekyb3d8bbwe',
 'Microsoft.VCLibs.140.00.UWPDesktop_14.0.30704.0_x64__8wekyb3d8bbwe',
 'Microsoft.VCLibs.140.00_14.0.30704.0_x64__8wekyb3d8bbwe',
 'Microsoft.Windows.Photos_2024.401.617.0_neutral_~_8wekyb3d8bbwe',
 'Microsoft.WindowsCalculator_2024.401.618.0_neutral_~_8wekyb3d8bbwe',
 'Microsoft.WindowsNotepad_2024.401.617.0_neutral_~_8wekyb3d8bbwe'
 )
 $target=@(
 @{Id='APPLICATIONS';Path=$prefix+'\Applications\'+$bundle;Names=@('Path','Regions','RequiresAllUserStoreRefresh');Children=@()},
 @{Id='CONFIG';Path=$prefix+'\Config\'+$family;Names=@('SetupPhase');Children=@()},
 @{Id='STAGED';Path=$prefix+'\Staged\'+$family;Names=@();Children=$roots},
 @{Id='WOW_CONFIG';Path='WOW6432Node\'+$prefix+'\Config\'+$family;Names=@('SetupPhase');Children=@()},
 @{Id='BROAD_FS';Path='Microsoft\Windows\CurrentVersion\CapabilityAccessManager\Capabilities\broadFilesystemAccess\Apps\'+$family;Names=@('InitUserAppConsentDenied','TerminateAppOnAccessChange','UserConsentRequired');Children=@()}
 )
 $marker=$prefix+'\Deprovisioned\'+$family
 $provider=[string[]]@(
  'Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Staged\Microsoft.UI.Xaml.2.8_8wekyb3d8bbwe',
  'Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Config\Microsoft.UI.Xaml.2.8_8wekyb3d8bbwe',
  'Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Staged\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe',
  'Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Config\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe'
 )
 if($provider.Count -ne 4 -or
    @($provider|Sort-Object -Unique).Count -ne 4 -or
    @($provider|Where-Object {$_ -match '\s' -or $_ -notmatch '^Microsoft\\Windows\\CurrentVersion\\Appx\\AppxAllUserStore\\(Staged|Config)\\Microsoft\.(UI\.Xaml\.2\.8|VCLibs\.140\.00\.UWPDesktop)_8wekyb3d8bbwe$'}).Count -ne 0){
  throw 'S37_PROVIDER_LIST_EXACT_FOUR_NOT_PROVEN'
 }
 $fsutil=Join-Path $env:SystemRoot 'System32\fsutil.exe'
 $icacls=Join-Path $env:SystemRoot 'System32\icacls.exe'
 $cmd=Join-Path $env:SystemRoot 'System32\cmd.exe'
 $s32csv='C:\work\logs\BlueLite_Stage1_S32_26300.9711_AppInstaller_PhysicalInventory.csv'
 $s36r2log='C:\work\logs\BlueLite_Stage1_S36R2_26300.9711_AppInstaller_LifecycleDisposable.txt'
 $s36r2json='C:\work\logs\BlueLite_Stage1_S36R2_26300.9711_AppInstaller_LifecycleEvidence.json'
 $aclDir='C:\work\logs\BlueLite_Stage1_S37_26300.9711_ACL_Evidence'
 $anomalyFile='C:\work\logs\BlueLite_Stage1_S37_26300.9711_OwnerAnomalies.csv'
 $committed=$false;$carveOK=$false
 $utf8=[Text.UTF8Encoding]::new($false)
 $loaded=$false;$discharged=$false;$sourceOK=$false;$cloneGone=$false;$testOK=$false;$jsonOK=$false
 $state='HOLD_S37_9711_R4_FULL_CANDIDATE'
 $captures=[System.Collections.Generic.List[object]]::new()
 $admin=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
 if($PSVersionTable.PSVersion.Major -ne 7 -or -not $admin){throw 'PS7_ADMIN_REQUIRED'}
 if(-not(Test-Path 'C:\work\logs' -PathType Container)){throw 'LOG_ROOT_MISSING'}
 foreach($path in @($work,$mount,$report,$snapshot,$aclDir,$anomalyFile)){
  if(Test-Path -LiteralPath $path){throw ('S36_OWNED_OUTPUT_EXISTS='+$path)}
 }
 [IO.File]::WriteAllText($report,'',$utf8)
 function Note([string]$v){
  $line=(Get-Date -Format 'HH:mm:ss')+' | '+$v
  Write-Host $line
  [IO.File]::AppendAllText($report,$line+[Environment]::NewLine,$utf8)
 }
 function Pin([string]$tag,[string]$path,[string]$sha){
  if(-not(Test-Path -LiteralPath $path -PathType Leaf)){throw ('PIN_MISSING='+$tag)}
  $actual=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
  if($actual -cne $sha){throw ('PIN_MISMATCH='+$tag+';'+$actual)}
  Note ('PIN_'+$tag+'=PASS')
 }
 function Run([string]$label,[string]$program,[string[]]$arguments){
  $lines=@(& $program @arguments 2>&1 | ForEach-Object {[string]$_})
  $ec=[int]$LASTEXITCODE
  Note ('NATIVE_'+$label+'_EXIT='+$ec)
  if($ec -ne 0){throw ('NATIVE_'+$label+'_FAILED='+$ec+';'+($lines -join ' | '))}
  return ($lines -join [Environment]::NewLine)
 }
 function MountTable{
  $lines=@(& $dism /English /Get-MountedWimInfo 2>&1 | ForEach-Object {[string]$_})
  if($LASTEXITCODE -ne 0){throw 'DISM_MOUNT_TABLE_FAILED'}
  return $lines
 }
 function Ours([string[]]$lines){
  foreach($line in $lines){
   $m=[regex]::Match($line,'^\s*Mount Dir\s*:\s*(.*?)\s*$')
   if($m.Success -and $m.Groups[1].Value.Trim() -ieq $mount){return $true}
  }
  return $false
 }
 function Same([string[]]$a,[string[]]$b){
  return ($a.Count -eq $b.Count -and
   @($a|Where-Object {$b -cnotcontains $_}).Count -eq 0 -and
   @($b|Where-Object {$a -cnotcontains $_}).Count -eq 0)
 }
 function ReadKey([string]$tag,[string]$relative){
  $k=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(($alias+'\'+$relative),$false)
  $exists=$null -ne $k
  [string[]]$children=@();[string[]]$values=@()
  if($exists){try{
   $children=@($k.GetSubKeyNames()|Sort-Object)
   $values=@($k.GetValueNames()|Sort-Object)
  }finally{$k.Dispose()}}
  $r=[pscustomobject]@{Label=$tag;Path=$relative;Exists=$exists;Children=$children;Values=$values}
  $captures.Add($r)
  Note ('REG_'+$tag+';EXISTS='+$exists+';CHILDREN='+$children.Count+';VALUES='+$values.Count)
  return $r
 }
 function State([string]$tag,[bool]$present){
  foreach($t in $target){
   $k=ReadKey ($tag+'_'+$t.Id) $t.Path
   if($k.Exists -ne $present){throw ('TARGET_KEY_PRESENCE_DRIFT='+$tag+';'+$t.Id)}
   if($present -and (-not(Same $k.Children ([string[]]$t.Children)) -or
      -not(Same $k.Values ([string[]]$t.Names)))){
    throw ('TARGET_PRESTATE_DRIFT='+$tag+';'+$t.Id)
   }
  }
  $m=ReadKey ($tag+'_MARKER') $marker
  if($m.Exists -eq $present){throw ('TARGET_MARKER_PRESENCE_DRIFT='+$tag)}
  if(-not $present -and ($m.Children.Count -ne 0 -or $m.Values.Count -ne 0)){
   throw 'TARGET_MARKER_NOT_EMPTY'
  }
 }
 function Providers([string]$tag){
  $result=[System.Collections.Generic.List[object]]::new()
  foreach($name in $provider){
   $k=ReadKey ($tag+'_PROVIDER') $name
   if(-not $k.Exists){throw ('PROVIDER_KEY_ABSENT='+$name)}
   $result.Add($k)
  }
  return @($result.ToArray())
 }
 function Appx([string]$tag,[string[]]$wanted){
  $text=Run ($tag+'_APPX') $dism @('/English',('/Image:'+$mount),'/Get-ProvisionedAppxPackages')
  $pkgs=@([regex]::Matches($text,'(?im)^\s*PackageName\s*:\s*(\S+)\s*$')|ForEach-Object {$_.Groups[1].Value})
  if(-not(Same $pkgs $wanted)){throw ($tag+'_APPX_EXACT_IDENTITY_MISMATCH='+($pkgs -join ';'))}
  Note ('APPX_'+$tag+'_PASS='+$pkgs.Count+'_EXACT')
 }
 function Payload([string]$tag){
  $base=Join-Path $mount 'Program Files\WindowsApps'
  $dirs=@(Get-ChildItem -LiteralPath $base -Directory -Force |
    Where-Object {$_.Name -like 'Microsoft.DesktopAppInstaller_*_8wekyb3d8bbwe'})
  if($dirs.Count -ne 4 -or @($dirs|Where-Object {$roots -cnotcontains $_.Name}).Count -ne 0){
   throw ($tag+'_APPINSTALLER_ROOTS_DRIFT')
  }
  for($i=0;$i -lt 4;$i++){
   $files=@(Get-ChildItem -LiteralPath (Join-Path $base $roots[$i]) -File -Recurse -Force -ErrorAction Stop)
   [long]$bytes=0
   foreach($file in $files){$bytes+=[long]$file.Length}
   if($files.Count -ne $count[$i] -or $bytes -ne $sizes[$i]){
    throw ($tag+'_APPINSTALLER_FILES_CHANGED='+$roots[$i])
   }
  }
  Note ('PAYLOAD_'+$tag+'=PASS_4_ROOTS_740_LOGICAL_BYTES_148137728')
 }
 try{
  Note 'STAGE=S37_26300_9711_R4_DISPOSABLE_FULL_CANDIDATE'
  Note 'MODE=DISPOSABLE_RW_FULL_R4_EXACT_COMMIT_ONLY_IF_ALL_GATES_PASS'
  Note '[1/7] SOURCE EVIDENCE PINS'
  Pin 'S36R2_REPORT' $s36r2log 'A8BCC29A6F575C477033D8FE5EA25F669CBA6672CC46888E3F5569EAAA649233'
  Pin 'S36R2_JSON' $s36r2json 'CD6606F5D7FA0BD6FE526B550474917801823A1E6D418F9771DF103689D54AED'
  Pin 'S32_CSV' $s32csv '5828C1540CC39B06CB73DB00C5D4604752A2D3BF9BB0039A7C11F005DB8B5B95'
  $s36r2text=[IO.File]::ReadAllText($s36r2log)
  if(-not $s36r2text.Contains('RESULT=PASS_S36R2_9711_R4_LIFECYCLE_TEST_ALWAYS_DISCARDED') -or
     -not $s36r2text.Contains('S31_ORIGINAL_SHA256_UNCHANGED=True')){
   throw 'S36R2_NATIVE_PROOF_MISSING'
  }
  $s36r2proof=Get-Content -LiteralPath $s36r2json -Raw -Encoding utf8|ConvertFrom-Json
  if(-not $s36r2proof.NativeLifecyclePassed){throw 'S36R2_JSON_NATIVE_LIFECYCLE_NOT_PASS'}
  Pin 'S36R1_PREVIOUS_LOG' 'C:\work\logs\BlueLite_Stage1_S36R1_26300.9711_AppInstaller_LifecycleDisposable.txt' '2DCCF677E2B94E0D5952BE4FB15E517310679B28510BBCA1D37E42ADFAB8F3FF'
  Pin 'S36R1_PREVIOUS_JSON' 'C:\work\logs\BlueLite_Stage1_S36R1_26300.9711_AppInstaller_LifecycleEvidence.json' '3D765C7345A7E8EAAE7C50D4208EE26512C7B6EFFDA02D67E561F4FB8C666E18'
  $priorR1=[IO.File]::ReadAllText('C:\work\logs\BlueLite_Stage1_S36R1_26300.9711_AppInstaller_LifecycleDisposable.txt')
  foreach($anchor in @('S36R1_PROVIDER_LIST=PASS_4_EXACT_SOURCE_S35_KEYS',
    'FAIL_CLOSED=NEW_MARKER_NOT_EMPTY_REGISTRY_API',
    'NATIVE_EMERGENCY_UNLOAD_EXIT=0','NATIVE_DISCARD_EXIT=0',
    'OWNED_RW_MOUNT_RELEASED=True','DISPOSABLE_CLONE_WIM_DELETED=True',
    'S31_ORIGINAL_SHA256_UNCHANGED=True',
    'RESULT=HOLD_S36R1_9711_APPINSTALLER_DISPOSABLE_LIFECYCLE')){
   if(-not $priorR1.Contains($anchor)){throw ('S36R1_EXPECTED_EVIDENCE_MISSING='+$anchor)}
  }
  Pin 'S36_ORIGINAL_LOG' 'C:\work\logs\BlueLite_Stage1_S36_26300.9711_AppInstaller_LifecycleDisposable.txt' '344DF85A1FC90D204ABCD34880378A7CBD75800F357EBACBA36EC2ED3BB8B650'
  Pin 'S36_ORIGINAL_JSON' 'C:\work\logs\BlueLite_Stage1_S36_26300.9711_AppInstaller_LifecycleEvidence.json' '798F7FE8104782C9CF4C3857F884E6BFEBBDE04677F75034A8D4F67663C51E35'
  $oldS36=[IO.File]::ReadAllText('C:\work\logs\BlueLite_Stage1_S36_26300.9711_AppInstaller_LifecycleDisposable.txt')
  foreach($must in @('RESULT=HOLD_S36_9711_APPINSTALLER_DISPOSABLE_LIFECYCLE',
    'OWNED_RW_MOUNT_RELEASED=True','DISPOSABLE_CLONE_WIM_DELETED=True',
    'S31_ORIGINAL_SHA256_UNCHANGED=True')){
   if(-not $oldS36.Contains($must)){throw ('S36_ORIGINAL_ROLLBACK_ANCHOR_MISSING='+$must)}
  }
  Pin 'S35_LOG' $s35Log 'B7B50189034A636B62A47627D6B14F5217AC752F995BD75BAC9533EF9B752DCD'
  Pin 'S35_JSON' $s35Json '6C280CB28E146CA1B49847457B1B072B4F9E1AAFDD441D5FBA82F243082A3727'
  Pin 'S34_LOG' $s34Log '09B30C9308BEC3371AF11180476E4A4F73D7A1C7F3B42E48E0962BB19F85980B'
  Pin 'S33_LOG' $s33Log 'FDA524744AB0626DD7155DDA71490B365ED3C51E6770C1884470ADF4565A69BA'
  $prior=[IO.File]::ReadAllText($s35Log)
  if(-not $prior.Contains('RESULT=PASS_S35_9711_APPINSTALLER_PROVIDER_DISCOVERY_READONLY')){
   throw 'S35_NATIVE_PASS_MARKER_MISSING'
  }
  if(-not [IO.File]::Exists($source) -or (Get-Item -LiteralPath $source).Length -ne 6509216853L){
   throw 'S31_WIM_IDENTITY_MISSING_OR_SIZE_CHANGED'
  }
  Pin 'S31_WIM' $source $sourceSHA
  $j=Get-Content -LiteralPath $s35Json -Raw -Encoding utf8 | ConvertFrom-Json
  $providerEntries=@($j.RegistryRoots | Where-Object {$_.Name -like 'PROVIDER_*'})
  $providerFromS35=[string[]]@($providerEntries|ForEach-Object {$_.RelativePath})
  if($providerEntries.Count -ne 4 -or
     @($providerEntries|Where-Object {-not $_.Exists}).Count -ne 0 -or
     -not(Same $providerFromS35 $provider)){
   throw 'S37_PROVIDER_FOUR_PATHS_NOT_EQUAL_PINNED_S35'
  }
  Note 'S37_PROVIDER_LIST=PASS_4_EXACT_SOURCE_S35_KEYS'
  if(-not(Same ([string[]]$j.ProvisionedPackageNames) ([string[]](@($keep)+@($bundle))))){
   throw 'S35_PROVISIONED_10_SET_DRIFT'
  }
  if(@(MountTable|Where-Object {$_ -match '^\s*Mount Dir\s*:'}).Count -ne 0){
   throw 'PREEXISTING_MOUNT_NO_ACTION'
  }
  $null=@(& $reg query $hive 2>&1)
  if($LASTEXITCODE -eq 0){throw 'OWNED_HIVE_ALIAS_ALREADY_PRESENT'}
  $free=(Get-PSDrive -Name C).Free
  if($null -eq $free -or $free -lt 12GB){throw ('DISPOSABLE_TEST_REQUIRES_12GIB_FREE='+$free)}
  Note ('DISK_FREE_PREFLIGHT_BYTES='+$free)
  Note '[2/7] EXACT OWNED CLONE AND RW MOUNT'
  $null=New-Item -ItemType Directory -Path $work
  Copy-Item -LiteralPath $source -Destination $clone -ErrorAction Stop
  Pin 'DISPOSABLE_CLONE' $clone $sourceSHA
  $null=New-Item -ItemType Directory -Path $mount
  $null=Run 'MOUNT' $dism @('/English','/Mount-Image',('/ImageFile:'+$clone),
   '/Index:1',('/MountDir:'+$mount))
  $fields=@{}
  foreach($line in @(MountTable)){
   $m=[regex]::Match([string]$line,
    '^\s*(Mount Dir|Image File|Image Index|Mounted Read/Write|Status)\s*:\s*(.*?)\s*$')
   if($m.Success){$fields[$m.Groups[1].Value]=$m.Groups[2].Value.Trim()}
  }
  if($fields.Count -ne 5 -or $fields['Mount Dir'] -ine $mount -or
     $fields['Image File'] -ine $clone -or $fields['Image Index'] -ne '1' -or
     $fields['Mounted Read/Write'] -ine 'Yes' -or $fields['Status'] -ine 'Ok'){
   throw 'OWNED_RW_MOUNT_NOT_PROVEN'
  }
  Note 'OWNED_RW_MOUNT=PASS_5_FIELDS'
  Note '[3/7] PRESTATE APPX,CBS,PAYLOAD,REGISTRY,PROVIDERS'
  $preHealth=Run 'PRE_HEALTH' $dism @('/English',('/Image:'+$mount),'/Cleanup-Image','/CheckHealth')
  if($preHealth -notmatch 'No component store corruption detected'){throw 'PRE_CBS_NOT_CLEAN'}
  Appx 'PRE' ([string[]](@($keep)+@($bundle)))
  Payload 'PRE'
  $software=Join-Path $mount 'Windows\System32\config\SOFTWARE'
  $null=Run 'LOAD' $reg @('load',$hive,$software)
  $loaded=$true
  State 'PRE' $true
  $before=Providers 'PRE'
  Note '[4/7] TARGET-ONLY DEPROVISION EMPTY LEAF + REMOVE FIVE EXACT TARGET KEYS'
  $null=Run 'MARKER_ADD' $reg @('add',($hive+'\'+$marker),'/f')
  $created=ReadKey 'CREATED_MARKER' $marker
  if(-not $created.Exists -or $created.Children.Count -ne 0){
   throw 'NEW_MARKER_TOPOLOGY_DRIFT'
  }
  if($created.Values.Count -eq 1 -and $created.Values[0] -ceq ''){
   $markerReg=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(($alias+'\'+$marker),$false)
   if($null -eq $markerReg){throw 'CREATED_MARKER_REOPEN_FAILED'}
   try{
    $defaultKind=$markerReg.GetValueKind('')
    $defaultData=$markerReg.GetValue('',$null,[Microsoft.Win32.RegistryValueOptions]::None)
   }finally{$markerReg.Dispose()}
   Note ('CREATED_MARKER_DEFAULT_KIND='+[string]$defaultKind)
   if($defaultKind -ne [Microsoft.Win32.RegistryValueKind]::String -or
      $null -eq $defaultData -or -not($defaultData -is [string]) -or
      $defaultData -cne ''){
    throw 'DEFAULT_MARKER_TYPE_OR_DATA_UNEXPECTED'
   }
   $null=Run 'REMOVE_EMPTY_DEFAULT_ONLY' $reg @('delete',($hive+'\'+$marker),'/ve','/f')
   Note 'MARKER_EMPTY_DEFAULT_NORMALIZED=PASS'
  }elseif($created.Values.Count -ne 0){
   throw 'CREATED_MARKER_UNEXPECTED_VALUES'
  }
  $emptyMarker=ReadKey 'NORMALIZED_EMPTY_MARKER' $marker
  if(-not $emptyMarker.Exists -or $emptyMarker.Children.Count -ne 0 -or
     $emptyMarker.Values.Count -ne 0){
   throw 'REGISTRY_API_MARKER_NOT_EMPTY_AFTER_NORMALIZATION'
  }
  Note 'R133_STYLE_EMPTY_MARKER_API=PASS_ZERO_CHILDREN_ZERO_VALUES'
  foreach($entry in $target){
   $null=Run ('DELETE_'+$entry.Id) $reg @('delete',($hive+'\'+$entry.Path),'/f')
  }
  State 'POST' $false
  $after=Providers 'POST'
  if($before.Count -ne $after.Count){throw 'PROVIDER_COUNT_CHANGED'}
  for($i=0;$i -lt $before.Count;$i++){
   if($before[$i].Path -cne $after[$i].Path -or
      -not(Same $before[$i].Children $after[$i].Children) -or
      -not(Same $before[$i].Values $after[$i].Values)){
    throw 'PROVIDER_REGISTRY_TOPOLOGY_CHANGED'
   }
  }
  [GC]::Collect();[GC]::WaitForPendingFinalizers()
  $null=Run 'UNLOAD' $reg @('unload',$hive)
  $loaded=$false
  Note '[5/7] NATIVE TEN-TO-NINE APPX TRANSITION WITH PAYLOAD PRESERVED'
  Appx 'POST' $keep
  Payload 'POST'
  $postHealth=Run 'POST_HEALTH' $dism @('/English',('/Image:'+$mount),'/Cleanup-Image','/CheckHealth')
  if($postHealth -notmatch 'No component store corruption detected'){throw 'POST_CBS_NOT_CLEAN'}
  $packages=Run 'POST_PACKAGES' $dism @('/English',('/Image:'+$mount),'/Get-Packages','/Format:Table')
  if($packages -match 'Install Pending|Uninstall Pending'){throw 'CBS_PENDING_AFTER_TARGET_LIFECYCLE'}
  Note '[6/9] HARDLINK OWNER CLOSURE ON CURRENT RW CLONE'
  $inventory=@(Import-Csv -LiteralPath $s32csv -Encoding utf8)
  if($inventory.Count -ne 740){throw 'S37_OWNER_INVENTORY_NOT_740'}
  $appRoot=Join-Path $mount 'Program Files\WindowsApps'
  $unique=[System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  $issues=[System.Collections.Generic.List[object]]::new()
  $checked=0
  foreach($r in $inventory){
   if($roots -cnotcontains $r.Root -or [string]::IsNullOrWhiteSpace($r.Relative) -or
      $r.Relative.StartsWith('\') -or $r.Relative.StartsWith('/') -or
      $r.Relative.Contains(':') -or
      @($r.Relative -split '\\'|Where-Object {$_ -eq '..' -or $_ -eq '.'}).Count -ne 0 -or
      -not $unique.Add($r.Root+'|'+$r.Relative)){throw 'S37_OWNER_CSV_BAD_PATH_OR_DUPLICATE'}
   $file=Join-Path (Join-Path $appRoot $r.Root) $r.Relative
   if(-not [IO.File]::Exists($file)){throw ('OWNER_FILE_MISSING='+$file)}
   $info=Get-Item -LiteralPath $file -Force
   if($info.Length -ne [long]$r.BytesLogical -or
      (($info.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0)){
    throw ('OWNER_FILE_SIZE_REPARSE_DRIFT='+$file)
   }
   $lines=@(& $fsutil hardlink list $file 2>&1|ForEach-Object {[string]$_})
   $exit=[int]$LASTEXITCODE
   $trimmed=@($lines|ForEach-Object {$_.Trim()}|Where-Object {$_.Length -gt 0})
   $why=''
   if($exit -ne 0 -or $trimmed.Count -ne 1){$why='NATIVE_EXIT_OR_LINK_COUNT'}
   else{
    $found=$trimmed[0]
    if($found -match '^[a-zA-Z]:\\'){$found=$found.Substring(2)}
    if($found -ine $file.Substring(2)){$why='FOREIGN_OWNER_PATH'}
   }
   if($why){$issues.Add([pscustomobject]@{Root=$r.Root;Relative=$r.Relative;Reason=$why;Native=($lines -join '|')})}
   $checked++
   if(($checked%100) -eq 0){Note ('OWNER_PROGRESS='+$checked+';ANOMALIES='+$issues.Count)}
  }
  if($issues.Count -gt 0){$issues|Export-Csv -LiteralPath $anomalyFile -NoTypeInformation -Encoding utf8}
  if($checked -ne 740 -or $issues.Count -ne 0){throw 'S37_HARDLINK_OWNER_CLOSURE_NOT_740'}
  Note 'S37_NATIVE_HARDLINK_OWNER=PASS_740_NO_EXTERNAL'
  Note '[7/9] ONLY FOUR EXACT PHYSICAL WINDOWSAPP ROOTS'
  $null=New-Item -ItemType Directory -Path $aclDir -ErrorAction Stop
  for($i=0;$i -lt 4;$i++){
   $tree=Join-Path $appRoot $roots[$i]
   $acl=Join-Path $aclDir ('ACL-'+($i+1)+'.txt')
   $null=Run ('ACL_SAVE_'+$i) $icacls @($tree,'/save',$acl,'/T','/C','/Q')
   if(-not [IO.File]::Exists($acl)){throw 'S37_ACL_BACKUP_MISSING'}
   $null=Run ('ACL_GRANT_'+$i) $icacls @($tree,'/grant:r','*S-1-5-32-544:(OI)(CI)F','/T','/C','/Q')
  }
  for($i=0;$i -lt 4;$i++){
   $tree=Join-Path $appRoot $roots[$i]
   $null=Run ('EXACT_REMOVE_'+$i) $cmd @('/d','/c',('rd /s /q "{0}"' -f $tree))
   if(Test-Path -LiteralPath $tree){throw ('TARGET_TREE_REMAINS='+$roots[$i])}
   Note ('S37_PHYSICAL_REMOVED='+$roots[$i])
  }
  $remain=@(Get-ChildItem -LiteralPath $appRoot -Directory -Force|
    Where-Object {$_.Name -like 'Microsoft.DesktopAppInstaller_*_8wekyb3d8bbwe'})
  if($remain.Count -ne 0){throw ('S37_REMAINING_APPINSTALLER_DIRS='+$remain.Count)}
  Appx 'POST_PHYSICAL' $keep
  $scan=Run 'POST_SCANHEALTH' $dism @('/English',('/Image:'+$mount),'/Cleanup-Image','/ScanHealth')
  if($scan -notmatch 'No component store corruption detected'){throw 'S37_SCANHEALTH_NOT_CLEAN'}
  $chk=Run 'POST_PHYSICAL_CHECKHEALTH' $dism @('/English',('/Image:'+$mount),'/Cleanup-Image','/CheckHealth')
  if($chk -notmatch 'No component store corruption detected'){throw 'S37_CHECKHEALTH_NOT_CLEAN'}
  $packagesAfter=Run 'POST_PHYSICAL_PACKAGES' $dism @('/English',('/Image:'+$mount),'/Get-Packages','/Format:Table')
  if($packagesAfter -match 'Install Pending|Uninstall Pending'){throw 'S37_CBS_PENDING'}
  $carveOK=$true
  Note 'S37_PHYSICAL_PRECOMMIT=PASS_740_REMOVED_APPX9_SCANHEALTH_CLEAN'
  $testOK=$true
  Note 'S37_FULL_PRECOMMIT=PASS'
 }catch{
  Note ('FAIL_CLOSED='+$_.Exception.Message)
 }finally{
  Note '[8/9] CLOSE HIVE AND COMMIT OWNED CANDIDATE ONLY ON FULL PRECOMMIT PASS'
  try{
   if($loaded){
    [GC]::Collect();[GC]::WaitForPendingFinalizers()
    $null=Run 'EMERGENCY_UNLOAD' $reg @('unload',$hive)
    $loaded=$false
   }
  }catch{Note ('HIVE_RELEASE_ERROR='+$_.Exception.Message)}
  try{
   if(-not $loaded -and (Ours @(MountTable))){
    $action=if($testOK -and $carveOK){'/Commit'}else{'/Discard'}
    $null=Run ('UNMOUNT_'+$action.TrimStart('/').ToUpper()) $dism @('/English','/Unmount-Image',('/MountDir:'+$mount),$action)
    if($action -eq '/Commit'){$committed=$true}
   }
   $discharged= -not (Ours @(MountTable))
   Note ('OWNED_RW_MOUNT_RELEASED='+$discharged)
  }catch{Note ('OWNED_UNMOUNT_ERROR='+$_.Exception.Message)}
  try{
   $data=[pscustomobject]@{
    Stage='S37';Scope='OWNED_CLONE_FULL_R4_COMMIT_ON_EXACT_GATES'
    OriginalWim=$source;OriginalSHA256=$sourceSHA
    CandidateWim=$clone;PackageKeepSet=$keep;ExactTargetFamily=$family
    PreAndPostTargetAndProviderRegistry=@($captures.ToArray())
    NativeLifecycleAndPhysicalPrecommitPassed=$testOK
    PhysicalFourRootRemovalConfirmed=$carveOK
    CandidateCommitted=$committed
   }
   [IO.File]::WriteAllText($snapshot,($data|ConvertTo-Json -Depth 8),$utf8)
   $jsonOK=$true
   Note ('EVIDENCE_JSON='+$snapshot)
  }catch{Note ('JSON_EVIDENCE_ERROR='+$_.Exception.Message)}
  try{
   if(-not $committed -and $discharged -and -not $loaded -and [IO.File]::Exists($clone)){
    Remove-Item -LiteralPath $clone -Force -ErrorAction Stop
   }
   $cloneGone= -not [IO.File]::Exists($clone)
   Note ('DISCARD_CANDIDATE_DELETED='+$cloneGone)
  }catch{Note ('CLONE_RELEASE_ERROR='+$_.Exception.Message)}
  Note '[9/9] PROTECTED ORIGINAL SHA AND RETAINED CANDIDATE'
  try{
   if([IO.File]::Exists($source) -and (Get-Item -LiteralPath $source).Length -eq 6509216853L){
    $sourceOK=((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ceq $sourceSHA)
   }
  }catch{Note ('SOURCE_REHASH_ERROR='+$_.Exception.Message)}
  Note ('S31_ORIGINAL_SHA256_UNCHANGED='+$sourceOK)
  $candidateOK=$false
  try{
   if($committed -and $discharged -and [IO.File]::Exists($clone)){
    $bytes=(Get-Item -LiteralPath $clone).Length
    $sha=(Get-FileHash -LiteralPath $clone -Algorithm SHA256).Hash
    $candidateOK=($bytes -gt 0 -and $sha -match '^[A-F0-9]{64}$')
    Note ('S37_CANDIDATE_BYTES='+$bytes)
    Note ('S37_CANDIDATE_SHA256='+$sha)
   }
  }catch{Note ('CANDIDATE_REHASH_ERROR='+$_.Exception.Message)}
  if($testOK -and $carveOK -and $jsonOK -and $committed -and
     $discharged -and $sourceOK -and $candidateOK -and -not $loaded){
   $state='PASS_S37_9711_R4_DISPOSABLE_CANDIDATE_COMMITTED_NOT_RELEASE'
  }
  Note ('PHYSICAL_R4_COMPLETED_ON_CLONE='+$carveOK)
  Note 'SOURCE_WIM_MUTATION=NOT_RUN'
  Note 'FINAL_RELEASE_CERTIFICATION=NOT_GRANTED'
  Note ('RESULT='+$state)
  Write-Host ('MAIN_LOG='+$report)
  Write-Host ('EVIDENCE_JSON='+$snapshot)
  Write-Host ('CANDIDATE_PATH='+$clone)
 }
}
