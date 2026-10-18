& {
 $ErrorActionPreference='Stop'
 Set-StrictMode -Version Latest
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_PS7_REQUIRED'}
 $principal=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'BL_ADMIN_REQUIRED'}
 $scripts='C:\work\scripts'
 $logs='C:\work\logs'
 if(-not(Test-Path -LiteralPath $scripts -PathType Container) -or
    -not(Test-Path -LiteralPath $logs -PathType Container)){throw 'BL_WORKSPACE_ROOTS_MISSING'}
 $oldReport='C:\work\logs\BlueLite_MAXPRE_SourceBoundPlan_26300.9711.txt'
 $oldReportHash='B33ECB86277057E30450DD66D7EB3A3066E4E29B9FA990DE580E0D3BA3FD451E'
 if((Get-Item -LiteralPath $oldReport -ErrorAction Stop).Length -ne 683 -or
    (Get-FileHash -LiteralPath $oldReport -Algorithm SHA256).Hash -cne $oldReportHash){
  throw 'BL_ORIGINAL_HOLD_REPORT_PIN_DRIFT'
 }
 $oldCore=Join-Path $scripts 'BlueLite.MaxPre.Core.psm1'
 $oldCoreSHA='821E9EEC836C4DA73CEA7B97B04C6806FA0084A7C4AB504592709CD7CA869403'
 if((Get-FileHash -LiteralPath $oldCore -Algorithm SHA256).Hash -cne $oldCoreSHA){throw 'BL_ORIGINAL_CORE_PIN_DRIFT'}
 $core=Join-Path $scripts 'BlueLite.MaxPre.Core.R1.psm1'
 $controller=Join-Path $scripts 'BlueLite.MaxPre.SourceBoundPlan.R1.ps1'
 $registry=Join-Path $scripts 'BlueLite_RecipeRegistry_r12.json'
 $registrySHA='6DE22CCAFF6A202A4FB79BFF745EEE6CB33E4C80EDFF57F076E07574336CDFDB'
 if((Get-FileHash -LiteralPath $registry -Algorithm SHA256).Hash -cne $registrySHA){throw 'BL_REGISTRY_PIN_DRIFT'}
 $sources=@(
  @{Path=$core;Hash='609C8FD727E553249640B68E30CD6B7BF740C7CE26372276A2DE75405D9EA404';Url='https://raw.githubusercontent.com/johnny-belgrade/windows/38102914df23a33a24dd0be0b89185e2e8f211f8/production/engine/BlueLite.MaxPre.Core.psm1'},
  @{Path=$controller;Hash='FD4A27AE66BF69ED5F0DABD3D730D4C3A38C96FD3DF581C8776A287E855A4881';Url='https://raw.githubusercontent.com/johnny-belgrade/windows/9c86a3c8f855ff51065b8c27390f99920724c14a/production/controller/BlueLite.MaxPre.SourceBoundPlan.R1.ps1'}
 )
 foreach($entry in $sources){
  if(Test-Path -LiteralPath $entry.Path){throw ('BL_R1_SOURCE_EXISTS_NO_OVERWRITE='+$entry.Path)}
  Invoke-WebRequest -Uri $entry.Url -OutFile $entry.Path -ErrorAction Stop
  $hash=(Get-FileHash -LiteralPath $entry.Path -Algorithm SHA256).Hash
  if($hash -cne $entry.Hash){
   Remove-Item -LiteralPath $entry.Path -Force
   throw ('BL_R1_SOURCE_SHA_MISMATCH='+$entry.Path+';'+$hash)
  }
  $tokens=$null;$errorsFound=$null
  [void][System.Management.Automation.Language.Parser]::ParseFile($entry.Path,[ref]$tokens,[ref]$errorsFound)
  if(@($errorsFound).Count -ne 0){
   $errorsFound|ForEach-Object {Write-Host $_.ToString()}
   throw ('BL_R1_AST_FAILED='+$entry.Path)
  }
  Write-Host ('BL_R1_SOURCE_SHA_AND_AST=PASS;'+$entry.Path)
 }
 Import-Module -Name $core -Force -ErrorAction Stop
 $original='C:\work\E2E\BlueLite_Stage1_S31_26300.9711_OneDriveAMBER\install.wim'
 $contract='C:\work\UUP_Source\26300.9711_2b22470a\BlueLite_SourceContract.json'
 $working='C:\work\E2E\BlueLite_MAXPRE_26300.9711_owned\install.working.wim'
 $null=Assert-BlueLiteOwnedPath -Path $original -OwnerRoot 'C:\work' -MustExist
 $null=Assert-BlueLiteOwnedPath -Path $contract -OwnerRoot 'C:\work' -MustExist
 $null=Assert-BlueLiteOwnedPath -Path $logs -OwnerRoot 'C:\work' -MustExist -Directory
 $null=Assert-BlueLiteOwnedPath -Path $working -OwnerRoot 'C:\work'
 Write-Host 'BL_R1_REGRESSION_FILEINFO_DIRECTORYINFO_MISSING_OUTPUT=PASS'
 $out=@(
  'C:\work\logs\BlueLite_MAXPRE_SourceBoundPlan_R1_26300.9711.txt',
  'C:\work\logs\BlueLite_MAXPRE_SourceBoundPlan_R1_26300.9711.json',
  'C:\work\logs\BlueLite_MAXPRE_SourceBoundReceipt_R1_26300.9711.json'
 )
 foreach($file in $out){
  if(Test-Path -LiteralPath $file){throw ('BL_R1_OUTPUT_ALREADY_EXISTS='+$file)}
 }
 $arguments=@('-NoProfile','-ExecutionPolicy','Bypass','-File',$controller,
  '-Build','26300.9711',
  '-CoreModulePath',$core,
  '-RegistryPath',$registry,
  '-SourceContractPath',$contract,
  '-OriginalWimPath',$original,
  '-WorkingWimPath',$working,
  '-ExpectedCoreSHA256','609C8FD727E553249640B68E30CD6B7BF740C7CE26372276A2DE75405D9EA404',
  '-ExpectedRegistrySHA256',$registrySHA,
  '-ExpectedSourceContractSHA256','08C05398AD37DB6FE0A58714D7F31B7C02A52CC91AFE3779402DB9CD1B2FEDEA',
  '-DeclaredOriginalWimSHA256','F52389FA66F8B60D56661C8786EC99409FB95447403B3C6FCBB94121EF8E340B',
  '-ExpectedOriginalWimBytes','6509216853')
 & (Join-Path $PSHOME 'pwsh.exe') @arguments
 if($LASTEXITCODE -ne 0){throw ('BL_R1_CONTROLLER_EXIT_NONZERO='+$LASTEXITCODE)}
 Write-Host 'BL_R1_CONTROLLER_EXIT=0;JSON_PLAN_AND_RECEIPT_CREATED_IF_NATIVE_PASS'
}