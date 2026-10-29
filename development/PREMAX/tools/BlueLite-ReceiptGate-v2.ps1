# BlueLite Hybrid Workflow v2 — independent receipt gate, not a script executor.
# PS7; Record and Verify MUST be separate native actions.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Record','Verify')][string]$Mode,
    [Parameter(Mandatory)][string]$ReceiptPath,
    [string]$OperationId,
    [string]$Action,
    [ValidateSet('PASS','HOLD','FAIL','NOT_RUN')][string]$Outcome = 'NOT_RUN',
    [string]$SourcePath = '',
    [string]$SourceSha256 = '',
    [string]$EvidencePath = '',
    [string]$Next = '',
    [string]$Detail = '',
    [string]$ExpectedSha256 = ''
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
function Require([bool]$Condition, [string]$Failure) {
    if (-not $Condition) { throw "BLV2_HOLD_$Failure" }
}
$full = [IO.Path]::GetFullPath($ReceiptPath)
$roots = @('C:\work\logs\', 'C:\work\PREMAX-work\')
$valid = $false
foreach ($root in $roots) {
    if ($full.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { $valid = $true; break }
}
Require $valid 'RECEIPT_PATH_OUTSIDE_APPROVED_LOG_ROOTS'
Require ($full.EndsWith('.json',[StringComparison]::OrdinalIgnoreCase)) 'RECEIPT_EXTENSION'
$dir = [IO.Path]::GetDirectoryName($full)
Require ([IO.Directory]::Exists($dir)) 'PARENT_NOT_FOUND'
$walk = $dir
while ($walk -and $walk.Length -ge 3) {
    $entry = Get-Item -LiteralPath $walk -Force
    Require (-not (($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) 'PARENT_REPARSE'
    if ($walk.Equals('C:\work',[StringComparison]::OrdinalIgnoreCase)) { break }
    $walk = [IO.Path]::GetDirectoryName($walk)
}
if ($Mode -eq 'Record') {
    Require ($OperationId -match '^[A-Za-z0-9][A-Za-z0-9_-]{2,79}$') 'OPERATION_ID'
    Require (-not [string]::IsNullOrWhiteSpace($Action)) 'ACTION_REQUIRED'
    Require (-not [string]::IsNullOrWhiteSpace($Next)) 'NEXT_REQUIRED'
    if ($SourceSha256) { Require ($SourceSha256 -match '^[a-fA-F0-9]{64}$') 'SOURCE_SHA' }
    $item = [ordered]@{
        schema = 'BlueLite.Receipt.v2'
        operation_id = $OperationId
        action = $Action
        outcome = $Outcome
        recorded_utc = [DateTime]::UtcNow.ToString('o')
        source_path = $SourcePath
        source_sha256 = $SourceSha256.ToUpperInvariant()
        evidence_path = $EvidencePath
        detail = $Detail
        one_next = $Next
        qa = 'PENDING_INDEPENDENT_READBACK'
    }
    $json = (ConvertTo-Json -InputObject $item -Depth 6) + [Environment]::NewLine
    $data = [Text.UTF8Encoding]::new($false).GetBytes($json)
    $stream = [IO.FileStream]::new($full, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try { $stream.Write($data,0,$data.Length); $stream.Flush($true) } finally { $stream.Dispose() }
    $sha = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
    Write-Output "BLV2_RECORDED|ID=$OperationId|SHA256=$sha|BYTES=$($data.Length)|QA=PENDING"
    exit 0
}
Require ($ExpectedSha256 -match '^[a-fA-F0-9]{64}$') 'EXPECTED_SHA_REQUIRED'
Require ([IO.File]::Exists($full)) 'RECEIPT_NOT_FOUND'
$leaf = Get-Item -LiteralPath $full -Force
Require (-not (($leaf.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) 'RECEIPT_REPARSE'
$observed = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
Require ($observed -eq $ExpectedSha256.ToUpperInvariant()) 'SHA_MISMATCH'
$rec = Get-Content -LiteralPath $full -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 6
Require ($rec.schema -ceq 'BlueLite.Receipt.v2') 'SCHEMA'
Require ($rec.operation_id -match '^[A-Za-z0-9][A-Za-z0-9_-]{2,79}$') 'ID'
Require ($rec.outcome -in @('PASS','HOLD','FAIL','NOT_RUN')) 'OUTCOME'
Require (-not [string]::IsNullOrWhiteSpace($rec.one_next)) 'NEXT'
Require ($rec.qa -ceq 'PENDING_INDEPENDENT_READBACK') 'QA_STATE'
Write-Output "BLV2_INDEPENDENT_READBACK_PASS|ID=$($rec.operation_id)|OUTCOME=$($rec.outcome)|SHA256=$observed|LOCAL_QA_PASS_ONLY"
