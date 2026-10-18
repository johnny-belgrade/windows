param(
 [string]$SourceWimPath='C:\work\E2E\BlueLite_Stage1_S31_26300.9711_OneDriveAMBER\install.wim',
 [string]$WorkingWimPath='C:\work\E2E\BlueLite_MAXPRE_26300.9711_owned\install.working.wim',
 [string]$CorePath='C:\work\scripts\BlueLite.MaxPre.Core.R1.psm1',
 [string]$TransactionPath='C:\work\logs\BlueLite_MAXPRE_TransactionGate_26300.9711.json'
)
& {
 $ErrorActionPreference='Stop'
 Set-StrictMode -Version Latest
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_PS7_REQUIRED'}
 $principal=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'BL_ADMIN_REQUIRED'}
 $root='C:\work'
 $logs='C:\work\logs'
 if(-not(Test-Path -LiteralPath $logs -PathType Container)){throw 'BL_LOGS_MISSING'}
 $report=Join-Path $logs 'BlueLite_MAXPRE_NativeOwnedPreflight_26300.9711.txt'
 $json=Join-Path $logs 'BlueLite_MAXPRE_NativeOwnedPreflight_26300.9711.json'
 foreach($p in @($report,$json)){if(Test-Path -LiteralPath $p){throw ('BL_OUTPUT_EXISTS_NO_OVERWRITE='+$p)}}
 $encoding=[Text.UTF8Encoding]::new($false)
 [IO.File]::WriteAllText($report,'',$encoding)
 function Note([string]$message){
  $line=(Get-Date -Format 'HH:mm:ss')+' | '+$message
  Write-Host $line
  [IO.File]::AppendAllText($report,$line+[Environment]::NewLine,$encoding)
 }
 function Pin([string]$tag,[string]$file,[string]$expected){
  $actual=(Get-FileHash -LiteralPath $file -Algorithm SHA256 -ErrorAction Stop).Hash
  if($actual -cne $expected){throw ('BL_SHA_DRIFT_'+$tag+'='+$actual)}
  Note ('PIN_'+$tag+'=PASS;'+$actual)
 }
 function NativeDism([string]$tag,[string[]]$arguments){
  $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
  if(-not(Test-Path -LiteralPath $dism -PathType Leaf)){throw 'BL_NATIVE_DISM_MISSING'}
  $lines=@(& $dism @arguments 2>&1 | ForEach-Object {[string]$_})
  $status=[int]$LASTEXITCODE
  $output=$lines -join [Environment]::NewLine
  if($status -ne 0 -or
     $output -notmatch '(?i)The operation completed successfully\.' -or
     $output -match '(?i)DISM\.exe\s+\[dism_options\]' -or
     $output -match '(?im)^\s*Error\s*:'){
   throw ('BL_DISM_'+$tag+'_NOT_PROVEN;EXIT='+$status)
  }
  return $output
 }
 $result='HOLD_MAXPRE_NATIVE_OWNED_PREFLIGHT_READONLY'
 try{
  Note 'MAXPRE_26300_NATIVE_OWNED_IMAGE_PREFLIGHT_READONLY'
  Note 'NO_WIM_SHA_NO_MOUNT_NO_CLONE_NO_COMPONENT_MUTATION'
  Pin 'CORE' $CorePath '609C8FD727E553249640B68E30CD6B7BF740C7CE26372276A2DE75405D9EA404'
  Pin 'TRANSACTION_ACTUAL' $TransactionPath '59C3EDCE3CD99E57CC3780BD6AAED2AAAC671A087EA3F1CF9F2726329ED94399'
  Import-Module -Name $CorePath -Force -ErrorAction Stop
  $transaction=Get-Content -LiteralPath $TransactionPath -Raw -ErrorAction Stop |
    ConvertFrom-Json -Depth 80 -ErrorAction Stop
  if($transaction.test_result -cne 'STATIC_CONTRACT_PASS_MUTATION_BLOCKED' -or
     $transaction.transaction.source_run_id -cne 'BL-26300.9711-20261018T085316328Z' -or
     $transaction.transaction.source_build -cne '26300.9711' -or
     $transaction.transaction.action_count -ne 6 -or
     $transaction.transaction.transaction_authorized -cne $false -or
     $transaction.transaction.mutations_executed -ne 0 -or
     @($transaction.transaction.actions|Where-Object {$_.EligibleForMutation -ne $false}).Count -ne 0){
   throw 'BL_OPERATOR_TRANSACTION_RECEIPT_NOT_MATCHING'
  }
  Note 'TRANSACTION_GATE=PASS;6_ACTIONS_BLOCKED;MUTATIONS=0'
  $original=Assert-BlueLiteOwnedPath -Path $SourceWimPath -OwnerRoot $root -MustExist
  $working=Assert-BlueLiteOwnedPath -Path $WorkingWimPath -OwnerRoot $root
  $null=Assert-BlueLiteDistinctImages -OriginalWim $original -WorkingWim $working
  if(-not [string]::Equals($original,[string]$transaction.transaction.original_wim_path,[StringComparison]::OrdinalIgnoreCase) -or
     -not [string]::Equals($working,[string]$transaction.transaction.working_wim_path,[StringComparison]::OrdinalIgnoreCase)){
   throw 'BL_IMAGE_PATHS_DIFFER_FROM_TRANSACTION'
  }
  if(Test-Path -LiteralPath $working){throw 'BL_OWNED_WORKING_WIM_ALREADY_EXISTS'}
  $info=Get-Item -LiteralPath $original -Force -ErrorAction Stop
  if($info.Length -ne 6509216853L){throw ('BL_SOURCE_SIZE_DRIFT='+$info.Length)}
  Note ('ORIGINAL_WIM_SIZE=PASS;BYTES='+$info.Length+';SHA_NOT_REHASHED')
  $mounts=NativeDism -tag 'MOUNT_INFO' -arguments @('/English','/Get-MountedWimInfo')
  if(-not $mounts.Contains('No mounted images found.') -or
     $mounts -match '(?im)^\s*Mount Dir\s*:'){
   throw 'BL_DISM_MOUNT_TABLE_NOT_EMPTY'
  }
  Note 'NATIVE_DISM_ZERO_MOUNTED_IMAGES=PASS'
  $reg=Join-Path $env:SystemRoot 'System32\reg.exe'
  $hives=@(& $reg query 'HKLM\SYSTEM\CurrentControlSet\Control\hivelist' 2>&1 |
    ForEach-Object {[string]$_})
  if([int]$LASTEXITCODE -ne 0){throw 'BL_REG_HIVELIST_NATIVE_FAILURE'}
  $aliases=@($hives|Where-Object {
    $_ -match '(?i)^\s*\\REGISTRY\\MACHINE\\(BL[0-9]|BlueLite|FB[0-9])'
  })
  if($aliases.Count -ne 0){throw ('BL_OFFLINE_BLUE_HIVES_LOADED='+$aliases.Count)}
  Note 'NATIVE_BLUE_OFFLINE_HIVE_ALIASES_ZERO=PASS'
  $image=NativeDism -tag 'IMAGE_INDEX_1' -arguments @('/English','/Get-ImageInfo',('/ImageFile:'+$original),'/Index:1')
  if($image -notmatch '(?im)^\s*Index\s*:\s*1\s*$' -or
     $image -notmatch '(?im)^\s*Version\s*:\s*10\.0\.26300(?:\.\d+)?\s*$'){
   throw 'BL_NATIVE_WIM_INDEX_OR_GERMANIUM_VERSION_UNPROVEN'
  }
  Note 'NATIVE_DISM_WIM_INDEX1_VERSION_26300=PASS'
  $evidence=[ordered]@{
    contract_version='1.0.0'
    source_run_id='BL-26300.9711-20261018T085316328Z'
    source_build='26300.9711'
    source_wim_path=$original
    source_wim_bytes=[long]$info.Length
    source_wim_sha256_verified_this_run=$false
    working_wim_path=$working
    working_wim_created=$false
    dism_zero_mounted_images=$true
    blue_offline_hive_aliases_zero=$true
    dism_index_one_germanium_26300=$true
    native_image_health_checked=$false
    protected_floor_verified=$false
    mutation_authorized=$false
    mutation_performed=$false
    next_action_authorized=$false
    result='PASS_MAXPRE_NATIVE_OWNED_PREFLIGHT_READONLY'
  }
  [IO.File]::WriteAllText($json,($evidence|ConvertTo-Json -Depth 14),$encoding)
  $check=Get-Content -LiteralPath $json -Raw -ErrorAction Stop | ConvertFrom-Json -Depth 30
  if($check.mutation_performed -cne $false -or
     $check.working_wim_created -cne $false -or
     $check.dism_zero_mounted_images -cne $true){
   throw 'BL_PREFLIGHT_JSON_ROUNDTRIP_INVALID'
  }
  Note ('EVIDENCE_JSON='+$json)
  $result='PASS_MAXPRE_NATIVE_OWNED_PREFLIGHT_READONLY'
 }catch{
  Note ('FAIL_CLOSED='+$_.Exception.Message)
 }finally{
  Note ('RESULT='+$result)
  Note 'NO_WIM_COPY_NO_MOUNT_NO_DISM_MUTATION_NO_DELETE'
  Write-Host ('REPORT='+$report)
 }
 if($result -ne 'PASS_MAXPRE_NATIVE_OWNED_PREFLIGHT_READONLY'){
  throw 'BL_NATIVE_PREFLIGHT_FAILED'
 }
}