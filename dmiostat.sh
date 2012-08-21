#!/bin/sh
#
# Disk Mapper-aware iostat
#
# Makes the automatic grouping of the disk devices in the iostat output according to device mapper tables.
# Requires sysstat version 10.0.5 or later: http://sebastien.godard.pagesperso-orange.fr/
# dmsetup table format description:
# http://docs.redhat.com/docs/en-US/Red_Hat_Enterprise_Linux/6/html/Logical_Volume_Manager_Administration/device_mapper.html
#
# Copyright (c) 2012 Ilya Voronin <ivoronin@gmail.com>
#

dmiostat_lookup_name() {
    MAJOR="${1%:*}"
    MINOR="${1#*:}"
    while read -a LINE; do
        if [[ "${LINE[0]}" == "${MAJOR}" && "${LINE[1]}" == "${MINOR}" ]]; then
            echo "${LINE[3]}"
        fi
    done < /proc/partitions
}
 
dmiostat_main() {
    GROUP_ARGS=""
    IOSTAT_ARGS="$*"

    OUTPUT="$(mktemp)"
    dmsetup table > "${OUTPUT}"
    
    while read -a LINE; do
        DEVICES=""
        set -- ${LINE[@]}

        GROUP="${1%%:}" ; shift
        GROUP="${GROUP#*-}"
        START="$1" ; shift
        LENGTH="$1" ; shift
        MAPPING="$1" ; shift
        
        case "${MAPPING}" in
            "multipath")
                FEATURES="$1" ; shift
                shift "${FEATURES}"

                HANDLERARGS="$1" ; shift
                shift "${HANDLERARGS}"

                PATHGROUPS="$1" ; shift
                PATHGROUP="$1" ; shift

                for _G in $(seq 1 "${PATHGROUPS}"); do
                    PATHSELECTOR="$1" ; shift
                    SELECTORARGS="$1" ; shift
                    shift "${SELECTORARGS}"
                    PATHS="$1" ; shift
                    PATHARGS="$1" ; shift
                    for _P in $(seq 1 "${PATHS}"); do
                        DEVICE="$1" ; shift
                        IOREQS="$1" ; shift
                        NAME="$(dmiostat_lookup_name "${DEVICE}")"
                        DEVICES="$DEVICES $NAME"
                    done
                done
            ;;
            "linear")
                DEVICE="$1" ; shift
                OFFSET="$1" ; shift
                NAME="$(dmiostat_lookup_name "${DEVICE}")"
                DEVICES="$DEVICES $NAME"
            ;;
            *)
                continue;
            ;;
        esac

        GROUP_ARGS="${GROUP_ARGS} -g ${GROUP} ${DEVICES} "
    done < "${OUTPUT}"
    rm -f "${OUTPUT}"
    iostat ${GROUP_ARGS} ${IOSTAT_ARGS}
}

dmiostat_main $*
