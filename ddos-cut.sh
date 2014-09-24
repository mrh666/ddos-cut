#!/bin/bash

SCRIPT_NAME="DDOS CUT v.0.5 by MrMrh"
RELEASE="Release date: 2014-09-24 14:23 GMT"

# Tested on CentOS 6.5, CentOS 7
# Please check all the variables before you run this script
# Put this script into your /usr/local/bin folder and make it executable: chmod +x /usr/local/bin/ddos-cut.sh
# A script using system resources and should be run from root or use sudo
# Crontab record you'll need (running every minute): * * * * *	/usr/local/bin/ddos-cut.sh 1> /dev/null 2> /dev/null
# Put this crontab record by: sudo crontab -e
#
# By default script will create:
#	temporary directory /tmp/ddos-cut
# 		Files in /tmp/ddos-cut will have names: UNIX_TIMESTAMP.IP and deleted automatically
#	Log file /var/log/ddos-cut.log
#	New IPTABLES chain ddos-cut

C_DATE=`date`
U_DATE=`date '+%s'`
CONNECTIONS_LIMIT=140 		# IP with more or equal than $CONNECTIONS_LIMIT will be banned
BAN_TIME=600 			# sec
LOG_DIR="/var/log/"
LOG_FILE=$LOG_DIR"ddos-cut.log"
NETSTAT="/bin/netstat"
GREP="/bin/grep"
EGREP="/bin/egrep"
AWK="/bin/awk"
SED="/bin/sed"
CUT="/bin/cut"
SORT="/bin/sort"
UNIQ="/usr/bin/uniq"
LS="/bin/ls -1"
LOGGER="/bin/logger"
IPTABLES="/sbin/iptables"
CHAIN_NAME="ddos-cut"
MKDIR="/bin/mkdir"
TMP_DIR="/tmp/ddos-cut"
LOG_PREF=$C_DATE" [ddos-cut.sh]: "

# Do not edit below this line
# ---------------------------

create_tmp_dir() {
	if [[ ! -e $TMP_DIR ]]; then
		$MKDIR $TMP_DIR
		LOG_TEXT="$LOG_PREF $TMP_DIR created"
		$LOGGER -s "$LOG_TEXT" 2>> $LOG_FILE
	elif [[ ! -d $TMP_DIR ]]; then
	    	LOG_TEXT="$LOG_PREF $TMP_DIR already exists and this is not a directory"
	    	$LOGGER -s "$LOG_TEXT" 2>> $LOG_FILE
	fi
}

flush_chain() {
	$IPTABLES -D INPUT -j $CHAIN_NAME
	$IPTABLES -F $CHAIN_NAME
	$IPTABLES -X $CHAIN_NAME
	if [ $($IPTABLES -n -L INPUT | grep "$CHAIN_NAME[ \t]" | wc -l) -eq 0 ]; then
		echo "Chain $CHAIN_NAME flushed and removed."
		LOG_TEXT="$LOG_PREF Chain $CHAIN_NAME flushed and removed."
		$LOGGER -s "$LOG_TEXT" 2>> $LOG_FILE
	fi
}

create_chain() {
	if [ $($IPTABLES -n -L INPUT | grep "$CHAIN_NAME[ \t]" | wc -l) -eq 0 ]; then
		$IPTABLES -N $CHAIN_NAME
		$IPTABLES -A $CHAIN_NAME -j RETURN
		$IPTABLES -I INPUT -j $CHAIN_NAME
		echo "New chain "$CHAIN_NAME" created."
		LOG_TEXT="$LOG_PREF New chain $CHAIN_NAME created."
		$LOGGER -s "$LOG_TEXT" 2>> $LOG_FILE
	fi
}

banned_list() {
	$IPTABLES -n -L $CHAIN_NAME | $GREP DROP | $AWK '{print $4}'
}

