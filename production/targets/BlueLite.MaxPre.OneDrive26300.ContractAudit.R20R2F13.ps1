$ErrorActionPreference = 'Stop'
$p = 'C:\work\scripts\BlueLite.MaxPre.OneDrive26300.Contract.R20R2F13.ps1'
$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($p,[ref]$tokens,[ref]$errors)
if ($errors.Count -ne 0) { throw ('AST_PARSER_ERRORS=' + ($errors | Out-String)) }
$calls = @($ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.CommandAst] }, $true))
$forbidden = @('Remove-Item','reg.exe','reg','dism.exe','dism','Mount-WindowsImage','Set-ItemProperty')
foreach ($call in $calls) {
    if ($call.GetCommandName() -in $forbidden) { throw ('FORBIDDEN_EXECUTABLE_AST=' + $call.GetCommandName()) }
}
$hash = (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash
Write-Output ('RESULT=PASS_R20R2F13_AST_STATIC_ONLY')
Write-Output ('SCRIPT_SHA256=' + $hash)
Write-Output ('SCRIPT_BYTES=' + ([IO.File]::ReadAllBytes($p).Length))
Write-Output ('AST_STATEMENTS=' + $ast.EndBlock.Statements.Count)
