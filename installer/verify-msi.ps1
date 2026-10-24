#Requires -Version 5.1
<#
    Inspect a built MSI without installing it: product identity, install layout,
    and the real file payload inside the embedded cabinet.

    Uses the WiX DTF managed API (Microsoft.Deployment.WindowsInstaller), which
    ships with WiX 3.14, needs no elevation, and runs no part of the package.
    Exits non-zero when a check fails so CI can gate the release on it.

.PARAMETER WixBin
    Directory holding Microsoft.Deployment.WindowsInstaller.dll. Defaults to
    $env:WIX\bin, then the directory of candle.exe on PATH.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Msi,
    [Parameter(Mandatory = $true)][string]$SourceDir,
    [string]$WixBin
)

$ErrorActionPreference = 'Stop'
$script:failures = New-Object System.Collections.Generic.List[string]

function Check([bool]$ok, [string]$label, [string]$detail) {
    if ($ok) { Write-Host "PASS  $label  $detail" }
    else { Write-Host "FAIL  $label  $detail"; $null = $script:failures.Add($label) }
}

function Resolve-WixBin {
    param([string]$Explicit)
    $candidates = @()
    if ($Explicit) { $candidates += $Explicit }
    if ($env:WIX) { $candidates += (Join-Path $env:WIX 'bin') }
    $candle = Get-Command 'candle.exe' -ErrorAction SilentlyContinue
    if ($candle) { $candidates += (Split-Path $candle.Source -Parent) }
    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath (Join-Path $c 'Microsoft.Deployment.WindowsInstaller.dll')) { return $c }
    }
    throw 'WiX DTF assemblies not found. Pass -WixBin, set WIX, or put candle.exe on PATH.'
}

$Msi = (Resolve-Path -LiteralPath $Msi).Path
$SourceDir = (Resolve-Path -LiteralPath $SourceDir).Path
$wixBin = Resolve-WixBin -Explicit $WixBin

Add-Type -Path (Join-Path $wixBin 'Microsoft.Deployment.WindowsInstaller.dll')
Add-Type -Path (Join-Path $wixBin 'Microsoft.Deployment.Compression.dll')
Add-Type -Path (Join-Path $wixBin 'Microsoft.Deployment.Compression.Cab.dll')

$db = New-Object Microsoft.Deployment.WindowsInstaller.Database($Msi, [Microsoft.Deployment.WindowsInstaller.DatabaseOpenMode]::ReadOnly)

function Get-Rows([string]$sql) {
    $rows = New-Object System.Collections.ArrayList
    $view = $db.OpenView($sql)
    try {
        $view.Execute()
        while ($null -ne ($rec = $view.Fetch())) {
            $row = New-Object object[] $rec.FieldCount
            for ($i = 0; $i -lt $rec.FieldCount; $i++) { $row[$i] = $rec.GetString($i + 1) }
            $null = $rows.Add($row)
        }
    }
    finally { $view.Close() }
    # The leading comma stops PowerShell from unrolling the outer array, which
    # would collapse a single-row result into its columns.
    return , $rows.ToArray()
}

# "short|long" -> "long"
function Get-LongName([string]$name) {
    if ($name -and $name.Contains('|')) { return $name.Substring($name.IndexOf('|') + 1) }
    return $name
}

Write-Host '== identity'
$props = @{}
foreach ($row in (Get-Rows 'SELECT `Property`, `Value` FROM `Property`')) { $props[$row[0]] = $row[1] }

$productName = $props['ProductName']
$version = $props['ProductVersion']
$upgrade = $props['UpgradeCode']
$table = [ordered]@{
    'MSI file'       = $Msi
    'ProductName'    = $productName
    'ProductVersion' = $version
    'Manufacturer'   = $props['Manufacturer']
    'UpgradeCode'    = $upgrade
    'ProductCode'    = $props['ProductCode']
}
foreach ($k in $table.Keys) { Write-Host ("{0,-15} : {1}" -f $k, $table[$k]) }

Check ($productName -eq 'msprex') 'ProductName is msprex' "$productName"
Check ($version -match '^\d+\.\d+\.\d+$') 'ProductVersion is major.minor.build' "$version"
Check ((($upgrade -replace '[{}-]', '').ToLowerInvariant()) -eq 'c3b2e2b6ceba4a38add35bdfe00248c4') 'UpgradeCode is stable' "$upgrade"
Check ($props['ALLUSERS'] -eq '1') 'per-machine install' "ALLUSERS=$($props['ALLUSERS'])"
Check ($props['ARPNOMODIFY'] -eq '1') 'ARP hides Modify' "ARPNOMODIFY=$($props['ARPNOMODIFY'])"

Write-Host ''
Write-Host '== install layout'
$components = @{}
foreach ($row in (Get-Rows 'SELECT `Component`, `Directory_`, `Attributes` FROM `Component`')) {
    $components[$row[0]] = @($row[1], $row[2])
}

