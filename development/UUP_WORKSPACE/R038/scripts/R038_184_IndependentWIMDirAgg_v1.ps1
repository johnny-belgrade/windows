# R038 OP184: independent, bounded, read-only detailed WIM path resource audit.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$stage = 'C:\work\_UUP\R035_Universal_PREMAX_26300\BlueLite_Work\BlueLite_Stage_v11_3_26300_9818_6c7bf258_fc76f92b'
$wim = Join-Path $stage 'BlueLite_R029_Outputs\install.wim'
$exe = Join-Path $stage 'bin\wimlib-imagex.exe'
$dll = Join-Path $stage 'bin\libwim-15.dll'
$scope = '\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_2024.401.617.0_neutral_~_8wekyb3d8bbwe'
$out = [ordered]@{ schema='BlueLite.R038.OP184.DirResourceAudit.v1'; utc=[datetime]::UtcNow.ToString('o'); status='HOLD'; source_sha256=$null; wim_bytes=$null; vendor_exit=$null; total_records=0; data_blob_sha_count=0; all_compressed_unique_bytes=0L; global_refcount_one_compressed_bytes=0L; scope=$scope; files=@(); raw_chars=0; error=$null }
$p = $null
try {
  $out.source_sha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
  $out.wim_bytes=[long](Get-Item -LiteralPath $wim).Length
  if($out.wim_bytes -ne 5663629505L){throw 'ORIGINAL_WIM_SIZE_DRIFT'}
  if((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -ne '01168A00FFC84EBFA1BD3B9C841214ED114B9AE4E9B23D555C0686448FD56BDE'){throw 'EXE_SHA_DRIFT'}
  if((Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash -ne 'E1B005C0F1391B30357E64885A08A09A2D41DE93B38ACAA25ED7A355F74F56B4'){throw 'DLL_SHA_DRIFT'}
  $si=[Diagnostics.ProcessStartInfo]::new()
  $si.FileName=$exe
  $si.WorkingDirectory=Join-Path $stage 'bin'
  $si.UseShellExecute=$false
  $si.CreateNoWindow=$true
  $si.RedirectStandardOutput=$true
  $si.RedirectStandardError=$true
  foreach($a in @('dir',$wim,'1','--detailed',('--path='+$scope))){[void]$si.ArgumentList.Add([string]$a)}
  $p=[Diagnostics.Process]::new()
  $p.StartInfo=$si
  if(-not $p.Start()){throw 'WIMLIB_START_FAILED'}
  $ot=$p.StandardOutput.ReadToEndAsync();$et=$p.StandardError.ReadToEndAsync()
  if(-not $p.WaitForExit(25000)){try{$p.Kill()}catch{};throw 'WIMLIB_TIMEOUT'}
  $out.vendor_exit=$p.ExitCode
  $raw=[string]$ot.GetAwaiter().GetResult()
  $err=[string]$et.GetAwaiter().GetResult()
  $out.raw_chars=$raw.Length
  if($out.vendor_exit -ne 0 -or $err.Trim() -or $raw.Length -gt 100000){throw 'WIMLIB_OUTPUT_EXIT_OR_BOUND_HOLD'}
  $records=New-Object 'System.Collections.Generic.List[object]'
  $current=$null
  foreach($line in ($raw -split '[\r\n]+')){
    if($line.StartsWith('Full Path')){
      if($null -ne $current){$records.Add([pscustomobject]$current)}
      $ix=$line.IndexOf('=')
      if($ix -lt 0){throw 'MALFORMED_FULLPATH'}
      $name=$line.Substring($ix+1).Trim().Trim([char]34)
      $current=[ordered]@{path=$name;hash=$null;compressed=-1L;uncompressed=-1L;refs=-1L}
    } elseif($null -ne $current){
      if($line -match '^Hash\s*=\s*0x([0-9a-fA-F]{40})'){$current.hash=$Matches[1].ToUpperInvariant()}
      elseif($line -match '^Compressed size\s*=\s*(\d+) bytes'){$current.compressed=[long]$Matches[1]}
      elseif($line -match '^Uncompressed size\s*=\s*(\d+) bytes'){$current.uncompressed=[long]$Matches[1]}
      elseif($line -match '^Reference Count\s*=\s*(\d+)'){$current.refs=[long]$Matches[1]}
    }
  }
  if($null -ne $current){$records.Add([pscustomobject]$current)}
  if($records.Count -eq 0){throw 'NO_PATH_RECORDS'}
  $seen=@{}
  $data=@()
  foreach($r in $records){
    if($null -eq $r.hash -or $r.compressed -lt 0 -or $r.refs -lt 0){throw 'INCOMPLETE_RECORD'}
    if($r.hash -ne ('0' * 40)){
      if(-not $seen.ContainsKey($r.hash)){
        $seen.Add($r.hash,$r)
        $data+= $r
      } elseif($seen[$r.hash].compressed -ne $r.compressed){throw 'DUP_BLOB_SIZE_CONFLICT'}
    }
  }
  $out.total_records=$records.Count
  $out.data_blob_sha_count=$data.Count
  $out.all_compressed_unique_bytes=[long](($data|Measure-Object compressed -Sum).Sum)
  $out.global_refcount_one_compressed_bytes=[long](($data|Where-Object { $_.refs -eq 1 }|Measure-Object compressed -Sum).Sum)
  $out.files=@($data|Select-Object -First 15|ForEach-Object { [pscustomobject]@{filename=([string]$_.path).Split('\')[-1];sha1=$_.hash;compressed=$_.compressed;refs=$_.refs} })
  $out.status='INDEPENDENT_DIR_RESOURCE_READONLY_PASS'
} catch { $out.error=$_.Exception.Message }
finally {if($null -ne $p){$p.Dispose()}}
$out | ConvertTo-Json -Depth 7 -Compress
if($out.status -ne 'INDEPENDENT_DIR_RESOURCE_READONLY_PASS'){exit 17}
