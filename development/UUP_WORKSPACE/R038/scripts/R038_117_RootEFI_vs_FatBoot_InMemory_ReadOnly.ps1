# R038 OP117: Source-only read of original R035 ISO; no output files, mount, BCD/VM operations.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root='C:\work\_UUP\R038_IsolatedBootBenchmark_26300'
$logs=Join-Path $root 'BlueLite_Logs'
$expectedIsoSha='54719935DBB05261D562DE964635E934E1D066975E1AAB8334D67CF6F7EE2CEC'
$expectedFatSha='52F407452257E3B9CE5F1FFB55C5C9AD8272532E014C22B7563E9B4A80BAC7B0'
$exe='C:\work\E2E\BlueLite_R85_Native_Converter_26200.9711_85096553\bin\7z.exe'
$dll='C:\work\E2E\BlueLite_R85_Native_Converter_26200.9711_85096553\bin\7z.dll'
$r=[ordered]@{
 schema='BlueLite.R038.OP117.RootUdfVsElToritoMemory.v1'
 utc=[DateTime]::UtcNow.ToString('o')
 status='HOLD';script_sha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
 original_iso_path=$null;original_iso_bytes=$null;original_iso_sha256=$null
 sevenzip_exe_sha256=$null;sevenzip_dll_sha256=$null
 fat_image_lba=526;fat_image_bytes=1474560;fat_image_sha256=$null
 fat_embedded_bootx64_bytes_historical=1037120
 fat_embedded_bootx64_sha256_historical='7CD32D9C2B3B976B3D4546B18D8F8BBDFC7093D83220729E8B7D624A1FAFA2E8'
 root_efi_member='EFI\BOOT\BOOTX64.EFI'
 root_efi_bytes=$null;root_efi_sha256=$null
 sevenzip_stream_exit=$null;sevenzip_stderr=$null
 root_efi_mz=$null;root_efi_pe=$null;root_efi_machine=$null;root_efi_optional_magic=$null
 root_efi_security_table_bytes=$null;root_efi_cert_table_type=$null;root_efi_cms_decoded=$null
 root_efi_signers=@();root_efi_embedded_certs=@();root_efi_cms_error=$null
 root_differs_from_fat_bootx64=$null
 baseline_guest=$null;control_guest=$null;mounted_wim_count=$null
 bytes_written_to_local_media=0;error=$null
}
$proc=$null
try {
 $receipt=Join-Path $logs 'R038_14_Extract_Result.json'
 if((Get-FileHash -LiteralPath $receipt -Algorithm SHA256).Hash -ne '6F27FBFE4C5B93023096579DABC31A0B0F1DCF7159DCCC54CE9902678D253B0B'){throw 'EXTRACTION_RECEIPT_CHANGED'}
 $iso=[string]((Get-Content -LiteralPath $receipt -Raw|ConvertFrom-Json).original_iso_path)
 if(-not $iso.StartsWith('C:\work\_UUP\R035_Universal_PREMAX_26300\BlueLite_Work\',[StringComparison]::OrdinalIgnoreCase) -or -not $iso.EndsWith('.ISO',[StringComparison]::OrdinalIgnoreCase)){throw 'SOURCE_ISO_PATH_OUTSIDE_GUARD'}
 $fi=Get-Item -LiteralPath $iso -ErrorAction Stop
 if(($fi.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or $fi.Length -ne 6749851648){throw 'SOURCE_ISO_SIZE_OR_LINK'}
 $r.original_iso_path=$fi.FullName
 $r.original_iso_bytes=[long]$fi.Length
 $r.original_iso_sha256=(Get-FileHash -LiteralPath $iso -Algorithm SHA256).Hash
 if($r.original_iso_sha256 -ne $expectedIsoSha){throw 'SOURCE_ISO_FULL_SHA_CHANGED'}
 $r.sevenzip_exe_sha256=(Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash
 $r.sevenzip_dll_sha256=(Get-FileHash -LiteralPath $dll -Algorithm SHA256).Hash
 if($r.sevenzip_exe_sha256 -ne '9E2631C19B243C28B0980607CED2540E9447B1166572483475547C1A9DD4AC0E' -or $r.sevenzip_dll_sha256 -ne '3DB62076E5FCC897FF29DA47FE4029900A4AD696B395B6FA96ACFF1229444C1D'){throw 'VENDOR_7ZIP_BINARY_CHANGED'}
 $b=Get-VM -Id 'c7536cc4-68f5-473a-9818-4053ba8794b2' -ErrorAction Stop
 $c=Get-VM -Id 'deb10ab5-3093-47a8-9a13-f3927446c606' -ErrorAction Stop
 $r.baseline_guest=([string]$b.State)+'/'+([string](Get-VMFirmware -VMName $b.Name).SecureBoot)
 $r.control_guest=([string]$c.State)+'/'+([string](Get-VMFirmware -VMName $c.Name).SecureBoot)
 if($b.Name -ne 'BlueLite-R038-UEFI-Baseline' -or $c.Name -ne 'BlueLite-R038-UEFI-SBOff-Control' -or $r.baseline_guest -ne 'Running/On' -or $r.control_guest -ne 'Off/Off'){throw 'DEVELOPMENT_GUEST_STATE_CHANGED'}
 $r.mounted_wim_count=@(Get-WindowsImage -Mounted -ErrorAction Stop).Count
 if($r.mounted_wim_count -ne 0){throw 'WIM_MOUNT_PRESENT'}
 # Exactly the 1.44 MiB FAT image at catalog-proven LBA526. Source ISO opened readonly.
 $fat=[byte[]]::new(1474560)
 $s=[IO.File]::Open($iso,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
 try {
  [void]$s.Seek([long]526*2048,[IO.SeekOrigin]::Begin)
  $nread=0
  while($nread -lt $fat.Length){
   $n=$s.Read($fat,$nread,$fat.Length-$nread)
   if($n -le 0){throw 'FAT_IMAGE_SHORT_READ'}
   $nread+=$n
  }
 }finally{$s.Dispose()}
 $r.fat_image_sha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($fat))
 if($r.fat_image_sha256 -ne $expectedFatSha){throw 'ELTORITO_FAT_FULL_SHA_CHANGED'}
 # Exact root UDF member streamed by 7-Zip to process stdout in RAM, NEVER a filesystem extraction.
 $psi=[Diagnostics.ProcessStartInfo]::new()
 $psi.FileName=$exe
 $psi.WorkingDirectory=Split-Path -Parent $exe
 $psi.UseShellExecute=$false
 $psi.CreateNoWindow=$true
 $psi.RedirectStandardOutput=$true
 $psi.RedirectStandardError=$true
 foreach($arg in @('e','-so','-y',$iso,'EFI\BOOT\BOOTX64.EFI')){[void]$psi.ArgumentList.Add([string]$arg)}
 $proc=[Diagnostics.Process]::new()
 $proc.StartInfo=$psi
 if(-not $proc.Start()){throw 'SEVENZIP_PROCESS_NOT_STARTED'}
 $stderrTask=$proc.StandardError.ReadToEndAsync()
 $ms=[IO.MemoryStream]::new()
 try{
  $buffer=[byte[]]::new(65536)
  while(($n=$proc.StandardOutput.BaseStream.Read($buffer,0,$buffer.Length)) -gt 0){
   if($ms.Length+$n -gt 4194304){throw 'ROOT_EFI_STREAM_MORE_THAN_4MIB'}
   $ms.Write($buffer,0,$n)
  }
  if(-not $proc.WaitForExit(30000)){throw 'SEVENZIP_TIMEOUT'}
  $r.sevenzip_stream_exit=$proc.ExitCode
  $err=[string]$stderrTask.GetAwaiter().GetResult()
  $r.sevenzip_stderr=$err.Substring(0,[Math]::Min($err.Length,400))
  if($proc.ExitCode -ne 0){throw ('SEVENZIP_EXIT_'+$proc.ExitCode)}
  $data=$ms.ToArray()
 }finally{$ms.Dispose()}
 $r.root_efi_bytes=[long]$data.Length
 if($data.Length -ne 3086848){throw ('ROOT_UDF_EFI_UNEXPECTED_BYTES_'+$data.Length)}
 $r.root_efi_sha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($data))
 $r.root_differs_from_fat_bootx64=($r.root_efi_bytes -ne $r.fat_embedded_bootx64_bytes_historical)
 $r.root_efi_mz=($data[0] -eq 77 -and $data[1] -eq 90)
 if(-not $r.root_efi_mz){throw 'ROOT_EFI_MZ_MISSING'}
 $pe=[BitConverter]::ToInt32($data,60)
 if($pe -lt 64 -or $pe+260 -ge $data.Length){throw 'ROOT_PE_HEADER_BOUNDS'}
 $r.root_efi_pe=($data[$pe] -eq 80 -and $data[$pe+1] -eq 69 -and $data[$pe+2] -eq 0 -and $data[$pe+3] -eq 0)
 if(-not $r.root_efi_pe){throw 'ROOT_EFI_PE_SIGNATURE_MISSING'}
 $machine=[BitConverter]::ToUInt16($data,$pe+4)
 $r.root_efi_machine=('0x{0:X4}' -f $machine)
 if($machine -ne 0x8664){throw 'ROOT_EFI_NOT_X64'}
 $opt=$pe+24
 $magic=[BitConverter]::ToUInt16($data,$opt)
 $r.root_efi_optional_magic=('0x{0:X4}' -f $magic)
 if($magic -ne 523 -and $magic -ne 267){throw 'UNEXPECTED_ROOT_EFI_PE_MAGIC'}
 $dir=$opt+$(if($magic -eq 523){112}else{96})+32
 if($dir+8 -gt $data.Length){throw 'CERT_DIRECTORY_OUTSIDE_PE'}
 $coff=[long][BitConverter]::ToUInt32($data,$dir)
 $csize=[long][BitConverter]::ToUInt32($data,$dir+4)
 $r.root_efi_security_table_bytes=$csize
 if($csize -gt 0){
  if($csize -lt 8 -or $coff -lt 1 -or $coff+$csize -gt $data.Length){throw 'ROOT_EFI_CERT_TABLE_OUTSIDE_FILE'}
  $clen=[long][BitConverter]::ToUInt32($data,[int]$coff)
  $ctyp=[int][BitConverter]::ToUInt16($data,[int]$coff+6)
  $r.root_efi_cert_table_type=('0x{0:X4}' -f $ctyp)
  if($clen -lt 8 -or $clen -gt $csize -or $clen -gt 524288){throw 'ROOT_EFI_CERT_TABLE_UNEXPECTED_LENGTH'}
  try{
   Add-Type -AssemblyName System.Security.Cryptography.Pkcs -ErrorAction Stop
   $enc=[byte[]]::new([int]$clen-8)
   [Array]::Copy($data,[int]$coff+8,$enc,0,$enc.Length)
   $cms=[Security.Cryptography.Pkcs.SignedCms]::new()
   $cms.Decode($enc)
   $r.root_efi_cms_decoded=$true
   $r.root_efi_signers=@($cms.SignerInfos|ForEach-Object {[ordered]@{subject=$_.Certificate.Subject;issuer=$_.Certificate.Issuer;thumbprint=$_.Certificate.Thumbprint}})
   $r.root_efi_embedded_certs=@($cms.Certificates|ForEach-Object {[ordered]@{subject=$_.Subject;issuer=$_.Issuer;not_after_utc=$_.NotAfter.ToUniversalTime().ToString('o');thumbprint=$_.Thumbprint}})
  }catch{
   $r.root_efi_cms_decoded=$false
   $r.root_efi_cms_error=$_.Exception.Message.Substring(0,[Math]::Min(250,$_.Exception.Message.Length))
  }
 }else{$r.root_efi_cms_decoded=$false}
 $r.status='ORIGINAL_ISO_UDF_ROOT_EFI_FAT_DIFFERENTIAL_READONLY_PASS'
}
catch{$r.error=$_.Exception.Message}
finally{if($null -ne $proc){$proc.Dispose()}}
$r|ConvertTo-Json -Depth 8
if($r.status -ne 'ORIGINAL_ISO_UDF_ROOT_EFI_FAT_DIFFERENTIAL_READONLY_PASS'){exit 2}
exit 0
