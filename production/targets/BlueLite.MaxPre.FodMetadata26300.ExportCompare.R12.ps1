# BlueLite R12 - reuse proven R8 native dual equal-max DISM export; FoDMetadata S39 vs S41.
& {
 $ErrorActionPreference='Stop'
 Set-StrictMode -Version Latest
 $PSNativeCommandUseErrorActionPreference=$false
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_PS7_REQUIRED'}
 $p=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'BL_ADMIN_REQUIRED'}
 $s39='C:\work\E2E\BlueLite_Stage1_S39_26300.9711_WebView_FOD_Native_R6\install.webview-disposable.wim'
 $s41='C:\work\E2E\BlueLite_Stage1_S41_26300.9711_FodMetadata_Superseded_R10\install.fodmetadata-disposable.wim'
 $h39='32AD747CD86052BDF6226A25B92A7B051E9946B3D43A591D1EFFD99B265AEBED'
 $h41='378B6C7A20D434172EA7AB2F4857C78431393C0B3C1B13D993D8AAF125D6B6B1'
 $r11='C:\work\logs\BlueLite_MAXPRE_FodMetadata_26300.9711_PostCommit_R11.txt'
 $dir='C:\work\E2E\BlueLite_S42_26300.9711_R12_FodMetadata_EqualMaxExports'
 $base=Join-Path $dir 'baseline-S39-max.wim'
 $after=Join-Path $dir 'fodmetadata-removed-S41-max.wim'
 $log='C:\work\logs\BlueLite_MAXPRE_FodMetadata_26300.9711_ExportCompare_R12.txt'
 $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
 $utf8=[Text.UTF8Encoding]::new($false)
 if(Test-Path -LiteralPath $dir){throw 'BL_R12_OUTPUT_DIR_EXISTS'}
 if(Test-Path -LiteralPath $log){throw 'BL_R12_LOG_EXISTS'}
 $ev=Get-Item -LiteralPath $r11 -ErrorAction Stop
 if($ev.Length -ne 2106 -or (Get-FileHash -LiteralPath $r11 -Algorithm SHA256).Hash -cne
    '711A2673A0541AF86A33C41E71B7758B060C6AE808119555C23C4D724F997F6A'){
  throw 'BL_R12_R11_OPERATOR_EVIDENCE_CHANGED'
 }
 $raw=[IO.File]::ReadAllText($r11)
 if(-not $raw.Contains('RESULT=PASS_S41_R11_INDEPENDENT_FODMETADATA_POSTCOMMIT_READONLY_ONLY')){
  throw 'BL_R12_R11_POSTCOMMIT_GATE_MISSING'
 }
 [IO.File]::WriteAllText($log,'',$utf8)
 function Note([string]$msg){
  Write-Host $msg
  [IO.File]::AppendAllText($log,$msg+[Environment]::NewLine,$utf8)
 }
 function Pin([string]$f,[long]$length,[string]$sha,[string]$label){
  $item=Get-Item -LiteralPath $f -Force -ErrorAction Stop
  if($item.PSIsContainer -or $item.Length -ne $length -or
     ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
     (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash -cne $sha){
   throw ('BL_R12_PIN_FAILED_'+$label)
  }
  Note ('SOURCE_'+$label+'_SHA_SIZE=PASS;'+$sha+';BYTES='+$length)
 }
 function Native([string]$tag,[string[]]$argv){
  $lines=@(& $dism @argv 2>&1 | ForEach-Object {[string]$_})
  $exit=[int]$LASTEXITCODE
  $text=$lines -join [Environment]::NewLine
  if($exit -ne 0 -or $text -match '(?im)^\s*Error\s*:' -or
    $text -notmatch '(?i)The operation completed successfully\.'){
   foreach($line in $lines){Note ('DISM_'+$tag+'_RAW='+$line)}
   throw ('BL_R12_DISM_'+$tag+'_FAILED_EXIT='+$exit)
  }
  return $text
 }
 function CheckZero(){
  $lines=@(& $dism /English /Get-MountedWimInfo 2>&1 | ForEach-Object {[string]$_})
  $exit=[int]$LASTEXITCODE
  $empty=@($lines|Where-Object {$_ -match '^\s*No mounted images found\.\s*$'}).Count
  $listed=@($lines|Where-Object {$_ -match '^\s*Mount Dir\s*:'}).Count
  Note ('DISM_MOUNTS_EXIT='+$exit+';EMPTY='+$empty+';LISTED='+$listed)
  if($exit -ne 0 -or $empty -ne 1 -or $listed -ne 0){throw 'BL_R12_MOUNTS_NOT_ZERO'}
 }
 function Export([string]$label,[string]$from,[string]$to){
  Note ('EXPORT_'+$label+'_BEGIN;COMPRESS=MAX;CHECKINTEGRITY=TRUE')
  $null=Native ('EXPORT_'+$label) @('/English','/Export-Image',('/SourceImageFile:'+$from),
   '/SourceIndex:1',('/DestinationImageFile:'+$to),'/Compress:max','/CheckIntegrity')
  $file=Get-Item -LiteralPath $to -Force -ErrorAction Stop
  if($file.PSIsContainer -or $file.Length -lt 1){throw ('BL_R12_EXPORT_MISSING_'+$label)}
  $sha=(Get-FileHash -LiteralPath $to -Algorithm SHA256).Hash
  $info=Native ('INFO_'+$label) @('/English','/Get-WimInfo',('/WimFile:'+$to),'/Index:1')
  Note ('EXPORTED_'+$label+'_SHA='+$sha+';BYTES='+$file.Length)
  Note ('EXPORTED_'+$label+'_DISM_GET_WIM_INFO=PASS')
  return [long]$file.Length
 }
 $state='HOLD_R12_EQUAL_MAX_EXPORT'
 try{
  Note 'BLUELITE_R12_FODMETADATA_S39_S41_EQUIVALENT_MAX_EXPORT_SIZE_COMPARISON'
  Note 'ORIGINAL_R11_SHA=PASS'
  Pin $s39 6595075169L $h39 'S39'
  Pin $s41 6636510185L $h41 'S41'
  $free=[IO.DriveInfo]::new('C').AvailableFreeSpace
  Note ('FREE_C_BEFORE_BYTES='+$free)
  if($free -lt 24GB){throw 'BL_R12_REQUIRES_24_GIB_FREE'}
  CheckZero
  [void][IO.Directory]::CreateDirectory($dir)
  $b=Export 'S39' $s39 $base
  $a=Export 'S41' $s41 $after
  Note ('EXPORTED_S39_BYTES='+$b)
  Note ('EXPORTED_S41_BYTES='+$a)
  Note ('EQUAL_MAX_EXPORT_DELTA_S39_MINUS_S41_BYTES='+($b-$a))
  Note 'POSITIVE_DELTA_MEANS_S41_EXPORT_SMALLER'
  Pin $s39 6595075169L $h39 'S39_POST'
  Pin $s41 6636510185L $h41 'S41_POST'
  CheckZero
  Note 'TWO_SOURCE_WIMS_UNCHANGED=PASS'
  Note 'OUTPUT_SIZE_NOT_DEPLOYED_FOOTPRINT_OR_ISO_OR_HARDLINK_UNIQUE_BYTES;FODMETADATA_S39_TO_S41_ONLY'
  $state='PASS_R12_FODMETADATA_EQUAL_COMPRESSION_DUAL_NATIVE_EXPORT_MEASUREMENT_ONLY'
 }catch{
  Note ('FAIL_CLOSED='+$_.Exception.Message)
 }finally{
  Note ('RESULT='+$state)
  Note ('REPORT='+$log)
  Note ('EXPORT_S39='+$base)
  Note ('EXPORT_S41='+$after)
  Note 'KEEP_MEASUREMENT_WIMS;S31_S37_S39_S40_S41_PROTECTED'
 }
 if($state -ne 'PASS_R12_FODMETADATA_EQUAL_COMPRESSION_DUAL_NATIVE_EXPORT_MEASUREMENT_ONLY'){
  throw 'BL_R12_MEASUREMENT_HOLD'
 }
}
