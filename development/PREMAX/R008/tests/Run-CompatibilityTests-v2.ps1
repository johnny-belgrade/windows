param([string]$Root,[string]$LogRoot)
$ErrorActionPreference='Stop'
$ps7=(Get-Command pwsh.exe).Source
$p=Join-Path $Root 'cases\compatibility_native51'
if(Test-Path -LiteralPath $p){throw 'Fixture exists'}
[void][IO.Directory]::CreateDirectory($p);[void][IO.Directory]::CreateDirectory($LogRoot)
Copy-Item -Path (Join-Path $Root 'candidate\*') -Destination $p -Recurse
Copy-Item -Path (Join-Path $Root 'fixture\*') -Destination $p -Recurse -Force
$specs=@(
 @{name='PS7_Preflight_OpenStdin';exe=$ps7;script='BlueLite_Preflight.ps1';args=@('-UUPRoot',$p);marker='PREFLIGHT_PASS'},
 @{name='PS51_Triad_Runtime';exe='powershell.exe';script='BlueLite_SourceTriadGate.ps1';args=@('-UUPRoot',$p,'-WindowsQueueFile',(Join-Path $p 'WindowsQueue.txt'),'-LogPath',(Join-Path $p 'SourceTriad.log'));marker='SOURCE_TRIAD_D4_PASS names=98'},
 @{name='PS51_Precut_Runtime';exe='powershell.exe';script='BlueLite_SourcePrecutDecision.ps1';args=@('-UUPRoot',$p,'-WindowsQueueFile',(Join-Path $p 'WindowsQueue.txt'),'-AppsQueueFile',(Join-Path $p 'AppsQueue.txt'),'-SourceTriadLog',(Join-Path $p 'SourceTriad.log'),'-LogPath',(Join-Path $p 'Decision.json'));marker='SOURCE_PRECUT_DECISION_PASS Windows=98 AppX=32'}
)
foreach($s in $specs){
 $script=Join-Path (Join-Path $p 'BlueLite') $s.script
 $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName=$s.exe;$psi.UseShellExecute=$false;$psi.RedirectStandardInput=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
 foreach($a in @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$script)+$s.args){[void]$psi.ArgumentList.Add($a)}
 # RDC inherits PS7 module paths; give the Windows PS5.1 child its own stock module path.
 if($s.exe -eq 'powershell.exe'){$psi.Environment['PSModulePath']=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\Modules'}
 $proc=[Diagnostics.Process]::new();$proc.StartInfo=$psi;[void]$proc.Start()
 # Deliberately keep redirected stdin OPEN; fixed source must not wait for EOF.
 $o=$proc.StandardOutput.ReadToEndAsync();$e=$proc.StandardError.ReadToEndAsync()
 if(-not $proc.WaitForExit(15000)){$proc.Kill($true);$proc.WaitForExit();$code=124}else{$code=$proc.ExitCode}
 $log=Join-Path $LogRoot ($s.name+'.log');[IO.File]::WriteAllText($log,$o.GetAwaiter().GetResult()+$e.GetAwaiter().GetResult());$proc.Dispose()
 $ok=$code -eq 0 -and [IO.File]::ReadAllText($log) -match $s.marker
 $r=[ordered]@{test=$s.name;utc=[DateTime]::UtcNow.ToString('o');script_sha256=(Get-FileHash -LiteralPath $script).Hash;expected_exit=0;actual_exit=$code;expected_marker=$s.marker;log=$log;log_sha256=(Get-FileHash -LiteralPath $log).Hash;status=$(if($ok){'PASS'}else{'FAIL'});stdin_kept_open=$true;image_mutation=$false}
 $f=Join-Path $LogRoot ($s.name+'.json');[IO.File]::WriteAllText($f,($r|ConvertTo-Json))
 if(-not $ok){throw ('COMPATIBILITY_FAIL '+$s.name)}
 & $ps7 -NoProfile -NonInteractive -File (Join-Path $Root 'tests\Verify-Receipt.ps1') -Path $f -ExpectedSha256 (Get-FileHash -LiteralPath $f).Hash
 if($LASTEXITCODE -ne 0){throw 'Independent verification failed'}
 Write-Output ('COMPATIBILITY_PASS '+$s.name)
}
