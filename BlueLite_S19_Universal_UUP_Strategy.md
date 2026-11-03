> **R005 APPROVED RECOVERY / FREEZE 2026-11-03:** 2026-11-03 R005 / Master v6.3.4 §0L: operator-approved FIVE ORDERED phases; Phase1 GOLDEN frozen, 10 native file SHA + fresh-process verifications, WIM 3D606513D9C1D2B157AAFD6925FF1655C9A48520CE5D4219AF2ED654C82753E4, ISO 570BD12E9DBBBB51CACFB3B9A403326AA5000FAC1D2F7E44482EFCC154CB3736, 7z full ISO read and WIM index/layout PASS. Last single evidence C:\work\logs\BlueLite_R005_GoldenFreeze_20261103T171855421Z_ca672a9b.zip SHA256 D3B4B992037F348560FDE32DB02EC75FEC9EBD2D1D4963767844BC0F5A452901. Script C:\work\scripts\BlueLite_R005_GoldenFreeze_v1.ps1 SHA256 350CB4A4507C70451234666D822AFC4AAD8B75DC4088A24422B24357FF54406D. Technical per-op QA at development/PREMAX/R005/R005_OP01_FinalNativeQA.json; approval and Recovery-on-Demand proposal at R005_OP00_ApprovedOrderAndFreezePlan.md and R005_OP00_RecoveryOnDemand_DesignEvidence.md. Frozen R004 untouched; next source-only F01/F02/F03/F04/F06. Recovery-on-Demand is metadata/optional external matched WinRE, boot.wim retained, not yet tested. NTLite deferred. No further image mutation authorized. S19 original S19A operator-run NOT_RUN remains a separate track; no source-filter changes or universal converter inference from one run. Microsoft REAgentC /setreimage and recovery partition validation are FUTURE requirements, not runtime PASS.

> **2026-11-03 R004 NATIVE PROOF — MASTER v6.3.3 §0K supersedes S19-era v4 NOT_RUN status, not the S19A record.** Operator-original 26300.9818 UUP ZIP + predecessor-source-based reviewed MAX_PRE v4 produced real final WIM/ISO and complete offline inventory: WIM 7,488,515,256 -> 5,736,092,221 bytes, ISO 6,822,354,944 bytes. Runtime ZIP SHA256 D64DAD834847DE4CD4FA577D51ED25158085B29D3A81BF073697B673A14D3905; 98 Windows and 2,798 original Apps out+SHA1 identities matched predecessor, 129 unique downloaded payloads; runtime three external metadata files NOT_PROVIDED. Stock WinRE/boot path retained, effective SkipWinRE=1 already omits embedded winre.wim from install.wim, boot.wim 824,426,219 B remains. Full immutable evidence, 135 removed package-inventory identities and dependency/WinRE roadmap: development/PREMAX/R004 OP04–OP08, live Current. **Original independent S19A operator dry-run remains NOT_RUN**; do not conflate different tools. ISO ~5GB and clean installed 14.5–15.5GB/VM are still unproven release gates. Original S19A script/code backup below intentionally unchanged.

# BlueLite S19 — **UNIVERSAL UUP SOURCE CONTRACT + SELECTIVE WIM/ISO STRATEGY**

**STATUS:** 2026-11-01 operator-approved technical companion to **Master v6.3.3 §0I / §0J / §0K**, §0H, §7.3–§7.4. Latest §0J additionally governs target footprint, permanent download approval, unlimited versioned Lane B corrective runs and 3-attempt connector/platform HOLD. **S19A code exists, verified UTF-8 Git blob and native Windows PS7 AST PASS; S19A real operator Run NOT_RUN.** This is not a separate dynamic status document; live NEXT remains only in `BlueLite_Current_Status.md`.

## 1. **Non-negotiable universal flow**

**ONE ENGINE / PER-BUILD FROZEN SOURCE / DECLARATIVE PROFILE.** Operator chooses official 26300.x GA build, original UUP ZIP and target edition/language. For each run, bind launcher UUID and authentic Windows+Apps `aria2` source metadata, actual original converter ZIP and SHA, **three new variable-per-build metadata inputs**, source contract plus optional final selections. G2/G3 JIT always refreshes *transport*, never alters immutable D4 `out+sha1` payloads. Use existing D6 downloader and source-reviewed converter v128m/Oct-3 reversible patch; do NOT reimplement new downloader or assume old CU-specific hashes. Native `ConvertConfig.ini`, `CustomAppsList.txt` and G4 transitive framework facts govern AppX; **5 staging app identities, 4 final keep** remain separately enforced.

