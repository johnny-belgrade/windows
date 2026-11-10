# R038 OP68: Native parse/source identity only, NO INVOCATION of cleanup engine.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$path='C:\work\scripts\R038_66_CleanupOwnedStageLeaf.ps1'
$tokens=$null
$parseErrors=$null
$null=[System.Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$parseErrors)
$sha=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
$length=(Get-Item -LiteralPath $path -ErrorAction Stop).Length
$result=[ordered]@{
 schema='BlueLite.R038.ASTSourceAudit.v1'
 source_path=$path
 source_length_bytes=[long]$length
 source_sha256=$sha
 ast_error_count=@($parseErrors).Count
 errors=@($parseErrors|ForEach-Object {$_.Message})
 status=if(@($parseErrors).Count -eq 0){'AST0_SOURCE_HASHED_READ_ONLY_PASS'}else{'AST_SYNTAX_HOLD'}
}
$result|ConvertTo-Json -Depth 5
if($result.status -ne 'AST0_SOURCE_HASHED_READ_ONLY_PASS'){exit 2}
exit 0
