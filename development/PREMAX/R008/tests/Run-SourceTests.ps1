param([Parameter(Mandatory=$true)][string]$Root,[Parameter(Mandatory=$true)][string]$LogRoot)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ps7=(Get-Command pwsh.exe).Source
if(Test-Path -LiteralPath $LogRoot){throw 'Immutable test log root already exists'}
[void][IO.Directory]::CreateDirectory($LogRoot)
$results=New-Object 'System.Collections.Generic.List[object]'
function Fixture([string]$Name){
 $p=Join-Path $Root ('cases\'+$Name)
 if(Test-Path -LiteralPath $p){throw 'Fixture already exists'}
 [void][IO.Directory]::CreateDirectory($p)
 Copy-Item -Path (Join-Path $Root 'candidate\*') -Destination $p -Recurse
 Copy-Item -Path (Join-Path $Root 'fixture\*') -Destination $p -Recurse -Force
 return $p
}
function Run([string]$Name,[string]$Script,[string[]]$Arguments,[int]$Expected,[string]$Marker,[string]$HostExe=$ps7){
 $log=Join-Path $LogRoot ($Name+'.log')
 $psi=[Diagnostics.ProcessStartInfo]::new()
 $psi.FileName=$HostExe;$psi.UseShellExecute=$false;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true;$psi.RedirectStandardInput=$true
 foreach($arg in @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$Script)+$Arguments){[void]$psi.ArgumentList.Add($arg)}
 $proc=[Diagnostics.Process]::new();$proc.StartInfo=$psi
 [void]$proc.Start();$proc.StandardInput.Close()
 $stdout=$proc.StandardOutput.ReadToEndAsync();$stderr=$proc.StandardError.ReadToEndAsync()
 if(-not $proc.WaitForExit(45000)){$proc.Kill($true);$proc.WaitForExit();$code=124}else{$code=$proc.ExitCode}
 $text=@($stdout.GetAwaiter().GetResult(),$stderr.GetAwaiter().GetResult());$proc.Dispose()
 [IO.File]::WriteAllLines($log,[string[]]$text,[Text.UTF8Encoding]::new($false))
 $ok=($code -eq $Expected -and ([IO.File]::ReadAllText($log) -match $Marker))
 $r=[ordered]@{test=$Name;utc=[DateTime]::UtcNow.ToString('o');script=$Script;script_sha256=(Get-FileHash -LiteralPath $Script -Algorithm SHA256).Hash;actual_exit=$code;expected_exit=$Expected;expected_marker=$Marker;log=$log;log_sha256=(Get-FileHash -LiteralPath $log -Algorithm SHA256).Hash;status=$(if($ok){'PASS'}else{'FAIL'});scope='ISOLATED_SOURCE_FIXTURE_NO_DOWNLOAD_NO_CONVERTER_NO_IMAGE';next='Independent receipt verification'}
 $receipt=Join-Path $LogRoot ($Name+'.json')
 [IO.File]::WriteAllText($receipt,($r|ConvertTo-Json -Depth 5),[Text.UTF8Encoding]::new($false))
 if(-not $ok){throw ('TEST_FAILED '+$Name+' code='+$code+' log='+$log)}
 $sha=(Get-FileHash -LiteralPath $receipt -Algorithm SHA256).Hash
 $qa=@(& $ps7 -NoProfile -NonInteractive -File (Join-Path $Root 'tests\Verify-Receipt.ps1') -Path $receipt -ExpectedSha256 $sha 2>&1)
 if($LASTEXITCODE -ne 0 -or ($qa -join "`n") -notmatch 'INDEPENDENT_RECEIPT_PASS'){throw ('QA_FAILED '+$Name)}
 [IO.File]::WriteAllLines((Join-Path $LogRoot ($Name+'.verify.log')),[string[]]$qa)
 $results.Add([pscustomobject]@{test=$Name;receipt_sha256=$sha;status='PASS'})
 Write-Output ('TEST_PASS '+$Name)
}
function Gate([string]$Name,[string]$P,[int]$Exit=1,[switch]$Offline){
 $a=@('-UUPRoot',$P,'-LogPath',(Join-Path $P 'SourceTriad.log'))
 if($Offline){$a+='-OfflineOnly'}else{$a+=@('-WindowsQueueFile',(Join-Path $P 'WindowsQueue.txt'))}
 $m=if($Exit -eq 0){'SOURCE_TRIAD_(D4|OFFLINE)_PASS names=98'}else{'SOURCE_TRIAD_D4_HOLD'}
 Run $Name (Join-Path $P 'BlueLite\BlueLite_SourceTriadGate.ps1') $a $Exit $m
}
function Preflight([string]$Name,[string]$P,[int]$Exit=1){
 $m=if($Exit -eq 0){'PREFLIGHT_PASS'}else{'PREFLIGHT_HOLD'}
 Run $Name (Join-Path $P 'BlueLite\BlueLite_Preflight.ps1') @('-UUPRoot',$P) $Exit $m
}
function Classify([string]$Name,[string]$P,[int]$Exit=1){
 $m=if($Exit -eq 0){'SOURCE_PRECUT_DECISION_PASS Windows=98 AppX=32'}else{'SOURCE_PRECUT_DECISION_HOLD'}
 Run $Name (Join-Path $P 'BlueLite\BlueLite_SourcePrecutDecision.ps1') @('-UUPRoot',$P,'-WindowsQueueFile',(Join-Path $P 'WindowsQueue.txt'),'-AppsQueueFile',(Join-Path $P 'AppsQueue.txt'),'-SourceTriadLog',(Join-Path $P 'SourceTriad.log'),'-LogPath',(Join-Path $P 'Decision.json')) $Exit $m
}
$p=Fixture 'positive'
Run 'AST_PS7' (Join-Path $Root 'tests\Parse-All.ps1') @('-Root',$p) 0 'AST_PASS count=15'
Run 'AST_PS51' (Join-Path $Root 'tests\Parse-All.ps1') @('-Root',$p) 0 'AST_PASS count=15' 'powershell.exe'
Preflight 'OriginalSource_Preflight' $p 0
Gate 'OriginalSource_Offline' $p 0 -Offline
Gate 'OriginalSource_D4' $p 0
Classify 'OriginalSource_Classify' $p 0
$i=0
foreach($n in @('List of files UUP.txt','File_renaming_script.cmd','SHA-1 checksums file.txt')){
 $i++;$q=Fixture ('missing'+$i);Remove-Item -LiteralPath (Join-Path $q $n);Preflight ('Missing_Input_'+$i) $q
}
$q=Fixture 'wrong_build';$f=Join-Path $q 'uup_download_windows.cmd';[IO.File]::WriteAllText($f,[IO.File]::ReadAllText($f).Replace('26300.9818','26200.9818'));Preflight 'WrongBuild' $q
$q=Fixture 'other_CU';$f=Join-Path $q 'uup_download_windows.cmd';[IO.File]::WriteAllText($f,[IO.File]::ReadAllText($f).Replace('26300.9818','26300.9999'));Preflight 'SyntheticOtherCU_NoHardcodedRevision' $q 0
$q=Fixture 'tamper';Add-Content -LiteralPath (Join-Path $q 'BlueLite\BlueLite_Profile.ini') -Value '#tamper';Preflight 'TamperedProfile' $q
$q=Fixture 'mismatch';$f=Join-Path $q 'SHA-1 checksums file.txt';$s=[IO.File]::ReadAllText($f);[IO.File]::WriteAllText($f,'0'+$s.Substring(1));Gate 'WrongSourceHash' $q
$q=Fixture 'ledger_extra';Add-Content -LiteralPath (Join-Path $q 'SHA-1 checksums file.txt') -Value 'malformed row';Gate 'MalformedLedger' $q
$q=Fixture 'list_extra';Add-Content -LiteralPath (Join-Path $q 'List of files UUP.txt') -Value 'malformed row';Gate 'MalformedList' $q
$q=Fixture 'rename_extra';Add-Content -LiteralPath (Join-Path $q 'File_renaming_script.cmd') -Value 'echo UNEXPECTED';Gate 'RenameDataNeverExecuted' $q
$q=Fixture 'duplicate_guid';$f=Join-Path $q 'File_renaming_script.cmd';$line=@([IO.File]::ReadAllLines($f)|Where-Object{$_ -like 'rename *'})[0];Add-Content -LiteralPath $f -Value $line;Gate 'DuplicateRenameGUID' $q
$q=Fixture 'duplicate_sha';$f=Join-Path $q 'SHA-1 checksums file.txt';Add-Content -LiteralPath $f -Value ([IO.File]::ReadAllLines($f)[0]);Gate 'DuplicateLedgerName' $q
$q=Fixture 'incomplete_queue';Add-Content -LiteralPath (Join-Path $q 'WindowsQueue.txt') -Value 'https://example.invalid/incomplete';Gate 'IncompleteD4Record' $q
$q=Fixture 'duplicate_out';$f=Join-Path $q 'WindowsQueue.txt';$s=[IO.File]::ReadAllText($f);$m=[regex]::Match($s,'(?m)^\s*out=.+$');$s=$s.Insert($m.Index,$m.Value+"`n");[IO.File]::WriteAllText($f,$s);Gate 'DuplicateD4Out' $q
$q=Fixture 'unsafe_name';$f=Join-Path $q 'SHA-1 checksums file.txt';$s=[IO.File]::ReadAllText($f).Replace('*DesktopDeployment.cab','*..\DesktopDeployment.cab');[IO.File]::WriteAllText($f,$s);Gate 'UnsafeFilename' $q
$q=Fixture 'stale_text';[IO.File]::WriteAllText((Join-Path $q 'SourceTriad.log'),'SOURCE_TRIAD_D4_PASS names=98 GUID=98');Classify 'BarePassMarkerRejected' $q
# Mutations AFTER a good gate must invalidate the bound decision.
Add-Content -LiteralPath (Join-Path $p 'WindowsQueue.txt') -Value '#changed-after-gate';Classify 'ChangedQueueAfterGate' $p
Copy-Item -LiteralPath (Join-Path $Root 'fixture\WindowsQueue.txt') -Destination (Join-Path $p 'WindowsQueue.txt') -Force
Add-Content -LiteralPath (Join-Path $p 'List of files UUP.txt') -Value '';Classify 'ChangedMetadataAfterGate' $p
# Existing renewer: offline candidate only, no network, verify-only.
$q=Fixture 'renew';$url='https://uupdump.net/get.php?id=6c7bf258-2632-47dd-83ee-c23945978da1&pack=en-us&edition=professional'
$argsRenew=@('-Mode','Windows','-Url',$url,'-ActiveQueueFile',(Join-Path $q 'WindowsQueue.txt'),'-OriginalQueueFile',(Join-Path $q 'WindowsQueue.txt'),'-FrozenQueueFile',(Join-Path $q 'unused_frozen.txt'),'-OfflineCandidateQueueFile',(Join-Path $q 'WindowsQueue.txt'),'-LogPath',(Join-Path $q 'Renew.log'),'-VerifyOnly')
Run 'RenewIdentityUnchanged' (Join-Path $q 'BlueLite\BlueLite_RenewQueue.ps1') $argsRenew 0 'QUEUE_RENEW_IDENTITY_PASS'
$f=Join-Path $q 'renew_bad.txt';$s=[IO.File]::ReadAllText((Join-Path $q 'WindowsQueue.txt'));$s=[regex]::Replace($s,'(?<=checksum=sha-1=)[a-fA-F0-9]{40}',('0'*40));[IO.File]::WriteAllText($f,$s)
$argsRenew[11]=$f
Run 'RenewIdentityChanged' (Join-Path $q 'BlueLite\BlueLite_RenewQueue.ps1') $argsRenew 1 'QUEUE_RENEW_HOLD'
$summary=[ordered]@{status='NATIVE_SOURCE_FIXTURE_PASS';count=$results.Count;utc=[DateTime]::UtcNow.ToString('o');tests=@($results.ToArray());runtime_UUP='NOT_RUN';image_mutation=$false}
[IO.File]::WriteAllText((Join-Path $LogRoot 'Summary.json'),($summary|ConvertTo-Json -Depth 6),[Text.UTF8Encoding]::new($false))
Write-Output ('R008_NATIVE_SOURCE_TESTS_PASS count='+$results.Count)
