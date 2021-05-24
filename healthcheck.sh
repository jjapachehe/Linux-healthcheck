#!/bin/bash
#######################################
## name:            healthcheck      ##
## author:          jjapache         ##
#######################################

#Global variables
date=$(date +"%Y%m%d")

#check root user
if [ "$(whoami)" != "root" ]; then
    echo "Use root to execute"
    exit 1
fi

banner()
{
    echo "+-----------------------------------------------------------------------+"
    printf "\t\t   $@ \t\t\t   \n"
    echo "+-----------------------------------------------------------------------+"
}

separator() 
{
    echo -e "\n************************************************************************"
}

#start
echo "*************************************************************************" 
echo "*                        Health Check $(hostname)                     *"
echo "*                                                                       *"
echo "*************************************************************************"

#system information
banner "Node Information"
hostnamectl
uptime=$(uptime|sed 's/.*up \([^,]*\), .*/\1/'); printf "\t    Uptime: $uptime\n"
last_reboot=$(sudo last reboot | awk 'NR==3 {print $3 " " $4 " " $5 " " $6 " " $7}'); printf "       last reboot: $last_reboot\n"
banner "Memory and CPU Usage"
printf "Total RAM:\t\t"; grep MemTotal /proc/meminfo| awk '{printf(" %.0f GB\n", $2/1024/1024)}'
printf "Memory free:\t\t"; grep MemFree /proc/meminfo| awk '{printf(" %.0f GB\n", $2/1024/1024)}'
printf "Memory available:\t"; grep MemAvailable /proc/meminfo| awk '{printf(" %.0f GB\n", $2/1024/1024)}'
printf "Memory used:\t\t"; vmstat -s | grep -w "used memory" | awk '{printf(" %.0f GB\n", $1/1024/1024)}'
printf "Swap total:\t\t"; grep SwapTotal /proc/meminfo| awk '{printf(" %.0f GB\n", $2/1024/1024)}'
printf "Swap free:\t\t"; grep SwapFree /proc/meminfo| awk '{printf(" %.0f GB\n", $2/1024/1024)}'
printf "Swap used:\t\t"; vmstat -s | grep -w "used swap" | awk '{printf(" %.0f GB\n", $1/1024/1024)}'
printf "Load average:\t\t"; uptime|grep -o "load average.*"|awk '{print " "$3" " $4" " $5}'
printf "CPU usage:\t\t"; mpstat -P ALL 1 5 -u | grep "^Average" | sed "s/Average://g" | grep -w "all" | awk '{print $NF}' | awk -F'.' '{print (" "100 -$1 "%")}'
separator
printf "\t\tTop process CPU\n"
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head
separator
printf "\t\tTop process Memory\n"
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head
banner "NTP and synchronization"
printf "NTP information:\t"; ntpstat | awk 'NR==1 {print $0}'
printf "NTP lead field:\t\t"; ntpq -c rv | awk 'NR==1 {print $3}'
separator
printf "\t\t Time and Date status\n"
timedatectl
banner "Network interfaces"
printf "\t\tIP information\n"
ifconfig|grep "inet " | column -t
printf "Network RX-ERR:\t\t"; netstat -i|egrep -v "Iface|statistics"|awk '{sum += $4} END {print sum}'
printf "Network TX-ERR:\t\t"; netstat -i|egrep -v "Iface|statistics"|awk '{sum += $8} END {print sum}'
separator
printf "Bonding information\n"
ip link show | grep "bond.*:" | grep UP | awk -F":" '{print $2}'
separator
printf "\t\tNetwork interface statistics\n"
netstat -i | grep -v ^lo | column -t
separator
printf "\t\tCurrent bandwidth usage\n"
for interface in $(ip link show | awk '{print $2}' | grep -v '^[0-9]' | grep -v "@"| sed 's/:$//')
do
    printf "${interface}: "; sar 1 1 -n DEV | grep ${interface} | grep -v ^Average | tail -1 | awk '{print $6+$7 " Mb"}'
done
banner "Filesystem and disk information"
printf "\t\tFilesystem > 75 percent usage:\n\n"
for i in $(df -Ph|egrep -v "^Filesystem|mnt" | awk '{print $5"," $6}' | sort -nr) 
do 
    if [ `echo $i| awk -F "," '{print $1}' | sed 's/%$//'` -gt 75 ]; then
        echo $i| awk -F "," '{if ($1 >=80) print $1 " " $2}'
    else
        echo "All FS are under 75%"
        break
    fi
done
separator
printf "\t\t Disk Usage output\n"
df -Ph

