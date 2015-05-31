#!/bin/bash
# Description:
#

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
    awk -F '|' '/CN.ipv4/ {print  $4 "/" 32-log($5)/log(2) }' \
    > china.list
