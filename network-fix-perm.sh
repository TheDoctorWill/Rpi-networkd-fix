#!/bin/bash

Red='\033[0;31m'
White='\033[0;37m'
Nc='\033[0m'

echo -e "${Red}Initializing... "

#user instructions
echo -e "${White}enter the IP address of this PI (192.168.1.x is ideal. do not end in a .1)"

#user inputs IP that they want
read IP

#default gateway instructions
echo 'enter the default Gateway for this PI (192.168.1.1 usually works)'

#user inputs defualt gateway
read DG

#inform user that ensuing operation will take a moment
echo -e "${Red}cleaning up - DO NOT UNPLUG YOUR COMPUTER (this may take some time)"

#remove older networking utilities. this is the longest part of the script and can take several minutes
$(sudo apt remove --purge --auto-remove dhcpcd5 fake-hwclock ifupdown isc-dhcp-client isc-dhcp-common openresolv)
#inform user when oepration is complete
echo -e "${White}removed the older utilities"

#kills wpa_supplicant and DHCPCD. wpa_supplicant is reenabled later
$(sudo killall wpa_supplicant)
$(sudo killall dhcpcd)

#inform user DHCPCD is dead
echo 'purged witches'

#write wlan0 configuration to file
echo -e "[Match]\nName=wlan0\n\n[Network]\nDHCP=ipv4" > /etc/systemd/network/10-wlan0.network

#write eth0 configuration to file. variables for default gateway and custom IP are here
echo -e "[Match]\nName=eth0\n\n[Network]\nAddress=$IP/24\nGateway=$DG, 8.8.8.8" > /etc/systemd/network/10-eth0.network

#inform user configs have been writen
echo 'setup configs'

#enable required libraries for networkd to function, use dns, and timesync.
$(sudo systemctl enable systemd-networkd)
$(sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf)
$(sudo systemctl enable systemd-resolved)
$(sudo systemctl enable systemd-timesyncd)
$(sudo systemctl restart systemd-networkd)
$(sudo systemctl restart systemd-resolved)
$(sudo systemctl restart systemd-timesyncd)

#inform user
echo 'enabled software'

#get local SSIDs
output=$(sudo iwlist wlan0 scan | grep ESSID | paste -sd, -)
#show local SSIDs
echo $output | tr "," "\n"

#request wifi name
echo -e "${Red}please enter the wifi name from the list above ${Nc}"

#store wifi name for later
read ssid
s1="NONE"
#request wifi psk
echo -e "${Red}please enter the wifi password. If there is no WIFI password, please put NONE ${Nc}"

#store wifi psk for later
read pass

#check if there is password
if [[ $pass == $s1 ]];
then
# creat config for no password wifi
echo -e "ctrl_interface=DIR=/run/wpa_supplicant GROUP=netdev\nupdate_config=0\ncountry=US\nnetwork={\nssid=\""$ssid"\"\nkey_mgmt=NONE\n}" > /etc/wpa_supplicant/wpa_supplicant-wlan0.conf

else
#write configuration file for network. wifi name and psk are used here
echo -e "ctrl_interface=DIR=/run/wpa_supplicant GROUP=netdev\nupdate_config=0\ncountry=US\nnetwork={\nssid=\""$ssid"\"\npsk=\""$pass"\"\n}" > /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
fi
#secure file with wifi information in it
$(sudo chmod 600 /etc/wpa_supplicant/wpa_supplicant-wlan0.conf)

#enable wlan0
$(sudo systemctl enable wpa_supplicant@wlan0)

#start wlan0 (may not be nessecary, but I like to be safe)
$(sudo systemctl start wpa_supplicant@wlan0)

#inform user we need input to reboot
echo -e "${Red}reboot to implement changes (y or n) ${Nc}"

#we do not need user input to reboot, but i thought it would be weird if it just did it without saying anything. currently, even if you say no, it will still reboot.
read idc

#reboot
$(sudo systemctl restart wpa_supplicant@wlan0)
