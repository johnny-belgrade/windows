# BlueLite R054 OP01 — immutable original source plus exactly two .ps1 modules, both SHA manifests; produce ONE clean universal ZIP.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$base='C:\work\_UUP'
$oldZip=Join-Path $base 'R051_PREMAX_Universal_26300x\BlueLite_PRE_MAX_26300x_R051_v1.zip'
$root=Join-Path $base 'temp\R054_OP01_Src_20261121'
$source=Join-Path $root 'Source'
$delivery=Join-Path $base 'R054_PREMAX_Universal_26300x'
$target=Join-Path $delivery 'BlueLite_PRE_MAX_26300x_R054_v1.zip'
$hist=Join-Path $base 'UUP-history\R054_20261121'
$receipt=Join-Path $hist 'R054_OP01_Builder.json'
$sourceExpected='2BEF0E01CB25AC7A5792329B2A63BBC5D3A67C296F0B138761DD4677AC6C18DB'
if((Test-Path $root) -or (Test-Path $delivery) -or (Test-Path $receipt)){throw 'R054_OWNED_ROOT_COLLISION_NO_OVERWRITE'}
if((Get-FileHash $oldZip).Hash -ne $sourceExpected){throw 'PROTECTED_R051_SOURCE_SHA_CHANGED'}
[void][IO.Directory]::CreateDirectory($source)
[IO.Compression.ZipFile]::ExtractToDirectory($oldZip,$source)
$wimPs=Join-Path $source 'Engine\BlueLite\BlueLite_PreDebloatWim.ps1'
$patchPs=Join-Path $source 'Engine\BlueLite\BlueLite_PatchConverter.ps1'
$w=[IO.File]::ReadAllText($wimPs)
$p=[IO.File]::ReadAllText($patchPs)
if((Get-FileHash $wimPs).Hash -ne '0B8A659AB0AD25E3105CC4091267511EB3F657F112D9E83256B5637F32007A9A'){throw 'ORIGINAL_WIM_PSH_SHA_CHANGED'}
if((Get-FileHash $patchPs).Hash -ne '0ABC4E76567E2B236E23F9D4E8495E923136C57199746FA78B9F405F1C307035'){throw 'ORIGINAL_CONVERTER_PATCH_SHA_CHANGED'}
$hookOld='powershell -NoProfile -ExecutionPolicy Bypass -File "BlueLite\BlueLite_PreDebloatWim.ps1"'
$hookNew=@'
if not exist "%ProgramFiles%\PowerShell\7\pwsh.exe" (
  echo [BlueLite ERROR] 64-bit PowerShell 7 missing; cannot safely run offline WIM script.
  exit /b 93
)
"%ProgramFiles%\PowerShell\7\pwsh.exe" -NoLogo -NoProfile -NonInteractive -File "BlueLite\BlueLite_PreDebloatWim.ps1"
'@
if(-not $p.Contains($hookOld)){throw 'VERIFIED_ORIGINAL_HOOK_ANCHOR_MISSING'}
$p=$p.Replace($hookOld,$hookNew)
if($p.Contains($hookOld)){throw 'ORIGINAL_PS5_HOOK_SURVIVED'}
$paramAnchor='    [string]$WorkDirectory = ".\BlueLite_FinalWim_Work",'
if(-not $w.Contains($paramAnchor)){throw 'WIM_PARAMETER_ANCHOR_MISSING'}
$w=$w.Replace($paramAnchor,'    [int64]$MaxInstallWimBytes = 5500000000,'+[Environment]::NewLine+$paramAnchor)
$pathAnchor='    if ([IO.Path]::IsPathRooted($WorkDirectory))'
$pathInjection=@'
    # R054: own short mount rooted in the actual user's original selected UUP root.
    # The engine can nest BlueLite_Work multiple times; do not mount inside it.
    if ($WorkDirectory -eq ".\BlueLite_FinalWim_Work") {
        $currentPath=[IO.Path]::GetFullPath((Get-Location).Path)
        $workMark='\BlueLite_Work\'
        $idx=$currentPath.IndexOf($workMark,[StringComparison]::OrdinalIgnoreCase)
        if ($idx -lt 4) { throw 'R054_SHORT_MOUNT_OWNER_ROOT_NOT_PROVEN' }
        $ownerRoot=$currentPath.Substring(0,$idx)
        $WorkDirectory=Join-Path $ownerRoot 'BL_WIM_R054'
    }
    if ([IO.Path]::GetFullPath($WorkDirectory).Length -gt 120) { throw 'R054_MOUNT_PATH_TOO_LONG_FOR_CBS_SAFE_INVENTORY' }
