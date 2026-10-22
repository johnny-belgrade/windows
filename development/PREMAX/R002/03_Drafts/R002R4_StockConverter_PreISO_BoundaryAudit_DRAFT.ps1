# R002R4 stock original v128m converter pre-ISO source order contract.
# SOURCE INSPECTION ONLY. NEVER execute this vendor .cmd, fetch payloads, mount WIM or build ISO.
[CmdletBinding()]
param(
 [string]$ContractPath='C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package\01_Inputs\R002R4_StockConverterPreISO_Contract.json'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Deny([string]$Code){throw ('R002R4_FAIL_CLOSED='+$Code)}
function Gate([bool]$Condition,[string]$Code){if(-not $Condition){Deny $Code}}
function Hash([string]$Path){
 Gate (Test-Path -LiteralPath $Path -PathType Leaf) 'SOURCE_NOT_FOUND'
 (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()
}
$c=Get-Content -LiteralPath $ContractPath -Raw -ErrorAction Stop|ConvertFrom-Json -ErrorAction Stop
Gate ($c.schema -ceq 'BlueLite.R002R4.StockConverterPreISOContract.v1' -and $c.intent -ceq 'SOURCE_ONLY_REVIEW_NO_RUNTIME') 'CONTRACT_SCHEMA'
Gate ($c.safety.runtime_authorized -eq $false -and $c.safety.converter_runtime_executed -eq $false -and $c.safety.network_payload_allowed -eq $false -and $c.safety.wim_mutation_allowed -eq $false -and $c.safety.iso_export_allowed -eq $false) 'RUNTIME_FLAG_NOT_FALSE'
Gate ($c.upstream.version -ceq 'v128m' -and $c.upstream.uupdump_misc_converter_windows_version -ceq 'v128m' -and $c.upstream.actual_vendor_binary_verified -eq $false) 'UPSTREAM_VERSION_SELECTION_MISMATCH'
Gate ($c.upstream.github_blob_sha -ceq '262a6e6b0ad2016d1345927bdc334898f71b49f2') 'LIVE_GITHUB_BLOB_REPIN_NEEDED'
Gate ((Hash $c.upstream.local_snapshot) -ceq $c.upstream.local_snapshot_sha256) 'UPSTREAM_SOURCE_SHA_DRIFT'
$readme='C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package\01_Inputs\R002R4_UPSTREAM_ReadMe_v128m_REFERENCE.html.txt'
Gate ((Hash $readme) -ceq $c.upstream.readme_local_sha256) 'UPSTREAM_README_SHA_DRIFT'
Gate ($c.frozen_original_source.build -ceq '26300.9711' -and (Hash $c.frozen_original_source.zip) -ceq $c.frozen_original_source.zip_sha256) 'FROZEN_ORIGINAL_UUP_ZIP_DRIFT'
Gate ($c.frozen_original_source.upstream_declared_converter -ceq 'v126' -and $c.frozen_original_source.cross_version_compatibility_certified -eq $false) 'FROZEN_SOURCE_CROSS_VERSION_NOT_HOLD'
$opt=$c.intended_vendor_options
Gate ($opt.AutoStart -ceq '1') 'AUTOSTART_ISO_WIM_ONLY_REQUIRED'
Gate ($opt.SkipISO -ceq '1') 'SKIPISO_REQUIRED_FOR_PREISO_HANDOFF'
Gate ($opt.SkipWinRE -ceq '0') 'WINRE_PRESERVE_REQUIRED'
Gate ($opt.StartVirtual -ceq '0') 'VIRTUAL_EDITION_UNREVIEWED'
Gate ($opt.wim2esd -ceq '0' -and $opt.wim2swm -ceq '0') 'WIM_FORMAT_REQUIRED'
Gate ($opt.SkipApps -ceq '0' -and $opt.NetFx3 -ceq '0' -and $opt.ResetBase -ceq '0') 'RECONSTRUCTION_POLICY_DRIFT'
Gate ($c.safety.notice_heavy_cpu_before_action -eq $true -and $c.safety.all_large_output_cwork -eq $true) 'THERMAL_OR_PATH_GUARD'
Gate ($c.handoff.source_output_mode -ceq 'ISO_FULL_LAYOUT_WITH_INSTALL_WIM_NO_FINAL_ISO') 'WRONG_OUTPUT_MODE'
Gate ($c.handoff.immutable_source_wim_required -eq $true -and $c.handoff.distinct_mutable_working_wim_required -eq $true -and $c.handoff.final_iso_separate_verified_step -eq $true) 'MAXPRE_IMMUTABILITY_OR_ISO_GATE'
$path=[IO.Path]::GetFullPath([string]$c.handoff.output_directory)
Gate ($path.StartsWith('C:\work\',[StringComparison]::OrdinalIgnoreCase)) 'OUTPUT_CWORK_SCOPE'
$src=[IO.File]::ReadAllText([string]$c.upstream.local_snapshot)
Gate ($src -match '(?m)^@set uivr=v128m\s*$') 'STOCK_VENDOR_VERSION_LITERAL'
function At([string]$Fragment,[string]$Scope,[string]$Fail){
 $i=$Scope.IndexOf($Fragment,[StringComparison]::Ordinal)
 Gate ($i -ge 0) $Fail
 return $i
}
$auto1=At 'if %AutoStart% equ 1 (set WIMFILE=install.wim&goto :ISO)' $src 'AUTO1_ISO_BRANCH'
$auto3=At 'if %AutoStart% equ 3 (set AIO=1&set WIMFILE=install.wim&goto :Single)' $src 'AUTO3_SINGLE_BRANCH_EXPECTED'
Gate ($auto1 -ge 0 -and $auto3 -ge 0) 'AUTO_MODE_BRANCHES_MISSING'
$isoMatch=[Regex]::Match($src,'(?m)^:ISO\r?$')
$singleMatch=[Regex]::Match($src,'(?m)^:Single\r?$')
Gate ($isoMatch.Success -and $singleMatch.Success -and $isoMatch.Index -lt $singleMatch.Index) 'ISO_AND_SINGLE_BOUNDARIES'
$iso=$src.Substring($isoMatch.Index,$singleMatch.Index-$isoMatch.Index)
# Physical order: metadata -> full install WIM -> WinRE -> boot.wim -> final SkipISO branch -> ISO builder (not run).
$setup=At 'call :dk_color1 %Blue% "=== Creating Setup Media Layout . . ."' $iso 'SOURCE_MEDIA_LAYOUT_NOT_FOUND'
$setWim=At 'set _file=ISOFOLDER\sources\%WIMFILE%' $iso 'SOURCE_INSTALL_WIM_MEDIA_TARGET_NOT_FOUND'
$toInstall=At 'goto :InstallWim' $iso 'SOURCE_INSTALL_RECONSTRUCTION_BRANCH_NOT_FOUND'
$retIso=At ':RetISO' $iso 'SOURCE_INSTALL_RECONSTRUCTION_RETURN_NOT_FOUND'
$toWinre=At 'goto :WinreWim' $iso 'SOURCE_RECOVERY_PREPARATION_BRANCH_NOT_FOUND'
$bakIso=At ':BakISO' $iso 'SOURCE_RECOVERY_RETURN_NOT_FOUND'
$boot=At 'copy /y %_srcwim% ISOFOLDER\sources\boot.wim' $iso 'SOURCE_BOOT_MEDIA_NOT_FOUND'
$virtual=At 'if %StartVirtual% neq 0' $iso 'SOURCE_VIRTUAL_BRANCH_MISSING'
$setIso=At 'set isiso=1' $iso 'SOURCE_ISO_MODE_FLAG_MISSING'
$toFinish=At 'goto :esdSWM' $iso 'SOURCE_FINISH_BRANCH_MISSING'
$finIso=At ':finISO' $iso 'SOURCE_FINISH_LABEL_MISSING'
$skip=$finIso+(At 'if %SkipISO% neq 0 (' ($iso.Substring($finIso)) 'SOURCE_SKIPISO_GATE_MISSING')
$rename=At 'ren ISOFOLDER %DVDISO%' ($iso.Substring($skip)) 'SOURCE_SKIPISO_LAYOUT_RENAME_MISSING'
$exit=At 'goto :QUIT' ($iso.Substring($skip)) 'SOURCE_SKIPISO_EXIT_MISSING'
$cd=At 'cdimage.exe -bootdata:' $iso 'SOURCE_ISO_BUILDER_MISSING'
$createIso=At '=== Creating ISO . . .' $iso 'SOURCE_ISO_BUILDER_STAGE_MISSING'
Gate ($setup -lt $setWim -and $setWim -lt $toInstall -and $toInstall -lt $retIso -and $retIso -lt $toWinre -and $toWinre -lt $bakIso -and $bakIso -lt $boot -and $boot -lt $setIso -and $setIso -lt $toFinish -and $toFinish -lt $finIso -and $finIso -lt $skip -and $skip -lt $createIso -and $createIso -lt $cd) 'SOURCE_PREISO_STAGE_ORDER'
$branch=$iso.Substring($skip,$createIso-$skip)
Gate ($branch -match '(?s)^if %SkipISO% neq 0 \(\s*ren ISOFOLDER %DVDISO%\s*set qmsg=.*?\s*goto :QUIT\s*\)') 'SOURCE_SKIPISO_FINISHED_LAYOUT_AND_EXIT'
Gate ($c.upstream.actual_vendor_archive_downloaded -eq $false -and $c.upstream.actual_vendor_binary_verified -eq $false) 'CONTRACT_PRETENDS_VENDOR_BINARY_VERIFIED'
Write-Output 'R002R4_SOURCE_BOUNDARY=PASS_ORIGINAL_V128M_SOURCE_BRANCH_ORDER'
Write-Output 'R002R4_SOURCE_LAYOUT=ISO_MEDIA_PLUS_INSTALL_WIM_PLUS_BOOT_WIM_BEFORE_SKIPISO_EXIT'
Write-Output 'R002R4_NO_FINAL_ISO_BUILT=SOURCE_BRANCH_PROVED_ONLY'
Write-Output 'R002R4_FROZEN_9711_SOURCE_DECLARED_V126=TRUE;V128M_CROSS_VERSION_RUNTIME=HOLD'
Write-Output 'R002R4_NEXT_VENDOR_ARCHIVE_AND_REAL_CONVERTER_TEST=SEPARATE_AUTH_AND_CPU_PRENOTICE'
Write-Output 'R002R4_RUNTIME_ALLOWED=FALSE'
