#!/bin/bash

VERSION="@VERSION@"

if (( ${BASH_VERSINFO[0]} < 3 )); then
    echo "Bash version 3 or greater is required to run this program"
    exit 1
fi

set -e
shopt -s extglob

scout_recon() {
    if [[ "$(scout_exec uname 2>/dev/null)" != "Linux" ]]; then
        scout_error "Unsupported OS"
    fi

    case "$(scout_exec lsb_release -is 2>/dev/null)" in
        "RedHatEnterpriseServer" | "CentOS") 
            DISTRO="RedHat"
        ;;
        "Debian" | "Ubuntu")
            DISTRO="Debian"
        ;;
        "SUSE LINUX")
            DISTRO="SuSe"
        ;;
        *)
            DISTRO="UNKNOWN"
        ;;
    esac

    #
    # System
    #
    scout_cmdo "system" hostname
    scout_cmdo "system" hostid
    scout_cmdo "system" lsb_release -a
    scout_cmdo "system" uname -a
    scout_cmdo "system" uptime
    scout_cmdo "system" who -r
    scout_cmdo "system" who -b
    scout_cmdo "system" runlevel

    # processes
    scout_cmdo "system" ps alxwww
    scout_cmdo "system" pstree
    scout_cmdo "system" lsof -nb

    case "${DISTRO}" in
        "RedHat")
            scout_file "system" /etc/redhat-release
        ;;
        "Debian")
            scout_file "system" /etc/debian_version
        ;;
        "SuSe")
            scout_file "system" /etc/SuSE-release
            scout_file "system" /etc/novell-release
            scout_file "system" /etc/sles-release
        ;;
    esac

    # ipcs
    scout_cmdo "system/ipcs" ipcs -a
    scout_cmdo "system/ipcs" ipcs -a -t
    scout_cmdo "system/ipcs" ipcs -a -p
    scout_cmdo "system/ipcs" ipcs -a -c
    scout_cmdo "system/ipcs" ipcs -a -l
    scout_cmdo "system/ipcs" ipcs -a -u

    # sysctl
    scout_file "system" /etc/sysctl.conf
    scout_file "system" /etc/sysctl.d
    scout_cmdo "system" sysctl -a

    # linker
    scout_file "system" /etc/ld.so.conf
    scout_file "system" /etc/ld.so.conf.d
    scout_cmdo "system" /sbin/ldconfig -v -N -X
    scout_cmdo "system" /sbin/ldconfig -p -N -X

    # etc
    scout_cmdo "system" find /etc -ls

    # cron
    scout_cmdo "system/cron" crontab -l -u root
    scout_file "system/cron" /etc/crontab
    scout_file "system/cron" /etc/cron.d
    scout_file "system/cron" /etc/cron.daily
    scout_file "system/cron" /etc/cron.hourly
    scout_file "system/cron" /etc/cron.monthly
    scout_file "system/cron" /etc/cron.weekly
    scout_cmdo "system/cron" find /var/spool/cron/crontabs -ls

    # pam
    scout_file "system/pam" /etc/pam.d
    scout_file "system/pam" /etc/security

    #
    # Kernel
    #
    scout_cmdo "kernel" find /boot -ls
    scout_file "kernel" /proc/cmdline
    scout_file "kernel" /proc/version

    # Modules
    scout_cmdo "kernel" lsmod
    scout_file "kernel" /etc/depmod.d
    scout_file "kernel" /etc/modprobe.d
    scout_file "kernel" /etc/modprobe.conf
    scout_file "kernel" /etc/modules
    scout_file "kernel" /etc/modules.conf

    # Grub
    scout_file "kernel/grub" /boot/grub/device.map
    scout_file "kernel/grub" /boot/grub/grub.conf  # GRUB < 1.0
    scout_file "kernel/grub" /boot/grub/menu.lst   # GRUB > 1.0
    scout_file "kernel/grub" /boot/grub/grub.cfg   # GRUB > 1.0

    if [[ "${DISTRO}" == "RedHat" ]]; then
        scout_file "kernel/grub/efi" /boot/efi/EFI/redhat/grub.conf
    fi
    
    #
    # Devices
    #
    scout_file "devices" /proc/devices
    scout_file "devices" /proc/ioports
    scout_file "devices" /proc/interrupts
    scout_cmdo "devices" find /dev -ls
    scout_cmdo "devices" lspci
    scout_cmdo "devices" lspci -v
    scout_cmdo "devices" lsusb
    scout_cmdo "devices" lsusb -v

    # CPU
    scout_cmdo "devices" lscpu
    scout_file "devices" /proc/cpuinfo

    scout_cmdo "devices" dmidecode
    scout_cmdo "devices" biosdecode
    scout_cmdo "devices" vpddecode
    scout_cmdo "devices" ownership

    # udev
    scout_file "devices" /etc/udev/udev.conf
    scout_file "devices" /etc/udev/rules.d
    scout_cmdo "devices" udevinfo -e                # old udev
    scout_cmdo "devices" udevadm info --export-db   # new udev

    if scout_test -x /usr/bin/systool; then
        for BUS in $(scout_find /sys/bus -maxdepth 1 -type d); do
            scout_cmdo "devices/sysfs" systool -b "$(basename ${BUS})" -v
        done
        for CLASS in $(scout_find /sys/class -maxdepth 1 -type d); do
            scout_cmdo "devices/sysfs" systool -c "$(basename ${CLASS})" -v
        done
        for MODULE in $(scout_find /sys/module -maxdepth 1 -type d); do
            scout_cmdo "devices/sysfs" systool -m "$(basename ${MODULE})" -v
        done
    else
        scout_log "Skipping systool: not installed"
    fi
    true

    #
    # Packages
    #
    case "${DISTRO}" in
        "RedHat")
            scout_cmdo "packages" rpm -qa
            scout_file "packages" /etc/yum.conf
            scout_file "packages" /etc/yum
            scout_file "packages" /etc/yum.repos.d
        ;;
        "Debian")
            scout_cmdo "packages" dpkg -l
            scout_file "packages" /etc/apt
        ;;
        "SuSe")
            # TODO: Add YaST
            scout_cmdo "packages" rpm -qa
        ;;
    esac

    #
    # Networking
    #
    case "${DISTRO}" in
        "RedHat")
            scout_file "network" /etc/sysconfig/network
            ESNS="/etc/sysconfig/network-scripts"
            scout_file "network" find ${ESNS} -ls
            for IFCFG in $(scout_find ${ESNS} -name "ifcfg-*" -maxdepth 1 -type f); do
                scout_file "network/network-scripts" "${IFCFG}"
            done
        ;;
        "Debian")
            scout_file "network" /etc/network/interfaces
        ;;
    esac

    # Common commands
    scout_cmdo "network" ifconfig -a
    scout_cmdo "network" netstat -rn
    scout_cmdo "network" netstat -peona
    scout_cmdo "network" netstat -s
    scout_cmdo "network" arp -an

    # ethtool
    for IF in $(scout_exec ip -o link | awk -F': ' '{ print $2 }'); do
        scout_cmdo "network" ethtool "${IF}"
        scout_cmdo "network" ethtool -i "${IF}"
        scout_cmdo "network" ethtool -k "${IF}"
        scout_cmdo "network" ethtool -P "${IF}"
        scout_cmdo "network" ethtool -S "${IF}"
    done

    # Bridge
    scout_cmdo "network" brctl show

    # Bonding
    scout_file "network" /proc/net/bonding
    scout_cmdo "network" ifenslave -a

    # iptables
    if scout_test -f /proc/net/ip_tables_names; then
        for TABLE in $(scout_exec cat /proc/net/ip_tables_names); do
            scout_cmdo "network/iptables" iptables -t "${TABLE}" -Lnv --line-numbers
        done
    else
        scout_log "Skipping iptables: not enabled"
    fi

    # iproute2
    scout_cmdo "network" ip route show table all
    scout_cmdo "network" ip link
    scout_cmdo "network" ip address
    scout_file "network" /etc/iproute2

    # ntp
    scout_cmdo "network" ntpq -p

    # hosts
    scout_file "network" /etc/hosts
    scout_file "network" /etc/hosts.allow
    scout_file "network" /etc/hosts.deny
    scout_file "network" /etc/hosts.equiv

    # resolver
    scout_file "network" /etc/nsswitch.conf
    scout_file "network" /etc/resolv.conf
    scout_file "network" /etc/hostname
    scout_file "network" /etc/services
    scout_file "network" /etc/ethers
    scout_file "network" /etc/networks
    scout_file "network" /etc/protocols

    # inetd
    scout_file "network" /etc/inetd.conf
    scout_file "network" /etc/xinetd.conf
    scout_file "network" /etc/xinetd.d
    scout_file "network" /etc/xinetd.d

    #
    # Filesystems
    #
    scout_cmdo "filesystems" df -h
    scout_cmdo "filesystems" df -i
    scout_cmdo "filesystems" mount
    scout_cmdo "filesystems" findmnt
    scout_file "filesystems" /etc/fstab
    scout_file "filesystems" /etc/fstab.d
    scout_file "filesystems" /etc/exports

    # tune2fs
    for FS in $(scout_exec mount | awk '{ if ( $5 ~ "^ext.$" ) { print $1 } }'); do
        scout_cmdo "filesystems" tune2fs -l "${FS}"
    done

    #
    # Memory
    #
    scout_cmdo "memory" swapon -s
    scout_cmdo "memory" free
    scout_cmdo "memory" free -m
    scout_cmdo "memory" free -g
    scout_file "memory" /proc/meminfo
    scout_file "memory" /proc/slabinfo
    scout_file "memory" /proc/buddyinfo
    scout_file "memory" /proc/vmstat
    
    #
    # Disks
    #
    scout_cmdo "disks" fdisk -l  # Units: cylinders
    scout_cmdo "disks" fdisk -lu # Units: sectors
    scout_cmdo "disks" parted -l
    scout_cmdo "disks" raw -qa
    scout_cmdo "disks" blkid

    # /proc
    scout_file "disks" /proc/scsi/scsi
    scout_file "disks" /proc/partitions

    # lsblk
    if scout_test -x /bin/lsblk; then
        scout_cmdo "disks" lsblk -a
        scout_cmdo "disks" lsblk -ab
        scout_cmdo "disks" lsblk -at
        scout_cmdo "disks" lsblk -am
    else
        scout_log "Skipping lsblk: not installed"
    fi

    # MD
    scout_file "disks/md" /proc/mdstat
    scout_file "disks/md" /etc/mdadm/mdadm.conf

    # LVM
    scout_cmdo "disks/lvm" lvs -o lv_all
    scout_cmdo "disks/lvm" lvdisplay -m --all
    scout_cmdo "disks/lvm" pvs -o pv_all
    scout_cmdo "disks/lvm" pvdisplay -m
    scout_cmdo "disks/lvm" vgs -o vg_all
    scout_cmdo "disks/lvm" vgdisplay -v
    scout_cmdo "disks/lvm" lvm dumpconfig
    scout_cmdo "disks/lvm" lvm formats
    scout_cmdo "disks/lvm" lvm segtypes
    scout_cmdo "disks/lvm" lvm version
    scout_file "disks/lvm" /etc/lvm/lvm.conf

    # Multipath
    if scout_test -x /sbin/multipath; then
        scout_cmdo "disks" multipath -ll # -v4
        scout_file "disks" /etc/multipath.conf
    else
        scout_log "Skipping multipath: not installed"
    fi

    # Device mapper
    scout_cmdo "disks/dm" dmsetup table
    scout_cmdo "disks/dm" dmsetup info
    scout_cmdo "disks/dm" dmsetup deps
    scout_cmdo "disks/dm" dmsetup targets
    scout_cmdo "disks/dm" dmsetup version
    scout_cmdo "disks/dm" dmsetup ls --tree

    #
    # Services
    #
    case "${DISTRO}" in
        "RedHat") scout_cmdo "services" chkconfig --list
                  scout_file "services" /etc/inittab ;;
        "Debian") scout_cmdo "services" service --status-all ;;
    esac

    #
    # XEN
    #
    if scout_test -d /proc/xen; then
        scout_cmdo "xen" xm info
        scout_cmdo "xen" xm dmesg
        scout_cmdo "xen" xm list
        scout_cmdo "xen" xm list --long
        scout_cmdo "xen" xm vcpu-list
        scout_cmdo "xen" xm log
        scout_file "xen" /etc/xen
        scout_file "xen" /proc/xen
    else
        scout_log "Skipping xen: not running"
    fi

    #
    # KVM
    #
    scout_cmdo "kvm" kvm_stat --once

    #
    # Logs
    #
    scout_cmdo "system" dmesg

    # logrotate
    scout_file "logs" /etc/logrotate.conf
    scout_file "logs" /etc/logrotate.d
    scout_file "logs" /var/lib/logrotate.status

    # syslog
    for LOG in $(scout_find /var/log -maxdepth 1 \
                        -name "messages*" -o -name "syslog*" -type f); do
        scout_file "logs" "${LOG}"
    done
    scout_file "logs" /etc/syslog.conf
    scout_file "logs" /etc/rsyslog.conf
}