'@
if(-not $w.Contains($pathAnchor)){throw 'WIM_WORKDIR_ANCHOR_MISSING'}
$w=$w.Replace($pathAnchor,$pathInjection+[Environment]::NewLine+$pathAnchor)
$mountAnchor='    if (-not (Test-Path -LiteralPath (Join-Path $mountDir ''Windows''))) { throw "Mounted Windows root missing: $mountDir" }'
$winreInjection=@'
    # R054: source SkipWinRE=1 permits installed Recovery-on-Demand only; Setup boot.wim must stay.
    if (Test-Path -LiteralPath (Join-Path $mountDir 'Windows\System32\Recovery\winre.wim') -PathType Leaf) {
        throw 'WINRE_PRESENCE_HOLD: installed winre.wim remains despite original source SkipWinRE=1'
    }
'@
if(-not $w.Contains($mountAnchor)){throw 'WIM_MOUNT_ANCHOR_MISSING'}
$w=$w.Replace($mountAnchor,$mountAnchor+[Environment]::NewLine+$winreInjection)
$sizeAnchor='    $newSize=(Get-Item -LiteralPath $exportWim).Length'
$sizeInjection=@'
    # R054 owner hard upper bound: decimal bytes; never rename LZMS ESD to install.wim.
    if ($MaxInstallWimBytes -ne 5500000000) { throw 'R054_OWNER_EXACT_MAX_WIM_BYTES_GATE_REFUSED' }
    if ($newSize -gt $MaxInstallWimBytes) {
        $wimlib=Join-Path (Get-Location).Path 'bin\wimlib-imagex.exe'
        if (Test-Path -LiteralPath $wimlib -PathType Leaf) {
            Write-Host "[R054 LZX] WIM export $newSize B exceeds owner target; trying compatible LZX:100 recompression."
            & $wimlib optimize $exportWim '--compress=LZX:100'
            if ($LASTEXITCODE -ne 0) { throw "R054_LZX_OPTIMIZE_HOLD_$LASTEXITCODE" }
            $newSize=(Get-Item -LiteralPath $exportWim).Length
            [void]$actions.Add("LZX:100 re-optimization, final bytes $newSize")
        } else {
            [void]$warnings.Add('R054 LZX optimizer not present; only native DISM Max compression attempted.')
        }
    }
    if ($newSize -gt $MaxInstallWimBytes) {
        throw "SIZE_HOLD: post-debloat install.wim $newSize decimal bytes exceeds hard maximum $MaxInstallWimBytes; ISO creation refused."
    }
    [void]$actions.Add("OWNER WIM SIZE GATE PASSED: $newSize <= $MaxInstallWimBytes decimal bytes")
