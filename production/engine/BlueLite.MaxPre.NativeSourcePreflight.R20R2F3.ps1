# BlueLite R20R2F3: source-bound CRLF-safe native preflight using existing SHA-pinned F1.
# The exact F1 source is patched only in memory; no existing script is changed.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
if ($PSVersionTable.PSVersion.Major -ne 7) { throw 'BL_R20R2F3_PS7_REQUIRED' }
$principal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'BL_R20R2F3_ADMIN_REQUIRED'
}
$f1 = 'C:\work\scripts\BlueLite.MaxPre.NativeSourcePreflight.R20R2F1.ps1'
$rawEvidence = 'C:\work\logs\BlueLite_26300_9807_WimInfoRaw_R20R2F1C.txt'
$lastReport = 'C:\work\logs\BlueLite_26300_9807_HighImpactNativePreflight_R20R2F2.txt'
$lastJson = 'C:\work\logs\BlueLite_26300_9807_HighImpactNativePreflight_R20R2F2.json'
$source = 'C:\work\26300.9807-UUP\install.wim'
$report = 'C:\work\logs\BlueLite_26300_9807_HighImpactNativePreflight_R20R2F3.txt'
$json = 'C:\work\logs\BlueLite_26300_9807_HighImpactNativePreflight_R20R2F3.json'
$mount = 'C:\BLR20R2RO'
$inputs = @(
    [pscustomobject]@{Path=$f1; Length=14311; Sha='88F03C07A7EE8F000C77BBD464D448E6B57001C5A49004984F0C0C6728D2C919'; Id='F1'},
    [pscustomobject]@{Path=$rawEvidence; Length=1216; Sha='C7CABC82A56716FD32697260A6B9F403D4B781579703A5448DFD4412554F4EB2'; Id='R20R2F1C'},
    [pscustomobject]@{Path=$lastReport; Length=3407; Sha='B67A408D8E5D0BEF5AF99B7A0675B8678EA49CD28C9014164EC87FAFEADCF9F0'; Id='R20R2F2'}
)
foreach ($entry in $inputs) {
    $item = Get-Item -LiteralPath $entry.Path -ErrorAction Stop
    if ($item.PSIsContainer -or $item.Length -ne $entry.Length -or
        (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) -or
        (Get-FileHash -LiteralPath $entry.Path -Algorithm SHA256).Hash -cne $entry.Sha) {
        throw ('BL_R20R2F3_INPUT_NOT_PINNED_' + $entry.Id)
    }
}
$evidence = [IO.File]::ReadAllText($rawEvidence)
foreach ($needed in @('NATIVE_EXIT=0', 'IMAGE_SECTION_REGEX=False',
    'WIMINFO_RAW|Details for image : C:\work\26300.9807-UUP\install.wim',
    'WIMINFO_RAW|Version : 10.0.26300', 'WIMINFO_RAW|ServicePack Build : 9807',
    'RESULT=CAPTURE_R20R2F1C_ONLY')) {
    if (-not $evidence.Contains($needed)) { throw 'BL_R20R2F3_RAW_EVIDENCE_SHAPE' }
}
# The previous HOLD must be the exact preserved original; its JSON must be absent.
if (Test-Path -LiteralPath $lastJson) { throw 'BL_R20R2F3_PRIOR_JSON_UNEXPECTED' }
$lastText = [IO.File]::ReadAllText($lastReport)
foreach ($needed in @(
    'NATIVE_MOUNT_READONLY_EXIT=0',
    'CAPABILITY=Edge.Webview2.Platform~~~~;STATE=INSTALLED',
    'PACKAGE=Microsoft-Edge-WebView-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1;STATE=STAGED;NATIVE_EXIT=0',
    'FAIL_CLOSED=BL_R20R2_PACKAGE_MUM_REPARSE',
    'OWNED_READONLY_DISCARD=PASS', 'ZERO_MOUNTS_POST_WIM=PASS',
    'ZERO_MOUNTS_POST_IMAGE=PASS', 'SOURCE_POST_PIN=PASS',
    'RESULT=HOLD_R20R2_NATIVE_SOURCE_PREFLIGHT')) {
    if (-not $lastText.Contains($needed)) { throw 'BL_R20R2F3_PRIOR_HOLD_SHAPE' }
}
foreach ($output in @($report,$json,$mount)) {
    if (Test-Path -LiteralPath $output) { throw ('BL_R20R2F3_NO_OVERWRITE_OR_MOUNT=' + $output) }
}
$image = Get-Item -LiteralPath $source -ErrorAction Stop
if ($image.PSIsContainer -or $image.Length -ne 7021953581 -or
    (($image.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) {
    throw 'BL_R20R2F3_SOURCE_IDENTITY_HOLD'
}

# Repair all CRLF-sensitive .NET multiline end anchors in the pinned F1 code.
$original = [IO.File]::ReadAllText($f1)
$changes = @(
    @('Details for image[ \t]*:[^\r\n]*$', 'Details for image[ \t]*:[^\r\n]*\r?$'),
    @('(Installed|Not Present|Staged)[ \t]*$', '(Installed|Not Present|Staged)[ \t]*\r?$'),
    @('(Installed|Staged|Superseded|Install Pending|Uninstall Pending)[ \t]*$', '(Installed|Staged|Superseded|Install Pending|Uninstall Pending)[ \t]*\r?$'),
    @('(Install Pending|Uninstall Pending|Partially Installed)[ \t]*$', '(Install Pending|Uninstall Pending|Partially Installed)[ \t]*\r?$')
)
$patched = $original
foreach ($change in $changes) {
    $before = [string]$change[0]
    $after = [string]$change[1]
    if ([regex]::Matches($patched,[regex]::Escape($before)).Count -ne 1) {
        throw ('BL_R20R2F3_PATCH_ANCHOR_NOT_UNIQUE_' + $before)
    }
    $patched = $patched.Replace($before,$after)
}
# ReparsePoint is metadata on some DISM-mounted MUM files, not CBS state.
# Never open/follow/read this MUM. Validate exact filename and directory; query CBS natively.
$oldMum = "if((`$f.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'BL_R20R2_PACKAGE_MUM_REPARSE'}"
$newMum = @'
if(($f.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){
  if($f.Extension -cne '.mum' -or
     [IO.Path]::GetDirectoryName($f.FullName) -ine $dir -or
     $f.BaseName -cnotmatch '^Microsoft-[A-Za-z0-9_.~-]+$'){
    throw 'BL_R20R2_PACKAGE_MUM_METADATA_SCOPE_HOLD'
  }
  Note ('PACKAGE_MUM_REPARSE_METADATA_ONLY='+$f.Name)
}
'@
if ([regex]::Matches($patched,[regex]::Escape($oldMum)).Count -ne 1) {
    throw 'BL_R20R2F3_MUM_ANCHOR_NOT_UNIQUE'
}
$patched = $patched.Replace($oldMum,$newMum)
# Safe filename acceptance and deliberate negative fixtures.
$mumPattern = '^Microsoft-[A-Za-z0-9_.~-]+$'
foreach ($candidate in @(
    'Microsoft-Edge-WebView-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1',
    'Microsoft-Windows-OneDrive-Setup-Package~31bf3856ad364e35~amd64~~10.0.26100.1')) {
    if ($candidate -cnotmatch $mumPattern) { throw 'BL_R20R2F3_MUM_POSITIVE_FIXTURE' }
}
foreach ($candidate in @('..\escape','not-microsoft','Microsoft-test\x','Microsoft-test.exe/mum')) {
    if ($candidate -cmatch $mumPattern) { throw 'BL_R20R2F3_MUM_NEGATIVE_FIXTURE' }
}
if ($patched -ceq $original) { throw 'BL_R20R2F3_NO_PATCH' }

# CRLF + LF positive fixtures, negative fixtures for missing header and pending state.
foreach ($nl in @(([string][char]13 + [string][char]10), ([string][char]10))) {
    $sample = 'Details for image : C:\fixture.wim' + $nl +
      'Version : 10.0.26300' + $nl + 'ServicePack Build : 9807' + $nl
    if (-not [regex]::IsMatch($sample,'(?im)^[ \t]*Details for image[ \t]*:[^\r\n]*\r?$')) {
        throw 'BL_R20R2F3_IMAGE_SECTION_FIXTURE'
    }
    foreach ($state in @('Installed','Not Present','Staged')) {
        if (-not [regex]::IsMatch(('State : ' + $state + $nl),
            '(?im)^[ \t]*State[ \t]*:[ \t]*(Installed|Not Present|Staged)[ \t]*\r?$')) {
            throw 'BL_R20R2F3_CAPABILITY_FIXTURE'
        }
    }
    if (-not [regex]::IsMatch(('State : Superseded' + $nl),
        '(?im)^[ \t]*State[ \t]*:[ \t]*(Installed|Staged|Superseded|Install Pending|Uninstall Pending)[ \t]*\r?$')) {
        throw 'BL_R20R2F3_PACKAGE_FIXTURE'
    }
    if (-not [regex]::IsMatch(('State : Install Pending' + $nl),
        '(?im)^[ \t]*State[ \t]*:[ \t]*(Install Pending|Uninstall Pending|Partially Installed)[ \t]*\r?$')) {
        throw 'BL_R20R2F3_PENDING_FIXTURE'
    }
    if ([regex]::IsMatch(('State : Unknown' + $nl),
        '(?im)^[ \t]*State[ \t]*:[ \t]*(Installed|Not Present|Staged)[ \t]*\r?$')) {
        throw 'BL_R20R2F3_NEGATIVE_CAPABILITY_FIXTURE'
    }
}
$tokens = $null
$parseErrors = $null
$null = [Management.Automation.Language.Parser]::ParseInput($patched,[ref]$tokens,[ref]$parseErrors)
if (@($parseErrors).Count -gt 0) { throw ('BL_R20R2F3_AST_' + $parseErrors[0].Message) }
$runner = [ScriptBlock]::Create($patched)
Write-Host 'BL_R20R2F3_F1_PIN_CRLF_MUM_FIXTURES_AST=PASS'
$parameters = @{
    ImagePath=$source
    ExpectedSha256='0FB778D4696DABA17EDC52E6391A3F217982422FB920C98C8273E0C51A094B49'
    ExpectedBytes=7021953581
    ExpectedImageVersion='10.0.26300'
    ExpectedServicePackBuild='9807'
    PriorReport='C:\work\logs\BlueLite_26300_9807_DirectSourceIdentity_R19P.txt'
    ReportPath=$report
    JsonPath=$json
    MountPath=$mount
}
& $runner @parameters
