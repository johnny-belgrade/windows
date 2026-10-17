& {
 Set-StrictMode -Version Latest
 $ErrorActionPreference='Stop'
 $PSNativeCommandUseErrorActionPreference=$false
 $wim='C:\work\E2E\BlueLite_Stage1_S31_26300.9711_OneDriveAMBER\install.wim'
 $log32='C:\work\logs\BlueLite_Stage1_S32_26300.9711_AppInstaller_ReadOnlyGate.txt'
 $csv32='C:\work\logs\BlueLite_Stage1_S32_26300.9711_AppInstaller_PhysicalInventory.csv'
 $report='C:\work\logs\BlueLite_Stage1_S33_26300.9711_AppInstaller_NativeOwnerGate.txt'
 $anomalyCsv='C:\work\logs\BlueLite_Stage1_S33_26300.9711_AppInstaller_OwnerAnomalies.csv'
 $mount='C:\BL33M'
 $expectedWim='F52389FA66F8B60D56661C8786EC99409FB95447403B3C6FCBB94121EF8E340B'
 $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
 $fsutil=Join-Path $env:SystemRoot 'System32\fsutil.exe'
 $u=[Text.UTF8Encoding]::new($false)
 $ok=$false; $released=$false; $same=$false
 $result='HOLD_S33_READONLY_APPINSTALLER_NATIVE_OWNER'
 $anomalies=[System.Collections.Generic.List[object]]::new()
 $roots=@(
  [pscustomobject]@{N='Microsoft.DesktopAppInstaller_1.21.10121.0_neutral_split.scale-100_8wekyb3d8bbwe';C=28;B=36084L},
  [pscustomobject]@{N='Microsoft.DesktopAppInstaller_1.21.10121.0_neutral_split.scale-125_8wekyb3d8bbwe';C=28;B=39330L},
  [pscustomobject]@{N='Microsoft.DesktopAppInstaller_1.21.10121.0_x64__8wekyb3d8bbwe';C=681;B=148010477L},
  [pscustomobject]@{N='Microsoft.DesktopAppInstaller_2024.401.617.0_neutral_~_8wekyb3d8bbwe';C=3;B=51837L}
 )
 $admin=[Security.Principal.WindowsPrincipal]::new(
  [Security.Principal.WindowsIdentity]::GetCurrent()
 ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
 if($PSVersionTable.PSVersion.Major -ne 7 -or -not $admin){throw 'PS7_ADMIN_REQUIRED'}
 if(-not(Test-Path 'C:\work\logs' -PathType Container)){throw 'LOGS_DIRECTORY_MISSING'}
 foreach($item in @($report,$anomalyCsv,$mount)){
  if(Test-Path -LiteralPath $item){throw "OWNED_PATH_ALREADY_EXISTS=$item"}
 }
 [IO.File]::WriteAllText($report,'',$u)
 function Note([string]$v){
  $line="$(Get-Date -Format 'HH:mm:ss') | $v"
  Write-Host $line
  [IO.File]::AppendAllText($report,$line+[Environment]::NewLine,$u)
 }
 function Pin([string]$tag,[string]$file,[string]$hash){
  if(-not(Test-Path -LiteralPath $file -PathType Leaf)){throw "PIN_MISSING=$tag"}
  $got=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
  if($got -cne $hash){throw "PIN_SHA_DRIFT=$tag;$got"}
  Note "PIN_$tag=PASS"
 }
 function MountTable {
  $out=@(& $dism /English /Get-MountedWimInfo 2>&1 | ForEach-Object {[string]$_})
  if($LASTEXITCODE -ne 0){throw 'MOUNT_TABLE_FAILED'}
  return $out
 }
 function Mine([string[]]$lines){
  foreach($line in $lines){
   $m=[regex]::Match($line,'^\s*Mount Dir\s*:\s*(.*?)\s*$')
   if($m.Success -and $m.Groups[1].Value.Trim() -ieq $mount){return $true}
  }
  return $false
 }
 function NativeDism([string]$label,[string[]]$arguments){
  $out=@(& $dism @arguments 2>&1 | ForEach-Object {[string]$_})
  $ec=[int]$LASTEXITCODE
  Note "DISM_$($label)_EXIT=$ec"
  if($ec -ne 0){throw "DISM_$($label)_FAIL=$ec;$($out -join ' | ')"}
  return ($out -join [Environment]::NewLine)
 }
 try{
  Note 'STAGE=S33_26300_9711_APPINSTALLER_NATIVE_OWNER'
  Note 'MODE=READONLY_SHORT_MOUNT_NO_REGISTRY_NO_MUTATION'
  Note '[1/5] EXACT PREVIOUS REPORT, CSV, WIM'
  Pin 'S32_LOG' $log32 '0F8501CAE72CEDBE7450E0F4025F6E6E22C3564EBEC3751E03149BB6A750D5E2'
  Pin 'S32_CSV' $csv32 '5828C1540CC39B06CB73DB00C5D4604752A2D3BF9BB0039A7C11F005DB8B5B95'
  $text32=[IO.File]::ReadAllText($log32)
  foreach($marker in @('RESULT=PASS_S32_9711_READONLY_APPINSTALLER_PREOWNER_GATE',
     'S31_WIM_UNCHANGED=True','HARDLINK_OWNER_CLOSURE=NOT_CERTIFIED')){
   if(-not $text32.Contains($marker)){throw "S32_MARKER_NOT_FOUND=$marker"}
  }
  if(-not(Test-Path -LiteralPath $wim -PathType Leaf) -or
      (Get-Item -LiteralPath $wim).Length -ne 6509216853L){throw 'S31_WIM_LENGTH_DRIFT'}
  Pin 'S31_WIM' $wim $expectedWim
  $csv=@(Import-Csv -LiteralPath $csv32 -Encoding utf8)
  if($csv.Count -ne 740){throw "CSV_COUNT_DRIFT=$($csv.Count)"}
  foreach($col in @('Root','Relative','BytesLogical','ReparsePoint','Attributes')){
   if($csv[0].PSObject.Properties.Name -cnotcontains $col){throw "CSV_COLUMN_MISSING=$col"}
  }
  $expectedRoots=@($roots | ForEach-Object {$_.N})
  $seen=[System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  [long]$total=0
  foreach($r in $csv){
   if($expectedRoots -cnotcontains $r.Root -or
      [string]::IsNullOrWhiteSpace($r.Relative) -or $r.Relative.StartsWith('\') -or
      $r.Relative.StartsWith('/') -or $r.Relative.Contains(':') -or
      @($r.Relative -split '\\' | Where-Object {$_ -eq '..' -or $_ -eq '.'}).Count -ne 0 -or
      $r.ReparsePoint -cne 'True' -or
      $r.Attributes -cne 'Archive, SparseFile, ReparsePoint'){
    throw "CSV_IDENTITY_DRIFT=$($r.Root);$($r.Relative)"
   }
   if(-not $seen.Add("$($r.Root)\$($r.Relative)")){throw 'CSV_DUPLICATE'}
   [long]$size=0
   if(-not [long]::TryParse($r.BytesLogical,[ref]$size) -or $size -lt 0){throw 'CSV_BAD_SIZE'}
   $total+=$size
  }
  if($total -ne 148137728L){throw 'CSV_SIZE_DRIFT'}
  foreach($spec in $roots){
   $group=@($csv | Where-Object {$_.Root -ceq $spec.N})
   [long]$sum=0
   foreach($r in $group){$sum+=[long]$r.BytesLogical}
   if($group.Count -ne $spec.C -or $sum -ne $spec.B){throw "CSV_ROOT_DRIFT=$($spec.N)"}
  }
  if(@(MountTable | Where-Object {$_ -match '^\s*Mount Dir\s*:'}).Count -ne 0){
   throw 'FOREIGN_OR_PREEXISTING_MOUNT'
  }
  Note 'PREFLIGHT=PASS_740_FILES_4_ROOTS'
  Note '[2/5] READONLY SHORT MOUNT'
  $null=New-Item -ItemType Directory -Path $mount
  $null=NativeDism 'MOUNT' @('/English','/Mount-Image',"/ImageFile:$wim",
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
   throw 'READONLY_MOUNT_5_FIELD_NOT_PROVEN'
  }
  Note 'MOUNT_READONLY_OWNER=PASS_5_FIELDS'
  Note '[3/5] NATIVE EXACT 740 HARDLINK OWNERS'
  $appRoot=Join-Path $mount 'Program Files\WindowsApps'
  $foundRoots=@(Get-ChildItem -LiteralPath $appRoot -Directory -Force |
    Where-Object {$_.Name -like 'Microsoft.DesktopAppInstaller_*_8wekyb3d8bbwe'})
  if($foundRoots.Count -ne 4 -or
     @($foundRoots | Where-Object {$expectedRoots -cnotcontains $_.Name}).Count -ne 0){
   throw 'CURRENT_ROOTS_CHANGED'
  }
  $checked=0
  foreach($r in $csv){
   $full=Join-Path (Join-Path $appRoot $r.Root) $r.Relative
   $reason='';$raw=''
   if(-not [IO.File]::Exists($full)){
    $reason='FILE_NOT_PRESENT'
   }else{
    $info=Get-Item -LiteralPath $full -Force
    if($info.Length -ne [long]$r.BytesLogical -or
        (($info.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0)){
     $reason='FILE_SIZE_OR_REPARSE_DRIFT'
    }else{
     $native=@(& $fsutil hardlink list $full 2>&1 | ForEach-Object {[string]$_})
     $code=[int]$LASTEXITCODE
     $lines=@($native | ForEach-Object {$_.Trim()} | Where-Object {$_.Length -gt 0})
     $raw=$lines -join ' | '
     if($code -ne 0 -or $lines.Count -eq 0){$reason='FSUTIL_FAILED'}
     elseif($lines.Count -ne 1){$reason='MULTIPLE_LINKS'}
     else{
      $returned=$lines[0]
      if($returned -match '^[a-zA-Z]:\\'){$returned=$returned.Substring(2)}
      if($returned -ine $full.Substring(2)){$reason='FOREIGN_LINK'}
     }
    }
   }
   if($reason.Length -gt 0){
    $anomalies.Add([pscustomobject]@{Root=$r.Root;Relative=$r.Relative;Reason=$reason;Output=$raw})
   }
   $checked++
   if(($checked % 100) -eq 0){
    Note "CHECKED=$checked;ANOMALIES=$($anomalies.Count)"
   }
  }
  Note "OWNER_QUERIES=$checked;OWNER_ANOMALIES=$($anomalies.Count)"
  if($checked -ne 740 -or $anomalies.Count -ne 0){throw 'NATIVE_HARDLINK_OWNER_NOT_CERTIFIED'}
  Note 'NATIVE_OWNER=PASS_740_OF_740_NO_EXTERNAL_LINKS'
  Note 'OFFLINE_APPX_REGISTRY_LIFECYCLE=NOT_TESTED'
  $ok=$true
 }catch{
  Note "ERROR=$($_.Exception.Message)"
 }finally{
  Note '[4/5] ANOMALIES AND OWNED DISCARD'
  try{
   if($anomalies.Count -gt 0){
    $anomalies | Export-Csv -LiteralPath $anomalyCsv -NoTypeInformation -Encoding utf8
    Note "ANOMALIES_FILE=$anomalyCsv"
   }
   if(Mine @(MountTable)){
    $null=NativeDism 'DISCARD' @('/English','/Unmount-Image',"/MountDir:$mount",'/Discard')
   }
   $released= -not (Mine @(MountTable))
   Note "OWNED_MOUNT_RELEASED=$released"
  }catch{ Note "FINALIZATION_ERROR=$($_.Exception.Message)" }
  Note '[5/5] SOURCE SHA AND TERMINAL'
  try{
   if($released -and (Get-Item -LiteralPath $wim).Length -eq 6509216853L){
    $same=((Get-FileHash -LiteralPath $wim -Algorithm SHA256).Hash -ceq $expectedWim)
   }
  }catch{Note "HASH_ERROR=$($_.Exception.Message)"}
  Note "S31_WIM_SHA256_UNCHANGED=$same"
  if($ok -and $released -and $same){
   $result='PASS_S33_9711_READONLY_APPINSTALLER_NATIVE_OWNER_740'
  }
  Note 'WIM_MUTATION=NOT_RUN'
  Note 'REGISTRY_MUTATION=NOT_RUN'
  Note 'APPINSTALLER_REMOVAL_AUTHORITY=NOT_GRANTED'
  Note "RESULT=$result"
  Write-Host "MAIN_LOG=$report"
  if($anomalies.Count -gt 0){Write-Host "ANOMALIES_CSV=$anomalyCsv"}
 }
}
