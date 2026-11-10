# R038 OP76 - only native read-only PowerShell/.NET path API comparison.
$ErrorActionPreference='Stop'
$base='C:\work\_UUP\R038_IsolatedBootBenchmark_26300\BlueLite_Logs\R038_14_ISO_BCD_SDI'
$parent=Join-Path $base 'efi\microsoft\boot'
$path=Join-Path $parent 'bcd.LOG2'
$result=[ordered]@{
 schema='BlueLite.R038.OP76.PathApiReadOnly.v1'
 utc=[DateTime]::UtcNow.ToString('o')
 script_sha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
 exact_path=$path
 child_listing=@()
 get_item=$null
 test_path=$null
 dotnet_file_exists=$null
 dotnet_attributes=$null
 dotnet_fileinfo=$null
 ps_get_filehash=$null
 dotnet_sha256=$null
 status='HOLD'
 error=$null
}
try {
 $children=@(Get-ChildItem -LiteralPath $parent -Force -File -ErrorAction Stop)
 $result.child_listing=@($children | ForEach-Object { [ordered]@{ name=$_.Name; full_name=$_.FullName; bytes=[int64]$_.Length; attributes=[string]$_.Attributes } })
 try {
  $obj=Get-Item -LiteralPath $path -Force -ErrorAction Stop
  $result.get_item=[ordered]@{ok=$true;name=$obj.Name;full_name=$obj.FullName;bytes=[int64]$obj.Length;attributes=[string]$obj.Attributes}
 } catch { $result.get_item=[ordered]@{ok=$false; error=$_.Exception.Message;type=$_.Exception.GetType().FullName} }
 try { $result.test_path=[ordered]@{ok=$true; exists=[bool](Test-Path -LiteralPath $path -PathType Leaf -ErrorAction Stop)} }
 catch { $result.test_path=[ordered]@{ok=$false;error=$_.Exception.Message} }
 $result.dotnet_file_exists=[IO.File]::Exists($path)
 try { $result.dotnet_attributes=[ordered]@{ok=$true;attrs=[string][IO.File]::GetAttributes($path)} }
 catch { $result.dotnet_attributes=[ordered]@{ok=$false;error=$_.Exception.Message} }
 try { $fi=[IO.FileInfo]::new($path);$fi.Refresh();$result.dotnet_fileinfo=[ordered]@{exists=$fi.Exists;full_name=$fi.FullName;bytes=[int64]$fi.Length;attributes=[string]$fi.Attributes} }
 catch { $result.dotnet_fileinfo=[ordered]@{ok=$false;error=$_.Exception.Message} }
 try { $result.ps_get_filehash=[ordered]@{ok=$true;sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction Stop).Hash} }
 catch { $result.ps_get_filehash=[ordered]@{ok=$false;error=$_.Exception.Message} }
 try {
  $sha=[Security.Cryptography.SHA256]::HashData([IO.File]::ReadAllBytes($path))
  $result.dotnet_sha256=[ordered]@{ok=$true;sha256=[Convert]::ToHexString($sha)}
 } catch { $result.dotnet_sha256=[ordered]@{ok=$false;error=$_.Exception.Message} }
 $member=@($result.child_listing | Where-Object {$_.name -ceq 'bcd.LOG2'})
 if ($member.Count -ne 1 -or [int64]$member[0].bytes -ne 0) {throw 'TARGET_CHILD_LISTING_NOT_ZERO_BYTE_SINGLE'}
 if ($result.dotnet_file_exists -ne $true) {throw 'DOTNET_EXISTS_FALSE'}
 if ($result.dotnet_sha256.ok -ne $true -or $result.dotnet_sha256.sha256 -ne 'E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855'){throw 'NET_SHA_ZERO_MISMATCH'}
 if ($result.get_item.ok -eq $false) { $result.status='DIAGNOSED_GETITEM_PROVIDER_DISCREPANCY' }
 else { $result.status='READ_ONLY_FILE_API_CONSISTENT_NOW' }
} catch { $result.error=$_.Exception.Message }
$result | ConvertTo-Json -Depth 8
if ($result.status -eq 'HOLD'){exit 2}
exit 0
