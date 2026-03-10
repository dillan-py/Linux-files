# remove_duplicate_ips_simple.py
# Removes dupliate items in a list for IP addresses which may have many repeating.

print("Enter IP addresses (one per line)")
print("When finished, just press Enter on an empty line\n")

ips = []

while True:
    line = input().strip()
    if not line:          # empty line → stop
        break
    ips.append(line)

# Remove duplicates while preserving first appearance order
seen = set()
unique_ips = []

for ip in ips:
    if ip not in seen:
        seen.add(ip)
        unique_ips.append(ip)

print("\nUnique IPs:")
for ip in unique_ips:
    print(ip)

print(f"\nTotal unique: {len(unique_ips)}")
