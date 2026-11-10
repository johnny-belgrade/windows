# R038 OP126 - read-only SHA compare original R035 El Torito FAT to UDF efisys.bin via in-memory stdout.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$logs='C:\work\_UUP\R038_IsolatedBootBenchmark_26300\BlueLite_Logs'
$fatHashExpected='52F407452257E3B9CE5F1FFB55C5C9AD8272532E014C22B7563E9B4A80BAC7B0'
$report=[ordered]@{
 schema='BlueLite.R038.OP126.UDFEfisysFATReadOnly.v1'
 utc=[DateTime]::UtcNow.ToString('o'); status='HOLD'
 script_sha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
 original_iso_sha256=$null; original_iso_bytes=$null
 fat_lba=526; fat_size=1474560; fat_sha256=$null
 udf_member='EFI\Microsoft\Boot\efisys.bin'; udf_size=$null; udf_sha256=$null
 udf_el_torito_fat_sha_equal=$null
 sevenzip_exit=$null; sevenzip_stderr=$null
 baseline=$null; control=$null; mounted_wim_count=$null
 created_output_files=0;error=$null
}
$child=$null
try{
 $receipt=Join-Path $logs 'R038_14_Extract_Result.json'
 if((Get-FileHash -LiteralPath $receipt -Algorithm SHA256).Hash -ne '6F27FBFE4C5B93023096579DABC31A0B0F1DCF7159DCCC54CE9902678D253B0B'){throw 'EXTRACT_RECEIPT_CHANGED'}
 $iso=[string]((Get-Content -LiteralPath $receipt -Raw|ConvertFrom-Json).original_iso_path)
 if(-not $iso.StartsWith('C:\work\_UUP\R035_Universal_PREMAX_26300\BlueLite_Work\',[StringComparison]::OrdinalIgnoreCase) -or -not $iso.EndsWith('.ISO',[StringComparison]::OrdinalIgnoreCase)){throw 'ISO_PATH_INVALID'}
 $f=Get-Item -LiteralPath $iso -ErrorAction Stop
 if($f.Length -ne 6749851648 -or (($f.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)){throw 'ISO_SOURCE_CHANGED'}
 $report.original_iso_bytes=[long]$f.Length
 $report.original_iso_sha256=(Get-FileHash -LiteralPath $iso -Algorithm SHA256).Hash
 if($report.original_iso_sha256 -ne '54719935DBB05261D562DE964635E934E1D066975E1AAB8334D67CF6F7EE2CEC'){throw 'ISO_SOURCE_SHA_DRIFT'}
 $fat=[byte[]]::new(1474560)
 $stream=[IO.File]::Open($iso,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
 try{
  [void]$stream.Seek([long]526*2048,[IO.SeekOrigin]::Begin)
  $nread=0
  while($nread -lt $fat.Length){
   $n=$stream.Read($fat,$nread,$fat.Length-$nread)
   if($n -le 0){throw 'FAT_IMAGE_SHORT_READ'}
   $nread+=$n
  }
 }finally{$stream.Dispose()}
 $report.fat_sha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($fat))
 if($report.fat_sha256 -ne $fatHashExpected){throw 'FAT_IMAGE_HASH_DRIFT'}
 $exe='C:\work\E2E\BlueLite_R85_Native_Converter_26200.9711_85096553\bin\7z.exe'
 $dll='C:\work\E2E\BlueLite_R85_Native_Converter_26200.9711_85096553\bin\7z.dll'
 if((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -ne '9E2631C19B243C28B0980607CED2540E9447B1166572483475547C1A9DD4AC0E' -or (Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash -ne '3DB62076E5FCC897FF29DA47FE4029900A4AD696B395B6FA96ACFF1229444C1D'){throw 'VENDOR_7Z_SHA_DRIFT'}
 $psi=[Diagnostics.ProcessStartInfo]::new($exe)
 $psi.UseShellExecute=$false;$psi.CreateNoWindow=$true
 $psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
 foreach($arg in @('e','-so','-y',$iso,'EFI\Microsoft\Boot\efisys.bin')){[void]$psi.ArgumentList.Add($arg)}
 $child=[Diagnostics.Process]::new()
 $child.StartInfo=$psi
 if(-not $child.Start()){throw '7Z_START_FAILED'}
 $stderrTask=$child.StandardError.ReadToEndAsync()
 $mem=[IO.MemoryStream]::new()
 try{
  $buf=[byte[]]::new(32768)
  $n=1
  while($n -gt 0){
   $n=$child.StandardOutput.BaseStream.Read($buf,0,$buf.Length)
   if($n -gt 0){
    if($mem.Length+$n -gt 2097152){throw 'UDF_EFISYS_STREAM_TOO_BIG'}
    $mem.Write($buf,0,$n)
   }
  }
  if(-not $child.WaitForExit(30000)){throw '7Z_TIMEOUT'}
  $report.sevenzip_exit=$child.ExitCode
  $er=[string]$stderrTask.GetAwaiter().GetResult()
  $report.sevenzip_stderr=$er.Substring(0,[Math]::Min($er.Length,230))
  if($child.ExitCode -ne 0){throw '7Z_EXTRACT_TO_MEMORY_NONZERO'}
  $bytes=$mem.ToArray()
 }finally{$mem.Dispose()}
 $report.udf_size=[long]$bytes.Length
 if($bytes.Length -ne 1474560){throw 'UDF_EFISYS_SOURCE_SIZE_DIFFERENT'}
 $report.udf_sha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))
 $report.udf_el_torito_fat_sha_equal=($report.udf_sha256 -eq $report.fat_sha256)
 $baseline=Get-VM -Id 'c7536cc4-68f5-473a-9818-4053ba8794b2' -ErrorAction Stop
 $control=Get-VM -Id 'deb10ab5-3093-47a8-9a13-f3927446c606' -ErrorAction Stop
 $report.baseline=([string]$baseline.State)+'/'+([string](Get-VMFirmware -VMName $baseline.Name).SecureBoot)
 $report.control=([string]$control.State)+'/'+([string](Get-VMFirmware -VMName $control.Name).SecureBoot)
 if($baseline.Name -ne 'BlueLite-R038-UEFI-Baseline' -or $control.Name -ne 'BlueLite-R038-UEFI-SBOff-Control' -or $report.baseline -ne 'Running/On' -or $report.control -ne 'Off/Off'){throw 'GUEST_STATES_CHANGED'}
 $report.mounted_wim_count=@(Get-WindowsImage -Mounted -ErrorAction Stop).Count
 if($report.mounted_wim_count -ne 0){throw 'HOST_WIM_MOUNTED'}
 $report.status=if($report.udf_el_torito_fat_sha_equal){'UDF_EFISYS_ELTORITO_FAT_SOURCE_SHA_EQUAL_READONLY_PASS'}else{'UDF_EFISYS_ELTORITO_FAT_MISMATCH_SOURCE_HOLD'}
}catch{$report.error=$_.Exception.Message}
finally{if($null -ne $child){$child.Dispose()}}
$report|ConvertTo-Json -Depth 6
if($report.status -ne 'UDF_EFISYS_ELTORITO_FAT_SOURCE_SHA_EQUAL_READONLY_PASS'){exit 2}
exit 0
