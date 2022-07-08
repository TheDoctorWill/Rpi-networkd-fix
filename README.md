# Rpi-networkd-fix
This is a script that automatically replaces the raspberry pi networking utilities with networkd. It is designed to be setup for pi clusters and pi networking in general. it allows you to use both wlan and ethernet at the same time.

Below is a step by step guide for how to do this, but just run network-fix-perm.sh to get the same result

run network-redo.sh to undo the permenant changes

run network-fix.sh for the change to be temperary until the next reboot

run network-change.sh to change which network you are connected to.



_________________________________________________________________________
Networking Raspberry PIs the better way.

Networking is a pain, and with raspberry pi, it is even worse. For this project, I have two raspberry pi 4s, but you could add many more with a switch. I simply want to be able to connect both PIs together and have them both still able to access the internet. In other words, I would like to have two PIs on an internal network also be able to independently access the internet. Standing between me and this goal is dhcpcd.service, which is the default networking service used by the pi. It is alright, and it works, but it does not let the eth0 and wlan0 interfaces work at the same time no matter what I do. So let’s kill it.
1.	Burn the Witches
Remove all packages
sudo apt remove --purge --auto-remove dhcpcd5 fake-hwclock ifupdown isc-dhcp-client isc-dhcp-common openresolv
Kill WPA and DHCPCD
sudo killall wpa_supplicant
sudo killall dhcpcd
2.	Setup wlan0 and eth0 interfaces for networkd
Create wlan0 configuration 
sudo nano /etc/systemd/network/10-wlan0.network
fill it with this
[Match]
Name=wlan0

[Network]
DHCP=ipv4
Then create eth0 configuration
sudo nano /etc/systemd/network/10-eth0.network
then fill it with this 
important note, DHCP for this is an option, but for this project, it is easier to set a static IP. This static ip can be change to whatever you need.
[Match]
Name=eth0

[Network]
Address=192.168.1.100/24
Gateway=192.168.1.1, 8.8.8.8
The secondary gateway being 8.8.8.8 is extremely important. It will route traffic from the internal network back out to the internet.
3.	Enable networkd and other utilities
Enable network management service:
sudo systemctl enable systemd-networkd
Enable network name resolution (DNS) service:
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
sudo systemctl enable systemd-resolved
Enable network time synchronization (NTP) service:
sudo systemctl enable systemd-timesyncd
Reboot:
sudo reboot
Log back in (see step 3)
Check if everything is working:
systemctl status systemd-networkd
systemctl status systemd-resolved
systemctl status systemd-timesyncd
4.	Connect to the internet
Check for local SSIDs 
Sudo iwlist wlan0 scan | grep ESSID
This will output a list of local ESSIDs

Create config file
sudo nano /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
Add this configuration
ctrl_interface=DIR=/run/wpa_supplicant GROUP=netdev
update_config=0
country=US

network={
    ssid="name"
    psk="password"
   #(nkey_mgmt=NONE for passwordless connections)
}
Replace name and password with the network name and password.
Secure the file
sudo chmod 600 /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
enable WPA_supplicant
sudo systemctl enable wpa_supplicant@wlan0
sudo systemctl start wpa_supplicant@wlan0
wait then check status
networkctl status wlan0
wlan0 should say “configured”
to double check, try pinging an external website
ping google.com
if you are getting a response, you are almost done
to make sure everything is good, make sure to ping your other PIs after they have been setup
after all this, you are completely done

Just for fun, I made some scripts that do the whole thing automatically. You can find them here:


WHAT JUST HAPPENED?
Basically, we accessed systemd using systemctl. Systemctl is just a command, but systemd is more interesting. Basically, systemd is the first process that starts after the kernel is setup. Systemd loads literally every baselevel process on the computer and gets them running in parallel. This is important, as parallel process are easier to manage independently of each other. If one component breaks of systemd, it means that it is unlikely for other components to break because of that component being broken. 
What systemd does is run many different low-level processes in parallel, so what we do in this project is disable some of those processes (DHCPCD mainly) and enable some others (networkd, resolved, and timesyncd). Outside of the benefits already discussed by doing this (mainly actually being able to connect to both eth0 and wlan 0 at the same time), we also get the benefit of using lower-level services to do what higher level services would do. Practically speaking, this means we are using the resources of the system a little more efficiently, which is always good.
As networkd is a lower-level process, we get some other benefits too. It has much more configurability and modularity than dhcpcd and its software components. The same goes for the other services we enable as well.
However, this is not a fully beneficial change. Networkd is not as user friendly as dhcpcd, and neither are the other components. It is useful to understand that while networkd is better for higher level users, beginners and mid-level users will likely not want to use the software, despite its benefits. When making systems for other users, stick to dhcpcd, unless you know that the user of the system will be doing more advanced network configuration.
