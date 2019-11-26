#!/bin/bash

iptables -P INPUT ACCEPT

iptables -F
iptables -X

iptables -N ATTACKED1
iptables -N ATTACKED2
iptables -N ATTACKED3
iptables -N ATTK_CHECK
iptables -N BAN1
iptables -N BAN2
iptables -N BAN3
iptables -N BAN4
iptables -N BAN5

# iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp -m multiport --dports 22,25 -m recent --rcheck --seconds 62208000 --name BANNED5 --rsource -j DROP
iptables -A INPUT -p tcp -m multiport --dports 22,25 -m recent --rcheck --seconds 14515200 --name BANNED4 --rsource -j DROP
iptables -A INPUT -p tcp -m multiport --dports 22,25 -m recent --update --seconds 86400 --name BANNED3 --rsource -j DROP
iptables -A INPUT -p tcp -m multiport --dports 22,25 -m recent --update --seconds 7200 --name BANNED2 --rsource -j DROP
iptables -A INPUT -p tcp -m multiport --dports 22,25 -m recent --update --seconds 1800 --name BANNED1 --rsource -j DROP

iptables -A INPUT -p tcp -m multiport --dports 22,25 -m state --state NEW -j ATTK_CHECK
iptables -A INPUT -p tcp -m multiport --dports 22,25 -m state --state NEW -j ATTK_CHECK

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp -s 77.55.219.47 -j ACCEPT

#OTHER PRE-EXISTING RULES

# Allow HTTP server & SSL.
iptables -A INPUT -i eth0 -p tcp -m state --state NEW --dport 80 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp -m state --state NEW --dport 443 -j ACCEPT

# Allow Postfix & Dovecot.
iptables -A INPUT -i eth0 -p tcp -m state --state NEW --match multiport --dports 143,465,587,993,995 -j ACCEPT

# iptables -A INPUT -i eth0 -p tcp -m limit --limit 3/min -m state --state NEW -j LOG --log-level 4

iptables -A ATTACKED1 -m recent --rcheck --name BANNED4 --rsource -j BAN5
iptables -A ATTACKED1 -m recent --rcheck --name BANNED3 --rsource -j BAN4
iptables -A ATTACKED1 -m recent --rcheck --name BANNED2 --rsource -j BAN3
iptables -A ATTACKED1 -m recent --rcheck --name BANNED1 --rsource -j BAN2
iptables -A ATTACKED1 -j BAN1

iptables -A ATTACKED2 -m recent --rcheck --name BANNED4 --rsource -j BAN5
iptables -A ATTACKED2 -m recent --rcheck --name BANNED3 --rsource -j BAN4
iptables -A ATTACKED2 -m recent --rcheck --name BANNED2 --rsource -j BAN3
iptables -A ATTACKED2 -j BAN2

iptables -A ATTACKED3 -m recent --rcheck --name BANNED4 --rsource -j BAN5
iptables -A ATTACKED3 -m recent --rcheck --name BANNED3 --rsource -j BAN4
iptables -A ATTACKED3 -j BAN3

iptables -A ATTK_CHECK -m recent --update --seconds 3600 --hitcount 31 --name ATTK --rsource -j ATTACKED3
iptables -A ATTK_CHECK -m recent --update --seconds 600 --hitcount 11 --name ATTK --rsource -j ATTACKED2
iptables -A ATTK_CHECK -m recent --update --seconds 60 --hitcount 6 --name ATTK --rsource -j ATTACKED1
iptables -A ATTK_CHECK -m recent --set --name ATTK --rsource
iptables -A ATTK_CHECK -j ACCEPT

iptables -A BAN1 -m limit --limit 5/min -j LOG --log-prefix "IPTABLES (Rule BANNED-30m): " --log-level 7
iptables -A BAN1 -m recent --set --name BANNED1 --rsource -j DROP

iptables -A BAN2 -m limit --limit 5/min -j LOG --log-prefix "IPTABLES (Rule BANNED-2h): " --log-level 7
iptables -A BAN2 -m recent --remove --name BANNED1 --rsource
iptables -A BAN2 -m recent --set --name BANNED2 --rsource -j DROP

iptables -A BAN3 -m limit --limit 5/min -j LOG --log-prefix "IPTABLES (Rule BANNED-1d): " --log-level 7
iptables -A BAN3 -m recent --remove --name BANNED2 --rsource
iptables -A BAN3 -m recent --set --name BANNED3 --rsource -j DROP

iptables -A BAN4 -m limit --limit 5/min -j LOG --log-prefix "IPTABLES (Rule BANNED-1w): " --log-level 7
iptables -A BAN4 -m recent --remove --name BANNED3 --rsource
iptables -A BAN4 -m recent --set --name BANNED4 --rsource -j DROP

iptables -A BAN5 -m limit --limit 5/min -j LOG --log-prefix "IPTABLES (Rule BANNED-1mo): " --log-level 7
iptables -A BAN5 -m recent --remove --name BANNED4 --rsource
iptables -A BAN5 -m recent --set --name BANNED5 --rsource -j DROP

if hash "ipset" &> /dev/null; then
  iptables -I INPUT -m set --match-set blacklist src -j DROP
  iptables -I FORWARD -m set --match-set blacklist src -j DROP
else
  echo 'ipset not installed.'
fi

# iptables save
iptables-save > /etc/iptables/rules.v4
