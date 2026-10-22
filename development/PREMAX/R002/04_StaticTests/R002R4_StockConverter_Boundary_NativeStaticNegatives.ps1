# R002R4 local-native strict AST + real pinned v128m source positive + synthetically altered input negatives.
# Never executes vendor CMD; all mutations restricted to fresh isolated negative fixture JSON/text.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root='C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package'
$source=Join-Path $root '03_Drafts\R002R4_StockConverter_PreISO_BoundaryAudit_DRAFT.ps1'
$contract=Join-Path $root '01_Inputs\R002R4_StockConverterPreISO_Contract.json'
$negative=Join-Path $root '04_StaticTests\R002R4_StockConverter_Negatives_001'
if(Test-Path -LiteralPath $negative){throw 'R002R4_NEGATIVE_DIRECTORY_PREEXISTS'}
[void][IO.Directory]::CreateDirectory($negative)
$tok=$null;$err=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($source,[ref]$tok,[ref]$err)
if(@($err).Count -gt 0){throw 'R002R4_AST_SYNTAX_FAIL'}
$commands=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.CommandAst]},$true))
$forbid=@($commands|Where-Object {$_.GetCommandName() -match '^(Invoke-WebRequest|Invoke-RestMethod|Start-Process|aria2c|dism|reg|Remove-Item|Mount-WindowsImage|Dismount-WindowsImage|Export-WindowsImage)$'})
if($forbid.Count){throw 'R002R4_AST_UNAUTHORIZED_MUTATION_OR_NETWORK'}
Write-Output ('R002R4_AST_PASS;COMMANDS='+$commands.Count)
$positive=@(& $source -ContractPath $contract -ErrorAction Stop)
if(@($positive|Where-Object {$_ -eq 'R002R4_SOURCE_BOUNDARY=PASS_ORIGINAL_V128M_SOURCE_BRANCH_ORDER'}).Count -ne 1 -or @($positive|Where-Object {$_ -eq 'R002R4_RUNTIME_ALLOWED=FALSE'}).Count -ne 1){throw 'R002R4_POSITIVE_OUTPUT_MISMATCH'}
Write-Output 'R002R4_REAL_STOCK_SOURCE_BOUNDARY_POSITIVE=PASS'
function Negative([string]$Name,[string]$Expect,[scriptblock]$Transform){
 $doc=Get-Content -LiteralPath $contract -Raw|ConvertFrom-Json
 & $Transform $doc
 $path=Join-Path $negative ($Name+'.json')
 [IO.File]::WriteAllText($path,($doc|ConvertTo-Json -Depth 25),[Text.UTF8Encoding]::new($false))
 try {
  $null=@(& $source -ContractPath $path -ErrorAction Stop)
  throw ('R002R4_NEGATIVE_UNEXPECTED_ACCEPT='+$Name)
 }catch{
  $msg=$_.Exception.Message
  if($msg -like 'R002R4_NEGATIVE_UNEXPECTED_ACCEPT=*'){throw}
  if($msg -notlike ('*R002R4_FAIL_CLOSED='+$Expect+'*')){throw ('R002R4_NEGATIVE_WRONG_GATE='+$Name+';'+$msg)}
  Write-Output ('R002R4_NEGATIVE_PASS='+$Name+';GATE='+$Expect)
 }
}
Negative 'runtime_true' 'RUNTIME_FLAG_NOT_FALSE' {param($d)$d.safety.runtime_authorized=$true}
Negative 'cross_version_pretend_proven' 'FROZEN_SOURCE_CROSS_VERSION_NOT_HOLD' {param($d)$d.frozen_original_source.cross_version_compatibility_certified=$true}
Negative 'auto_start_single_wim' 'AUTOSTART_ISO_WIM_ONLY_REQUIRED' {param($d)$d.intended_vendor_options.AutoStart='3'}
Negative 'skip_iso_disabled' 'SKIPISO_REQUIRED_FOR_PREISO_HANDOFF' {param($d)$d.intended_vendor_options.SkipISO='0'}
Negative 'skip_installed_winre' 'WINRE_PRESERVE_REQUIRED' {param($d)$d.intended_vendor_options.SkipWinRE='1'}
Negative 'start_virtual_editions' 'VIRTUAL_EDITION_UNREVIEWED' {param($d)$d.intended_vendor_options.StartVirtual='1'}
Negative 'wim_to_esd' 'WIM_FORMAT_REQUIRED' {param($d)$d.intended_vendor_options.wim2esd='1'}
Negative 'output_outside_cwork' 'OUTPUT_CWORK_SCOPE' {param($d)$d.handoff.output_directory='C:\BLR20R2F5\not_allowed_for_heavy\ISO'}
Negative 'upstream_sha_drift' 'UPSTREAM_SOURCE_SHA_DRIFT' {param($d)$d.upstream.local_snapshot_sha256='0'*64}
Negative 'wrong_converter_version' 'UPSTREAM_VERSION_SELECTION_MISMATCH' {param($d)$d.upstream.version='v126'}
$original=(Get-Content -LiteralPath $contract -Raw|ConvertFrom-Json).upstream.local_snapshot
$originalText=[IO.File]::ReadAllText($original)
$altered=$originalText.Replace('if %SkipISO% neq 0 (','if %SkipISO% equ 0 (')
if($originalText -ceq $altered){throw 'SOURCE_ALTERED_NEGATIVE_NOT_CHANGED'}
$mutated=Join-Path $negative 'AlteredVendorSource_STATIC_ONLY.txt'
[IO.File]::WriteAllText($mutated,$altered,[Text.UTF8Encoding]::new($false))
Negative 'semantic_wrong_skipiso_branch_repinned_sha' 'SOURCE_SKIPISO_GATE_MISSING' {
 param($d)
 $d.upstream.local_snapshot=$mutated
 $d.upstream.local_snapshot_sha256=(Get-FileHash -LiteralPath $mutated -Algorithm SHA256).Hash
}
Write-Output 'R002R4_NEGATIVE_TESTS=11_OF_11_PASS'
Write-Output 'R002R4_OVERALL=PASS_SOURCE_BOUNDARY_AND_NEGATIVE_STATIC_ONLY_NO_VENDOR_EXECUTION'
