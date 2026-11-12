# R043 OP07 second native process - exact original .9974 P1 metadata and archived R029 DISM state.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$logs='C:\work\_UUP\R043_PREMAX_P1_20261112\BlueLite_Logs'
$source=Join-Path $logs 'R043_OP06_OneDrive_AI_InstalledTargets_Producer.json'
$out=Join-Path $logs 'R043_OP07_OneDriveP1_SecondNativeVerify.json'
if(Test-Path $out){throw 'P1_SECOND_9974_OWNER_QA_ALREADY_EXISTS'}
$p=Get-Content -LiteralPath $source -Raw|ConvertFrom-Json
if($p.status -ne 'R043_OP06_ORIGINAL_R042_9974_WIM_P1_BOUNDED_FILE_PATH_METADATA_ONLY_PRODUCER_PASS' -or @($p.results).Count -ne 9){throw 'SOURCE_METADATA_RECEIPT_NOT_PASS'}
$required=@{
 'OneDriveSetupSystem32'=[int]0
 'CBSsearchHost'=[int]0
 'OneDriveSetupSysWOW64'=[int]49
 'OneDriveSettingsSync'=[int]49
 'EdgeUpdateX86'=[int]49
 'RecallAPI'=[int]49
 'AIxHost'=[int]49
 'ExactWinREPayload'=[int]49
 'CLI_help'=[int]0
}
$items=@()
foreach($x in $p.results){
 if(-not $required.ContainsKey([string]$x.name)){throw ('UNEXPECTED_TARGET_'+$x.name)}
 if([int]$x.nativeExit -ne [int]$required[[string]$x.name]){throw ('NATIVE_EXIT_CHANGED_'+$x.name)}
 $f=[IO.FileInfo]::new([string]$x.log)
 if(-not $f.Exists -or $f.Length -gt 1MB -or (Get-FileHash $f.FullName -Algorithm SHA256).Hash -ne $x.logSHA){throw ('LOG_ABSENT_OR_SHA_CHANGED_'+$x.name)}
 $t=[IO.File]::ReadAllText($f.FullName)
 if(-not $t.Contains('NATIVE_EXIT: '+[string]$x.nativeExit)){throw ('LOG_NATIVE_EXIT_HEADER_MISMATCH_'+$x.name)}
 if($x.nativeExit -eq 49 -and -not $t.Contains('The path does not exist in the WIM image.')){throw ('WIM_PATH_ABSENCE_NOT_CONFIRMED_'+$x.name)}
 $items += [pscustomobject]@{target=$x.name;exit=$x.nativeExit;logSHA=$x.logSHA}
}
$one=Get-Content -LiteralPath (Join-Path $logs 'R043_OP06_OneDriveSetupSystem32.txt') -Raw
$search=Get-Content -LiteralPath (Join-Path $logs 'R043_OP06_CBSsearchHost.txt') -Raw
foreach($requiredText in @('OneDriveSetup.exe','Hash              = 0x054ff47240288181f2f472c9dc4a04c9c194d083','Uncompressed size = 89771848 bytes','Compressed size   = 85873690 bytes','Reference Count   = 2')){if(-not $one.Contains($requiredText)){throw ('ONEDRIVE_PHYSICAL_METADATA_MISMATCH_'+$requiredText)}}
foreach($requiredText in @('SearchHost.exe','Compressed size   = 25150 bytes','Reference Count   = 2')){if(-not $search.Contains($requiredText)){throw ('SEARCH_PHYSICAL_METADATA_MISMATCH_'+$requiredText)}}
$native='C:\work\_UUP\R042_FULL_ONECMD_9974_20261111\BlueLite_Logs'
$capPath=Join-Path $native 'BlueLite_R029_DISM_064_AfterCapabilities.txt'
$pkgPath=Join-Path $native 'BlueLite_R029_DISM_066_AfterPackages.txt'
$caps=Get-Content -LiteralPath $capPath -Raw
$pkgs=Get-Content -LiteralPath $pkgPath -Raw
if($caps -notmatch '(?m)^Capability Identity : Edge\.Webview2\.Platform~~~~0\.0\.1\.0\r?$' -or $caps -notmatch '(?m)^Capability Identity : Language\.Basic~~~en-US~0\.0\.1\.0\r?$'){throw 'NATIVE_R029_AFTER_CAPS_EXPECTED_NAMES_MISSING'}
$edge=[regex]::Match($caps,'(?ms)Capability Identity : Edge\.Webview2\.Platform~~~~0\.0\.1\.0\r?\nState : (?<state>[^\r\n]+)')
$lang=[regex]::Match($caps,'(?ms)Capability Identity : Language\.Basic~~~en-US~0\.0\.1\.0\r?\nState : (?<state>[^\r\n]+)')
if(-not $edge.Success -or $edge.Groups['state'].Value -ne 'Not Present' -or -not $lang.Success -or $lang.Groups['state'].Value -ne 'Installed'){throw 'AFTER_CAPABILITY_PROTECTED_TARGET_POST_STATES_WRONG'}
if($pkgs -notmatch '(?m)^Image Version: 10\.0\.26300\.9974\r?$' -or $pkgs -notmatch 'Package_for_ServicingStack_9971' -or $pkgs -notmatch 'Package_for_RollupFix' -or $pkgs -notmatch 'Microsoft-Windows-SenseClient-FoD-Package'){throw 'AFTER_NATIVE_PACKAGES_SOURCE_OR_PROTECTED_PRESENCE_NOT_PROVEN'}
if($pkgs -match 'Microsoft-OneDrive-Setup-Package'){throw 'VISIBLE_ONEDRIVE_PACKAGE_TOPOLOGY_CHANGED_FROM_EXPECTED'}
$nativeResult=Get-Content -LiteralPath (Join-Path $native 'BlueLite_R029_RESULT.json') -Raw|ConvertFrom-Json
if($nativeResult.build -ne '26300.9974' -or $nativeResult.install_wim -ne $p.originalWim -or $nativeResult.install_wim_sha256 -ne $p.sourcePinnedWimPhysicalSha256 -or [IO.FileInfo]::new($p.originalWim).Length -ne 5602983183){throw 'R029_SOURCE_ORIGINAL_PIN_DRIFT'}
$vms=@(Get-VM)
if($vms.Count -ne 3 -or @($vms|Where-Object{$_.State -ne 'Off'}).Count -or @(Get-WindowsImage -Mounted).Count -or @(Get-Disk).Count -ne 1 -or ([IO.DriveInfo]::new('C')).AvailableFreeSpace -lt 60GB){throw 'HOST_RESOURCE_SAFETY_NOT_PASS'}
$o=[ordered]@{
 schema='BlueLite.R043.OP07.OneDrive9974CurrentWIMPhysicalByteAndNativeCBSReadOnly.v1'
 utc=[DateTime]::UtcNow.ToString('o')
 status='R043_OP07_9974_ONEDRIVE85M_REF2_SEARCH25K_REF2_WEBVIEW_CAP_NOTPRESENT_R029_POST_OWNER_INDEPENDENT_PASS'
 firstOneDriveProducerSHA=(Get-FileHash $source -Algorithm SHA256).Hash
 nativeLogsVerified=$items
 originalWim=$p.originalWim
 originalWimFullShaSourcePinned=$p.sourcePinnedWimPhysicalSha256
 OneDriveSystem32CompressedBytes=85873690
 OneDriveSystem32RawBytes=89771848
 OneDriveSystem32WimDataSHA1='054ff47240288181f2f472c9dc4a04c9c194d083'
 OneDriveSystem32GlobalReferenceCount=2
 OneDriveDirectPathRemovalReclaimableBytes='UNKNOWN_NOT_85873690_CANNOT_ASSUME'
 SearchHostCompressedBytes=25150
 SearchHostReferenceCount=2
 EdgeWebview2CapabilityStateAfter=$edge.Groups['state'].Value
 LanguageBasicENUSStateAfter=$lang.Groups['state'].Value
 nativeAfterCapabilitiesSHA=(Get-FileHash $capPath -Algorithm SHA256).Hash
 nativeAfterPackagesSHA=(Get-FileHash $pkgPath -Algorithm SHA256).Hash
 originalAfterPackagesVisibleOneDriveIdentityPresent=$false
 hiddenOneDriveCBSpackageRegistryUndetermined=$true
 rawWimRemovalNotAllowed=$true
 noBootPerformanceWorkThisOperation=$true
 all3GuestsOff=$true
 hostMountedWimCount=0
 CfreeGiB=[math]::Round(([IO.DriveInfo]::new('C')).AvailableFreeSpace/1GB,3)
}
[IO.File]::WriteAllText($out,(($o|ConvertTo-Json -Depth 7)+[Environment]::NewLine),[Text.UTF8Encoding]::new($false))
[pscustomobject]@{status=$o.status;OneDriveCompressedBytes=$o.OneDriveSystem32CompressedBytes;OneDriveGlobalRefs=$o.OneDriveSystem32GlobalReferenceCount;EdgeWebViewAfter=$o.EdgeWebview2CapabilityStateAfter;OneDriveCBSidentity='HIDDEN_OWNER_NOT_PROVEN';receiptSHA=(Get-FileHash $out -Algorithm SHA256).Hash}|ConvertTo-Json -Compress
