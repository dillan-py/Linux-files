#!/usr/bin/env python3
#apt install python3-impacket
#sudo apt update && sudo apt install smbclient

import argparse
import csv
import json
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

def read_hosts(file_path):
    """Read hosts from CSV: host,username,password."""
    hosts = []
    with open(file_path, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            hosts.append(row)
    return hosts

def query_winver(host_info):
    """Use rpcclient srvinfo via RPC for winver data."""
    host = host_info['host']
    user = host_info['username']
    passw = host_info['password']
    
    cmd = [
        'rpcclient', '-U', f'{user}%{passw}', host, '-c', 'srvinfo'
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        output = result.stdout.strip()
        error = result.stderr.strip()
        
        if result.returncode != 0 or not output:
            return {'host': host, 'output': '', 'error': error or 'Command failed', 'success': False}
        return {'host': host, 'output': output, 'error': '', 'success': True}
    except subprocess.TimeoutExpired:
        return {'host': host, 'output': '', 'error': 'Timeout', 'success': False}
    except Exception as e:
        return {'host': host, 'output': '', 'error': str(e), 'success': False}

def main():
    parser = argparse.ArgumentParser(description="Remote Windows Version Query via RPC (Port 135)")
    parser.add_argument('--host', help="Single host IP")
    parser.add_argument('--user', required=True, help="Local username (admin)")
    parser.add_argument('--password', required=True, help="Password")
    parser.add_argument('--hosts', help="CSV file: host,username,password")
    parser.add_argument('--parallel', type=int, default=1, help="Max parallel queries")
    args = parser.parse_args()

    if args.hosts:
        hosts = read_hosts(args.hosts)
    else:
        hosts = [{'host': args.host, 'username': args.user, 'password': args.password}]

    results = []
    with ThreadPoolExecutor(max_workers=args.parallel) as executor:
        futures = [executor.submit(query_winver, host_info) for host_info in hosts]
        for future in futures:
            result = future.result()
            results.append(result)
            if result['success']:
                print(f"[+] {result['host']}: {result['output']}")
            else:
                print(f"[-] {result['host']}: {result['error']}")

    report = {'timestamp': '2025-10-09', 'results': results}
    with open('winver_rpc_report.json', 'w') as f:
        json.dump(report, f, indent=4)
    print("[+] Report saved to winver_rpc_report.json")

if __name__ == "__main__":
    main()
