# BlueLite v1.0 R043 OP95 - Edge FOD evidence-only gate for the Windows 26300.x family.
# DRYRUN ONLY. Query a pre-existing, explicitly owned READONLY WIM mount.
# No mount, no image servicing changes, no file carving, no registry editing.
# A CBS Staged result is NOT proof of removability or physical WIM compression savings.
# This script is a source artifact. OP95 does not execute it.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$OwnerWim,
    [Parameter(Mandatory=$true)][string]$MountDir,
    [Parameter(Mandatory=$true)]
    [ValidatePattern('^26300\.[0-9]+$')]
    [string]$SourceBuild,
    [Parameter(Mandatory=$true)][string]$PackageName,
    [Parameter(Mandatory=$true)][string]$ReceiptPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function FailClosed([string]$Reason) {
    throw ('BlueLite.EdgeFOD.DRYRUN HOLD: ' + $Reason)
}
if ($PackageName -cnotmatch '^Microsoft-Edge-WebView-FOD-Package~31bf3856ad364e35~amd64~~10\.0\.[0-9]+\.[0-9]+$') {
    FailClosed 'Package identity does not match exact Edge WebView FoD CBS family.'
}
if (-not (Test-Path -LiteralPath $OwnerWim -PathType Leaf)) {
    FailClosed 'Expected owner WIM does not exist.'
}
if (-not (Test-Path -LiteralPath $MountDir -PathType Container)) {
    FailClosed 'Expected existing mount directory does not exist.'
}
if ([IO.Path]::GetExtension($OwnerWim) -ine '.wim') {
    FailClosed 'Owner is not a WIM file.'
}
$ownerFull = [IO.Path]::GetFullPath($OwnerWim).TrimEnd('\')
$mountFull = [IO.Path]::GetFullPath($MountDir).TrimEnd('\')
$receiptFull = [IO.Path]::GetFullPath($ReceiptPath)
$scriptFolder = [IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\')
if (-not [string]::Equals([IO.Path]::GetDirectoryName($receiptFull), $scriptFolder,
    [StringComparison]::OrdinalIgnoreCase)) {
    FailClosed 'Receipt must be a new file in the same existing evidence directory as this script.'
}
if (Test-Path -LiteralPath $receiptFull) {
    FailClosed 'Refusing to overwrite an existing receipt.'
}
$expectedSourceFamily = '26300.'
if (-not $SourceBuild.StartsWith($expectedSourceFamily, [StringComparison]::Ordinal)) {
    FailClosed 'Source build is outside Germanium 26300.x.'
}
$mounts = @(Get-WindowsImage -Mounted)
if ($mounts.Count -ne 1) {
    FailClosed 'Exactly one pre-existing WIM mount is required.'
}
$active = $mounts[0]
if (-not [string]::Equals([IO.Path]::GetFullPath($active.ImagePath).TrimEnd('\'), $ownerFull,
    [StringComparison]::OrdinalIgnoreCase) -or
    -not [string]::Equals([IO.Path]::GetFullPath($active.Path).TrimEnd('\'), $mountFull,
    [StringComparison]::OrdinalIgnoreCase) -or
    [int]$active.ImageIndex -ne 1 -or
    [string]$active.MountMode -ne 'ReadOnly' -or
    [string]$active.MountStatus -ne 'Ok') {
    FailClosed 'Mounted image ownership, index or READONLY state is not proven.'
}
$cDrive = Get-PSDrive -Name C -ErrorAction Stop
if ([int64]$cDrive.Free -lt 64424509440) {
    FailClosed 'C: protection floor 60GiB not met.'
}
$offVM = 0
if (Get-Command -Name Get-VM -ErrorAction SilentlyContinue) {
    $blVM = @(Get-VM | Where-Object { $_.Name -like 'BlueLite*' })
    $running = @($blVM | Where-Object { [string]$_.State -ne 'Off' })
    if ($running.Count -ne 0) {
        FailClosed 'A BlueLite VM is not Off.'
    }
    $offVM = $blVM.Count
}
$dismPath = Join-Path $env:SystemRoot 'System32\dism.exe'
if (-not (Test-Path -LiteralPath $dismPath -PathType Leaf)) {
    FailClosed 'Built-in DISM executable absent.'
}

# Only DISM Get-PackageInfo is permitted by this script. No image modifications.
$nativeOut = @(& $dismPath ('/Image:' + $mountFull) /Get-PackageInfo
    ('/PackageName:' + $PackageName) 2>&1)
$nativeExit = $LASTEXITCODE
$lines = @($nativeOut | ForEach-Object { [string]$_ })
$stateLines = @($lines | Where-Object { $_ -match '^\s*State\s*:\s*' })
$releaseLines = @($lines | Where-Object { $_ -match '^\s*Release Type\s*:\s*' })
$packageState = if ($stateLines.Count -gt 0) {
    ($stateLines[0] -split ':', 2)[1].Trim()
} else { 'UNKNOWN' }
$releaseType = if ($releaseLines.Count -gt 0) {
    ($releaseLines[0] -split ':', 2)[1].Trim()
} else { 'UNKNOWN' }
$status = if ($nativeExit -eq 0 -and $packageState -ne 'UNKNOWN' -and
    $releaseType -ne 'UNKNOWN') {
    'READONLY_PACKAGE_STATE_OBSERVED_ELIGIBILITY_STILL_UNPROVEN'
} else {
    'NATIVE_QUERY_HOLD_NO_ELIGIBILITY_CONCLUSION'
}
$result = [ordered]@{
    schema = 'BlueLite.PREMAX.Germanium.EdgeFOD.SourceGate.DRYRUN.v1'
    timestampUtc = (Get-Date).ToUniversalTime().ToString('o')
    status = $status
    sourceBuildClaim = $SourceBuild
    exactPackageIdentity = $PackageName
    ownerWim = $ownerFull
    mountedImage = $mountFull
    mountMode = 'ReadOnly'
    preExistingMountCount = $mounts.Count
    currentCFreeBytes = [int64]$cDrive.Free
    BlueLiteGuestsOff = $offVM
    nativeQueryExit = $nativeExit
    packageCBSState = $packageState
    releaseType = $releaseType
    packageRemovabilityCertified = $false
    compressedBytesSaved = 0
    hasModifiedAnyImage = $false
    requiresExactParentOwnerAndServicingDependencyProof = $true
    requiresSeparateExplicitOwnerApprovalForAnyMutation = $true
}
($result | ConvertTo-Json -Depth 5) |
    Set-Content -LiteralPath $receiptFull -Encoding UTF8
$result | ConvertTo-Json -Depth 5
if ($nativeExit -ne 0) {
    FailClosed 'Read-only DISM query failed; receipt records HOLD.'
}
