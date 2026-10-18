& {
 $ErrorActionPreference='Stop'
 Set-StrictMode -Version Latest
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_PS7_REQUIRED'}
 $root='C:\work'
 $scripts=Join-Path $root 'scripts'
 $logs=Join-Path $root 'logs'
 if(-not(Test-Path -LiteralPath $scripts -PathType Container) -or
    -not(Test-Path -LiteralPath $logs -PathType Container)){throw 'BL_WORKSPACE_MISSING'}
 $plan=Join-Path $logs 'BlueLite_MAXPRE_SourceBoundPlan_R1_26300.9711.json'
 $receipt=Join-Path $logs 'BlueLite_MAXPRE_SourceBoundReceipt_R1_26300.9711.json'
 $planHash='A46C7BE0B4A1F6E2BF5889B22A80404FB788D0E2A5927AE2F3EB4BB4114C6E0F'
 $receiptHash='F9656A7594797F04F7F3B96A89C551BBEE544946754B60D665D8F7778FAA17D9'
 if((Get-FileHash -LiteralPath $plan -Algorithm SHA256).Hash -cne $planHash -or
    (Get-FileHash -LiteralPath $receipt -Algorithm SHA256).Hash -cne $receiptHash){
  throw 'BL_R1_OPERATOR_EVIDENCE_PIN_DRIFT'
 }
 $module=Join-Path $scripts 'BlueLite.MaxPre.Transaction.psm1'
 $test=Join-Path $scripts 'BlueLite.MaxPre.Transaction.SourcePairTests.ps1'
 $moduleHash='6F1784D350D4983F4C3AE29328D518613944FF8BA56C1F1566ADD48459A6389F'
 $items=@(
  @{
   Path=$module
   Hash=$moduleHash
   Url='https://raw.githubusercontent.com/johnny-belgrade/windows/83cf7bce276d8a75d7d1a1828f6e8bdc9b4bb19b/production/engine/BlueLite.MaxPre.Transaction.psm1'
  },
  @{
   Path=$test
   Hash='8C443961136CDD6F5921491FB09B58268109E0EDD242F595BE8A15F59391810C'
   Url='https://raw.githubusercontent.com/johnny-belgrade/windows/ca9d0d8353087331f5a8ca35e7a73228bfe5d5e9/production/tests/BlueLite.MaxPre.Transaction.SourcePairTests.ps1'
  }
 )
 foreach($item in $items){
  if(Test-Path -LiteralPath $item.Path){throw ('BL_LOCAL_SOURCE_EXISTS_NO_OVERWRITE='+$item.Path)}
  Invoke-WebRequest -Uri $item.Url -OutFile $item.Path -ErrorAction Stop
  $sha=(Get-FileHash -LiteralPath $item.Path -Algorithm SHA256).Hash
  if($sha -cne $item.Hash){
   Remove-Item -LiteralPath $item.Path -Force
   throw ('BL_SOURCE_SHA_MISMATCH='+$item.Path+';'+$sha)
  }
  $tokens=$null
  $parseErrors=$null
  [void][System.Management.Automation.Language.Parser]::ParseFile($item.Path,[ref]$tokens,[ref]$parseErrors)
  if(@($parseErrors).Count -ne 0){
   $parseErrors|ForEach-Object {Write-Host $_.ToString()}
   throw ('BL_AST_PARSER_FAILURE='+$item.Path)
  }
  Write-Host ('BL_PIN_AND_AST=PASS;'+$item.Path)
 }
 $invoke=@('-NoProfile','-ExecutionPolicy','Bypass','-File',$test,
  '-ModulePath',$module,'-PlanPath',$plan,'-ReceiptPath',$receipt,
  '-ExpectedModuleSHA256',$moduleHash,
  '-ExpectedPlanSHA256',$planHash,'-ExpectedReceiptSHA256',$receiptHash)
 & (Join-Path $PSHOME 'pwsh.exe') @invoke
 if($LASTEXITCODE -ne 0){throw ('BL_TX_TEST_EXIT='+$LASTEXITCODE)}
 Write-Host 'BL_TX_OPERATOR_LAUNCHER_EXIT=0'
}