# BlueLite R038_00_PreflightReadOnly.ps1 — exact benchmark fixture / immutable full source
# Only owned new R038 workspace writes after validating all source SHA and no mounts.
[CmdletBinding()]
param([string]$Root = 'C:\work\_UUP\R038_IsolatedBootBenchmark_26300')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($Root -ne 'C:\work\_UUP\R038_IsolatedBootBenchmark_26300'){throw 'UNEXPECTED_ROOT'}
if(Test-Path -LiteralPath $Root){throw 'R038_WORKSPACE_ALREADY_EXISTS_STOP'}
$parent='C:\work\_UUP'
if(([IO.File]::GetAttributes($parent) -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'REPARSE_PARENT'}
$wimLog='C:\work\_UUP\R035_Universal_PREMAX_26300\BlueLite_Logs\BlueLite_R029_RESULT.json'
if(-not (Test-Path -LiteralPath $wimLog -PathType Leaf)){throw 'NO_R035_NATIVE_RESULT'}
$r=Get-Content -LiteralPath $wimLog -Raw |ConvertFrom-Json
$variants='C:\work\_UUP\temp\R036_BootSpeed_Variants_20261109'
$expected=@(
 [pscustomobject]@{kind='R035_ISO';path=[string]$r.iso;bytes=[long]6749851648;sha='54719935DBB05261D562DE964635E934E1D066975E1AAB8334D67CF6F7EE2CEC'},
 [pscustomobject]@{kind='R035_INSTALL_WIM';path=[string]$r.install_wim;bytes=[long]5663629505;sha='1441B1900374A503DB9045236AEDF1C9604E56A78AA5F9CDCF394DEDC383AD67'},
 [pscustomobject]@{kind='R035_SETUP_BOOT_WIM';path=[string]$r.boot_wim;bytes=[long]824384151;sha='F659254B86D7478B02A5D02204530CDA8805FE8EA58A4DFE69F69BB4C0144A26'},
 [pscustomobject]@{kind='R036_SETUPONLY_LZX';path=(Join-Path $variants 'SetupOnly_LZX.wim');bytes=[long]810820600;sha='3B564C831A0CF646F55B56572C438CD8B42AD381673BF4D458B36059301BF0FD'},
 [pscustomobject]@{kind='R036_SETUPONLY_XPRESS';path=(Join-Path $variants 'SetupOnly_XPRESS.wim');bytes=[long]865395146;sha='889113125DA22A7498EFC8A3C855AAE090530F2043E56C2DB7573972ED998ABF'},
 [pscustomobject]@{kind='R036_DUAL_XPRESS';path=(Join-Path $variants 'Dual_XPRESS.wim');bytes=[long]868986529;sha='A21098E7B8A6E563219B9948526D84A7923A3D3A3777C69D776E4C8B04069C44'}
)
$mounts=@(Get-WindowsImage -Mounted -ErrorAction Stop)
if($mounts.Count -ne 0){throw 'MOUNTED_IMAGES_PRESENT'}
$active=@(Get-Process -Name dism,dismhost,aria2c,NTLite,VirtualBoxVM,vmware-vmx -ErrorAction SilentlyContinue)
if($active.Count){throw 'MEDIA_MUTATION_PROCESS_PRESENT'}
$free=[long](Get-PSDrive C).Free
if($free -lt 80000000000){throw 'INSUFFICIENT_FREE_SPACE_BELOW_80GB'}
$cmds=@('Get-VM','Get-VMHost','Get-VMSwitch','New-VM','Start-VM','Checkpoint-VM','Get-VMFirmware','New-VHD')
foreach($name in $cmds){if(-not(Get-Command $name -ErrorAction SilentlyContinue)){throw ('HYPERV_CMDLET_MISSING_'+$name)}}
$hostInfo=Get-VMHost -ErrorAction Stop
$prior=@(Get-VM -ErrorAction Stop)
$switches=@(Get-VMSwitch -ErrorAction Stop)
if($prior|Where-Object Name -Like 'BlueLite-R038-*'){throw 'R038_VM_PREEXISTS_STOP'}
if(-not($switches|Where-Object Name -eq 'Default Switch')){throw 'DEFAULT_SWITCH_UNAVAILABLE'}
$verified=[Collections.Generic.List[object]]::new()
foreach($item in $expected){
 $f=Get-Item -LiteralPath $item.path -ErrorAction Stop
 if($f.Length -ne $item.bytes){throw ('FILE_LENGTH_DRIFT_'+$item.kind)}
 if(($f.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw ('REPARSE_MEDIA_'+$item.kind)}
 $sha=(Get-FileHash -LiteralPath $item.path -Algorithm SHA256).Hash
 if($sha -ne $item.sha){throw ('FILE_SHA_CHANGED_'+$item.kind)}
 [void]$verified.Add([ordered]@{kind=$item.kind;path=$item.path;bytes=$f.Length;sha256=$sha})
 Write-Output ('R038_PREFLIGHT_SOURCE_SHA_PASS '+$item.kind+' '+$f.Length)
}
[IO.Directory]::CreateDirectory($Root)|Out-Null
$logs=Join-Path $Root 'BlueLite_Logs'
[IO.Directory]::CreateDirectory($logs)|Out-Null
$receipt=Join-Path $logs 'R038_00_PreflightReadOnly_Result.json'
$data=[ordered]@{schema='BlueLite.R038.Preflight.v1';timestamp_utc=[datetime]::UtcNow.ToString('o');status='ISOLATED_HOST_AND_SIX_SOURCE_SHA_PASS_VM_NOT_CREATED';workroot=$Root;script_sha256=(Get-FileHash -LiteralPath $PSCommandPath).Hash;media=@($verified);free_bytes_at_check=$free;host=$env:COMPUTERNAME;hyperv_available=$true;prior_vm_count=$prior.Count;default_switch_available=$true;vm_created=$false;wim_mount_count=0;active_media_process_count=0}
$json=[Text.UTF8Encoding]::new($false).GetBytes(($data|ConvertTo-Json -Depth 9)+[Environment]::NewLine)
$stream=[IO.File]::Open($receipt,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$stream.Write($json)}finally{$stream.Dispose()}
Write-Output ('R038_00_PREFLIGHT_PASS source_count='+$verified.Count+' receiptSHA='+(Get-FileHash $receipt).Hash+' freeB='+$free)
