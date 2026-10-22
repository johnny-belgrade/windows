# R002R3 native read-only diff and isolated contract negative tests.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$r='C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package'
$adapter=Join-Path $r '03_Drafts\R002R3_ConverterNativeConfigAdapter_DRAFT.ps1'
$contract=Join-Path $r '01_Inputs\R002R3_ConverterNative_9711_Contract.json'
$base=Join-Path $r '04_StaticTests\R002R2_Fixture_001'
$out=Join-Path $r '04_StaticTests\R002R3_ConfigFixture_001'
$neg=Join-Path $r '04_StaticTests\R002R3_NegativeCases_002'
if(Test-Path -LiteralPath $neg){throw 'NEGATIVE_DIRECTORY_ALREADY_EXISTS'}
$null=[IO.Directory]::CreateDirectory($neg)
$t=$null;$e=$null;$ast=[Management.Automation.Language.Parser]::ParseFile($adapter,[ref]$t,[ref]$e)
if(@($e).Count){throw 'ADAPTER_AST_SYNTAX_FAIL'}
$cmds=@($ast.FindAll({param($x)$x -is [Management.Automation.Language.CommandAst]},$true))
$forbidden=@($cmds | Where-Object {$_.GetCommandName() -match '^(Invoke-WebRequest|Invoke-RestMethod|Start-Process|aria2c|dism|reg|Mount-WindowsImage|Dismount-WindowsImage|Export-WindowsImage|Remove-Item)$'})
if($forbidden.Count){throw 'ADAPTER_FORBIDDEN_RUNTIME_AST'}
Write-Output ('R002R3_AST_PASS;COMMANDS='+$cmds.Count)
$c=Get-Content -LiteralPath $contract -Raw | ConvertFrom-Json
$originalConfig=[IO.File]::ReadAllLines((Join-Path $base 'ConvertConfig.ini'))
$generatedConfig=[IO.File]::ReadAllLines((Join-Path $out 'ConvertConfig.ini'))
if($originalConfig.Length -ne $generatedConfig.Length){throw 'CONFIG_LINE_COUNT_DIFFERS'}
$diff=[Collections.Generic.List[string]]::new()
for($i=0;$i -lt $originalConfig.Length;$i++) {
 if($originalConfig[$i] -cne $generatedConfig[$i]){ $diff.Add($generatedConfig[$i].Trim()) }
}
foreach($k in @('AutoStart','CustomList','StubAppsFull')){
 if(@($diff|Where-Object {$_ -match ('^'+$k+'\s*=\s*[01]\s*$')}).Count -ne 1){throw ('EXPECTED_CHANGE_NOT_EXACT_'+$k)}
}
if($diff.Count -ne 3){throw ('UNEXPECTED_CONFIG_CHANGE_COUNT='+$diff.Count)}
Write-Output 'R002R3_NATIVE_CONFIG_DIFF=EXACT_3_ALLOWED_ONLY'
$origList=[IO.File]::ReadAllLines((Join-Path $base 'CustomAppsList.txt'))
$newList=[IO.File]::ReadAllLines((Join-Path $out 'CustomAppsList.txt'))
if($origList.Length -ne $newList.Length){throw 'APP_LIST_ROW_LOSS'}
$active=@($newList|Where-Object {$_ -match '^\s*[A-Za-z][A-Za-z0-9.]+_[A-Za-z0-9]+\s*$'})
if($active.Count -ne 5){throw 'APP_LIST_ACTIVE_COUNT'}
foreach($family in @($c.required_staging_families)){if($family -cnotin $active){throw ('APP_LIST_MISSING='+$family)}}
foreach($family in @($c.forbidden_active_non_staging)){if($family -cin $active){throw ('APP_LIST_FORBIDDEN='+$family)}}
Write-Output 'R002R3_NATIVE_APP_LIST=EXACT_5_STAGING_FAMILIES_STORE_NOT_ACTIVE'
$local=Get-Content -LiteralPath (Join-Path $out 'R002R3_ConfigReceipt.json') -Raw | ConvertFrom-Json
if($local.no_converter_runtime -ne $true -or $local.vendor_binary_actual_version_verified -ne $false){throw 'RUNTIME_STATUS_WRONG'}
foreach($n in @('ConvertConfig.ini','CustomAppsList.txt')){
 $path=Join-Path $base $n
 $expect=if($n -eq 'ConvertConfig.ini'){$c.original_config_sha256}else{$c.original_app_list_sha256}
 if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $expect){throw 'UPSTREAM_TEMPLATE_CHANGED'}
}
Write-Output 'R002R3_UPSTREAM_TEMPLATES_SHA_UNCHANGED=TRUE'
function MustReject([string]$Name,[string]$GateName,[scriptblock]$Change,[string]$Mode='Audit'){
 $obj=Get-Content -LiteralPath $contract -Raw | ConvertFrom-Json
 & $Change $obj
 $file=Join-Path $neg ($Name+'.json')
 [IO.File]::WriteAllText($file,($obj|ConvertTo-Json -Depth 20),[Text.UTF8Encoding]::new($false))
 try{
  if($Mode -eq 'SmallFixture'){
   $response=@(& $adapter -Mode SmallFixture -ContractPath $file -OutputDirectory (Join-Path $r '04_StaticTests\R002R3_NegativeOutput_Nonexistent'))
  }elseif($Mode -eq 'Existing'){
   $response=@(& $adapter -Mode SmallFixture -ContractPath $file -OutputDirectory $out -Authorization 'I_APPROVE_R002R3_TINY_CONFIG_FIXTURE_ONLY')
  }else{$response=@(& $adapter -Mode Audit -ContractPath $file)}
  throw ('UNEXPECTED_NEGATIVE_ACCEPT='+$Name)
 }catch{
  $msg=$_.Exception.Message
  if($msg -like 'UNEXPECTED_NEGATIVE_ACCEPT=*'){throw}
  if($msg -notlike ('*R002R3_HOLD='+$GateName+'*')){throw ('NEGATIVE_WRONG_GATE='+$Name+';'+$msg)}
  Write-Output ('R002R3_NEGATIVE_PASS='+$Name+';GATE='+$GateName)
 }
}
MustReject 'runtime_true' 'CONTRACT_SCHEMA_OR_RUNTIME' {param($v)$v.runtime_allowed=$true}
MustReject 'zip_source_hash' 'SOURCE_ZIP_SHA_DRIFT' {param($v)$v.source_zip_sha256='0'*64}
MustReject 'ini_template_hash' 'SOURCE_INI_SHA_DRIFT' {param($v)$v.original_config_sha256='0'*64}
MustReject 'newer_converter_unreviewed' 'CONVERTER_VERSION_NOT_IN_REVIEWED_MATRIX' {param($v)$v.converter_declared='uup-converter-wimlib-v128m.7z'}
MustReject 'winre_drift' 'INI_ORIGINAL_PREDICATE_SkipWinRE' {param($v)$v.settings_pinned_expected.'convert-UUP'.SkipWinRE='1'}
MustReject 'appx_photo_missing' 'REQUIRED_FIVE_FAMILY_CONTRACT' {param($v)$v.required_staging_families=@($v.required_staging_families|Where-Object {$_ -ne 'Microsoft.Windows.Photos_8wekyb3d8bbwe'})}
MustReject 'g4_wrong_count' 'HISTORIC_G4_CLOSURE_NOT_BOUND' {param($v)$v.source_g4_staging_count=27}
MustReject 'missing_fixture_authorization' 'SMALL_FIXTURE_AUTH_REQUIRED' {param($v)} 'SmallFixture'
MustReject 'existing_output' 'OUTPUT_ALREADY_EXISTS' {param($v)} 'Existing'
Write-Output 'R002R3_NEGATIVES=9_OF_9_PASS'
Write-Output 'R002R3_RESULT=PASS_SOURCE_V126_CONFIG_EXACT_FIVE_NEGATIVES_STATIC_ONLY'