1. **S19A SOURCE-ONLY — ZERO NETWORK:** validate all input sources/renaming/sha1 and original launcher/D4, output deterministic frozen contract and conservative `KEEP_UNTIL_CONVERTER_CLOSURE_PROVEN` selection inventory, independently verify report/receipt.
2. **S19B SELECTIVE FETCH — CONDITIONAL:** classify ESD/edition/language/base/delta/metadata/SSU/LCU/NDP/needed FOD as potentially mandatory; grant omission only on observed converter/CompDB dependency proof. AppX five required staging identities and exact providers may be source-bound selected without downloading 2798 apps. JIT G2/G3 handles expired MS signatures under strict same-UUID D4 identity gate. Check every downloaded SHA-1 and compute SHA256.
3. **S19C CONVERSION — SEPARATE APPROVAL:** original v128m, source-pinned reversible overlay and real supported configuration; preserve source reconstruction closure. Build correct `install.wim` and supported updates/cleanup; WinPE Setup `boot.wim` is retained; WinRE only under approved verified alternate recovery.
4. **S19D POST-RECONSTRUCTION — SEPARATE APPROVAL:** offline remove/disable only verified residuals, WIM export/recompression and full integrity checks; ISO with boot validation, final ISO/footprint measurement and rollback evidence. Measured target: final ISO around 5 GB (compressed transport) and clean installed physical footprint 15.0 GB ± 500 MB, acceptable 14.5–15.5 GB decimal (GB=10^9 B, MB=10^6 B), before machine-specific drivers/user programs; actual native evidence required, no guarantee. Master v6.3.2 §0J defines scope and dependency disposition. Real installation/Update/VM tests are mandatory for release.

**NEVER execute `File_renaming_script.cmd` as a command.** It is only a GUID-name lookup and redundant cross-check; original `aria2` `out=` records already provide correct destination names. Never drop needed reconstruction packages merely because their final feature is unwanted.

## 2. **The three operator-supplied input files — names remain constant across build changes**

| Filename (exact) | Meaning | R003 fixture SHA256 | R003 bytes |
|---|---|---|---:|
| `List of files UUP.txt` | filename / UTC URL expiry / original SHA-1 / displayed size | `D4E315D675260B4D2E9F354739C53DA069528AC47C18D428B4F6198E42DC6AAA` | 12759 |
| `File_renaming_script.cmd` | GUID → original filename, parsed **data-only** | `5B2EF8687885E2D9EDFC5A1F50C2D25F37E8E86D4E23E2EA92833022C3579C94` | 10393 |
| `SHA-1 checksums file.txt` | immutable expected `sha1 *filename` ledger | `C757AE7C250F25C1FFD265EECB140528EFAC51283558FCC699E182360EB632F4` | 9779 |

**Verified fixture:** exactly 98 names/98 SHA1/98 GUID mappings, 76 CAB / 19 ESD / 2 MSU / 1 WIM; source Windows 98-item D4 identity `8B690FB8E065BD5DB668667A13FF1CA4B9A4029FB4947FD43E774E8B0D373644`; content-pair SHA256 `65CF6BBC1AD6DA869B3478C7E466C234942476392028381EAF5A2D0B9B3C004A`; original launcher ZIP `26300.9818_amd64_en-us_professional_6c7bf258_convert.zip`, source UUID `6c7bf258-2632-47dd-83ee-c23945978da1` SHA256 `39406F106A467D1DFD592AC8BDF36C665B126EEDD4A4A268E19E1EF30062E9E2`. Expired URLs may be refreshed JIT; the 98 content hashes may NOT change.

## 3. **S19A operator contract and proof limits**

**Verbatim executable backup below.** Canonical GitHub script: `scripts/BlueLite_S19A_UniversalSourceContract_v1.ps1`; exact **SHA256 `A5EEC5A1C659F2787D769098E0B0357697BE72314F1900AD61E2648347E87748`**, 15,828 bytes / 253 LF lines, UTF-8 no BOM; native `Parser.ParseInput` on authorized Windows PS7: **0 AST parse errors**. Save in `C:\work\scripts`, triad under `C:\work\scripts\S19A_Input`; original ZIP/Windows queue/D4 module stay in original read-only `C:\work` locations. No output except `C:\work\logs\BlueLite_S19A_UniversalContract_001_{Report.json,Receipt.json,IndependentQA.txt,Evidence.zip}`, unique immutable outputs. The script does **not** fetch or rename payloads, invoke .cmd/aria2/constructor, run converter, alter installation files or touch OS image.

