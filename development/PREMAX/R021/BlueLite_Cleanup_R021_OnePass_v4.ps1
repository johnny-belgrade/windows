#requires -Version 7.0
<#
 BlueLite R021 | Retired E2E + duplicate-payload cleanup v4
 Operator-local ONLY; default Run mode removes positively identified files.
 A single invocation scans, plans, hashes, deletes, independently verifies
 EACH deletion in a fresh PowerShell process, and packs the evidence ZIP.
 No directories, original UUP/vendor archives, source scripts, logs, or GOLDEN
 26300.9818 R004 files are ever deletion targets.
 Save to C:\work\scripts; outputs ONLY to C:\work\logs.
 No hard-coded Windows version is used to mutate the OS. This is disk-artifact
 lifecycle cleanup, never a Windows-image-servicing operation.
#>
[CmdletBinding()]
param(
    [ValidateSet('Run','DryRun','VerifyStep','VerifyFinal')]
    [string]$Mode = 'Run',
    [string]$ReceiptPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Policy = 'BlueLite_R021_RetiredGeneratedArtifacts_20261106'
$Roots = @('C:\work','C:\BLR20R2F5')
$LogRoot = 'C:\work\logs'
$Limit = [int64]100000000
$GoldenRoot = 'C:\work\26300.9818-UUP-MAX_PRE_26300_v4'
$GoldenWim = Join-Path $GoldenRoot 'install.wim'
$GoldenIso = Join-Path $GoldenRoot '26300.9818.261025-0959.26H2_GE_RELEASE_SVC_PROD3_CLIENTPRO_OEMRET_X64FRE_EN-US.ISO'
$ExpectedGoldenWimBytes = [int64]5736092221
$ExpectedGoldenIsoBytes = [int64]6822354944
$S41Log = 'C:\work\logs\BlueLite_Storage_S41_26300.9711_ExactFourWimDeletion.txt'
$R20Log = 'C:\work\logs\BlueLite_26300_9807_WebViewEqualCompress_R20R2F6.txt'
$StageProofs = @(
    'C:\work\logs\BlueLite_Storage_S41_26300.9711_ExactFourWimDeletion.txt',
    'C:\work\logs\BlueLite_MAXPRE_FodMetadata_26300.9711_ExportCompare_R12.txt'
)
$ProtectedExtensions = @('.zip','.7z','.rar','.tar','.gz','.tgz','.zst','.xz',
 '.txt','.md','.log','.etl','.evtx','.csv','.tsv','.json','.jsonl','.xml',
 '.ps1','.psm1','.psd1','.cmd','.bat','.ini','.cfg','.yml','.yaml','.toml',
 '.pdf','.docx','.xlsx','.html','.htm','.reg','.manifest','.exe','.dll',
 '.msi','.msix','.appx','.msixbundle','.appxbundle')
$ProtectedDirNames = @('logs','BlueLite_Logs','scripts','backup','backups','evidence',
 'analyses','analysis','regression','regressions','uup-history','premax-work',
 'library','checkpoints','checkpoint','mount','mounts','documents','docs')

function Hash-File([string]$Path) {
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()
}
function Within([string]$Path,[string]$Parent) {
    $p = [IO.Path]::GetFullPath($Path)
    $prefix = [IO.Path]::GetFullPath($Parent).TrimEnd('\') + '\'
    $p.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)
}
function Safe-Path([string]$Path) {
    if(-not ((Within $Path $Roots[0]) -or (Within $Path $Roots[1]))) {return $false}
    $f=Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if(($f.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {return $false}
    $d=$f.DirectoryName
    while(-not [string]::IsNullOrEmpty($d)) {
        $item=Get-Item -LiteralPath $d -Force -ErrorAction Stop
        if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {return $false}
        if($d -ieq $Roots[0] -or $d -ieq $Roots[1]) {return $true}
        $up=[IO.Path]::GetDirectoryName($d)
        if($up -eq $d) {break}
        $d=$up
    }
    return $false
}
function Write-Immutable([string]$Path,[string]$Contents) {
    $fs=[IO.FileStream]::new($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
    try {
        $w=[IO.StreamWriter]::new($fs,[Text.UTF8Encoding]::new($false))
        try {$w.Write($Contents);$w.Flush()} finally {$w.Dispose()}
    } finally {$fs.Dispose()}
}
function Quote-Csv([AllowNull()][object]$Value) {
    '"' + ([string]$Value).Replace('"','""').Replace("`r",' ').Replace("`n",' ') + '"'
}
function Check-Golden {
    if(-not [IO.File]::Exists($GoldenWim) -or -not [IO.File]::Exists($GoldenIso)) {
        throw 'GOLDEN_SOURCE_MISSING_NO_CLEANUP'
    }
    if(([IO.FileInfo]::new($GoldenWim)).Length -ne $ExpectedGoldenWimBytes -or
       ([IO.FileInfo]::new($GoldenIso)).Length -ne $ExpectedGoldenIsoBytes) {
        throw 'GOLDEN_SIZE_DRIFT_NO_CLEANUP'
    }
}
function Check-SafeSystem {
    $active=@(Get-Process -ErrorAction SilentlyContinue | Where-Object {
        $_.ProcessName -match '(?i)^(dism|dismhost|wimlib.*|ntlite|aria2c|oscdimg|xorriso|vbox.*|virtualbox.*|vmware.*|7z|7za)$'
    })
    if($active.Count -gt 0) {
        throw ('ACTIVE_IMAGE_OR_DOWNLOAD_PROCESS '+(@($active|ForEach-Object{$_.ProcessName}) -join ','))
    }
    $output=@(& dism.exe /English /Get-MountedWimInfo 2>&1)
    $code=$LASTEXITCODE
    $text=($output|ForEach-Object{[string]$_}) -join "`n"
    if($code -ne 0 -or -not $text.Contains('No mounted images found.')) {
        throw ('MOUNT_STATE_NOT_PROVEN_EMPTY code='+$code)
    }
}
function Evidence-Present([string]$Path,[string[]]$Needles) {
    if(-not [IO.File]::Exists($Path)) {return $false}
    try {
        $info=[IO.FileInfo]::new($Path)
        if($info.Length -lt 80 -or $info.Length -gt 40000000) {return $false}
        $data=[IO.File]::ReadAllText($Path)
        foreach($needle in $Needles) {
            if(-not $data.Contains($needle)) {return $false}
        }
        return $true
    } catch {return $false}
}
function Check-Unlocked([string]$Path) {
    try {
        $f=[IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::None)
        $f.Dispose()
        return $true
    } catch {return $false}
}
function Is-OldEnough([IO.FileInfo]$File,[int]$Days) {
    $since=[datetime]::UtcNow.AddDays(-$Days)
    ($File.LastWriteTimeUtc -lt $since -and $File.CreationTimeUtc -lt $since)
}
function Exact-File([string]$A,[string]$B) {
    [string]::Equals($A,$B,[StringComparison]::OrdinalIgnoreCase)
}
function Protected-Reason([IO.FileInfo]$F) {
    $p=$F.FullName
    if($ProtectedExtensions -contains $F.Extension.ToLowerInvariant()) {
        return 'KEEP_ARCHIVE_SOURCE_SCRIPT_OR_EVIDENCE'
    }
    foreach($part in ($p -split '\\')) {
        if($ProtectedDirNames -contains $part) {return 'KEEP_EVIDENCE_OR_CHECKPOINT_TREE'}
    }
    if((Within $p $GoldenRoot) -or $p -match '(?i)\\BlueLite_(Stage_v|PREMAX_Factory|PREMAX_Auto)') {
        return 'KEEP_GOLDEN_OR_ACTIVE_PREMAX'
    }
    if($p -match '(?i)\\(?:Original|GOLDEN|source-archive|source_original)\\') {
        return 'KEEP_ORIGINAL_SOURCE'
    }
    return ''
}

# Single-purpose independent verifier, always launched in a FRESH PS7 process.
if($Mode -eq 'VerifyStep' -or $Mode -eq 'VerifyFinal') {
    if([string]::IsNullOrWhiteSpace($ReceiptPath) -or -not (Within $ReceiptPath $LogRoot)) {
        throw 'VERIFY_RECEIPT_OUTSIDE_LOG_ROOT'
    }
    $r=Get-Content -LiteralPath $ReceiptPath -Raw -Encoding utf8 | ConvertFrom-Json
    $verifyPath=Join-Path $LogRoot (([IO.Path]::GetFileNameWithoutExtension($ReceiptPath)).Replace('_Receipt','_Verify')+'.json')
    $issues=[Collections.Generic.List[string]]::new()
    if(-not (Exact-File ([string]$r.script_sha256) (Hash-File $PSCommandPath))) { $issues.Add('SCRIPT_HASH_DRIFT') }
    try {Check-Golden} catch {$issues.Add($_.Exception.Message)}
    if($Mode -eq 'VerifyStep') {
        if($r.schema -ne 'BlueLite.R021.StepReceipt.v4') {$issues.Add('STEP_SCHEMA_INVALID')}
        if(-not ((Within ([string]$r.deleted_path) 'C:\work\E2E') -or
                  (Within ([string]$r.deleted_path) 'C:\work\26300.9818-UUP-v5') -or
                  (Within ([string]$r.deleted_path) 'C:\BLR20R2F5') -or
                  [regex]::IsMatch([string]$r.deleted_path,'(?i)(?:^|[\\._-])(?:26200|25H2)(?=$|[\\._-])'))) {
            $issues.Add('DELETED_PATH_OUTSIDE_CANDIDATES')
        }
        if([IO.File]::Exists([string]$r.deleted_path)) {$issues.Add('DELETED_PATH_STILL_EXISTS')}
        if($r.keeper_path) {
            if(-not [IO.File]::Exists([string]$r.keeper_path)) {
                $issues.Add('DUPLICATE_KEEPER_MISSING')
            } elseif((Hash-File ([string]$r.keeper_path)) -ne [string]$r.deleted_sha256) {
                $issues.Add('DUPLICATE_KEEPER_SHA_DRIFT')
            }
        }
    } else {
        if($r.schema -ne 'BlueLite.R021.RunReceipt.v4') {$issues.Add('RUN_SCHEMA_INVALID')}
        foreach($field in @('audit_path','plan_path','summary_path')) {
            $f=[string]$r.$field
            if(-not (Within $f $LogRoot) -or -not [IO.File]::Exists($f)) {
                $issues.Add('MISSING_OR_ESCAPED_'+$field)
            } else {
                $shaField=$field.Replace('_path','_sha256')
                $expectedSha=[string]$r.PSObject.Properties[$shaField].Value
                if((Hash-File $f) -ne $expectedSha) {
                    $issues.Add('HASH_MISMATCH_'+$field)
                }
            }
        }
        if($issues.Count -eq 0) {
            $steps=@(Import-Csv -LiteralPath ([string]$r.audit_path)|Where-Object Action -eq 'DELETED')
            if($steps.Count -ne [int]$r.deleted_count) {$issues.Add('DELETED_COUNT_MISMATCH')}
            foreach($item in $steps) {
                if([IO.File]::Exists($item.Path)) {$issues.Add('DELETED_PATH_REAPPEARED '+$item.Path)}
            }
        }
    }
    $status=if($issues.Count -eq 0){'PASS'}else{'HOLD'}
    $verify=[ordered]@{
        schema='BlueLite.R021.FreshPS7Verify.v4';mode=$Mode
        run_id=[string]$r.run_id;utc=[datetime]::UtcNow.ToString('o')
        status=$status;receipt_sha256=Hash-File $ReceiptPath
        issues=@($issues.ToArray());pid=$PID
    }
    Write-Immutable $verifyPath ($verify|ConvertTo-Json -Depth 6)
    Write-Output ('[BlueLite R021] '+$Mode+'='+$status+' '+$verifyPath)
    if($status -ne 'PASS') {exit 17}
    exit 0
}

$DryRun = ($Mode -eq 'DryRun')
$runId='BlueLite_R021_Cleanup_'+[datetime]::UtcNow.ToString('yyyyMMddTHHmmssfffffffZ')+'_'+[guid]::NewGuid().ToString('N').Substring(0,8)
$planPath=Join-Path $LogRoot ($runId+'_Plan.csv')
$auditPath=Join-Path $LogRoot ($runId+'_Audit.csv')
$summaryPath=Join-Path $LogRoot ($runId+'_Summary.json')
$receiptPath=Join-Path $LogRoot ($runId+'_Receipt.json')
$zipPath=Join-Path $LogRoot ($runId+'_EVIDENCE.zip')
$scriptSha=Hash-File $PSCommandPath
$freeStart=([IO.DriveInfo]::new('C:\')).AvailableFreeSpace
$stats=[ordered]@{scanned=0;large=0;planned=0;deleted=0;dryrun=0;kept=0;held=0;errors=0;deleted_bytes=0L}
$errors=[Collections.Generic.List[string]]::new()
$stepFiles=[Collections.Generic.List[string]]::new()
$script:AuditWriter=$null
$script:StopNow=$false
$preflight=$false
$fullScan=$false

function Audit([string]$Action,[string]$Path,[int64]$Bytes,[string]$Reason,[string]$Sha='', [string]$Keeper='') {
    $fields=@([datetime]::UtcNow.ToString('o'),$Action,$Path,$Bytes,$Reason,$Sha,$Keeper)
    $script:AuditWriter.WriteLine((@($fields|ForEach-Object{Quote-Csv $_}) -join ','))
    $script:AuditWriter.Flush()
}
function Get-Decision([IO.FileInfo]$F) {
    $p=$F.FullName
    if($F.Length -le $Limit) {return [pscustomobject]@{action='KEEP';reason='BELOW_100MB';sha='';keeper=''}}
    if(-not ((Within $p $Roots[0]) -or (Within $p $Roots[1]))) {
        return [pscustomobject]@{action='HOLD';reason='OUTSIDE_BOUNDED_ROOTS';sha='';keeper=''}
    }
    $protect=Protected-Reason $F
    if($protect) {return [pscustomobject]@{action='KEEP';reason=$protect;sha='';keeper=''}}

    # Six explicitly named 26300.9711 legacy disposable / measurement WIMs.
    $e2e='C:\work\E2E'
    $stages=@(
        [pscustomobject]@{rel='BlueLite_Stage1_S31_26300.9711_OneDriveAMBER\install.wim';bytes=6509216853L;sha='F52389FA66F8B60D56661C8786EC99409FB95447403B3C6FCBB94121EF8E340B'},
        [pscustomobject]@{rel='BlueLite_Stage1_S37_26300.9711_FullR4Candidate\install.disposable.wim';bytes=6551362129L;sha='A599CF7B7CB44748D738D1F5AD75D1D6C462DD15293755DFFB17F6D2ABE0BE9F'},
        [pscustomobject]@{rel='BlueLite_Stage1_S39_26300.9711_WebView_FOD_Native_R6\install.webview-disposable.wim';bytes=6595075169L;sha=''},
        [pscustomobject]@{rel='BlueLite_Stage1_S41_26300.9711_FodMetadata_Superseded_R10\install.fodmetadata-disposable.wim';bytes=6636510185L;sha=''},
        [pscustomobject]@{rel='BlueLite_S40_26300.9711_R8_EqualMaxExports\baseline-S37-max.wim';bytes=6160680526L;sha=''},
        [pscustomobject]@{rel='BlueLite_S40_26300.9711_R8_EqualMaxExports\webview-removed-S39-max.wim';bytes=5557124413L;sha=''}
    )
    foreach($stage in $stages) {
        if(Exact-File $p (Join-Path $e2e $stage.rel)) {
            if($F.Length -ne $stage.bytes){return [pscustomobject]@{action='HOLD';reason='EXPERIMENT_SIZE_DRIFT';sha='';keeper=''}}
            if(-not (Evidence-Present $S41Log @('S31','S37'))) {
                return [pscustomobject]@{action='HOLD';reason='S41_HISTORICAL_PROOF_MISSING';sha='';keeper=''}
            }
            return [pscustomobject]@{action='DELETE';reason='RETIRED_26300_9711_EXPERIMENT_IMAGE';sha=$stage.sha;keeper=''}
        }
    }

    # Historical 26300.9711 downloaded transport payload, NOT the ZIP/source/metadata.
    $oldPayload='C:\work\E2E\BlueLite_DL_R26_D6_26300.9711_2b22470a\UUPs'
    if(Within $p $oldPayload) {
        if($F.Extension -in @('.esd','.ESD','.cab','.CAB','.msu','.MSU','.wim','.WIM')) {
            if(-not (Evidence-Present $S41Log @('S31','S37'))) {
                return [pscustomobject]@{action='HOLD';reason='HISTORICAL_RECONSTRUCTION_PROOF_MISSING';sha='';keeper=''}
            }
            return [pscustomobject]@{action='DELETE';reason='RETIRED_26300_9711_DOWNLOADED_PAYLOAD_NOT_VENDOR_ZIP';sha='';keeper=''}
        }
        return [pscustomobject]@{action='KEEP';reason='OLD_UUP_NON_PAYLOAD_SOURCE_DATA';sha='';keeper=''}
    }

    # Generated setup boot.wim, not source WinPE of current v10.1 or R004.
    $oldBoot='C:\work\E2E\BlueLite_Stage1_S20_26300.9711_ConverterWorkspace\26300.9711.261009-2244.26H2_GE_RELEASE_SVC_PROD1_CLIENTPRO_OEMRET_X64FRE_EN-US\sources\boot.wim'
    if(Exact-File $p $oldBoot) {
        if($F.Length -ne 727417359L){return [pscustomobject]@{action='HOLD';reason='RETIRED_BOOT_WIM_SIZE_DRIFT';sha='';keeper=''}}
        return [pscustomobject]@{action='DELETE';reason='RETIRED_STAGE_S20_GENERATED_BOOT_WIM';sha='';keeper=''}
    }

    # R20R2F6 measured export: exact native source SHA and historical LOG evidence.
    $r20='C:\BLR20R2F5\R20R2F6_exports\WebViewRemoved_26300_9807_MAX.wim'
    if(Exact-File $p $r20) {
        if($F.Length -ne 6407308664L -or
           -not (Evidence-Present $R20Log @('F8F2FFF0A40508C88F8426B2923FEDCF9B00F3FFF3A5637A13C0EB0006E8BA7E','PASS_R20R2F6_EQUAL_MAX_COMPRESSION_MEASUREMENT_ONLY'))) {
            return [pscustomobject]@{action='HOLD';reason='R20_SHA_SIZE_OR_LOG_PROOF_MISSING';sha='';keeper=''}
        }
        return [pscustomobject]@{action='DELETE';reason='RETIRED_R20_MEASUREMENT_ONLY_WIM';sha='F8F2FFF0A40508C88F8426B2923FEDCF9B00F3FFF3A5637A13C0EB0006E8BA7E';keeper=''}
    }

    # v5 26300.9818 candidate ISO: preserve v4 GOLDEN ISO and WIM in every case.
    $v5='C:\work\26300.9818-UUP-v5'
    $v5Iso=Join-Path $v5 '26300.9818.261025-0959.26H2_GE_RELEASE_SVC_PROD3_CLIENTPRO_OEMRET_X64FRE_EN-US.ISO'
    if(Exact-File $p $v5Iso) {
        if($F.Length -ne 6820456448L) {return [pscustomobject]@{action='HOLD';reason='V5_ISO_SIZE_DRIFT';sha='';keeper=''}}
        return [pscustomobject]@{action='DELETE';reason='RETIRED_V5_NON_GOLDEN_ISO_R004_GOLDEN_RETAINED';sha='';keeper=''}
    }

    # v5 UUP binary duplicates: only delete if FULL SHA256 equals R004 keeper.
    $v5Uup=Join-Path $v5 'UUPs'
    if(Within $p $v5Uup) {
        if($F.Extension -notin @('.esd','.ESD','.cab','.CAB','.msu','.MSU','.wim','.WIM')) {
            return [pscustomobject]@{action='KEEP';reason='V5_NON_BINARY_SOURCE_OR_TOOL';sha='';keeper=''}
        }
        $rel=$p.Substring($v5Uup.TrimEnd('\').Length+1)
        if($rel.Contains('\')) {return [pscustomobject]@{action='HOLD';reason='DUPLICATE_NESTING_UNEXPECTED';sha='';keeper=''}}
        $keeper=Join-Path (Join-Path $GoldenRoot 'UUPs') $rel
        if(-not [IO.File]::Exists($keeper)) {
            return [pscustomobject]@{action='HOLD';reason='R004_KEEPER_MISSING';sha='';keeper=$keeper}
        }
        if(([IO.FileInfo]::new($keeper)).Length -ne $F.Length) {
            return [pscustomobject]@{action='HOLD';reason='R004_KEEPER_SIZE_DIFFERS';sha='';keeper=$keeper}
        }
        return [pscustomobject]@{action='CHECK_DUPLICATE';reason='V5_IDENTICAL_UUP_PAYLOAD_R004_KEPT';sha='';keeper=$keeper}
    }

    # 25H2 retired generated binary artifacts (scope approved in Master §0M).
    if($p -match '(?i)(?:^|[\\._-])(?:26200|25H2)(?=$|[\\._-])' -and
       $p -notmatch '(?i)(?:^|[\\._-])(?:26300|26H2)(?=$|[\\._-])' -and
       $F.Extension -in @('.wim','.WIM','.iso','.ISO','.esd','.ESD','.vhd','.VHD','.vhdx','.VHDX','.cab','.CAB','.msu','.MSU','.swm','.SWM')) {
        return [pscustomobject]@{action='DELETE';reason='R020_25H2_26200_RETIRED_GENERATED_BINARY';sha='';keeper=''}
    }
    return [pscustomobject]@{action='KEEP';reason='NO_APPROVED_UNUSED_OR_DUPLICATE_PROOF';sha='';keeper=''}
}

try {
    if(-not [IO.Directory]::Exists($LogRoot)){throw 'CANONICAL_LOG_FOLDER_MISSING'}
    foreach($root in $Roots) {
        if(-not [IO.Directory]::Exists($root)) {throw ('BOUNDED_ROOT_MISSING '+$root)}
        $a=Get-Item -LiteralPath $root -Force
        if(($a.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {throw ('BOUNDED_ROOT_REPARSE '+$root)}
    }
    Check-Golden
    Check-SafeSystem
    $preflight=$true

    $errList=@()
    $all=[Collections.Generic.List[IO.FileInfo]]::new()
    foreach($root in $Roots) {
        # Keep EVERY parameter on this one expression: Clean100 v2 broke on an orphan -ErrorAction.
        $found=@(Get-ChildItem -LiteralPath $root -Force -Recurse -File -ErrorAction SilentlyContinue -ErrorVariable +errList)
        $stats.scanned += $found.Count
        foreach($f in $found) {if($f.Length -gt $Limit){$all.Add($f)}}
    }
    if($errList.Count -gt 0){throw ('ENUMERATION_ERRORS_'+$errList.Count)}
    $stats.large=$all.Count
    $fullScan=$true

    $planned=[Collections.Generic.List[object]]::new()
    foreach($f in ($all|Sort-Object FullName)) {
        $decision=Get-Decision $f
        $planned.Add([pscustomobject]@{
            File=$f;Action=[string]$decision.action;Reason=[string]$decision.reason
            Keeper=[string]$decision.keeper;Pin=[string]$decision.sha
            Bytes=[int64]$f.Length;WriteUtc=$f.LastWriteTimeUtc;CreateUtc=$f.CreationTimeUtc
        })
    }
    $stats.planned=@($planned|Where-Object{$_.Action -in @('DELETE','CHECK_DUPLICATE')}).Count

    $planHeader='Path,Bytes,Decision,Reason,Keeper,ModifiedUtc'
    $planText=($planHeader+"`n")
    foreach($item in $planned) {
        $fields=@($item.File.FullName,$item.Bytes,$item.Action,$item.Reason,$item.Keeper,$item.WriteUtc.ToString('o'))
        $planText+=(@($fields|ForEach-Object{Quote-Csv $_}) -join ',')+"`n"
    }
    Write-Immutable $planPath $planText

    $fileStream=[IO.FileStream]::new($auditPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
    $script:AuditWriter=[IO.StreamWriter]::new($fileStream,[Text.UTF8Encoding]::new($false))
    $script:AuditWriter.WriteLine('Utc,Action,Path,Bytes,Reason,SHA256,Keeper')
    Audit 'PREFLIGHT_PASS' '' 0 'DISM_ZERO_GOLDEN_PINNED_BOUNDED_ROOTS'
    Audit 'INVENTORY_PASS' '' $stats.large ('ELIGIBLE_CANDIDATES='+$stats.planned)

    foreach($entry in $planned) {
        $f=$entry.File
        $p=$f.FullName
        if($entry.Action -eq 'KEEP') {
            Audit 'KEEP' $p $entry.Bytes $entry.Reason
            $stats.kept++
            continue
        }
        if($entry.Action -eq 'HOLD') {
            Audit 'HOLD' $p $entry.Bytes $entry.Reason
            $stats.held++
            continue
        }
        try {
            Check-SafeSystem
            Check-Golden
            if(-not [IO.File]::Exists($p)) {throw 'FILE_DISAPPEARED_AFTER_PLAN'}
            $now=Get-Item -LiteralPath $p -Force
            if($now.Length -ne $entry.Bytes -or $now.LastWriteTimeUtc -ne $entry.WriteUtc -or
                $now.CreationTimeUtc -ne $entry.CreateUtc) {throw 'FILE_IDENTITY_CHANGED_SINCE_PLAN'}
            if(-not (Safe-Path $p)) {throw 'NOT_DIRECT_BOUNDED_FILE_OR_REPARSE'}
            if(-not (Check-Unlocked $p)) {throw 'FILE_OPEN_OR_LOCKED'}
            if((Protected-Reason $now) -ne '') {throw 'PROTECTED_AFTER_PLAN'}
            $currentDecision=Get-Decision $now
            if($currentDecision.action -ne $entry.Action -or $currentDecision.reason -ne $entry.Reason) {
                throw 'PLAN_DECISION_DRIFT'
            }
            $sha=Hash-File $p
            if($entry.Pin -and $sha -ne $entry.Pin) {throw 'PINNED_ORIGINAL_SHA256_MISMATCH'}
            if($entry.Action -eq 'CHECK_DUPLICATE') {
                if(-not [IO.File]::Exists($entry.Keeper)){throw 'R004_KEEPER_DISAPPEARED'}
                if(-not (Within $entry.Keeper (Join-Path $GoldenRoot 'UUPs'))) {throw 'KEEPER_PATH_NOT_GOLDEN'}
                if((Hash-File $entry.Keeper) -ne $sha) {throw 'R004_KEEPER_CONTENT_SHA256_MISMATCH'}
            }
            if($DryRun) {
                Audit 'WOULD_DELETE_SHA_VERIFIED' $p $entry.Bytes $entry.Reason $sha $entry.Keeper
                $stats.dryrun++
                continue
            }
            Audit 'DELETE_AUTHORIZED_SHA256' $p $entry.Bytes $entry.Reason $sha $entry.Keeper
            Remove-Item -LiteralPath $p -Force -ErrorAction Stop
            if([IO.File]::Exists($p)) {throw 'POST_DELETE_PATH_STILL_PRESENT'}
            Audit 'DELETED' $p $entry.Bytes $entry.Reason $sha $entry.Keeper
            $stats.deleted++
            $stats.deleted_bytes += $entry.Bytes
            $stepId=('{0:D3}' -f $stats.deleted)
            $stepReceipt=Join-Path $LogRoot ($runId+'_Step'+$stepId+'_Receipt.json')
            $record=[ordered]@{
                schema='BlueLite.R021.StepReceipt.v4';run_id=$runId
                utc=[datetime]::UtcNow.ToString('o');step=$stats.deleted
                deleted_path=$p;deleted_bytes=$entry.Bytes;deleted_sha256=$sha
                reason=$entry.Reason;keeper_path=$entry.Keeper
                script_sha256=$scriptSha;policy=$Policy
            }
            Write-Immutable $stepReceipt ($record|ConvertTo-Json -Depth 8)
            $stepFiles.Add($stepReceipt)
            & pwsh -NoProfile -NonInteractive -File $PSCommandPath -Mode VerifyStep -ReceiptPath $stepReceipt
            if($LASTEXITCODE -ne 0) {throw ('FRESH_STEP_VERIFY_HOLD_'+$LASTEXITCODE)}
            $stepFiles.Add((Join-Path $LogRoot ($runId+'_Step'+$stepId+'_Verify.json')))
        } catch {
            $stats.errors++
            Audit 'FILE_HOLD' $p $entry.Bytes $_.Exception.Message
            $errors.Add(($p+' | '+$_.Exception.Message))
            # If deletion occurred but independent readback failed, halt immediately.
            if(-not [IO.File]::Exists($p)) {$script:StopNow=$true;break}
        }
    }
} catch {
    $errors.Add(('FATAL_PREFLIGHT_OR_INVENTORY '+$_.Exception.Message))
    $stats.errors++
    if($null -ne $script:AuditWriter) {
        Audit 'FATAL_HOLD' '' 0 $_.Exception.Message
    }
    $script:StopNow=$true
} finally {
    if($null -ne $script:AuditWriter){$script:AuditWriter.Flush();$script:AuditWriter.Dispose()}
}

$freeEnd=([IO.DriveInfo]::new('C:\')).AvailableFreeSpace
$status=if($script:StopNow){'HOLD'}elseif($stats.errors -gt 0 -or $stats.held -gt 0){'PARTIAL'}else{'PASS'}
$summary=[ordered]@{
    schema='BlueLite.R021.RunSummary.v4';run_id=$runId;policy=$Policy
    utc=[datetime]::UtcNow.ToString('o');status=$status;mode=$Mode
    roots=$Roots;exclusive_threshold_bytes=$Limit
    e2e_native_reference_bytes=[int64]54036819319
    e2e_operator_reference_bytes=[int64]54036820152
    scanned=$stats.scanned;large=$stats.large;planned=$stats.planned
    deleted_count=$stats.deleted;dryrun_verified_count=$stats.dryrun
    kept=$stats.kept;held=$stats.held;errors=$stats.errors
    deleted_logical_bytes=$stats.deleted_bytes
    free_before=$freeStart;free_after=$freeEnd;actual_free_delta=($freeEnd-$freeStart)
    preflight_pass=$preflight;complete_scan=$fullScan
    issues=@($errors.ToArray());next='SEND_EVIDENCE_ZIP_TO_BL_PROJECT'
}
try {
    if(-not [IO.File]::Exists($planPath)) {Write-Immutable $planPath 'Path,Bytes,Decision,Reason,Keeper,ModifiedUtc'}
    if(-not [IO.File]::Exists($auditPath)) {Write-Immutable $auditPath 'Utc,Action,Path,Bytes,Reason,SHA256,Keeper'}
    Write-Immutable $summaryPath ($summary|ConvertTo-Json -Depth 12)
    $receipt=[ordered]@{
        schema='BlueLite.R021.RunReceipt.v4';run_id=$runId
        utc=[datetime]::UtcNow.ToString('o');status=$status;script_sha256=$scriptSha
        policy=$Policy;audit_path=$auditPath;audit_sha256=Hash-File $auditPath
        plan_path=$planPath;plan_sha256=Hash-File $planPath
        summary_path=$summaryPath;summary_sha256=Hash-File $summaryPath
        deleted_count=$stats.deleted;deleted_logical_bytes=$stats.deleted_bytes
    }
    Write-Immutable $receiptPath ($receipt|ConvertTo-Json -Depth 8)
    & pwsh -NoProfile -NonInteractive -File $PSCommandPath -Mode VerifyFinal -ReceiptPath $receiptPath
    if($LASTEXITCODE -ne 0) { $status='HOLD'; $errors.Add('FINAL_INDEPENDENT_VERIFY_HOLD') }
    # One self-contained bounded evidence ZIP, no original sources, no bulk payloads.
    $members=[Collections.Generic.List[string]]::new()
    foreach($file in @($planPath,$auditPath,$summaryPath,$receiptPath,
              (Join-Path $LogRoot ($runId+'_Verify.json')))) {
        if([IO.File]::Exists($file)){$members.Add($file)}
    }
    foreach($f in $stepFiles){if([IO.File]::Exists($f)){$members.Add($f)}}
    $za=[IO.Compression.ZipFile]::Open($zipPath,[IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach($file in $members) {
            [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($za,$file,
                [IO.Path]::GetFileName($file),[IO.Compression.CompressionLevel]::Optimal)
        }
    } finally {$za.Dispose()}
    Write-Host ('[BlueLite R021] STATUS='+$status+' scanned='+$stats.scanned+' large='+$stats.large+' planned='+$stats.planned)
    Write-Host ('[BlueLite R021] DELETED='+$stats.deleted+' HELD='+$stats.held+' ERRORS='+$stats.errors)
    Write-Host ('[BlueLite R021] LOGICAL_FREED_GiB='+[math]::Round($stats.deleted_bytes/1GB,3))
    Write-Host ('[BlueLite R021] ACTUAL_FREE_DELTA_GiB='+[math]::Round(($freeEnd-$freeStart)/1GB,3))
    Write-Host ('UPLOAD_EVIDENCE='+$zipPath)
    Write-Host ('EVIDENCE_SHA256='+(Hash-File $zipPath))
} catch {
    throw ('BLUELITE_R021_FINAL_EVIDENCE_HOLD_'+$_.Exception.Message)
}
if($status -eq 'HOLD') {throw 'BLUELITE_R021_HOLD_CHECK_EVIDENCE'}
if($status -eq 'PARTIAL') {throw 'BLUELITE_R021_PARTIAL_CHECK_HOLD_FILE_ROWS'}
