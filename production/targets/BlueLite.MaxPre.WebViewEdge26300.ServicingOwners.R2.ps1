# BlueLite MAX_PRE WebView/Edge R2 - bounded servicing/manifest metadata, existing S37, readonly.
# NOT a removal engine or a package/health certification.
& {
  $ErrorActionPreference='Stop'
  Set-StrictMode -Version Latest
  if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_PS7_REQUIRED'}
  $principal=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
  if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'BL_ADMIN_REQUIRED'}
  $image='C:\work\E2E\BlueLite_Stage1_S37_26300.9711_FullR4Candidate\install.disposable.wim'
  $imageSHA='A599CF7B7CB44748D738D1F5AD75D1D6C462DD15293755DFFB17F6D2ABE0BE9F'
  $r1txt='C:\work\logs\BlueLite_MAXPRE_WebViewEdge_26300.9711_TargetGate_R1.txt'
  $r1txtSHA='29535E0700CCCD229D2792A8CAB6E895130BC19DE8A33CA783AF0CE9F52DCB22'
  $r1csv='C:\work\logs\BlueLite_MAXPRE_WebViewEdge_26300.9711_Owners_R1.csv'
  $r1csvSHA='896ADB7044F7D77C234F1C898D4956C143289C1DEAB58D0099454570CB3417FA'
  $mount='C:\work\MWV26300R2'
  $log='C:\work\logs\BlueLite_MAXPRE_WebViewEdge_26300.9711_ServicingOwners_R2.txt'
  $csv='C:\work\logs\BlueLite_MAXPRE_WebViewEdge_26300.9711_ServicingMetadata_R2.csv'
  $owners=@(
    'amd64_microsoft-edge-webview_31bf3856ad364e35_10.0.26100.1_none_8fe1c356f34a19ca',
    'amd64_microsoft-edge-webview_31bf3856ad364e35_10.0.26100.9711_none_2e9083253adbaceb'
  )
  $utf8=[Text.UTF8Encoding]::new($false)
  foreach($p in @($log,$csv,$mount)){
    if(Test-Path -LiteralPath $p){throw ('BL_R2_PATH_ALREADY_EXISTS='+$p)}
  }
  if(-not(Test-Path -LiteralPath 'C:\work\logs' -PathType Container)){throw 'BL_LOG_ROOT_MISSING'}
  foreach($o in @(@{Path=$r1txt;Size=6619L;SHA=$r1txtSHA},@{Path=$r1csv;Size=3462L;SHA=$r1csvSHA})){
    $item=Get-Item -LiteralPath $o.Path -ErrorAction Stop
    if($item.PSIsContainer -or $item.Length -ne $o.Size -or
      (Get-FileHash -LiteralPath $o.Path -Algorithm SHA256).Hash -cne $o.SHA){
      throw ('BL_R1_EVIDENCE_CHANGED='+$o.Path)
    }
  }
  $rowsR1=@(Import-Csv -LiteralPath $r1csv -Encoding utf8)
  if($rowsR1.Count -ne 21 -or
    @($rowsR1|Where-Object {$_.OwnerClass -eq 'EDGE_WEBVIEW_FAMILY'}).Count -ne 2 -or
    @($rowsR1|Where-Object {$_.OwnerName -in $owners}).Count -ne 2 -or
    (@($rowsR1|Measure-Object -Property ReparseFiles -Sum)[0].Sum -ne 754)){
    throw 'BL_R1_CSV_TOPOLOGY_DRIFT'
  }
  [IO.File]::WriteAllText($log,'',$utf8)
  function Note([string]$line){
    Write-Host $line
    [IO.File]::AppendAllText($log,$line+[Environment]::NewLine,$utf8)
  }
  function NativeDism([string]$tag,[string[]]$dismArguments){
    $exe=Join-Path $env:SystemRoot 'System32\dism.exe'
    $output=@(& $exe @dismArguments 2>&1|ForEach-Object {[string]$_})
    $rc=[int]$LASTEXITCODE
    $body=$output -join [Environment]::NewLine
    if($rc -ne 0 -or $body -notmatch '(?i)The operation completed successfully\.' -or
       $body -match '(?im)^\s*Error\s*:'){
      throw ('BL_DISM_'+$tag+'_EXIT_'+$rc)
    }
    return $body
  }
  $result='HOLD_WEBVIEW_EDGE_R2_READONLY'
  $attempted=$false
  $mounted=$false
  $created=$false
  try {
    Note 'BLUELITE_MAXPRE_WEBVIEW_EDGE_S37_R2_SERVICING_METADATA_READONLY'
    Note ('PIN_R1_TXT=PASS;'+$r1txtSHA)
    Note ('PIN_R1_CSV=PASS;'+$r1csvSHA)
    $info=Get-Item -LiteralPath $image -Force -ErrorAction Stop
    if($info.PSIsContainer -or $info.Length -ne 6551362129L -or
       ($info.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){
      throw 'BL_S37_IMAGE_METADATA_DRIFT'
    }
    if((Get-FileHash -LiteralPath $image -Algorithm SHA256).Hash -cne $imageSHA){
      throw 'BL_S37_IMAGE_SHA_DRIFT'
    }
    Note ('PIN_S37_WIM=PASS;'+$imageSHA)
    $before=NativeDism 'PRE_MOUNT_LIST' @('/English','/Get-MountedWimInfo')
    if(-not $before.Contains('No mounted images found.') -or $before -match '(?im)^\s*Mount Dir\s*:'){
      throw 'BL_PREEXISTING_DISM_MOUNT'
    }
    $reg=Join-Path $env:SystemRoot 'System32\reg.exe'
    $hives=@(& $reg query 'HKLM\SYSTEM\CurrentControlSet\Control\hivelist' 2>&1|ForEach-Object {[string]$_})
    if([int]$LASTEXITCODE -ne 0 -or
      @($hives|Where-Object {$_ -match '(?i)^\s*\\REGISTRY\\MACHINE\\(BL[0-9]|BlueLite|FB[0-9])'}).Count -ne 0){
      throw 'BL_OFFLINE_HIVE_ALIAS_ALREADY_LOADED'
    }
    Note 'PRE_DISM_MOUNTS_AND_BLUE_HIVES_ZERO=PASS'
    [void][IO.Directory]::CreateDirectory($mount)
    $created=$true
    $attempted=$true
    $null=NativeDism 'MOUNT_RO' @('/English','/Mount-Image',('/ImageFile:'+$image),'/Index:1',('/MountDir:'+$mount),'/ReadOnly')
    $mounted=$true
    Note 'S37_NATIVE_MOUNT_READONLY=PASS'
    $manifestRoot=Join-Path $mount 'Windows\WinSxS\Manifests'
    $catalogRoot=Join-Path $mount 'Windows\WinSxS\Catalogs'
    $packageRoot=Join-Path $mount 'Windows\servicing\Packages'
    foreach($root in @($manifestRoot,$catalogRoot,$packageRoot)){
      if(-not(Test-Path -LiteralPath $root -PathType Container)){throw ('BL_OFFLINE_METADATA_ROOT_MISSING='+$root)}
      $dirInfo=Get-Item -LiteralPath $root -Force
      if(($dirInfo.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){
        throw ('BL_METADATA_DIRECTORY_REPARSE='+$root)
      }
    }
    $items=[System.Collections.Generic.List[object]]::new()
    foreach($owner in $owners){
      foreach($kind in @('MANIFEST','CATALOG')){
        $path=if($kind -eq 'MANIFEST'){
          Join-Path $manifestRoot ($owner+'.manifest')
        }else{
          Join-Path $catalogRoot ($owner+'.cat')
        }
        $present=Test-Path -LiteralPath $path -PathType Leaf
        [long]$size=0
        $isReparse=$false
        if($present){
          $meta=Get-Item -LiteralPath $path -Force -ErrorAction Stop
          $size=[long]$meta.Length
          $isReparse=(($meta.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)
        }
        $items.Add([pscustomobject]@{
          Kind=$kind;Identity=($owner+$(if($kind -eq 'MANIFEST'){'.manifest'}else{'.cat'}))
          Present=$present;LengthMetadata=$size;Reparse=$isReparse
          Scope='EXACT_COMPONENT_ID';ContentRead=$false
        })
        Note ('EXACT_'+$kind+'='+$owner+';PRESENT='+$present+';REPARSE='+$isReparse+';LENGTH_METADATA='+$size)
      }
    }
    # Package names are metadata candidates, not ownership proof.
    $mums=@(Get-ChildItem -LiteralPath $packageRoot -File -Filter '*.mum' -Force -ErrorAction Stop|
      Where-Object {$_.Name -match '(?i)(webview|edge)' }|Sort-Object Name)
    if($mums.Count -gt 200){throw ('BL_PACKAGE_SCOPE_LIMIT='+$mums.Count)}
    foreach($mum in $mums){
      $items.Add([pscustomobject]@{
        Kind='SERVICING_MUM_NAME';Identity=$mum.Name;Present=$true
        LengthMetadata=[long]$mum.Length
        Reparse=(($mum.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)
        Scope='NAME_MATCH_ONLY';ContentRead=$false
      })
      Note ('SERVICING_MUM_NAME='+$mum.Name+';REPARSE='+
        (($mum.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)+
        ';LENGTH_METADATA='+$mum.Length)
    }
    $caps=NativeDism 'CAPABILITY_NAMES' @('/English',('/Image:'+$mount),'/Get-Capabilities')
    $pkgs=NativeDism 'PACKAGE_NAMES' @('/English',('/Image:'+$mount),'/Get-Packages')
    $capMatches=@($caps -split '\r?\n'|Where-Object {$_ -match '(?i)^\s*Capability Identity\s*:' -and $_ -match '(?i)(webview|edge)'})
    $pkgMatches=@($pkgs -split '\r?\n'|Where-Object {$_ -match '(?i)^\s*Package Identity\s*:' -and $_ -match '(?i)(webview|edge)'})
    Note ('DISM_WEBVIEW_EDGE_CAPABILITY_IDENTITIES='+$capMatches.Count)
    foreach($line in $capMatches){Note ('CAPABILITY='+$line.Trim())}
    Note ('DISM_WEBVIEW_EDGE_PACKAGE_IDENTITIES='+$pkgMatches.Count)
    foreach($line in $pkgMatches){Note ('PACKAGE='+$line.Trim())}
    $items|Export-Csv -LiteralPath $csv -Encoding utf8 -NoTypeInformation -ErrorAction Stop
    Note ('EXACT_MANIFEST_CATALOG_METADATA_ROWS=4;SERVICING_MUM_NAME_MATCHES='+$mums.Count)
    Note ('CSV_ROWS='+$items.Count)
    Note 'CBS_PACKAGE_OWNER_EDGES=UNRESOLVED;NO_MUM_CONTENT_DEREFERENCE'
    Note 'NO_PACKAGE_OR_CAPABILITY_NAME_MATCH_DOES_NOT_PROVE_PAYLOAD_REMOVABLE_OR_ABSENT'
    Note 'REGISTRY_R13_RUNTIME_EXECUTION_ALLOWED=FALSE'
    Note 'NO_WIM_COPY_NO_SERVICING_MUTATION_NO_CBS_HEALTH_OR_PENDING_CERTIFICATION'
    $result='PASS_WEBVIEW_EDGE_S37_R2_SERVICING_METADATA_READONLY_ONLY'
  }catch{
    Note ('FAIL_CLOSED='+$_.Exception.Message)
  }finally{
    if($attempted){
      try {
        $state=@(& (Join-Path $env:SystemRoot 'System32\dism.exe') /English /Get-MountedWimInfo 2>&1|
          ForEach-Object {[string]$_}) -join [Environment]::NewLine
        if($mounted -or $state.Contains($mount)){
          $null=NativeDism 'DISCARD_RO' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Discard')
          Note 'NATIVE_READONLY_DISCARD=PASS'
        }
        $after=NativeDism 'POST_MOUNT_LIST' @('/English','/Get-MountedWimInfo')
        if(-not $after.Contains('No mounted images found.')){throw 'BL_DISM_MOUNTS_REMAIN'}
        $mounted=$false
        Note 'POST_DISM_MOUNTS_ZERO=PASS'
      }catch{
        $mounted=$true
        $result='HOLD_R2_MOUNT_HANDLE_REVIEW'
        Note ('CRITICAL_MOUNT_CLEANUP_HOLD='+$_.Exception.Message)
      }
    }
    if($created -and -not $mounted){
      try{
        if((Get-ChildItem -LiteralPath $mount -Force -ErrorAction Stop|Measure-Object).Count -eq 0){
          [IO.Directory]::Delete($mount,$false)
          Note 'OWNED_EMPTY_MOUNT_DIR_REMOVED=PASS'
        }else{Note 'OWNED_MOUNT_FOLDER_NONEMPTY_KEEP_FOR_REVIEW'}
      }catch{Note ('OWNED_FOLDER_CLEANUP_HOLD='+$_.Exception.Message)}
    }
    Note ('RESULT='+$result)
    Note ('REPORT='+$log)
    Note ('METADATA_CSV='+$csv)
    Note 'S31_S37_IMMUTABLE;NO_CLONE_NO_MUTATION'
  }
  if($result -ne 'PASS_WEBVIEW_EDGE_S37_R2_SERVICING_METADATA_READONLY_ONLY'){
    throw 'BL_R2_SCOPED_SERVICING_METADATA_FAILED'
  }
}