**Run mode:** pins original ZIP SHA256, D4 module SHA256, optional expected 98-entry Windows D4 identity; reads launcher UUID/pack/edition; requires all three metadata files and exactly matching filename+SHA1+rename sets and original Windows queue; generates explicit per-package `KEEP_UNTIL_CONVERTER_CLOSURE_PROVEN` dry-run inventory (candidate classification is NOT approved removal). Writes Report + Receipt; launches fresh PowerShell 7 `Verify` child to recompile and hash input & snapshot; ZIP audit. **PASS means only source contract / dry-run**, NOT converter or ISO certification. If any input differs, FAIL CLOSED and preserve evidence.

**Next gate:** prove actual v128m/CompDB converter source dependencies, including base ESD, edition/language, update chain, optional FOD, Edge/WebView, WinPE setup and required conditional packages; run an independently approved selective-plan *without* invoking image mutations. Source 26300.9818 remains development fixture; test universality on two distinct operator-chosen official 26300.x sources when available. Master §0G keeps historic Handoff frozen; this file is specification+source backup, **not a fourth Current Status**.

## 4. **S19A complete verbatim PowerShell 7 source backup — DO NOT EDIT INDEPENDENTLY**

The code in this fenced block must be byte-identical to the canonical `.ps1`. Update both files with the same SHA-pinned reviewed operation, never a different version under the same name.