scout_help() {
    echo "scout [-V] [-s hostname] [-t tag] [-v]" ; exit ${1:-0}
}

scout_version() {
    echo "${VERSION}"
    exit 0
}

scout_exec() {
    [[ ${SSH_HOST} ]] && ssh -S "${SSH_CTL}" "${SSH_HOST}" $@ || $@
}

scout_test() {
    scout_exec test $@ >/dev/null 2>&1
}

scout_find() {
    scout_exec find $@ 2>/dev/null
}

scout_copy() {
    SRC=$1; DST=$2
    if [[ ${SSH_HOST} ]]; then
        # scp fails to copy 0-sized files (/proc), so we need to use sftp
        # -b /dev/null is needed to switch sftp to batch mode to make it quiet
        sftp -b /dev/null -p -r -q -o ControlMaster=no -o "ControlPath=${SSH_CTL}" \
            "${SSH_USER}@${SSH_HOST}:${SRC}" "${DST}" > /dev/null
    else
        cp -a "${SRC}" "${DST}" > /dev/null
    fi
}

scout_cmdo() {
    SUBDIR=$1; CMD=$2; ARGS=${@:3}

    # Create subdir
    mkdir -p "${SCOUT_DIR}/${SUBDIR}"

    # Construct outut name
    OUT="${CMD##*/}${ARGS:+ ${ARGS}}"   # Basename
    OUT="${OUT//[ \/]/_}"               # Remove spaces and slashes
    OUT="${OUT//+(_)/_}"                # Remove duplicate underscores
    OUT="${SCOUT_DIR}/${SUBDIR}/${OUT}"

    # Run command
    scout_log "Saving output of ${CMD}${ARGS:+ ${ARGS}}"
    scout_exec ${CMD} ${ARGS} > "${OUT}.out" 2> "${OUT}.err" || echo -n "$?" > "${OUT}.rc"
}

