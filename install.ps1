<#
.SYNOPSIS
    msprex — Windows 10/11 Provisioning & Debloat Utility
.DESCRIPTION
    Downloads and executes the MSP-Ultra-Debloat script for Windows provisioning.
    Supports parameterized execution for remote technician scenarios.

.PARAMETER ScriptUrl
    URL to the debloat script. Defaults to the GitHub raw URL.
.PARAMETER SkipDeploy
    If set, only downloads the script without executing it.
.PARAMETER TempPath
    Temporary path to save the downloaded script. Defaults to $env:TEMP\debloat.ps1.
.PARAMETER ExecutionPolicy
    Execution policy to use. Defaults to RemoteSigned for the process scope.

.EXAMPLE
    .\install.ps1
    Run with default settings (download and execute debloat script).

.EXAMPLE
    .\install.ps1 -SkipDeploy
    Download the debloat script without executing it.

.EXAMPLE
    .\install.ps1 -ScriptUrl "https://raw.githubusercontent.com/OneByJorah/msprex/main/debloat/MSP-Ultra-Debloat.ps1"
    Run from a custom script URL.

.NOTES
    Requires Windows 10/11 with PowerShell 5.1+.
    Must be run from an elevated (Administrator) PowerShell prompt.
    This tool is Windows-only and cannot be containerized.
#>

param(
    [string]$ScriptUrl = "https://raw.githubusercontent.com/OneByJorah/msprex/main/debloat/MSP-Ultra-Debloat.ps1",
    [switch]$SkipDeploy,
    [string]$TempPath = "$env:TEMP\debloat.ps1",
    [string]$ExecutionPolicy = "RemoteSigned"
)

# ── System Requirements Check ──────────────────────────────
$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
$psVersion = $PSVersionTable.PSVersion

Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           msprex — Windows Provisioning      ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "System Information:" -ForegroundColor Yellow
Write-Host "  OS: $($osInfo.Caption) (Build $($osInfo.BuildNumber))"
Write-Host "  PowerShell: $psVersion"
Write-Host "  Architecture: $($osInfo.OSArchitecture)"
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "WARNING: Not running as Administrator. Some operations may fail." -ForegroundColor Yellow
    Write-Host "Restart the script from an elevated PowerShell prompt for full functionality." -ForegroundColor Yellow
    Write-Host ""
}

# ── Download Script ───────────────────────────────────────
# Enforce TLS 1.2+ (Windows PowerShell 5.1 does not always negotiate it by default)
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

Write-Host "Downloading debloat script from:" -ForegroundColor Green
Write-Host "  $ScriptUrl"
Write-Host "  → $TempPath"
Write-Host ""

try {
    Invoke-WebRequest -Uri $ScriptUrl -OutFile $TempPath -ErrorAction Stop
    Write-Host "✓ Download complete." -ForegroundColor Green
} catch {
    Write-Host "✗ Download failed: $_" -ForegroundColor Red
    exit 1
}

# ── Execute Script ─────────────────────────────────────────
if (-not $SkipDeploy) {
    Write-Host "Executing debloat script..." -ForegroundColor Green
    Write-Host ""
    
    try {
        powershell -NoProfile -ExecutionPolicy $ExecutionPolicy -File $TempPath
        if ($LASTEXITCODE -ne 0) {
            Write-Host "✗ Execution failed (exit code $LASTEXITCODE)." -ForegroundColor Red
            exit 1
        }
        Write-Host ""
        Write-Host "✓ msprex completed successfully." -ForegroundColor Green
        Write-Host "  A system restart is recommended to apply all changes." -ForegroundColor Yellow
    } catch {
        Write-Host "✗ Execution failed: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Script downloaded to: $TempPath" -ForegroundColor Yellow
    Write-Host "Run it manually with: powershell -ExecutionPolicy $ExecutionPolicy -File `"$TempPath`"" -ForegroundColor Yellow
}

# ── Cleanup ────────────────────────────────────────────────
if (-not $SkipDeploy) {
    Remove-Item $TempPath -Force -ErrorAction SilentlyContinue
}
