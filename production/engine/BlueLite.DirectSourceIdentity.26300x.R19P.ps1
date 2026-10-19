# BlueLite R19P: exact local 26300.9807 ISO + loose WIM source identity.
# Read-only. No mount, no download, no WIM copy or servicing modification.
[CmdletBinding()]
param(
 [string]$IsoPath='C:\work\26300.9807-UUP\26300.9807.261013-1834.26H2_GE_RELEASE_SVC_PROD3_CLIENTPRO_OEMRET_X64FRE_EN-US.ISO',
 [string]$WimPath='C:\work\26300.9807-UUP\install.wim',
 [string]$ReportPath='C:\work\logs\BlueLite_26300_9807_DirectSourceIdentity_R19P.txt'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_R19P_PS7_REQUIRED'}
$principal=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'BL_R19P_ADMIN_REQUIRED'}
$dism=Join-Path $env:WINDIR 'System32\dism.exe'
if(-not [IO.File]::Exists($dism)){throw 'BL_R19P_DISM_MISSING'}
$iso=[IO.Path]::GetFullPath($IsoPath)
$wim=[IO.Path]::GetFullPath($WimPath)
$report=[IO.Path]::GetFullPath($ReportPath)
if($iso -eq $wim -or $report -eq $iso -or $report -eq $wim){throw 'BL_R19P_PATH_COLLISION'}
if(-not [IO.Directory]::Exists([IO.Path]::GetDirectoryName($report))){throw 'BL_R19P_LOG_PARENT_MISSING'}
if([IO.File]::Exists($report)){throw 'BL_R19P_NO_REPORT_OVERWRITE'}
if($iso -notmatch '^[A-Za-z]:\\' -or $wim -notmatch '^[A-Za-z]:\\'){throw 'BL_R19P_LOCAL_SOURCE_ONLY'}
if([IO.Path]::GetExtension($iso) -ine '.iso' -or [IO.Path]::GetExtension($wim) -ine '.wim'){
 throw 'BL_R19P_SOURCE_EXTENSIONS_WRONG'
}
function Inspect([string]$path,[string]$label){
 if(-not [IO.File]::Exists($path)){throw ('BL_R19P_'+$label+'_ABSENT')}
 $fi=Get-Item -LiteralPath $path -Force -ErrorAction Stop
 if(($fi.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw ('BL_R19P_'+$label+'_REPARSE')}
 if($fi.Length -lt 1073741824){throw ('BL_R19P_'+$label+'_UNEXPECTEDLY_SMALL')}
 return [pscustomobject]@{
  Length=[long]$fi.Length
  ModifiedUtcTicks=[long]$fi.LastWriteTimeUtc.Ticks
 }
}
$isoBefore=Inspect $iso 'ISO'
$wimBefore=Inspect $wim 'WIM'
$enc=[Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText($report,'',$enc)
function Note([string]$s){
 Write-Host $s
 [IO.File]::AppendAllText($report,$s+[Environment]::NewLine,$enc)
}
function Native([string]$tag,[string[]]$argsNative){
 $lines=@(& $dism @argsNative 2>&1|ForEach-Object {[string]$_})
 $rc=[int]$LASTEXITCODE
 Note ('DISM_'+$tag+'_EXIT='+$rc)
 foreach($line in $lines){Note ('DISM_'+$tag+'|'+$line)}
 $text=$lines -join [Environment]::NewLine
 if($rc -ne 0 -or $text -notmatch '(?i)The operation completed successfully\.'){
  throw ('BL_R19P_DISM_'+$tag+'_FAIL_'+$rc)
 }
 return $text
}
$completed=$false
try{
 Note 'BLUELITE_R19P_26300_9807_DIRECT_SOURCE_IDENTITY'
 Note 'SCOPE=EXACT_OPERATOR_TWO_FILES_READONLY_NO_NETWORK_NO_MOUNT_NO_COPY'
 Note ('ISO_PATH='+$iso)
 Note ('WIM_PATH='+$wim)
 Note ('ISO_BYTES='+$isoBefore.Length)
 Note ('ISO_TIMELINE_BYTES=8094824448;SIZE_MATCH='+($isoBefore.Length -eq 8094824448))
 Note ('WIM_BYTES='+$wimBefore.Length)
 Note ('WIM_PRE_WINRE_TIMELINE_BYTES=6198772736;SIZE_MATCH='+($wimBefore.Length -eq 6198772736))
 Note 'PHASE=HASH_ISO_SHA256'
 $isoSha=(Get-FileHash -LiteralPath $iso -Algorithm SHA256).Hash
 Note ('ISO_SHA256='+$isoSha)
 Note 'PHASE=HASH_STANDALONE_WIM_SHA256'
 $wimSha=(Get-FileHash -LiteralPath $wim -Algorithm SHA256).Hash
 Note ('WIM_SHA256='+$wimSha)
 Note 'PHASE=NATIVE_DISM_WIMINFO_INDEX_LIST'
 $list=Native 'INDEX_LIST' @('/English','/Get-WimInfo',('/WimFile:'+$wim))
 if($list -notmatch '(?im)^\s*Index\s*:\s*1\s*$'){throw 'BL_R19P_INDEX1_NOT_IN_LIST'}
 Note 'PHASE=NATIVE_DISM_WIMINFO_INDEX_1'
 $info=Native 'INDEX_1' @('/English','/Get-WimInfo',('/WimFile:'+$wim),'/Index:1')
 $v=[regex]::Match($info,'(?im)^\s*Version\s*:\s*(\S+)\s*$')
 $a=[regex]::Match($info,'(?im)^\s*Architecture\s*:\s*(\S+)\s*$')
 $e=[regex]::Match($info,'(?im)^\s*Edition\s*:\s*(\S+)\s*$')
 $sb=[regex]::Match($info,'(?im)^\s*ServicePack\s+Build\s*:\s*(\S+)\s*$')
 $version=if($v.Success){$v.Groups[1].Value}else{'NOT_REPORTED'}
 $arch=if($a.Success){$a.Groups[1].Value}else{'NOT_REPORTED'}
 $edition=if($e.Success){$e.Groups[1].Value}else{'NOT_REPORTED'}
 $servicePackBuild=if($sb.Success){$sb.Groups[1].Value}else{'NOT_REPORTED'}
 Note ('WIM_INDEX1_VERSION='+$version+';ARCH='+$arch+';EDITION='+$edition+';SERVICING_BUILD_FIELD='+$servicePackBuild)
 if($version -notmatch '^10\.0\.26300(?:\.\d+)?$'){throw 'BL_R19P_WIM_NOT_26300_LINEAGE'}
 if($arch -cne 'x64'){throw 'BL_R19P_WIM_NOT_X64'}
 if($edition -cne 'Professional'){throw 'BL_R19P_WIM_NOT_PROFESSIONAL'}
 $isoAfter=Inspect $iso 'ISO'
 $wimAfter=Inspect $wim 'WIM'
 if($isoAfter.Length -ne $isoBefore.Length -or
    $isoAfter.ModifiedUtcTicks -ne $isoBefore.ModifiedUtcTicks -or
    $wimAfter.Length -ne $wimBefore.Length -or
    $wimAfter.ModifiedUtcTicks -ne $wimBefore.ModifiedUtcTicks){
  throw 'BL_R19P_SOURCE_METADATA_CHANGED_DURING_READ'
 }
 Note 'SOURCE_TWO_FILES_BYTES_AND_TIMESTAMPS_UNCHANGED=PASS'
 Note 'ISO_EMBEDDED_INSTALL_WIM_RELATION=UNKNOWN_NOT_MOUNTED_OR_READ'
 Note 'WIM_CU_PACKAGE_TOPOLOGY=NOT_CHECKED_BY_GET_WIMINFO'
 $completed=$true
}catch{
 Note ('HOLD_REASON='+$_.Exception.Message)
}finally{
 Note 'NO_IMAGE_MOUNT_NO_IMAGE_CLONE_NO_HOST_SERVICING_NO_DOWNLOAD'
 if($completed){
  Note 'RESULT=PASS_R19P_ISO_AND_STANDALONE_WIM_SHA_DISM_IDENTITY_ONLY'
 }else{
  Note 'RESULT=HOLD_R19P_SOURCE_IDENTITY'
 }
}