scout_file() {
    SUBDIR=$1; FILE=$2

    # Create subdir
    mkdir -p "${SCOUT_DIR}/${SUBDIR}"

    # Construct outut name
    OUT="${SCOUT_DIR}/${SUBDIR}/${FILE##*/}" # Basename

    # Copy file/dir
    scout_log "Saving file/dir ${FILE}"
    scout_copy "${FILE}" "${OUT}" 2> /dev/null || true # Ignore errors
}

scout_prep() {
    SCOUT_DIR=$(mktemp --directory)

    echo "${VERSION}" > "${SCOUT_DIR}/version"

    # Start master SSH connection
    if [[ -n ${SSH_HOST} ]]; then
        scout_log "Starting master SSH connection to ${SSH_USER}@${SSH_HOST}:${SSH_PORT}"
        SSH_CTL=$(mktemp --dry-run)
        ssh -N -f -M -S "${SSH_CTL}" -p "${SSH_PORT}" "${SSH_USER}@${SSH_HOST}"
    fi
}

scout_pack() {
    # Delete empty .err files
    scout_log "Cleaning up output directory"
    find "${SCOUT_DIR}" -type f -name "*.err" -size 0 -delete

    # Create TBZ
    SHORTNAME=$(scout_exec hostname --short)
    DATE=$(scout_exec date +%m%d%y.%H%M%S)
    NAME="scout-${SHORTNAME}${TAG:+.${TAG}}.${DATE}"
    scout_log "Packing collected data to ${NAME}.tbz"
    tar -c -j -C "$(dirname ${SCOUT_DIR})" -f "${NAME}.tbz" \
        --transform "s#$(basename ${SCOUT_DIR})#${NAME}#" "$(basename ${SCOUT_DIR})"

    (( ${VERBOSE} )) && scout_log "Output saved in ${NAME}.tbz" || echo "${NAME}.tbz"
}

