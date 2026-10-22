# BlueLite R002-R20: bounded synthetic stdin/EOF diagnostic v1; execution state belongs to its receipt.
# Tests tiny local fixtures only. Never invokes old adapters or changes security settings.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSEdition -cne 'Core' -or $PSVersionTable.PSVersion.Major -lt 7) {
    throw 'R20_REQUIRES_POWERSHELL_7'
}
$cycleRoot = 'C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package'
$fixtureRoot = Join-Path $cycleRoot '04_StaticTests\R002R20_InputEof_001'
$evidenceRoot = Join-Path $cycleRoot '05_Evidence\R002R20_InputEof_001'
foreach ($ownedPath in @($fixtureRoot, $evidenceRoot)) {
    if (Test-Path -LiteralPath $ownedPath) { throw 'R20_OWNED_PATH_COLLISION' }
}
$childExe = Join-Path $PSHOME 'pwsh.exe'
if (-not [IO.File]::Exists($childExe)) { throw 'R20_NATIVE_PWSH_ABSENT' }
$fixtureA = @'
[CmdletBinding()]
param()
Write-Output 'R20_BEGIN'
$input = 'fixture'
Write-Output ('R20_VALUE=' + $input)
Write-Output 'R20_END'
'@
$fixtureB = $fixtureA.Replace('$input', '$sourceRoot')
function InputReferenceCount([string]$sourceText) {
    $parseTokens = $null
    $parseErrors = $null
    $tree = [Management.Automation.Language.Parser]::ParseInput(
        $sourceText, [ref]$parseTokens, [ref]$parseErrors)
    if (@($parseErrors).Count -ne 0) { throw 'R20_AST_ERROR' }
    $references = @($tree.FindAll({
        param($node)
        $node -is [Management.Automation.Language.VariableExpressionAst] -and
        $node.VariablePath.UserPath -match '(^|:)input$'
    }, $false))
    return $references.Count
}
if ((InputReferenceCount $fixtureA) -ne 2 -or
    (InputReferenceCount $fixtureB) -ne 0 -or
    (InputReferenceCount ([IO.File]::ReadAllText($PSCommandPath))) -ne 0) {
    throw 'R20_AST_INPUT_PREDICATE_MISMATCH'
}
$rows = [Collections.Generic.List[object]]::new()
$utf8 = [Text.UTF8Encoding]::new($false)
$receiptPath = Join-Path $evidenceRoot 'R002R20_InputEof_NativeReceipt.json'
$report = [ordered]@{
    task = 'R002R20_SYNTHETIC_INPUT_EOF'
    started_utc = [DateTime]::UtcNow.ToString('o')
    powershell_version = $PSVersionTable.PSVersion.ToString()
    parent_pid = $PID
    script_sha256 = (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
    native_executable = $childExe
    original_adapters_executed = $false
    network_requests = 0
    image_registry_security_mutations = 0
    result = 'RUNNING'
    error = $null
    fixture_sha256 = [ordered]@{}
    cases = @()
}
function RunCase([string]$caseName, [string]$scriptPath, [string]$stdinMode, [int]$holdMs) {
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $childExe
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.WorkingDirectory = $fixtureRoot
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in @('-NoLogo', '-NoProfile', '-NonInteractive', '-File', $scriptPath)) {
        [void]$startInfo.ArgumentList.Add($argument)
    }
    $child = [Diagnostics.Process]::new()
    $child.StartInfo = $startInfo
    $started = $false
    $clock = [Diagnostics.Stopwatch]::StartNew()
    $row = [ordered]@{
        case = $caseName; stdin = $stdinMode; child_pid = $null
        before_eof_exited = $null; before_eof_first_line = $null
        exit_code = $null; elapsed_ms = $null; stdout = $null; stderr = $null
        result = 'RUNNING'; cleanup = 'NOT_NEEDED'; error = $null
    }
    $rows.Add($row)
    try {
        if (-not $child.Start()) { throw 'R20_CHILD_START_FALSE' }
        $started = $true
        $row.child_pid = $child.Id
        $firstLine = $child.StandardOutput.ReadLineAsync()
        $errorText = $child.StandardError.ReadToEndAsync()
        if ($stdinMode -ceq 'CLOSED') {
            $child.StandardInput.Close()
        } elseif ($stdinMode -ceq 'HELD_THEN_CLOSED') {
            $row.before_eof_exited = $child.WaitForExit($holdMs)
            $row.before_eof_first_line = $firstLine.IsCompleted
            $child.StandardInput.Close()
        } elseif ($stdinMode -cne 'LEFT_OPEN') {
            throw 'R20_UNKNOWN_STDIN_MODE'
        }
        if (-not $child.WaitForExit(3000)) { throw 'R20_CHILD_TIMEOUT_3000MS' }
        if (-not $firstLine.Wait(1000) -or -not $errorText.Wait(1000)) {
            throw 'R20_OUTPUT_COMPLETION_TIMEOUT'
        }
        $tail = $child.StandardOutput.ReadToEndAsync()
        if (-not $tail.Wait(1000)) { throw 'R20_STDOUT_TAIL_TIMEOUT' }
        $row.exit_code = $child.ExitCode
        $row.elapsed_ms = $clock.ElapsedMilliseconds
        $row.stdout = ($firstLine.GetAwaiter().GetResult() + "`n" + $tail.GetAwaiter().GetResult()).Replace("`r`n", "`n").TrimEnd()
        $row.stderr = $errorText.GetAwaiter().GetResult()
        if ($row.exit_code -ne 0 -or $row.stderr.Length -ne 0 -or
            $row.stdout -cne "R20_BEGIN`nR20_VALUE=fixture`nR20_END") {
            throw 'R20_CHILD_EXACT_OUTPUT_OR_EXIT_MISMATCH'
        }
        if ($stdinMode -ceq 'HELD_THEN_CLOSED' -and
            ($row.before_eof_exited -or $row.before_eof_first_line)) {
            throw 'R20_INPUT_EOF_HYPOTHESIS_NOT_REPRODUCED'
        }
        $row.result = 'PASS'
        Write-Output ('R20_CASE_PASS=' + $caseName + ';MS=' + $row.elapsed_ms)
    } catch {
        $row.result = 'HOLD'
        $row.error = $_.Exception.Message
        throw
    } finally {
        if ($started) {
            try {
                if (-not $child.HasExited) {
                    $child.Kill($true)
                    if (-not $child.WaitForExit(1000)) { throw 'R20_OWNED_CHILD_CLEANUP_TIMEOUT' }
                    $row.cleanup = 'OWNED_CHILD_TERMINATED'
                } else {
                    $row.cleanup = 'OWNED_CHILD_EXITED'
                }
            } finally {
                $child.Dispose()
            }
        } else {
            $child.Dispose()
        }
    }
}
try {
    [void][IO.Directory]::CreateDirectory($evidenceRoot)
    [void][IO.Directory]::CreateDirectory($fixtureRoot)
    $pathA = Join-Path $fixtureRoot 'AutomaticInput.ps1'
    $pathB = Join-Path $fixtureRoot 'OrdinarySourceRoot.ps1'
    [IO.File]::WriteAllText($pathA, $fixtureA, $utf8)
    [IO.File]::WriteAllText($pathB, $fixtureB, $utf8)
    $report.fixture_sha256['A'] = (Get-FileHash -LiteralPath $pathA -Algorithm SHA256).Hash
    $report.fixture_sha256['B'] = (Get-FileHash -LiteralPath $pathB -Algorithm SHA256).Hash
    Write-Output ('R20_BEGIN_NATIVE_DIAGNOSTIC;PS=' + $report.powershell_version)
    RunCase 'RENAMED_LEFT_OPEN' $pathB 'LEFT_OPEN' 0
    RunCase 'INPUT_CLOSED' $pathA 'CLOSED' 0
    $holdBudget = [int][Math]::Min(3000, [Math]::Max(1500, [int]$rows[1].elapsed_ms + 1000))
    RunCase 'INPUT_HELD_THEN_CLOSED' $pathA 'HELD_THEN_CLOSED' $holdBudget
    $report.result = 'PASS_R002R20_SYNTHETIC_INPUT_EOF_MECHANISM'
} catch {
    $report.result = 'HOLD_R002R20_SYNTHETIC_INPUT_EOF'
    $report.error = $_.Exception.Message
} finally {
    $report.cases = @($rows.ToArray())
    $report.finished_utc = [DateTime]::UtcNow.ToString('o')
    if ([IO.Directory]::Exists($evidenceRoot)) {
        [IO.File]::WriteAllText($receiptPath, ($report | ConvertTo-Json -Depth 8), $utf8)
    }
}
Write-Output ('RESULT=' + $report.result)
Write-Output ('RECEIPT=' + $receiptPath)
if ($report.result -cne 'PASS_R002R20_SYNTHETIC_INPUT_EOF_MECHANISM') { exit 86 }
exit 0

