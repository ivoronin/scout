#!/bin/sh
#
# Kernel slab allocator statistics reporting script
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

printf "%32s %8s\n" "CACHE" "SIZE"
awk '/^[^#]/ { printf("%32s %7dk\n", $1, $3*$4/1024); }' \
	"${ROOT}/proc/slabinfo" 2> /dev/null | sort -rhk2
