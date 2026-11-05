# BlueLite R010 | source-only post-R009 gate | PS7 | immutable ROOT logs
# Save this executable ONLY at C:\work\scripts\BlueLite_R010_ReadOnlySourceGate_v1.ps1
[CmdletBinding()]
param(
  [ValidateSet('Run','Verify')][string]$Mode='Run',
  [ValidateSet('','OP01','OP02','OP03','OP04')][string]$Op=''
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$Original='C:\work\26300.9818-UUP'
$Stage='C:\work\PREMAX-work\R009_V61_OfflinePreflight\UUP'
$R009='C:\work\logs\BlueLite_R009_V61_OfflinePreflight_v1'
$R009Zip='C:\work\logs\BlueLite_R009_V61_OfflinePreflight_v1_Evidence.zip'
$Logs='C:\work\logs'
$Prefix='BlueLite_R010'
$ZipPath=Join-Path $Logs 'BlueLite_R010_Evidence.zip'
$ExpectedSourceManifest='A01F06FBACB86FFF9EC88C60C4053B81EFB8F6D34A1DE138D07F1903E4E49A7A'
$ExpectedR009Zip='7FCE894119179A34DBF6B2E903F795022EE0E8E2FDD54F6208248191509F128C'
$ExpectedOverlayManifest='F7E7BE02D2B63B7340977B5CD6021161AD3EADBC8030822067F7747D8CE77B5C'
$Step='PRECHECK'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'R010 requires PowerShell 7'}
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Assert([bool]$Yes,[string]$Why){if(-not $Yes){throw $Why}}
function HashFile([string]$P){(Get-FileHash -LiteralPath $P -Algorithm SHA256).Hash.ToUpperInvariant()}
function HashBytes([byte[]]$B){[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($B))}
function P([string]$Name){Join-Path $Logs ('BlueLite_R010_'+$Name)}
function ReadJson([string]$Name){Get-Content -LiteralPath $Name -Raw -Encoding UTF8|ConvertFrom-Json}
function NewJson([string]$Name,[object]$Data){
  $path=P $Name
  Assert ([String]::Equals([IO.Path]::GetDirectoryName($path),$Logs,[StringComparison]::OrdinalIgnoreCase)) 'Output not in logs ROOT'
  $bytes=[Text.UTF8Encoding]::new($false).GetBytes(($Data|ConvertTo-Json -Depth 32)+"`n")
  $f=[IO.File]::Open($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
  try{$f.Write($bytes,0,$bytes.Length)}finally{$f.Dispose()}
}
function GetSource {
  $mPath=Join-Path $R009 'OP01_SourceManifest.json'
  Assert ([IO.File]::Exists($mPath)) 'R009 source manifest missing'
  $digest=HashFile $mPath
  Assert ($digest -eq $ExpectedSourceManifest) 'R009 source manifest SHA differs'
  $m=ReadJson $mPath
  Assert (@($m.files).Count -eq 15) 'R009 original inventory count !=15'
  Assert ($m.source_root -eq $Original) 'Wrong R009 original source'
  $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  foreach($f in @($m.files)){
    $rel=[string]$f.rel
    Assert (-not [IO.Path]::IsPathRooted($rel) -and -not ($rel -match '(^|[\\/])\.\.([\\/]|$)')) 'Unsafe original file path'
    Assert ($seen.Add($rel)) 'Duplicate original file path'
    foreach($base in @($Original,$Stage)){
      $path=Join-Path $base $rel
      Assert ([IO.File]::Exists($path)) ('Missing source file '+$path)
      Assert (([IO.FileInfo]::new($path)).Length -eq [long]$f.bytes) ('Size differs '+$path)
      Assert ((HashFile $path) -eq $f.sha256) ('SHA differs '+$path)
    }
  }
  $orig=@(Get-ChildItem -LiteralPath $Original -File -Force -Recurse)
  Assert ($orig.Count -eq 15) 'Original root file inventory drift'
  Assert (-not [IO.File]::Exists((Join-Path $Original 'START.cmd'))) 'Original UUP source is not untouched'
  Assert (-not [IO.Directory]::Exists((Join-Path $Original 'BlueLite'))) 'Original UUP source contains overlay'
  return [ordered]@{status='PASS';checked_source_members=15;checked_original_bytes=$true;checked_stage_bytes=$true;manifest_sha256=$digest;original_root=$Original;stage_root=$Stage}
}
function GetOverlay {
  $manifest=Join-Path $Stage 'BlueLite_Package_SHA256.txt'
  Assert ([IO.File]::Exists($manifest)) 'No staged R008 overlay SHA manifest'
  $mh=HashFile $manifest
  Assert ($mh -eq $ExpectedOverlayManifest) 'R008 overlay manifest unexpectedly changed'
  $rows=@([IO.File]::ReadAllLines($manifest)|Where-Object {$_.Trim().Length -gt 0})
  Assert ($rows.Count -eq 37) 'R008 runtime overlay manifest count !=37'
  $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  foreach($line in $rows){
    Assert ($line -match '^([a-fA-F0-9]{64}) \*(.+)$') 'Malformed R008 overlay manifest'
    $digest=$Matches[1].ToUpperInvariant();$rel=$Matches[2]
    Assert (-not [IO.Path]::IsPathRooted($rel) -and -not ($rel -match '(^|[\\/])\.\.([\\/]|$)')) 'Unsafe overlay relative path'
    Assert ($seen.Add($rel)) 'Duplicate R008 overlay member'
    $target=Join-Path $Stage ($rel -replace '/','\')
    Assert ([IO.File]::Exists($target)) ('Missing runtime member '+$rel)
    Assert ((HashFile $target) -eq $digest) ('Overlay SHA differs '+$rel)
  }
  Assert ([IO.File]::Exists((Join-Path $Stage 'START.cmd'))) 'Staged START.cmd not present'
  $ps=@(Get-ChildItem -LiteralPath (Join-Path $Stage 'BlueLite') -Filter '*.ps1' -File)
  Assert ($ps.Count -eq 15) 'Expected 15 PowerShell BlueLite script files'
  return [ordered]@{status='PASS';manifest_sha256=$mh;manifest_members=37;ps1_count=15;start_cmd_present=$true;start_cmd_executed=$false;source_only=$true}
}
function GetR009 {
  Assert ([IO.File]::Exists($R009Zip)) 'R009 native evidence archive absent'
  Assert ((HashFile $R009Zip) -eq $ExpectedR009Zip) 'R009 native evidence ZIP SHA mismatch'
  $lastReceipt=ReadJson (Join-Path $R009 'OP05_Receipt.json')
  $lastVerify=ReadJson (Join-Path $R009 'OP05_Verify.json')
  Assert ($lastReceipt.status -eq 'PASS' -and $lastVerify.status -eq 'PASS') 'R009 final status was not PASS'
  Assert ((HashFile (Join-Path $R009 'OP05_Receipt.json')) -eq $lastVerify.proof.receipt_sha256) 'R009 final SHA link failed'
  Assert ($lastReceipt.archive_sha256 -eq $ExpectedR009Zip) 'R009 receipt evidence SHA changed'
  $members=@($lastReceipt.archive_members)
  Assert ($members.Count -eq 13) 'R009 expected 13 evidence members'
  $za=[IO.Compression.ZipFile]::OpenRead($R009Zip)
  try{
    Assert ($za.Entries.Count -eq 13) 'R009 ZIP member count different'
    $observed=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($m in $members){
      Assert ($observed.Add([string]$m.name)) 'R009 duplicate manifest member'
      $entry=$za.GetEntry([string]$m.name)
      Assert ($null -ne $entry) ('R009 evidence missing '+$m.name)
      Assert ([long]$entry.Length -eq [long]$m.bytes) 'R009 evidence member size mismatch'
      $stream=$entry.Open();$mem=[IO.MemoryStream]::new()
      try{$stream.CopyTo($mem)}finally{$stream.Dispose()}
      $digest=HashBytes $mem.ToArray();$mem.Dispose()
      Assert ($digest -eq $m.sha256) ('R009 evidence member SHA mismatch '+$m.name)
    }
  }finally{$za.Dispose()}
  $timestamps=@()
  foreach($i in 1..5){
    $id='OP{0:d2}' -f $i
    $rec=ReadJson (Join-Path $R009 ($id+'_Receipt.json'))
    $ver=ReadJson (Join-Path $R009 ($id+'_Verify.json'))
    Assert ($rec.operation -eq $id -and $ver.operation -eq $id) ('R009 wrong step '+$id)
    Assert ($rec.status -eq 'PASS' -and $ver.status -eq 'PASS') ('R009 step HOLD '+$id)
    Assert ((HashFile (Join-Path $R009 ($id+'_Receipt.json'))) -eq $ver.proof.receipt_sha256) ('R009 step SHA link mismatch '+$id)
    $timestamps+=([DateTimeOffset]::Parse([string]$rec.utc))
    $timestamps+=([DateTimeOffset]::Parse([string]$ver.utc))
  }
  for($i=1;$i -lt $timestamps.Count;$i++){Assert ($timestamps[$i] -gt $timestamps[$i-1]) 'R009 receipt/verify ordering not monotonic'}
  $triad=ReadJson (Join-Path $R009 'SourceTriad.offline.log.json')
  $preflight=[IO.File]::ReadAllText((Join-Path $R009 'Preflight.txt'))
  Assert ($triad.status -eq 'SOURCE_TRIAD_OFFLINE_PASS' -and [int]$triad.count -eq 98 -and [int]$triad.guids -eq 98) 'R009 triad native fail'
  Assert ($preflight -match '^PREFLIGHT_PASS build=26300\.9818 uuid=6c7bf258-2632-47dd-83ee-c23945978da1 members=37 PS_AST=15') 'R009 source preflight marker mismatch'
  Assert ($null -eq $triad.windows_queue_sha256) 'Unexpected retrieved D4 queue hash in offline-only run'
  foreach($name in @('List of files UUP.txt','File_renaming_script.cmd','SHA-1 checksums file.txt')){
    Assert ($triad.source_sha256.$name -eq (HashFile (Join-Path $Original $name))) ('R009 triad input changed '+$name)
  }
  return [ordered]@{
    status='PASS';r009_native_source_only='PASS';r009_receipt_verify_chains=5
    r009_zip_sha256=$ExpectedR009Zip;archive_members=13;triad_records=98
    original_build='26300.9818';windows_queue_sha256=$null
    full_v6_1_runtime='NOT_RUN';release_certification='NOT_CERTIFIED'
    gate='FULL_RUNTIME_AUTHORIZATION_REQUIRED'
    open_dependencies=@('D4 dynamic Windows queue not proven in R009','26300 second distinct source pending','F01 DesktopAppInstaller provisioned','F02 Language.Basic CBS owner','F03 WMIC package selectors','F04 transactional WIM promotion','5GB ISO target','installed 14.5-15.5GB footprint','Setup OOBE boot VM Update Defender')
  }
}
function WriteReceipt([string]$O,[string]$Next,[object]$Extras){
  $kind=switch($O){'OP01'{'SourceReport.json'};'OP02'{'OverlayReport.json'};'OP03'{'GateReport.json'}}
  $reportSha=HashFile (P ($O+'_'+$kind))
  NewJson ($O+'_Receipt.json') ([ordered]@{
    schema='BlueLite.R010.OperatorReceipt.v1';operation=$O;utc=[DateTime]::UtcNow.ToString('o')
    status='PASS';authorization='READ_ONLY_R009_SOURCE_GATE';script_sha256=(HashFile $PSCommandPath)
    report_sha256=$reportSha
    details=$Extras;one_next=$Next
  })
}
function CheckOp([string]$O){
  Assert ($O -in @('OP01','OP02','OP03','OP04')) 'Unsupported Verify step'
  $rp=P ($O+'_Receipt.json')
  Assert ([IO.File]::Exists($rp)) 'Receipt missing'
  $receipt=ReadJson $rp
  Assert ($receipt.operation -eq $O -and $receipt.status -eq 'PASS') 'Receipt status or name wrong'
  Assert ($receipt.authorization -eq 'READ_ONLY_R009_SOURCE_GATE') 'Receipt authorization differs'
  Assert ($receipt.script_sha256 -eq (HashFile $PSCommandPath)) 'Script changed after first run'
  if($O -ne 'OP04'){
    $kind=switch($O){'OP01'{'SourceReport.json'};'OP02'{'OverlayReport.json'};'OP03'{'GateReport.json'}}
    $reportPath=P ($O+'_'+$kind)
    Assert ([IO.File]::Exists($reportPath)) 'Report missing'
    Assert ((HashFile $reportPath) -eq $receipt.report_sha256) 'Report SHA is not receipt-bound'
    $report=ReadJson $reportPath
    $live=switch($O){'OP01'{GetSource};'OP02'{GetOverlay};'OP03'{GetR009}}
    Assert ($report.status -eq 'PASS' -and $live.status -eq 'PASS') 'Native read-only source check failed'
    switch($O){
      'OP01'{Assert ($report.manifest_sha256 -eq $live.manifest_sha256 -and [int]$report.checked_source_members -eq 15) 'Source report semantics changed'}
      'OP02'{Assert ($report.manifest_sha256 -eq $live.manifest_sha256 -and [int]$report.manifest_members -eq 37) 'Overlay report semantics changed'}
      'OP03'{Assert ($report.gate -eq $live.gate -and $report.full_v6_1_runtime -eq 'NOT_RUN' -and [int]$report.r009_receipt_verify_chains -eq 5) 'Gate report semantics changed'}
    }
  }else{
    Assert ([IO.File]::Exists($ZipPath)) 'R010 evidence archive missing'
    Assert ((HashFile $ZipPath) -eq $receipt.details.archive_sha256) 'R010 archive SHA mismatch'
    $za=[IO.Compression.ZipFile]::OpenRead($ZipPath)
    try{
      $entries=@($za.Entries)
      Assert ($entries.Count -eq 9 -and @($receipt.details.members).Count -eq 9) 'R010 archive count != 9'
      $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
      foreach($m in @($receipt.details.members)){
        Assert ($seen.Add([string]$m.name)) 'R010 archive manifest duplicate'
        $entry=$za.GetEntry([string]$m.name)
        Assert ($null -ne $entry) ('Archive missing '+$m.name)
        Assert ([long]$entry.Length -eq [long]$m.bytes) 'Archive member size mismatch'
        $mem=[IO.MemoryStream]::new();$stream=$entry.Open()
        try{$stream.CopyTo($mem)}finally{$stream.Dispose()}
        $h=HashBytes $mem.ToArray();$mem.Dispose()
        Assert ($h -eq $m.sha256) ('Archive member hash mismatch '+$m.name)
        Assert ((HashFile (P $m.name)) -eq $h) ('Root log changed '+$m.name)
      }
    }finally{$za.Dispose()}
  }
  return [ordered]@{status='PASS';step=$O;receipt_sha256=(HashFile $rp);fresh_process=$true;source_only=$true}
}
function IndependentVerify([string]$O){
  $pwsh=(Get-Command pwsh.exe -ErrorAction Stop).Source
  & $pwsh -NoProfile -NonInteractive -File $PSCommandPath -Mode Verify -Op $O
  Assert ($LASTEXITCODE -eq 0) ('R010_INDEPENDENT_'+$O+'_HOLD')
}
if($Mode -eq 'Verify'){
  try{
    $q=CheckOp $Op
    NewJson ($Op+'_Verify.json') ([ordered]@{schema='BlueLite.R010.IndependentVerify.v1';operation=$Op;utc=[DateTime]::UtcNow.ToString('o');status='PASS';proof=$q;one_next='NEXT_SCOPED_OPERATION'})
    Write-Host ($Op+'_INDEPENDENT_VERIFY_PASS')
    exit 0
  }catch{
    try{NewJson ($Op+'_Verify_HOLD.json') ([ordered]@{operation=$Op;status='HOLD';utc=[DateTime]::UtcNow.ToString('o');reason=$_.Exception.Message})}catch{}
    Write-Host ('R010_INDEPENDENT_HOLD step='+$Op+': '+$_.Exception.Message) -ForegroundColor Red
    exit 17
  }
}
try{
  Assert ([IO.Directory]::Exists($Logs)) 'C:\work\logs missing'
  Assert ([IO.Directory]::Exists($Original) -and [IO.Directory]::Exists($Stage) -and [IO.Directory]::Exists($R009)) 'R009 source/stage/log directory missing'
  Assert ([string]::Equals([IO.Path]::GetFullPath($PSCommandPath),'C:\work\scripts\BlueLite_R010_ReadOnlySourceGate_v1.ps1',[StringComparison]::OrdinalIgnoreCase)) 'Save PS1 under C:\work\scripts with exact filename'
  $old=@(Get-ChildItem -LiteralPath $Logs -Filter 'BlueLite_R010_*' -File)
  Assert ($old.Count -eq 0) 'R010 output already exists in log ROOT; fail closed, never overwrite'
  $Step='OP01'
  $source=GetSource
  NewJson 'OP01_SourceReport.json' $source
  WriteReceipt 'OP01' 'OP02_VERIFY_OVERLAY_SOURCE' ([ordered]@{files=15})
  IndependentVerify 'OP01'
  $Step='OP02'
  $overlay=GetOverlay
  NewJson 'OP02_OverlayReport.json' $overlay
  WriteReceipt 'OP02' 'OP03_CHECK_R009_NATIVE_GATE' ([ordered]@{members=37})
  IndependentVerify 'OP02'
  $Step='OP03'
  $native=GetR009
  NewJson 'OP03_GateReport.json' $native
  WriteReceipt 'OP03' 'OP04_PACKAGE_READ_ONLY_EVIDENCE' ([ordered]@{gate=$native.gate;native='R009_SOURCE_PREFLIGHT_PASS'})
  IndependentVerify 'OP03'
  $Step='OP04'
  $members=@()
  foreach($i in 1..3){
    $id='OP{0:d2}' -f $i
    $kind=switch($id){'OP01'{'SourceReport.json'};'OP02'{'OverlayReport.json'};'OP03'{'GateReport.json'}}
    $names=@(($id+'_'+$kind),($id+'_Receipt.json'),($id+'_Verify.json'))
    foreach($name in $names){
      $f=P $name
      Assert ([IO.File]::Exists($f)) ('Required R010 log missing '+$name)
      $members+=([ordered]@{name=[IO.Path]::GetFileName($f);bytes=[long]([IO.FileInfo]::new($f)).Length;sha256=(HashFile $f)})
    }
  }
  Assert ($members.Count -eq 9) 'R010 archive input count !=9'
  $zip=[IO.Compression.ZipFile]::Open($ZipPath,[IO.Compression.ZipArchiveMode]::Create)
  try{
    foreach($member in $members){[void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,(P $member.name),$member.name,[IO.Compression.CompressionLevel]::Optimal)}
  }finally{$zip.Dispose()}
  NewJson 'OP04_Receipt.json' ([ordered]@{schema='BlueLite.R010.OperatorReceipt.v1';operation='OP04';utc=[DateTime]::UtcNow.ToString('o');status='PASS';authorization='READ_ONLY_R009_SOURCE_GATE';script_sha256=(HashFile $PSCommandPath);details=[ordered]@{archive_sha256=(HashFile $ZipPath);members=$members};one_next='RETURN_R010_ROOT_LOGS_TO_CHATGPT'})
  IndependentVerify 'OP04'
  Write-Host 'R010_SOURCE_GATE_PASS_FULL_RUNTIME_NOT_AUTHORIZED'
  Write-Host ('UPLOAD: '+$ZipPath)
  Write-Host ('UPLOAD: '+(P 'OP04_Receipt.json'))
  Write-Host ('UPLOAD: '+(P 'OP04_Verify.json'))
  exit 0
}catch{
  try{NewJson 'HOLD.json' ([ordered]@{schema='BlueLite.R010.HOLD.v1';operation=$Step;utc=[DateTime]::UtcNow.ToString('o');status='HOLD';reason=$_.Exception.Message;one_next='RETURN_EXISTING_ROOT_RECEIPTS_AND_HOLD'})}catch{}
  Write-Host ('R010_HOLD '+$Step+': '+$_.Exception.Message) -ForegroundColor Red
  exit 17
}
