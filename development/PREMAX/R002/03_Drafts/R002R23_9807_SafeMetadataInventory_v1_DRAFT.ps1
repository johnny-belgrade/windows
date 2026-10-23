# BlueLite R002-R23: source-bound URL-free metadata inventory, PREPARED_NOT_RUN.
# R22 queue originals are immutable. No HTTP, payload, converter, image or registry operation.
[CmdletBinding()]
param([string]$Authorization='')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($PSVersionTable.PSEdition -cne 'Core' -or $PSVersionTable.PSVersion.Major -lt 7){throw 'R23_PS7_REQUIRED'}
if($Authorization -cne 'I_APPROVE_R002R23_LOCAL_METADATA_INVENTORY_ONLY'){throw 'R23_AUTHORIZATION_REQUIRED'}
$base='C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package'
$qdir=Join-Path $base '05_Evidence\R002R22_9807_NewQueue_001'
$outdir=Join-Path $base '05_Evidence\R002R23_MetadataInventory_001'
$module='C:\work\scripts\BlueLite_Stage1_S06_26300_G4_AppsOnly\BlueLite_QueueIdentity.psm1'
$sourceRoot='C:\work\UUP_Source\26300.9807_687d1ced'
function Sha([string]$path){return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}
function RequireHash([string]$path,[string]$expected){if((Sha $path) -cne $expected){throw 'R23_INPUT_SHA_DRIFT'}}
function WriteNew([string]$path,[string]$text){
 $bytes=[Text.UTF8Encoding]::new($false).GetBytes($text)
 $stream=[IO.File]::Open($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
}
if(Test-Path -LiteralPath $outdir){throw 'R23_OUTPUT_COLLISION'}
RequireHash $module '7015C86B97F91E38D691B2831B9AD353EB6D2369E8AD69559B8DC6FF5E31745E'
RequireHash (Join-Path $sourceRoot '26300.9807_amd64_en-us_professional_687d1ced_convert.zip') '83203A6E79E62579A7D64204120BCECC111FE114C614AB1DBFAE032BB02DE7B7'
RequireHash (Join-Path $sourceRoot 'uup_download_windows.cmd') '289EBCBEA3352F66187BDF2E75961A855DAA187F6C9F4739E7301F9C9F12DEB5'
RequireHash (Join-Path $sourceRoot 'BlueLite_S11_SourceContract.json') '9D9DCD4FD8190863F1591679574879D3B652D2FE6DED176EEFED0C204D947D11'
$r22Receipt=Join-Path $qdir 'R002R22_Native_Metadata_Receipt.txt'
RequireHash $r22Receipt '6EE8E416BB48F58E997774A799509DC4EA99FD60A9D82F3FECBF074AF2585814'
$pins=@(
 @{Name='Windows';Bytes=34639;Count=98;FileSHA='22E5DE1AD1A86A08C8BA1E1FBD7DF66AC06FA85E2FFCE1B1B7D7D01BAC29AC67';SemanticSHA='838219EF2F638D2C7F63E92E02F73FDD593802E1A284C63301AA7C6B29C3C33C'},
 @{Name='Apps';Bytes=947419;Count=2798;FileSHA='91A3542BDF027559EB8541C9841903613357894501D0FB392880A740E4D0F67A';SemanticSHA='8AFD51F42BEDEDED5ABF88F662A15376941C86099A5542EE4095A0F128F6764B'}
)
Import-Module -Name $module -Force
$records=[Collections.Generic.List[object]]::new()
$identities=[Collections.Generic.List[object]]::new()
foreach($pin in $pins){
 $path=Join-Path $qdir ($pin.Name+'Queue.newly_observed.txt')
 RequireHash $path $pin.FileSHA
 if((Get-Item -LiteralPath $path).Length -ne $pin.Bytes){throw 'R23_QUEUE_BYTES_DRIFT'}
 $identity=Get-BlueLiteQueueIdentity -Path $path
 if($identity.Count -ne $pin.Count -or $identity.SHA256 -cne $pin.SemanticSHA){throw 'R23_QUEUE_SEMANTIC_DRIFT'}
 $identities.Add([ordered]@{queue=$pin.Name;file_sha256=$pin.FileSHA;bytes=$pin.Bytes;count=$identity.Count;semantic_sha256=$identity.SHA256})
 foreach($record in $identity.Records){
  # Explicit projection: Url is never serialized or printed.
  $records.Add([pscustomobject][ordered]@{queue=$pin.Name;out=[string]$record.Out;checksum=[string]$record.Checksum})
 }
}
$ordered=@($records | Sort-Object queue,out -CaseSensitive)
$extensions=@($ordered | Group-Object -Property { [IO.Path]::GetExtension($_.out).ToLowerInvariant() } | Sort-Object Name | ForEach-Object {[ordered]@{extension=$_.Name;count=$_.Count}})
$overlap=@($ordered | Group-Object -Property { $_.out.ToLowerInvariant() } | Where-Object Count -gt 1 | Sort-Object Name | ForEach-Object {
 [ordered]@{out_lower=$_.Name;record_count=$_.Count;queues=@($_.Group.queue | Sort-Object -Unique);distinct_checksums=@($_.Group.checksum | Sort-Object -Unique)}
})
$started=[DateTime]::UtcNow.ToString('o')
$inventory=[ordered]@{
 schema='BlueLite.R002R23.SafeQueueInventory.v1';source_build='26300.9807';source_uuid='687d1ced-aab1-4cd5-ad05-705189769731'
 input_class='NEWLY_OBSERVED_R22_METADATA';original_pre_renewal_baseline='HOLD_UNPROVEN'
 dependency_closure='NOT_EVALUATED';payload_content_checksums='NOT_VERIFIED';runtime_execution_allowed=$false
 inputs=$identities.ToArray();record_count=$ordered.Count;extensions=$extensions;cross_queue_same_out=$overlap;records=$ordered
}
$inventoryText=($inventory | ConvertTo-Json -Depth 10)+[Environment]::NewLine
if($inventoryText -match '(?i)https?://|"Url"\s*:'){throw 'R23_URL_PROJECTION_FAILURE'}
$roundTrip=$inventoryText | ConvertFrom-Json
if($roundTrip.records.Count -ne 2896){throw 'R23_PROJECTED_COUNT_MISMATCH'}
foreach($pin in $pins){
 $actual=@($roundTrip.records | Where-Object queue -CEQ $pin.Name)
 if($actual.Count -ne $pin.Count){throw 'R23_PROJECTED_QUEUE_COUNT_MISMATCH'}
 # Recreate D4 semantic identity using only projected out+checksum.
 $keys=@($actual | ForEach-Object {$_.out.ToLowerInvariant()+[char]9+$_.checksum.ToUpperInvariant()} | Sort-Object -CaseSensitive)
 $serialized=($keys -join [char]10)+[char]10
 $sha=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($serialized)))
 if($sha -cne $pin.SemanticSHA){throw 'R23_PROJECTED_SEMANTIC_DRIFT'}
}
# Recheck immutable inputs immediately before creating any output.
foreach($pin in $pins){RequireHash (Join-Path $qdir ($pin.Name+'Queue.newly_observed.txt')) $pin.FileSHA}
RequireHash $r22Receipt '6EE8E416BB48F58E997774A799509DC4EA99FD60A9D82F3FECBF074AF2585814'
if(Test-Path -LiteralPath $outdir){throw 'R23_OUTPUT_COLLISION'}
[void][IO.Directory]::CreateDirectory($outdir)
try{
 $inventoryPath=Join-Path $outdir 'R002R23_SafeQueueInventory.json'
 WriteNew $inventoryPath $inventoryText
 if([IO.File]::ReadAllText($inventoryPath) -cne $inventoryText){throw 'R23_OUTPUT_READBACK_MISMATCH'}
 foreach($pin in $pins){RequireHash (Join-Path $qdir ($pin.Name+'Queue.newly_observed.txt')) $pin.FileSHA}
 $receipt=[ordered]@{
  result='PASS_R002R23_URL_FREE_METADATA_INVENTORY_ONLY';started_utc=$started;finished_utc=[DateTime]::UtcNow.ToString('o')
  native_pid=$PID;ps_version=$PSVersionTable.PSVersion.ToString();adapter_sha256=(Sha $PSCommandPath)
  inventory_sha256=(Sha $inventoryPath);inventory_bytes=(Get-Item -LiteralPath $inventoryPath).Length
  windows_count=98;apps_count=2798;total_records=$ordered.Count;projected_semantic_identity='PASS'
  http_requests=0;uup_payload_downloaded=$false;dependency_closure='NOT_EVALUATED';runtime_execution_allowed=$false
 }
 $receiptPath=Join-Path $outdir 'R002R23_Native_Inventory_Receipt.json'
 WriteNew $receiptPath (($receipt | ConvertTo-Json -Depth 5)+[Environment]::NewLine)
 $receipt | ConvertTo-Json -Depth 5
}catch{
 # Retain partial owned output. Do not leak raw URL-bearing input exceptions.
 Write-Output 'RESULT=HOLD_R002R23_OUTPUT_OR_POSTSTATE;PRESERVE_PARTIAL_OUTPUT'
 exit 86
}
