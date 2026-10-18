& {
 $ErrorActionPreference='Stop'
 Set-StrictMode -Version Latest
 $root='C:\work'
 $origin='C:\work\E2E\BlueLite_DL_R26_D6_26300.9711_2b22470a\UUPs'
 $duplicate='C:\work\E2E\BlueLite_Stage1_S20_26300.9711_ConverterWorkspace\UUPs'
 $log='C:\work\logs\BlueLite_Storage_S42_26300.9711_UUPPairs.txt'
 $csv='C:\work\logs\BlueLite_Storage_S42_26300.9711_UUPPairs.csv'
 $state='HOLD_S42_UUP_PAIR_READONLY'
 $utf8=[Text.UTF8Encoding]::new($false)
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'PS7_REQUIRED'}
 if(-not(Test-Path -LiteralPath $origin -PathType Container) -or
    -not(Test-Path -LiteralPath $duplicate -PathType Container)){throw 'UUP_ROOT_MISSING'}
 foreach($out in @($log,$csv)){if(Test-Path -LiteralPath $out){throw 'S42_OUTPUT_EXISTS_NO_OVERWRITE'}}
 [IO.File]::WriteAllText($log,'',$utf8)
 function Note([string]$msg){
  $line=(Get-Date -Format 'HH:mm:ss')+' | '+$msg
  Write-Host $line
  [IO.File]::AppendAllText($log,$line+[Environment]::NewLine,$utf8)
 }
 function Pin([string]$tag,[string]$p,[string]$sha,[long]$bytes){
  $item=Get-Item -LiteralPath $p -ErrorAction Stop
  if($bytes -ge 0 -and $item.Length -ne $bytes){throw ('SIZE_DRIFT='+$tag)}
  $actual=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash
  if($actual -cne $sha){throw ('SHA_DRIFT='+$tag)}
  Note ('PIN_'+$tag+'=PASS;BYTES='+$item.Length)
 }
 try{
  Note 'S42_READONLY_UUP_9711_DUPLICATE_AND_9807_SOURCE'
  Note 'NO_DOWNLOAD_NO_FILE_DELETE_NO_WIM_COPY_NO_MOUNT'
  Pin 'S41_ACTUAL' 'C:\work\logs\BlueLite_Storage_S41_26300.9711_ExactFourWimDeletion.txt' 'EB142796E30F6C7A8A110AC196A6EEA2EE51CCEA17D13ED8B354D3DF79B0F670' 4102
  Pin 'S16_ORIGINAL_UUP_PASS' 'C:\work\logs\BlueLite_Stage1_S16_26300.9711_FullPayload_UnionHashAudit.txt' 'C1F793FDE7B7BA63BF0CAC7F10799C9816FE27FEB6798416F61E2BE186993E3D' 929
  Pin 'D6_129_SOURCE_LEDGER' 'C:\work\E2E\BlueLite_DL_R26_D6_26300.9711_2b22470a\Queues\UUP_DownloadFile_SHA256.csv' 'A8A205E554C8A5958E6D0CB725AED99383D6BEC752FF64A7D66F5A5DF9609898' -1
  Pin '9807_ORIGINAL_ZIP' 'C:\work\26300.9807-UUP\26300.9807_amd64_en-us_professional_687d1ced_convert.zip' '83203A6E79E62579A7D64204120BCECC111FE114C614AB1DBFAE032BB02DE7B7' 8218
  Pin '9807_FROZEN_CONTRACT' 'C:\work\UUP_Source\26300.9807_687d1ced\BlueLite_S11_SourceContract.json' '9D9DCD4FD8190863F1591679574879D3B652D2FE6DED176EEFED0C204D947D11' -1
  $a=@(Get-ChildItem -LiteralPath $origin -File -Force -ErrorAction Stop)
  $b=@(Get-ChildItem -LiteralPath $duplicate -File -Force -ErrorAction Stop)
  $da=@(Get-ChildItem -LiteralPath $origin -Directory -Force)
  $db=@(Get-ChildItem -LiteralPath $duplicate -Directory -Force)
  if($a.Count -ne 129 -or $b.Count -ne 129 -or $da.Count -ne 0 -or $db.Count -ne 0){
   throw 'UUP_129_FILE_SHAPE_MISMATCH'
  }
  $byName=@{};foreach($item in $b){
   if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'STAGED_REPARSE'}
   if($byName.ContainsKey($item.Name)){throw 'DUPLICATE_NAME'}
   $byName[$item.Name]=$item
  }
  $list=[System.Collections.Generic.List[object]]::new()
  [long]$totalA=0;[long]$totalB=0
  foreach($item in ($a|Sort-Object Name)){
   if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'SOURCE_REPARSE'}
   if(-not $byName.ContainsKey($item.Name)){throw ('NAME_MISSING='+$item.Name)}
   $other=$byName[$item.Name]
   $x=(Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash
   $y=(Get-FileHash -LiteralPath $other.FullName -Algorithm SHA256).Hash
   $ok=($item.Length -eq $other.Length -and $x -ceq $y)
   $totalA += [long]$item.Length;$totalB += [long]$other.Length
   $list.Add([pscustomobject]@{Name=$item.Name;SourceBytes=$item.Length;StageBytes=$other.Length;SourceSHA256=$x;StageSHA256=$y;Identical=$ok})
   if($list.Count%16 -eq 0){Note ('PAIRS_HASHED='+$list.Count)}
  }
  $list|Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding utf8
  $different=@($list|Where-Object {-not $_.Identical})
  Note ('COUNT='+$list.Count+';DIFFERENT='+$different.Count)
  Note ('SOURCE_BYTES='+$totalA+';STAGED_BYTES='+$totalB)
  if($list.Count -ne 129 -or $different.Count -ne 0 -or
     $totalA -ne 8992976071L -or $totalB -ne 8992976071L){throw 'CONTENT_OR_TOTAL_DIFFERENCE'}
  $state='PASS_S42_129_UUP_PAIRS_BIT_IDENTICAL_READONLY'
 }catch{Note ('FAIL_CLOSED='+$_.Exception.Message)}
 finally{
  Note ('RESULT='+$state)
  Note 'DELETE=NOT_RUN;DOWNLOAD=NOT_RUN;CONVERTER=NOT_RUN'
  Write-Host ('REPORT='+$log)
  if(Test-Path -LiteralPath $csv -PathType Leaf){Write-Host ('CSV='+$csv)}
 }
}
