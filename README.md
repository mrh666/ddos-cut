ddos-cut
========

Netstat based anti-ddos solution. Prevent ddos attacks by IPv4 connections monitoring and use iptables for temporary DROP rules.
```
Usage: ddos-cut.sh option [IP]
```

Possible options:
```
		-bl | --banned-list: Show banned IP list and exit.
		-c | --clean-log: Make log file clean and exit.
		-h | --help | ?: Show this help and exit.
		-k <IP>| --kill <IP>: Kill one specific IP address for 600 seconds and exit.
		-s | --show-conn: Show current connections list and exit.
		-u | --unban-all: Release all banned IP and exit.
		-ui <IP> | --unban-ip <IP>: Release one specific IP address from ban and exit.
		-v | --version: Show version and exit.
		-V | --verbose: Verbose output.
```
Bash script was tested on CentOS 6.5, CentOS 7.

Please check all variables before you run this script.

A script using system resources and should be running from root or use sudo.

Make sure you have a git command installed. And if not, install it:
```
yum install git
```

Copy this script into /usr/local/bin folder:
```
git clone https://github.com/mrh666/ddos-cut.git && cp ddos-cut/ddos-cut.sh /usr/local/bin/
```

Make it executable: 
```
chmod +x /usr/local/bin/ddos-cut.sh
```

Add a crontab record (running every minute) - use <strong>crontab -e</strong>:
```
* * * * *	/usr/local/bin/ddos-cut.sh 1> /dev/null 2> /dev/null
```

By default script will create:<br />
Temporary directory /tmp/ddos-cut<br />
Files in /tmp/ddos-cut will have names: UNIX_TIMESTAMP.IP and deleted automatically<br />
Log file /var/log/ddos-cut.log<br />
New IPTABLES chain ddos-cut


Default parameter are:
```
Connections banned per one IP = 140
Jail time = 600 sec
```
