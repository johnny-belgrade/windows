# R038 OP121 independent new-source verification: read-only original ISO ELF/UDF EFI and FAT checksum.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$logs='C:\work\_UUP\R038_IsolatedBootBenchmark_26300\BlueLite_Logs'
$expectedIso='54719935DBB05261D562DE964635E934E1D066975E1AAB8334D67CF6F7EE2CEC'
$expectedFat='52F407452257E3B9CE5F1FFB55C5C9AD8272532E014C22B7563E9B4A80BAC7B0'
$expectedRoot='3F8A4CBBC97B89836DF92C4895236BE1FAC4A127665420D90509E897A7298511'
$r=[ordered]@{
 schema='BlueLite.R038.OP121.IndependentRootIsoCrossRead.v1'
 utc=[DateTime]::UtcNow.ToString('o')
 status='HOLD'
 verifier_sha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
 iso_sha256=$null;iso_bytes=$null
 fat_sha256=$null;fat_bytes=$null
 root_efi_sha256=$null;root_efi_bytes=$null
 pe_machine=$null;pe_optional_magic=$null;cms_decoded=$null;issuer=$null
 sevenzip_exit_code=$null;sevenzip_stderr=$null
 baseline_guest=$null;control_guest=$null;wim_mounts=$null
 output_file_count=0;error=$null
}
$child=$null
try{
 $extraction=Join-Path $logs 'R038_14_Extract_Result.json'
 if((Get-FileHash -LiteralPath $extraction -Algorithm SHA256).Hash -ne '6F27FBFE4C5B93023096579DABC31A0B0F1DCF7159DCCC54CE9902678D253B0B'){throw 'EXTRACT_EVIDENCE_SHA_DRIFT'}
 $sourceJson=Get-Content -LiteralPath $extraction -Raw|ConvertFrom-Json
 $iso=[string]$sourceJson.original_iso_path
 if(-not $iso.StartsWith('C:\work\_UUP\R035_Universal_PREMAX_26300\BlueLite_Work\',[StringComparison]::OrdinalIgnoreCase) -or -not $iso.EndsWith('.ISO',[StringComparison]::OrdinalIgnoreCase)){throw 'SOURCE_ISO_NOT_GUARDED'}
 $file=Get-Item -LiteralPath $iso -ErrorAction Stop
 if($file.Length -ne 6749851648 -or (($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)){throw 'SOURCE_SIZE_OR_LINK_DRIFT'}
 $r.iso_bytes=[long]$file.Length
 $r.iso_sha256=(Get-FileHash -LiteralPath $iso -Algorithm SHA256).Hash
 if($r.iso_sha256 -ne $expectedIso){throw 'ISO_HASH_CHANGED'}
 $fat=[byte[]]::new(1474560)
 $source=[IO.FileStream]::new($iso,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
 try{
  $source.Position=[long]526*2048
  $count=0
  while($count -lt $fat.Length){
   $n=$source.Read($fat,$count,$fat.Length-$count)
   if($n -lt 1){throw 'SHORT_READ_FAT'}
   $count+=$n
  }
 }finally{$source.Dispose()}
 $r.fat_bytes=$count
 $r.fat_sha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($fat))
 if($r.fat_sha256 -ne $expectedFat){throw 'FAT_HASH_CHANGED'}
 $exe='C:\work\E2E\BlueLite_R85_Native_Converter_26200.9711_85096553\bin\7z.exe'
 $dll='C:\work\E2E\BlueLite_R85_Native_Converter_26200.9711_85096553\bin\7z.dll'
 if((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -ne '9E2631C19B243C28B0980607CED2540E9447B1166572483475547C1A9DD4AC0E' -or (Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash -ne '3DB62076E5FCC897FF29DA47FE4029900A4AD696B395B6FA96ACFF1229444C1D'){throw '7Z_BINARY_DRIFT'}
 $psi=[Diagnostics.ProcessStartInfo]::new($exe)
 $psi.UseShellExecute=$false
 $psi.CreateNoWindow=$true
 $psi.RedirectStandardOutput=$true
 $psi.RedirectStandardError=$true
 [void]$psi.ArgumentList.Add('e')
 [void]$psi.ArgumentList.Add('-so')
 [void]$psi.ArgumentList.Add('-y')
 [void]$psi.ArgumentList.Add($iso)
 [void]$psi.ArgumentList.Add('EFI\BOOT\BOOTX64.EFI')
 $child=[Diagnostics.Process]::new()
 $child.StartInfo=$psi
 if(-not $child.Start()){throw '7Z_START_FAILED'}
 $stderrTask=$child.StandardError.ReadToEndAsync()
 $storage=[IO.MemoryStream]::new()
 try{
  $block=[byte[]]::new(32768)
  $n=1
  while($n -gt 0){
   $n=$child.StandardOutput.BaseStream.Read($block,0,$block.Length)
   if($n -gt 0){
    if($storage.Length+$n -gt 4194304){throw '7Z_ROOT_OUTPUT_TOO_LARGE'}
    $storage.Write($block,0,$n)
   }
  }
  if(-not $child.WaitForExit(30000)){throw '7Z_EXIT_TIMEOUT'}
  $r.sevenzip_exit_code=$child.ExitCode
  $err=[string]$stderrTask.GetAwaiter().GetResult()
  $r.sevenzip_stderr=$err.Substring(0,[Math]::Min($err.Length,200))
  if($child.ExitCode -ne 0){throw '7Z_ROOT_STREAM_NONZERO_EXIT'}
  $efi=$storage.ToArray()
 }finally{$storage.Dispose()}
 $r.root_efi_bytes=[long]$efi.Length
 if($efi.Length -ne 3086848){throw 'UDF_EFI_SIZE_DRIFT'}
 $r.root_efi_sha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($efi))
 if($r.root_efi_sha256 -ne $expectedRoot){throw 'UDF_EFI_SHA_DRIFT'}
 if($efi[0] -ne 77 -or $efi[1] -ne 90){throw 'EFI_MZ_INVALID'}
 $pe=[BitConverter]::ToInt32($efi,60)
 if($pe -lt 64 -or $pe+260 -ge $efi.Length -or $efi[$pe] -ne 80 -or $efi[$pe+1] -ne 69 -or $efi[$pe+2] -ne 0 -or $efi[$pe+3] -ne 0){throw 'EFI_PE_INVALID'}
 $r.pe_machine=('0x{0:X4}' -f [BitConverter]::ToUInt16($efi,$pe+4))
 $optional=$pe+24
 $mag=[BitConverter]::ToUInt16($efi,$optional)
 $r.pe_optional_magic=('0x{0:X4}' -f $mag)
 if($r.pe_machine -ne '0x8664' -or $mag -ne 523){throw 'EFI_PE_MACHINE_MAGIC_DRIFT'}
 $certdir=$optional+112+32
 $certStart=[int][BitConverter]::ToUInt32($efi,$certdir)
 $certSize=[int][BitConverter]::ToUInt32($efi,$certdir+4)
 if($certStart -lt 1 -or $certSize -lt 8 -or $certStart+$certSize -gt $efi.Length){throw 'EFI_CERT_TABLE_INVALID'}
 $certLength=[int][BitConverter]::ToUInt32($efi,$certStart)
 if($certLength -lt 8 -or $certLength -gt $certSize -or $certLength -gt 524288){throw 'EFI_CERT_LENGTH_INVALID'}
 try{
  Add-Type -AssemblyName System.Security.Cryptography.Pkcs -ErrorAction Stop
  $cmsBytes=[byte[]]::new($certLength-8)
  [Array]::Copy($efi,$certStart+8,$cmsBytes,0,$cmsBytes.Length)
  $cms=[Security.Cryptography.Pkcs.SignedCms]::new()
  $cms.Decode($cmsBytes)
  $r.cms_decoded=$true
  $signers=@($cms.SignerInfos)
  if($signers.Count -ne 1){throw 'CMS_SIGNER_COUNT_NOT_ONE'}
  $r.issuer=$signers[0].Certificate.Issuer
  if($r.issuer -notmatch 'Microsoft Windows Production PCA 2011'){throw 'CMS_ISSUER_NOT_2011'}
 }catch{throw ('SIGNED_CMS_METADATA_DIFF_'+$_.Exception.Message)}
 $baseline=Get-VM -Id 'c7536cc4-68f5-473a-9818-4053ba8794b2' -ErrorAction Stop
 $control=Get-VM -Id 'deb10ab5-3093-47a8-9a13-f3927446c606' -ErrorAction Stop
 $r.baseline_guest=([string]$baseline.State)+'/'+([string](Get-VMFirmware -VMName $baseline.Name).SecureBoot)
 $r.control_guest=([string]$control.State)+'/'+([string](Get-VMFirmware -VMName $control.Name).SecureBoot)
 if($baseline.Name -ne 'BlueLite-R038-UEFI-Baseline' -or $control.Name -ne 'BlueLite-R038-UEFI-SBOff-Control' -or $r.baseline_guest -ne 'Running/On' -or $r.control_guest -ne 'Off/Off'){throw 'GUEST_STATE_DRIFT'}
 $r.wim_mounts=@(Get-WindowsImage -Mounted -ErrorAction Stop).Count
 if($r.wim_mounts -ne 0){throw 'WIM_MOUNTS_PRESENT'}
 $r.status='SECOND_PROCESS_INDEPENDENT_ORIGINAL_ISO_FAT_UDF_ROOT_SHA_PE_CMS_PASS'
}catch{$r.error=$_.Exception.Message}
finally{if($null -ne $child){$child.Dispose()}}
$r|ConvertTo-Json -Depth 5
if($r.status -ne 'SECOND_PROCESS_INDEPENDENT_ORIGINAL_ISO_FAT_UDF_ROOT_SHA_PE_CMS_PASS'){exit 2}
exit 0
