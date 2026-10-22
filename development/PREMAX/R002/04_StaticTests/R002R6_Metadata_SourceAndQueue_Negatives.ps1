# BlueLite R002R6: six bounded synthetic D4 negative queue tests + real executor deny.
# No network and no actual source changes; fixtures only in unique own subtree.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root='C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package'
$target=Join-Path $root '04_StaticTests\R002R6_Negatives_001'
if ([IO.Directory]::Exists($target)) { throw 'R002R6_NEGATIVE_FIXTURE_COLLISION' }
$module='C:\work\scripts\BlueLite_Stage1_S06_26300_G4_AppsOnly\BlueLite_QueueIdentity.psm1'
$draft=Join-Path $root '03_Drafts\R002R6_9807_TwoQueue_MetadataOnly_DRAFT.ps1'
if ((Get-FileHash $module -Algorithm SHA256).Hash -cne '7015C86B97F91E38D691B2831B9AD353EB6D2369E8AD69559B8DC6FF5E31745E') { throw 'R002R6_D4_DRIFT' }
if ((Get-FileHash $draft -Algorithm SHA256).Hash -cne '755412852CF6E6A16DAC25386DFD988B2743924039BF969E0AB4DB91163D460F') { throw 'R002R6_DRAFT_DRIFT' }
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($draft,[ref]$tokens,[ref]$errors)
if (@($errors).Count -ne 0) { throw 'R002R6_AST_PARSE_HOLD' }
$cmds=@($ast.FindAll({param($a) $a -is [Management.Automation.Language.CommandAst]},$true)|ForEach-Object{$_.GetCommandName()})
if (@($cmds|Where-Object{$_ -match '^(Remove-Item|dism|reg|aria2c|Invoke-Expression|Start-Process)$'}).Count) { throw 'R002R6_FORBIDDEN_COMMAND_AST' }
Import-Module $module -Force
[void][IO.Directory]::CreateDirectory($target)
$nl=[string][char]10
$src='https://example.invalid/payload'+$nl
$sha='sha-256='+('0'*64)
$valid=$src+'  out=sample.cab'+$nl+'  checksum='+$sha+$nl
$cases=[ordered]@{
 'empty'=''
 'missing_checksum'=$src+'  out=sample.cab'+$nl
 'unsafe_out'=$src+'  out=../escape.cab'+$nl+'  checksum='+$sha+$nl
 'unsupported_checksum'=$src+'  out=sample.cab'+$nl+'  checksum=md5=aaa'+$nl
 'duplicate_out'=$valid+$valid
 'server_error'='#UUPDUMP_ERROR: simulated'+$nl
}
$pass=0
foreach($name in $cases.Keys) {
 $p=Join-Path $target ($name+'.txt')
 [IO.File]::WriteAllText($p,$cases[$name],[Text.UTF8Encoding]::new($false))
 $failed=$false
 try { $null=Get-BlueLiteQueueIdentity -Path $p } catch { $failed=$true }
 if (-not $failed) { throw "NEGATIVE_FAIL_OPEN=$name" }
 $pass++
}
$denied=$false
try { & $draft -Mode Fetch -Authorization NOT_AUTHORIZED | Out-Null } catch { if ($_.Exception.Message -like '*EXPLICIT_GUI_APPROVAL_REQUIRED*') { $denied=$true } }
if (-not $denied) { throw 'FETCH_WITHOUT_APPROVAL_DID_NOT_FAIL_CLOSED' }
$pass++
$receipt=Join-Path $target 'R002R6_NativeStaticTest.txt'
@(
 'R002R6_NATIVE_STATIC_NEGATIVES',
 'DRAFT_SHA256=755412852CF6E6A16DAC25386DFD988B2743924039BF969E0AB4DB91163D460F',
 'AST_ERRORS=0',
 "AST_COMMANDS=$($cmds.Count)",
 "EXPECTED_NEGATIVES=$pass/7",
 'NO_EXTERNAL_NETWORK=TRUE',
 'NO_UUP_PAYLOAD=TRUE',
 'RESULT=PASS_R002R6_7_OF_7_NEGATIVE_TESTS'
) | Set-Content -LiteralPath $receipt -Encoding utf8NoBOM
"RESULT=PASS_R002R6_7_OF_7_NEGATIVE_TESTS;AST_COMMANDS=$($cmds.Count);NO_NETWORK=TRUE"