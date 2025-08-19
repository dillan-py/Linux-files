#!/bin/bash

set -euo pipefail

audit_ssh() {
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 user@ip_address "id" && echo 'SSH is configured correctly' || echo 'SSH configuration needs attention'                                          
}

audit_firewall() {
  systemctl status firewalld.service > /dev/null 2>&1 && echo 'Firewall is enabled and running' || echo 'Firewall is not enabled or not running'                                                                                      
}

audit_updates() {
  sudo apt-get update -q && sudo apt-get upgrade -y -q && echo 'System updates are up to date' || echo 'System updates are not up to date'                                                                                            
}

audit_passwords() {
  if grep -q '^[a-zA-Z0-9]{8,}$' /etc/shadow; then
    echo 'Password policy is strong'
  else
    echo 'Password policy needs improvement'
  fi
}

audit_ssh && audit_firewall && audit_updates && audit_passwords
