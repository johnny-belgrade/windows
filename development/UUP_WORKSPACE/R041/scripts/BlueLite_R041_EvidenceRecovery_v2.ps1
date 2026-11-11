# BlueLite R041 explicit post-controller recovery-only evidence (no UUP/image/build actions).
[CmdletBinding()]
param(
  [ValidateSet('Pack','Verify')][string]$Mode='Pack',
  [Parameter(Mandatory=$true)][string]$CycleRoot
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
Add-Type -AssemblyName System.IO.Compression
$root=[IO.Path]::GetFullPath($CycleRoot).TrimEnd([char]92,[char]47)
$logs=Join-Path $root 'BlueLite_Logs'
$archive=Join-Path $logs 'BlueLite_R041_EVIDENCE.zip'
$manifestPath=Join-Path $logs 'BlueLite_R041_EvidenceManifest.json'
function Gate([bool]$Valid,[string]$Reason) { if(-not $Valid) { throw ('R041_RECOVERY_EVIDENCE_HOLD_'+$Reason) } }
function SHA([string]$File) { (Get-FileHash -LiteralPath $File -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant() }
function ReadJson([string]$File) { Get-Content -LiteralPath $File -Raw -Encoding UTF8 | ConvertFrom-Json }
function WriteNew([string]$Target,$Object) {
  $bytes=[Text.UTF8Encoding]::new($false).GetBytes(($Object|ConvertTo-Json -Depth 12)+[Environment]::NewLine)
  $s=[IO.File]::Open($Target,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
  try { $s.Write($bytes,0,$bytes.Length) } finally { $s.Dispose() }
}
function Eligible([IO.FileInfo]$File) {
  if($File.Name -in @('BlueLite_R041_EVIDENCE.zip','BlueLite_R041_EvidenceManifest.json')) { return $false }
  if($File.Name -match '^BlueLite_R041_EvidenceVerify_') { return $false }
  if($File.Length -gt 20000000L -or $File.Name -notmatch '^[A-Za-z0-9_.-]+$') { return $false }
  if($File.Extension -eq '.zip') { return ($File.Name -eq 'BlueLite_R035_EVIDENCE.zip') }
  if($File.Extension -in @('.txt','.json','.log','.csv')) {
    try {
      $text=[IO.File]::ReadAllText($File.FullName)
      if($text -match '(?i)(?:[?&](?:sig|signature|token|auth|authorization|access_token|se|sp|sv)=)[^ \r\n]+') { return $false }
    } catch { return $false }
  }
  return $true
}
try {
  Gate ([IO.Directory]::Exists($root) -and [IO.Directory]::Exists($logs)) 'CYCLE_OR_LOG_DIR_MISSING'
  Gate (([IO.File]::GetAttributes($root) -band [IO.FileAttributes]::ReparsePoint) -eq 0) 'CYCLE_REPARSE'
  Gate (@(Get-WindowsImage -Mounted -ErrorAction Stop).Count -eq 0) 'ACTIVE_WIM_MOUNT'
  $controllerPath=Join-Path $logs 'BlueLite_R035_Controller_Result.json'
  $nativePath=Join-Path $logs 'BlueLite_R029_RESULT.json'
  $provenancePath=Join-Path $logs 'R041_OP15_RecoveryProvenance.json'
  $originalEvidence=Join-Path $logs 'BlueLite_R035_EVIDENCE.zip'
  $report=Join-Path $logs 'UUP_post-debloat_info.txt'
  $r035BootPath=Join-Path $logs 'BlueLite_R035_CMD_Bootstrap.log'
  $r041BootPath=Join-Path $logs 'BlueLite_R041_CMD_Bootstrap.log'
  foreach($need in @($controllerPath,$nativePath,$provenancePath,$originalEvidence,$report,$r035BootPath,$r041BootPath)) {
    Gate ([IO.File]::Exists($need)) ('REQUIRED_SOURCE_MISSING_'+[IO.Path]::GetFileName($need))
  }
  $controller=ReadJson $controllerPath
  $native=ReadJson $nativePath
  $provenance=ReadJson $provenancePath
  $r035Boot=[IO.File]::ReadAllText($r035BootPath)
  $r041Boot=[IO.File]::ReadAllText($r041BootPath)
  $reportText=[IO.File]::ReadAllText($report)
  Gate ($controller.status -eq 'CANDIDATE_WIM_ISO_BUILT_NOT_RELEASE_CERTIFIED' -and $controller.originalBuild -eq '26300.9974') 'CONTROLLER_SOURCE_NOT_PASS'
  Gate ($native.status -eq 'IMAGE_CANDIDATE_BUILT_NOT_RELEASE_CERTIFIED' -and $native.build -eq $controller.originalBuild) 'NATIVE_SOURCE_NOT_PASS'
  Gate ($provenance.status -eq 'BACKEND_CANDIDATE_PASS_OUTER_FINALIZER_INCOMPLETE_ORIGIN_UNPROVED' -and $provenance.historicalR035CmdEnded -eq $false -and $provenance.rootR041WrapperTerminalExitUnknown -eq $true) 'IMMUTABLE_PROVENANCE_NOT_CLOSED'
  Gate ($r035Boot.Contains('R035_CONTROLLER_FINISHED native_exit=0') -and -not $r035Boot.Contains('R035_CMD_END native_exit=')) 'ORIGINAL_R035_CMD_PROVENANCE_CONFLICT'
  Gate ($r041Boot.Contains('NATIVE_ENGINE_DELEGATE_START')) 'R041_CMD_PROVENANCE_CONFLICT'
  Gate ($reportText.Contains('REPORT_CREATED_AFTER_NATIVE_CHILD_EXIT=TRUE') -and $reportText.Contains('FINAL_STATUS=FINAL_SOURCE_BOUND_IMAGE_CANDIDATE_VERIFIED; RELEASE_NOT_CERTIFIED') -and $reportText.Contains('ORIGINAL_NATIVE_CONTROLLER_EXIT=0')) 'FINAL_REPORT_SOURCE_NOT_PASS'
  Gate ((SHA $originalEvidence) -eq 'A4B2A819167F06693DB6EE3E55B76C0A8555DDA732BA5B92C1148BF447024') 'ORIGINAL_R035_EVIDENCE_SOURCE_SHA_CHANGED'
  if($Mode -eq 'Pack') {
    Gate (-not [IO.File]::Exists($archive) -and -not [IO.File]::Exists($manifestPath)) 'PREVIOUS_R041_RECOVERY_EVIDENCE_EXISTS'
    Gate ((SHA ([string]$native.install_wim)) -eq [string]$native.install_wim_sha256) 'ORIGINAL_CANDIDATE_WIM_SHA_DRIFT'
    Gate ((SHA ([string]$native.iso)) -eq [string]$native.iso_sha256) 'ORIGINAL_CANDIDATE_ISO_SHA_DRIFT'
    $members=[Collections.Generic.List[object]]::new()
    $excluded=[Collections.Generic.List[string]]::new()
    foreach($f in @(Get-ChildItem -LiteralPath $logs -File | Sort-Object Name)) {
      if(Eligible $f) {
        $members.Add([pscustomobject]@{name=$f.Name;bytes=[long]$f.Length;sha256=(SHA $f.FullName)})
      } else { $excluded.Add($f.Name) }
    }
    $names=@($members.ToArray() | ForEach-Object { $_.name })
    foreach($needed in @('BlueLite_R041_CMD_Bootstrap.log','BlueLite_R035_CMD_Bootstrap.log','R041_OP15_RecoveryProvenance.json','BlueLite_R035_EVIDENCE.zip','UUP_post-debloat_info.txt','BlueLite_R035_Controller_Result.json')) {
      Gate ($names -ccontains $needed) ('MANDATORY_EVIDENCE_NOT_INCLUDED_'+$needed)
    }
    $obj=[ordered]@{
      schema='BlueLite.R041.ExplicitInterruptedOuterCMDRecoveryEvidence.v2'
      status='RECOVERED_AFTER_INDEPENDENT_NATIVE_CANDIDATE_NOT_ORIGINAL_CMD_END'
      utc=[DateTime]::UtcNow.ToString('o')
      cycleRoot=$root
      nativeControllerExit=0
      historicalR035CmdEnded=$false
      outerR041WrapperExitProven=$false
      interruptionCause='UNKNOWN'
      evidenceRecovery=$true
      nativeCandidateReleaseCertified=$false
      sourceBuild=[string]$controller.originalBuild
      originalUupUUID=[string]$controller.originalUUID
      nativeWimSHA256=[string]$native.install_wim_sha256
      nativeIsoSHA256=[string]$native.iso_sha256
      originalR035EvidenceSHA256=(SHA $originalEvidence)
      sourceScriptSHA256=(SHA $PSCommandPath)
      sourceGitPath='development/UUP_WORKSPACE/R041/scripts/BlueLite_R041_EvidenceRecovery_v2.ps1'
      members=@($members.ToArray())
      excludedLogFileNames=@($excluded.ToArray())
    }
    WriteNew $manifestPath $obj
    $zip=[IO.Compression.ZipFile]::Open($archive,[IO.Compression.ZipArchiveMode]::Create)
    try {
      foreach($member in @($members.ToArray())) {
        $p=Join-Path $logs $member.name
        Gate ((SHA $p) -eq $member.sha256 -and [IO.FileInfo]::new($p).Length -eq $member.bytes) ('SOURCE_LOG_CHANGED_DURING_PACK_'+$member.name)
        [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$p,('BlueLite_Logs/'+$member.name),[IO.Compression.CompressionLevel]::Optimal)
      }
      [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$manifestPath,'BlueLite_Logs/BlueLite_R041_EvidenceManifest.json',[IO.Compression.CompressionLevel]::Optimal)
    } finally { $zip.Dispose() }
    Write-Output ('R041_RECOVERY_FINAL_EVIDENCE_PACKED ZIP='+$archive+' SHA256='+(SHA $archive)+' LOGS='+$members.Count+' SKIPPED='+$excluded.Count)
    exit 0
  }
  Gate ([IO.File]::Exists($archive) -and [IO.File]::Exists($manifestPath)) 'RECOVERED_ZIP_OR_MANIFEST_MISSING'
  $obj=ReadJson $manifestPath
  Gate ($obj.schema -eq 'BlueLite.R041.ExplicitInterruptedOuterCMDRecoveryEvidence.v2' -and $obj.evidenceRecovery -eq $true -and $obj.historicalR035CmdEnded -eq $false -and $obj.nativeControllerExit -eq 0) 'RECOVERY_MANIFEST_NOT_TRUTHFUL'
  $members=@($obj.members)
  Gate ($members.Count -ge 6) 'RECOVERY_EVIDENCE_TOO_FEW_MEMBERS'
  $zip=[IO.Compression.ZipFile]::OpenRead($archive)
  $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  try {
    Gate ($zip.Entries.Count -eq $members.Count+1) 'ZIP_MEMBER_COUNT_UNEXPECTED'
    foreach($m in $members) {
      $n=[string]$m.name
      Gate ($n -eq [IO.Path]::GetFileName($n) -and $seen.Add($n)) ('DUPLICATE_OR_UNSAFE_MEMBER_'+$n)
      $entry=$zip.GetEntry('BlueLite_Logs/'+$n)
      Gate ($null -ne $entry -and [long]$entry.Length -eq [long]$m.bytes) ('ZIP_MEMBER_MISSING_OR_SIZE_'+$n)
      $s=$entry.Open()
      try { $dig=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($s)) } finally { $s.Dispose() }
      Gate ($dig -eq [string]$m.sha256 -and $dig -eq (SHA (Join-Path $logs $n))) ('ZIP_VS_DISK_SHA_CHANGED_'+$n)
    }
    $mentry=$zip.GetEntry('BlueLite_Logs/BlueLite_R041_EvidenceManifest.json')
    Gate ($null -ne $mentry) 'ZIP_MANIFEST_NOT_EMBEDDED'
    $s=$mentry.Open()
    try { $dig=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($s)) } finally { $s.Dispose() }
    Gate ($dig -eq (SHA $manifestPath)) 'EMBEDDED_MANIFEST_DIGEST_CHANGED'
  } finally { $zip.Dispose() }
  $receipt=[ordered]@{
    schema='BlueLite.R041.RecoveryEvidenceNativeIndependentVerify.v2'
    utc=[DateTime]::UtcNow.ToString('o')
    status='R041_RECOVERY_EVIDENCE_ALL_MEMBER_SHA_PASS'
    archive=$archive
    archiveSHA256=(SHA $archive)
    includedLogMembers=$members.Count
    sourceManifestSHA256=(SHA $manifestPath)
    nativeControllerExit=0
    originalCMDCompleted=$false
    releaseCertified=$false
  }
  $receiptFile=Join-Path $logs ('BlueLite_R041_EvidenceVerify_Recovery_'+[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffffffZ')+'_'+[Guid]::NewGuid().ToString('N').Substring(0,8)+'.json')
  WriteNew $receiptFile $receipt
  Write-Output ('R041_RECOVERY_EVIDENCE_INDEPENDENT_SHA_PASS ZIP='+$archive+' SHA256='+$receipt.archiveSHA256+' FILES='+$members.Count+' RECEIPT='+$receiptFile)
  exit 0
} catch {
  [Console]::Error.WriteLine('R041_RECOVERY_EVIDENCE_HOLD '+$_.Exception.Message)
  exit 17
}
