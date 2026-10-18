function Get-MSPHost {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$ComputerName)
    Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $ComputerName |
        Select-Object Caption, Version, LastBootUpTime, FREEPhysicalMemory
}
function Invoke-MSPDeploy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$ComputerName,
        [Parameter(Mandatory = $true)][string]$ScriptPath
    )
    $script = Get-Content -Path $ScriptPath -Raw
    Invoke-Command -ComputerName $ComputerName -ScriptBlock { param($s) Invoke-Expression $s } -ArgumentList $script
}
function Test-MSPHealth {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$ComputerName,
        [int]$CPUThreshold = 80,
        [int]$MemoryThreshold = 80
    )
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $ComputerName
    $cpu = Get-CimInstance -ClassName Win32_Processor -ComputerName $ComputerName
    $memUsage = ($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize * 100
    return @{
        ComputerName = $ComputerName
        CPUUsage = $cpu.LoadPercentage
        MemoryUsage = [math]::Round($memUsage, 1)
        Status = if ($cpu.LoadPercentage -lt $CPUThreshold -and $memUsage -lt $MemoryThreshold) { 'Healthy' } else { 'Warning' }
    }
}
function New-MSPClient {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$ClientName,
        [Parameter(Mandatory = $true)][string]$ContactEmail
    )
    return @{
        ClientName = $ClientName
        ContactEmail = $ContactEmail
        CreatedAt = Get-Date
        Status = 'Active'
    }
}
Export-ModuleMember -Function @('Get-MSPHost', 'Invoke-MSPDeploy', 'Test-MSPHealth', 'New-MSPClient')
