# R002R25 sanitized diagnostic v1: read only original R22/R23 projection
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$b='C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package\05_Evidence'
$p="$b\R002R22_9807_NewQueue_001\AppsQueue.newly_observed.txt"
$j="$b\R002R23_MetadataInventory_001\R002R23_SafeQueueInventory.json"
if((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash -ne '91A3542BDF027559EB8541C9841903613357894501D0FB392880A740E4D0F67A'){throw 'R22_SHA_MISMATCH'}
if((Get-FileHash -LiteralPath $j -Algorithm SHA256).Hash -ne '0058049376679F6011F9BD3C9D51FE49BD631E46D843E38CF09E15D7AFD1CDE6'){throw 'R23_SHA_MISMATCH'}
$src=Get-Content -LiteralPath $j -Raw | ConvertFrom-Json
$map=@{}
foreach($r in @($src.records | Where-Object {$_.queue -eq 'Apps'})){$map.Add([string]$r.out,[string]$r.checksum)}
$names=0;$sameExact=0;$sameIgnoreCase=0;$different=0;$missing=0;$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$cur=[Collections.Generic.List[string]]::new()
function CompareRecord([string[]]$lines){
 $out=@($lines|Where-Object {$_ -match '^\s*out='});$sum=@($lines|Where-Object {$_ -match '^\s*checksum='})
 if($out.Count -ne 1 -or $sum.Count -ne 1){throw 'RECORD_FORMAT_DRIFT'}
 $n=($out[0] -replace '^\s*out=','').Trim().Trim('"')
 $h=($sum[0] -replace '^\s*checksum=','').Trim()
 $script:names++
 if(-not $script:seen.Add($n)){throw 'DUPLICATE_OUT'}
 if(-not $script:map.ContainsKey($n)){$script:missing++;return}
 if($script:map[$n] -ceq $h){$script:sameExact++}
 elseif($script:map[$n] -eq $h){$script:sameIgnoreCase++}
 else{$script:different++}
}
foreach($line in [IO.File]::ReadAllLines($p)){
 if($line -match '^\s*https?://'){
  if($cur.Count -gt 0){CompareRecord $cur.ToArray();$cur.Clear()}
  [void]$cur.Add($line)
 } elseif($cur.Count -gt 0){[void]$cur.Add($line)}
}
if($cur.Count -gt 0){CompareRecord $cur.ToArray()}
[pscustomobject]@{source_pin_pass=$true;raw_records=$names;r23_apps=$map.Count;exact_checksum_matches=$sameExact;case_only_checksum_differences=$sameIgnoreCase;other_checksum_differences=$different;out_absent_from_r23=$missing;url_fields_returned=0} | ConvertTo-Json -Compress
