#!/bin/zsh
sudo sysctl -w net.ipv4.icmp_echo_ignore_all=1
#Disables all ICMP echo responses

sudo sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1
#Disables responses to ICMP echo requests sent to broadcast or multicast addresses.

sudo sysctl -w net.ipv4.icmp_ignore_bogus_error_responses = 1
#Protects the system from processing potentially malicious or malformed ICMP error messages.

sudo sysctl -w net.ipv4.tcp_rfc1337=1
#Mitigates risks associated with TCP time-wait states, such as preventing attackers from prematurely closing connections by forging packets.

#sudo chmod 600 /proc/sys/kernel/{hostname,osrelease,version}
sudo sysctl -w net.ipv4.conf.all.accept_source_route=0
#Disables IP source routing for all network interfaces.
sudo sysctl -w net.ipv4.conf.default.accept_source_route=0
#Disables IP source routing for the default network interface configuration.
sudo sysctl -w net.ipv4.conf.all.accept_redirects=0
#Disables acceptance of ICMP redirect messages for all network interfaces.
sudo sysctl -w net.ipv4.conf.default.accept_redirects=0
#Disables acceptance of ICMP redirect messages for the default network interface configuration.
sudo sysctl --system
#Loads settings from all system configuration files to remain persistent
                                                                           