```powershell
# BlueLite S19A: UNIVERSAL Windows UUP source contract + conservative selection DRY RUN.
# Inputs: original UUP Dump ZIP, original Windows D4 aria2, and three per-source files.
# NO network, aria2 execution, CMD execution, converter, DISM, WIM, ISO or OS edits.
[CmdletBinding()]
param(
    [ValidateSet('Run','Verify')][string]$Mode = 'Run',
    [Parameter(Mandatory)][string]$InputDir,
    [Parameter(Mandatory)][string]$OriginalUupZip,
    [Parameter(Mandatory)][string]$WindowsQueue,
    [Parameter(Mandatory)][string]$D4Module,
    [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedSourceZipSha256,
    [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedD4ModuleSha256,
    [ValidatePattern('^$|^[A-Fa-f0-9]{64}$')][string]$ExpectedWindowsIdentitySha256 = '',
    [ValidateSet('Conservative','CandidateAudit')][string]$Profile = 'Conservative',
    [string]$OutputPrefix = 'C:\work\logs\BlueLite_S19A_UniversalContract_001_',
    [string]$ExpectedReceiptSha256 = ''
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$PSNativeCommandUseErrorActionPreference = $false
$Operation = 'S19A-UNIVERSAL-WINDOWS-UUP-SOURCE-CONTRACT-001'
$Utf8 = [Text.UTF8Encoding]::new($false)

function Gate([bool]$Condition,[string]$Reason) {
    if (-not $Condition) { throw ('BLUELITE_S19A_HOLD_' + $Reason) }
}
function Digest([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()
}
function HashText([string]$Value) {
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Value)))
}
function New-Text([string]$Path,[string]$Value) {
    $stream = [IO.FileStream]::new($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try {
        $writer = [IO.StreamWriter]::new($stream,$Utf8,1024,$true)
        try { $writer.Write($Value); $writer.Flush() } finally { $writer.Dispose() }
    } finally { $stream.Dispose() }
}
function Read-Text([string]$Path) {
    Gate ([IO.File]::Exists($Path)) ('MISSING_INPUT_' + [IO.Path]::GetFileName($Path))
    return [IO.File]::ReadAllText($Path,[Text.Encoding]::UTF8)
}
function ValidName([string]$Name) {
    return ($Name -cmatch '^[A-Za-z0-9][A-Za-z0-9._+\-]*$' -and $Name -notmatch '\.\.' -and $Name.Length -le 240)
}
function Map-Add([Collections.Generic.Dictionary[string,object]]$Map,[string]$Key,[object]$Value,[string]$Label) {
    Gate (ValidName $Key) ('INVALID_FILENAME_' + $Label)
    Gate (-not $Map.ContainsKey($Key)) ('DUPLICATE_' + $Label + '_' + $Key)
    $Map.Add($Key,$Value)
}
function Load-Metadata([string]$Folder) {
    $names = @('List of files UUP.txt','File_renaming_script.cmd','SHA-1 checksums file.txt')
    $paths = @($names | ForEach-Object { Join-Path $Folder $_ })
    foreach ($p in $paths) { Gate ([IO.File]::Exists($p)) ('TRIAD_MISSING_' + [IO.Path]::GetFileName($p)) }
    $list = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
    $shaMap = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
    $renameMap = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
    $guids = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    $listLines = @(Get-Content -LiteralPath $paths[0] -Encoding UTF8 | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    Gate ($listLines.Count -gt 1) 'EMPTY_FILE_LIST'
    Gate ($listLines[0].Trim() -ceq "File`tExpires`tSHA-1`tSize") 'LIST_HEADER_SCHEMA'
    foreach ($line in $listLines[1..($listLines.Count-1)]) {
        $cols = @($line -split "`t")
        Gate ($cols.Count -eq 4) 'LIST_ROW_FORMAT'
        $name = [string]$cols[0]
        Gate ($cols[2] -match '^[A-Fa-f0-9]{40}$') ('LIST_SHA1_FORMAT_' + $name)
        Gate ($cols[1] -cmatch '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} UTC$') ('LIST_EXPIRY_FORMAT_' + $name)
        $dateValue = $cols[1].Substring(0,19)
        $null = [DateTime]::ParseExact($dateValue,'yyyy-MM-dd HH:mm:ss',[Globalization.CultureInfo]::InvariantCulture)
        Gate ($cols[3] -match '^(\d+(?:\.\d+)?)\s*(KiB|MiB|GiB|B)$') ('LIST_SIZE_FORMAT_' + $name)
        Map-Add $list $name ([pscustomobject]@{ Sha1=$cols[2].ToUpperInvariant(); ExpiresUtc=$cols[1]; SizeDisplay=$cols[3] }) 'LIST'
    }
    foreach ($line in (Get-Content -LiteralPath $paths[2] -Encoding UTF8)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        Gate ($line -cmatch '^([A-Fa-f0-9]{40}) \*(.+)$') 'SHA1_LEDGER_SYNTAX'
        $sha = $Matches[1].ToUpperInvariant(); $file = $Matches[2]
        Map-Add $shaMap $file $sha 'SHA1'
    }
    foreach ($line in (Get-Content -LiteralPath $paths[1] -Encoding UTF8)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $l = $line.Trim()
        if ($l -ieq '@echo off' -or $l -ceq 'cd /d "%~dp0"') { continue }
        Gate ($l -cmatch '^rename "([A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12})" "([^"]+)"$') 'RENAME_NOT_DATA_ONLY'
        $guid = $Matches[1]; $target = $Matches[2]
        Gate ($guids.Add($guid)) ('DUPLICATE_RENAME_GUID_' + $guid)
        Map-Add $renameMap $target $guid 'RENAME'
    }
    Gate ($list.Count -gt 0 -and $list.Count -eq $shaMap.Count -and $list.Count -eq $renameMap.Count) 'TRIAD_COUNT_MISMATCH'
    foreach ($entry in $list.GetEnumerator()) {
        Gate ($shaMap.ContainsKey($entry.Key) -and $renameMap.ContainsKey($entry.Key)) ('TRIAD_FILENAME_MISMATCH_' + $entry.Key)
        Gate ($entry.Value.Sha1 -ceq $shaMap[$entry.Key]) ('TRIAD_SHA1_MISMATCH_' + $entry.Key)
    }
    return [pscustomobject]@{
        List=$list; Ledger=$shaMap; Renames=$renameMap
        Files=@([pscustomobject]@{Name=$names[0];Sha256=(Digest $paths[0]);Bytes=(Get-Item -LiteralPath $paths[0]).Length},
                [pscustomobject]@{Name=$names[1];Sha256=(Digest $paths[1]);Bytes=(Get-Item -LiteralPath $paths[1]).Length},
                [pscustomobject]@{Name=$names[2];Sha256=(Digest $paths[2]);Bytes=(Get-Item -LiteralPath $paths[2]).Length})
    }
}
function Get-Launcher([string]$ZipPath) {
    Add-Type -AssemblyName System.IO.Compression
    $zip = [IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        $entry=$zip.GetEntry('uup_download_windows.cmd')
        Gate ($null -ne $entry -and $entry.Length -gt 0 -and $entry.Length -le 524288) 'LAUNCHER_MISSING_OR_OVERSIZE'
        $reader=[IO.StreamReader]::new($entry.Open(),[Text.Encoding]::UTF8,$true)
        try { $text=$reader.ReadToEnd() } finally { $reader.Dispose() }
        $found=[regex]::Matches($text,'https://uupdump\.net/get\.php\?id=(?<uuid>[0-9a-fA-F-]{36})&pack=(?<pack>[A-Za-z0-9-]+)&edition=(?<edition>[A-Za-z0-9-]+)&aria2=2')
        $win=@($found|Where-Object{$_.Groups['edition'].Value -ine 'app'})
        Gate ($win.Count -eq 1) 'LAUNCHER_WINDOWS_ENDPOINT_NONUNIQUE'
        $w=$win[0]
        $parsedUuid = [Guid]::Empty
        Gate ([Guid]::TryParse($w.Groups['uuid'].Value,[ref]$parsedUuid)) 'LAUNCHER_UUID_INVALID'
        return [pscustomobject]@{Uuid=$w.Groups['uuid'].Value.ToLowerInvariant();Pack=$w.Groups['pack'].Value.ToLowerInvariant();Edition=$w.Groups['edition'].Value.ToLowerInvariant();WindowsEndpointKind='UUP_DUMP_GET_PHP_SOURCE_BOUND'}
    } finally { $zip.Dispose() }
}
function Get-Classification([string]$Name) {
    if ($Name -match '(?i)\.(ESD)$') { return 'RECONSTRUCTION_ESD' }
    if ($Name -match '(?i)(\.msu$|Windows11\.0-KB\d+.*\.cab$)') { return 'SERVICING_UPDATE' }
    if ($Name -match '(?i)^(Edge\.wim|Microsoft-Edge-WebView.*)$') { return 'EDGE_WEBVIEW_REVIEW' }
    if ($Name -match '(?i)(FOD|FoD|LanguageFeatures)') { return 'FOD_CONVERTER_REFERENCE_REVIEW' }
    if ($Name -match '(?i)(AggregatedMetadata|DesktopDeployment|FoDMetadata)') { return 'RECONSTRUCTION_METADATA' }
    return 'OTHER_WINDOWS_SOURCE_UNPROVEN'
}
function Compile([string]$Folder,[string]$ZipPath,[string]$QueuePath,[string]$ModulePath) {
    foreach ($path in @($ZipPath,$QueuePath,$ModulePath)) { Gate ([IO.File]::Exists($path)) ('MISSING_BOUND_INPUT_' + [IO.Path]::GetFileName($path)) }
    $zipSha=Digest $ZipPath; $moduleSha=Digest $ModulePath
    Gate ($zipSha -ceq $ExpectedSourceZipSha256.ToUpperInvariant()) 'UUP_ZIP_SHA_DRIFT'
    Gate ($moduleSha -ceq $ExpectedD4ModuleSha256.ToUpperInvariant()) 'D4_MODULE_SHA_DRIFT'
    $triad=Load-Metadata $Folder
    $launcher=Get-Launcher $ZipPath
    Import-Module -Name $ModulePath -Force -ErrorAction Stop
    $identity=Get-BlueLiteQueueIdentity -Path $QueuePath
    Gate ($identity.Count -eq $triad.List.Count) 'WINDOWS_D4_RECORD_COUNT'
    if ($ExpectedWindowsIdentitySha256) { Gate ($identity.SHA256 -ceq $ExpectedWindowsIdentitySha256.ToUpperInvariant()) 'WINDOWS_D4_FROZEN_IDENTITY_CHANGED' }
    $queueMap=[Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($record in @($identity.Records)) {
        $name=[string]$record.Out
        Gate ([string]$record.Checksum -match '^sha-1=[A-Fa-f0-9]{40}$') ('D4_CHECKSUM_FORMAT_' + $name)
        $shaVal = ([string]$record.Checksum).Substring(6).ToUpperInvariant()
        Map-Add $queueMap $name $shaVal 'WINDOWS_QUEUE'
    }
    $sorted=[string[]]@($triad.List.Keys);[Array]::Sort($sorted,[StringComparer]::Ordinal)
    $pairs=[Collections.Generic.List[string]]::new()
    $rows=[Collections.Generic.List[object]]::new()
    $ext=[ordered]@{CAB=0;ESD=0;MSU=0;WIM=0;OTHER=0}
    foreach ($name in $sorted) {
        Gate ($queueMap.ContainsKey($name)) ('D4_MISSING_' + $name)
        $m=$triad.List[$name]
        Gate ($queueMap[$name] -ceq $m.Sha1) ('D4_SHA1_MISMATCH_' + $name)
        [void]$pairs.Add($name.ToLowerInvariant() + '|sha-1=' + $m.Sha1.ToLowerInvariant())
        $suffix=[IO.Path]::GetExtension($name).TrimStart('.').ToUpperInvariant()
        if (-not $ext.Contains($suffix)) { $suffix='OTHER' }
        $ext[$suffix]=[int]$ext[$suffix]+1
        $class=Get-Classification $name
        [void]$rows.Add([pscustomobject][ordered]@{
            out=$name;sha1=$m.Sha1;rename_guid=$triad.Renames[$name];expires_utc=$m.ExpiresUtc
            size_display=$m.SizeDisplay;category=$class
            download_policy='KEEP_UNTIL_CONVERTER_CLOSURE_PROVEN';candidate_only=($class -in @('FOD_CONVERTER_REFERENCE_REVIEW','EDGE_WEBVIEW_REVIEW'))
        })
    }
    $canonicalPairs=[string[]]$pairs.ToArray()
    [Array]::Sort($canonicalPairs,[StringComparer]::Ordinal)
    $contentHash=HashText ([string]::Join("`n",$canonicalPairs))
    $snapshot=[ordered]@{
        schema='BlueLite.UniversalUUPSourceContract.S19A.v1'
        original_zip_sha256=$zipSha
        d4_module_sha256=$moduleSha
        original_windows_queue_sha256=(Digest $QueuePath)
        windows_d4_identity_sha256=([string]$identity.SHA256).ToUpperInvariant()
        windows_source_content_sha256=$contentHash
        launcher=$launcher
        triad=$triad.Files
        windows_records=$identity.Count
        extensions=$ext
        selection_profile=$Profile
        exclusion_decisions_applied=0
        network_requests=0
        converter_executed=$false
        image_mutations=$false
        files=$rows.ToArray()
    }
    $json=ConvertTo-Json -InputObject $snapshot -Depth 12 -Compress
    return [pscustomobject]@{Contract=$snapshot;CanonicalSha256=(HashText $json)}
}
function Get-Output([string]$Suffix) { return $OutputPrefix + $Suffix }

$compiled=Compile $InputDir $OriginalUupZip $WindowsQueue $D4Module
if ($Mode -ceq 'Verify') {
    Gate ($ExpectedReceiptSha256 -match '^[A-Fa-f0-9]{64}$') 'VERIFY_EXPECTED_RECEIPT_SHA_REQUIRED'
    $receiptPath=Get-Output 'Receipt.json';$reportPath=Get-Output 'Report.json'
    Gate ([IO.File]::Exists($receiptPath) -and [IO.File]::Exists($reportPath)) 'VERIFY_MISSING_PARENT_FILES'
    Gate ((Digest $receiptPath) -ceq $ExpectedReceiptSha256.ToUpperInvariant()) 'VERIFY_RECEIPT_SHA'
    $receipt=Read-Text $receiptPath | ConvertFrom-Json -ErrorAction Stop
    $report=Read-Text $reportPath | ConvertFrom-Json -ErrorAction Stop
    Gate ($receipt.operation -ceq $Operation -and $report.operation -ceq $Operation) 'VERIFY_OPERATION_ID'
    Gate ((Digest $reportPath) -ceq $receipt.report_sha256) 'VERIFY_REPORT_SHA'
    Gate ($report.contract_sha256 -ceq $compiled.CanonicalSha256) 'VERIFY_SNAPSHOT_RECOMPUTE'
    Gate ($report.contract.windows_records -eq 98 -or $report.contract.windows_records -gt 0) 'VERIFY_EMPTY_WINDOWS_SET'
    Gate ($report.contract.exclusion_decisions_applied -eq 0 -and $report.contract.network_requests -eq 0) 'VERIFY_NOT_DRY_RUN'
    $qa='BLUELITE_S19A_UNIVERSAL_SOURCE_CONTRACT_INDEPENDENT_QA_PASS|WINDOWS='+$report.contract.windows_records+'|TRIAD=D4_EQUAL|EXCLUDED=0|NO_NETWORK=TRUE|CONVERTER_NOT_RUN=TRUE|RECEIPT_SHA256='+$ExpectedReceiptSha256.ToUpperInvariant()
    New-Text (Get-Output 'IndependentQA.txt') ($qa+"`n")
    Write-Output $qa
    return
}

foreach ($n in @('Report.json','Receipt.json','IndependentQA.txt','Evidence.zip')) {
    Gate (-not [IO.File]::Exists((Get-Output $n))) ('OUTPUT_COLLISION_' + $n)
}
Gate ([IO.Directory]::Exists([IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($OutputPrefix)))) 'OUTPUT_PARENT_MISSING'
$scriptSha=Digest $PSCommandPath
$report=[ordered]@{
    operation=$Operation;result='SOURCE_CONTRACT_DRYRUN_PASS_PENDING_INDEPENDENT_QA'
    contract_sha256=$compiled.CanonicalSha256
    contract=$compiled.Contract
}
$reportJson=ConvertTo-Json -InputObject $report -Depth 14
New-Text (Get-Output 'Report.json') ($reportJson+"`n")
$receipt=[ordered]@{
    operation=$Operation;result='RECORDED_PENDING_SEPARATE_VERIFY'
    script_sha256=$scriptSha;report_sha256=(Digest (Get-Output 'Report.json'))
    contract_sha256=$compiled.CanonicalSha256
    utc=[DateTimeOffset]::UtcNow.ToString('o')
}
New-Text (Get-Output 'Receipt.json') ((ConvertTo-Json -InputObject $receipt -Depth 4)+"`n")
$receiptSha=Digest (Get-Output 'Receipt.json')
$pwsh=(Get-Command pwsh -ErrorAction Stop).Source
$verifyArgs=@('-NoProfile','-NonInteractive','-File',$PSCommandPath,'-Mode','Verify','-InputDir',$InputDir,'-OriginalUupZip',$OriginalUupZip,'-WindowsQueue',$WindowsQueue,'-D4Module',$D4Module,'-ExpectedSourceZipSha256',$ExpectedSourceZipSha256,'-ExpectedD4ModuleSha256',$ExpectedD4ModuleSha256,'-Profile',$Profile,'-OutputPrefix',$OutputPrefix,'-ExpectedReceiptSha256',$receiptSha)
if ($ExpectedWindowsIdentitySha256) { $verifyArgs+=@('-ExpectedWindowsIdentitySha256',$ExpectedWindowsIdentitySha256) }
& $pwsh @verifyArgs
Gate ($LASTEXITCODE -eq 0) 'CHILD_VERIFY_FAILED'
Gate ([IO.File]::Exists((Get-Output 'IndependentQA.txt'))) 'MISSING_FRESH_QA'
$zipPath=Get-Output 'Evidence.zip'
$zstream=[IO.FileStream]::new($zipPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
try {
    $archive=[IO.Compression.ZipArchive]::new($zstream,[IO.Compression.ZipArchiveMode]::Create,$true)
    try {
        foreach ($n in @('Report.json','Receipt.json','IndependentQA.txt')) {
            $source=Get-Output $n
            $item=$archive.CreateEntry($n,[IO.Compression.CompressionLevel]::Optimal)
            $input=[IO.File]::OpenRead($source)
            $output=$item.Open()
            try { $input.CopyTo($output) } finally { $output.Dispose();$input.Dispose() }
        }
    } finally { $archive.Dispose() }
} finally { $zstream.Dispose() }
$test=[IO.Compression.ZipFile]::OpenRead($zipPath)
try { Gate ($test.Entries.Count -eq 3) 'EVIDENCE_ZIP_MEMBER_COUNT' } finally { $test.Dispose() }
Write-Output ('BLUELITE_S19A_SOURCE_CONTRACT_DRYRUN_PASS|WINDOWS='+$compiled.Contract.windows_records+'|TRIAD_D4_EQUAL=TRUE|NO_DOWNLOAD=TRUE|FRESH_VERIFY=PASS|CONVERTER_NOT_RUN=TRUE')
Write-Output ('EVIDENCE='+$zipPath)
```
