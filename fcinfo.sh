#!/bin/sh
#
# Shows Fibre Channel Host/Target/LUN information
#
# Usage:
#   fcinfo <-h|-r|-d>
#       -h show HBAs
#       -r show targets
#       -d show LUNs
#
# Copyright (c) 2012 Ilya Voronin <ivoronin@gmail.com>
# 

function wwn() {
    sed -e 's/../:&/g;s/^:0x://' $1
}

MODE=""

set --  $(getopt hrd "$@")
while [ $# -gt 0 ]; do
    case "$1" in
    '-h') MODE="HOST" ;;
    '-r') MODE="RPORT" ;;
    '-d') MODE="DEVICE" ;;
    esac
    shift
done

if [ ! -d /sys/class/fc_host ]; then
    echo "No FC HBAs were found"
    exit 0
fi

HOST_FORMAT="%-4s %8s %23s %23s %7s %7s\n"
RPORT_FORMAT="%-4s %-5s %8s %23s %23s %7s\n"
DEVICE_FORMAT="%-4s %-5s %-3s %23s %5s %8s %16s %8s %8s %8s\n"

case "${MODE}" in
    "HOST") printf "${HOST_FORMAT}" \
                "HOST" "ADDR" "NWWN" "PWWN" "STATE" "SPEED" ;;
    "RPORT") printf "${RPORT_FORMAT}" \
                "HOST" "RPORT" "ADDR" "NWWN" "PWWN" "STATE" ;;
    "DEVICE") printf "${DEVICE_FORMAT}" \
                "HOST" "RPORT" "LUN" "RPORT PWWN" "NAME" \
                "VENDOR" "MODEL" "REVISION" "STATE" ;;
    *) echo "Usage: fcinfo <-h|-r|-d>"; exit 1 ;;
esac

for HOST in /sys/class/fc_host/host*; do
    HOST_NUM="${HOST##*host}"
    HOST_NWWN="$(wwn ${HOST}/node_name)"
    HOST_PWWN="$(wwn ${HOST}/port_name)"
    HOST_ADDR="$(cat ${HOST}/port_id)"
    HOST_SPEED="$(cat ${HOST}/speed)"
    HOST_STATE="$(cat ${HOST}/port_state)"
    HOST_TYPE="$(cat ${HOST}/port_type)"
    if [ "${MODE}" == "HOST" ]; then
        printf "${HOST_FORMAT}" "${HOST_NUM}" "${HOST_ADDR}" "${HOST_NWWN}" \
                                "${HOST_PWWN}" "${HOST_STATE}" "${HOST_SPEED}"
    else
        for RPORT in /sys/class/fc_remote_ports/rport-${HOST_NUM}:0-*; do
            RPORT_NUM="${RPORT##*-}"
            RPORT_NWWN="$(wwn ${RPORT}/node_name)"
            RPORT_PWWN="$(wwn ${RPORT}/port_name)"
            RPORT_ADDR="$(cat ${RPORT}/port_id)"
            RPORT_STATE="$(cat ${RPORT}/port_state)"
            if [ "${MODE}" == "RPORT" ]; then
                printf "${RPORT_FORMAT}" "${HOST_NUM}" "${RPORT_NUM}" "${RPORT_ADDR}" \
                                         "${RPORT_NWWN}" "${RPORT_PWWN}" "${RPORT_STATE}"
            else
                for DEVICE in /sys/class/scsi_device/${HOST_NUM}:0:${RPORT_NUM}:*; do
                    DEVICE_NUM="${DEVICE##*:}"
                    DEVICE_MAJMIN="$(cat ${DEVICE}/device/generic/dev)"
                    DEVICE_TYPE="$(cat ${DEVICE}/device/type)"
                    DEVICE_VENDOR="$(cat ${DEVICE}/device/vendor | tr -d ' ')"
                    DEVICE_MODEL="$(cat ${DEVICE}/device/model | tr -d ' ')"
                    DEVICE_REVISION="$(cat ${DEVICE}/device/rev)"
                    DEVICE_STATE="$(cat ${DEVICE}/device/state)"
                    DEVICE_NAME="-"
                    case "${DEVICE_TYPE}" in
                        "0")
                            # Disk
                            DEVICE_NAME=$(ls -d ${DEVICE}/device/block:sd* | \
                                        sed -ne 's#.*:\(sd[a-z]\+\)$#\1#p')
                        ;;
                        "1")
                            # Tape
                            DEVICE_NAME=$(ls -d ${DEVICE}/device/scsi_tape:st* | \
                                        sed -ne 's#.*:\(st[0-9]\+\)$#\1#p')
                        ;;
                        "8")
                            # Changer
                            DEVICE_NAME=$(ls -d ${DEVICE}/device/scsi_generic:sg* | \
                                        sed -ne 's#.*\(sg[0-9]\+\)$#\1#p')
                        ;;
                    esac
                    printf "${DEVICE_FORMAT}" "${HOST_NUM}" "${RPORT_NUM}" "${DEVICE_NUM}" \
                                            "${RPORT_PWWN}" "${DEVICE_NAME}" \
                                            "${DEVICE_VENDOR}" "${DEVICE_MODEL}" \
                                            "${DEVICE_REVISION}" "${DEVICE_STATE}"
                done
            fi
        done
    fi
done
