#Requires -Version 5.1
<#
.SYNOPSIS
    Build the msprex Windows Installer package (MSI) with WiX 3.14.

.DESCRIPTION
    Produces dist\msprex-<version>-x64.msi from installer\msprex.wxs.

    The MSI version is taken from the module manifest (msprex\msprex.psd1) by
    default, so the package can never advertise a version the module does not
    have. Pass -Version only to build a prerelease identifier or to test.

    Signing is optional and never faked: without -SignPfx the MSI is left
    unsigned and this script says so on the last line.

.PARAMETER WixBin
    Directory containing candle.exe / light.exe. Defaults to $env:WIX\bin,
    then PATH.

.PARAMETER SignPfx
    Path to a .pfx code-signing certificate. Requires the password in
    -SignPassword or the MSPREX_SIGN_PASSWORD environment variable.

.EXAMPLE
    pwsh -File installer\build.ps1 -WixBin C:\tools\wix\bin

.EXAMPLE
    $env:MSPREX_SIGN_PASSWORD = '...'
    pwsh -File installer\build.ps1 -SignPfx C:\certs\codesign.pfx
#>
[CmdletBinding()]
param(
    [string]$Version,
    [string]$WixBin,
    [string]$OutDir,
    [string]$SignPfx,
    [string]$SignPassword,
    [string]$TimestampUrl = 'http://timestamp.digicert.com',
    [switch]$SkipSign
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceDir = Join-Path $repoRoot 'msprex'
$outDir = if ($OutDir) { $OutDir } else { Join-Path $repoRoot 'dist' }
$objDir = Join-Path $repoRoot 'installer\obj'

function Resolve-WixTool {
    param([string]$Name)
    $candidates = @()
    if ($WixBin) { $candidates += (Join-Path $WixBin "$Name.exe") }
    if ($env:WIX) { $candidates += (Join-Path $env:WIX "bin\$Name.exe") }
    foreach ($c in $candidates) { if (Test-Path -LiteralPath $c) { return $c } }
    $cmd = Get-Command "$Name.exe" -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    throw "Could not find $Name.exe. Install WiX 3.14 and pass -WixBin, or set WIX to its install root."
}

# --- Version: module manifest is the source of truth ------------------------
$manifest = Join-Path $sourceDir 'msprex.psd1'
$moduleVersion = [version](Select-String -LiteralPath $manifest -Pattern "^\s*ModuleVersion\s*=\s*'([0-9.]+)'" |
        Select-Object -First 1).Matches[0].Groups[1].Value
if (-not $Version) { $Version = $moduleVersion.ToString() }
$parsed = $null
if (-not [version]::TryParse($Version, [ref]$parsed)) {
    throw "-Version '$Version' is not a valid MSI version (expected major.minor.build)."
}
if ($parsed -ne $moduleVersion) {
    throw "Refusing to build: MSI version $Version does not match ModuleVersion $moduleVersion in msprex.psd1. Bump both."
}

# --- Required payload must exist before invoking the compiler ---------------
$required = @(
    (Join-Path $sourceDir 'msprex.psd1'),
    (Join-Path $sourceDir 'msprex.psm1'),
    (Join-Path $repoRoot 'LICENSE'),
    (Join-Path $PSScriptRoot 'LICENSE.rtf')
)
foreach ($f in $required) {
    if (-not (Test-Path -LiteralPath $f)) { throw "Missing payload file: $f" }
}

$candle = Resolve-WixTool -Name 'candle'
$light = Resolve-WixTool -Name 'light'

New-Item -ItemType Directory -Force -Path $outDir, $objDir | Out-Null
$wixobj = Join-Path $objDir 'msprex.wixobj'
$msi = Join-Path $outDir "msprex-$Version-x64.msi"

Write-Host "candle $Version ($(Split-Path $candle -Leaf))"
& $candle -nologo -arch x64 `
    "-dVersion=$Version" `
    "-dSourceDir=$sourceDir" `
    "-dRepoRoot=$repoRoot" `
    -out $wixobj `
    (Join-Path $PSScriptRoot 'msprex.wxs')
if ($LASTEXITCODE -ne 0) { throw "candle failed with exit code $LASTEXITCODE" }

Write-Host "light -> $msi"
& $light -nologo -ext WixUIExtension -cultures:en-us -out $msi $wixobj
if ($LASTEXITCODE -ne 0) { throw "light failed with exit code $LASTEXITCODE" }

# --- Optional Authenticode signing -----------------------------------------
$signed = $false
if ($SignPfx -and -not $SkipSign) {
    if (-not (Test-Path -LiteralPath $SignPfx)) { throw "Certificate not found: $SignPfx" }
    if (-not $SignPassword) { $SignPassword = $env:MSPREX_SIGN_PASSWORD }
    if (-not $SignPassword) { throw "Signing requested but no password supplied (-SignPassword or MSPREX_SIGN_PASSWORD)." }

    $signtool = (Get-Command 'signtool.exe' -ErrorAction SilentlyContinue).Source
    if (-not $signtool) {
        $kits = Get-ChildItem 'C:\Program Files (x86)\Windows Kits\10\bin\*\x64\signtool.exe' -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending | Select-Object -First 1
        if ($kits) { $signtool = $kits.FullName }
    }
    if (-not $signtool) { throw "signtool.exe not found. Install the Windows SDK or sign on a runner that has it." }

    Write-Host "signing $msi (SHA256, RFC 3161 timestamp)"
    & $signtool sign /fd SHA256 /f $SignPfx /p $SignPassword /tr $TimestampUrl /td SHA256 $msi
    if ($LASTEXITCODE -ne 0) { throw "signtool sign failed with exit code $LASTEXITCODE" }

    & $signtool verify /pa /v $msi
    if ($LASTEXITCODE -ne 0) { throw "signtool verify failed with exit code $LASTEXITCODE" }
    $signed = $true
}

$hash = (Get-FileHash -LiteralPath $msi -Algorithm SHA256).Hash.ToLowerInvariant()
$size = (Get-Item -LiteralPath $msi).Length
Set-Content -LiteralPath "$msi.sha256" -Value "$hash  $(Split-Path $msi -Leaf)" -Encoding ascii

Write-Host ''
Write-Host "msi      : $msi"
Write-Host "size     : $size bytes"
Write-Host "sha256   : $hash"
Write-Host ("signature: " + $(if ($signed) { 'Signed and timestamped (Authenticode)' } else { 'UNSIGNED (no certificate supplied)' }))
