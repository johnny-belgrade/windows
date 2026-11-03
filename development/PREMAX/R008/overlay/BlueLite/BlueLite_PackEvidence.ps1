[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$UUPRoot,[int]$EngineExitCode=99)
$ErrorActionPreference='Stop'
try {
 Add-Type -AssemblyName System.IO.Compression
 Add-Type -AssemblyName System.IO.Compression.FileSystem
 $root=(Resolve-Path -LiteralPath $UUPRoot).Path
 $utc=[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
 $archive=Join-Path $root ('BlueLite_EVIDENCE_'+$utc+'.zip')
 $partial=Join-Path $root ('BlueLite_EVIDENCE_'+$utc+'.tmp.zip')
 $stage=Join-Path $root ('BlueLite_EVIDENCE_STAGE_'+$utc)
 $verify=Join-Path $root ('BlueLite_EVIDENCE_VERIFY_'+$utc)
 if(Test-Path -LiteralPath $archive){throw 'Timestamp collision for evidence filename.'}
 New-Item -ItemType Directory -Path (Join-Path $stage 'Logs') -Force|Out-Null
 $logDir=Join-Path $root 'BlueLite_Logs'
 if(Test-Path -LiteralPath $logDir){
  Copy-Item -LiteralPath (Join-Path $logDir '*') -Destination (Join-Path $stage 'Logs') -Recurse -Force -ErrorAction SilentlyContinue
  foreach($f in @(Get-ChildItem -LiteralPath $logDir -Force)){
   Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $stage 'Logs') -Recurse -Force -ErrorAction Stop
  }
 }
 $source=Join-Path $root 'uup_download_windows.cmd'
 $sourceSha=if(Test-Path -LiteralPath $source){(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash}else{'MISSING'}
 $profile=Join-Path $root 'BlueLite\BlueLite_Profile.ini'
 $profileSha=if(Test-Path -LiteralPath $profile){(Get-FileHash -LiteralPath $profile -Algorithm SHA256).Hash}else{'MISSING'}
 [ordered]@{
  CreatedUtc=[DateTime]::UtcNow.ToString('o')
  Status=$(if($EngineExitCode -eq 0){'ENGINE_RETURNED_ZERO'}else{'HOLD'})
  EngineExitCode=$EngineExitCode
  OriginalRoot=$root
  OriginalLauncherSha256=$sourceSha
  BlueLiteProfileSha256=$profileSha
  Scope='Transport/convert/MAX_PRE native evidence, NOT VM release proof.'
 } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $stage 'Summary.json') -Encoding UTF8
 $manifest=[Collections.Generic.List[object]]::new()
 foreach($file in @(Get-ChildItem -LiteralPath $stage -File -Recurse)){
  $rel=$file.FullName.Substring($stage.Length+1).Replace('\','/')
  [void]$manifest.Add([pscustomobject]@{Path=$rel;Size=$file.Length;SHA256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash})
 }
 $manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $stage 'FilesManifest.json') -Encoding UTF8
 [IO.Compression.ZipFile]::CreateFromDirectory($stage,$partial,[IO.Compression.CompressionLevel]::Optimal,$false)
 [IO.Compression.ZipFile]::ExtractToDirectory($partial,$verify)
 $items=@(Get-Content -LiteralPath (Join-Path $verify 'FilesManifest.json') -Raw | ConvertFrom-Json)
 if($items.Count -ne $manifest.Count){throw 'Evidence manifest count mismatch after ZIP extraction.'}
 foreach($item in $items){
  $p=Join-Path $verify ($item.Path.Replace('/','\'))
  if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw ('ZIP missing entry: {0}' -f $item.Path)}
  if((Get-Item -LiteralPath $p).Length -ne [long]$item.Size){throw ('ZIP size mismatch: {0}' -f $item.Path)}
  if((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash -ne $item.SHA256){throw ('ZIP SHA256 mismatch: {0}' -f $item.Path)}
 }
 Move-Item -LiteralPath $partial -Destination $archive -ErrorAction Stop
 $aHash=(Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash
 if(-not $aHash){throw 'Evidence ZIP digest missing.'}
 # Only after independent extraction+SHA verification: remove transient evidence folders.
 Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction Stop
 Remove-Item -LiteralPath $verify -Recurse -Force -ErrorAction Stop
 if(Test-Path -LiteralPath $logDir){Remove-Item -LiteralPath $logDir -Recurse -Force -ErrorAction Stop}
 foreach($old in @(Get-ChildItem -LiteralPath $root -File -Filter 'BlueLite_EVIDENCE_*.zip')){
  if($old.FullName -ne $archive){Remove-Item -LiteralPath $old.FullName -Force -ErrorAction Stop}
 }
 Write-Host ('EVIDENCE_ZIP_VERIFIED_AND_ONLY_LAST_RETAINED: {0}' -f $archive) -ForegroundColor Green
 Write-Host ('EVIDENCE_SHA256: {0}' -f $aHash)
 exit 0
}catch{
 Write-Host ('EVIDENCE_HOLD (original logs retained): {0}' -f $_.Exception.Message) -ForegroundColor Red
 exit 1
}