$files = @()
foreach ($row in (Get-Rows 'SELECT `File`, `FileName`, `FileSize`, `Component_` FROM `File`')) {
    $comp = $components[$row[3]]
    $files += , @{
        Id       = $row[0]
        Name     = (Get-LongName $row[1])
        Size     = [int]$row[2]
        Dir      = if ($comp) { $comp[0] } else { '' }
        Is64Bit  = if ($comp) { ([int]$comp[1] -band 256) -ne 0 } else { $false }
    }
}
foreach ($f in $files) {
    Write-Host ("  {0,-12} {1,-14} {2,6} bytes  64-bit={3}" -f $f.Dir, $f.Name, $f.Size, $f.Is64Bit)
}
Check ($files.Count -eq 3) 'exactly 3 files packaged' "$($files.Count) files"
Check (@($files | Where-Object { $_.Dir -eq 'MSPREXDIR' }).Count -eq 3) 'all files target MSPREXDIR' 'module directory'
Check (@($files | Where-Object { -not $_.Is64Bit }).Count -eq 0) 'all components marked 64-bit' 'Win64=yes'

$dirs = @{}
foreach ($row in (Get-Rows 'SELECT `Directory`, `Directory_Parent`, `DefaultDir` FROM `Directory`')) {
    $dirs[$row[0]] = @($row[1], $row[2])
}
$segments = @()
$node = 'MSPREXDIR'
while ($node -and $dirs.ContainsKey($node)) {
    $segment = Get-LongName $dirs[$node][1]
    # '.' marks a system folder; keep the Id so the path shows where Windows puts it.
    $segments = @($(if ($segment -eq '.') { "<$node>" } else { $segment })) + $segments
    $node = $dirs[$node][0]
}
$resolved = $segments -join '\'
Write-Host "  resolved: $resolved"
Check ($resolved -match '<ProgramFiles64Folder>\\WindowsPowerShell\\Modules\\msprex$') 'installs into the PowerShell module path' $resolved
Check (@($files | Where-Object { $_.Name -eq 'msprex.psd1' }).Count -eq 1) 'module manifest is packaged' 'msprex.psd1'
Check (@($files | Where-Object { $_.Name -eq 'msprex.psm1' }).Count -eq 1) 'module script is packaged' 'msprex.psm1'

Write-Host ''
Write-Host '== payload integrity (embedded cabinet)'
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('msprex-verify-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
try {
    $cabName = $null
    foreach ($row in (Get-Rows 'SELECT `Cabinet` FROM `Media`')) { if ($row[0]) { $cabName = $row[0].TrimStart([char]'#'); break } }
    Write-Host "  cabinet stream: $cabName"

    $cabPath = Join-Path $tmp $cabName
    $view = $db.OpenView("SELECT ``Data`` FROM ``_Streams`` WHERE ``Name``='$cabName'")
    try {
        $view.Execute()
        $rec = $view.Fetch()
        if ($rec) { $rec.GetStream(1, $cabPath) } else { throw "stream $cabName not found in MSI" }
    }
    finally { $view.Close() }
    Write-Host "  extracted $cabName ($((Get-Item -LiteralPath $cabPath).Length) bytes)"

    $cab = New-Object Microsoft.Deployment.Compression.Cab.CabInfo($cabPath)
    $entries = @{}
    foreach ($entry in $cab.GetFiles()) { $entries[$entry.Name] = $entry }

    $unpacked = Join-Path $tmp 'payload'
    New-Item -ItemType Directory -Force -Path $unpacked | Out-Null
    $cab.Unpack($unpacked)

    foreach ($src in @('msprex.psd1', 'msprex.psm1')) {
        $fileRow = $files | Where-Object { $_.Name -eq $src } | Select-Object -First 1
        $want = (Get-FileHash -LiteralPath (Join-Path $SourceDir $src) -Algorithm SHA256).Hash
        $entryPath = if ($fileRow -and $entries.ContainsKey($fileRow.Id)) { Join-Path $unpacked (Split-Path $entries[$fileRow.Id].Name -Leaf) } else { $null }
        if (-not $entryPath -or -not (Test-Path -LiteralPath $entryPath)) {
            $entryPath = Get-ChildItem -LiteralPath $unpacked -Recurse -File | Where-Object { $_.Name -eq $fileRow.Id } | Select-Object -First 1
            $entryPath = if ($entryPath) { $entryPath.FullName } else { $null }
        }
        $got = if ($entryPath) { (Get-FileHash -LiteralPath $entryPath -Algorithm SHA256).Hash } else { '' }
        Check ($got -eq $want) "payload $src matches source" $(if ($got) { 'sha256 ok' } else { 'missing from cab' })
    }
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

$db.Close()
Write-Host ''
if ($script:failures.Count -gt 0) {
    Write-Host "FAILED: $($script:failures -join ', ')"
    exit 1
}
Write-Host 'All MSI checks passed.'
