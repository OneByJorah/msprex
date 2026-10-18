<#
.SYNOPSIS
    MSP automation engine - PowerShell-based remote management, scripted deployments, monitoring checks, and client provisioning.

.DESCRIPTION
    MSP automation engine - PowerShell-based remote management, scripted deployments, monitoring checks, and client provisioning for managed service providers.

.AUTHOR
    OneByJorah <info@jorahone.com>

.COPYRIGHT
    2026 JorahOne, LLC

.LICENSE
    MIT
#>

@{
    ModuleVersion = '1.0.0'
    CompatiblePSEditions = @('Desktop', 'Core')
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'OneByJorah'
    CompanyName = 'JorahOne, LLC'
    Copyright = '2026 JorahOne, LLC'
    ModuleName = 'msprex'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Get-MSPHost', 'Invoke-MSPDeploy', 'Test-MSPHealth', 'New-MSPClient')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('msp', 'automation', 'powershell', 'monitoring', 'deployment', 'jorahone')
            LicenseUri = 'https://github.com/OneByJorah/msprex/blob/main/LICENSE'
            ProjectUri = 'https://github.com/OneByJorah/msprex'
            ReleaseNotes = 'Initial release: MSP automation engine with remote management, deployment, monitoring, and client provisioning.'
        }
    }
}