scout_cleanup() {
    # Stop master SSH connection
    # bugs.debian.org/563857
    [[ ${SSH_HOST} ]] && ssh -S "${SSH_CTL}" -O exit -q "${SSH_HOST}" 2>/dev/null 

    # Remove output directory
    rm -rf "${SCOUT_DIR}"
}

scout_error() {
    (( ${VERBOSE} )) && scout_log $@ || echo $@
    exit 1
}

scout_log() {
    MSG="$(date '+%m.%d.%y %H:%M:%S') $@"
    (( ${VERBOSE} )) && echo "$MSG"
    echo "${MSG}" >> "${SCOUT_DIR}/scout.log"
}

# SSH
SSH_USER="root"
SSH_HOST=
SSH_PORT=22
SSH_CTL=

TAG=
VERBOSE=0

SCOUT_DIR=

while getopts "hs:t:vV" OPTION; do
    case "${OPTION}" in
        "h") scout_help         ;;
        "s") SSH_HOST=${OPTARG} ;;
        "t") TAG=${OPTARG}      ;;
        "v") let VERBOSE+=1     ;; # evaluate as an arithmetic expression
        "V") scout_version      ;;
        "?") scout_help 1       ;;
    esac
done

scout_prep
trap scout_cleanup EXIT # Cleanup on exit
scout_recon
scout_pack
exit
