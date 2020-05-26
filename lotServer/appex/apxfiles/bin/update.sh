#!/bin/echo Warning: this is a library file, can not be execute directly:
# Author:	Vicer
# Date:		Mar, 2017

echo
echo "************************************************************"
echo "*                                                          *"
echo "*                 ServerSpeeder Updater                    *"        
echo "*                                                          *"
echo "************************************************************"
echo
MyKNK=''
Installed=''
which wget >/dev/null 2>&1
[ $? -ne 0 ] && {
echo 'ERROR(WGET): "wget" not found, please install "wget" using "yum install wget" or "apt-get install wget" according to your linux distribution'
return 1
}
which awk >/dev/null 2>&1
[ $? -ne 0 ] && {
echo 'ERROR(AWK): "awk" not found, please install "awk" using "yum install gawk" or "apt-get install gawk" according to your linux distribution'
return 1
}
which sed >/dev/null 2>&1
[ $? -ne 0 ] && {
echo 'ERROR(SED): "sed" not found, please install "sed" using "yum install sed" or "apt-get install sed" according to your linux distribution'
return 1
}
[ -d '/appex/bin' ] && Installed="$(ls -1 '/appex/bin' |grep 'acce-')"
[ -z "$Installed" ] && echo 'Not Install! ' && return 1
[ -f /etc/redhat-release ] && KNA=$(awk '{print $1}' /etc/redhat-release)
[ -f /etc/os-release ] && KNA=$(awk -F'[= "]' '/PRETTY_NAME/{print $3}' /etc/os-release)
[ -f /etc/lsb-release ] && KNA=$(awk -F'[="]+' '/DISTRIB_ID/{print $2}' /etc/lsb-release)
KNB=$(getconf LONG_BIT)
MyKNK="$(echo "$Installed" |awk -F '[[]|]' '{print $2}')"
[ -n "$MyKNK" ] && KNK="$(echo "$MyKNK" |awk -F '_' '{for(i=3;i<=NF;i++){printf "%s_",$i}}' |sed 's/_$//g')" || return 1
URLKernel='https://raw.githubusercontent.com/0oVicero0/serverSpeeder_kernel/master/serverSpeeder.txt'
MyKernel=$(wget --no-check-certificate -qO- "$URLKernel" |grep "$KNA/" |grep "/x$KNB/" |grep "/$KNK/" |sort -n -k 2 -t '_' |tail -n 1)
[ -z "$MyKernel" ] && echo 'The kernel is not fonund in library! ' && return 1
KNV="$(echo "$MyKernel" |awk -F '/' '{print $5}')"
KNN="$(echo "$MyKernel" |awk -F '/' '{ print $2 }')"
rm -rf /tmp/acce*
wget --no-check-certificate -q -O "/tmp/acce-"$KNV"-["$KNA"_"$KNN"_"$KNK"]" "https://raw.githubusercontent.com/0oVicero0/serverSpeeder_kernel/master/$MyKernel"
[ ! -f "/tmp/acce-"$KNV"-["$KNA"_"$KNN"_"$KNK"]" ] && echo "Update error! " && {
chattr -R -i /appex >/dev/null 2>&1
[ -d /etc/rc.d ] && rm -rf /etc/rc.d/init.d/serverSpeeder >/dev/null 2>&1
[ -d /etc/rc.d ] && rm -rf /etc/rc.d/rc*.d/*serverSpeeder >/dev/null 2>&1
[ -d /etc/rc.d ] && rm -rf /etc/rc.d/init.d/lotServer >/dev/null 2>&1
[ -d /etc/rc.d ] && rm -rf /etc/rc.d/rc*.d/*lotServer >/dev/null 2>&1
[ -d /etc/init.d ] && rm -rf /etc/init.d/serverSpeeder >/dev/null 2>&1
[ -d /etc/init.d ] && rm -rf /etc/rc*.d/*serverSpeeder >/dev/null 2>&1
[ -d /etc/init.d ] && rm -rf /etc/init.d/lotServer >/dev/null 2>&1
[ -d /etc/init.d ] && rm -rf /etc/rc*.d/*lotServer >/dev/null 2>&1
rm -rf /etc/lotServer.conf >/dev/null 2>&1
rm -rf /etc/serverSpeeder.conf >/dev/null 2>&1
[ -f /appex/bin/serverSpeeder.sh ] && bash /appex/bin/serverSpeeder.sh uninstall -f >/dev/null 2>&1
return 1
}
[ -f "/appex/bin/$Installed" ] && rm -rf "/appex/bin/$Installed"
mv "/tmp/acce-"$KNV"-["$KNA"_"$KNN"_"$KNK"]" "/appex/bin/acce-"$KNV"-["$KNA"_"$KNN"_"$KNK"]"
[ -f '/appex/etc/config' ] && sed -i "s/^apxexe\=.*/apxexe\=\"\/appex\/bin\/"$(ls -1 /appex/bin |grep 'acce-')"\"/" /appex/etc/config
chown -R root:root /appex
chmod -R a+x /appex
echo -e "The last version is \033[32m$KNV\033[0m! "
