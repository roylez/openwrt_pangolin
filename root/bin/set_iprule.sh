#!/bin/sh
grep -F "option lookup '100'" /etc/config/network || \
	cat <<- EOF >> /etc/config/network

	config rule
	        option mark   '0x1'
	        option lookup '100'
	EOF
