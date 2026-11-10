# R038 OP130: independent physical SHA audit, read-only from original R035 ISO, no filesystem output.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$logs = 'C:\work\_UUP\R038_IsolatedBootBenchmark_26300\BlueLite_Logs'
$isoSha = '54719935DBB05261D562DE964635E934E1D066975E1AAB8334D67CF6F7EE2CEC'
$fatSha = '52F407452257E3B9CE5F1FFB55C5C9AD8272532E014C22B7563E9B4A80BAC7B0'
$exe = 'C:\work\E2E\BlueLite_R85_Native_Converter_26200.9711_85096553\bin\7z.exe'
$dll = 'C:\work\E2E\BlueLite_R85_Native_Converter_26200.9711_85096553\bin\7z.dll'
$report = [ordered]@{
 schema='BlueLite.R038.OP130.EfisysIndependentPhysicalRead.v1'
 utc=[DateTime]::UtcNow.ToUniversalTime().ToString('o')
 status='HOLD'
 verifier_sha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
 original_iso_sha256=$null
 original_iso_bytes=$null
 fat_eltorito_bytes=1474560
 fat_eltorito_sha256=$null
 udf_member='EFI\Microsoft\Boot\efisys.bin'
 udf_efisys_bytes=$null
 udf_efisys_sha256=$null
 content_sha_equal=$null
 stream_exit_code=$null
 stream_stderr=$null
 baseline_guest=$null
 control_guest=$null
 mounted_wim_count=$null
 output_files_created=0
 error=$null
}
$process=$null
try {
 $receipt=Join-Path $logs 'R038_14_Extract_Result.json'
 if((Get-FileHash -LiteralPath $receipt -Algorithm SHA256).Hash -ne '6F27FBFE4C5B93023096579DABC31A0B0F1DCF7159DCCC54CE9902678D253B0B'){throw 'EXTRACTION_RECEIPT_HASH_CHANGED'}
 $manifest=Get-Content -LiteralPath $receipt -Raw -ErrorAction Stop | ConvertFrom-Json
 $source=[string]$manifest.original_iso_path
 if(-not $source.StartsWith('C:\work\_UUP\R035_Universal_PREMAX_26300\BlueLite_Work\',[StringComparison]::OrdinalIgnoreCase) -or -not $source.EndsWith('.ISO',[StringComparison]::OrdinalIgnoreCase)){throw 'SOURCE_ISO_PATH_OUTSIDE_OWNER'}
 $iso=Get-Item -LiteralPath $source -ErrorAction Stop
 if(($iso.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or $iso.Length -ne 6749851648){throw 'ORIGINAL_ISO_NOT_EXACT_SOURCE'}
 $report.original_iso_bytes=[long]$iso.Length
 $report.original_iso_sha256=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
 if($report.original_iso_sha256 -ne $isoSha){throw 'ORIGINAL_ISO_FULL_SHA_DRIFT'}
 if((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -ne '9E2631C19B243C28B0980607CED2540E9447B1166572483475547C1A9DD4AC0E' -or (Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash -ne '3DB62076E5FCC897FF29DA47FE4029900A4AD696B395B6FA96ACFF1229444C1D'){throw '7ZIP_TOOL_SHA_DRIFT'}
 $direct = [byte[]]::new(1474560)
 $isoStream=[IO.FileStream]::new($source,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
 try {
  $isoStream.Position=[long]526*2048
  $total=0
  while($total -lt $direct.Length) {
   $got=$isoStream.Read($direct,$total,$direct.Length-$total)
   if($got -le 0){throw 'DIRECT_FAT_IMAGE_SHORT_READ'}
   $total+=$got
  }
 } finally { $isoStream.Dispose() }
 $report.fat_eltorito_sha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($direct))
 if($report.fat_eltorito_sha256 -ne $fatSha){throw 'ELTORITO_FAT_SHA_DRIFT'}
 $start=[Diagnostics.ProcessStartInfo]::new()
 $start.FileName=$exe
 $start.WorkingDirectory=Split-Path -Path $exe -Parent
 $start.UseShellExecute=$false
 $start.CreateNoWindow=$true
 $start.RedirectStandardOutput=$true
 $start.RedirectStandardError=$true
 foreach($a in @('e','-so','-y',$source,'EFI\Microsoft\Boot\efisys.bin')){[void]$start.ArgumentList.Add([string]$a)}
 $process=[Diagnostics.Process]::new()
 $process.StartInfo=$start
 if(-not $process.Start()){throw 'VENDOR_7ZIP_LAUNCH_FAILED'}
 $errTask=$process.StandardError.ReadToEndAsync()
 $memory=[IO.MemoryStream]::new()
 try {
  $block=[byte[]]::new(65536)
  $count=1
  while($count -gt 0){
   $count=$process.StandardOutput.BaseStream.Read($block,0,$block.Length)
   if($count -gt 0){
    if($memory.Length+$count -gt 2097152){throw 'EFISYS_MORE_THAN_2MIB'}
    $memory.Write($block,0,$count)
   }
  }
  if(-not $process.WaitForExit(30000)){throw '7ZIP_EXIT_TIMEOUT'}
  $report.stream_exit_code=$process.ExitCode
  $e=[string]$errTask.GetAwaiter().GetResult()
  $report.stream_stderr=$e.Substring(0,[Math]::Min($e.Length,200))
  if($process.ExitCode -ne 0){throw ('7ZIP_STREAM_FAILED_'+$process.ExitCode)}
  $udfBytes=$memory.ToArray()
 } finally {$memory.Dispose()}
 $report.udf_efisys_bytes=[long]$udfBytes.Length
 if($udfBytes.Length -ne $direct.Length){throw 'EFISYS_SIZE_NOT_FAT_SIZE'}
 $report.udf_efisys_sha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($udfBytes))
 $report.content_sha_equal=($report.udf_efisys_sha256 -eq $report.fat_eltorito_sha256)
 if(-not $report.content_sha_equal){throw 'UDF_EFISYS_AND_FAT_SHA_DIFFERENT'}
 $baseline=Get-VM -Id 'c7536cc4-68f5-473a-9818-4053ba8794b2' -ErrorAction Stop
 $control=Get-VM -Id 'deb10ab5-3093-47a8-9a13-f3927446c606' -ErrorAction Stop
 $report.baseline_guest=([string]$baseline.State)+'/'+([string](Get-VMFirmware -VMName $baseline.Name).SecureBoot)
 $report.control_guest=([string]$control.State)+'/'+([string](Get-VMFirmware -VMName $control.Name).SecureBoot)
 if($baseline.Name -ne 'BlueLite-R038-UEFI-Baseline' -or $control.Name -ne 'BlueLite-R038-UEFI-SBOff-Control' -or $report.baseline_guest -ne 'Running/On' -or $report.control_guest -ne 'Off/Off'){throw 'DEVELOPMENT_VM_GUARDS_CHANGED'}
 $report.mounted_wim_count=@(Get-WindowsImage -Mounted -ErrorAction Stop).Count
 if($report.mounted_wim_count -ne 0){throw 'DISM_MOUNT_PRESENT'}
 $report.status='INDEPENDENT_UDF_EFISYS_ELTORITO_FAT_SHA_EQUAL_SOURCE_PASS'
} catch { $report.error=$_.Exception.Message }
finally{ if($null -ne $process){$process.Dispose()} }
$report | ConvertTo-Json -Depth 5
if($report.status -ne 'INDEPENDENT_UDF_EFISYS_ELTORITO_FAT_SHA_EQUAL_SOURCE_PASS'){exit 2}
exit 0
