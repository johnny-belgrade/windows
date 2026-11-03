[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][string]$WindowsQueueFile,
 [Parameter(Mandatory=$true)][string]$AppsQueueFile,
 [Parameter(Mandatory=$true)][string]$SourceTriadLog,
 [Parameter(Mandatory=$true)][string]$LogPath
)
$ErrorActionPreference='Stop'
function Parse-Queue([string]$Path) {
 if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){throw ('Queue missing: '+$Path)}
 $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 $items=[Collections.Generic.List[object]]::new()
 $current='';$sha=''
 foreach($line in [IO.File]::ReadAllLines($Path)){
  if($line -match '^\s*https?://'){
   if($current){
    if(-not $sha){throw ('Missing SHA1 for queue out='+$current)}
    [void]$items.Add([pscustomobject]@{name=$current;sha1=$sha})
   }
   $current='';$sha=''
  }elseif($line -match '^\s*out=(.+?)\s*$'){
   $current=$Matches[1].Trim().Trim('"')
   if($current -ne [IO.Path]::GetFileName($current) -or -not $seen.Add($current)){
    throw ('Unsafe or duplicated queue out='+$current)
   }
  }elseif($line -match '^\s*checksum=sha-1=([A-Fa-f0-9]{40})\s*$'){
   $sha=$Matches[1].ToUpperInvariant()
  }
 }
 if($current){
  if(-not $sha){throw ('Missing SHA1 for final queue out='+$current)}
  [void]$items.Add([pscustomobject]@{name=$current;sha1=$sha})
 }
 if($items.Count -ne $seen.Count){throw 'Queue out/checksum cardinality mismatch'}
 return ,($items.ToArray())
}
try {
 if(-not(Test-Path -LiteralPath $SourceTriadLog -PathType Leaf)){throw 'Mandatory D4 triad gate receipt missing'}
 $triad=[IO.File]::ReadAllText($SourceTriadLog)
 $m=[regex]::Match($triad,'SOURCE_TRIAD_D4_PASS names=(\d+) GUID=(\d+)')
 if(-not $m.Success){throw 'Mandatory D4 source triad was not fully verified'}
 $expected=[int]$m.Groups[1].Value
 $win=[object[]](Parse-Queue $WindowsQueueFile)
 $apps=[object[]](Parse-Queue $AppsQueueFile)
 if($win.Count -ne $expected -or $expected -lt 10){throw ('D4 queue cardinality mismatch: '+$win.Count+'/'+$expected)}
 if($apps.Count -lt 5){throw ('Staging Apps queue too small: '+$apps.Count)}
 $rows=[Collections.Generic.List[object]]::new()
 $fod=0
 foreach($r in $win){
  $candidate=$r.name -match '(?i)FoD|LanguageFeatures|FeaturesOnDemand|NetFx3'
  if($candidate){$fod++}
  $class=if($candidate){'FOD_OR_LANGUAGE_CANDIDATE'}elseif($r.name -match '(?i)\.msu$'){'SERVICING_UPDATE'}elseif($r.name -match '(?i)\.esd$'){'EDITION_DELTA_ESD'}elseif($r.name -match '(?i)\.wim$'){'RECONSTRUCTION_WIM'}else{'REFERENCE_OR_METADATA_CAB'}
  [void]$rows.Add([pscustomobject]@{
   name=$r.name;sha1=$r.sha1;class=$class
   pre_download_omit_authorized=$false
   decision='KEEP_FOR_RECONSTRUCTION_UNLESS_FULL_CONVERTER_COMPDB_CLOSURE_CERTIFIED'
  })
 }
 $record=[ordered]@{
  schema='BlueLite.SourcePrecutDecision.v1'
  utc=[DateTime]::UtcNow.ToString('o')
  Windows_queue_rows=$win.Count
  AppX_queue_rows=$apps.Count
  source_triad_verified_count=$expected
  FOD_or_language_candidate_rows=$fod
  source_windows_omissions_authorized=0
  AppX_top_level_staging_policy='five required, framework dependency closure independently resolved'
  WinRE_policy='effective SkipWinRE=1; preserve Setup boot.wim; optional external recovery'
  source_win_queue_modified=$false
  rationale='CompDB mentions are NOT proof of converter-unreferenced payloads; protect reconstruction'
  candidates=@($rows.ToArray())
  status='SOURCE_PRECUT_CLASSIFIED_KEEP_UNTIL_CLOSURE'
 }
 $outDir=Split-Path -Parent $LogPath
 if($outDir -and -not(Test-Path -LiteralPath $outDir)){[void][IO.Directory]::CreateDirectory($outDir)}
 $bytes=[Text.UTF8Encoding]::new($false).GetBytes(($record|ConvertTo-Json -Depth 8))
 [IO.File]::WriteAllBytes($LogPath,$bytes)
 Write-Host ('SOURCE_PRECUT_DECISION_PASS Windows={0} AppX={1} FoD_candidates={2} unproven_source_omissions=0' -f $win.Count,$apps.Count,$fod) -ForegroundColor Green
 exit 0
}catch{
 Write-Host ('SOURCE_PRECUT_DECISION_HOLD: '+$_.Exception.Message) -ForegroundColor Red
 exit 1
}
