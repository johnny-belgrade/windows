# BlueLite R8 - equal-compression DISM exports; S37 and S39 are protected inputs.
& {
 $ErrorActionPreference='Stop'
 Set-StrictMode -Version Latest
 $PSNativeCommandUseErrorActionPreference=$false
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_PS7_REQUIRED'}
 $p=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'BL_ADMIN_REQUIRED'}
 $s37='C:\work\E2E\BlueLite_Stage1_S37_26300.9711_FullR4Candidate\install.disposable.wim'
 $s39='C:\work\E2E\BlueLite_Stage1_S39_26300.9711_WebView_FOD_Native_R6\install.webview-disposable.wim'
 $h37='A599CF7B7CB44748D738D1F5AD75D1D6C462DD15293755DFFB17F6D2ABE0BE9F'
 $h39='32AD747CD86052BDF6226A25B92A7B051E9946B3D43A591D1EFFD99B265AEBED'
 $r7='C:\work\logs\BlueLite_MAXPRE_WebViewEdge_26300.9711_PostCommit_R7.txt'
 $dir='C:\work\E2E\BlueLite_S40_26300.9711_R8_EqualMaxExports'
 $base=Join-Path $dir 'baseline-S37-max.wim'
 $after=Join-Path $dir 'webview-removed-S39-max.wim'
 $log='C:\work\logs\BlueLite_MAXPRE_WebViewEdge_26300.9711_ExportCompare_R8.txt'
 $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
 $utf8=[Text.UTF8Encoding]::new($false)
 if(Test-Path -LiteralPath $dir){throw 'BL_R8_OUTPUT_DIR_EXISTS'}
 if(Test-Path -LiteralPath $log){throw 'BL_R8_LOG_EXISTS'}
 $ev=Get-Item -LiteralPath $r7 -ErrorAction Stop
 if($ev.Length -ne 3160 -or (Get-FileHash -LiteralPath $r7 -Algorithm SHA256).Hash -cne
    '756B9BFD521A714F843A3A188D2B83B60B799006A928415A331A1D0885CFF43B'){
  throw 'BL_R8_R7_OPERATOR_EVIDENCE_CHANGED'
 }
 $raw=[IO.File]::ReadAllText($r7)
 if(-not $raw.Contains('RESULT=PASS_S39_R7_WEBVIEW_INDEPENDENT_POSTCOMMIT_READONLY_ONLY')){
  throw 'BL_R8_R7_POSTCOMMIT_GATE_MISSING'
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
   throw ('BL_R8_PIN_FAILED_'+$label)
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
   throw ('BL_R8_DISM_'+$tag+'_FAILED_EXIT='+$exit)
  }
  return $text
 }
 function CheckZero(){
  $lines=@(& $dism /English /Get-MountedWimInfo 2>&1 | ForEach-Object {[string]$_})
  $exit=[int]$LASTEXITCODE
  $empty=@($lines|Where-Object {$_ -match '^\s*No mounted images found\.\s*$'}).Count
  $listed=@($lines|Where-Object {$_ -match '^\s*Mount Dir\s*:'}).Count
  Note ('DISM_MOUNTS_EXIT='+$exit+';EMPTY='+$empty+';LISTED='+$listed)
  if($exit -ne 0 -or $empty -ne 1 -or $listed -ne 0){throw 'BL_R8_MOUNTS_NOT_ZERO'}
 }
 function Export([string]$label,[string]$from,[string]$to){
  Note ('EXPORT_'+$label+'_BEGIN;COMPRESS=MAX;CHECKINTEGRITY=TRUE')
  $null=Native ('EXPORT_'+$label) @('/English','/Export-Image',('/SourceImageFile:'+$from),
   '/SourceIndex:1',('/DestinationImageFile:'+$to),'/Compress:max','/CheckIntegrity')
  $file=Get-Item -LiteralPath $to -Force -ErrorAction Stop
  if($file.PSIsContainer -or $file.Length -lt 1){throw ('BL_R8_EXPORT_MISSING_'+$label)}
  $sha=(Get-FileHash -LiteralPath $to -Algorithm SHA256).Hash
  $info=Native ('INFO_'+$label) @('/English','/Get-WimInfo',('/WimFile:'+$to),'/Index:1')
  Note ('EXPORTED_'+$label+'_SHA='+$sha+';BYTES='+$file.Length)
  Note ('EXPORTED_'+$label+'_DISM_GET_WIM_INFO=PASS')
  return [long]$file.Length
 }
 $state='HOLD_R8_EQUAL_MAX_EXPORT'
 try{
  Note 'BLUELITE_R8_EQUIVALENT_MAX_DISM_EXPORT_SIZE_COMPARISON'
  Note 'ORIGINAL_R7_SHA=PASS'
  Pin $s37 6551362129L $h37 'S37'
  Pin $s39 6595075169L $h39 'S39'
  $free=[IO.DriveInfo]::new('C').AvailableFreeSpace
  Note ('FREE_C_BEFORE_BYTES='+$free)
  if($free -lt 24GB){throw 'BL_R8_REQUIRES_24_GIB_FREE'}
  CheckZero
  [void][IO.Directory]::CreateDirectory($dir)
  $b=Export 'S37' $s37 $base
  $a=Export 'S39' $s39 $after
  Note ('EXPORTED_S37_BYTES='+$b)
  Note ('EXPORTED_S39_BYTES='+$a)
  Note ('EQUAL_MAX_EXPORT_DELTA_S37_MINUS_S39_BYTES='+($b-$a))
  Note 'POSITIVE_DELTA_MEANS_S39_EXPORT_SMALLER'
  Pin $s37 6551362129L $h37 'S37_POST'
  Pin $s39 6595075169L $h39 'S39_POST'
  CheckZero
  Note 'TWO_SOURCE_WIMS_UNCHANGED=PASS'
  Note 'OUTPUT_SIZE_NOT_DEPLOYED_FOOTPRINT_OR_ISO_OR_HARDLINK_UNIQUE_BYTES'
  $state='PASS_R8_EQUAL_COMPRESSION_DUAL_NATIVE_EXPORT_MEASUREMENT_ONLY'
 }catch{
  Note ('FAIL_CLOSED='+$_.Exception.Message)
 }finally{
  Note ('RESULT='+$state)
  Note ('REPORT='+$log)
  Note ('EXPORT_S37='+$base)
  Note ('EXPORT_S39='+$after)
  Note 'KEEP_MEASUREMENT_WIMS;S31_S37_S39_PROTECTED'
 }
 if($state -ne 'PASS_R8_EQUAL_COMPRESSION_DUAL_NATIVE_EXPORT_MEASUREMENT_ONLY'){
  throw 'BL_R8_MEASUREMENT_HOLD'
 }
}
