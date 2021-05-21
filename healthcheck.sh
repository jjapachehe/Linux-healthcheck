#!/bin/bash
#######################################
## name:            healthcheck      ##
## author:          jjapache         ##
#######################################

#Global variables
date=$(date +"%Y%m%d")

#check mmsuper user
if [ "$(whoami)" != "root" ]; then
    echo "Use mmsuper to execute"
    exit 1
fi

banner()
{
    echo "+-----------------------------------------------------------------------+"
    printf "| %-40s |\n"
    printf "|\t   $@ \t\t\t   \n"
    echo "|                                                                     "
    echo "+-----------------------------------------------------------------------+"
}

separator() 
{
    echo "***********************************************************************"
}

#start
echo "*************************************************************************" 
echo "*                        Health Check $(hostname)                     *"
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
printf "\t\tTop process using CPU\n"
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head
separator
printf "\t\tTop process using Memory\n"
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head
banner "NTP and synchronization"
printf "NTP information:\t\t"; ntpstat | awk 'NR==1 {print $0}'
printf "NTP lead field:\t\t"; ntpq -c rv | awk 'NR==1 {print $3}'
separator
printf "\t\t Time and Date status\n"
timedatectl
banner "Network interfaces"
separator
printf "Bonding information"
ip link show | grep "bond.*:" | grep UP | awk -F":" '{print $2}'
separator
printf "\t\tNetwork interface statistics"
netstat -i | grep -v ^lo | column -t