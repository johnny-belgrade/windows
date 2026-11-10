# R038 OP154 source-only DISM stdout and per-field regex fixture diagnostic; no image mutation.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$wim='C:\work\_UUP\R035_Universal_PREMAX_26300\BlueLite_Work\BlueLite_Stage_v11_3_26300_9818_6c7bf258_fc76f92b\BlueLite_R029_Outputs\install.wim'
$r=[ordered]@{schema='BlueLite.R038.OP154.DISMRegexDiagnostic.v1';status='HOLD';script_sha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash;fixture_match=$null;fixture_value=$null;regex_pattern=$null;dism_exit=$null;dism_stdout_length=$null;dism_stdout_head=$null;dism_stdout_type=$null;dism_first_index_match=$null;dism_first_index_value=$null;dism_stderr=$null;result_files_created=0;error=$null}
$proc=$null
try{
 $f=Get-Item -LiteralPath $wim -ErrorAction Stop
 if($f.Length -ne 5663629505 -or (($f.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)){throw 'SOURCE_WIM_FILE_SIZE_OR_LINK_CHANGED'}
 $pattern='(?im)^\s*'+[regex]::Escape('Index')+'\s*:\s*(.*?)\s*$'
 $r.regex_pattern=$pattern
 $fixture=[Environment]::NewLine+'Index : 1'+[Environment]::NewLine+'Name : Windows 11 Pro'+[Environment]::NewLine
 $test=[regex]::Match($fixture,$pattern)
 $r.fixture_match=$test.Success
 $r.fixture_value=if($test.Success){[string]$test.Groups[1].Value.Trim()}else{$null}
 $psi=[Diagnostics.ProcessStartInfo]::new()
 $psi.FileName='C:\Windows\System32\dism.exe'
 $psi.WorkingDirectory='C:\Windows\System32'
 $psi.UseShellExecute=$false
 $psi.CreateNoWindow=$true
 $psi.RedirectStandardOutput=$true
 $psi.RedirectStandardError=$true
 foreach($arg in @('/English','/Get-WimInfo',('/WimFile:'+$wim),'/Index:1')){[void]$psi.ArgumentList.Add([string]$arg)}
 $proc=[Diagnostics.Process]::new()
 $proc.StartInfo=$psi
 if(-not $proc.Start()){throw 'DISM_START_FAILED'}
 $outTask=$proc.StandardOutput.ReadToEndAsync()
 $errTask=$proc.StandardError.ReadToEndAsync()
 if(-not $proc.WaitForExit(30000)){try{$proc.Kill($true)}catch{};throw 'DISM_WAIT_TIMEOUT'}
 $actual=[string]$outTask.GetAwaiter().GetResult()
 $stderr=[string]$errTask.GetAwaiter().GetResult()
 $r.dism_exit=$proc.ExitCode
 $r.dism_stdout_length=$actual.Length
 $r.dism_stdout_type=$actual.GetType().FullName
 $r.dism_stdout_head=$actual.Substring(0,[Math]::Min(900,$actual.Length))
 $r.dism_stderr=$stderr.Substring(0,[Math]::Min(200,$stderr.Length))
 if($actual.Length -gt 15000 -or $stderr.Length -gt 2000){throw 'OUTPUT_OVERSIZE'}
 $m=[regex]::Match($actual,$pattern)
 $r.dism_first_index_match=$m.Success
 $r.dism_first_index_value=if($m.Success){[string]$m.Groups[1].Value.Trim()}else{$null}
 if($proc.ExitCode -ne 0){throw 'DISM_METADATA_EXIT_NONZERO'}
 $r.status='DISM_RAW_STDOUT_REGEX_DIAGNOSTIC_READONLY_CAPTURED'
}catch{$r.error=$_.Exception.Message}
finally{if($null -ne $proc){$proc.Dispose()}}
$r|ConvertTo-Json -Depth 4
if($r.status -ne 'DISM_RAW_STDOUT_REGEX_DIAGNOSTIC_READONLY_CAPTURED'){exit 2}
exit 0
