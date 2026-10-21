# R20R2F14 static scope/source/AST; never runs target.
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$target='C:\work\scripts\BlueLite.MaxPre.OneDrive26300.AmberDisposable.R20R2F14.ps1'
$spec='C:\work\logs\BlueLite_26300_9807_OneDriveContract_R20R2F13.json'
$tokens=$null
$errors=$null
$ast=[System.Management.Automation.Language.Parser]::ParseFile($target,[ref]$tokens,[ref]$errors)
if($errors.Count -ne 0){throw ('AST_ERRORS='+($errors|Out-String))}
$c=[IO.File]::ReadAllText($target)
$j=Get-Content -LiteralPath $spec -Raw | ConvertFrom-Json
if($j.negative_fixture_count -ne 10 -or -not $j.positive_fixture_passed){throw 'R13_GUARDS_NOT_CERTIFIED'}
foreach($required in @(
  $j.only_future_direct_native_remove_candidate,
  $j.en_us_satellite,
  $j.child_and_parent_expected[0].Owner,
  $j.child_and_parent_expected[1].Owner,
  $j.source_candidate_sha256,
  $j.source_original_sha256,
  'R14_OUTPUT_PATH_EXISTS_NO_OVERWRITE',
  'OFFLINE_HIVE_UNLOAD_FAILED',
  'PRE_EXISTING_MOUNT_FAIL_CLOSED',
  'POST_TARGET_STILL_RESOLVING',
  'CBS_SCANHEALTH_FAILURE',
  'OWNED_UNMOUNT_ACTION',
  'NEUTRAL_CHILD_ONLY_DECOUPLED=PASS'
)){
  if(-not $c.Contains([string]$required)){throw ('MISSING_GUARD='+$required)}
}
$cntRemove=@([regex]::Matches($c,"'/Remove-Package'")).Count
$cntExport=@([regex]::Matches($c,"'export'")).Count
$cntDelete=@([regex]::Matches($c,"'delete'")).Count
$cntRegAdd=@([regex]::Matches($c,"'add'")).Count
if($cntRemove -ne 1 -or $cntExport -ne 1 -or $cntDelete -ne 1 -or $cntRegAdd -ne 1){throw "MUTATION_SCOPE_STATIC_COUNT_FAIL:$cntRemove/$cntExport/$cntDelete/$cntRegAdd"}
if($c -match '(?i)\bRemove-Item\b|\bResetBase\b|\bClear-Disk\b|\bRemove-WindowsPackage\b'){throw 'BROAD_MUTATOR_FOUND'}
if(-not $c.Contains("Run 'REMOVE_ONE_NEUTRAL'")){throw 'NATIVE_REMOVE_EXACT_LABEL_MISSING'}
if(-not $c.Contains("Run 'DELETE_NEUTRAL_OWNERS'")){throw 'NEUTRAL_OWNERS_EXACT_LABEL_MISSING'}
if(-not $c.Contains('"/PackageName:$neut"')){throw 'REMOVE_NEUTRAL_NAME_TOKEN_MISSING'}
if(-not $c.Contains('"$c\$neut\Owners"')){throw 'OWNER_TARGET_TOKEN_MISSING'}
$sha=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
$receipt='C:\work\logs\BlueLite_26300_9807_OneDriveAmberStatic_R20R2F14.txt'
if([IO.File]::Exists($receipt)){throw 'STATIC_RECEIPT_EXISTS_NO_OVERWRITE'}
$rows=@(
  'BLUELITE_R20R2F14_STATIC_SOURCE_REVIEW_ONLY',
  'RESULT=PASS_R20R2F14_AST_SCOPE_SOURCE_STATIC_NO_RUNTIME',
  'NEGATIVE_FIXTURE_REFERENCE=R13_10_OF_10',
  ('SCRIPT_SHA256='+$sha),
  ('SCRIPT_BYTES='+([IO.File]::ReadAllBytes($target).Length)),
  ('SCRIPT_LINES='+(@([IO.File]::ReadAllLines($target)).Count)),
  'REG_BLOCK_CHANGE=NOT_RUN',
  'WIM_MOUNT_UNMOUNT_CLONE_CBS_MUTATION=NOT_RUN',
  'AUTHORIZATION=USER_APPROVED_PENDING_TOTALCMD_CLOSURE_CONFIRMATION'
)
[IO.File]::WriteAllLines($receipt,$rows,[Text.UTF8Encoding]::new($false))
$rows
