# BlueLite R20R2F13 -- source-bound STATIC OneDrive AMBER contract / negative fixtures.
# NO WIM MOUNT, NO CBS WRITE, NO DISM, NO REG, NO WIM CLONE, NO native remove.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$base = 'C:\work'
$log = 'C:\work\logs\BlueLite_26300_9807_OneDriveContract_R20R2F13.txt'
$json = 'C:\work\logs\BlueLite_26300_9807_OneDriveContract_R20R2F13.json'
$utf8 = [System.Text.UTF8Encoding]::new($false)
if ($PSVersionTable.PSVersion.Major -ne 7) { throw 'PS7_REQUIRED' }
if ([IO.File]::Exists($log) -or [IO.File]::Exists($json)) { throw 'R20R2F13_OUTPUT_EXISTS_NO_OVERWRITE' }
$items = @(
    @('R10','BlueLite_26300_9807_OneDriveExactTopology_R20R2F10.txt','3F6E43D9F967F5F81B58488A5AA62A836E681AB1584A49F02453A7E8F90A5B8D'),
    @('R11','BlueLite_26300_9807_OneDriveCBSOwners_R20R2F11.txt','7C7C3BCC378524ACF0CACD941B60DAEC836CA88E5DFF3EDD24DD7AD0095E778D'),
    @('R11R1','BlueLite_26300_9807_OneDriveScratchCloseout_R20R2F11R1.txt','2F9284ADF285F104616EADB1177D765DFC9CE697EEAFDE937E1E4F6FEB2230F0'),
    @('R12','BlueLite_26300_9807_OneDriveParentOwner_R20R2F12.txt','1B32F0F86E3C3909784169F1B44E0486EB3D42335641F3A822C599F6FC28475B'),
    @('S31','BlueLite_Stage1_S31_26300.9711_OneDrive_AMBER_Apply.txt','0BEE37DAD57F111F878EAF37C5EFB9B0B59BF68C4B7ED638F067008603C20DF6')
)
$body = @{}
$lines = [System.Collections.Generic.List[string]]::new()
function Note([string] $v) { $lines.Add($v); Write-Output $v }
function RequireMarker([string] $source, [string] $marker, [string] $id) {
    if (-not $source.Contains($marker)) { throw ('EVIDENCE_MARKER_MISSING_' + $id + '_' + $marker) }
}
try {
    Note 'BLUELITE_R20R2F13_ONEDRIVE_26300_9807_STATIC_CONTRACT'
    Note 'MODE=LOCAL_RECEIPT_HASH_PINS_AND_NEGATIVE_FIXTURES_ONLY'
    foreach ($it in $items) {
        $file = Join-Path 'C:\work\logs' ([string]$it[1])
        if (-not [IO.File]::Exists($file)) { throw ('SOURCE_NOT_FOUND_' + $it[0]) }
        $hash = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
        if ($hash -cne [string]$it[2]) { throw ('SOURCE_SHA_MISMATCH_' + $it[0]) }
        $body[[string]$it[0]] = [IO.File]::ReadAllText($file)
        Note ('PIN_' + $it[0] + '=PASS')
    }
    RequireMarker $body.R10 'ONEDRIVE_2_NATIVE_EXACT_STATES=PASS' 'R10'
    RequireMarker $body.R10 'ONEDRIVE_SETUP_PAYLOAD=Windows\System32\OneDriveSetup.exe;PRESENT=True' 'R10_PAYLOAD'
    RequireMarker $body.R11 'RESULT=HOLD_R20R2F11_CBS_OR_OWNED_HIVE_MOUNT_CLOSEOUT' 'R11_IS_HISTORICAL_HOLD'
    RequireMarker $body.R11R1 'RESULT=PASS_R20R2F11R1' 'R11R1_CLOSEOUT'
    RequireMarker $body.R12 'EXACT_2_CHILD_OWNER_LINKS_AND_2_PARENT_CBS_KEYS=PASS' 'R12'
    RequireMarker $body.R12 'RESULT=PASS_R20R2F12_TWO_ONEDRIVE_CBS_PARENTS_READONLY_ONLY' 'R12_RESULT'
    RequireMarker $body.R12 'MUTATION_AUTHORIZATION=NOT_GRANTED' 'R12_AUTH'
    RequireMarker $body.R12 'PIN_CANDIDATE_POST=PASS;BYTES=6407308664;SHA256=F8F2FFF0A40508C88F8426B2923FEDCF9B00F3FFF3A5637A13C0EB0006E8BA7E' 'R12_WIM'
    RequireMarker $body.S31 'RESULT=PASS_S31_9711_ONEDRIVE_AMBER_COMMITTED' 'S31'
    RequireMarker $body.S31 'AMBER_TARGET_REMOVED=OLD_NEUTRAL;CBS_NONRESOLVING=PASS' 'S31_OLD_STAGED'
    RequireMarker $body.S31 'ONEDRIVEBACKUP=SEPARATE_COMPONENT_NOT_TARGETED' 'S31_BACKUP'
    Note 'SOURCE_BOUND_R10_R11_R11R1_R12_AND_HISTORICAL_S31=PASS'
    $neutral = 'Microsoft-Windows-OneDrive-Setup-Package~31bf3856ad364e35~amd64~~10.0.26100.1'
    $satellite = 'Microsoft-Windows-OneDrive-Setup-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1'
    $parentN = 'Microsoft-Windows-Not-Supported-On-LTSB-Package~31bf3856ad364e35~amd64~~10.0.26100.1301'
    $parentS = 'Microsoft-Windows-Not-Supported-On-LTSB-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1'
    $rows = @(
        [ordered]@{ Name='NEUTRAL_STAGED'; Identity=$neutral; State=64; Visibility=2; Owner=$parentN; OwnerDWORD=196672; ParentState=64; ParentVisibility=2 },
        [ordered]@{ Name='EN_US_SATELLITE'; Identity=$satellite; State=112; Visibility=2; Owner=$parentS; OwnerDWORD=196720; ParentState=112; ParentVisibility=2 }
    )
    # All integers 64/112, 196672/196720 correspond to exact R12 observed hex fields 0x40/0x70, 0x30040/0x30070.
    function ContractErrors([object[]] $testRows, [string] $candidateSha, [string] $claimedNeutral, [int] $allowedRemoveCount) {
        $errors = [System.Collections.Generic.List[string]]::new()
        if ($testRows.Count -ne 2) { $errors.Add('WRONG_CARDINALITY') }
        if ($candidateSha -cne 'F8F2FFF0A40508C88F8426B2923FEDCF9B00F3FFF3A5637A13C0EB0006E8BA7E') { $errors.Add('WRONG_SOURCE_SHA') }
        if ($claimedNeutral -cne $neutral) { $errors.Add('WRONG_NEUTRAL_ID') }
        if ($allowedRemoveCount -ne 1) { $errors.Add('OVERBROAD_REMOVE_SCOPE') }
        if ($testRows.Count -eq 2) {
            $a = $testRows[0]; $b = $testRows[1]
            if ($a.Name -cne 'NEUTRAL_STAGED' -or $a.Identity -cne $neutral -or $a.State -ne 64 -or $a.Visibility -ne 2 -or $a.Owner -cne $parentN -or $a.OwnerDWORD -ne 196672 -or $a.ParentState -ne 64 -or $a.ParentVisibility -ne 2) { $errors.Add('NEUTRAL_TOPOLOGY_MISMATCH') }
            if ($b.Name -cne 'EN_US_SATELLITE' -or $b.Identity -cne $satellite -or $b.State -ne 112 -or $b.Visibility -ne 2 -or $b.Owner -cne $parentS -or $b.OwnerDWORD -ne 196720 -or $b.ParentState -ne 112 -or $b.ParentVisibility -ne 2) { $errors.Add('SATELLITE_TOPOLOGY_MISMATCH') }
        }
        return @($errors.ToArray())
    }
    $expectedSha = 'F8F2FFF0A40508C88F8426B2923FEDCF9B00F3FFF3A5637A13C0EB0006E8BA7E'
    $positive = @(ContractErrors $rows $expectedSha $neutral 1)
    if ($positive.Count -ne 0) { throw ('POSITIVE_FIXTURE_REJECTED_' + ($positive -join ',')) }
    $cases = @(
        @('NEG_WRONG_PARENT', [ordered]@{ Owner='UNEXPECTED_PARENT' }, 0, 'NEUTRAL_TOPOLOGY_MISMATCH'),
        @('NEG_WRONG_STATE', [ordered]@{ State=112 }, 0, 'NEUTRAL_TOPOLOGY_MISMATCH'),
        @('NEG_WRONG_VISIBILITY', [ordered]@{ Visibility=1 }, 0, 'NEUTRAL_TOPOLOGY_MISMATCH'),
        @('NEG_WRONG_OWNER_DWORD', [ordered]@{ OwnerDWORD=196720 }, 0, 'NEUTRAL_TOPOLOGY_MISMATCH'),
        @('NEG_SATELLITE_OWNER', [ordered]@{ Owner='UNEXPECTED_PARENT' }, 1, 'SATELLITE_TOPOLOGY_MISMATCH'),
        @('NEG_PARENT_STATE', [ordered]@{ ParentState=112 }, 0, 'NEUTRAL_TOPOLOGY_MISMATCH')
    )
    $negativePasses = 0
    foreach ($case in $cases) {
        $test = @(foreach ($r in $rows) { $clone = [ordered]@{}; foreach ($key in $r.Keys) { $clone[$key] = $r[$key] }; $clone })
        foreach ($k in $case[1].Keys) { $test[[int]$case[2]][$k] = $case[1][$k] }
        $bad = @(ContractErrors $test $expectedSha $neutral 1)
        if ($bad -notcontains [string]$case[3]) { throw ('NEGATIVE_NOT_REJECTED_' + $case[0]) }
        $negativePasses++
    }
    if (@(ContractErrors $rows ('0' * 64) $neutral 1) -notcontains 'WRONG_SOURCE_SHA') { throw 'NEG_SOURCE_SHA_NOT_REJECTED' }
    $negativePasses++
    if (@(ContractErrors $rows $expectedSha $satellite 1) -notcontains 'WRONG_NEUTRAL_ID') { throw 'NEG_NEUTRAL_ID_NOT_REJECTED' }
    $negativePasses++
    if (@(ContractErrors $rows $expectedSha $neutral 2) -notcontains 'OVERBROAD_REMOVE_SCOPE') { throw 'NEG_SCOPE_NOT_REJECTED' }
    $negativePasses++
    if (@(ContractErrors @($rows[0]) $expectedSha $neutral 1) -notcontains 'WRONG_CARDINALITY') { throw 'NEG_MISSING_SATELLITE_NOT_REJECTED' }
    $negativePasses++
    Note 'POSITIVE_TOPOLOGY_FIXTURE=PASS'
    Note ('NEGATIVE_TOPOLOGY_FIXTURES=PASS_' + $negativePasses + '_OF_' + $negativePasses)
    $contract = [ordered]@{
        contract_id = 'BL.ONEDRIVE.26300.9807.R20R2F13'
        contract_mode = 'STATIC_ONLY_NO_IMAGE_OR_CBS_MUTATION'
        source_build = '26300.9807'
        source_candidate_path = 'C:\BLR20R2F5\R20R2F6_exports\WebViewRemoved_26300_9807_MAX.wim'
        source_candidate_size = 6407308664
        source_candidate_sha256 = $expectedSha
        source_original_path = 'C:\work\26300.9807-UUP\install.wim'
        source_original_sha256 = '0FB778D4696DABA17EDC52E6391A3F217982422FB920C98C8273E0C51A094B49'
        mutation_authorized = $false
        reviewed_mutation_script_exists = $false
        only_future_direct_native_remove_candidate = $neutral
        en_us_satellite = $satellite
        child_and_parent_expected = $rows
        retained = @($parentN,$parentS,'OneDriveBackup')
        future_guard = @(
            'Separate operator GUI approval and full mutation-code review required',
            'One NEW owned disposable clone under C:\work\E2E; original and WebViewRemoved source immutable',
            'Before any CBS write: live source hashes, index=1, exact mount-owner and both parent/child states/owner cardinality',
            'Only staged neutral child is proposed for visibility 2->1 and exact single Owners removal',
            'Never directly modify en-US satellite, LTSB parent keys or OneDriveBackup',
            'Native DISM /Remove-Package neutral only after hive unload and just the exact authorized target',
            'All two original OneDrive package identities must become nonresolving; System32 OneDriveSetup absent, WinSxS OneDrive-Setup absent; OneDriveBackup retained',
            'Pending=0, native CheckHealth/ScanHealth CLEAN, retained protected floor unchanged, no unknown delta',
            'Unexpected state/exit/leftover/health => DISCARD new owned WIM, no source change',
            'Do not claim predicted size saving before controlled clean export'
        )
        historical_s31_is_not_9807_certificate = $true
        positive_fixture_passed = $true
        negative_fixture_count = $negativePasses
        next = 'PREPARE_REVIEWED_DISPOSABLE_9807_SINGLE_STAGED_MUTATION_SCRIPT_THEN_REQUIRE_GUI_APPROVAL'
    }
    [IO.File]::WriteAllText($json,(ConvertTo-Json -InputObject $contract -Depth 12),$utf8)
    Note 'PLAN_JSON_WRITTEN=PASS'
    Note 'IMAGE_HASH_RECHECK=DEFERRED_TO_FUTURE_OPERATOR_AUTHORIZED_DISPOSABLE_RUN'
    Note 'DISM_REG_WIM_CLONE_AND_CBS_WRITE=NOT_RUN'
    Note 'RESULT=PASS_R20R2F13_STATIC_SOURCE_BOUND_CANDIDATE_AND_NEGATIVE_FIXTURES'
} catch {
    Note ('RESULT=HOLD_R20R2F13_STATIC_' + $_.Exception.Message)
    throw
} finally {
    [IO.File]::WriteAllLines($log,$lines,$utf8)
}
