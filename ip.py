ip_list = []

print("Enter IPv4 addresses (one per line). Press Enter twice to finish:")

while True:
    ip = input()
    if ip == "":
        break
    ip_list.append(ip.strip())

print(', '.join(ip_list))
