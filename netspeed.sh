#!/bin/sh
#
# Linux network interface utilization reporting script
#
# Copyright (c) 2012 Ilya Voronin <ivoronin@gmail.com>
#

printf "%8s %8s %8s\n" "IFACE" "TX" "RX"
while cat /proc/net/dev; do sleep ${1:-5}; done | awk -F: '
/:/ {
    n = split($2, counters, " ");
    rb = counters[1];
    tb = counters[9];
    time = systime();

    if ( stats[$1, "time"] != 0 ) {
        rbs = ( rb - stats[$1, "rb"] ) / ( time - stats[$1, "time"] );
        tbs = ( tb - stats[$1, "tb"] ) / ( time - stats[$1, "time"] );
        printf("%8s %7dK %7dK\n", $1, rbs/1024, tbs/1024);
    }

    stats[$1, "time"] = time;
    stats[$1, "rb"] = rb;
    stats[$1, "tb"] = tb;
}'
