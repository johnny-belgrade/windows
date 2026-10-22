# R002 original UUP Dump ZIP overlay layout reviewer; NO extraction, copy or execution.
[CmdletBinding()]
param([Parameter(Mandatory)][string]$ProfilePath)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Gate([bool]$Allowed,[string]$Reason){if(-not $Allowed){throw ('R002_OVERLAY_FAIL_CLOSED='+$Reason)}}
$p=Get-Content -LiteralPath $ProfilePath -Raw | ConvertFrom-Json
Gate ($p.schema -ceq 'BlueLite.R002.Stage1.StaticProfile.v1' -and $p.runtime_allowed -eq $false) 'PROFILE_UNAUTHORIZED'
$zip=[string]$p.source.zip_path
Gate (Test-Path -LiteralPath $zip -PathType Leaf) 'ORIGINAL_ZIP_MISSING'
Gate ((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash -ceq $p.source.zip_sha256) 'FROZEN_ZIP_SHA_DRIFT'
Add-Type -AssemblyName System.IO.Compression
$z=[IO.Compression.ZipFile]::OpenRead($zip)
try{
 $names=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 foreach($entry in $z.Entries){
  $n=$entry.FullName.Replace('\','/')
  Gate (-not [string]::IsNullOrWhiteSpace($n) -and -not $n.StartsWith('/') -and -not $n.Contains(':') -and -not ($n -match '(^|/)\.\.(/|$)')) 'ARCHIVE_UNSAFE_OR_TRAVERSAL'
  Gate ($names.Add($n)) 'ARCHIVE_DUPLICATE_ENTRY'
 }
 foreach($key in @('uup_download_windows.cmd','ConvertConfig.ini','CustomAppsList.txt','files/get_aria2.ps1','files/converter_windows')){
  Gate ($names.Contains($key)) ('UPSTREAM_ARCHIVE_REQUIRED_ENTRY_'+$key)
 }
 Write-Output ('R002_ORIGINAL_UUP_ZIP_LAYOUT=PASS;ENTRIES='+$names.Count)
 Write-Output 'OVERLAY_ROOT=EXTRACT_ORIGINAL_ONLY_IN_SEPARATELY_APPROVED_OWNED_WORKSPACE'
 Write-Output 'OVERLAY_ADDITIONS=BlueLite/;BlueLite_Stage1.cmd;BlueLite_Stage1.ps1'
 Write-Output 'OVERLAY_ORIGINAL_UUP_LAUNCHER=IMMUTABLE_DO_NOT_REPLACE'
 Write-Output 'OVERLAY_EXISTING_CONVERTCONFIG_AND_CUSTOMAPPSLIST=NEVER_OVERWRITE_WITHOUT_PINNED_VERSION_REVIEW'
 Write-Output 'OVERLAY_NO_EXTRACTION_NO_EXECUTION=TRUE'
}finally{$z.Dispose()}
