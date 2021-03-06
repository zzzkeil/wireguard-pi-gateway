#!/bin/bash

####
#options
####
echo "Setup wireguard"
echo
read -p "Set the Server ipv4 (endpoint) :  " -e -i ServerIP IP01
read -p "Set the Wireguard Server Port :  " -e -i 54321 wg0port
read -p "Set the Servers PuplicKey :  " -e -i ServerPupKey PK04
read -p "Set client ipv4 without /32 :  " -e -i 10.8.0.3 cipv4
read -p "Set client ipv6 without /128 :  " -e -i fd42:42:42:42::3 cipv6
read -p "Set client DNS ipv4 :  " -e -i 10.8.0.1 DNSv4
read -p "Set client DNS ipv6 :  " -e -i fd42:42:42:42::1 DNSv6
echo
echo
echo "###########################################"
echo
echo
echo "Setup your WiFi"
echo
read -p "WiFi SSID  :  " -e -i Wlanname ssid
read -p "WiFi Password  :  " -e -i password ssidpasswd
echo
echo

####
sudo apt update && sudo apt upgrade -y
sudo echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
sudo echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
sudo apt install dirmngr raspberrypi-kernel-headers dnsmasq iptables-persistent -y
echo "deb http://deb.debian.org/debian/ unstable main" | sudo tee --append /etc/apt/sources.list.d/unstable.list
sudo apt-key adv --keyserver   keyserver.ubuntu.com --recv-keys 8B48AD6246925553 
printf 'Package: *\nPin: release a=unstable\nPin-Priority: 150\n' | sudo tee --append /etc/apt/preferences.d/limit-unstable
sudo apt update
sudo apt install wireguard -y
sudo systemctl stop dnsmasq


####
#network 
####
echo '
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
network={
    ssid="'"${ssid}"'"
    psk="'"${ssidpasswd}"'"
    }' | sudo tee --append /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null


sudo cp /etc/sysctl.conf /etc/sysctl.conf.orig
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sudo sed -i 's/#net.ipv6.conf.all.forwarding=1/net.ipv6.conf.all.forwarding=1/g' /etc/sysctl.conf
echo "net.ipv6.conf.all.autoconf=0
net.ipv6.conf.eth0.autoconf=0" | sudo tee --append /etc/sysctl.conf > /dev/null


sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
sudo iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE
sudo iptables -A FORWARD -i wg0 -o wg0 -m conntrack --ctstate NEW -j ACCEPT
sudo ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo ip6tables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
sudo ip6tables -t nat -A POSTROUTING -o wg0 -j MASQUERADE
sudo ip6tables -A FORWARD -i wg0 -o wg0 -m conntrack --ctstate NEW -j ACCEPT
sudo iptables-save > /etc/iptables/rules.v4
sudo ip6tables-save > /etc/iptables/rules.v6



sudo mv /etc/dhcpcd.conf /etc/dhcpcd.conf.orig
echo "
interface eth0
static ip_address=10.7.0.1/24
static ip6_address=fd00:10:7:1::1/64
static domain_name_servers=$DNSv4 $DNSv6
" | sudo tee --append /etc/dhcpcd.conf > /dev/null

sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
echo "interface=eth0
no-dhcp-interface=wlan0
enable-ra
listen-address=127.0.0.1
listen-address=10.7.0.1
listen-address=::1
listen-address=fd00:10:7:1::1
dhcp-range=fd00:10:7:1::2,fd00:10:7:1::52,24h
dhcp-range=10.7.0.2,10.7.0.52,24h
dhcp-option=option:dns-server,$DNSv4
dhcp-option=option6:dns-server,[$DNSv6]
dhcp-option=option:router,10.7.0.1
"  | sudo tee --append /etc/dnsmasq.conf > /dev/null


####
#wireguard
####

sudo mkdir /etc/wireguard/keys
sudo chmod 700 /etc/wireguard/keys
sudo touch /etc/wireguard/keys/wg0
sudo chmod 600 /etc/wireguard/keys/wg0
sudo wg genkey > /etc/wireguard/keys/wg0
sudo wg pubkey < /etc/wireguard/keys/wg0 > /etc/wireguard/keys/wg0.pub

echo "[Interface]
Address = $cipv4/32
Address = $cipv6/128
PrivateKey = PK03
DNS = $DNSv4, DNSv6

[Peer]
Endpoint = $IP01:$wg0port
PublicKey = $PK04
AllowedIPs = 0.0.0.0/0, ::/0
" | sudo tee --append /etc/wireguard/wg0.conf > /dev/null
sudo sed -i "s@PK03@$(cat /etc/wireguard/keys/wg0)@" /etc/wireguard/wg0.conf
chmod 600 /etc/wireguard/wg0.conf

echo
echo
echo "########################################################################"
echo
pupkey=$(cat /etc/wireguard/keys/wg0.pub)
echo "Set your client data in to your wireguard server config :"
echo
echo "[Peer]
PublicKey = $pupkey
AllowedIPs = $cipv4/32, $cipv6/128"
echo
echo "########################################################################"
echo
echo
echo


####
#finish
####
sudo systemctl enable wg-quick@wg0.service
sudo systemctl start dnsmasq
echo "reboot your system now"
echo "check if you need to change your client network settings"
