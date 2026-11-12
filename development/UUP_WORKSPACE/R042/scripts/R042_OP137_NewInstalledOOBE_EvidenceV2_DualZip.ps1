# BlueLite R042 OP137: final secondary small evidence V2 for original native installed OOBE; no WIM, ISO, VHDX duplicated in this ZIP.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$workspace='C:\work\_UUP'
$delivery=Join-Path $workspace 'R042_PREMAX_Delivery_20261111'
$safe=Join-Path $workspace 'R042_SafetyBackup_20261112'
$history=Join-Path $workspace 'UUP-history\R042_SafetyBackup_20261112'
$stage=Join-Path $safe 'contents_V2'
$zip=Join-Path $safe 'R042_InstalledOOBE_Evidence_V2_20261112.zip'
$zip2=Join-Path $history 'R042_PREMAX_Evidence_Safety_20261112.zip'
$receipt=Join-Path $delivery 'R042_OP137_NewInstalledOOBE_EvidenceV2_Producer.json'
foreach($f in @($stage,$zip,$zip2,$receipt)){
 if(Test-Path -LiteralPath $f){throw ('OP137_V2_BACKUP_ALREADY_EXISTS_NO_OVERWRITE_'+$f)}
}
$portable=Join-Path $delivery 'BlueLite_PREMAX_R042_Universal26300x_NoPrompt_DRAFT.zip'
$portableSHA=(Get-FileHash -LiteralPath $portable -Algorithm SHA256).Hash
if($portableSHA -ne '99BAF4E3407CF5F964DB2418F00A010C485F2622392ACE27C132D3BF0C2A21E1'){throw 'PORTABLE_USER_ZIP_SHA_DRIFT'}
$frame=Join-Path $workspace 'R042_VM_FullCMD_9974_Setup_20261111\BlueLite_Logs\R042_OP87_NewFullCMDVM_GuestVideo_640x480.png'
if((Get-FileHash $frame -Algorithm SHA256).Hash -ne 'EDAA894FB6A0B0B8A11D7C4D7D68A4E5D3BD5B2090B44B50851835AC77BD341A'){throw 'LIVE_SETUP_PNG_SHA_DRIFT'}
$media=Get-Content -LiteralPath (Join-Path $delivery 'R042_OP71_FullMediaSHA_IndependentReadback.json') -Raw|ConvertFrom-Json
if($media.status -ne 'R042_OP71_4PHYSICAL_FULL_MEDIA_SHA_6684801024_OUTSIDE_FAT_SOURCE_PATCH_SECOND_NATIVE_QA_PASS'){throw 'ORIGINAL_FOUR_MEDIA_SHA_QA_NOT_PASS'}
$installedFrame=Join-Path $workspace 'R042_InstalledBoot_9974_20261112\BlueLite_Logs\R042_OP124_InstalledVHD_FirstBoot_640x480.png'
if((Get-FileHash $installedFrame -Algorithm SHA256).Hash -ne 'E198A17DAC1E29D5852E472292FDA8A3AEBFC474492F1E5857EFA2EC719F287F'){throw 'ORIGINAL_INSTALLED_OOBE_REAL_WMI_PNG_SHA_CHANGED'}
$fullVhdQA=Get-Content -LiteralPath (Join-Path $delivery 'R042_OP135_InstalledOOBE_FullVHD_DualCopy_IndependentVerify.json') -Raw|ConvertFrom-Json
if($fullVhdQA.status -ne 'R042_OP135_14GB_INSTALLED_OOBE_VHD_HISTORY_COPY_BOTH_FULL_SHA_GUID_DYNAMIC_UNMOUNTED_SECOND_NATIVE_PASS'){throw 'ORIGINAL_INSTALLED_VHD_HISTORY_FULL_SHA_QA_NOT_PASS'}
$hostQA=Get-Content -LiteralPath (Join-Path $delivery 'R042_OP133_FinalPrePoweroffHostSafety_IndependentVerify.json') -Raw|ConvertFrom-Json
if($hostQA.status -ne 'R042_OP133_INDEPENDENT_SECOND_NATIVE_ALL_3_VMS_OFF_ZERO_VHD_WIM_HIVE_MUTATORS_ORIGINAL_SHA_PASS_SHUTDOWN_READY'){throw 'HOST_SHUTDOWN_SAFETY_QA_NOT_PASS'}
if(@(Get-VM|Where-Object{$_.State -ne 'Off'}).Count){throw 'ANY_VM_RESTARTED_ARCHIVE_HOLD'}
$groups=@(
 [pscustomobject]@{name='full-native-build-logs';path=(Join-Path $workspace 'R042_FULL_ONECMD_9974_20261111\BlueLite_Logs')},
 [pscustomobject]@{name='native-delivery-scripts-receipts';path=$delivery},
 [pscustomobject]@{name='new-exact-A391-vm-visual';path=(Join-Path $workspace 'R042_VM_FullCMD_9974_Setup_20261111\BlueLite_Logs')},
 [pscustomobject]@{name='original-26300-9974-installed-oobe-logs';path=(Join-Path $workspace 'R042_InstalledBoot_9974_20261112\BlueLite_Logs')}
)
$all=[Collections.Generic.List[object]]::new()
$sourceTotal=0L
foreach($g in $groups){
 if(-not (Test-Path -LiteralPath $g.path -PathType Container)){throw ('SOURCE_EVIDENCE_DIR_ABSENT_'+$g.path)}
 foreach($f in @(Get-ChildItem -LiteralPath $g.path -File -Recurse)){
  if($f.Name -like 'R042_OP137_NewInstalledOOBE_EvidenceV2_*'){continue}
  if($f.Length -gt 100MB){throw ('UNEXPECTED_BULK_SOURCE_IN_LOGS_'+$f.FullName)}
  $sourceTotal += $f.Length
  if($sourceTotal -gt 250MB){throw 'EVIDENCE_SOURCES_EXCEED_250MB_DONT_ARCHIVE_BULK_MEDIA'}
  $rel=$f.FullName.Substring($g.path.Length).TrimStart([char]92)
  $all.Add([pscustomobject]@{source=$f.FullName;zipPath=($g.name+'/'+($rel -replace '\\','/'));size=$f.Length;sha256=(Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash})
 }
}
$script='C:\work\scripts\BlueLite_R042_OP87_NewFullCMDVM_WMIFrame_ReadOnly.ps1'
if(-not (Test-Path -LiteralPath $script -PathType Leaf)){throw 'NEW_EXACT_WMI_SOURCE_NOT_PRESENT'}
$all.Add([pscustomobject]@{source=$script;zipPath='new-vm-wmi-source/BlueLite_R042_OP87_NewFullCMDVM_WMIFrame_ReadOnly.ps1';size=([IO.FileInfo]::new($script)).Length;sha256=(Get-FileHash $script -Algorithm SHA256).Hash})
foreach($extra in @('C:\work\scripts\R042_OP94_SafetyEvidenceBackup_20261112.ps1','C:\work\scripts\R042_OP124_InstalledVHD_WMI_640_ReadOnly_v2.ps1','C:\work\scripts\R042_OP137_NewInstalledOOBE_EvidenceV2_DualZip.ps1')){
 if(-not [IO.File]::Exists($extra)){throw ('REQUIRED_SOURCE_SCRIPT_MISSING_'+$extra)}
 $all.Add([pscustomobject]@{source=$extra;zipPath=('reference-sources/'+[IO.Path]::GetFileName($extra));size=([IO.FileInfo]::new($extra)).Length;sha256=(Get-FileHash $extra -Algorithm SHA256).Hash})
}
[void][IO.Directory]::CreateDirectory($stage)
foreach($item in $all){
 $file=Join-Path $stage ($item.zipPath.Replace('/',[IO.Path]::DirectorySeparatorChar))
 [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($file))
 [IO.File]::Copy([string]$item.source,$file,$false)
}
$manifest=[ordered]@{
 schema='BlueLite.R042.OP137.InstalledOOBEFinalEvidenceArchiveManifest.v2'
 utc=[DateTime]::UtcNow.ToString('o')
 originalRoot='C:\work\_UUP\R042_FULL_ONECMD_9974_20261111'
 preservedUserDistro='C:\work\_UUP\R042_PREMAX_Delivery_20261111\BlueLite_PREMAX_R042_Universal26300x_NoPrompt_DRAFT.zip'
 preservedUserDistroSHA=$portableSHA
 actualWin11SetupPngFullSHA='EDAA894FB6A0B0B8A11D7C4D7D68A4E5D3BD5B2090B44B50851835AC77BD341A'
 newFullCmdOriginalWIMphysicalSHA='61AA38CD52B85962C52E4A8F9D14C4F7C4D0699D9A57446261D26EB723C0AEC2'
 newFullCmdOriginalBootWIMphysicalSHA='CCB407362893B0473B57B2BD153DE66954CC9C61C49793037D22DE0708DA0C9E'
 originalSourceISOfullSHA='481E15E67E91FEBE19ED953C9615F17CBDA7756EACC7C23A6A0090649DA8AF7D'
 derivedNewExactA391ISOfullSHA='A3913F0133A0195622D3CA4FD89DDA1C2591E527C0FF46C3C777BBA76872E9BA'
 fullMediaPhysicalProofSourceReceipt=(Join-Path $delivery 'R042_OP71_FullMediaSHA_IndependentReadback.json')
 originalInstalledOOBEPNGphysicalSHA256='E198A17DAC1E29D5852E472292FDA8A3AEBFC474492F1E5857EFA2EC719F287F'
 originalOOBEInstalledVHDsource=$fullVhdQA.originalVHDpath
 originalOOBEInstalledVHDfullSHA256=$fullVhdQA.originalFullPhysicalSHA256
 originalOOBEInstalledVHDhistoryBackup=$fullVhdQA.historyVHDbackupPath
 originalOOBEInstalledVHDhistoryBackupFullSHA256=$fullVhdQA.backupIndependentFullPhysicalSHA256
 originalOOBEInstalledVHDphysicalBytes=$fullVhdQA.eachVHDphysicalBytes
 finalHostAllThreeVMsOffIndependentReceiptSHA=(Get-FileHash (Join-Path $delivery 'R042_OP133_FinalPrePoweroffHostSafety_IndependentVerify.json') -Algorithm SHA256).Hash
 correctOwnerCurrentShaAtArchiveCreation='105cc81c8bf2e14be45062713fce9f4a2558c002'
 sourceMemberCount=$all.Count
 sourceMembers=@($all|Sort-Object zipPath|ForEach-Object{[pscustomobject]@{zipPath=$_.zipPath;bytes=$_.size;sha256=$_.sha256}})
 bigOriginalWimIsoSourceBytesAreReferenced_NOTDuplicated=$true
}
$manifestPath=Join-Path $stage '_BLUELITE_ARCHIVE_MANIFEST.json'
[IO.File]::WriteAllText($manifestPath,(($manifest|ConvertTo-Json -Depth 10)+[Environment]::NewLine),[Text.UTF8Encoding]::new($false))
[void][IO.Directory]::CreateDirectory($history)
$sourceItems=@(Get-ChildItem -LiteralPath $stage -Recurse -File)
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -CompressionLevel Optimal -ErrorAction Stop
[IO.File]::Copy($zip,$zip2,$false)
$za=(Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
$zb=(Get-FileHash -LiteralPath $zip2 -Algorithm SHA256).Hash
if($za -ne $zb){throw 'TWO_ARCHIVE_COPIES_DIFFER'}
$rec=[ordered]@{
 schema='BlueLite.R042.OP137.InstalledOOBETwoPhysicalEvidenceArchives.v2'
 utc=[DateTime]::UtcNow.ToString('o')
 status='R042_OP137_SECONDARY_INSTALLED_OOBE_TWO_SMALL_EVIDENCE_ZIPS_SHA_SAME_PENDING_INDEPENDENT_MEMBER_QA'
 primaryArchive=$zip
 historyArchive=$zip2
 primarySHA256=$za
 historySHA256=$zb
 archiveBytes=([IO.FileInfo]::new($zip)).Length
 manifestSHA256=(Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash
 archivedPhysicalFileCount=$sourceItems.Count
 originalSourceMemberCount=$all.Count
 originalSourceMemberLogicalBytes=$sourceTotal
 universalDistroZipSHA256=$portableSHA
 actualWin11SetupScreenshotSHA256='EDAA894FB6A0B0B8A11D7C4D7D68A4E5D3BD5B2090B44B50851835AC77BD341A'
 actualInstalledWin11OOBEscreenshotSHA256='E198A17DAC1E29D5852E472292FDA8A3AEBFC474492F1E5857EFA2EC719F287F'
 originalSourceOOBEVhdAndHistoryFullSHA=$fullVhdQA.originalFullPhysicalSHA256
 originalOOBEVHDphysicalBytes=$fullVhdQA.eachVHDphysicalBytes
 finalSafetyIndependentHostReceiptSHA=(Get-FileHash (Join-Path $delivery 'R042_OP133_FinalPrePoweroffHostSafety_IndependentVerify.json') -Algorithm SHA256).Hash
 sourceWimIsoNotDeleted=$true
 originalGoldenMasterNotChanged=$true
 localArchivesShareSinglePhysicalDrive=$true
}
[IO.File]::WriteAllText($receipt,(($rec|ConvertTo-Json -Depth 7)+[Environment]::NewLine),[Text.UTF8Encoding]::new($false))
[pscustomobject]@{
 status=$rec.status
 archiveSHA256=$za
 archiveBytes=$rec.archiveBytes
 originalMemberCount=$all.Count
 originalSourceLogicalBytes=$sourceTotal
 primary=$zip
 history=$zip2
 producerReceiptSHA256=(Get-FileHash $receipt -Algorithm SHA256).Hash
}|ConvertTo-Json -Compress -Depth 5
