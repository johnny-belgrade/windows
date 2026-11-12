# BlueLite R042: backup only small evidence, receipts and original universal distro ZIP; never delete original WIM/ISO.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$workspace='C:\work\_UUP'
$delivery=Join-Path $workspace 'R042_PREMAX_Delivery_20261111'
$safe=Join-Path $workspace 'R042_SafetyBackup_20261112'
$history=Join-Path $workspace 'UUP-history\R042_SafetyBackup_20261112'
$stage=Join-Path $safe 'contents'
$zip=Join-Path $safe 'R042_PREMAX_Evidence_Safety_20261112.zip'
$zip2=Join-Path $history 'R042_PREMAX_Evidence_Safety_20261112.zip'
$receipt=Join-Path $delivery 'R042_OP94_Backup_Producer.json'
foreach($f in @($safe,$history,$stage,$zip,$zip2,$receipt)){
 if(Test-Path -LiteralPath $f){throw ('OP94_BACKUP_EXISTS_NO_OVERWRITE_'+$f)}
}
$portable=Join-Path $delivery 'BlueLite_PREMAX_R042_Universal26300x_NoPrompt_DRAFT.zip'
$portableSHA=(Get-FileHash -LiteralPath $portable -Algorithm SHA256).Hash
if($portableSHA -ne '99BAF4E3407CF5F964DB2418F00A010C485F2622392ACE27C132D3BF0C2A21E1'){throw 'PORTABLE_USER_ZIP_SHA_DRIFT'}
$frame=Join-Path $workspace 'R042_VM_FullCMD_9974_Setup_20261111\BlueLite_Logs\R042_OP87_NewFullCMDVM_GuestVideo_640x480.png'
if((Get-FileHash $frame -Algorithm SHA256).Hash -ne 'EDAA894FB6A0B0B8A11D7C4D7D68A4E5D3BD5B2090B44B50851835AC77BD341A'){throw 'LIVE_SETUP_PNG_SHA_DRIFT'}
$media=Get-Content -LiteralPath (Join-Path $delivery 'R042_OP71_FullMediaSHA_IndependentReadback.json') -Raw|ConvertFrom-Json
if($media.status -ne 'R042_OP71_4PHYSICAL_FULL_MEDIA_SHA_6684801024_OUTSIDE_FAT_SOURCE_PATCH_SECOND_NATIVE_QA_PASS'){throw 'ORIGINAL_FOUR_MEDIA_SHA_QA_NOT_PASS'}
$groups=@(
 [pscustomobject]@{name='full-native-build-logs';path=(Join-Path $workspace 'R042_FULL_ONECMD_9974_20261111\BlueLite_Logs')},
 [pscustomobject]@{name='native-delivery-scripts-receipts';path=$delivery},
 [pscustomobject]@{name='new-exact-A391-vm-visual';path=(Join-Path $workspace 'R042_VM_FullCMD_9974_Setup_20261111\BlueLite_Logs')}
)
$all=[Collections.Generic.List[object]]::new()
$sourceTotal=0L
foreach($g in $groups){
 if(-not (Test-Path -LiteralPath $g.path -PathType Container)){throw ('SOURCE_EVIDENCE_DIR_ABSENT_'+$g.path)}
 foreach($f in @(Get-ChildItem -LiteralPath $g.path -File -Recurse)){
  if($f.Name -like 'R042_OP94_Backup_*'){continue}
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
[void][IO.Directory]::CreateDirectory($stage)
foreach($item in $all){
 $file=Join-Path $stage ($item.zipPath.Replace('/',[IO.Path]::DirectorySeparatorChar))
 [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($file))
 [IO.File]::Copy([string]$item.source,$file,$false)
}
$manifest=[ordered]@{
 schema='BlueLite.R042.OP94.NativeEvidenceBackupManifest.v1'
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
 correctOwnerCurrentSha='105cc81c8bf2e14be45062713fce9f4a2558c002'
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
 schema='BlueLite.R042.OP94.TwoCopiesOfEvidenceSourceArchival.v1'
 utc=[DateTime]::UtcNow.ToString('o')
 status='R042_OP94_TWO_LOCAL_EVIDENCE_ARCHIVES_SHA_IDENTICAL_PENDING_INDEPENDENT_MEMBER_CHECK'
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
