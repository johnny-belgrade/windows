# BlueLite R028: dependency-aware optional NIC FoD/Sense removal from MOUNTED OFFLINE install image.
# Runs only inside operator-owned stage; never on host C:\Windows, boot.wim or original UUP.
[CmdletBinding()]
param(
 [ValidateSet('Inspect','Execute')][string]$Mode='Inspect',
 [Parameter(Mandatory=$true)][string]$MountPath,
 [Parameter(Mandatory=$true)][string]$ReportPath,
 [switch]$RemoveNetworkDriverFoD,
 [switch]$RemoveSenseClientFoD
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
function RequireBL([bool]$v,[string]$why){if(-not $v){throw ('R028_FOD_HOLD_'+$why)}}
function HashBL([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToUpperInvariant()}
function WriteBL([string]$p,$o) {
 $raw=[Text.UTF8Encoding]::new($false).GetBytes(($o|ConvertTo-Json -Depth 12)+[Environment]::NewLine)
 $f=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$f.Write($raw,0,$raw.Length)}finally{$f.Dispose()}
}
$started=[DateTime]::UtcNow
$mount=[IO.Path]::GetFullPath($MountPath).TrimEnd([char]'\')
$report=[IO.Path]::GetFullPath($ReportPath)
$actions=[Collections.Generic.List[object]]::new()
$holds=[Collections.Generic.List[object]]::new()
$mountPresent=$false
try {
 RequireBL ($mount.StartsWith('C:\work\',[StringComparison]::OrdinalIgnoreCase) -and $mount -match '(?i)\\BlueLite_Stage_v11_3_[^\\]+\\') 'NOT_OWNED_STAGE_MOUNT'
 RequireBL (Test-Path -LiteralPath (Join-Path $mount 'Windows\System32\Config\SOFTWARE') -PathType Leaf) 'NOT_MOUNTED_OFFLINE_WINDOWS'
 RequireBL ($report.StartsWith('C:\work\',[StringComparison]::OrdinalIgnoreCase) -and $report.Contains('\BlueLite_Logs\')) 'REPORT_NOT_LOCAL_UUP_LOGS'
 RequireBL (-not (Test-Path -LiteralPath $report)) 'REPORT_ALREADY_EXISTS'
 RequireBL ($mount -notmatch '\s' -and $report -notmatch '\s') 'SPACES_NOT_SUPPORTED'
 $caps=@(Get-WindowsCapability -Path $mount -ErrorAction Stop)
 $packages=@(Get-WindowsPackage -Path $mount -ErrorAction Stop)
 $apps=@(Get-AppxProvisionedPackage -Path $mount -ErrorAction Stop)
 $target=[Collections.Generic.List[object]]::new()
 foreach($cap in $caps){
  if([string]$cap.State -ne 'Installed'){continue}
  $n=[string]$cap.Name
  $kind=''
  if($RemoveNetworkDriverFoD -and $n -match '^Microsoft\.Windows\.(Wifi|Ethernet)\.Client\.[\w.~-]+'){$kind='NETWORK_HARDWARE_DRIVER_FOD'}
  elseif($RemoveSenseClientFoD -and $n -match '^Microsoft\.Windows\.Sense\.Client~'){$kind='MDE_SENSE_CLIENT_FOD'}
  if($kind){$target.Add([pscustomobject]@{name=$n;kind=$kind})}
 }
 $baseline=[ordered]@{
  installed_capabilities=@($caps|Where-Object {[string]$_.State -eq 'Installed'}).Count
  installed_driver_fod=@($caps|Where-Object {[string]$_.State -eq 'Installed' -and $_.Name -match '^Microsoft\.Windows\.(Wifi|Ethernet)\.Client\.'}).Count
  installed_sense_fod=@($caps|Where-Object {[string]$_.State -eq 'Installed' -and $_.Name -match '^Microsoft\.Windows\.Sense\.Client~'}).Count
  installed_fod_packages=@($packages|Where-Object {[string]$_.PackageState -eq 'Installed' -and $_.PackageName -match '(?i)FOD-Package|FoDMetadata'}).Count
  appinstaller_provisioned=@($apps|Where-Object {$_.DisplayName -eq 'Microsoft.DesktopAppInstaller'}).Count
  language_basic_en_us=@($caps|Where-Object {$_.Name -like 'Language.Basic~~~en-US~*' -and [string]$_.State -eq 'Installed'}).Count
 }
 if($Mode -eq 'Execute') {
  RequireBL ($RemoveNetworkDriverFoD -or $RemoveSenseClientFoD) 'NO_EXPLICIT_REMOVAL_FLAGS'
  foreach($c in @($target)){
   $answer=@(& dism.exe /English "/Image:$mount" /Remove-Capability "/CapabilityName:$($c.name)" 2>&1 | ForEach-Object {$_.ToString()})
   $exit=[int]$LASTEXITCODE
   $now=@(Get-WindowsCapability -Path $mount -ErrorAction Stop | Where-Object {$_.Name -eq $c.name})
   $remaining=($now.Count -eq 1 -and [string]$now[0].State -eq 'Installed')
   $receipt=[ordered]@{utc=[DateTime]::UtcNow.ToString('o');name=$c.name;kind=$c.kind;dism_exit=$exit;still_installed=$remaining;output_tail=($answer|Select-Object -Last 8)}
   if($exit -eq 0 -and -not $remaining){$actions.Add($receipt)}
   else{$holds.Add($receipt)}
  }
 }
 $afterCaps=@(Get-WindowsCapability -Path $mount -ErrorAction Stop)
 $afterPkgs=@(Get-WindowsPackage -Path $mount -ErrorAction Stop)
 $afterApps=@(Get-AppxProvisionedPackage -Path $mount -ErrorAction Stop)
 $final=[ordered]@{
  schema='BlueLite.R028.InstalledFoD.v1'
  utc=$started.ToString('o')
  mode=$Mode
  status=if($Mode -eq 'Inspect'){'INVENTORY_ONLY'}elseif($holds.Count){'PARTIAL_DEPENDENCY_HOLD'}else{'SELECTED_FOD_REMOVED'}
  mount=$mount
  baseline=$baseline
  requested=@{network_fod=[bool]$RemoveNetworkDriverFoD;sense_fod=[bool]$RemoveSenseClientFoD}
  targets=@($target.ToArray())
  successful=@($actions.ToArray())
  holds=@($holds.ToArray())
  final=[ordered]@{
   installed_driver_fod=@($afterCaps|Where-Object {[string]$_.State -eq 'Installed' -and $_.Name -match '^Microsoft\.Windows\.(Wifi|Ethernet)\.Client\.'}).Count
   installed_sense_fod=@($afterCaps|Where-Object {[string]$_.State -eq 'Installed' -and $_.Name -match '^Microsoft\.Windows\.Sense\.Client~'}).Count
   installed_fod_packages=@($afterPkgs|Where-Object {[string]$_.PackageState -eq 'Installed' -and $_.PackageName -match '(?i)FOD-Package|FoDMetadata'}).Count
   appinstaller_provisioned=@($afterApps|Where-Object {$_.DisplayName -eq 'Microsoft.DesktopAppInstaller'}).Count
   language_basic_en_us=@($afterCaps|Where-Object {$_.Name -like 'Language.Basic~~~en-US~*' -and [string]$_.State -eq 'Installed'}).Count
  }
  protected_policy='KEEP WU/CBS/DEFENDER/SECURITY_UI/BASIC_ENUS/NETWORK_STACK; remove only optional NIC driver capability and optional Sense EDR by explicit flags. Universal NIC OOBE requires driver injection where absent.'
  release_certified=$false
  one_next='REVIEW_DEPENDENCIES_AND_WIM_ISO_OUTPUT'
 }
 WriteBL $report $final
 Write-Host ('R028_FOD_'+$final.status+' BEFORE_DRIVER='+$baseline.installed_driver_fod+' AFTER_DRIVER='+$final.final.installed_driver_fod+' HOLDS='+$holds.Count)
 exit 0
}catch{
 Write-Host ('R028_FOD_HOLD '+$_.Exception.Message)
 try{if(-not(Test-Path -LiteralPath $report)){WriteBL $report ([ordered]@{status='HOLD';reason=$_.Exception.Message;utc=[DateTime]::UtcNow.ToString('o');no_host_mutation=$true})}}catch{}
 exit 17
}
