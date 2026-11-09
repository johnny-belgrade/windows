# BlueLite R038_08_ReadOnlyISOBootChain.ps1 - ISO9660 + El Torito catalog forensic using read-only FileStream; ZERO source ISO writes
[CmdletBinding()]
param([string]$Root='C:\work\_UUP\R038_IsolatedBootBenchmark_26300')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($Root -ne 'C:\work\_UUP\R038_IsolatedBootBenchmark_26300'){throw 'OWNED_ROOT_MISMATCH'}
$logs=Join-Path $Root 'BlueLite_Logs'
$prior=Join-Path $logs 'R038_07_GuestVideoCapture_Result.json'
$output=Join-Path $logs 'R038_08_ISOElToritoReadOnly_Result.json'
if(Test-Path $output){throw 'ISO_CATALOG_RECEIPT_ALREADY_EXISTS'}
if((Get-FileHash $prior).Hash -ne '9B828CC3773C95E23DA7BAE8D84B45A3610E4EDCA8138D04E8599F08B915D6A2'){throw 'SCREEN_RECEIPT_SHA_DRIFT'}
$baselinePath='C:\work\_UUP\R035_Universal_PREMAX_26300\BlueLite_Logs\BlueLite_R029_RESULT.json'
$baseline=Get-Content -LiteralPath $baselinePath -Raw|ConvertFrom-Json
$rootGolden='C:\work\_UUP\UUP-history\09_ProtectedGolden\26300.9818-UUP-MAX_PRE_26300_v4'
$goldISOs=@(Get-ChildItem -LiteralPath $rootGolden -File -Filter '*.iso' -ErrorAction Stop)
if($goldISOs.Count -ne 1){throw 'GOLDEN_ISO_NOT_UNIQUE'}
$sources=@(
 [pscustomobject]@{kind='R035_LATEST_PREMAX_26300_9818';path=[string]$baseline.iso;expectedLength=[long]6749851648;expectedFullSHAFromR038='54719935DBB05261D562DE964635E934E1D066975E1AAB8334D67CF6F7EE2CEC'},
 [pscustomobject]@{kind='R004_PROTECTED_GOLDEN_26300_9818';path=$goldISOs[0].FullName;expectedLength=[long]6822354944;expectedFullSHAFromR038=$null}
)
if(@(Get-WindowsImage -Mounted -ErrorAction Stop).Count){throw 'HOST_IMAGE_MOUNT_NOT_ZERO'}
$vm=Get-VM -Id 'c7536cc4-68f5-473a-9818-4053ba8794b2' -ErrorAction Stop
if($vm.Name -ne 'BlueLite-R038-UEFI-Baseline' -or $vm.Generation -ne 2){throw 'UNEXPECTED_VM'}
$dvd=Get-VMDvdDrive -VMName $vm.Name -ErrorAction Stop
if($dvd.Path -ne $baseline.iso){throw 'DVD_WAS_CHANGED'}
$fw=Get-VMFirmware -VMName $vm.Name -ErrorAction Stop
if([string]$fw.SecureBoot -ne 'On' -or $fw.BootOrder[0].Device.Path -ne $baseline.iso){throw 'UEFI_CONFIG_CHANGED'}
function Read-Sector([IO.FileStream]$file,[long]$lba) {
 if($lba -lt 0 -or (($lba+1)*2048) -gt $file.Length){throw ('ELTORITO_LBA_OUT_OF_RANGE_'+$lba)}
 $buffer=[byte[]]::new(2048)
 [void]$file.Seek($lba*2048,[IO.SeekOrigin]::Begin)
 $got=$file.Read($buffer,0,2048)
 if($got -ne 2048){throw 'SHORT_ISO_SECTOR_READ'}
 return ,$buffer
}
function Hash-Bytes([byte[]]$data) {
 return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($data))
}
function Read-BootEntry([byte[]]$catalog,[int]$offset,[int]$platform,[string]$source,[IO.FileStream]$file) {
 if($offset -lt 0 -or $offset+31 -ge $catalog.Length){throw 'BOOT_ENTRY_OFFSET'}
 $flag=[int]$catalog[$offset]
 $media=[int]($catalog[$offset+1] -band 15)
 $sectors=[int][BitConverter]::ToUInt16($catalog,$offset+6)
 $lba=[long][BitConverter]::ToUInt32($catalog,$offset+8)
 $validRange=($lba -gt 0 -and ($lba*2048+512) -le $file.Length)
 $first512hex=$null;$bootSig=$false;$fatMarker=$null;$sectorSHA=$null
 if($validRange){
  $sect=Read-Sector $file $lba
  $sectorSHA=Hash-Bytes $sect
  $first512hex=[Convert]::ToHexString($sect[0..15])
  $bootSig=($sect[510] -eq 0x55 -and $sect[511] -eq 0xAA)
  $fatMarker=[Text.Encoding]::ASCII.GetString($sect,54,8).Trim([char]0,' ')
 }
 return [ordered]@{iso_kind=$source;entry_offset=$offset;platform_id=('0x{0:X2}' -f $platform);boot_indicator=('0x{0:X2}' -f $flag);bootable=($flag -eq 0x88);media_type=$media;no_emulation=($media -eq 0);load_segment=[int][BitConverter]::ToUInt16($catalog,$offset+2);sector_count_512B=$sectors;image_lba_2048B=$lba;image_offset_bytes=($lba*2048);image_lba_valid=$validRange;image_first_sector_sha256=$sectorSHA;image_first16_hex=$first512hex;image_ends_55AA=$bootSig;image_fat_marker=$fatMarker}
}
$results=[Collections.Generic.List[object]]::new()
foreach($item in $sources) {
 $i=Get-Item -LiteralPath $item.path -ErrorAction Stop
 if($i.Length -ne $item.expectedLength){throw ('ISO_SOURCE_BYTES_CHANGED_'+$item.kind)}
 if(($i.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw ('SOURCE_IS_REPARSE_'+$item.kind)}
 $fs=[IO.File]::Open($i.FullName,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
 try {
  $descs=[Collections.Generic.List[object]]::new();$boot=null;$primary=$null
  for($lba=16;$lba -lt 96;$lba++){
   $sector=Read-Sector $fs $lba
   $magic=[Text.Encoding]::ASCII.GetString($sector,1,5)
   if($magic -ne 'CD001'){break}
   $type=[int]$sector[0]
   [void]$descs.Add([ordered]@{lba=$lba;type=$type;magic=$magic})
   if($type -eq 0 -and ([Text.Encoding]::ASCII.GetString($sector,7,32)).StartsWith('EL TORITO SPECIFICATION')){$boot=$sector}
   if($type -eq 1){$primary=$sector}
   if($type -eq 255){break}
  }
  $entries=[Collections.Generic.List[object]]::new()
  $catalogLba=$null;$catalogSHA=$null;$validation=$false;$bios=0;$efi=0;$catalogMarker=$null
  if($null -ne $boot){
   $catalogLba=[long][BitConverter]::ToUInt32($boot,71)
   $catalog=Read-Sector $fs $catalogLba
   $catalogSHA=Hash-Bytes $catalog
   $sum=[long]0
   for($k=0;$k -lt 32;$k+=2){$sum += [BitConverter]::ToUInt16($catalog,$k)}
   $validation=($catalog[0] -eq 1 -and $catalog[30] -eq 0x55 -and $catalog[31] -eq 0xAA -and (($sum -band 65535) -eq 0))
   $catalogMarker=([Text.Encoding]::ASCII.GetString($catalog,4,24)).Trim([char]0,' ')
   if($validation) {
    [void]$entries.Add((Read-BootEntry $catalog 32 ([int]$catalog[1]) $item.kind $fs))
    $offset=64
    while($offset+31 -lt $catalog.Length){
     $header=[int]$catalog[$offset]
     if($header -ne 0x90 -and $header -ne 0x91){break}
     $platform=[int]$catalog[$offset+1]
     $count=[int][BitConverter]::ToUInt16($catalog,$offset+2)
     if($count -le 0 -or $count -gt 20){throw 'ELTORITO_SECTION_COUNT_INVALID'}
     for($z=0;$z -lt $count;$z++){
      $entryOffset=$offset+32+$z*32
      [void]$entries.Add((Read-BootEntry $catalog $entryOffset $platform $item.kind $fs))
     }
     $offset += 32*(1+$count)
     if($header -eq 0x91){break}
    }
   }
  }
  $efi=@($entries|Where-Object {$_.platform_id -eq '0xEF' -and $_.bootable -and $_.no_emulation -and $_.image_lba_valid})
  $bios=@($entries|Where-Object {$_.platform_id -eq '0x00' -and $_.bootable -and $_.no_emulation -and $_.image_lba_valid})
  $isoResult=[ordered]@{kind=$item.kind;source_path=$i.FullName;source_bytes=$i.Length;source_full_sha_previously_proven=$item.expectedFullSHAFromR038;volume_id=$(if($null -ne $primary){[Text.Encoding]::ASCII.GetString($primary,40,32).Trim([char]0,' ')}else{$null});descriptor_records=@($descs);el_torito_boot_record_present=($null -ne $boot);boot_catalog_lba=$catalogLba;boot_catalog_sector_sha256=$catalogSHA;boot_catalog_validation_good=$validation;catalog_manufacturer=$catalogMarker;boot_entries=@($entries);valid_UEFI_boot_entry_count=$efi.Count;valid_BIOS_boot_entry_count=$bios.Count;uefi_catalog_entry_detected=($efi.Count -gt 0);bios_catalog_entry_detected=($bios.Count -gt 0)}
  [void]$results.Add($isoResult)
  Write-Output ('R038_ISO_CATALOG '+$item.kind+' catalogPresent='+$isoResult.el_torito_boot_record_present+' validation='+$validation+' bios='+$bios.Count+' efi='+$efi.Count+' catalogLba='+$catalogLba)
 }finally{$fs.Dispose()}
}
$state='READONLY_TWO_ISO_CATALOGS_RECORDED_UEFI_BOOT_CAUSE_PENDING'
$record=[ordered]@{schema='BlueLite.R038.ISOBootCatalogReadOnly.v1';utc=[datetime]::UtcNow.ToString('o');status=$state;script_sha256=(Get-FileHash $PSCommandPath).Hash;prior_screenshot_receipt_sha=(Get-FileHash $prior).Hash;source_iso_original_unchanged=$true;guest_vm_id=$vm.VMId.ToString();guest_state=[string]$vm.State;guest_secureboot=[string]$fw.SecureBoot;guest_firmware_dvd_first=$true;host_wim_mount_count=0;media=@($results);boot_setup_ui='NOT_REACHED_UEFI_SCREEN_PRESERVED';first_installed_boot='NOT_RUN';repeat_boot='NOT_RUN';no_image_or_guest_mutation=$true}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($record|ConvertTo-Json -Depth 12)+[Environment]::NewLine)
$f=[IO.File]::Open($output,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$f.Write($bytes)}finally{$f.Dispose()}
Write-Output ('R038_OP24_ISO_ELTORITO_READONLY_PASS receiptSha='+(Get-FileHash $output).Hash+' sourceCount='+$results.Count+' status='+$state+' noVMchange=true')
