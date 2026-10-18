& {
 $ErrorActionPreference='Stop'
 Set-StrictMode -Version Latest
 $original='C:\work\E2E\BlueLite_DL_R26_D6_26300.9711_2b22470a\UUPs'
 $staged='C:\work\E2E\BlueLite_Stage1_S20_26300.9711_ConverterWorkspace\UUPs'
 $report='C:\work\logs\BlueLite_Storage_S42D_26300.9711_UUPShape.txt'
 $csv='C:\work\logs\BlueLite_Storage_S42D_26300.9711_UUPShape.csv'
 $s42='C:\work\logs\BlueLite_Storage_S42_26300.9711_UUPPairs.txt'
 $utf8=[Text.UTF8Encoding]::new($false)
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'PS7_REQUIRED'}
 $principal=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'ADMIN_REQUIRED'}
 if(-not(Test-Path -LiteralPath 'C:\work\logs' -PathType Container)){throw 'LOG_DIR_MISSING'}
 foreach($out in @($report,$csv)){if(Test-Path -LiteralPath $out){throw 'S42D_OUTPUT_EXISTS_NO_OVERWRITE'}}
 [IO.File]::WriteAllText($report,'',$utf8)
 function Note([string]$msg){
  $line=(Get-Date -Format 'HH:mm:ss')+' | '+$msg
  Write-Host $line
  [IO.File]::AppendAllText($report,$line+[Environment]::NewLine,$utf8)
 }
 $result='HOLD_S42D_READONLY_DIAGNOSTIC'
 try{
  Note 'S42D_READONLY_EXACT_TWO_UUP_ROOTS_SHAPE_ONLY'
  $pin=Get-Item -LiteralPath $s42 -ErrorAction Stop
  if($pin.Length -ne 668 -or
    (Get-FileHash -LiteralPath $s42 -Algorithm SHA256).Hash -cne '5C83E45CD28B493B0F0853F9028E547479118D56542CC52C4A70B67E683DFACB'){
   throw 'ORIGINAL_S42_HOLD_RECEIPT_MISMATCH'
  }
  Note 'PIN_ORIGINAL_S42_HOLD=PASS;BYTES=668'
  $roots=@($original,$staged)
  $sets=[System.Collections.Generic.List[object]]::new()
  foreach($root in $roots){
   $d=Get-Item -LiteralPath $root -Force -ErrorAction Stop
   if(-not $d.PSIsContainer){throw ('NOT_DIRECTORY='+$root)}
   $cursor=$d
   $workSeen=$false
   while($null -ne $cursor){
    if(($cursor.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){
     throw ('REPARSE_ANCESTOR='+$cursor.FullName)
    }
    if($cursor.FullName -ieq 'C:\work'){$workSeen=$true;break}
    $cursor=$cursor.Parent
   }
   if(-not $workSeen){throw ('OUTSIDE_WORK='+$root)}
   $entries=@(Get-ChildItem -LiteralPath $root -Force -ErrorAction Stop)
   $files=@($entries|Where-Object {-not $_.PSIsContainer})
   $dirs=@($entries|Where-Object {$_.PSIsContainer})
   $sum=[long]0
   foreach($f in $files){$sum += [long]$f.Length}
   $sets.Add([pscustomobject]@{Root=$root;All=$entries;Files=$files;Dirs=$dirs;Bytes=$sum})
   Note ('ROOT='+$root)
   Note ('FILES='+$files.Count+';DIRECTORIES='+$dirs.Count+';ITEMS='+$entries.Count+';FILE_BYTES='+$sum)
   foreach($dir in $dirs){Note ('DIRECTORY_ENTRY='+$dir.Name+';ATTR='+$dir.Attributes)}
  }
  $one=$sets[0];$two=$sets[1]
  $a=@{};$b=@{}
  foreach($f in $one.All){
   if($a.ContainsKey($f.Name)){throw ('SOURCE_DUPLICATE_NAME='+$f.Name)}
   $a[$f.Name]=$f
  }
  foreach($f in $two.All){
   if($b.ContainsKey($f.Name)){throw ('STAGED_DUPLICATE_NAME='+$f.Name)}
   $b[$f.Name]=$f
  }
  $names=@($a.Keys)+@($b.Keys)
  $names=@($names|Sort-Object -Unique)
  $rows=[System.Collections.Generic.List[object]]::new()
  foreach($name in $names){
   $x=$null;$y=$null
   if($a.ContainsKey($name)){$x=$a[$name]}
   if($b.ContainsKey($name)){$y=$b[$name]}
   $xKind=if($null -eq $x){'ABSENT'}elseif($x.PSIsContainer){'DIRECTORY'}else{'FILE'}
   $yKind=if($null -eq $y){'ABSENT'}elseif($y.PSIsContainer){'DIRECTORY'}else{'FILE'}
   $xBytes=if($xKind -eq 'FILE'){[long]$x.Length}else{$null}
   $yBytes=if($yKind -eq 'FILE'){[long]$y.Length}else{$null}
   $diff='SAME_SHAPE_NOT_HASHED'
   if($null -eq $x){$diff='ONLY_STAGED'}
   elseif($null -eq $y){$diff='ONLY_ORIGINAL'}
   elseif($xKind -ne $yKind){$diff='KIND_MISMATCH'}
   elseif($xKind -eq 'FILE' -and $xBytes -ne $yBytes){$diff='SIZE_MISMATCH'}
   if($null -ne $x -and ($x.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){$diff+=';ORIGINAL_REPARSE'}
   if($null -ne $y -and ($y.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){$diff+=';STAGED_REPARSE'}
   $rows.Add([pscustomobject]@{
    Name=$name;OriginalKind=$xKind;StagedKind=$yKind;
    OriginalBytes=$xBytes;StagedBytes=$yBytes;
    OriginalAttributes=if($null -eq $x){''}else{[string]$x.Attributes};
    StagedAttributes=if($null -eq $y){''}else{[string]$y.Attributes};
    ShapeClassification=$diff
   })
  }
  $rows|Export-Csv -LiteralPath $csv -Encoding utf8 -NoTypeInformation
  $unexpected=@($rows|Where-Object {$_.ShapeClassification -ne 'SAME_SHAPE_NOT_HASHED'})
  Note ('UNION_ITEMS='+$rows.Count+';SHAPE_DIFFERENCES='+$unexpected.Count)
  foreach($r in $unexpected){
   Note ('DIFFERENCE='+$r.ShapeClassification+';NAME='+$r.Name+';ORIGINAL_BYTES='+$r.OriginalBytes+';STAGED_BYTES='+$r.StagedBytes)
  }
  $asExpected=($one.Files.Count -eq 129 -and $two.Files.Count -eq 129 -and
               $one.Dirs.Count -eq 0 -and $two.Dirs.Count -eq 0)
  Note ('S42_EXACT_129_FILE_SHAPE_NOW='+$asExpected)
  Note 'PAIR_SHA256=NOT_RUN;IDENTITY=NOT_CERTIFIED;DELETION=NOT_AUTHORIZED'
  $result='PASS_S42D_SHAPE_DIAGNOSTIC_CAPTURED_ONLY'
 }catch{
  Note ('FAIL_CLOSED='+$_.Exception.Message)
 }finally{
  Note ('RESULT='+$result)
  Note 'NO_DOWNLOAD_NO_DELETE_NO_CONVERTER_NO_WIM_MUTATION'
  Write-Host ('REPORT='+$report)
  if(Test-Path -LiteralPath $csv -PathType Leaf){Write-Host ('CSV='+$csv)}
 }
}