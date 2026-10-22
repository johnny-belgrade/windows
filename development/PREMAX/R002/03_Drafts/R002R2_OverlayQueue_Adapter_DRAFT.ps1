# R002R2 DEVELOPMENT ONLY: ZIP overlay + D4 transport + frozen D5/G4 closure.
# Small isolated test fixture. No network/aria2/converter/WIM/registry.
[CmdletBinding()]
param(
 [ValidateSet('AuditOnly','MaterializeFixture')][string]$Mode='AuditOnly',
 [string]$ProfilePath='C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package\01_Inputs\R002_Stage1_Profile_9711.json',
 [string]$FixtureDirectory='',
 [string]$FixtureAuthorization=''
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Deny([string]$Reason){throw ('R002R2_FAIL_CLOSED='+$Reason)}
function Gate([bool]$Test,[string]$Reason){if(-not $Test){Deny $Reason}}
function Hash([string]$Path) {
 Gate (Test-Path -LiteralPath $Path -PathType Leaf) 'REQUIRED_FILE_MISSING'
 return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}
$root='C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package'
$p=Get-Content -LiteralPath $ProfilePath -Raw | ConvertFrom-Json
Gate ($p.schema -ceq 'BlueLite.R002.Stage1.StaticProfile.v1' -and $p.runtime_allowed -eq $false) 'SOURCE_PROFILE_UNTRUSTED'
Gate ($p.source.build -ceq '26300.9711' -and $p.source.edition -ceq 'professional' -and $p.source.language -ceq 'en-us' -and $p.source.arch -ceq 'amd64') 'NOT_PINNED_POSITIVE_FIXTURE'
Gate ((Hash $p.source.zip_path) -ceq $p.source.zip_sha256) 'FROZEN_ZIP_SHA_DRIFT'
Gate ((Hash $p.source.launcher_path) -ceq $p.source.launcher_sha256) 'FROZEN_LAUNCHER_SHA_DRIFT'
Gate ((Hash $p.queue.module_path) -ceq $p.queue.module_sha256) 'D4_MODULE_SHA_DRIFT'
$modules='C:\work\scripts\BlueLite_Stage1_S06_26300_G4_AppsOnly'
$d6='F80259BE397BB5541B204D840D8D071BB4A768899AA97C5A1B5662BEF0E5CFD6'
$d5='D9835FC164FDC2C6684DF44798E9F41EDFC9961F889B112BE27CD984441015FF'
Gate ((Hash (Join-Path $modules 'BlueLite_DL_R26_D6.ps1')) -ceq $d6) 'D6_SOURCE_SHA_DRIFT'
Gate ((Hash (Join-Path $modules 'BlueLite_ResolveAppDependencies.ps1')) -ceq $d5) 'D5_RESOLVER_SHA_DRIFT'
Gate ((Hash (Join-Path $modules 'BlueLite_RequiredStagingApps.txt')) -ceq '3812FFA2EBE6085889F007D1522D2EC3F970A9C23E1457B8B2D73798FD252265') 'G4_KEEP_SHA_DRIFT'
Gate ($p.staging.windows_queue -ceq 'PRESERVE_FULL_RECONSTRUCTION') 'WINDOWS_RECONSTRUCTION_PRUNING'
Gate ($p.staging.apps_closure -ceq 'REUSE_D5_D6_G4_MANIFEST_VERIFIED') 'G4_CLOSURE_POLICY'
$keep=@(Get-Content -LiteralPath (Join-Path $modules 'BlueLite_RequiredStagingApps.txt') | Where-Object {$_ -and -not $_.StartsWith('#')})
Gate ($keep.Count -eq 5 -and @($p.staging.required_apps).Count -eq 5) 'FIVE_STAGING_APP_COUNT'
foreach($name in @($p.staging.required_apps)){Gate ($name -cin $keep) 'STAGING_APP_PROFILE_DRIFT'}
Import-Module -Name $p.queue.module_path -Force -ErrorAction Stop
$w=Get-BlueLiteQueueIdentity -Path $p.queue.frozen_windows
$a=Get-BlueLiteQueueIdentity -Path $p.queue.frozen_apps
$wr=Assert-BlueLiteQueueSamePayload -Baseline $p.queue.frozen_windows -Candidate $p.queue.renewed_windows
$ar=Assert-BlueLiteQueueSamePayload -Baseline $p.queue.frozen_apps -Candidate $p.queue.renewed_apps
Gate ($w.Count -eq 98 -and $wr.Count -eq 98 -and $w.SHA256 -ceq $p.queue.original_windows_identity_sha256) 'WINDOWS_FULL_IDENTITY'
Gate ($a.Count -eq 2798 -and $ar.Count -eq 2798 -and $a.SHA256 -ceq $p.queue.original_apps_identity_sha256) 'APPS_FULL_IDENTITY'
$groot='C:\work\E2E\BlueLite_Stage1_S06_26300_9711_2b22470a\Queues'
$subset=Join-Path $groot 'AppsQueue.filtered.txt'
$g=Get-BlueLiteQueueIdentity -Path $subset
Gate ($g.Count -eq 32 -and $g.SHA256 -ceq '32486F7757C96A21053AE49B568A17F9BB2E5BA973700D0A0F8B9327D45D9F9D') 'G4_SUBSET_SHA_OR_COUNT'
$glog=Get-Content -LiteralPath (Join-Path $groot 'ResolveAppDependencies.log') -Raw
Gate ($glog.Contains('Unproven required AppX dependencies: 0') -and $glog.Contains('Final Apps queue records: 32')) 'G4_LOG_PROOF_ABSENT'
Add-Type -AssemblyName System.IO.Compression
$zip=[IO.Compression.ZipFile]::OpenRead([string]$p.source.zip_path)
try {
 $names=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 foreach($item in $zip.Entries) {
  $name=$item.FullName.Replace('\','/')
  Gate ($name.Length -gt 0 -and -not $name.StartsWith('/') -and -not $name.Contains(':') -and -not ($name -match '(^|/)\.\.?(/|$)') -and -not $name.EndsWith('/')) 'ZIP_ENTRY_UNSAFE'
  Gate ($names.Add($name)) 'ZIP_DUPLICATE_ENTRY'
 }
 foreach($req in @('uup_download_windows.cmd','ConvertConfig.ini','CustomAppsList.txt','files/get_aria2.ps1','files/converter_windows')){Gate ($names.Contains($req)) 'ZIP_REQUIRED_FILE'}
 $count=$names.Count
}finally{$zip.Dispose()}
Write-Output ('R002R2_AUDIT_PASS;WINDOWS=98;APPS=2798;G4_STAGING=32;UPSTREAM_ZIP_ENTRIES='+$count+';NO_NETWORK=TRUE')
if($Mode -eq 'AuditOnly') {Write-Output 'R002R2_AUDIT_NO_WRITE=TRUE';return}
Gate ($FixtureAuthorization -ceq 'I_APPROVE_R002R2_SMALL_FIXTURE_ONLY') 'FIXTURE_AUTH_TOKEN'
$parent=Join-Path $root '04_StaticTests'
Gate (-not [string]::IsNullOrWhiteSpace($FixtureDirectory)) 'FIXTURE_DIR_REQUIRED'
$dest=[IO.Path]::GetFullPath($FixtureDirectory).TrimEnd('\')
Gate ($dest.StartsWith($parent+'\', [StringComparison]::OrdinalIgnoreCase) -and (Split-Path $dest -Parent) -ceq $parent) 'NOT_OWNED_FIXTURE_PATH'
Gate (-not (Test-Path -LiteralPath $dest)) 'FIXTURE_PREEXISTS'
$null=[IO.Directory]::CreateDirectory($dest)
$zip=[IO.Compression.ZipFile]::OpenRead([string]$p.source.zip_path)
try{
 foreach($entry in $zip.Entries){
  $target=[IO.Path]::GetFullPath((Join-Path $dest $entry.FullName.Replace('/','\')))
  Gate ($target.StartsWith($dest+'\', [StringComparison]::OrdinalIgnoreCase)) 'ZIP_TARGET_TRAVERSAL'
  $null=[IO.Directory]::CreateDirectory((Split-Path $target -Parent))
  [IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$target,$false)
 }
}finally{$zip.Dispose()}
Gate ((Hash (Join-Path $dest 'uup_download_windows.cmd')) -ceq $p.source.launcher_sha256) 'EXTRACTED_LAUNCHER_SHA_DRIFT'
$bp=Join-Path $dest 'BlueLite'
$queues=Join-Path $bp 'Queues'
$null=[IO.Directory]::CreateDirectory($queues)
$windowsPath=Join-Path $queues 'Windows.full.active.aria2.txt'
$appsPath=Join-Path $queues 'Apps.staging32.active.aria2.txt'
[IO.File]::Copy([string]$p.queue.renewed_windows,$windowsPath,$false)
$wc=Assert-BlueLiteQueueSamePayload -Baseline $p.queue.frozen_windows -Candidate $windowsPath
$ac=Sync-BlueLiteQueueSubsetTransport -Subset $subset -FullCandidate $p.queue.renewed_apps -Output $appsPath
Gate ($wc.Count -eq 98 -and $ac.Count -eq 32 -and $ac.SHA256 -ceq $g.SHA256) 'OVERLAY_QUEUE_PROOF'
$report=[ordered]@{
 schema='BlueLite.R002R2.SmallOverlayFixture.v1';status='PASS_STATIC_FIXTURE_ONLY'
 build=[string]$p.source.build;zip_sha256=[string]$p.source.zip_sha256
 launcher_sha256=[string]$p.source.launcher_sha256;upstream_entries=$count
 windows_full=98;apps_original_full=2798;apps_closed_staging=32
 staging_apps=$keep;g4_semantic_sha256=[string]$g.SHA256
 d4_sha256=[string]$p.queue.module_sha256;d5_sha256=$d5;d6_sha256=$d6
 signed_urls='LOCAL_QUEUE_ONLY';new_getphp=$false;aria2=$false
 converter=$false;wim_mutation=$false;runtime_authorized=$false
 original_launcher_preserved=$true;original_convertconfig_preserved=$true
}
[IO.File]::WriteAllText((Join-Path $bp 'FixtureGate.json'),($report|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
$stub=(@('@echo off','echo R002R2_FIXTURE_ONLY_NO_RUNTIME_AUTHORIZATION','exit /b 86') -join [Environment]::NewLine)+[Environment]::NewLine
[IO.File]::WriteAllText((Join-Path $dest 'BlueLite_Stage1.cmd'),$stub,[Text.Encoding]::ASCII)
Gate ((Hash $p.source.zip_path) -ceq $p.source.zip_sha256) 'ORIGINAL_ZIP_CHANGED_POST'
Write-Output ('R002R2_FIXTURE_PASS;UPSTREAM_ENTRIES='+$count+';WINDOWS=98;APPS_STAGING=32;G4_UNRESOLVED=0;NO_NETWORK=TRUE;NO_WIM=TRUE')