'@
if(-not $w.Contains($sizeAnchor)){throw 'WIM_EXPORT_SIZE_ANCHOR_MISSING'}
$w=$w.Replace($sizeAnchor,$sizeAnchor+[Environment]::NewLine+$sizeInjection)
foreach($a in @('MaxInstallWimBytes = 5500000000','R054_SHORT_MOUNT_OWNER_ROOT_NOT_PROVEN','WINRE_PRESENCE_HOLD','SIZE_HOLD: post-debloat install.wim')){if(-not $w.Contains($a)){throw ('PATCH_NOT_RETAINED '+$a)}}
[IO.File]::WriteAllText($wimPs,$w,[Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText($patchPs,$p,[Text.UTF8Encoding]::new($false))
function RefreshManifest([string]$manifest,[string]$rootDir,[int]$expected) {
 $rows=@([IO.File]::ReadAllLines($manifest))
 if($rows.Count -ne $expected){throw ('MANIFEST_ROWS_NOT_'+$expected)}
 $next=@(foreach($line in $rows){
  if($line -notmatch '^([A-Fa-f0-9]{64}) \*(.+)$'){throw ('BAD_ORIGINAL_MANIFEST_ROW '+$line)}
  $rel=$Matches[2]
  $file=Join-Path $rootDir $rel.Replace('/','\')
  if(-not [IO.File]::Exists($file)){throw ('MANIFEST_TARGET_MISSING '+$file)}
  ((Get-FileHash $file).Hash+' *'+$rel)
 })
 [IO.File]::WriteAllText($manifest,($next -join [Environment]::NewLine)+[Environment]::NewLine,[Text.UTF8Encoding]::new($false))
}
RefreshManifest (Join-Path $source 'Engine\BlueLite_Package_SHA256.txt') (Join-Path $source 'Engine') 46
RefreshManifest (Join-Path $source 'SHA256SUMS.txt') $source 49
$astCount=0
foreach($ps in @(Get-ChildItem $source -Recurse -File -Filter '*.ps1')){
 $tok=$null;$err=$null
 $null=[Management.Automation.Language.Parser]::ParseFile($ps.FullName,[ref]$tok,[ref]$err)
 if(@($err).Count -ne 0){throw ('SOURCE_PSH_AST_FAILED '+$ps.FullName+' '+(@($err)|Out-String))}
 $astCount++
}
if($astCount -ne 26){throw ('SOURCE_AST_COUNT '+$astCount)}
$older=[IO.Compression.ZipFile]::OpenRead($oldZip)
try{
 if($older.Entries.Count -ne 50){throw 'PROTECTED_ZIP_NOT50'}
 $changed=@();$kept=0
 foreach($item in $older.Entries){
  $newFile=Join-Path $source $item.FullName.Replace('/','\')
  $stream=$item.Open();try{$before=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($stream))}finally{$stream.Dispose()}
  $after=(Get-FileHash $newFile).Hash
  if($before -ne $after){$changed+=([ordered]@{Member=$item.FullName;Before=$before;After=$after})}
  else{$kept++}
 }
}finally{$older.Dispose()}
$expectedChanged=@('Engine/BlueLite/BlueLite_PatchConverter.ps1','Engine/BlueLite/BlueLite_PreDebloatWim.ps1','Engine/BlueLite_Package_SHA256.txt','SHA256SUMS.txt')
if($changed.Count -ne 4 -or $kept -ne 46 -or @($changed|Where-Object {$_.Member -notin $expectedChanged}).Count -ne 0){throw ('EXACT_SOURCE_CHANGE_NOT4 '+($changed|ConvertTo-Json -Compress))}
[void][IO.Directory]::CreateDirectory($delivery)
[void][IO.Directory]::CreateDirectory($hist)
[IO.Compression.ZipFile]::CreateFromDirectory($source,$target,[IO.Compression.CompressionLevel]::Optimal,$false)
if(@(Get-ChildItem -LiteralPath $delivery -Force).Count -ne 1){throw 'CLEAN_DELIVERY_MORE_THAN_ONE_FILE'}
$z=[IO.Compression.ZipFile]::OpenRead($target)
try{if($z.Entries.Count -ne 50){throw 'NEW_ZIP_NOT50'}}finally{$z.Dispose()}
$rec=[ordered]@{
 Schema='BlueLite.R054.OP01.OfficialSourceZipBuilder.v1'
 UTC=[DateTime]::UtcNow.ToString('o');PID=$PID
 ParentSHA256=(Get-FileHash $oldZip).Hash
 NewZipPath=$target;NewZipSHA256=(Get-FileHash $target).Hash;NewZipBytes=(Get-Item $target).Length
 SourceMembers=50;ChangedMembers=$changed;UnchangedFromR051=$kept
 ManifestInnerRows=46;ManifestOuterRows=49;PS7ASTFiles=$astCount
 ExactTargetInstallWimMaxDecimalBytes=5500000000
 SourceProfileOriginalSkipWinRE1=$true;SetupBootWimStillRequired=$true
 NoOriginalOrFullWimMutation=$true;RuntimeISO='NOT_RUN';RuntimeFirstInstalledGuestBoot='NOT_RUN'
 Result='NATIVE_NEW_R054_SINGLE_ZIP_BUILT_REQUIRES_INDEPENDENT_QA'
}
$receiptBytes=[Text.UTF8Encoding]::new($false).GetBytes(($rec|ConvertTo-Json -Depth 12)+[Environment]::NewLine)
$fs=[IO.File]::Open($receipt,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$fs.Write($receiptBytes,0,$receiptBytes.Length)}finally{$fs.Dispose()}
Write-Host ('R054_OP01_NEW_PORTABLE_SOURCE_ZIP_BUILT ZIP_SHA='+$rec.NewZipSHA256+' BYTES='+$rec.NewZipBytes+' CHANGED='+$changed.Count+'/4 UNCHANGED='+$kept+'/46 AST='+$astCount+'/26 RECEIPT_SHA='+(Get-FileHash $receipt).Hash)
