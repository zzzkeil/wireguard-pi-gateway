# wireguard-pi-gateway
## Client <-> Raspberry Pi <-> Wireguard Server <-> Internet

### setup_v01.sh --> just worked  but has no secure iptables,
and no second script for just change the Wifi network


### Raspberry pi:

#### eth0 as dhcp server and gateway for a connected client ( or clients )
#### wlan0 to connect to a unknown network ( Hotel WiFi or Puplic Wifi or ..... )
#### wg0 wireguard tunnel all trafic



----------------------------------------
How to install :
###### Raspberry Pi  raspbian-stretch-lite :
```
sudo wget -O  setup.sh https://raw.githubusercontent.com/zzzkeil/wireguard-pi-gateway/master/setup_v01.sh

sudo chmod +x setup.sh

sudo ./setup.sh
```
-----------------------------------------
