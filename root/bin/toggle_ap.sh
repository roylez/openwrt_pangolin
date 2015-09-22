#!/bin/sh
# toggle between AP mode and router mode by linking /etc/config/{network,wireless}
# to corresponding files

network_conf=/etc/config/network

# if network is a sym link
if [[ -h $network_conf ]]; then
    old_target=$(readlink $network_conf |sed 's:.*\.::')
fi

case $old_target in
    ap     ) target=client  ;;
    client ) target=router  ;;
    router ) target=ap      ;;
    * ) target=ap	    ;;
esac

logger "===== enabling $target mode ====="

ln -sf /etc/config/network.$target /etc/config/network
ln -sf /etc/config/wireless.$target /etc/config/wireless
