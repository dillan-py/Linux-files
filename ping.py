#With a text file of hostnames to find the IP addresses from, will show the hostname and ip address in result
import socket
import sys

def get_ip_address(hostname):
    """Resolve a hostname to its IP address."""
    try:
        ip_address = socket.gethostbyname(hostname)
        return ip_address
    except socket.gaierror:
        return "Unable to resolve"

def read_hosts(file_path):
    """Read hostnames from a file, one per line."""
    try:
        with open(file_path, 'r') as file:
            # Strip whitespace and filter out empty lines
            return [line.strip() for line in file if line.strip()]
    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found.")
        return []
    except Exception as e:
        print(f"Error reading file: {e}")
        return []

def main():
    # Check if a file path is provided as a command-line argument
    if len(sys.argv) != 2:
        print("Usage: python3 ping.py <hosts_file>")
        sys.exit(1)

    file_path = sys.argv[1]
    hosts = read_hosts(file_path)

    if not hosts:
        print("No hosts to process.")
        sys.exit(1)

    # Process each host
    for host in hosts:
        ip = get_ip_address(host)
        print(f"{host}: {ip}")

if __name__ == "__main__":
