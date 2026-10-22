# R002 MAX_PRE: PURE OFFLINE DECISION PLANNER; development draft, NO WIM OPEN/MOUNT/CHANGE.
# A synthetic fixture PASS certifies contract guards only, never real target topology.
[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$ImageContractPath,
 [Parameter(Mandatory)][string]$RecipeSnapshotPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Gate([bool]$Ok,[string]$Why) {if(-not $Ok){throw ('R002_PLAN_FAIL_CLOSED='+$Why)}}
$c=Get-Content -LiteralPath $ImageContractPath -Raw -ErrorAction Stop | ConvertFrom-Json
$r=Get-Content -LiteralPath $RecipeSnapshotPath -Raw -ErrorAction Stop | ConvertFrom-Json
Gate ($c.schema -ceq 'BlueLite.R002.ImageContract.v1') 'IMAGE_CONTRACT_SCHEMA'
Gate ($r.schema -ceq 'BlueLite.R002.ReadOnlyRecipeInventory.v1') 'REGISTRY_SCHEMA'
Gate ($c.source_family -ceq 'Germanium' -and $c.build -match '^26300\.[0-9]+$' -and $c.index -ge 1) 'BUILD_INDEX_LINEAGE'
Gate ($c.original_wim_sha256 -cmatch '^[0-9A-F]{64}$') 'FROZEN_WIM_SHA_PIN_MISSING'
Gate ($c.image_original -match '^C:\\work\\' -and $c.image_working -match '^C:\\work\\') 'WIM_PATH_OUTSIDE_OWNED_SCOPE'
$src=[IO.Path]::GetFullPath([string]$c.image_original).TrimEnd('\')
$dst=[IO.Path]::GetFullPath([string]$c.image_working).TrimEnd('\')
Gate (-not [string]::Equals($src,$dst,[StringComparison]::OrdinalIgnoreCase)) 'IMMUTABLE_AND_WORKING_WIM_COLLIDE'
Gate (-not $dst.StartsWith((Split-Path -Path $src -Parent)+'\', [StringComparison]::OrdinalIgnoreCase)) 'OWNERSHIP_REQUIRES_DISJOINT_WORKSPACE'
Gate ($c.operator_authorized_mutation -eq $false -and $c.converter_runtime_authorized -eq $false) 'NO_RUNTIME_ALLOWED_IN_THIS_DRAFT'
Gate ($c.source_topology_verified -eq $false) 'UNEXPECTED_TOPOLOGY_CERTIFICATION'
Gate (@($r.recipes).Count -ge 7) 'RECIPE_INVENTORY_INCOMPLETE'
Gate (@($r.recipes | Where-Object { $_.runtime_execution_allowed -ne $false }).Count -eq 0) 'RECIPE_RUNTIME_FLAG_TRUE'
Gate ($c.staging_five_verified -eq $false -and $c.protected_floor_verified -eq $false) 'NO_PRETEND_REAL_IMAGE_CERTIFICATION'
foreach($recipe in @($r.recipes)){
 $target=[string]$recipe.recipe_id
 Gate (-not [string]::IsNullOrWhiteSpace($target)) 'EMPTY_RECIPE_ID'
 $decision=if($recipe.disposition -ceq 'COMPONENT_ENGINE_HANDOFF'){'HANDOFF_PENDING_CURRENT_TARGET_TOPOLOGY'}else{'HOLD_PENDING_CURRENT_TARGET_TOPOLOGY'}
 Write-Output ('R002_MAXPRE_PLAN_ONLY;RECIPE='+$target+';DECISION='+$decision)
}
Write-Output 'R002_WIM_READ=FALSE;WIM_MUTATION=FALSE;NATIVE_POSTSTATE=NOT_RUN'
Write-Output 'R002_MAXPRE_DISPATCH=STATIC_PLAN_ONLY'
