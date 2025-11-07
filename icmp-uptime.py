# Install once
#sudo apt-get install python3-scapy   # Debian/Ubuntu
# or
#pip3 install --user scapy

#!/usr/bin/env python3
"""
ICMP Timestamp → Remote Uptime (little-endian, clock-synced)
Works on Linux/macOS/Windows (with Npcap)
"""

from scapy.all import IP, ICMP, send, sr1, conf
from datetime import datetime, timezone
import sys

def ms_since_midnight():
    now = datetime.now(timezone.utc)
    midnight = now.replace(hour=0, minute=0, second=0, microsecond=0)
    return int((now - midnight).total_seconds() * 1000)

def uptime_str(ms):
    d, ms = divmod(ms, 86400000)
    h, ms = divmod(ms, 3600000)
    m, ms = divmod(ms, 60000)
    s = ms / 1000
    return f"{int(d)}d {int(h):02d}h {int(m):02d}m {s:05.2f}s"

def probe(host, retries=5, timeout=2):
    conf.verb = 0                     # quiet
    for attempt in range(1, retries+1):
        print(f"[*] Attempt {attempt}/{retries} → {host}")

        local_ms = ms_since_midnight()
        pkt = IP(dst=host)/ICMP(type=13, id=0x1234, seq=1)/b"\x00"*12

        ans = sr1(pkt, timeout=timeout, verbose=0)
        if not ans:
            print("    [-] No reply")
            continue

        # Scapy gives us the raw payload after ICMP header
        payload = bytes(ans[ICMP].payload)
        if len(payload) < 12:
            print("    [-] Short payload")
            continue

        # Little-endian 4-byte fields
        orig_le = payload[0:4]
        recv_le = payload[4:8]
        tran_le = payload[8:12]

        orig_ms = int.from_bytes(orig_le, 'little')
        recv_ms = int.from_bytes(recv_le, 'little')
        tran_ms = int.from_bytes(tran_le, 'little')

        # Uptime calculation (handle midnight wrap)
        MS_DAY = 86_400_000
        if local_ms >= orig_ms:
            uptime_ms = local_ms - orig_ms
        else:
            uptime_ms = local_ms + (MS_DAY - orig_ms)

        print(f"[+] Reply from {ans.src}")
        print(f"    Originate : {orig_ms:,} ms  →  {orig_le.hex(' ')}")
        print(f"    Receive   : {recv_ms:,} ms")
        print(f"    Transmit  : {tran_ms:,} ms")
        print(f"    Local send: {local_ms:,} ms")
        print(f"\nREMOTE UPTIME: {uptime_str(uptime_ms)}")
        return

    print(f"[-] All {retries} attempts failed.")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: sudo python3 icmp_timestamp_uptime.py <ip>")
        print("Try:   sudo python3 icmp_timestamp_uptime.py 8.8.8.8")
        sys.exit(1)
    probe(sys.argv[1])

#proof: sudo tcpdump -i any icmp and host 8.8.8.8
