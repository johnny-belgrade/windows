# BlueLite R028 stage-only converter/PreDebloat fix, preserves manifest-pinned v11.3 source.
[CmdletBinding()]
param([ValidateSet('Inspect','Prepare')][string]$Mode='Inspect',
 [Parameter(Mandatory=$true)][string]$Stage,
 [Parameter(Mandatory=$true)][string]$SelectedRoot)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function GateBL([bool]$ok,[string]$why){if(-not $ok){throw ('R028_PATCH_HOLD_'+$why)}}
function ShaBL([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()}
function WriteBL([string]$path,[string]$value,[Text.Encoding]$encoding) {
 $bytes=$encoding.GetBytes($value);$f=[IO.File]::Open($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$f.Write($bytes,0,$bytes.Length)}finally{$f.Dispose()}
}
$stage=[IO.Path]::GetFullPath($Stage).TrimEnd([char]'\')
$root=[IO.Path]::GetFullPath($SelectedRoot).TrimEnd([char]'\')
GateBL ($root.StartsWith('C:\work\',[StringComparison]::OrdinalIgnoreCase) -and $root -notmatch '\s') 'SELECTED_ROOT'
GateBL ($stage.StartsWith((Join-Path $root 'BlueLite_Work')+'\',[StringComparison]::OrdinalIgnoreCase)) 'STAGE_NOT_ROOT_CHILD'
GateBL ((Split-Path $stage -Leaf) -match '^BlueLite_Stage_v11_3_26300_\d+_[a-f0-9]{8}_[a-f0-9]{8}$') 'STAGE_ID'
GateBL (-not(Test-Path -LiteralPath (Join-Path $stage 'BlueLite_Logs\ConvertStart.marker'))) 'CONVERTER_ALREADY_STARTED'
GateBL (-not(Test-Path -LiteralPath (Join-Path $stage 'ISOFOLDER'))) 'ISO_FOLDER_ALREADY_USED'
$baseline=Join-Path $stage 'BlueLite\BlueLite_PreDebloatWim.ps1'
$converter=Join-Path $stage 'convert-UUP.cmd'
$scriptName='BlueLite_R028_PreDebloatWim.ps1'
$scriptPath=Join-Path $stage ('BlueLite\'+$scriptName)
$targetFod=Join-Path $stage 'BlueLite\BlueLite_R028_FoD.ps1'
$targetCapture=Join-Path $stage 'BlueLite\BlueLite_R028_Capture.ps1'
$srcFod=Join-Path $root 'BlueLite_R028_FoD.ps1'
$srcCapture=Join-Path $root 'BlueLite_R028_Capture.ps1'
$logs=Join-Path $root 'BlueLite_Logs'
GateBL ((ShaBL $baseline) -eq '70B137758AB8CF7741DB84BB15E02C7544097DA58B492AB6DE2551FDBAD46DA5') 'BASELINE_MODULE_SHA_UNKNOWN'
GateBL ((Test-Path $srcFod -PathType Leaf) -and (Test-Path $srcCapture -PathType Leaf)) 'NEW_HELPER_MISSING'
GateBL ((Test-Path $logs -PathType Container)) 'ROOT_LOG_DIR'
GateBL (-not(Test-Path $scriptPath) -and -not(Test-Path $targetFod) -and -not(Test-Path $targetCapture)) 'R028_PATCH_ALREADY_STARTED'
$baseContent=[IO.File]::ReadAllText($baseline)
# Match exactly one original wrong identity gate, tolerate CRLF and build UBR string syntax.
$rx='(?m)^.*Compact export identity gate failed.*$'
$matches=[regex]::Matches($baseContent,$rx)
GateBL ($matches.Count -eq 1) ('WIM_IDENTITY_ANCHOR_COUNT_'+$matches.Count)
GateBL ($matches[0].Value.Contains('if (($exportInfo -join') -and $matches[0].Value.Contains('-notmatch [regex]::Escape($actualBuild)') -and $matches[0].Value.Contains('Compact export identity gate failed: expected build $actualBuild.')) 'WIM_IDENTITY_OLD_SOURCE_NOT_EXACT'
$identity=@'
    # R028 corrected: DISM WIMInfo Version contains the base OS build but not the registry UBR.
    # CurrentBuildNumber plus UBR were verified earlier from the mounted offline SOFTWARE hive.
    $exportText=[string]::Join([Environment]::NewLine,[string[]]$exportInfo)
    $versionRx='(?im)^[ \t]*Version[ \t]*:[ \t]*10\.0\.'+[regex]::Escape([string]$currentBuild)+'[ \t]*$'
    if ($exportText -notmatch $versionRx) { throw "R028 exported WIM family mismatch: expected 10.0.$currentBuild" }
    if ($exportText -notmatch '(?im)^[ \t]*Edition[ \t]*:[ \t]*Professional[ \t]*$') { throw 'R028 exported WIM edition is not Professional' }
    if ($exportText -notmatch '(?im)^[ \t]*Architecture[ \t]*:[ \t]*x64[ \t]*$') { throw 'R028 exported WIM not x64' }
'@
$patched=$baseContent.Substring(0,$matches[0].Index)+$identity.TrimEnd()+$baseContent.Substring($matches[0].Index+$matches[0].Length)
$foDAnchor='    $allPkgs=@(Get-WindowsPackage -Path $mountDir -ErrorAction Stop)'
GateBL ($patched.Split([string[]]@($foDAnchor),[StringSplitOptions]::None).Count -eq 2) 'FOD_INSERT_ANCHOR_COUNT'
$foDInsert=@'
    # R028: actual installed NIC driver/Sense FoD removal; distinct from UUP download references.
    $selectedUUPRoot=Split-Path (Split-Path (Get-Location).Path -Parent) -Parent
    $r028ExtraReport=Join-Path (Join-Path $selectedUUPRoot 'BlueLite_Logs') ('BlueLite_R028_FoD_'+$actualBuild+'_'+[Guid]::NewGuid().ToString('N').Substring(0,8)+'.json')
    & pwsh.exe -NoProfile -NonInteractive -File 'BlueLite\BlueLite_R028_FoD.ps1' -Mode Execute -MountPath $mountDir -ReportPath $r028ExtraReport -RemoveNetworkDriverFoD -RemoveSenseClientFoD
    if ($LASTEXITCODE -ne 0) { throw 'R028 extra FoD phase failed; refusing commit.' }
    [void]$actions.Add('R028 EXTRA FOD REPORT: '+$r028ExtraReport)
'@
$patched=$patched.Replace($foDAnchor,$foDInsert.TrimEnd()+[Environment]::NewLine+$foDAnchor)
$tok=$null;$err=$null;[void][Management.Automation.Language.Parser]::ParseInput($patched,[ref]$tok,[ref]$err)
GateBL ($err.Count -eq 0) ('PATCHED_PS_AST_'+($err|Select-Object -First 1).Message)
$enc=[Text.Encoding]::GetEncoding(1252)
$batch=[IO.File]::ReadAllText($converter,$enc)
$oldCall='BlueLite\BlueLite_PreDebloatWim.ps1'
GateBL ($batch.Split([string[]]@($oldCall),[StringSplitOptions]::None).Count -eq 2) 'CONVERTER_MODULE_CALL_COUNT'
$batch=$batch.Replace($oldCall,('BlueLite\'+$scriptName))
$hookRx='(?m)(\s*exit /b 92\s*\)\s*)(if %SkipISO% neq 0 \()'
$hookMatches=[regex]::Matches($batch,$hookRx)
GateBL ($hookMatches.Count -eq 1) ('CONVERTER_CAPTURE_ANCHOR_COUNT_'+$hookMatches.Count)
$m=$hookMatches[0]
$inject='pwsh.exe -NoProfile -NonInteractive -File "BlueLite\BlueLite_R028_Capture.ps1" -StageRoot "."'+[Environment]::NewLine+
 'if errorlevel 1 ('+[Environment]::NewLine+'  echo [R028 ERROR] setup WIM capture gate failed'+[Environment]::NewLine+'  exit /b 93'+[Environment]::NewLine+')'+[Environment]::NewLine
$replacement=$m.Groups[1].Value+$inject+$m.Groups[2].Value
$batch=$batch.Substring(0,$m.Index)+$replacement+$batch.Substring($m.Index+$m.Length)
GateBL ($batch.Contains('BlueLite_R028_Capture.ps1') -and $batch.Contains($scriptName)) 'PATCHED_CONVERTER_NOT_COMPLETE'
if($Mode -eq 'Inspect') {
 Write-Host ('R028_PATCH_STATIC_PASS original_module_sha='+(ShaBL $baseline)+' new_PS_AST=0 module_call=1 capture_anchor=1')
 exit 0
}
$runId='BlueLite_R028_Patch_'+[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffffffZ')+'_'+[Guid]::NewGuid().ToString('N').Substring(0,8)
$backup=Join-Path $logs ($runId+'_converter_before.cmd')
$report=Join-Path $logs ($runId+'_REPORT.json')
try{
 Copy-Item -LiteralPath $converter -Destination $backup -ErrorAction Stop
 GateBL ((ShaBL $converter) -eq (ShaBL $backup)) 'BACKUP_CONVERTER_SHA'
 WriteBL $scriptPath $patched ([Text.UTF8Encoding]::new($false))
 Copy-Item -LiteralPath $srcFod -Destination $targetFod
 Copy-Item -LiteralPath $srcCapture -Destination $targetCapture
 GateBL ((ShaBL $targetFod) -eq (ShaBL $srcFod) -and (ShaBL $targetCapture) -eq (ShaBL $srcCapture)) 'HELPER_COPIES_SHA'
 [IO.File]::WriteAllText($converter,$batch,$enc)
 GateBL ([IO.File]::ReadAllText($converter,$enc) -eq $batch) 'CONVERTER_READBACK_MISMATCH'
 $t=$null;$e=$null;[void][Management.Automation.Language.Parser]::ParseFile($scriptPath,[ref]$t,[ref]$e)
 GateBL ($e.Count -eq 0) 'NATIVE_PATCHED_SOURCE_AST_FAIL'
 $obj=[ordered]@{schema='BlueLite.R028.Patch.v1';status='PREPARED';utc=[DateTime]::UtcNow.ToString('o');stage=$stage;source_module_sha256=(ShaBL $baseline);new_module_sha256=(ShaBL $scriptPath);patched_converter_sha256=(ShaBL $converter);converter_original_sha256=(ShaBL $backup);new_fod_sha256=(ShaBL $targetFod);new_capture_sha256=(ShaBL $targetCapture);identity_fix='WIMInfo 10.0.build plus offline CurrentBuild and UBR';fod_policy='NIC driver capability + Sense EDR targets';one_next='NATIVE_CONVERTER_ONCE'}
 $b=[Text.UTF8Encoding]::new($false).GetBytes(($obj|ConvertTo-Json -Depth 9)+[Environment]::NewLine)
 $f=[IO.File]::Open($report,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$f.Write($b,0,$b.Length)}finally{$f.Dispose()}
 Write-Host ('R028_PATCH_NATIVE_PASS '+$report)
 exit 0
}catch{
 Write-Host ('R028_PATCH_HOLD '+$_.Exception.Message)
 exit 17
}
