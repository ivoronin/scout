#!/bin/sh
#
# Linux per-process memory statistics reporting script
#
# Columns:
#  PID      - Process ID
#  SIZE     - Virtual size
#  RSS      - Resident Set Size (used RAM: shared and private)
#  PSS      - Proportional Set Size (Sum of pages, where each page
#             is divided by the number of processes sharing it)
#  SHR      - Shared set size
#  PRIV      - Private (unique) set size
#  REF      - Referened set size (see /proc/pid/clear_refs)
#  ANON     - Anonymous set size (not mapped to any files)
#  HUGE     - Transparent anonymous huge pages set size
#  SWAP     - Swapped set size
#  LCK      - Locked memory size
#  SHM      - Size of attached SYSV SHM segments
#  COMMAND  - Process name
#
# Known issues:
#  Script fails to detect SysV shared memory on old kernels (RHEL5)
#  Execution can take a while depending on how many processes are running
#
# Copyright (c) 2012 Ilya Voronin <ivoronin@gmail.com>
#

ROOT=/

OPTIONS=$(getopt -n pmemstat -o R: -- "$@") || exit 1
eval set -- "${OPTIONS}"

while [ $# -ge 0 ]; do
    case "$1" in
        -R) ROOT="$2" ;;
        --) shift ; break ;;
        *) break ;;
    esac
    shift
done

printf "%8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %8s %s\n" \
    "PID" "SIZE" "RSS" "PSS" "SHR" "PRIV" "REF" "ANON" "HUGE" "SWAP" "LCK" "SHM" "COMMAND"

for PIDDIR in $(find "${ROOT}/proc" -maxdepth 1 -type d -name "[0-9]*"); do
    # /proc/pid/comm is not available in old kernels
    # /proc/pid/cmdline is too long sometimes and separator varies (\0 or \s)
    # so this is the most stable interface
    COMMAND=$(awk '/^Name:/ { print $2 }' "${PIDDIR}/status" 2> /dev/null)
    awk "-vpid=${PIDDIR##*/}" "-vcommand=${COMMAND}" \
        '/SYSV/ { sysv = 1 }
         /^Size:/ { if ( sysv == 1 ) { shm += $2; sysv = 0; } else size += $2 }
         /^Rss:/ { rss += $2 }
         /^Pss:/ { pss += $2 }
         /^Shared_Clean:/ { shared += $2 }
         /^Shared_Dirty:/ { shared += $2 }
         /^Private_Clean:/ { private += $2 }
         /^Private_Dirty:/ { private += $2 }
         /^Referenced:/ { referenced += $2 }
         /^Anonymous:/ { anonymous += $2 }
         /^AnonHugePages:/ { hugepages += $2 }
         /^Swap:/ { swap += $2 }
         /^Locked:/ { locked += $2 }
        END { printf("%8d %7dM %7dM %7dM %7dM %7dM %7dM %7dM %7dM %7dM %7dM %7dM %s\n",
              pid, size/1024, rss/1024, pss/1024, shared/1024, private/1024, referenced/1024, 
              anonymous/1024, hugepages/1024, swap/1024, locked/1024, shm/1024, command) }' \
        "${PIDDIR}/smaps" 2> /dev/null
done | sort -rhk4