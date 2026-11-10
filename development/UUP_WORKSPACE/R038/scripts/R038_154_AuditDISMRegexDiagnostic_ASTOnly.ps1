# R038 OP154 strictly AST-only static source audit, never invokes target script.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$path='C:\work\scripts\R038_154_DISM_IndexField_RegexFixture_ReadOnly.ps1'
$result=[ordered]@{schema='BlueLite.R038.OP154.DISMRegexSourceAST.v1';status='HOLD';path=$path;bytes=$null;sha256=$null;parser_errors=$null;errors=@();error=$null}
try{
 $f=Get-Item -LiteralPath $path -ErrorAction Stop
 if(($f.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'SOURCE_REPARSE'}
 $result.bytes=[long]$f.Length
 $result.sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
 $tok=$null;$errs=$null
 [void][System.Management.Automation.Language.Parser]::ParseFile($path,[ref]$tok,[ref]$errs)
 $result.parser_errors=@($errs).Count
 $result.errors=@($errs|ForEach-Object {$_.Message})
 if($result.parser_errors -ne 0){throw 'SOURCE_AST_PARSE_HOLD'}
 $result.status='SOURCE_AST0_SHA_READONLY_PASS'
}catch{$result.error=$_.Exception.Message}
$result|ConvertTo-Json -Depth 4
if($result.status -ne 'SOURCE_AST0_SHA_READONLY_PASS'){exit 2}
exit 0
