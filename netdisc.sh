#!/bin/bash
#
# Looks for CDP/LLDP packets on network interfaces
#
# Copyright (c) 2013 Ilya Voronin <ivoronin@gmail.com>
#
# Usage:
#   netdisc.sh [eth0 eth1 ...]
#

TIMEOUT="61s"
IGNORE_INTERFACES="^(lo|usb|bond|tun|tap|macvtap|br)"

if [ $# -ne 0 ]; then
    INTERFACES=$*
else
    INTERFACES=$(ip -o link |\
        sed -re "s/^[^:]: ([^:]+): .*/\1/" |\
            grep -Ev "${IGNORE_INTERFACES}")
fi

for INTERFACE in ${INTERFACES}; do
    echo "> Looking for CDP/LLDP packet on ${INTERFACE} for at least ${TIMEOUT}"
    timeout "${TIMEOUT}" \
        tcpdump -i "${INTERFACE}" -nn -v -c 1 -s 1500 \
            '(ether[12:2]=0x88cc or ether[20:2]=0x2000)' 2>&1 |\
                sed -e "s/^/. ${INTERFACE}: /"
done
