param(
    [Parameter(Mandatory=$true)][string]$WimPath,
    [int]$Index = 1,
    [Parameter(Mandatory=$true)][string]$CapabilityPatternsFile,
    [Parameter(Mandatory=$true)][string]$FeatureDisableOnlyFile,
    [Parameter(Mandatory=$true)][string]$FeatureRemovePayloadFile,
    [Parameter(Mandatory=$true)][string]$PackagePatternsFile,
    [Parameter(Mandatory=$true)][string]$CustomAppsListPath,
    [Parameter(Mandatory=$true)][string]$ProfilePath,
    [Parameter(Mandatory=$true)][string]$ComponentWatchlistFile,
    [Parameter(Mandatory=$true)][string]$RequiredStagingAppIdentitiesFile,
    [Parameter(Mandatory=$true)][string]$RequiredFinalAppIdentitiesFile,
    [Parameter(Mandatory=$true)][string]$StagingOnlyAppPatternsFile,
    [Parameter(Mandatory=$true)][string]$ReleaseForbiddenAppPatternsFile,
    [Parameter(Mandatory=$true)][string]$OfflineHandoffPatternsFile,
    [Parameter(Mandatory=$true)][string]$ProtectedFloorFile,
    [string]$ExpectedBuildFile,
    [string]$WorkDirectory = ".\BlueLite_FinalWim_Work",
    [string]$LogPath = ".\BlueLite_Logs\FinalWimDebloat.log"
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Read-PatternFile([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { throw "Pattern file not found: $Path" }
    return @(Get-Content -LiteralPath $Path | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') })
}
function Read-SimpleIni([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { throw "INI not found: $Path" }
    $map=@{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        $t=$line.Trim(); if (-not $t -or $t.StartsWith('#') -or $t.StartsWith(';') -or $t.StartsWith('[')) { continue }
        $i=$t.IndexOf('='); if ($i -lt 1) { continue }
        $map[$t.Substring(0,$i).Trim()]=$t.Substring($i+1).Trim()
    }
    return $map
}
function Get-IniInt($Map,[string]$Name,[int]$Default) {
    if ($Map.ContainsKey($Name)) { return [int]$Map[$Name] }
    return $Default
}
function Match-Any([string]$Name,[string[]]$Patterns) {
    foreach ($p in $Patterns) { if ($Name.IndexOf($p,[StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true } }
    return $false
}
function Invoke-Dism([string[]]$DismArgs,[string]$Label) {
    Write-Host "[DISM] $Label" -ForegroundColor Cyan
    & dism.exe @DismArgs
    $code=$LASTEXITCODE
    if ($code -ne 0) { throw "$Label failed with DISM exit code $code" }
}
function Invoke-DismCapture([string[]]$DismArgs,[string]$Label) {
    Write-Host "[DISM] $Label" -ForegroundColor Cyan
    $out=@(& dism.exe @DismArgs 2>&1 | ForEach-Object { $_.ToString() })
    $code=$LASTEXITCODE
    if ($code -ne 0) { throw "$Label failed with DISM exit code $code`n$($out -join "`n")" }
    return $out
}
function Invoke-Reg([string[]]$RegArgs,[string]$Label,[switch]$AllowMissing) {
    & reg.exe @RegArgs | Out-Null
    $code=$LASTEXITCODE
    if ($code -ne 0 -and -not $AllowMissing) { throw "$Label failed with reg.exe exit code $code" }
    return $code
}
function Get-RegRawValue([string]$Key,[string]$Name) {
    $out=@(& reg.exe query $Key /v $Name 2>&1 | ForEach-Object { $_.ToString() })
    if ($LASTEXITCODE -ne 0) { return $null }
    foreach ($line in $out) {
        if ($line -match ('^\s*' + [regex]::Escape($Name) + '\s+REG_\S+\s+(.+?)\s*$')) { return $Matches[1] }
    }
    return $null
}
function Convert-RegDword([string]$Raw) {
    if (-not $Raw) { return $null }
    if ($Raw -match '^0x([0-9a-fA-F]+)$') { return [Convert]::ToInt64($Matches[1],16) }
    return [int64]$Raw
}

function Assert-ProtectedFloor([string]$Mount,[string[]]$RelativePaths,[string]$Label,[System.Collections.Generic.List[string]]$Actions) {
    $missing=[System.Collections.Generic.List[string]]::new()
    foreach($rel in $RelativePaths) {
        $p=Join-Path $Mount $rel
        if(-not (Test-Path -LiteralPath $p -PathType Leaf)) { [void]$missing.Add($rel) }
    }
    if($missing.Count -gt 0) { throw ("$Label failed; protected file(s) missing: " + ($missing -join ', ')) }
    [void]$Actions.Add("$Label PASSED: $($RelativePaths.Count) protected files present")
}

function Get-DeniedAppIdentities([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { throw "CustomAppsList not found: $Path" }
    $deny=[System.Collections.Generic.List[string]]::new()
    foreach ($line in Get-Content -LiteralPath $Path) {
        $t=$line.Trim()
        if ($t -match '^#\s*([A-Za-z0-9][A-Za-z0-9._-]+)_[A-Za-z0-9]+\s*$') { [void]$deny.Add($Matches[1]) }
    }
    return @($deny | Select-Object -Unique)
}
function Save-Inventory([string]$Mount,[string]$Path,[string]$Phase,[string]$Build) {
    $obj=[ordered]@{
        CapturedAtUtc=[DateTime]::UtcNow.ToString('o')
        Phase=$Phase
        Build=$Build
        Packages=@(Get-WindowsPackage -Path $Mount -ErrorAction Stop | Select-Object PackageName,PackageState,ReleaseType)
        Capabilities=@(Get-WindowsCapability -Path $Mount -ErrorAction Stop | Select-Object Name,State)
        Features=@(Get-WindowsOptionalFeature -Path $Mount -ErrorAction Stop | Select-Object FeatureName,State)
        ProvisionedApps=@(Get-AppxProvisionedPackage -Path $Mount -ErrorAction Stop | Select-Object DisplayName,PackageName,Version,Architecture,ResourceId)
    }
    $obj | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Path -Encoding UTF8
}
function Assert-HealthyStore([string]$Mount,[string]$Label,[System.Collections.Generic.List[string]]$HealthLog) {
    $out=Invoke-DismCapture @('/English',"/Image:$Mount",'/Cleanup-Image','/CheckHealth') $Label
    foreach ($l in $out) { [void]$HealthLog.Add("[$Label] $l") }
    $text=$out -join "`n"
    if ($text -match '(?i)No component store corruption detected') { return }
    if ($text -match '(?i)component store is repairable|component store cannot be repaired|corruption.*detected') {
        throw "$Label FAILED: component store is not healthy."
    }
    throw "$Label FAILED CLOSED: DISM health result was not recognized as healthy."
}
function Assert-RetainedProvisionedApps([object[]]$Apps,[string[]]$Required,[string]$Label,[System.Collections.Generic.List[string]]$Actions) {
    $missing=[System.Collections.Generic.List[string]]::new()
    foreach($req in $Required) {
        $found=$false
        foreach($app in $Apps) {
            if(([string]$app.DisplayName).IndexOf($req,[StringComparison]::OrdinalIgnoreCase) -ge 0) {
                $found=$true
                break
            }
        }
        if(-not $found) { [void]$missing.Add($req) }
    }
    if($missing.Count -gt 0) {
        throw ("$Label failed; missing provisioned app(s): " + ($missing -join ', '))
    }
    [void]$Actions.Add("$Label PASSED: $($Required -join ', ')")
}

function Get-MatchingProvisionedApps([object[]]$Apps,[string[]]$Patterns) {
    $hits=[System.Collections.Generic.List[object]]::new()
    foreach($app in $Apps) {
        foreach($pat in $Patterns) {
            if(([string]$app.DisplayName).IndexOf($pat,[StringComparison]::OrdinalIgnoreCase) -ge 0) {
                [void]$hits.Add($app); break
            }
        }
    }
    return @($hits)
}
function Assert-NoDeniedProvisionedApps([object[]]$Apps,[string[]]$Denied,[string]$Label,[System.Collections.Generic.List[string]]$Actions) {
    $hits=Get-MatchingProvisionedApps $Apps $Denied
    if($hits.Count -gt 0) {
        $names=@($hits | ForEach-Object { $_.DisplayName } | Sort-Object -Unique)
        throw ("$Label failed; disabled provisioned app(s) survived: " + ($names -join ', '))
    }
    [void]$Actions.Add("$Label PASSED")
}
function Attempt-RemoveProvisionedAppPatterns([string]$Mount,[string[]]$Patterns,[System.Collections.Generic.List[string]]$Actions,[System.Collections.Generic.List[string]]$Warnings) {
    foreach($pat in $Patterns) {
        $current=@(Get-AppxProvisionedPackage -Path $Mount -ErrorAction Stop)
        $targets=@($current | Where-Object { ([string]$_.DisplayName).IndexOf($pat,[StringComparison]::OrdinalIgnoreCase) -ge 0 })
        foreach($app in $targets) {
            Write-Host "[REMOVE STAGING-ONLY APP] $($app.DisplayName)" -ForegroundColor Yellow
            $removeError=$null
            try { Remove-AppxProvisionedPackage -Path $Mount -PackageName $app.PackageName -ErrorAction Stop | Out-Null }
            catch { $removeError=$_.Exception.Message }
            $verify=@(Get-AppxProvisionedPackage -Path $Mount -ErrorAction Stop | Where-Object { $_.PackageName -eq $app.PackageName -or $_.DisplayName -eq $app.DisplayName })
            if($verify.Count -eq 0) {
                [void]$Actions.Add("APPX STAGING REMOVE CONFIRMED: $($app.DisplayName) :: $($app.PackageName)")
            } else {
                $detail=if($removeError){$removeError}else{'removal command returned but package is still provisioned'}
                [void]$Warnings.Add("APPX STAGING RESIDUE: $($app.DisplayName) :: $($app.PackageName) :: $detail")
            }
        }
    }
}
function Write-HandoffReport([string]$Path,[string[]]$Patterns,[object[]]$Apps,[object[]]$Caps,[object[]]$Pkgs,[object[]]$Features) {
    $hits=[System.Collections.Generic.List[string]]::new()
    foreach($pat in $Patterns) {
        foreach($x in @($Apps | Where-Object { ([string]$_.DisplayName).IndexOf($pat,[StringComparison]::OrdinalIgnoreCase) -ge 0 })) { [void]$hits.Add("APPX :: $pat :: $($x.DisplayName) :: $($x.PackageName)") }
        foreach($x in @($Caps | Where-Object { ([string]$_.Name).IndexOf($pat,[StringComparison]::OrdinalIgnoreCase) -ge 0 })) { [void]$hits.Add("CAPABILITY :: $pat :: $($x.Name) :: $($x.State)") }
        foreach($x in @($Pkgs | Where-Object { ([string]$_.PackageName).IndexOf($pat,[StringComparison]::OrdinalIgnoreCase) -ge 0 })) { [void]$hits.Add("PACKAGE :: $pat :: $($x.PackageName) :: $($x.PackageState)") }
        foreach($x in @($Features | Where-Object { ([string]$_.FeatureName).IndexOf($pat,[StringComparison]::OrdinalIgnoreCase) -ge 0 })) { [void]$hits.Add("FEATURE :: $pat :: $($x.FeatureName) :: $($x.State)") }
    }
    @('BlueLite MAX_PRE v2.0 FULL OFFLINE SCRIPT-DEBLOAT handoff','Presence is evidence for later offline scripting analysis, not permission for manual WinSxS deletion.','',($hits | Sort-Object -Unique)) | Set-Content -LiteralPath $Path -Encoding UTF8
}

$mounted=$false
$mountDir=$null
$actions=[System.Collections.Generic.List[string]]::new()
$warnings=[System.Collections.Generic.List[string]]::new()
$healthLog=[System.Collections.Generic.List[string]]::new()

try {
    if (-not (Test-Path -LiteralPath $WimPath)) { throw "Final install.wim not found: $WimPath" }
    $WimPath=(Resolve-Path -LiteralPath $WimPath).Path
    foreach ($p in @($CapabilityPatternsFile,$FeatureDisableOnlyFile,$FeatureRemovePayloadFile,$PackagePatternsFile,$CustomAppsListPath,$ProfilePath,$ComponentWatchlistFile,$RequiredStagingAppIdentitiesFile,$RequiredFinalAppIdentitiesFile,$StagingOnlyAppPatternsFile,$ReleaseForbiddenAppPatternsFile,$OfflineHandoffPatternsFile,$ProtectedFloorFile)) {
        if (-not (Test-Path -LiteralPath $p)) { throw "Required BlueLite input not found: $p" }
    }

    $profile=Read-SimpleIni $ProfilePath
    $healthGate=Get-IniInt $profile 'HealthGate' 1
    $runScanHealth=Get-IniInt $profile 'RunScanHealth' 0
    $keepDefender=Get-IniInt $profile 'KeepDefenderPayload' 1
    $keepWU=Get-IniInt $profile 'KeepWindowsUpdateServicing' 1
    $disableSearch=Get-IniInt $profile 'DisableSearchIndexing' 1
    $disableSysMain=Get-IniInt $profile 'DisableSysMain' 1
    $doSvcStart=Get-IniInt $profile 'DeliveryOptimizationStart' 3
    $strictReleaseApps=Get-IniInt $profile 'StrictReleaseForbiddenAppGate' 0
    $runCleanup=Get-IniInt $profile 'RunStartComponentCleanup' 1
    $runResetBase=Get-IniInt $profile 'RunResetBase' 0
    $allowedFamilies=if($profile.ContainsKey('AllowedBuildFamilies')){([string]$profile['AllowedBuildFamilies']).Split(',') | ForEach-Object {$_.Trim()} | Where-Object {$_}}else{@('26300')}
    $compression=if($profile.ContainsKey('FinalCompression')){[string]$profile['FinalCompression']}else{'max'}
    if ($compression -notin @('max','fast','none')) { throw "Unsupported FinalCompression: $compression" }

    if ([IO.Path]::IsPathRooted($WorkDirectory)) { $WorkDirectory=[IO.Path]::GetFullPath($WorkDirectory) }
    else { $WorkDirectory=[IO.Path]::GetFullPath((Join-Path (Get-Location).Path $WorkDirectory)) }
    $mountDir=Join-Path $WorkDirectory 'Mount'
    $exportWim=Join-Path $WorkDirectory 'install.compact.wim'
    if (Test-Path -LiteralPath $WorkDirectory) {
        $left=@(Get-ChildItem -LiteralPath $WorkDirectory -Force -ErrorAction SilentlyContinue)
        if ($left.Count -gt 0) { throw "Work directory is not empty: $WorkDirectory" }
    } else { New-Item -ItemType Directory -Path $WorkDirectory -Force | Out-Null }
    New-Item -ItemType Directory -Path $mountDir -Force | Out-Null

    $logDir=Split-Path -Parent ([IO.Path]::GetFullPath($LogPath))
    if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

    [string[]]$capPatterns=Read-PatternFile $CapabilityPatternsFile
    [string[]]$featDisable=Read-PatternFile $FeatureDisableOnlyFile
    [string[]]$featRemove=Read-PatternFile $FeatureRemovePayloadFile
    [string[]]$pkgPatterns=Read-PatternFile $PackagePatternsFile
    [string[]]$watchPatterns=Read-PatternFile $ComponentWatchlistFile
    [string[]]$requiredStagingApps=Read-PatternFile $RequiredStagingAppIdentitiesFile
    [string[]]$requiredFinalApps=Read-PatternFile $RequiredFinalAppIdentitiesFile
    [string[]]$stagingOnlyApps=Read-PatternFile $StagingOnlyAppPatternsFile
    [string[]]$releaseForbiddenApps=Read-PatternFile $ReleaseForbiddenAppPatternsFile
    [string[]]$offlineHandoff=Read-PatternFile $OfflineHandoffPatternsFile
    [string[]]$protectedFloor=Read-PatternFile $ProtectedFloorFile
    [string[]]$appDeny=Get-DeniedAppIdentities $CustomAppsListPath

    # Profile invariants: the common v1.0 base must remain capable of a later Defender ON
    # variant and must retain Windows Update/CBS servicing infrastructure.
    if ($keepDefender -ne 0) {
        foreach ($p in @($capPatterns + $pkgPatterns + $featRemove)) {
            if ($p -match '(?i)Defender|SecHealthUI|WinDefend|WdFilter|WdNis|Sense') { throw "Profile invariant: Defender core removal pattern is forbidden in common base: $p" }
        }
    }
    if ($keepWU -ne 0) {
        foreach ($p in @($capPatterns + $pkgPatterns + $featRemove)) {
            if ($p -match '(?i)ServicingStack|RollupFix|WindowsUpdate|UpdateOrchestrator|WaaSMedic') { throw "Profile invariant: Windows servicing removal pattern is forbidden: $p" }
        }
    }

    Invoke-Dism @('/Mount-Image',"/ImageFile:$WimPath","/Index:$Index","/MountDir:$mountDir") 'Mount final install.wim'
    if (-not (Test-Path -LiteralPath (Join-Path $mountDir 'Windows'))) { throw "Mounted Windows root missing: $mountDir" }
    $mounted=$true

    # READ-ONLY build identity gate from the OFFLINE SOFTWARE hive.
    # No BlueLite mutation is allowed before baseline/pending/health/protected-floor gates pass.
    $softHive=Join-Path $mountDir 'Windows\System32\Config\SOFTWARE'
    Invoke-Reg @('load','HKLM\BlueLiteSOFTWARE',$softHive) 'Load offline SOFTWARE hive for build identity' | Out-Null
    try {
        $cv='HKLM\BlueLiteSOFTWARE\Microsoft\Windows NT\CurrentVersion'
        $currentBuild=Get-RegRawValue $cv 'CurrentBuildNumber'
        if (-not $currentBuild) { $currentBuild=Get-RegRawValue $cv 'CurrentBuild' }
        $ubr=Convert-RegDword (Get-RegRawValue $cv 'UBR')
        if (-not $currentBuild -or $null -eq $ubr) { throw 'Could not read offline build identity.' }
        $actualBuild="$currentBuild.$ubr"
        if ($currentBuild -notin $allowedFamilies) { throw "REFUSED: image family $currentBuild is outside AllowedBuildFamilies=$($allowedFamilies -join ',')." }

        if ($ExpectedBuildFile -and (Test-Path -LiteralPath $ExpectedBuildFile)) {
            $expectedJson=Get-Content -LiteralPath $ExpectedBuildFile -Raw | ConvertFrom-Json
            $expect=[string]$expectedJson.UUP_BUILD
            $family=[string]$expectedJson.BUILD_FAMILY
            if ($family -and $currentBuild -ne $family) { throw "REFUSED: mounted image family $currentBuild does not match configured Germanium family $family." }
            if ($expect -and $expect -ne $actualBuild) { throw "REFUSED: resolver selected $expect but reconstructed WIM reports $actualBuild." }
        }
        [void]$actions.Add("BUILD VERIFIED: $actualBuild")
    }
    finally {
        [GC]::Collect(); [GC]::WaitForPendingFinalizers(); Start-Sleep -Milliseconds 100
        Invoke-Reg @('unload','HKLM\BlueLiteSOFTWARE') 'Unload offline SOFTWARE after build identity' | Out-Null
    }

    # TRUE PRE-MUTATION BASELINE / GATES.
    Save-Inventory $mountDir (Join-Path $logDir "Inventory-$actualBuild-before.json") 'before' $actualBuild

    $preApps=@(Get-AppxProvisionedPackage -Path $mountDir -ErrorAction Stop)
    Assert-RetainedProvisionedApps $preApps $requiredStagingApps 'PRE-DEBLOAT STAGING APPX GATE' $actions

    $pendingPre=@(Get-WindowsPackage -Path $mountDir -ErrorAction Stop | Where-Object { $_.PackageState -match 'Pending' })
    if ($pendingPre.Count -gt 0) { throw "PRE-MUTATION pending gate failed: $($pendingPre.Count) pending package state(s)." }
    [void]$actions.Add('PRE-MUTATION PENDING GATE PASSED: 0')

    if ($healthGate -ne 0) { Assert-HealthyStore $mountDir 'Initial CheckHealth gate' $healthLog; [void]$actions.Add('INITIAL COMPONENT STORE HEALTHY') }
    Assert-ProtectedFloor $mountDir $protectedFloor 'PRE-DEBLOAT VM/NETWORK/STORAGE FLOOR' $actions

    # MUTATION STARTS HERE: offline SOFTWARE policy layer only.
    Invoke-Reg @('load','HKLM\BlueLiteSOFTWARE',$softHive) 'Load offline SOFTWARE hive for policy mutation' | Out-Null
    try {
        Invoke-Reg @('add','HKLM\BlueLiteSOFTWARE\Policies\Microsoft\Windows\System','/v','EnableSmartScreen','/t','REG_DWORD','/d','0','/f') 'Disable SmartScreen policy' | Out-Null
        Invoke-Reg @('add','HKLM\BlueLiteSOFTWARE\Policies\Microsoft\Windows\System','/v','ShellSmartScreenLevel','/t','REG_SZ','/d','Off','/f') 'Set SmartScreen level Off' | Out-Null
        Invoke-Reg @('add','HKLM\BlueLiteSOFTWARE\Policies\Microsoft\Windows\WindowsCopilot','/v','TurnOffWindowsCopilot','/t','REG_DWORD','/d','1','/f') 'Disable Copilot policy' | Out-Null
        Invoke-Reg @('add','HKLM\BlueLiteSOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Policies\Windows\Widgets','/v','AllowWidgets','/t','REG_DWORD','/d','0','/f') 'Disable Widgets policy' | Out-Null
        Invoke-Reg @('add','HKLM\BlueLiteSOFTWARE\Microsoft\Windows\Windows Error Reporting','/v','Disabled','/t','REG_DWORD','/d','1','/f') 'Disable WER' | Out-Null
        Invoke-Reg @('add','HKLM\BlueLiteSOFTWARE\Policies\Microsoft\Windows\DataCollection','/v','AllowTelemetry','/t','REG_DWORD','/d','0','/f') 'Minimize telemetry policy' | Out-Null
        Invoke-Reg @('add','HKLM\BlueLiteSOFTWARE\Policies\Microsoft\Windows\CloudContent','/v','DisableWindowsConsumerFeatures','/t','REG_DWORD','/d','1','/f') 'Disable consumer features' | Out-Null
        Invoke-Reg @('add','HKLM\BlueLiteSOFTWARE\Policies\Microsoft\Windows\CloudContent','/v','DisableTailoredExperiencesWithDiagnosticData','/t','REG_DWORD','/d','1','/f') 'Disable tailored experiences' | Out-Null
        [void]$actions.Add('OFFLINE SOFTWARE POLICIES APPLIED')
    }
    finally {
        [GC]::Collect(); [GC]::WaitForPendingFinalizers(); Start-Sleep -Milliseconds 100
        Invoke-Reg @('unload','HKLM\BlueLiteSOFTWARE') 'Unload offline SOFTWARE after policy mutation' | Out-Null
    }

    # Service policy: reg.exe only against OFFLINE SYSTEM. Do not disable WU/BITS/TrustedInstaller.
    $sysHive=Join-Path $mountDir 'Windows\System32\Config\SYSTEM'
    Invoke-Reg @('load','HKLM\BlueLiteSYSTEM',$sysHive) 'Load offline SYSTEM hive' | Out-Null
    try {
        $cur=Convert-RegDword (Get-RegRawValue 'HKLM\BlueLiteSYSTEM\Select' 'Current')
        if ($null -eq $cur) { throw 'Could not read offline SYSTEM Select\Current.' }
        $controlSet=('ControlSet{0:D3}' -f [int]$cur)
        $disable=@('DiagTrack','dmwappushservice','WerSvc','RemoteRegistry','RemoteAccess','WMPNetworkSvc','MapsBroker')
        if ($disableSearch -ne 0) { $disable += 'WSearch' }
        if ($disableSysMain -ne 0) { $disable += 'SysMain' }
        foreach ($svc in $disable | Select-Object -Unique) {
            $key="HKLM\BlueLiteSYSTEM\$controlSet\Services\$svc"
            & reg.exe query $key *> $null
            if ($LASTEXITCODE -eq 0) {
                Invoke-Reg @('add',$key,'/v','Start','/t','REG_DWORD','/d','4','/f') "Disable service $svc" | Out-Null
                [void]$actions.Add("SERVICE DISABLED: $svc")
            }
        }
        $doKey="HKLM\BlueLiteSYSTEM\$controlSet\Services\DoSvc"
        & reg.exe query $doKey *> $null
        if ($LASTEXITCODE -eq 0) {
            Invoke-Reg @('add',$doKey,'/v','Start','/t','REG_DWORD','/d',[string]$doSvcStart,'/f') 'Set DoSvc start policy' | Out-Null
            [void]$actions.Add("SERVICE START: DoSvc=$doSvcStart")
        }
    }
    finally {
        [GC]::Collect(); [GC]::WaitForPendingFinalizers(); Start-Sleep -Milliseconds 100
        Invoke-Reg @('unload','HKLM\BlueLiteSYSTEM') 'Unload offline SYSTEM hive' | Out-Null
    }

    # AppX staging cleanup. Every removal is re-queried before it can be logged as success.
    # DesktopAppInstaller is known to resist standard offline removal on this baseline;
    # residue is handed to the later full offline script-debloat queue instead of being falsely reported as removed.
    Attempt-RemoveProvisionedAppPatterns $mountDir $stagingOnlyApps $actions $warnings

    # Remove all ordinary user-facing Apps disabled by the generated CustomAppsList.
    # Frameworks are not inferred as bloat here.
    $prov=@(Get-AppxProvisionedPackage -Path $mountDir -ErrorAction Stop)
    foreach ($app in $prov) {
        $name=[string]$app.DisplayName
        if (-not (Match-Any $name $appDeny)) { continue }
        Write-Host "[REMOVE PROVISIONED APP] $name" -ForegroundColor Yellow
        try {
            Remove-AppxProvisionedPackage -Path $mountDir -PackageName $app.PackageName -ErrorAction Stop | Out-Null
            [void]$actions.Add("APPX REMOVE: $name :: $($app.PackageName)")
        } catch { [void]$warnings.Add("APPX SKIP: $name :: $($_.Exception.Message)") }
    }

    $caps=@(Get-WindowsCapability -Path $mountDir -ErrorAction Stop)
    foreach ($cap in $caps) {
        if (-not (Match-Any $cap.Name $capPatterns) -or $cap.State -eq 'NotPresent') { continue }
        Write-Host "[REMOVE CAPABILITY] $($cap.Name) [$($cap.State)]" -ForegroundColor Yellow
        try {
            Invoke-Dism @('/English',"/Image:$mountDir",'/Remove-Capability',"/CapabilityName:$($cap.Name)") "Remove capability $($cap.Name)"
            [void]$actions.Add("CAPABILITY REMOVE: $($cap.Name)")
        } catch { [void]$warnings.Add("CAPABILITY SKIP: $($cap.Name) :: $($_.Exception.Message)") }
    }

    $features=@(Get-WindowsOptionalFeature -Path $mountDir -ErrorAction Stop)
    foreach ($feature in $features) {
        if ($feature.State -notmatch '^Enabled') { continue }
        if (Match-Any $feature.FeatureName $featRemove) {
            try {
                Disable-WindowsOptionalFeature -Path $mountDir -FeatureName $feature.FeatureName -Remove -NoRestart -ErrorAction Stop | Out-Null
                [void]$actions.Add("FEATURE DISABLE+REMOVE: $($feature.FeatureName)")
            } catch { [void]$warnings.Add("FEATURE REMOVE SKIP: $($feature.FeatureName) :: $($_.Exception.Message)") }
        }
        elseif (Match-Any $feature.FeatureName $featDisable) {
            try {
                Disable-WindowsOptionalFeature -Path $mountDir -FeatureName $feature.FeatureName -NoRestart -ErrorAction Stop | Out-Null
                [void]$actions.Add("FEATURE DISABLE: $($feature.FeatureName)")
            } catch { [void]$warnings.Add("FEATURE DISABLE SKIP: $($feature.FeatureName) :: $($_.Exception.Message)") }
        }
    }

    $allPkgs=@(Get-WindowsPackage -Path $mountDir -ErrorAction Stop)
    foreach ($pattern in $pkgPatterns) {
        $pkgs=@($allPkgs | Where-Object { $_.PackageName.IndexOf($pattern,[StringComparison]::OrdinalIgnoreCase) -ge 0 } | Sort-Object PackageName -Descending)
        foreach ($pkg in $pkgs) {
            # MAX_PRE package fallback is intentionally narrower than capability/feature removal.
            # Only already-Superseded rows are eligible here; current Installed/Staged packages
            # remain available to the later topology-aware universal script-debloat phase.
            if ([string]$pkg.PackageState -ne 'Superseded') { continue }
            Write-Host "[REMOVE SUPERSEDED PACKAGE] $($pkg.PackageName) [$($pkg.PackageState)]" -ForegroundColor Yellow
            try {
                Remove-WindowsPackage -Path $mountDir -PackageName $pkg.PackageName -NoRestart -ErrorAction Stop | Out-Null
                [void]$actions.Add("SUPERSEDED PACKAGE REMOVE: $($pkg.PackageName)")
            } catch { [void]$warnings.Add("SUPERSEDED PACKAGE SKIP: $($pkg.PackageName) :: $($_.Exception.Message)") }
        }
    }

    $pending=@(Get-WindowsPackage -Path $mountDir -ErrorAction Stop | Where-Object { $_.PackageState -match 'Pending' })
    if ($pending.Count -gt 0) { throw "Pre-cleanup gate found $($pending.Count) pending package state(s)." }
    if ($runResetBase -ne 0) { throw 'MAX_PRE v2.0 forbids ResetBase before the full offline script-debloat phase is complete.' }
    if ($runCleanup -ne 0) { Invoke-Dism @('/English',"/Image:$mountDir",'/Cleanup-Image','/StartComponentCleanup') 'Deliberate StartComponentCleanup (ResetBase deferred)' }

    $pending=@(Get-WindowsPackage -Path $mountDir -ErrorAction Stop | Where-Object { $_.PackageState -match 'Pending' })
    if ($pending.Count -gt 0) { throw "Final gate found $($pending.Count) pending package state(s); refusing to commit." }

    if ($runScanHealth -ne 0) {
        $scan=Invoke-DismCapture @('/English',"/Image:$mountDir",'/Cleanup-Image','/ScanHealth') 'Final ScanHealth'
        foreach ($l in $scan) { [void]$healthLog.Add("[Final ScanHealth] $l") }
    }
    if ($healthGate -ne 0) { Assert-HealthyStore $mountDir 'Final CheckHealth gate' $healthLog; [void]$actions.Add('FINAL COMPONENT STORE HEALTHY') }
    Assert-ProtectedFloor $mountDir $protectedFloor 'POST-PREDEBLOAT VM/NETWORK/STORAGE FLOOR' $actions

    # Report watchlist matches without removing them.
    $watchHits=[System.Collections.Generic.List[string]]::new()
    $postPkgs=@(Get-WindowsPackage -Path $mountDir -ErrorAction Stop)
    $postCaps=@(Get-WindowsCapability -Path $mountDir -ErrorAction Stop)
    $postApps=@(Get-AppxProvisionedPackage -Path $mountDir -ErrorAction Stop)
    $postFeatures=@(Get-WindowsOptionalFeature -Path $mountDir -ErrorAction Stop)

    # Post-predebloat AppX policy: four retained apps must exist; every app disabled by CustomAppsList
    # must be absent. Release-forbidden staging residue is reported for the later full offline script-debloat phase and can be
    # made fail-closed by setting StrictReleaseForbiddenAppGate=1.
    Assert-RetainedProvisionedApps $postApps $requiredFinalApps 'POST-DEBLOAT FINAL APPX GATE' $actions
    Assert-NoDeniedProvisionedApps $postApps $appDeny 'POST-DEBLOAT DISABLED APPX ABSENCE GATE' $actions
    $forbiddenHits=Get-MatchingProvisionedApps $postApps $releaseForbiddenApps
    $residuePath=Join-Path $logDir "ReleaseForbiddenAppResidues-$actualBuild.txt"
    if($forbiddenHits.Count -gt 0) {
        @('BlueLite MAX_PRE v2.0 release-forbidden AppX residues (post-predebloat)',($forbiddenHits | ForEach-Object { "$($_.DisplayName) :: $($_.PackageName)" } | Sort-Object -Unique)) | Set-Content -LiteralPath $residuePath -Encoding UTF8
        $names=@($forbiddenHits | ForEach-Object { $_.DisplayName } | Sort-Object -Unique)
        [void]$warnings.Add("RELEASE-FORBIDDEN APPX RESIDUE -> FULL OFFLINE SCRIPT QUEUE: $($names -join ', ')")
        if($strictReleaseApps -ne 0) { throw ("Strict release AppX gate failed: " + ($names -join ', ')) }
    } else {
        @('BlueLite MAX_PRE v2.0 release-forbidden AppX residues (post-predebloat)','NONE') | Set-Content -LiteralPath $residuePath -Encoding UTF8
        [void]$actions.Add('RELEASE-FORBIDDEN APPX GATE CLEAN')
    }

    Write-HandoffReport (Join-Path $logDir "OfflineScript-Handoff-$actualBuild.txt") $offlineHandoff $postApps $postCaps $postPkgs $postFeatures

    foreach ($w in $watchPatterns) {
        foreach ($x in @($postPkgs | Where-Object { $_.PackageName.IndexOf($w,[StringComparison]::OrdinalIgnoreCase) -ge 0 })) { [void]$watchHits.Add("PACKAGE :: $w :: $($x.PackageName) :: $($x.PackageState)") }
        foreach ($x in @($postCaps | Where-Object { $_.Name.IndexOf($w,[StringComparison]::OrdinalIgnoreCase) -ge 0 })) { [void]$watchHits.Add("CAPABILITY :: $w :: $($x.Name) :: $($x.State)") }
        foreach ($x in @($postApps | Where-Object { $_.DisplayName.IndexOf($w,[StringComparison]::OrdinalIgnoreCase) -ge 0 })) { [void]$watchHits.Add("APPX :: $w :: $($x.DisplayName)") }
    }
    $watchHits | Sort-Object -Unique | Set-Content -LiteralPath (Join-Path $logDir "ComponentWatch-$actualBuild.txt") -Encoding UTF8

    Save-Inventory $mountDir (Join-Path $logDir "Inventory-$actualBuild-after.json") 'after' $actualBuild
    $healthLog | Set-Content -LiteralPath (Join-Path $logDir "Health-$actualBuild.txt") -Encoding UTF8

    Invoke-Dism @('/Unmount-Image',"/MountDir:$mountDir",'/Commit') 'Commit and unmount final WIM'
    $mounted=$false

    if (Test-Path -LiteralPath $exportWim) { Remove-Item -LiteralPath $exportWim -Force }
    Invoke-Dism @('/Export-Image',"/SourceImageFile:$WimPath","/SourceIndex:$Index","/DestinationImageFile:$exportWim","/Compress:$compression",'/CheckIntegrity') "Re-export install.wim /Compress:$compression"
    $oldSize=(Get-Item -LiteralPath $WimPath).Length
    $newSize=(Get-Item -LiteralPath $exportWim).Length
    if ($newSize -le 0) { throw 'Compact export produced an empty WIM.' }
    $exportInfo=Invoke-DismCapture @('/English','/Get-WimInfo',"/WimFile:$exportWim","/Index:$Index") 'Validate compact export identity'
    if (($exportInfo -join "`n") -notmatch [regex]::Escape($actualBuild)) { throw "Compact export identity gate failed: expected build $actualBuild." }
    Move-Item -LiteralPath $exportWim -Destination $WimPath -Force
    $finalHash=(Get-FileHash -LiteralPath $WimPath -Algorithm SHA256).Hash.ToUpperInvariant()

    @(
        'BlueLite v1.0 MAX_PRE v2.0 PRE-DEBLOAT WIM',
        "WIM: $WimPath", "Index: $Index", "Build: $actualBuild", "Profile: $($profile['Profile'])",
        "Original bytes before compact export: $oldSize", "Compacted bytes: $newSize", "Saved bytes: $($oldSize-$newSize)",
        "Final WIM SHA256: $finalHash",
        "Actions: $($actions.Count)", "Warnings/skips: $($warnings.Count)",
        '', 'ACTIONS:', $actions,
        '', 'WARNINGS / CBS SKIPS:', $warnings,
        '', "Health log: $(Join-Path $logDir "Health-$actualBuild.txt")",
        "Before inventory: $(Join-Path $logDir "Inventory-$actualBuild-before.json")",
        "After inventory: $(Join-Path $logDir "Inventory-$actualBuild-after.json")",
        "Release-forbidden residues: $(Join-Path $logDir "ReleaseForbiddenAppResidues-$actualBuild.txt")",
        "Offline script handoff: $(Join-Path $logDir "OfflineScript-Handoff-$actualBuild.txt")"
    ) | Set-Content -LiteralPath $LogPath -Encoding UTF8

    Remove-Item -LiteralPath $WorkDirectory -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] BlueLite MAX_PRE v2.0 pre-debloat completed. Actions: $($actions.Count), skips: $($warnings.Count)" -ForegroundColor Green
    Write-Host "[OK] WIM compacted: $([math]::Round($oldSize/1GB,2)) GB -> $([math]::Round($newSize/1GB,2)) GB" -ForegroundColor Green
    exit 0
}
catch {
    $msg=$_.Exception.ToString()
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    try {
        @('BlueLite MAX_PRE v2.0 PRE-DEBLOAT FAILURE',$msg,'','ACTIONS BEFORE FAILURE:',$actions,'','WARNINGS BEFORE FAILURE:',$warnings,'','HEALTH OUTPUT:',$healthLog) | Set-Content -LiteralPath $LogPath -Encoding UTF8
    } catch {}
    if ($mounted -and $mountDir -and (Test-Path -LiteralPath (Join-Path $mountDir 'Windows'))) {
        Write-Host '[INFO] Failure occurred while WIM was mounted; discarding ALL BlueLite mount changes.' -ForegroundColor Yellow
        & dism.exe /Unmount-Image "/MountDir:$mountDir" /Discard
    }
    exit 1
}
