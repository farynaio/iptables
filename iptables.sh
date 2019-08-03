#!/bin/bash

iptables -P INPUT ACCEPT

iptables -F

iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# LOG & ACCEPT chain.
iptables -N LOG_ACCEPT
iptables -A LOG_ACCEPT -m limit --limit 3/min -j LOG --log-prefix "iptables_INPUT_accepted: " --log-level 4
iptables -A LOG_ACCEPT -j ACCEPT

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Accept all loop back traffic and reject anything to localhost that does not originate from lo.
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT ! -i lo -s 127.0.0.0/8 -j REJECT

# Accept all established traffic.
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Unlock services port.
iptables -A INPUT -i eth0 -p tcp -m state --state NEW --dport 3000 -j LOG_ACCEPT

# Log any packets which don't fit the rules above.
# (optional but useful)
iptables -A INPUT -m limit --limit 3/min -j LOG --log-prefix "iptables_INPUT_denied: " --log-level 4

# iptables save
# iptables-save > /etc/iptables/rules.v4

iptables -L -v