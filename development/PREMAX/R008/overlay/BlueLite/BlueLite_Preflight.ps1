[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$UUPRoot)
$ErrorActionPreference='Stop'
try {
 $root=(Resolve-Path -LiteralPath $UUPRoot).Path
 if($root.Contains(' ')){throw 'Original UUP converter rejects paths containing spaces. Choose a folder path without spaces.'}
 foreach($name in @('uup_download_windows.cmd','ConvertConfig.ini','CustomAppsList.txt','files\get_aria2.ps1','files\converter_windows','files\converter_multi','BlueLite\BlueLite_UUP.cmd')){
  if(-not(Test-Path -LiteralPath (Join-Path $root $name) -PathType Leaf)){throw ('Missing required ORIGINAL UUP/BlueLite input: {0}' -f $name)}
 }
  # R007 source identity is mandatory BEFORE download; full 1:1:1 + D4 follows after URL queue retrieval.
  foreach($n in @('List of files UUP.txt','File_renaming_script.cmd','SHA-1 checksums file.txt')){
   $sourceInputPath=Join-Path $root $n
   if(-not(Test-Path -LiteralPath $sourceInputPath -PathType Leaf) -or (Get-Item -LiteralPath $sourceInputPath).Length -lt 100){
    throw ('SOURCE_TRIAD_REQUIRED_BEFORE_DOWNLOAD: '+$n)
   }
  }
 $launcher=[IO.File]::ReadAllText((Join-Path $root 'uup_download_windows.cmd'))
 if($launcher -match '(?i)BLUELITE'){throw 'Original launcher was already modified by another overlay. Use an untouched UUP Dump root.'}
 $t=[regex]::Match($launcher,'(?im)^\s*title\s+(\d{5}\.\d+)_(amd64|x64|arm64)_([a-z]{2}-[a-z]{2})_([a-z0-9]+)')
 if(-not $t.Success){throw 'Cannot prove build/architecture/language/edition from untouched UUP Dump launcher title.'}
 if(-not $t.Groups[1].Value.StartsWith('26300.')){throw ('Selected launcher is not 26300.x: {0}' -f $t.Groups[1].Value)}
 if($t.Groups[2].Value -notin @('amd64','x64') -or $t.Groups[3].Value -ne 'en-us' -or $t.Groups[4].Value -ne 'professional'){
  throw ('Unsupported variant: {0}_{1}_{2}; proven contract is 26300.x amd64 en-us professional.' -f $t.Groups[2].Value,$t.Groups[3].Value,$t.Groups[4].Value)
 }
 $get=[regex]::Matches($launcher,'(?i)https://uupdump\.net/get\.php\?[^"\r\n]+')
 if($get.Count -lt 2){throw 'Missing original UUP Dump Windows/Apps get.php sources.'}
 $uuids=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 foreach($g in $get){
  $u=[regex]::Match($g.Value,'(?i)[?&]id=([0-9a-f-]{36}(?:_rev\.\d+)?)')
  if(-not $u.Success){throw 'Missing source UUID in original get.php URL.'}
  [void]$uuids.Add($u.Groups[1].Value)
 }
 if($uuids.Count -ne 1){throw 'Windows and Apps URLs do not share the same UUP UUID.'}
 $manifest=Join-Path $root 'BlueLite_Package_SHA256.txt'
 if(-not(Test-Path -LiteralPath $manifest)){throw 'BlueLite ZIP manifest absent.'}
 $checked=0
 foreach($l in [IO.File]::ReadAllLines($manifest)){
  if($l.Trim().Length -eq 0){continue}
  if($l -notmatch '^([0-9A-Fa-f]{64}) \*(.+)$'){throw 'Invalid SHA256 manifest record.'}
  $name=$Matches[2]; $expected=$Matches[1].ToUpperInvariant()
  if($name.Contains('..') -or [IO.Path]::IsPathRooted($name)){throw ('Unsafe manifest path: {0}' -f $name)}
  $p=Join-Path $root $name
  if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw ('Overlay member missing: {0}' -f $name)}
  $actual=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash
  if($actual -ne $expected){throw ('Overlay member SHA256 mismatch: {0}' -f $name)}
  $checked++
 }
 if($checked -lt 20){throw 'Manifest contains too few member hashes.'}
 $scripts=@(Get-ChildItem -LiteralPath (Join-Path $root 'BlueLite') -Filter '*.ps1' -File)
 foreach($f in $scripts){
  $tok=$null; $err=$null
  [void][Management.Automation.Language.Parser]::ParseFile($f.FullName,[ref]$tok,[ref]$err)
  if($err.Count -gt 0){throw ('PS AST error in {0}: {1}' -f $f.Name,$err[0].Message)}
 }
 # Validate all three source maps before bootstrap or payload download.
 $gate=Join-Path $root 'BlueLite\BlueLite_SourceTriadGate.ps1'
 $ps7=(Get-Command pwsh.exe -ErrorAction Stop).Source
 & $ps7 -NoProfile -NonInteractive -File $gate -UUPRoot $root -OfflineOnly -LogPath (Join-Path $root 'BlueLite_Logs\SourceTriad.offline.log')
 if($LASTEXITCODE -ne 0){throw 'SOURCE_TRIAD_OFFLINE_HOLD'}
 $log=Join-Path $root 'BlueLite_Logs\Preflight.txt'
 $folder=Split-Path -Parent $log
 if(-not(Test-Path -LiteralPath $folder)){New-Item -ItemType Directory -Path $folder -Force|Out-Null}
 $msg=('PREFLIGHT_PASS build={0} uuid={1} members={2} PS_AST={3}' -f $t.Groups[1].Value,(@($uuids)[0]),$checked,$scripts.Count)
 $msg|Set-Content -LiteralPath $log -Encoding UTF8
 Write-Host $msg -ForegroundColor Green
 exit 0
}catch{
 $msg='PREFLIGHT_HOLD: '+$_.Exception.Message
 Write-Host $msg -ForegroundColor Red
 try{$folder=Join-Path $UUPRoot 'BlueLite_Logs';if(-not(Test-Path -LiteralPath $folder)){New-Item -ItemType Directory -Path $folder -Force|Out-Null};$msg|Set-Content -LiteralPath (Join-Path $folder 'Preflight.txt') -Encoding UTF8}catch{}
 exit 1
}