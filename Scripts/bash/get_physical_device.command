#!/bin/bash --login


# add brew
# add ios-deploy

xcrun instruments -s devices | grep -E "\(" | sed '/Simulator/d'


#if xcrun instruments -s devices | sed '/Simulator/d' | sed '/Known Devices:/d' | sed '/nb/d' | sed '/Apple Watch/d' | grep -q '(null)'; then
#    echo "Please unlock your iPhone and tap on 'Trust' button"
#fi
#
#if [[ ${3} == "phys_device" ]];then
#wifi_address=$(ideviceinfo | grep 'WiFiAddress' | cut -d " " -f 2)
#device_ip=$(arp -a | grep $wifi_address | cut -d "(" -f 2 | cut -d ")" -f 1)
#if [[ $device_ip == "" ]];then
#device_name=$(ideviceinfo | grep 'DeviceName' | cut -d " " -f 2 | cut -d "'" -f 1 | tr '[:upper:]' '[:lower:]')
#device_ip=$(arp -a | grep $device_name | cut -d "(" -f 2 | cut -d ")" -f 1)
#fi
#
#if [[ $device_ip == "" ]];then
#nmap -sn $(ifconfig en0 | grep inet | grep -v inet6 | awk '{print $2}')/24
#device_ip=$(arp -a | grep $wifi_address | cut -d "(" -f 2 | cut -d ")" -f 1)
#if [[ $device_ip == "" ]];then
#device_name=$(ideviceinfo | grep 'DeviceName' | cut -d " " -f 2 | cut -d "'" -f 1 | tr '[:upper:]' '[:lower:]')
#device_ip=$(arp -a | grep $device_name | cut -d "(" -f 2 | cut -d ")" -f 1)
#fi
#fi
#
#if [[ $device_ip == "" ]];then
#echo "Calabash Launcher can't get your iPhone IP(check that device is in the same network as your MacBook and has internet access). Run test again when internet connection on the device is back to normal"
#exit
#fi
#device=DEVICE_IP=http://$device_ip:37265
#else
#device=${3}
#fi

