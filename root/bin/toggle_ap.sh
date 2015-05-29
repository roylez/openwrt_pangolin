#!/bin/sh
# toggle between AP mode and router mode by linking /etc/config/{network,wireless}
# to corresponding files

network_conf=/etc/config/network

# if network is a sym link
if [[ -h $network_conf ]]; then
    old_target=$(readlink $network_conf |sed 's:.*\.::')
fi

if [[ $old_target = "ap" ]] || [[ -z $old_target ]]; then
    target='router'
else
    target='ap'
fi

logger "===== enabling $target mode ====="

ln -sf /etc/config/network.$target /etc/config/network
ln -sf /etc/config/wireless.$target /etc/config/wireless
