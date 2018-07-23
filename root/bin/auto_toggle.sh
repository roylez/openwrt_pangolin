#!/bin/sh
# toggle between AP mode and router mode by linking /etc/config/{network,wireless}
# to corresponding files

network_conf=/etc/config/network

# if network is a sym link
if [[ -h $network_conf ]]; then
    old_target=$(readlink $network_conf |sed 's:.*\.::')
fi

if [[ "client" = $old_target ]]; then
    iw dev |grep -q 'ssid .*client' || (/root/bin/toggle_ap.sh && ifup -a &)
fi
