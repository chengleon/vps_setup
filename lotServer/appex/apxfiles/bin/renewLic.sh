#!/bin/echo Warning: this is a library file, can not be execute directly:
# Author:	Vicer
# Date:		Mar, 2017

function renew() {

	echo
	echo "************************************************************"
	echo "*                                                          *"
	echo "*           ServerSpeeder License Updater (1.2)            *"        
	echo "*                                                          *"
	echo "************************************************************"
	echo

	# Locate wget awk
	which wget >/dev/null 2>&1
	[ $? -ne 0 ] && {
		echo 'ERROR(WGET): "wget" not found, please install "wget" using "yum install wget" or "apt-get install wget" according to your linux distribution'
		return 1
	}
	
	which awk >/dev/null 2>&1
	[ $? -ne 0 ] && {
		echo 'ERROR(WGET): "awk" not found, please install "awk" using "yum install gawk" or "apt-get install gawk" according to your linux distribution'
		return 1
	}
	
	# Get interface
	local ifname=eth0
	[ -f /proc/net/dev ] && {
		if grep 'eth0:' /proc/net/dev >/dev/null; then
			ifname=eth0
		else
			#exclude: lo sit stf gif dummy vmnet vir        
			ifname=`cat /proc/net/dev | awk -F: 'function trim(str){sub(/^[ \t]*/,"",str); sub(/[ \t]*$/,"",str); return str } NR>2 {print trim($1)}'  | grep -Ev '^lo|^sit|^stf|^gif|^dummy|^vmnet|^vir|^gre|^ipip|^ppp|^bond|^tun|^tap|^ip6gre|^ip6tnl|^teql' | awk 'NR==1 {print $0}' `
		fi
	}
	
	[ -z "$ifname" ] && {
		echo "Network interface not found! (error code: 100)"
		return 1
	}
	
	MAC=$(ifconfig "$ifname" |awk '/HWaddr/{ print $5 }')
	[ -z "$MAC" ] && MAC=$(ifconfig "$Eth" |awk '/ether/{ print $2 }')
	local myMAC="$MAC"
	[ -n "$1" ] && local Band="$1" && shift || local Band='1024M'
	local url="http://$HOST/lic?mac=$myMAC&bandwidth=$Band"
	
	local out=apxhttp.$$
	rm -rf $ROOT_PATH/lic 2>/dev/null
	echo "authenticating..."
	wget -o $out -O $ROOT_PATH/lic $url
	local downStat=0
	[ -f $ROOT_PATH/lic ] && {
		local filesize=0
		local stat=`which stat`
		[ -n "$stat" ] && filesize=`stat -c "%s" $ROOT_PATH/lic`
		[ -z "$stat" ] && filesize=`ls -l $ROOT_PATH/lic | awk '{print $5}'`
		[ $filesize -gt 100 ] && downStat=1
	}
	if [ $downStat = 1 ]; then
		sleep 1
		[ -f cookies.$$ ] && {
			newname=`cat cookies.$$ | awk '/licenceName/ {print $7}'`
			expireDate=`cat cookies.$$ | awk '/expireDate/ {print $7}'`
		}
		[ -z "$newname" ] && newname="apx.lic"
		mv $ROOT_PATH/lic $ROOT_PATH/etc/$newname
		echo "License file updated!"
		sed -i "s/^apxlic=.*/apxlic=\"\\$ROOT_PATH\/etc\/$newname\"/" $ROOT_PATH/etc/config
		. $ROOT_PATH/etc/config 2>/dev/null
		[ $VER_STAGE -lt 19 -o "$1" != "-grace" ] && {
			[ -n "$expireDate" ] && echo "Expire date: $expireDate"
			echo "Restarting $PRODUCT_NAME..."
			restart
		}
		echo "Done!"
	else
		grep 401 $out >/dev/null 2>&1
		[ $? -eq 0 ] && {
			echo "Email does not exist! (error code: 401)"
			rm -rf $out cookies.$$ 2>/dev/null
			return 1
		}
		grep 402 $out >/dev/null 2>&1
		[ $? -eq 0 ] && {
			echo "Invalid license code! (error code: 402)"
			rm -rf $out cookies.$$ 2>/dev/null
			return 1
		}
		grep 403 $out >/dev/null 2>&1
		[ $? -eq 0 ] && {
			echo "License does not exist! (error code: 403)"
			rm -rf $out cookies.$$ 2>/dev/null
			return 1
		}
		grep 408 $out >/dev/null 2>&1
		[ $? -eq 0 ] && {
			echo "License code used out! (error code: 408)"
			rm -rf $out cookies.$$ 2>/dev/null
			return 1
		}
		grep 409 $out >/dev/null 2>&1
		[ $? -eq 0 ] && {
			echo "License code expired! (error code: 409)"
			rm -rf $out cookies.$$ 2>/dev/null
			return 1
		}
		grep 411 $out >/dev/null 2>&1
		[ $? -eq 0 ] && {
			echo "Not allowed IP address.(error code: 411)"
			rm -rf $out cookies.$$ 2>/dev/null
			return 1
		}
		grep 412 $out >/dev/null 2>&1
		[ $? -eq 0 ] && {
			echo "No available license code.(error code: 412)"
			rm -rf $out cookies.$$ 2>/dev/null
			return 1
		}
		grep 413 $out >/dev/null 2>&1
		[ $? -eq 0 ] && {
			echo "Do not need to renew license"
			rm -rf $out cookies.$$ 2>/dev/null
			return 1
		}
		grep 417 $out >/dev/null 2>&1
		[ $? -eq 0 ] && {
			echo "Your license has expired! (error code: 417)"
			rm -rf $out cookies.$$ 2>/dev/null
			return 1
		}
		grep 503 $out >/dev/null 2>&1
		[ $? -eq 0 ] && {
			echo "Serial no of this server is obsolete! (error code: 503)"
			rm -rf $out cookies.$$ 2>/dev/null
			return 1
		}
		echo "Error occur! (error code: 400)"
		cat $out
		rm -rf $out cookies.$$ 2>/dev/null
	fi
	rm -rf $out cookies.$$ 2>/dev/null
}
