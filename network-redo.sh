#!/bin/bash

Red='\033[0;31m'
White='\033[0;37m'
Nc='\033[0m'

echo -e "${Red}Initializing...  this may take some time${Nc}"

$(sudo apt install dhcpcd5 fake-hwclock ifupdown isc-dhcp-client isc-dhcp-common openresolv)
$(sudo systemctl enable dhcpcd)
$(sudo systemctl enable fake-hwclock.service)
$(sudo systemctl disable systemd-networkd)
$(sudo systemctl disable systemd-resolved)
$(sudo systemctl disable systemd-timesyncd)
$(sudo systemctl restart dhcpcd)

echo "Done"
