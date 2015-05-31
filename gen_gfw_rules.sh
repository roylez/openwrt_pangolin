#!/bin/sh

# Write gfw iptables
firewall_gfw="firewall.user"
shadowsocks_ip="SHADOWSOCKS_IP"
shadowsocks_port=1080

if [ -f $firewall_gfw ]; then
 rm $firewall_gfw
fi

echo "#!/bin/ash" >>$firewall_gfw
echo >>$firewall_gfw
echo "# Create a new chain named SHADOWSOCKS" >>$firewall_gfw
echo "iptables -t nat -N SHADOWSOCKS" >>$firewall_gfw
echo >>$firewall_gfw

echo "# Ignore shadowsocks server" >>$firewall_gfw
echo "iptables -t nat -A SHADOWSOCKS -d $shadowsocks_ip -j RETURN" >>$firewall_gfw
echo >>$firewall_gfw

echo "# Ignore LANs ip addresses" >>$firewall_gfw
echo "iptables -t nat -A SHADOWSOCKS -d 0.0.0.0/8 -j RETURN" >>$firewall_gfw
echo "iptables -t nat -A SHADOWSOCKS -d 10.0.0.0/8 -j RETURN" >>$firewall_gfw
echo "iptables -t nat -A SHADOWSOCKS -d 127.0.0.0/8 -j RETURN" >>$firewall_gfw
echo "iptables -t nat -A SHADOWSOCKS -d 169.254.0.0/16 -j RETURN" >>$firewall_gfw
echo "iptables -t nat -A SHADOWSOCKS -d 172.16.0.0/16 -j RETURN" >>$firewall_gfw
echo "iptables -t nat -A SHADOWSOCKS -d 192.168.0.0/16 -j RETURN" >>$firewall_gfw
echo "iptables -t nat -A SHADOWSOCKS -d 224.0.0.0/4 -j RETURN" >>$firewall_gfw
echo "iptables -t nat -A SHADOWSOCKS -d 240.0.0.0/4 -j RETURN" >>$firewall_gfw
echo >>$firewall_gfw

echo "# Ignore China ip addresses" >>$firewall_gfw
# Get latest delegated internet number resources from apnic
apnic_list=/tmp/apnic_list
if [ -f $apnic_list ]; then
 echo "deleting old delegated internet number resources ..."
 rm $apnic_list
fi
echo "Downloading latest delegated internet number resources from apnic ..."
wget -q -O $apnic_list -c http://ftp.apnic.net/stats/apnic/delegated-apnic-latest

echo "Extracting china ip addresses from downloaded latest delegated internet number resources ..."
cat $apnic_list | \
    awk -F '|' '/CN.ipv4/ {print "iptables -t nat -A SHADOWSOCKS -d " $4 "/" 32-log($5)/log(2) " -j RETURN" }' \
    >> $firewall_gfw

echo >>$firewall_gfw

echo "# Other ip addresses should be redirected to shadowsocks' local port" >>$firewall_gfw
echo "iptables -t nat -A SHADOWSOCKS -p tcp -j REDIRECT --to-ports $shadowsocks_port" >>$firewall_gfw
echo >>$firewall_gfw

echo "# Apply the rules" >>$firewall_gfw
echo "iptables -t nat -A PREROUTING -p tcp -j SHADOWSOCKS" >>$firewall_gfw

echo "Firewall rules for shadowsocks have been written into file " $firewall_gfw
