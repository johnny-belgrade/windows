# R002 universal Stage1 source + renewable transport gate; DEVELOPMENT / READ-ONLY.
# No get.php invocation, no aria2, no converter, no DISM/WIM/registry/network.
[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$ProfilePath,
 [ValidateSet('Audit','Plan')][string]$Mode='Audit',
 [string]$RecipeRegistryPath='C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package\01_Inputs\R002_RecipeRegistry_Snapshot.json'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Gate([bool]$Ok,[string]$Code) { if(-not $Ok){throw ('R002_FAIL_CLOSED='+$Code)} }
function Sha([string]$Path) {
 Gate (Test-Path -LiteralPath $Path -PathType Leaf) 'REQUIRED_FILE_MISSING'
 return (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()
}
function ParamValue([uri]$Url,[string]$Name) {
 foreach($segment in $Url.Query.TrimStart('?').Split('&')){
  $pair=$segment.Split('=',2)
  if($pair.Count -eq 2 -and $pair[0] -ieq $Name){return [uri]::UnescapeDataString($pair[1])}
 }
 return ''
}
function Test-FrozenEndpoint([uri]$Url,[string]$UUID,[string]$Pack,[string]$Edition){
 Gate ($Url.Scheme -ceq 'https' -and $Url.Host -ceq 'uupdump.net' -and $Url.AbsolutePath -ceq '/get.php') 'FROZEN_ENDPOINT_HOST_OR_PATH'
 Gate ((ParamValue $Url 'id') -ceq $UUID -and (ParamValue $Url 'pack') -ceq $Pack -and (ParamValue $Url 'edition') -ceq $Edition -and (ParamValue $Url 'aria2') -ceq '2') 'FROZEN_ENDPOINT_IDENTITY'
}
Gate ($PSVersionTable.PSVersion.Major -ge 7) 'PS7_REQUIRED'
$p=Get-Content -LiteralPath $ProfilePath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
Gate ($p.schema -ceq 'BlueLite.R002.Stage1.StaticProfile.v1' -and $p.runtime_allowed -eq $false) 'PROFILE_SCHEMA_OR_RUNTIME_FLAG'
Gate ($p.source.build -match '^26300\.[0-9]+$' -and $p.source.arch -ceq 'amd64' -and $p.source.language -ceq 'en-us' -and $p.source.edition -ceq 'professional') 'UNREVIEWED_SOURCE_CLASS'
Gate ($p.source.uuid -match '^[0-9a-f-]{36}$') 'UUID_BAD_FORMAT'
Gate ((Sha $p.source.zip_path) -ceq $p.source.zip_sha256) 'ORIGINAL_ZIP_SHA_DRIFT'
Gate ((Sha $p.source.launcher_path) -ceq $p.source.launcher_sha256) 'ORIGINAL_LAUNCHER_SHA_DRIFT'
Gate ((Sha $p.queue.module_path) -ceq $p.queue.module_sha256) 'D4_MODULE_SHA_DRIFT'
Gate ($p.staging.windows_queue -ceq 'PRESERVE_FULL_RECONSTRUCTION') 'WINDOWS_INPUT_PRUNING_PROHIBITED'
Gate ($p.staging.winre -ceq 'PRESERVE_INSTALLED_WINRE') 'WINRE_RECOVERY_CHANGE_REQUIRES_SEPARATE_APPROVAL'
Gate ($p.staging.apps_closure -ceq 'REUSE_D5_D6_G4_MANIFEST_VERIFIED') 'APPS_DEPENDENCY_CLOSURE_NOT_PINNED'
Gate ($p.staging.netfx3 -ceq 'OFF') 'NETFX3_SOURCE_POLICY_UNREVIEWED'
$required=@('Microsoft.SecHealthUI','Microsoft.DesktopAppInstaller','Microsoft.WindowsCalculator','Microsoft.WindowsNotepad','Microsoft.Windows.Photos')
$actual=@($p.staging.required_apps)
Gate ($actual.Count -eq 5) 'STAGING_FIVE_CARDINALITY'
foreach($name in $required){Gate ($name -cin $actual) ('MISSING_REQUIRED_STAGING_APP_'+$name)}
Gate (@($actual | Select-Object -Unique).Count -eq 5) 'STAGING_DUPLICATE'
$launcher=[IO.File]::ReadAllText($p.source.launcher_path)
$urls=@([regex]::Matches($launcher,'https://uupdump\.net/get\.php\?[^"\s]+') | ForEach-Object Value | Select-Object -Unique)
$win=@($urls | Where-Object { (ParamValue ([uri]$_) 'edition') -ceq $p.source.edition })
Gate ($win.Count -eq 1) 'ORIGINAL_WINDOWS_ENDPOINT_COUNT'
Test-FrozenEndpoint ([uri]$win[0]) $p.source.uuid $p.source.language $p.source.edition
Test-FrozenEndpoint ([uri]("https://uupdump.net/get.php?id="+$p.source.uuid+"&pack=neutral&edition=app&aria2=2")) $p.source.uuid 'neutral' 'app'
Import-Module -Name $p.queue.module_path -Force -ErrorAction Stop
$w=Get-BlueLiteQueueIdentity -Path $p.queue.frozen_windows
$a=Get-BlueLiteQueueIdentity -Path $p.queue.frozen_apps
Gate ($w.SHA256 -ceq $p.queue.original_windows_identity_sha256 -and $w.Count -eq [int]$p.queue.expected_windows_count) 'FROZEN_WINDOWS_IDENTITY_OR_COUNT'
Gate ($a.SHA256 -ceq $p.queue.original_apps_identity_sha256 -and $a.Count -eq [int]$p.queue.expected_apps_count) 'FROZEN_APPS_IDENTITY_OR_COUNT'
$wrenew=Assert-BlueLiteQueueSamePayload -Baseline $p.queue.frozen_windows -Candidate $p.queue.renewed_windows
$arenew=Assert-BlueLiteQueueSamePayload -Baseline $p.queue.frozen_apps -Candidate $p.queue.renewed_apps
Gate ($wrenew.Count -eq $w.Count -and $arenew.Count -eq $a.Count) 'RENEWED_QUEUE_COUNTS'
Write-Output ('R002_SOURCE_TRANSPORT_STATIC=PASS;BUILD='+$p.source.build+';WINDOWS='+$w.Count+';APPS='+$a.Count+';NO_NETWORK=TRUE')
if($Mode -eq 'Plan'){
 Gate (Test-Path -LiteralPath $RecipeRegistryPath -PathType Leaf) 'REGISTRY_SNAPSHOT_MISSING'
 $reg=Get-Content -LiteralPath $RecipeRegistryPath -Raw | ConvertFrom-Json
 Gate (@($reg.recipes).Count -ge 7) 'REGISTRY_SNAPSHOT_TOO_SMALL'
 Gate (@($reg.recipes | Where-Object { $_.runtime_execution_allowed -ne $false }).Count -eq 0) 'REGISTRY_RUNTIME_FLAG_NOT_FALSE'
 foreach($step in @($p.pipeline)){Write-Output ('PLAN_ONLY_STEP='+$step)}
 Write-Output ('RECIPE_PLAN=ALL_'+@($reg.recipes).Count+'_REVIEW_REQUIRED_NO_MUTATIONS')
 Write-Output 'HANDOFF=NTLITE_ONLY_FOR_PROVEN_COMPONENT_ENGINE_RESIDUE'
}
Write-Output 'R002_EXECUTION_AUTHORIZATION=FALSE'
