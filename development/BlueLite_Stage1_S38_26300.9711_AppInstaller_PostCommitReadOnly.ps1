& {
 Set-StrictMode -Version Latest
 $ErrorActionPreference='Stop'
 $PSNativeCommandUseErrorActionPreference=$false
 $source='C:\work\E2E\BlueLite_Stage1_S31_26300.9711_OneDriveAMBER\install.wim'
 $sourceSHA='F52389FA66F8B60D56661C8786EC99409FB95447403B3C6FCBB94121EF8E340B'
 $candidate='C:\work\E2E\BlueLite_Stage1_S37_26300.9711_FullR4Candidate\install.disposable.wim'
 $candidateSHA='A599CF7B7CB44748D738D1F5AD75D1D6C462DD15293755DFFB17F6D2ABE0BE9F'
 $candidateSize=6551362129L
 $s37log='C:\work\logs\BlueLite_Stage1_S37_26300.9711_AppInstaller_FullR4Candidate.txt'
 $s37json='C:\work\logs\BlueLite_Stage1_S37_26300.9711_AppInstaller_FullR4Evidence.json'
 $mount='C:\BL38M'
 $work='C:\work\logs\BlueLite_Stage1_S38_26300.9711_Audit'
 $report='C:\work\logs\BlueLite_Stage1_S38_26300.9711_AppInstaller_PostCommitReadOnly.txt'
 $snapshot='C:\work\logs\BlueLite_Stage1_S38_26300.9711_AppInstaller_PostCommitSnapshot.json'
 $residualCsv='C:\work\logs\BlueLite_Stage1_S38_26300.9711_AppInstaller_AppRepositoryResiduals.csv'
 $hiveAlias='BL38SOFT_'+$PID
 $hive='HKLM\'+$hiveAlias
 $copy=Join-Path $work 'OFFLINE_SOFTWARE_evidence_copy.bin'
 $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
 $reg=Join-Path $env:SystemRoot 'System32\reg.exe'
 $utf8=[Text.UTF8Encoding]::new($false)
 $appFamily='Microsoft.DesktopAppInstaller_8wekyb3d8bbwe'
 $appBundle='Microsoft.DesktopAppInstaller_2024.401.617.0_neutral_~_8wekyb3d8bbwe'
 $prefix='Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore'
 $target=@(
  @{Label='APPLICATIONS';Path=$prefix+'\Applications\'+$appBundle},
  @{Label='CONFIG';Path=$prefix+'\Config\'+$appFamily},
  @{Label='STAGED';Path=$prefix+'\Staged\'+$appFamily},
  @{Label='WOW_CONFIG';Path='WOW6432Node\'+$prefix+'\Config\'+$appFamily},
  @{Label='BROAD_FS';Path='Microsoft\Windows\CurrentVersion\CapabilityAccessManager\Capabilities\broadFilesystemAccess\Apps\'+$appFamily}
 )
 $marker=$prefix+'\Deprovisioned\'+$appFamily
 $provider=[string[]]@(
  'Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Staged\Microsoft.UI.Xaml.2.8_8wekyb3d8bbwe',
  'Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Config\Microsoft.UI.Xaml.2.8_8wekyb3d8bbwe',
  'Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Staged\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe',
  'Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Config\Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe'
 )
 $loaded=$false;$released=$false;$candidateOK=$false;$originalOK=$false
 $preflightOK=$false;$auditOK=$false;$snapshotOK=$false
 $result='HOLD_S38_9711_R4_POSTCOMMIT_READONLY'
 $scopes=[System.Collections.Generic.List[object]]::new()
 $residual=[System.Collections.Generic.List[object]]::new()
 $s37=$null
 $admin=[Security.Principal.WindowsPrincipal]::new(
  [Security.Principal.WindowsIdentity]::GetCurrent()
 ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
 if($PSVersionTable.PSVersion.Major -ne 7 -or -not $admin){throw 'S38_PS7_ADMIN_REQUIRED'}
 if(-not(Test-Path -LiteralPath 'C:\work\logs' -PathType Container)){throw 'LOGS_ROOT_MISSING'}
 foreach($p in @($mount,$work,$report,$snapshot,$residualCsv)){
  if(Test-Path -LiteralPath $p){throw ('S38_OUTPUT_EXISTS_NO_OVERWRITE='+$p)}
 }
 [IO.File]::WriteAllText($report,'',$utf8)
 function Note([string]$v){
  $line=(Get-Date -Format 'HH:mm:ss')+' | '+$v
  Write-Host $line
  [IO.File]::AppendAllText($report,$line+[Environment]::NewLine,$utf8)
 }
 function Pin([string]$label,[string]$path,[string]$sha){
  if(-not [IO.File]::Exists($path)){throw ('S38_EVIDENCE_MISSING='+$label)}
  $got=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
  if($got -cne $sha){throw ('S38_PIN_FAILED='+$label+';'+$got)}
  Note ('PIN_'+$label+'=PASS')
 }
 function NativeDism([string]$label,[string[]]$args){
  $out=@(& $dism @args 2>&1 | ForEach-Object {[string]$_})
  $code=[int]$LASTEXITCODE
  Note ('DISM_'+$label+'_EXIT='+$code)
  if($code -ne 0){throw ('S38_DISM_FAILURE='+$label+';'+$code+';'+($out -join ' | '))}
  return ($out -join [Environment]::NewLine)
 }
 function MountTable{
  $out=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_})
  if($LASTEXITCODE -ne 0){throw 'S38_MOUNT_TABLE_FAILED'}
  return $out
 }
 function Ours([string[]]$table){
  foreach($line in $table){
   $match=[regex]::Match($line,'^\s*Mount Dir\s*:\s*(.*?)\s*$')
   if($match.Success -and $match.Groups[1].Value.Trim() -ieq $mount){return $true}
  }
  return $false
 }
 function Same([string[]]$a,[string[]]$b){
  return ($a.Count -eq $b.Count -and
    @($a|Where-Object {$b -cnotcontains $_}).Count -eq 0 -and
    @($b|Where-Object {$a -cnotcontains $_}).Count -eq 0)
 }
 function ReadKey([string]$label,[string]$relative){
  $key=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(($hiveAlias+'\'+$relative),$false)
  $exists=$null -ne $key
  [string[]]$children=@();[string[]]$names=@()
  if($exists){try{
    $children=@($key.GetSubKeyNames()|Sort-Object)
    $names=@($key.GetValueNames()|Sort-Object)
  }finally{$key.Dispose()}}
  $item=[pscustomobject]@{Label=$label;Path=$relative;Exists=$exists;
    Children=$children;Values=$names}
  $scopes.Add($item)
  Note ('REG_'+$label+';EXISTS='+$exists+';CHILDREN='+$children.Count+';VALUES='+$names.Count)
  return $item
 }
 try{
  Note 'STAGE=S38_26300_9711_APPINSTALLER_POSTCOMMIT_INDEPENDENT_READONLY'
  Note 'MODE=SOURCE_AND_CANDIDATE_SHA_PIN_READONLY_WIM_COPIED_SOFTWARE'
  Note '[1/7] VALIDATE S37 REPORT/JSON AND TWO IMMUTABLE WIMS'
  Pin 'S37_REPORT' $s37log '069174FC422357D9A12DD64CB9B8EB2C9BD2C947E44C5360F0565DC9E7C808F7'
  Pin 'S37_JSON' $s37json '22C4968E0B7238CADF8614D96E6A70A3F1466495E466BA79FD68B74469980AF4'
  $log=[IO.File]::ReadAllText($s37log)
  foreach($anchor in @('RESULT=PASS_S37_9711_R4_DISPOSABLE_CANDIDATE_COMMITTED_NOT_RELEASE',
    'NATIVE_UNMOUNT_COMMIT_EXIT=0','OWNED_RW_MOUNT_RELEASED=True',
    'S37_PHYSICAL_PRECOMMIT=PASS_740_REMOVED_APPX9_SCANHEALTH_CLEAN',
    'S31_ORIGINAL_SHA256_UNCHANGED=True',
    'S37_CANDIDATE_SHA256='+$candidateSHA)){
   if(-not $log.Contains($anchor)){throw ('S37_REPORT_ANCHOR_MISSING='+$anchor)}
  }
  $s37=Get-Content -LiteralPath $s37json -Raw -Encoding utf8|ConvertFrom-Json
  if(-not $s37.CandidateCommitted -or -not $s37.NativeLifecycleAndPhysicalPrecommitPassed -or
     -not $s37.PhysicalFourRootRemovalConfirmed -or
     $s37.CandidateWim -cne $candidate -or
     @($s37.PackageKeepSet).Count -ne 9){throw 'S37_JSON_CONTRACT_FAIL'}
  Pin 'S31_IMMUTABLE_WIM' $source $sourceSHA
  if(-not [IO.File]::Exists($candidate) -or
    (Get-Item -LiteralPath $candidate).Length -ne $candidateSize){
   throw 'S37_COMMITTED_CANDIDATE_SIZE_OR_MISSING'
  }
  Pin 'S37_COMMITTED_WIM' $candidate $candidateSHA
  if(@(MountTable|Where-Object {$_ -match '^\s*Mount Dir\s*:'}).Count -ne 0){
   throw 'S38_EXISTING_WIM_MOUNT_NO_ACTION'
  }
  $null=@(& $reg query $hive 2>&1)
  if($LASTEXITCODE -eq 0){throw 'S38_HIVE_ALIAS_ALREADY_PRESENT'}
  $preflightOK=$true
  Note '[2/7] OWNED SHORT READONLY MOUNT'
  $null=New-Item -ItemType Directory -Path $mount
  $null=NativeDism 'MOUNT_RO' @('/English','/Mount-Image',('/ImageFile:'+$candidate),
    '/Index:1',('/MountDir:'+$mount),'/ReadOnly')
  $owner=@{}
  foreach($line in @(MountTable)){
   $m=[regex]::Match([string]$line,
     '^\s*(Mount Dir|Image File|Image Index|Mounted Read/Write|Status)\s*:\s*(.*?)\s*$')
   if($m.Success){
    if($owner.ContainsKey($m.Groups[1].Value)){throw 'S38_DUPLICATE_MOUNT_FIELD'}
    $owner[$m.Groups[1].Value]=$m.Groups[2].Value.Trim()
   }
  }
  if($owner.Count -ne 5 -or $owner['Mount Dir'] -ine $mount -or
     $owner['Image File'] -ine $candidate -or $owner['Image Index'] -ne '1' -or
     $owner['Mounted Read/Write'] -ine 'No' -or $owner['Status'] -ine 'Ok'){
   throw 'S38_READONLY_MOUNT_OWNER_NOT_PROVEN'
  }
  Note 'S38_READONLY_MOUNT_OWNER=PASS_5_FIELDS'
  Note '[3/7] INDEPENDENT APPX IDENTITY + ABSENT PHYSICAL ROOTS'
  $apps=NativeDism 'PROVISIONED' @('/English',('/Image:'+$mount),'/Get-ProvisionedAppxPackages')
  $nativeNames=[string[]]@([regex]::Matches($apps,'(?im)^\s*PackageName\s*:\s*(\S+)\s*$')|
    ForEach-Object {$_.Groups[1].Value})
  $expected=[string[]]@($s37.PackageKeepSet)
  if(-not(Same $nativeNames $expected)){throw ('S38_PROVISIONED_EXACT_NINE_DRIFT='+($nativeNames -join '|'))}
  Note 'S38_PROVISIONED_APPX=PASS_NINE_EXACT'
  $windowsApps=Join-Path $mount 'Program Files\WindowsApps'
  $dirs=@(Get-ChildItem -LiteralPath $windowsApps -Directory -Force -ErrorAction Stop|
    Where-Object {$_.Name.StartsWith('Microsoft.DesktopAppInstaller_',[StringComparison]::OrdinalIgnoreCase)})
  if($dirs.Count -ne 0){throw ('S38_WINDOWS_APPS_RESIDUAL_APPINSTALLER_ROOTS='+$dirs.Count)}
  Note 'S38_APPINSTALLER_WINDOWS_APPS_ROOTS=PASS_ZERO'
  Note '[4/7] APPREPOSITORY FOCUSED NAME-RESIDUAL INVENTORY'
  $repository=Join-Path $mount 'ProgramData\Microsoft\Windows\AppRepository'
  if(-not(Test-Path -LiteralPath $repository -PathType Container)){
   throw 'S38_APPREPOSITORY_LOCATION_MISSING'
  }
  $repoObjects=0
  Get-ChildItem -LiteralPath $repository -Recurse -Force -ErrorAction Stop|
   ForEach-Object {
    $repoObjects++
    if($_.Name.IndexOf('DesktopAppInstaller',[StringComparison]::OrdinalIgnoreCase) -ge 0){
      $kind=if($_.PSIsContainer){'Directory'}else{'File'}
      $residual.Add([pscustomobject]@{Scope='APPREPOSITORY_FILENAME';Path=$_.FullName.Substring($mount.Length);Type=$kind})
    }
   }
  Note ('APPREPOSITORY_ITEMS_ENUMERATED='+$repoObjects)
  Note ('APPREPOSITORY_FILENAME_RESIDUAL_COUNT='+$residual.Count)
  if($residual.Count -gt 0){
   $residual|Export-Csv -LiteralPath $residualCsv -NoTypeInformation -Encoding utf8
   Note ('RESIDUAL_INVENTORY_CSV='+$residualCsv)
  }
  Note 'RESIDUAL_SCAN_SCOPE=FILENAME_ONLY_NOT_BINARY_OR_ALL_REGISTRY'
  Note '[5/7] COPIED OFFLINE SOFTWARE, EXACT REGISTRY POSTSTATE'
  $null=New-Item -ItemType Directory -Path $work
  Copy-Item -LiteralPath (Join-Path $mount 'Windows\System32\config\SOFTWARE') -Destination $copy -ErrorAction Stop
  Note ('SOFTWARE_COPY_SHA256='+(Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash)
  $load=@(& $reg load $hive $copy 2>&1|ForEach-Object {[string]$_})
  $ec=[int]$LASTEXITCODE
  Note ('COPIED_HIVE_LOAD_EXIT='+$ec)
  if($ec -ne 0){throw ('S38_COPY_HIVE_LOAD_FAILED='+$($load -join '|'))}
  $loaded=$true
  foreach($scope in $target){
   $r=ReadKey ('TARGET_'+$scope.Label) $scope.Path
   if($r.Exists){throw ('S38_TARGET_RESIDUAL_KEY='+$scope.Label)}
  }
  $mark=ReadKey 'DEPROVISIONED_MARKER' $marker
  if(-not $mark.Exists -or $mark.Children.Count -ne 0 -or $mark.Values.Count -ne 0){
   throw 'S38_MARKER_NOT_EXACT_EMPTY_LEAF'
  }
  $prev=@($s37.PreAndPostTargetAndProviderRegistry|Where-Object {$_.Label -eq 'POST_PROVIDER'})
  if($prev.Count -ne 4 -or $provider.Count -ne 4){throw 'S37_PROVIDER_EVIDENCE_COUNT_DRIFT'}
  foreach($path in $provider){
   $present=ReadKey 'PRESERVED_PROVIDER' $path
   $previous=@($prev|Where-Object {$_.Path -ceq $path})
   if($previous.Count -ne 1 -or -not $present.Exists -or
      -not(Same ([string[]]$present.Children) ([string[]]$previous[0].Children)) -or
      -not(Same ([string[]]$present.Values) ([string[]]$previous[0].Values))){
    throw ('S38_PROVIDER_POSTCOMMIT_DRIFT='+$path)
   }
  }
  Note 'S38_REGISTRY_APPINSTALLER_POSTSTATE=PASS_FIVE_ABSENT_EMPTY_MARKER_FOUR_PROVIDERS'
  [GC]::Collect();[GC]::WaitForPendingFinalizers()
  $unload=@(& $reg unload $hive 2>&1|ForEach-Object {[string]$_})
  $unloadExit=[int]$LASTEXITCODE
  Note ('COPIED_HIVE_UNLOAD_EXIT='+$unloadExit)
  if($unloadExit -ne 0){throw ('S38_COPY_HIVE_UNLOAD_FAILED='+($unload -join '|'))}
  $loaded=$false
  Remove-Item -LiteralPath $copy -Force -ErrorAction Stop
  Note 'OWNED_DISPOSABLE_SOFTWARE_COPY_REMOVED=TRUE'
  Note '[6/7] POSTCOMMIT CBS INDEPENDENT READONLY HEALTH'
  $check=NativeDism 'CHECKHEALTH' @('/English',('/Image:'+$mount),'/Cleanup-Image','/CheckHealth')
  if($check -notmatch 'No component store corruption detected'){throw 'S38_CHECKHEALTH_NOT_CLEAN'}
  $scan=NativeDism 'SCANHEALTH' @('/English',('/Image:'+$mount),'/Cleanup-Image','/ScanHealth')
  if($scan -notmatch 'No component store corruption detected'){throw 'S38_SCANHEALTH_NOT_CLEAN'}
  $packages=NativeDism 'PACKAGES' @('/English',('/Image:'+$mount),'/Get-Packages','/Format:Table')
  if($packages -match 'Install Pending|Uninstall Pending'){throw 'S38_SERVICING_PENDING'}
  $auditOK=$true
  Note 'S38_READONLY_POSTCOMMIT_GATES=PASS'
 }catch{
  Note ('FAIL_CLOSED='+$_.Exception.Message)
 }finally{
  Note '[7/7] RELEASE TEMP COPIED HIVE, DISCARD RO MOUNT, VERIFY SOURCE & CANDIDATE'
  try{
   if($loaded){
    [GC]::Collect();[GC]::WaitForPendingFinalizers()
    $o=@(& $reg unload $hive 2>&1|ForEach-Object {[string]$_})
    $ec=[int]$LASTEXITCODE
    Note ('EMERGENCY_HIVE_UNLOAD_EXIT='+$ec)
    if($ec -eq 0){$loaded=$false}
   }
  }catch{Note ('HIVE_RELEASE_ERROR='+$_.Exception.Message)}
  try{
   if(-not $loaded -and [IO.File]::Exists($copy)){Remove-Item -LiteralPath $copy -Force -ErrorAction Stop}
  }catch{Note ('COPY_RELEASE_ERROR='+$_.Exception.Message)}
  try{
   if(-not $loaded -and (Ours @(MountTable))){
    $null=NativeDism 'DISCARD_RO' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Discard')
   }
   $released= -not(Ours @(MountTable))
   Note ('OWNED_READONLY_MOUNT_RELEASED='+$released)
  }catch{Note ('S38_RO_DISCARD_ERROR='+$_.Exception.Message)}
  try{
   $kept=@()
   if($null -ne $s37){$kept=@($s37.PackageKeepSet)}
   $data=[pscustomobject]@{
    Stage='S38';Scope='INDEPENDENT_COMMITTED_CANDIDATE_READONLY'
    CandidateWim=$candidate;CandidateSHA256=$candidateSHA;CandidateSize=$candidateSize
    OriginalWim=$source;OriginalSHA256=$sourceSHA
    ExpectedNinePackages=$kept
    InspectedOfflineRegistry=@($scopes.ToArray())
    AppRepositoryFilenameMatches=@($residual.ToArray())
    ReadonlyAuditSucceeded=$auditOK
    FinalReleaseCertificateGranted=$false
   }
   [IO.File]::WriteAllText($snapshot,($data|ConvertTo-Json -Depth 9),$utf8)
   $snapshotOK=$true
   Note ('S38_EVIDENCE_JSON='+$snapshot)
  }catch{Note ('S38_SNAPSHOT_ERROR='+$_.Exception.Message)}
  try{
   if($released -and [IO.File]::Exists($candidate) -and
      (Get-Item -LiteralPath $candidate).Length -eq $candidateSize){
    $candidateOK=((Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash -ceq $candidateSHA)
   }
  }catch{Note ('CANDIDATE_SHA_RECHECK_ERROR='+$_.Exception.Message)}
  try{
   if([IO.File]::Exists($source) -and (Get-Item -LiteralPath $source).Length -eq 6509216853L){
    $originalOK=((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ceq $sourceSHA)
   }
  }catch{Note ('S31_SHA_RECHECK_ERROR='+$_.Exception.Message)}
  Note ('S37_COMMITTED_CANDIDATE_SHA_UNCHANGED='+$candidateOK)
  Note ('S31_ORIGINAL_SHA_UNCHANGED='+$originalOK)
  if($preflightOK -and $auditOK -and $snapshotOK -and
    -not $loaded -and $released -and $candidateOK -and $originalOK){
   $result='PASS_S38_9711_APPINSTALLER_INDEPENDENT_POSTCOMMIT_READONLY'
  }
  Note 'S37_CANDIDATE_MODIFICATION=NOT_RUN'
  Note 'FINAL_RELEASE_CERTIFICATION=NOT_GRANTED'
  Note ('RESULT='+$result)
  Write-Host ('MAIN_LOG='+$report)
  Write-Host ('EVIDENCE_JSON='+$snapshot)
  if([IO.File]::Exists($residualCsv)){Write-Host ('RESIDUAL_CSV='+$residualCsv)}
 }
}
