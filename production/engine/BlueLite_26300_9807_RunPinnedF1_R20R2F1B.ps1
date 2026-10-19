# BlueLite R20R2F1B: invoke only the already-present SHA-pinned F1.
# GUI-delivered PS7 Admin wrapper, no network, download, source modification or overwrite.
# F1 itself mounts only the owned source image read-only and closes via /Discard.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
if ($PSVersionTable.PSVersion.Major -ne 7) { throw 'BL_R20R2F1B_PS7_REQUIRED' }
$principal = [Security.Principal.WindowsPrincipal]::new(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'BL_R20R2F1B_ADMIN_REQUIRED'
}
$scriptPath = 'C:\work\scripts\BlueLite.MaxPre.NativeSourcePreflight.R20R2F1.ps1'
$receipt = 'C:\work\logs\BlueLite_26300_9807_R20R2F1_CollisionAudit_R20R2F1A.txt'
$source = 'C:\work\26300.9807-UUP\install.wim'
$log = 'C:\work\logs\BlueLite_26300_9807_HighImpactNativePreflight_R20R2.txt'
$json = 'C:\work\logs\BlueLite_26300_9807_HighImpactNativePreflight_R20R2.json'
$mount = 'C:\BLR20R2RO'
$expectedF1 = '88F03C07A7EE8F000C77BBD464D448E6B57001C5A49004984F0C0C6728D2C919'
$expectedReceipt = 'AF72EA98449B6697CB0061C6D0C05A865B60E54C0E52FF7FBCE45FDDB43A8528'
$expectedSource = '0FB778D4696DABA17EDC52E6391A3F217982422FB920C98C8273E0C51A094B49'

# The receipt proves that only the already-correct F1 file caused the prior OR-guard HOLD.
foreach ($entry in @(
    [pscustomobject]@{Path=$scriptPath; Bytes=14311; Hash=$expectedF1; Key='F1'},
    [pscustomobject]@{Path=$receipt; Bytes=2654; Hash=$expectedReceipt; Key='R20R2F1A'}
)) {
    $f = Get-Item -LiteralPath $entry.Path -ErrorAction Stop
    if ($f.PSIsContainer -or
        (($f.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) -or
        $f.Length -ne $entry.Bytes -or
        (Get-FileHash -LiteralPath $entry.Path -Algorithm SHA256).Hash -cne $entry.Hash) {
        throw ('BL_R20R2F1B_PIN_MISMATCH_' + $entry.Key)
    }
}
$text = [IO.File]::ReadAllText($receipt)
foreach ($required in @(
    'F1_EXPECTED_SHA256_MATCH=True',
    'OBJECT=R20R2_TXT;EXISTS=False',
    'OBJECT=R20R2_JSON;EXISTS=False',
    'OBJECT=OWNED_MOUNT;EXISTS=False',
    'PREVIOUS_OR_GUARD_EXISTING_OBJECT_COUNT=1',
    'NATIVE_EXIT=/Get-MountedWimInfo=0',
    'NATIVE_EXIT=/Get-MountedImageInfo=0',
    'RESULT=PASS_R20R2F1A_INVENTORY_CAPTURE_ONLY'
)) {
    if (-not $text.Contains($required)) { throw 'BL_R20R2F1B_RECEIPT_MISSING_PROOF' }
}
foreach ($path in @($log, $json, $mount)) {
    if (Test-Path -LiteralPath $path) {
        throw ('BL_R20R2F1B_EXISTING_REPORT_OR_MOUNT=' + $path)
    }
}
$image = Get-Item -LiteralPath $source -ErrorAction Stop
if ($image.PSIsContainer -or
    (($image.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) -or
    $image.Length -ne 7021953581) {
    throw 'BL_R20R2F1B_SOURCE_LENGTH_OR_TYPE_MISMATCH'
}
# F1 performs the actual source SHA256 PRE and POST, source identity,
# fresh native mount-inventory gate, read-only mount and owned /Discard.
Write-Host 'BL_R20R2F1B_LOCAL_F1_AND_RECEIPT_SHA256=PASS'
Write-Host 'F1_INVOCATION=LOCAL_ONLY;OWNED_MOUNT=READONLY;NO_SOURCE_MUTATION'
$f1Params = @{
    ImagePath = $source
    ExpectedSha256 = $expectedSource
    ExpectedBytes = 7021953581
    ExpectedImageVersion = '10.0.26300'
    ExpectedServicePackBuild = '9807'
    PriorReport = 'C:\work\logs\BlueLite_26300_9807_DirectSourceIdentity_R19P.txt'
    ReportPath = $log
    JsonPath = $json
    MountPath = $mount
}
& $scriptPath @f1Params
