#!/bin/bash

iptables -P INPUT ACCEPT

iptables -F

iptables -A INPUT -p tcp --dport 22 -j ACCEPT

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Accept all loop back traffic and reject anything to localhost that does not originate from lo.
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT ! -i lo -s 127.0.0.0/8 -j REJECT

# Accept all established traffic.
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow HTTP server & SSL.
iptables -A INPUT -i eth0 -p tcp -m state --state NEW --dport 80 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp -m state --state NEW --dport 443 -j ACCEPT

# Allow Postfix.
iptables -A INPUT -i eth0 -p tcp -m state --state NEW --match multiport --dports 25,465,587,143,993 -j ACCEPT

# Unlock services port.
iptables -A INPUT -i eth0 -p tcp -m state --state NEW --dport 3000 -j ACCEPT

iptables -A INPUT -i eth0 -p tcp -m limit --limit 3/min -m state --state NEW -j LOG --log-level 4

# iptables save
iptables-save > /etc/iptables/rules.v4

iptables -L