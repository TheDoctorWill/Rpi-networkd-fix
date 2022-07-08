#inform user script is functional
echo "getting SSIDs"

#get local SSIDs
output=$(sudo iwlist wlan0 scan | grep ESSID | paste -sd, -)
#show local SSIDs
echo $output | tr "," "\n"


#request wifi name
echo 'please enter the wifi name from the list above'

#store wifi name for later
read ssid
s1="NONE"
#request wifi psk
echo 'please enter the wifi password. If there is no WIFI password, please put NONE'

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
$(sudo systemctl restart wpa_supplicant@wlan0)

echo "Done"
