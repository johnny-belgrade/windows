param([string]$Path,[string]$ExpectedSha256)
$ErrorActionPreference='Stop'
if((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash -ne $ExpectedSha256){throw 'Receipt SHA mismatch'}
$r=Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json
if($r.actual_exit -ne $r.expected_exit){throw 'Unexpected child exit'}
if((Get-FileHash -LiteralPath $r.log -Algorithm SHA256).Hash -ne $r.log_sha256){throw 'Native log SHA mismatch'}
$t=Get-Content -LiteralPath $r.log -Raw
if($t -notmatch $r.expected_marker){throw 'Native marker missing'}
if($r.status -ne 'PASS' -or -not $r.script_sha256 -or -not $r.utc){throw 'Incomplete receipt'}
Write-Output ('INDEPENDENT_RECEIPT_PASS '+$r.test);exit 0
