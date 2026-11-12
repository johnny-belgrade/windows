# R042 OP141: durable offline snapshot of 6 exact Git blob documents and final host-off checkpoint.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$dev='C:\work\_UUP\R042_PREMAX_Delivery_20261111'
$primary='C:\work\_UUP\R042_SafetyBackup_20261112\GitSnapshot_Final_20261112'
$history='C:\work\_UUP\UUP-history\R042_SafetyBackup_20261112\GitSnapshot_Final_20261112'
$checkpoint='C:\work\_UUP\R042_FINAL_SHUTDOWN_CHECKPOINT_20261112.md'
$receipt=Join-Path $dev 'R042_OP141_GitFinalDocs_LocalTwoSnapshot_Producer.json'
foreach($p in @($primary,$history,$checkpoint,$receipt)){if(Test-Path -LiteralPath $p){throw ('LOCAL_DOCS_FINAL_SOURCE_ALREADY_EXISTS_'+$p)}}
$gate=Get-Content -LiteralPath (Join-Path $dev 'R042_OP133_FinalPrePoweroffHostSafety_IndependentVerify.json') -Raw|ConvertFrom-Json
$zipQA=Get-Content -LiteralPath (Join-Path $dev 'R042_OP137_NewInstalledOOBE_EvidenceV2_IndependentVerify.json') -Raw|ConvertFrom-Json
$vhdQA=Get-Content -LiteralPath (Join-Path $dev 'R042_OP135_InstalledOOBE_FullVHD_DualCopy_IndependentVerify.json') -Raw|ConvertFrom-Json
if($gate.status -ne 'R042_OP133_INDEPENDENT_SECOND_NATIVE_ALL_3_VMS_OFF_ZERO_VHD_WIM_HIVE_MUTATORS_ORIGINAL_SHA_PASS_SHUTDOWN_READY' -or $zipQA.status -ne 'R042_OP137_V2_DUAL_INSTALLED_OOBE_EVIDENCE_ZIP_ALL_313_SOURCE_MEMBERS_BOTH_SHA_SECOND_INDEPENDENT_PASS' -or $vhdQA.status -ne 'R042_OP135_14GB_INSTALLED_OOBE_VHD_HISTORY_COPY_BOTH_FULL_SHA_GUID_DYNAMIC_UNMOUNTED_SECOND_NATIVE_PASS'){throw 'FINAL_LOCAL_DOC_SECURITY_GATES_NOT_PASS'}
if(@(Get-VM|Where-Object{$_.State -ne 'Off'}).Count){throw 'A_TEST_VM_RESTARTED_STOP_LOCAL_SNAPSHOT'}
$commit='a4fb1e5a6c0872fc8f1708645f49307a31c827fa'
$expected=[ordered]@{
 'Start_Instruction.md'='a5cb9fcb1dba4e817e208222df8c4639d18976e8'
 'BlueLite-Master_Germanium_Strategy_final.md'='3b32f372267fb6fb8fbdb5430476d915c4054c83'
 'BlueLite_Current_Status.md'='5ee607a51620df9d067cad95cbcc85045f082b54'
 'BlueLite_Session_Entry.md'='a62fedf26e24ad6e9dd19ae5c7a47e4bdd10fbf7'
 'BlueLite_Sources.md'='f581220d7f2c7bb8a039c405f1fbb0244483ef2c'
 'BlueLite_Germanium_Handoff.md'='114b9d536f11601a1b28f20e48d1e18bbb0223d6'
}
function Get-GitBlobSHA([string]$path){
 $data=[IO.File]::ReadAllBytes($path)
 $prefix=[Text.Encoding]::ASCII.GetBytes(('blob '+$data.Length+[char]0))
 $joined=[byte[]]::new($prefix.Length+$data.Length)
 [Buffer]::BlockCopy($prefix,0,$joined,0,$prefix.Length)
 [Buffer]::BlockCopy($data,0,$joined,$prefix.Length,$data.Length)
 return [Convert]::ToHexString([Security.Cryptography.SHA1]::HashData($joined)).ToLowerInvariant()
}
[void][IO.Directory]::CreateDirectory($primary)
[void][IO.Directory]::CreateDirectory($history)
$members=@()
foreach($name in $expected.Keys){
 $url='https://raw.githubusercontent.com/johnny-belgrade/windows/'+$commit+'/'+$name
 $dest=Join-Path $primary $name
 Invoke-WebRequest -Uri $url -OutFile $dest -MaximumRedirection 3 -ErrorAction Stop
 $gitsha=Get-GitBlobSHA $dest
 if($gitsha -ne $expected[$name]){throw ('RAW_GIT_DOC_BLOB_MISMATCH_'+$name+'_'+$gitsha)}
 $other=Join-Path $history $name
 [IO.File]::Copy($dest,$other,$false)
 if((Get-GitBlobSHA $other) -ne $gitsha){throw ('HISTORY_GIT_DOC_BLOB_MISMATCH_'+$name)}
 $members += [pscustomobject]@{name=$name;blob=$gitsha;bytes=([IO.FileInfo]::new($dest)).Length;primarySHA256=(Get-FileHash $dest -Algorithm SHA256).Hash;historySHA256=(Get-FileHash $other -Algorithm SHA256).Hash}
}
$lines=@(
 '# BlueLite R042 FINAL PROVEN HOST SHUTDOWN CHECKPOINT - 2026-11-12'
 ''
 'Current Git blob 5ee607a51620df9d067cad95cbcc85045f082b54. Session Entry blob a62fedf26e24ad6e9dd19ae5c7a47e4bdd10fbf7. Sources blob f581220d7f2c7bb8a039c405f1fbb0244483ef2c. Full Handoff blob 114b9d536f11601a1b28f20e48d1e18bbb0223d6. Original Master and Start retained.'
 ''
 'REAL FIRST ORIGINAL 26300.9974 PRE_MAX Windows 11 Pro installed boot OOBE region/country GUI visual PASS after native first UUP CMD exit0, DISM apply original WIM index1 to owner-only VHD and EFI BCD. Original WMI PNG: C:\work\_UUP\R042_InstalledBoot_9974_20261112\BlueLite_Logs\R042_OP124_InstalledVHD_FirstBoot_640x480.png SHA256 E198A17DAC1E29D5852E472292FDA8A3AEBFC474492F1E5857EFA2EC719F287F. Uncompleted OOBE/Explorer, installed Hyper-V HOST, secureboot ON, repeated boot speed, final size NOT CERTIFIED.'
 ''
 'ALL THREE HYPER-V TEST VMS OFF, original VHD and DVD source files preserved. VHD host attached count0, WIM mount0, native DISM No mounted images, host Disk0 System Boot only, temporary registry hive aliases0, active image servicing processes0. Independent source QA R042 OP134. User may power off or restart host now. Assistant did not shut it down.'
 ''
 'FULL installed original .9974 OOBE VHD SOURCE and UUP-history COPY each 14,164,164,608B SHA256 83495CADF17B8B9F7D44084524C8C63008C0D98DCB57A997EF1F10E848ABCEDC. Primary C:\work\_UUP\R042_InstalledBoot_9974_20261112\R042_Installed26300_9974_SourceOwner.vhdx. History C:\work\_UUP\UUP-history\R042_InstalledBoot_9974_20261112\R042_Installed26300_9974_Proven_OOBE_BACKUP.vhdx.'
 ''
 'Original universal root PRE_MAX.cmd user zip C:\work\_UUP\R042_PREMAX_Delivery_20261111\BlueLite_PREMAX_R042_Universal26300x_NoPrompt_DRAFT.zip SHA256 99BAF4E3407CF5F964DB2418F00A010C485F2622392ACE27C132D3BF0C2A21E1. Includes required BlueLite_Logs directory. V1 source evidence archives two copies each SHA E08358DF9AD7C98BC0444BD3EACAE24DA542C640C991E9CA087E0328C40CF814, 256 of 256 SHA verified. V2 OOBE evidence archives two copies each SHA C6A52BD5A1D141D00BF3154F18AF9B4EE71D05E917B1A239FB29BB9BED9BA385, 313 of 313 SHA verified. Backup folders C:\work\_UUP\R042_SafetyBackup_20261112 and C:\work\_UUP\UUP-history\R042_SafetyBackup_20261112.'
 ''
 'Six complete authority documents copied from one pinned Git commit a4fb1e5a6c0872fc8f1708645f49307a31c827fa to TWO local GitSnapshot_Final_20261112 folders with independent per-file Git blob and SHA. Both sets on same physical C disk: user should also save to external disk if physical independence required.'
 ''
 'EXACTLY ONE NEXT AFTER OWNER COMMAND AND PC RESTART: Master sections 0H / 0I source-bound SIZE-FIRST P1 largest owner-qualified physically unique compressed removable install.wim payload, read-only dependency mapping with individual native receipt and separate QA before any image mutation.'
 ''
 'No extra Hyper-V guest starts or host shutdown performed during final preservation.'
)
[IO.File]::WriteAllText($checkpoint,(($lines -join [Environment]::NewLine)+[Environment]::NewLine),[Text.UTF8Encoding]::new($false))
[IO.File]::Copy($checkpoint,(Join-Path $primary 'R042_FINAL_SHUTDOWN_CHECKPOINT_20261112.md'),$false)
[IO.File]::Copy($checkpoint,(Join-Path $history 'R042_FINAL_SHUTDOWN_CHECKPOINT_20261112.md'),$false)
$rec=[ordered]@{
 utc=[DateTime]::UtcNow.ToString('o')
 status='R042_OP141_SIX_PINNED_GIT_DOCS_LOCAL_HISTORY_FULL_BLOB_SHA_AND_FINAL_CHECKPOINT_PASS_PENDING_SECOND_QA'
 pinnedGitCommit=$commit
 sourceFiles=$members
 localGitSnapshot=$primary
 historyGitSnapshot=$history
 rootFinalCheckpoint=$checkpoint
 checkpointSHA256=(Get-FileHash $checkpoint -Algorithm SHA256).Hash
 originalFullHandoffPreservedLocal=$true
 HyperVthreeGuestsOff=$true
 originalHostSafetyQAstatus=$gate.status
 fullInstalledOriginalVHDcopySHA=$vhdQA.originalFullPhysicalSHA256
 originalEvidenceV2QAstatus=$zipQA.status
 noHostShutdownPerformed=$true
}
[IO.File]::WriteAllText($receipt,(($rec|ConvertTo-Json -Depth 9)+[Environment]::NewLine),[Text.UTF8Encoding]::new($false))
[pscustomobject]@{status=$rec.status;sixGitBlobVerified=$members.Count;fullHandoffBytes=(@($members|Where-Object{$_.name -eq 'BlueLite_Germanium_Handoff.md'}))[0].bytes;checkpointSha=$rec.checkpointSHA256;receiptSha=(Get-FileHash $receipt -Algorithm SHA256).Hash}|ConvertTo-Json -Compress
