# R002R2 read-only postfixture and deliberate fail-closed negative tests.
# Does not execute extracted launcher/stub or contact network.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root='C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package'
$draft=Join-Path $root '03_Drafts\R002R2_OverlayQueue_Adapter_DRAFT.ps1'
$fixture=Join-Path $root '04_StaticTests\R002R2_Fixture_001'
$profile=Join-Path $root '01_Inputs\R002_Stage1_Profile_9711.json'
$bad=Join-Path $root '04_StaticTests\R002R2_WrongSourceSHA_Fixture.json'
$src=Get-Content -LiteralPath $profile -Raw | ConvertFrom-Json
$tok=$null;$err=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($draft,[ref]$tok,[ref]$err)
if(@($err).Count -ne 0){throw 'AST_FAIL'}
$cmds=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.CommandAst]},$true))
if(@($cmds | Where-Object {$_.GetCommandName() -match '^(Invoke-WebRequest|Invoke-RestMethod|aria2c|dism|reg|Mount-WindowsImage|Dismount-WindowsImage|Export-WindowsImage|Remove-Item)$'}).Count -gt 0){throw 'FORBIDDEN_NETWORK_OR_WIM_CMD'}
Write-Output ('R002R2_AST=PASS;COMMANDS='+$cmds.Count)
$gate=Get-Content -LiteralPath (Join-Path $fixture 'BlueLite\FixtureGate.json') -Raw | ConvertFrom-Json
if($gate.status -cne 'PASS_STATIC_FIXTURE_ONLY' -or $gate.runtime_authorized -ne $false -or $gate.windows_full -ne 98 -or $gate.apps_closed_staging -ne 32){throw 'FIXTURE_CONTRACT_FALSE'}
$stub=Get-Content -LiteralPath (Join-Path $fixture 'BlueLite_Stage1.cmd') -Raw
if($stub -notmatch '(?im)^exit /b 86\s*$'){throw 'ENTRYPOINT_NOT_DENY_ONLY'}
Add-Type -AssemblyName System.IO.Compression
$z=[IO.Compression.ZipFile]::OpenRead([string]$src.source.zip_path)
try {
 foreach($ent in $z.Entries) {
  $path=Join-Path $fixture $ent.FullName.Replace('/','\')
  $stream=$ent.Open()
  try{$buffer=[IO.MemoryStream]::new();try{$stream.CopyTo($buffer);$bytes=$buffer.ToArray()}finally{$buffer.Dispose()}}finally{$stream.Dispose()}
  $local=[IO.File]::ReadAllBytes($path)
  if($bytes.Length -ne $local.Length -or -not ([Linq.Enumerable]::SequenceEqual([byte[]]$bytes,[byte[]]$local))){throw ('UPSTREAM_MEMBER_NOT_BYTE_EXACT='+$ent.FullName)}
 }
 Write-Output ('R002R2_UPSTREAM_MEMBERS_BYTE_EQUAL='+$z.Entries.Count)
}finally{$z.Dispose()}
Import-Module -Name $src.queue.module_path -Force -ErrorAction Stop
$w=Assert-BlueLiteQueueSamePayload -Baseline $src.queue.frozen_windows -Candidate (Join-Path $fixture 'BlueLite\Queues\Windows.full.active.aria2.txt')
$a=Assert-BlueLiteQueueSamePayload -Baseline 'C:\work\E2E\BlueLite_Stage1_S06_26300_9711_2b22470a\Queues\AppsQueue.filtered.txt' -Candidate (Join-Path $fixture 'BlueLite\Queues\Apps.staging32.active.aria2.txt')
if($w.Count -ne 98 -or $a.Count -ne 32){throw 'OVERLAY_QUEUE_POST_IDENTITY'}
Write-Output 'R002R2_QUEUE_POST_IDENTITY=PASS_WINDOWS_98_G4_APPS_32'
function Expect([string]$Name,[string]$Expected,[scriptblock]$Call){
 try{& $Call | Out-Null;throw ('NEGATIVE_UNEXPECTED_SUCCESS='+$Name)}
 catch {if($_.Exception.Message -like 'NEGATIVE_UNEXPECTED_SUCCESS=*'){throw};if($_.Exception.Message -notlike ('*'+$Expected+'*')){throw ('NEGATIVE_WRONG_RESULT='+$Name+';'+$_.Exception.Message)}}
 Write-Output ('R002R2_NEGATIVE_PASS='+$Name+';GATE='+$Expected)
}
Expect 'missing_token' 'FIXTURE_AUTH_TOKEN' {& $draft -Mode MaterializeFixture -FixtureDirectory (Join-Path $root '04_StaticTests\R002R2_NoAuth_Nonexistent')}
Expect 'existing_destination' 'FIXTURE_PREEXISTS' {& $draft -Mode MaterializeFixture -FixtureDirectory $fixture -FixtureAuthorization 'I_APPROVE_R002R2_SMALL_FIXTURE_ONLY'}
Expect 'wrong_ownership' 'NOT_OWNED_FIXTURE_PATH' {& $draft -Mode MaterializeFixture -FixtureDirectory 'C:\work\PREMAX-work\R001_Universal_PREMAX_UUP\R002R2_NotOwned' -FixtureAuthorization 'I_APPROVE_R002R2_SMALL_FIXTURE_ONLY'}
if(Test-Path -LiteralPath $bad){throw 'NEGATIVE_SOURCE_FIXTURE_PREEXISTS'}
$badObj=Get-Content -LiteralPath $profile -Raw | ConvertFrom-Json
$badObj.source.zip_sha256='0'*64
[IO.File]::WriteAllText($bad,($badObj|ConvertTo-Json -Depth 20),[Text.UTF8Encoding]::new($false))
Expect 'source_sha_drift' 'FROZEN_ZIP_SHA_DRIFT' {& $draft -Mode AuditOnly -ProfilePath $bad}
if((Get-FileHash -LiteralPath $src.source.zip_path -Algorithm SHA256).Hash -cne $src.source.zip_sha256){throw 'SOURCE_ZIP_CHANGED'}
Write-Output 'R002R2_NEGATIVES=4_OF_4_PASS;SOURCE_ZIP_UNCHANGED=TRUE'
Write-Output 'R002R2_STATIC_RESULT=PASS_SMALL_OVERLAY_AND_D4_G4_INTEGRATION_ONLY'
