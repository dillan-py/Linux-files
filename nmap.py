# Automated Nmap scripts, enter the number of the option you want and enter the ip address
'''
Steps:

Copy the code
cat > nmap.py
Paste the code and press Ctrl+D (x2)

chmod +x nmap.py
python3 nmap.py

'''

import os
import sys
import subprocess
import ipaddress

# List of 10 useful Nmap commands
commands = [
    {"name": "Nmap Fast scan", "cmd_template": "sudo nmap -F {}", "requires_sudo": True},
    {"name": "Version detection", "cmd_template": "nmap -sV {}", "requires_sudo": False},
    {"name": "OS detection", "cmd_template": "sudo nmap -O {}", "requires_sudo": True},
    {"name": "Aggressive scan", "cmd_template": "sudo nmap -A {}", "requires_sudo": True},
    {"name": "Ping scan", "cmd_template": "nmap -sn {}", "requires_sudo": False},
    {"name": "TCP SYN scan", "cmd_template": "sudo nmap -sS {}", "requires_sudo": True},
    {"name": "UDP scan", "cmd_template": "sudo nmap -sU {}", "requires_sudo": True},
    {"name": "Default script scan", "cmd_template": "nmap -sC {}", "requires_sudo": False},
    {"name": "Vulnerability scan", "cmd_template": "nmap --script vuln {}", "requires_sudo": False},
    {"name": "Full port scan", "cmd_template": "nmap -p- {}", "requires_sudo": False}
]

def is_valid_ip(ip):
    try:
        ipaddress.ip_address(ip)
        return True
    except ValueError:
        return False

def print_menu():
    print("\nNmap Command Menu:")
    for i, cmd in enumerate(commands, start=1):
        example = cmd["cmd_template"].format("<target_ip>")
        print(f"{i} - {cmd['name']} - {example}")
    print("0 - Exit")
    print("Select an option:")

def main():
    while True:
        print_menu()
        try:
            choice = int(input("> "))
            if choice == 0:
                print("Exiting...")
                sys.exit(0)
            elif 1 <= choice <= len(commands):
                selected = commands[choice - 1]
                while True:
                    target_ip = input("Enter target IP address (or 'back' to return to menu): ").strip()
                    if target_ip.lower() == 'back':
                        break
                    if is_valid_ip(target_ip):
                        command = selected["cmd_template"].format(target_ip)
                        print(f"Running: {command}")
                        # Use os.system to run the command, allowing real-time output and sudo prompts
                        result = os.system(command)
                        if result != 0:
                            print(f"Command exited with code {result}, but continuing...")
                        break
                    else:
                        print("Invalid IP address. Please try again.")
            else:
                print("Invalid choice. Please select a valid option.")
        except ValueError:
            print("Invalid input. Please enter a number.")
        except KeyboardInterrupt:
            print("\nInterrupted. Returning to menu...")
        except Exception as e:
            print(f"Unexpected error: {e}. Continuing...")

if __name__ == "__main__":
    main()
