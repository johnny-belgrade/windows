# BlueLite R038_09_EFIBootImageAndSecureBoot_ReadOnly_v1.1.ps1 — no ISO/WIM/VM writes; parse embedded FAT and PE signer certificate in memory only
[CmdletBinding()]
param([string]$Root='C:\work\_UUP\R038_IsolatedBootBenchmark_26300')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($Root -ne 'C:\work\_UUP\R038_IsolatedBootBenchmark_26300'){throw 'WORKSPACE_NOT_APPROVED'}
$logs=Join-Path $Root 'BlueLite_Logs'
$catalogPath=Join-Path $logs 'R038_08_ISOElToritoReadOnly_Result.json'
$output=Join-Path $logs 'R038_09_EFIFATBootloader_SecureBoot_Result.json'
if(Test-Path -LiteralPath $output){throw 'FORENSIC_RESULT_ALREADY_EXISTS'}
if((Get-FileHash -LiteralPath $catalogPath).Hash -ne '5D561C25A722006CC6960E4B0C7CE11703FF308B0483E18B0374D327063639B4'){throw 'ELTORITO_EVIDENCE_SHA_DRIFT'}
$catalog=Get-Content -LiteralPath $catalogPath -Raw|ConvertFrom-Json
if($catalog.media.Count -ne 2 -or $catalog.status -ne 'READONLY_TWO_ISO_CATALOGS_RECORDED_UEFI_BOOT_CAUSE_PENDING'){throw 'UNEXPECTED_CATALOG_MANIFEST'}
$vmid='c7536cc4-68f5-473a-9818-4053ba8794b2'
$vm=Get-VM -Id $vmid -ErrorAction Stop
if($vm.Name -ne 'BlueLite-R038-UEFI-Baseline' -or $vm.Generation -ne 2){throw 'WRONG_ISOLATED_GUEST'}
$fw=Get-VMFirmware -VMName $vm.Name -ErrorAction Stop
$dvd=@(Get-VMDvdDrive -VMName $vm.Name -ErrorAction Stop)
if($dvd.Count -ne 1 -or $dvd[0].Path -ne $catalog.media[0].source_path -or [string]$fw.SecureBoot -ne 'On'){throw 'VM_DVD_OR_SECUREBOOT_DRIFT'}
if(@(Get-WindowsImage -Mounted -ErrorAction Stop).Count -ne 0){throw 'HOST_WIM_MOUNT_EXISTS'}
function Hash-Buffer([byte[]]$data){return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($data))}
function Take-Bytes([byte[]]$data,[int]$start,[int]$length){
 if($start -lt 0 -or $length -lt 0 -or ([long]$start+$length) -gt $data.Length){throw 'FAT_BYTE_SLICE_BOUNDS'}
 $part=[byte[]]::new($length)
 [Array]::Copy($data,$start,$part,0,$length)
 return ,$part
}
function Next-FATCluster([byte[]]$data,[Collections.IDictionary]$geo,[int]$cluster) {
 $type=[string]$geo.fat_type;$begin=[int]$geo.fat_sector_start*[int]$geo.bytes_per_sector
 if($type -eq 'FAT12'){
  $at=$begin+$cluster+[int][math]::Floor($cluster/2)
  if($at+2 -gt $data.Length){throw 'FAT12_ENTRY_OUT_OF_RANGE'}
  $word=[int]$data[$at] -bor ([int]$data[$at+1] -shl 8)
  $next=if($cluster -band 1){$word -shr 4}else{$word -band 4095}
  if($next -ge 4088){return 0}
  if($next -lt 2 -or $next -eq 4087){throw 'FAT12_BROKEN_CLUSTER_CHAIN'}
  return [int]$next
 }
 if($type -eq 'FAT16'){
  $at=$begin+$cluster*2
  if($at+2 -gt $data.Length){throw 'FAT16_ENTRY_OUT_OF_RANGE'}
  $next=[int][BitConverter]::ToUInt16($data,$at)
  if($next -ge 65528){return 0}
  if($next -lt 2 -or $next -eq 65527){throw 'FAT16_BROKEN_CLUSTER_CHAIN'}
  return $next
 }
 throw ('UNSUPPORTED_IMAGE_FAT_TYPE_'+$type)
}
function Read-FATClusterChain([byte[]]$data,[Collections.IDictionary]$geo,[int]$initial,[int]$limitBytes){
 if($initial -lt 2){throw 'INVALID_INITIAL_FAT_CLUSTER'}
 $bps=[int]$geo.bytes_per_sector
 $spc=[int]$geo.sectors_per_cluster
 $clusterBytes=$bps*$spc
 $out=[IO.MemoryStream]::new()
 $seen=[Collections.Generic.HashSet[int]]::new()
 try{
  $cl=$initial
  while($cl -ne 0){
   if(-not $seen.Add($cl)){throw 'CYCLIC_FAT_CLUSTER_CHAIN'}
   if($seen.Count -gt 8192 -or $out.Length+$clusterBytes -gt $limitBytes){throw 'FAT_CHAIN_EXCEEDS_BOUNDED_READ'}
   if($cl -gt [int]$geo.max_cluster_index){throw 'FAT_CLUSTER_INDEX_TOO_LARGE'}
   $offset=([int]$geo.first_data_sector+($cl-2)*$spc)*$bps
   $piece=Take-Bytes $data $offset $clusterBytes
   $out.Write($piece,0,$piece.Length)
   $cl=Next-FATCluster $data $geo $cl
  }
  return ,$out.ToArray()
 }finally{$out.Dispose()}
}
function Parse-FATDirectory([byte[]]$dir){
 $list=[Collections.Generic.List[object]]::new()
 for($i=0;$i+31 -lt $dir.Length;$i+=32){
  $first=[int]$dir[$i]
  if($first -eq 0){break}
  if($first -eq 229){continue}
  $attr=[int]$dir[$i+11]
  if($attr -eq 15 -or (($attr -band 8) -ne 0)){continue}
  $base=[Text.Encoding]::ASCII.GetString($dir,$i,8).Trim()
  $ext=[Text.Encoding]::ASCII.GetString($dir,$i+8,3).Trim()
  $name=if($ext){$base+'.'+$ext}else{$base}
  $cluster=[int][BitConverter]::ToUInt16($dir,$i+26)
  $size=[long][BitConverter]::ToUInt32($dir,$i+28)
  [void]$list.Add([ordered]@{name=$name;short_base=$base;ext=$ext;is_dir=(($attr -band 16) -ne 0);start_cluster=$cluster;file_bytes=$size;attribute_hex=('0x{0:X2}' -f $attr)})
 }
 return ,@($list)
}
function Find-OneFAT([object[]]$list,[string]$name,[bool]$expectDir){
 $found=@($list | Where-Object {$_.name -eq $name -and $_.is_dir -eq $expectDir})
 if($found.Count -eq 0){return $null}
 if($found.Count -ne 1){throw ('DUPLICATE_FAT_SHORT_ENTRY_'+$name)}
 return $found[0]
}
function Inspect-PE([byte[]]$binary){
 $p=[ordered]@{mz_present=$false;pe_signature_present=$false;machine_hex=$null;pe_magic_hex=$null;security_directory_offset=$null;security_directory_bytes=0;win_certificate_type=$null;embedded_signed_cms_decoded=$false;cms_parse_error=$null;signers=@();embedded_certificates=@();winverifytrust_or_uefi_policy_validated=$false}
 if($binary.Length -lt 512){return $p}
 $p.mz_present=($binary[0] -eq 77 -and $binary[1] -eq 90)
 if(-not $p.mz_present){return $p}
 $pe=[BitConverter]::ToInt32($binary,60)
 if($pe -lt 64 -or $pe+260 -gt $binary.Length){return $p}
 $p.pe_signature_present=($binary[$pe] -eq 80 -and $binary[$pe+1] -eq 69 -and $binary[$pe+2] -eq 0 -and $binary[$pe+3] -eq 0)
 if(-not $p.pe_signature_present){return $p}
 $p.machine_hex=('0x{0:X4}' -f [BitConverter]::ToUInt16($binary,$pe+4))
 $optionalStart=$pe+24
 $magic=[BitConverter]::ToUInt16($binary,$optionalStart)
 $p.pe_magic_hex=('0x{0:X4}' -f $magic)
 $certOff=if($magic -eq 523){112}elseif($magic -eq 267){96}else{-1}
 if($certOff -lt 0){return $p}
 $dir=$optionalStart+$certOff+32
 if($dir+8 -gt $binary.Length){return $p}
 $offset=[long][BitConverter]::ToUInt32($binary,$dir)
 $count=[long][BitConverter]::ToUInt32($binary,$dir+4)
 $p.security_directory_offset=$offset
 $p.security_directory_bytes=$count
 if($count -lt 8 -or $offset -lt 1 -or ($offset+$count) -gt $binary.Length){return $p}
 $certLength=[long][BitConverter]::ToUInt32($binary,[int]$offset)
 $certType=[int][BitConverter]::ToUInt16($binary,[int]$offset+6)
 $p.win_certificate_type=('0x{0:X4}' -f $certType)
 if($certLength -lt 8 -or $certLength -gt $count -or $certLength -gt 500000){return $p}
 try{
  Add-Type -AssemblyName System.Security.Cryptography.Pkcs -ErrorAction Stop
  $pkcs=Take-Bytes $binary ([int]$offset+8) ([int]$certLength-8)
  $cms=[System.Security.Cryptography.Pkcs.SignedCms]::new()
  $cms.Decode($pkcs)
  $signers=[Collections.Generic.List[object]]::new()
  foreach($si in $cms.SignerInfos){
   $cert=$si.Certificate
   [void]$signers.Add([ordered]@{subject=$(if($null -ne $cert){$cert.Subject}else{$null});issuer=$(if($null -ne $cert){$cert.Issuer}else{$null});thumbprint=$(if($null -ne $cert){$cert.Thumbprint}else{$null})})
  }
  $certs=[Collections.Generic.List[object]]::new()
  foreach($cert in $cms.Certificates){
   [void]$certs.Add([ordered]@{subject=$cert.Subject;issuer=$cert.Issuer;not_after_utc=$cert.NotAfter.ToUniversalTime().ToString('o');thumbprint=$cert.Thumbprint})
  }
  $p.embedded_signed_cms_decoded=$true
  $p.signers=@($signers)
  $p.embedded_certificates=@($certs)
 }catch{
  $p.cms_parse_error=$_.Exception.Message.Substring(0,[math]::Min(300,$_.Exception.Message.Length))
 }
 return $p
}
$sourceResults=[Collections.Generic.List[object]]::new()
foreach($source in $catalog.media){
 $entries=@($source.boot_entries | Where-Object {$_.platform_id -eq '0xEF' -and $_.bootable -and $_.image_lba_valid})
 if($entries.Count -ne 1){throw ('EFI_CATALOG_NOT_UNIQUE_'+$source.kind)}
 $imageLba=[long]$entries[0].image_lba_2048B
 if($imageLba -ne 526){throw 'UNEXPECTED_EFI_IMAGE_LBA'}
 $f=Get-Item -LiteralPath $source.source_path -ErrorAction Stop
 if($f.Length -ne [long]$source.source_bytes){throw ('SOURCE_ISO_BYTES_CHANGED_'+$source.kind)}
 $file=[IO.File]::Open($f.FullName,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
 try{
  $offset=$imageLba*2048
  $boot=[byte[]]::new(512)
  [void]$file.Seek($offset,[IO.SeekOrigin]::Begin)
  if($file.Read($boot,0,512) -ne 512){throw 'SOURCE_FAT_BOOT_SHORT'}
  $bytesPerSec=[int][BitConverter]::ToUInt16($boot,11)
  $spc=[int]$boot[13]
  $reserved=[int][BitConverter]::ToUInt16($boot,14)
  $fatCount=[int]$boot[16]
  $rootCount=[int][BitConverter]::ToUInt16($boot,17)
  $total16=[int][BitConverter]::ToUInt16($boot,19)
  $total32=[long][BitConverter]::ToUInt32($boot,32)
  $totalSec=if($total16 -gt 0){[long]$total16}else{$total32}
  $fatSize16=[int][BitConverter]::ToUInt16($boot,22)
  if($bytesPerSec -ne 512 -and $bytesPerSec -ne 1024 -and $bytesPerSec -ne 2048 -and $bytesPerSec -ne 4096){throw 'FAT_UNSUPPORTED_SECTOR_SIZE'}
  if($spc -lt 1 -or $spc -gt 128 -or ($spc -band ($spc-1)) -ne 0){throw 'FAT_UNSUPPORTED_CLUSTER_SIZE'}
  if($reserved -lt 1 -or $fatCount -lt 1 -or $fatCount -gt 4 -or $rootCount -le 0 -or $fatSize16 -lt 1){throw 'FAT_NOT_SIMPLE_12_OR_16'}
  $rootSec=[int][math]::Ceiling($rootCount*32.0/$bytesPerSec)
  $firstData=$reserved+$fatCount*$fatSize16+$rootSec
  $clusters=[int][math]::Floor(($totalSec-$firstData)/$spc)
  $fatType=if($clusters -lt 4085){'FAT12'}elseif($clusters -lt 65525){'FAT16'}else{'OTHER'}
  if($fatType -eq 'OTHER'){throw 'FAT32_UNSUPPORTED_STOP'}
  $volBytes=[long]$bytesPerSec*$totalSec
  if($volBytes -le 0 -or $volBytes -gt 67108864 -or ($offset+$volBytes) -gt $file.Length){throw ('EFI_IMAGE_EXCEEDS_SAFE_BOUNDS_'+$source.kind)}
  $vol=[byte[]]::new([int]$volBytes)
  [void]$file.Seek($offset,[IO.SeekOrigin]::Begin)
  $read=0
  while($read -lt $vol.Length){
   $n=$file.Read($vol,$read,$vol.Length-$read)
   if($n -le 0){throw 'SHORT_READ_EFI_FAT_IMAGE'}
   $read += $n
  }
  $geo=[ordered]@{bytes_per_sector=$bytesPerSec;sectors_per_cluster=$spc;reserved_sectors=$reserved;fat_count=$fatCount;fat_sector_start=$reserved;sectors_per_fat=$fatSize16;root_entries=$rootCount;root_directory_sectors=$rootSec;first_data_sector=$firstData;cluster_count=$clusters;max_cluster_index=($clusters+1);total_sectors=$totalSec;fat_type=$fatType}
  $rootOffset=($reserved+$fatCount*$fatSize16)*$bytesPerSec
  $rootDir=Take-Bytes $vol $rootOffset ($rootCount*32)
  $rootEntries=Parse-FATDirectory $rootDir
  $efi=Find-OneFAT $rootEntries 'EFI' $true
  $paths=[Collections.Generic.List[object]]::new()
  $efiDir=$null;$bootDir=$null;$efiBootLoader=$null
  if($null -ne $efi){
   $efiDir=Parse-FATDirectory (Read-FATClusterChain $vol $geo ([int]$efi.start_cluster) 1048576)
   $bootFolder=Find-OneFAT $efiDir 'BOOT' $true
   if($null -ne $bootFolder){
    $bootDir=Parse-FATDirectory (Read-FATClusterChain $vol $geo ([int]$bootFolder.start_cluster) 1048576)
    $efiBootLoader=Find-OneFAT $bootDir 'BOOTX64.EFI' $false
   }
  }
  $loaderRecord=$null
  if($null -ne $efiBootLoader){
   $bytes=[long]$efiBootLoader.file_bytes
   if($bytes -le 0 -or $bytes -gt 16777216){throw 'EFI_BOOTLOADER_SIZE_OUTSIDE_BOUNDS'}
   $chain=Read-FATClusterChain $vol $geo ([int]$efiBootLoader.start_cluster) 33554432
   if($chain.Length -lt $bytes){throw 'FAT_CHAIN_TRUNCATED_BOOTLOADER'}
   $bootx64=Take-Bytes $chain 0 ([int]$bytes)
   $loaderRecord=[ordered]@{path='EFI\BOOT\BOOTX64.EFI';file_bytes=$bytes;file_sha256=(Hash-Buffer $bootx64);source_start_cluster=$efiBootLoader.start_cluster;pe=(Inspect-PE $bootx64)}
   Write-Output ('R038_OP27_SOURCE_EFI '+$source.kind+' FAT='+$fatType+' imageBytes='+$vol.Length+' BootX64Bytes='+$bytes+' BootX64SHA='+$loaderRecord.file_sha256+' PEmachine='+$loaderRecord.pe.machine_hex+' CmsDecoded='+$loaderRecord.pe.embedded_signed_cms_decoded)
  }else{
   Write-Output ('R038_OP27_SOURCE_EFI '+$source.kind+' FAT='+$fatType+' imageBytes='+$vol.Length+' BootX64=NOT_FOUND_BY_FAT8DOT3')
  }
  [void]$sourceResults.Add([ordered]@{kind=$source.kind;iso_path=$f.FullName;iso_bytes=$f.Length;efi_image_lba=$imageLba;efi_fat_geometry=$geo;efi_fat_image_bytes=$vol.Length;efi_fat_image_sha256=(Hash-Buffer $vol);fat_root_entry_names=@($rootEntries|Select-Object -First 30 -ExpandProperty name);efi_directory_names=$(if($null -ne $efiDir){@($efiDir|Select-Object -First 30 -ExpandProperty name)}else{@()});efi_boot_directory_names=$(if($null -ne $bootDir){@($bootDir|Select-Object -First 30 -ExpandProperty name)}else{@()});bootx64=$loaderRecord})
 }finally{$file.Dispose()}
}
$comparison=[ordered]@{efi_fat_whole_image_sha_identical=($sourceResults[0].efi_fat_image_sha256 -eq $sourceResults[1].efi_fat_image_sha256);bootx64_both_found=($null -ne $sourceResults[0].bootx64 -and $null -ne $sourceResults[1].bootx64);bootx64_sha_identical=$(if($null -ne $sourceResults[0].bootx64 -and $null -ne $sourceResults[1].bootx64){$sourceResults[0].bootx64.file_sha256 -eq $sourceResults[1].bootx64.file_sha256}else{$null})}
$firmware=[ordered]@{secureboot=[string]$fw.SecureBoot;secureboot_template=$(if($fw.PSObject.Properties.Name -contains 'SecureBootTemplate'){[string]$fw.SecureBootTemplate}else{'PROPERTY_NOT_EXPOSED'});first_boot_type=[string]$fw.BootOrder[0].BootType;dvd_path=$dvd[0].Path;guest_state=[string]$vm.State;guest_generation=$vm.Generation}
$events=[Collections.Generic.List[object]]::new()
foreach($name in @('Microsoft-Windows-Hyper-V-Worker-Admin','Microsoft-Windows-Hyper-V-VMMS-Admin')){
 try{
  $raw=@(Get-WinEvent -FilterHashtable @{LogName=$name;StartTime=[datetime]'2026-11-09T14:30:00'} -MaxEvents 50 -ErrorAction Stop)
  foreach($ev in $raw){
   if($ev.Message -and ($ev.Message.Contains($vm.Name) -or $ev.Message.Contains($vmid))){
    [void]$events.Add([ordered]@{log=$name;utc=$ev.TimeCreated.ToUniversalTime().ToString('o');id=$ev.Id;level=$ev.LevelDisplayName;message=$ev.Message.Substring(0,[Math]::Min(500,$ev.Message.Length))})
   }
  }
 }catch{
  [void]$events.Add([ordered]@{log=$name;status='EVENTS_NOT_ACCESSIBLE_OR_NO_MATCH';error=$_.Exception.Message.Substring(0,[math]::Min(120,$_.Exception.Message.Length))})
 }
}
$record=[ordered]@{schema='BlueLite.R038.EFIFATAndPEReadOnly.v1';utc=[datetime]::UtcNow.ToString('o');status='READONLY_EFI_FAT_PE_CERT_METADATA_RECORDED_SECUREBOOT_CAUSE_UNPROVEN';script_sha256=(Get-FileHash -LiteralPath $PSCommandPath).Hash;prior_catalog_receipt_sha=(Get-FileHash $catalogPath).Hash;sources=@($sourceResults);comparison=$comparison;guest_firmware=$firmware;hyperv_vm_log_events=@($events);all_source_iso_files_opened_read_only=$true;no_binary_extraction=$true;no_guest_or_host_firmware_state_modified=$true;no_VM_power_change=$true;setup_UI='NOT_REACHED_GUEST_UEFI_BOOT_LOADER_FAILED';installed_first_boot='NOT_RUN';repeat_boot='NOT_RUN';free_c=[long](Get-PSDrive C).Free}
$data=[Text.UTF8Encoding]::new($false).GetBytes(($record|ConvertTo-Json -Depth 18)+[Environment]::NewLine)
$handle=[IO.File]::Open($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$handle.Write($data)}finally{$handle.Dispose()}
Write-Output ('R038_OP27_EFI_FAT_PE_READONLY_DONE sourceCount='+$sourceResults.Count+' fatIdentical='+$comparison.efi_fat_whole_image_sha_identical+' bootx64Both='+$comparison.bootx64_both_found+' bootx64ShaIdentical='+$comparison.bootx64_sha_identical+' secureBoot='+$fw.SecureBoot+' receiptSha='+(Get-FileHash $output).Hash+' free='+$record.free_c)
