#!/bin/bash

SCRIPT_NAME="DDOS CUT v.0.2 by MrMrh"
RELEASE="Release date: 2014-09-22 13:36 GMT"

# Tested on CentOS 6.5, CentOS 7
# Please check all variables before you run this script
# Put this script into your /usr/local/bin folder and make it executable: chmod +x /usr/local/bin/ddos-cut.sh
# Script using system resources and should be running from root or sudo user
# Crontab record you'll need (running every minute): * * * * *	/usr/local/bin/ddos-cut.sh 1> /dev/null 2> /dev/null
# Put this crontab record by: sudo crontab -e
#
# By default script will create:
#	temporary directory /tmp/ddos-cut (will contain scripts for IP unban after )
#	Log file /var/log/ddos-cut
#	IPTABLES chain ddos-cut

C_DATE=`date`
U_DATE=`date '+%s'`
CONNECTIONS_LIMIT=140 		# IP with connctions more than $CONNECTIONS_LIMIT will be banned
BAN_TIME=600 			# Num seconds
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
LS="/bin/ls"
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

create_chain() {
	if [ $($IPTABLES -L $CHAIN_NAME 2>/dev/null | wc -l) -eq 0 ]; then
		$IPTABLES -N $CHAIN_NAME
		if [ $($IPTABLES -L $CHAIN_NAME 2>/dev/null | wc -l) -gt 0 ]; then
			echo "New chain "$CHAIN_NAME" created."
		fi
	fi
}

banned_list() {
	$IPTABLES -n -L $CHAIN_NAME | $GREP DROP | awk '{print $4}'
}

unban_all() {
	$IPTABLES -F $CHAIN_NAME
	rm -rf $TMP_DIR/* 1>/dev/null 2>/dev/null
	if [ $($IPTABLES -L $CHAIN_NAME 2>/dev/null | wc -l) -eq 2 ]; then
		if [ "$VERBOSE" == 1 ]; then
			echo "Chain cleaned"
		fi
	elif [ $($IPTABLES -L $CHAIN_NAME 2>/dev/null | wc -l) -eq 0 ]; then
		create_chain
		if [ "$VERBOSE" == 1 ]; then
			echo "Chain doesn't exist. New chain "$CHAIN_NAME" created."
		fi
	fi
}

unban_ip() {
	valid_ip "$1"
	if [ "$valid_ip" == 1 ]; then
		if [ $($IPTABLES -n -L $CHAIN_NAME | $GREP "$1" | wc -l) -eq 1 ]; then
			IP_CHECK="$1"
			$IPTABLES -D $CHAIN_NAME -s $IP_CHECK -j DROP
			if [ $($IPTABLES -n -L $CHAIN_NAME | $GREP "$1" | wc -l) -lt 1 ]; then
				rm -rf "$TMP_DIR/$CREATION_TIME.$1" # 1>/dev/null 2>/dev/null
				LOG_TEXT="$LOG_PREF $1 unbanned"
				$LOGGER -s "$LOG_TEXT" 2>> $LOG_FILE
			else 
				echo "Something goes wrong. Try again later."
			fi
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
		let DELTIME=$U_DATE-$BAN_TIME
		if [ $CREATION_TIME -lt $DELTIME ]; then
			echo "$IP_TO_REMOVE expired"
			unban_ip "$IP_TO_REMOVE"
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
		$IPTABLES -A $CHAIN_NAME -s "$1" -j DROP
		if [ $($IPTABLES -n -L $CHAIN_NAME | $GREP "$1" | wc -l) -ge 1 ]; then
			LOG_TEXT="$LOG_PREF IP $1 has $2 connections. Banned."
			if [ "$VERBOSE" == 1 ]; then
				echo $LOG_TEXT
			fi
			$LOGGER -s "$LOG_TEXT" 2>> $LOG_FILE
		fi
	fi
	FILE_TO_UNBAN="$TMP_DIR/$U_DATE.$1"
	echo "$1" > $FILE_TO_UNBAN
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

new_log() {
	# Create the log file if not exists, check if it's possible to write to log file
	( [ -e "$LOG_FILE" ] || touch "$LOG_FILE" ) && [ ! -w "$LOG_FILE" ] && echo cannot write to $LOG_FILE && exit 1
}

show_current() {
	$NETSTAT --numeric-ports --numeric-users -ntu | \
	# Cut localhost from output
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
	# Sort by amount of open connections
	$SORT -n
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

new_log
create_tmp_dir
create_chain
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
