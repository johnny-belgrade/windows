# BlueLite R036 v3: source-bound boot.wim speed candidate builder.
# v3 adds strict single-variant export per Git OPnn (operator approved three variants) on validated existing own TEMP. Default Analyze remains strictly read-only. Export requires separate, explicit owner review/authorization.
# This does NOT modify R035 source WIM, existing ISO, EFI/BCD, vendor ZIP, or installed WinRE.
[CmdletBinding()]
param(
    [ValidateSet('Analyze','ExportVariants','Verify')]
    [string]$Mode='Analyze',
    [string]$CycleRoot='C:\work\_UUP\R035_Universal_PREMAX_26300',
    [string]$ExperimentRoot='C:\work\_UUP\temp\R036_BootSpeed_Variants_20261108',
    [ValidateSet('SetupOnly_LZX','SetupOnly_XPRESS','Dual_XPRESS')]
    [string]$Variant='SetupOnly_LZX',
    [switch]$ExplicitOwnerApprovedDerivedWimExport
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
function Assert([bool]$condition,[string]$why) {
    if (-not $condition) { throw ('R036_FAIL_CLOSED_'+$why) }
}
function FileHash([string]$path) {
    (Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()
}
function WriteNewJson([string]$path,$value) {
    $bytes=[Text.UTF8Encoding]::new($false).GetBytes((ConvertTo-Json -InputObject $value -Depth 10)+[Environment]::NewLine)
    $handle=[IO.File]::Open($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try { $handle.Write($bytes) } finally { $handle.Dispose() }
}
function ValidRoot([string]$path) {
    $p=[IO.Path]::GetFullPath($path).TrimEnd('\')
    Assert ($p -match '^C:\\work\\_UUP\\R\d{3}_[A-Za-z0-9_.-]+$') 'INVALID_CYCLE_ROOT'
    $p
}
function AssertNoReparse([string]$path) {
    $obj=Get-Item -LiteralPath $path -Force -ErrorAction Stop
    Assert (($obj.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) ('REPARSE_'+$obj.Name)
}
function GetVariantSpec([string]$label) {
    switch($label) {
      'SetupOnly_LZX' { return @{ image='2'; comp='LZX'; count=1; boot=1; setupIndex=1 } }
      'SetupOnly_XPRESS' { return @{ image='2'; comp='XPRESS'; count=1; boot=1; setupIndex=1 } }
      'Dual_XPRESS' { return @{ image='all'; comp='XPRESS'; count=2; boot=2; setupIndex=2 } }
      default { throw 'INVALID_VARIANT' }
    }
}
$CycleRoot=ValidRoot $CycleRoot
$report=Join-Path $CycleRoot 'BlueLite_Logs\BlueLite_R029_Capture_Result.json'
Assert (Test-Path -LiteralPath $report -PathType Leaf) 'CAPTURE_RECEIPT_REQUIRED'
AssertNoReparse $CycleRoot
AssertNoReparse (Split-Path $report -Parent)
$receipt=Get-Content -LiteralPath $report -Raw -ErrorAction Stop|ConvertFrom-Json
Assert ($receipt.status -eq 'NATIVE_WIM_BOOT_HARDLINK_SHA_PASS') 'CAPTURE_NOT_PROVEN'
Assert ([string]$receipt.root -ieq $CycleRoot) 'RECEIPT_ROOT_MISMATCH'
$boot=[string]$receipt.setup_boot_wim
Assert ($boot.StartsWith($CycleRoot+'\',[StringComparison]::OrdinalIgnoreCase)) 'BOOT_ESCAPES_ROOT'
Assert (Test-Path -LiteralPath $boot -PathType Leaf) 'BOOT_SOURCE_MISSING'
AssertNoReparse $boot
Assert ((Get-Item -LiteralPath $boot).Length -eq [long]$receipt.setup_boot_bytes) 'BOOT_SOURCE_BYTE_DRIFT'
Assert ((FileHash $boot) -eq ([string]$receipt.setup_boot_sha256).ToUpperInvariant()) 'BOOT_SOURCE_SHA_DRIFT'
$sourceImage=@(Get-WindowsImage -ImagePath $boot -ErrorAction Stop)
Assert ($sourceImage.Count -eq 2) 'NOT_CANONICAL_TWO_INDEX_SOURCE'
$sourceBoot1=Get-WindowsImage -ImagePath $boot -Index 1 -ErrorAction Stop
$sourceBoot2=Get-WindowsImage -ImagePath $boot -Index 2 -ErrorAction Stop
Assert ($sourceBoot1.ImageBootable -eq 'No' -and $sourceBoot2.ImageBootable -eq 'Yes') 'BOOTABLE_INDEX_NOT_TWO'
Assert ($sourceImage[1].ImageName -match 'Windows Setup') 'SETUP_INDEX_IDENTITY'
$sourceInfo=@(Get-WindowsImage -ImagePath $boot -Index 2 -ErrorAction Stop)
$wimlib=Join-Path ([string]$receipt.stage) 'bin\wimlib-imagex.exe'
Assert ($wimlib.StartsWith($CycleRoot+'\',[StringComparison]::OrdinalIgnoreCase)) 'TOOL_ESCAPES_CYCLE_ROOT'
Assert (Test-Path -LiteralPath $wimlib -PathType Leaf) 'STAGED_WIMLIB_MISSING'
AssertNoReparse $wimlib
$toolSha=FileHash $wimlib
$sourceSha=FileHash $boot
Write-Output ('R036_SOURCE_PIN_PASS BOOT_BYTES='+$receipt.setup_boot_bytes+' BOOT_SHA256='+$sourceSha+' WIMLIB_SHA256='+$toolSha)
if($Mode -eq 'Analyze') {
    $sourceWimInfo=@(& $wimlib 'info' $boot 2>&1)
    Assert ($LASTEXITCODE -eq 0) 'SOURCE_WIM_INFO_EXIT'
    $sourceWimInfo | Select-Object -First 15 | ForEach-Object { Write-Output $_ }
    Write-Output 'R036_ANALYZE_ONLY_PASS NO_DERIVED_WIM_NO_BCD_NO_ISO_NO_MOUNT'
    return
}
$ExperimentRoot=[IO.Path]::GetFullPath($ExperimentRoot).TrimEnd('\')
Assert ($ExperimentRoot -match '^C:\\work\\_UUP\\temp\\R036_[A-Za-z0-9_.-]+$') 'EXPERIMENT_ROOT_NOT_OWNED_TEMP'
Assert (-not $ExperimentRoot.StartsWith($CycleRoot+'\',[StringComparison]::OrdinalIgnoreCase)) 'EXPERIMENT_INSIDE_CYCLE'
AssertNoReparse (Split-Path $ExperimentRoot -Parent)
if($Mode -eq 'Verify') {
    Assert (Test-Path -LiteralPath $ExperimentRoot -PathType Container) 'VERIFY_ROOT_MISSING'
    AssertNoReparse $ExperimentRoot
    $spec=GetVariantSpec $Variant
    $candidate=Join-Path $ExperimentRoot ($Variant+'.wim')
    $manifest=Join-Path $ExperimentRoot ($Variant+'.receipt.json')
    $verified=Join-Path $ExperimentRoot ($Variant+'.verified.json')
    Assert (-not(Test-Path $verified)) 'VERIFY_RECEIPT_EXISTS'
    Assert ((Test-Path $candidate -PathType Leaf) -and (Test-Path $manifest -PathType Leaf)) 'VERIFY_REQUIRED_FILES_MISSING'
    $m=Get-Content -LiteralPath $manifest -Raw|ConvertFrom-Json
    Assert ($m.status -eq 'VARIANT_WIM_EXPORTED_PENDING_INDEPENDENT_VERIFY') 'BAD_VARIANT_RECEIPT'
    Assert ($m.source_sha256 -eq $sourceSha -and $m.tool_sha256 -eq $toolSha -and $m.variant -eq $Variant) 'SOURCE_MANIFEST_IDENTITY'
    Assert ((Get-Item $candidate).Length -eq [long]$m.bytes -and (FileHash $candidate) -eq $m.sha256) 'DERIVATIVE_FILE_SHA_BYTES'
    $imgs=@(Get-WindowsImage -ImagePath $candidate -ErrorAction Stop)
    Assert ($imgs.Count -eq [int]$spec.count) 'DERIVATIVE_INDEX_COUNT'
    $booted=[Collections.Generic.List[object]]::new()
    foreach($item in $imgs) {
        $detail=Get-WindowsImage -ImagePath $candidate -Index ([int]$item.ImageIndex) -ErrorAction Stop
        if($detail.ImageBootable -eq 'Yes') { [void]$booted.Add($detail) }
    }
    Assert ($booted.Count -eq 1 -and [int]$booted[0].ImageIndex -eq [int]$spec.boot) 'DERIVATIVE_BOOTABLE_INDEX'
    $detail=@(Get-WindowsImage -ImagePath $candidate -Index ([int]$spec.setupIndex))
    Assert (($detail.Count -eq 1) -and ($detail[0].ImageSize -eq $sourceInfo[0].ImageSize)) 'SETUP_LOGICAL_SIZE_CHANGED'
    & $wimlib 'verify' $candidate | Out-Null
    Assert ($LASTEXITCODE -eq 0) 'WIMLIB_FULL_VERIFY_FAIL'
    $originalPaths=@(& $wimlib 'dir' $boot '2')
    Assert ($LASTEXITCODE -eq 0) 'SOURCE_PATH_LIST_FAIL'
    $variantPaths=@(& $wimlib 'dir' $candidate ([string]$spec.setupIndex))
    Assert ($LASTEXITCODE -eq 0) 'CANDIDATE_PATH_LIST_FAIL'
    $a=@($originalPaths|Where-Object{$_ -like '\*'}|Sort-Object -Unique)
    $b=@($variantPaths|Where-Object{$_ -like '\*'}|Sort-Object -Unique)
    Assert ($a.Count -eq $b.Count) 'SOURCE_CANDIDATE_PATH_COUNT'
    Assert (-not(Compare-Object -ReferenceObject $a -DifferenceObject $b)) 'SOURCE_CANDIDATE_PATH_DIFF'
    $proof=[ordered]@{
       schema='BlueLite.R036.IndependentVariantVerification.v1';utc=[DateTime]::UtcNow.ToString('o')
       status='INDEPENDENT_WIM_FULL_SHA_INDEX_BOOT_PATH_VERIFY_PASS'
       variant=$Variant;source_sha256=$sourceSha;candidate_sha256=FileHash $candidate
       variant_receipt_sha256=FileHash $manifest;index_count=$imgs.Count
       boot_index=[int]$spec.boot;setup_path_count=$a.Count
       native_wimlib_verify='PASS';wim_original_modified=$false;iso_modified=$false;boot_time='NOT_MEASURED'
    }
    WriteNewJson $verified $proof
    Write-Output ('R036_INDEPENDENT_VARIANT_PASS='+$Variant+' SHA='+(FileHash $candidate)+' BYTES='+(Get-Item $candidate).Length+' RECEIPT_SHA='+(FileHash $verified))
    return
}
Assert ($Mode -eq 'ExportVariants') 'INVALID_MODE'
Assert ($ExplicitOwnerApprovedDerivedWimExport.IsPresent) 'SEPARATE_OWNER_REVIEW_APPROVAL_MISSING'
if (-not (Test-Path -LiteralPath $ExperimentRoot)) {
    [void][IO.Directory]::CreateDirectory($ExperimentRoot)
}
Assert (Test-Path -LiteralPath $ExperimentRoot -PathType Container) 'EXPERIMENT_ROOT_NOT_DIRECTORY'
AssertNoReparse $ExperimentRoot
$existing=@(Get-ChildItem -LiteralPath $ExperimentRoot -Force -ErrorAction Stop)
$allowed=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($n in @('SetupOnly_LZX','SetupOnly_XPRESS','Dual_XPRESS')) {
    foreach ($suffix in @('.wim','.receipt.json','.verified.json')) { [void]$allowed.Add($n+$suffix) }
}
foreach ($item in $existing) {
    Assert (-not $item.PSIsContainer -and $allowed.Contains($item.Name)) ('UNKNOWN_EXPERIMENT_MEMBER_'+$item.Name)
    Assert ((($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0)) ('EXPERIMENT_MEMBER_REPARSE_'+$item.Name)
}
$specs=@($Variant)
foreach($name in $specs) {
    $v=GetVariantSpec $name
    $dest=Join-Path $ExperimentRoot ($name+'.wim')
    Assert (-not(Test-Path -LiteralPath $dest)) ('VARIANT_ALREADY_EXISTS_'+$name)
    Write-Output ('R036_VARIANT_EXPORT_START='+$name)
    & $wimlib 'export' $boot ([string]$v.image) $dest '--boot' ('--compress='+$v.comp) '--check' 2>&1 | ForEach-Object { Write-Output $_ }
    Assert ($LASTEXITCODE -eq 0) ('WIM_EXPORT_NATIVE_EXIT_'+$name)
    Assert (Test-Path -LiteralPath $dest -PathType Leaf) ('WIM_EXPORT_MISSING_'+$name)
    $m=[ordered]@{
       schema='BlueLite.R036.VariantWim.v1'; utc=[DateTime]::UtcNow.ToString('o')
       status='VARIANT_WIM_EXPORTED_PENDING_INDEPENDENT_VERIFY';variant=$name
       source=$boot;source_sha256=$sourceSha;tool=$wimlib;tool_sha256=$toolSha
       wim=$dest;bytes=(Get-Item $dest).Length;sha256=FileHash $dest
       expected_boot_index=[int]$v.boot;compression=$v.comp;iso_unchanged=$true
       native_wim_export='EXIT0';boot_time='NOT_MEASURED';source_image_unchanged=$true
    }
    $mr=Join-Path $ExperimentRoot ($name+'.receipt.json')
    WriteNewJson $mr $m
    & (Join-Path $PSHOME 'pwsh.exe') '-NoProfile' '-NonInteractive' '-File' $PSCommandPath '-Mode' 'Verify' '-CycleRoot' $CycleRoot '-ExperimentRoot' $ExperimentRoot '-Variant' $name
    Assert ($LASTEXITCODE -eq 0) ('SEPARATE_VERIFIER_EXIT_'+$name)
    Assert ((FileHash $boot) -eq $sourceSha) ('PROTECTED_SOURCE_CHANGED_'+$name)
}
Write-Output 'R036_VARIANTS_ALL_THREE_INDEPENDENT_SHA_INDEX_PATH_PASS NO_ISO_BUILD NO_SETUP_BOOT_TIMING_CLAIM'
