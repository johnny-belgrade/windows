param([string]$Root)
$ErrorActionPreference='Stop'
$n=0
foreach($p in [IO.Directory]::GetFiles((Join-Path $Root 'BlueLite'),'*.ps1')){
 $tok=$null;$err=$null;[void][Management.Automation.Language.Parser]::ParseFile($p,[ref]$tok,[ref]$err)
 if($err.Count){foreach($e in $err){Write-Output ($p+': '+$e.Message)};exit 1};$n++
}
Write-Output ('AST_PASS count='+$n+' host='+$PSVersionTable.PSVersion);exit 0
