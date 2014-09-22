ddos-cut
========

Netstat based anti-ddos solution
Usage: ddos-cut.sh option [IP]

Possible options:
		-bl | --banned-list: Show banned IP list and exit.
		-c | --clean-log: Make log file clean and exit.
		-h | --help | ?: Show this help and exit.
		-k <IP>| --kill <IP>: Kill one specific IP address for 600 seconds and exit.
		-s | --show-conn: Show current connections list and exit.
		-u | --unban-all: Release all banned IP and exit.
		-ui <IP> | --unban-ip <IP>: Release one specific IP address from ban and exit.
		-v | --version: Show version and exit.
		-V | --verbose: Verbose output.

Bash script was tested on CentOS 6.5, CentOS 7

Please check all variables before you run this script.

1. Script using system resources and should be running from root or use sudo

2. Make sure you gave a git command installed. And i not, install it with something like:
yum install git

3. Copy this script into your /usr/local/bin folder:
git clone https://github.com/mrh666/ddos-cut.git && cp ddos-cut/ddos-cut.sh /usr/local/bin/

3. Make it executable: 
chmod +x /usr/local/bin/ddos-cut.sh

4. Crontab record you'll need (running every minute) - use <crontab -e>:
* * * * *	/usr/local/bin/ddos-cut.sh 1> /dev/null 2> /dev/null

By default script will create:
  temporary directory /tmp/ddos-cut (will contain scripts for IP unban after )
  Log file /var/log/ddos-cut
  IPTABLES chain ddos-cut
  