unban_all() {
	flush_chain
	rm -rf $TMP_DIR/* 1>/dev/null 2>/dev/null
	create_chain
}

unban_ip() {
	valid_ip "$1"
	if [ "$valid_ip" == 1 ]; then
		if [ $($IPTABLES -n -L $CHAIN_NAME | $GREP "$1" | wc -l) -ge 1 ]; then
			$LS $TMP_DIR | $GREP "$1" |
			while read line; do
				$IPTABLES -D $CHAIN_NAME -s "$1" -j DROP
				rm -rf "$TMP_DIR/$line"
				LOG_TEXT="$LOG_PREF $1 unbanned"
				$LOGGER -s "$LOG_TEXT" 2>> $LOG_FILE
			done
		else
			echo "There is no such IP in $CHAIN_NAME chain"
			echo "IP can be found by runnig ddos-cut.sh --banned-list or ddos-cut.sh -bl"
		fi
	fi
		
}

unban_timer() {
	$LS $TMP_DIR |
	while read line; do
		CREATION_TIME=$(echo $line | cut -d"." -f1)
		IP_TO_REMOVE="$(echo $line | cut -d"." -f2).$(echo $line | cut -d"." -f3).$(echo $line | cut -d"." -f4).$(echo $line | cut -d"." -f5)"
		FILE_SUFFIX="$(echo $line | cut -d"." -f6)"
		let DELTIME=$U_DATE-$BAN_TIME
		if [ $CREATION_TIME -lt $DELTIME ]; then
			echo "$IP_TO_REMOVE expired"
			unban_ip "$IP_TO_REMOVE" "$CREATION_TIME" "$FILE_SUFFIX"
		fi
	done
}

valid_ip() {
	if [[ "$1" =~ ^(([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]).){3}([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$ ]]; then
		valid_ip=1
	else 
		echo "You should specify an IP address."
		exit
	fi
}

kill_ip() {
	valid_ip "$1"
	if [ "$valid_ip" == 1 ]; then
		$IPTABLES -I $CHAIN_NAME 1 -s "$1" -j DROP
		if [ $($IPTABLES -n -L $CHAIN_NAME | $GREP "$1" | wc -l) -ge 1 ]; then
			if [ -z "$2" ]; then
				CON=0
			else
				CON="$2"
			fi
			LOG_TEXT="$LOG_PREF IP $1 has $CON connections. Banned."
			if [ "$VERBOSE" == 1 ]; then
				echo $LOG_TEXT
			fi
			$LOGGER -s "$LOG_TEXT" 2>> $LOG_FILE
		fi
	fi
	
	FILE_TO_UNBAN="$(mktemp $TMP_DIR/$U_DATE.$1.XXXXXXXXXX)"
	echo "$1" > $FILE_TO_UNBAN
}

show_current() {
	$NETSTAT --numeric-ports --numeric-users -ntu | \
	# Clean output
	$EGREP -v "127.0.0.1|Address|servers" | \
	# Select only connected hosts
	$AWK '{print $5}' | \
	# Cut off IPv6 representation
	$SED s/::ffff:// | \
	# Cut off remote host port
	$CUT -d: -f1 | \
	# Sort by IP address
	$SORT | \
	# Count unique IP addresses
	$UNIQ -c | \
	# Sort by open connections
	$SORT -n
}

new_log() {
	# Create the log file if doesn't exist, check if it's possible to write to log file
	( [ -e "$LOG_FILE" ] || touch "$LOG_FILE" ) && [ ! -w "$LOG_FILE" ] && echo cannot write to $LOG_FILE && exit 1
}

ver() {
	echo $SCRIPT_NAME
	echo $RELEASE
}

helper() {
	ver
	echo ""
	echo "Usage: ddos-cut.sh option [IP]"
	echo "	Options:"
	echo "		-bl | --banned-list: Show banned IP list and exit."
	echo "		-c | --clean-log: Make log file clean and exit."
	echo "		-h | --help | ?: Show this help and exit."
	echo "		-k <IP>| --kill <IP>: Kill one specific IP address for $BAN_TIME seconds and exit."
	echo "		-s | --show-conn: Show current connections list and exit."
	echo "		-u | --unban-all: Release all banned IP and exit."
	echo "		-ui <IP> | --unban-ip <IP>: Release one specific IP address from ban and exit."
	echo "		-v | --version: Show version and exit."
	echo "		-V | --verbose: Verbose output."
	echo
}

while [ $1 ]; do
    case $1 in
		'-h' | '--help' | '?' )
		helper
		exit
	;;
		'-v' | '--version' )
		ver
		exit
	;;
		'-V' | '--verbose' )
		ver
		echo
		VERBOSE=1
	;;
		'-c' | '--clean-log' )
		cat /dev/null > $LOG_FILE
		if [ ! -s "$LOG_FILE" ]
		then
			if [ "$VERBOSE" == 1 ]; then
				echo "Log file "$LOG_FILE" cleaned"
			fi
		else
			new_log
			if [ "$VERBOSE" == 1 ]; then
				echo "Log file "$LOG_FILE" created"
			fi
		fi
		exit
	;;
		'-u' | '--unban-all' )
		unban_all
		exit
	;;
		'-ui' | '--unban-ip' )
		unban_ip "$2"
		exit
	;;
		'-bl' | '--banned-list' )
		banned_list
		exit
	;;
		'-k' | '--kill' )
		kill_ip "$2"
		exit
	;;
		'-s' | '--show-conn' )
		show_current
		exit
	;;
	esac
	shift
done

create_chain
new_log
create_tmp_dir
unban_timer

show_current |
while read line; do
	CONNECTIONS=$(echo $line | cut -d" " -f1)
	IP_CHECK=$(echo $line | cut -d" " -f2)
	if [ "$CONNECTIONS" -ge "$CONNECTIONS_LIMIT" ]; then
		kill_ip "$IP_CHECK" "$CONNECTIONS"
	fi
done

exit
