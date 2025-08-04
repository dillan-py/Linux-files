#!/bin/bash

#ICMP Timestamp Request Remote Date Disclosure
#CWE:  200
#CVE:  CVE-1999-0524

# Flush existing ICMP rules (optional, be cautious)
iptables -D INPUT -p icmp --icmp-type 13 -j DROP 2>/dev/null
iptables -D INPUT -p icmp --icmp-type 14 -j DROP 2>/dev/null
iptables -D INPUT -p icmp -j ACCEPT 2>/dev/null

# Drop ICMP type 13 (Timestamp Request)
iptables -A INPUT -p icmp --icmp-type 13 -j DROP

# Drop ICMP type 14 (Timestamp Reply)
iptables -A INPUT -p icmp --icmp-type 14 -j DROP

# Accept all other ICMP types
iptables -A INPUT -p icmp -j ACCEPT

# Show resulting ICMP rules
iptables -nL | grep icmp
                         
