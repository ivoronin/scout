#!/bin/sh

set -e

VERSION="@VERSION@"

scout_recon() {
    DISTRO="UNKNOWN"

    if [ "$(scout_exec uname 2>/dev/null)" != "Linux" ]; then
        scout_warn "Unsupported OS"
    fi

    if [ "$(scout_exec whoami 2>/dev/null)" != "root" ]; then
        scout_warn "Running as non-root user"
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
            scout_warn "Unsupported Linux distro"
        ;;
    esac

    #
    # System
    #
    scout_info "system"
    scout_cmdo "system" hostname
    scout_cmdo "system" hostid
    scout_cmdo "system" lsb_release -a
    scout_cmdo "system" uname -a
    scout_cmdo "system" uptime
    scout_cmdo "system" who -r
    scout_cmdo "system" who -b
    scout_cmdo "system" runlevel

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
    scout_info "kernel"
    scout_cmdo "kernel" find /boot -ls
    scout_file "proc" /proc/cmdline
    scout_file "proc" /proc/version

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

    if [ "${DISTRO}" = "RedHat" ]; then
        scout_file "kernel/grub/efi" /boot/efi/EFI/redhat/grub.conf
    fi

    #
    # Packages
    #
    scout_info "packages"
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
    # Services
    #
    scout_info "services"
    case "${DISTRO}" in
        "RedHat") scout_cmdo "services" chkconfig --list
                  scout_file "services" /etc/inittab ;;
        "Debian") scout_cmdo "services" service --status-all ;;
    esac

    
    #
    # processes
    #
    scout_info "processes"
    scout_cmdo "system" ps alxwww
    scout_cmdo "system" pstree
    scout_cmdo "system" lsof -nb

    for PIDDIR in $(scout_find /proc -maxdepth 1 -name "[0-9]*" -type d); do
        PID=${PIDDIR##*/}
        scout_file "proc/${PID}" "${PIDDIR}/status"
        scout_file "proc/${PID}" "${PIDDIR}/smaps"
    done

    #
    # Memory
    #
    scout_info "memory"
    scout_cmdo "memory" swapon -s
    scout_cmdo "memory" free
    scout_cmdo "memory" free -m
    scout_cmdo "memory" free -g
    scout_file "proc" /proc/meminfo
    scout_file "proc" /proc/slabinfo
    scout_file "proc" /proc/buddyinfo
    scout_file "proc" /proc/vmstat

    #
    # Devices
    #
    scout_info "hardware"
    scout_file "proc" /proc/devices
    scout_file "proc" /proc/ioports
    scout_file "proc" /proc/interrupts
    scout_cmdo "devices" find /dev -ls
    scout_cmdo "devices" lspci
    scout_cmdo "devices" lspci -v
    scout_cmdo "devices" lsusb
    scout_cmdo "devices" lsusb -v

    # CPU
    scout_cmdo "devices" lscpu
    scout_file "proc" /proc/cpuinfo

    # DMI/SMBIOS
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
        FINDEXPR="-maxdepth 1 -type d"
        for BUS in $(scout_find /sys/bus ${FINDEXPR}); do
            scout_cmdo "devices/sysfs" systool -b "${BUS##*/}" -v
        done
        for CLASS in $(scout_find /sys/class ${FINDEXPR}); do
            scout_cmdo "devices/sysfs" systool -c "${CLASS##*/}" -v
        done
        for MODULE in $(scout_find /sys/module ${FINDEXPR}); do
            scout_cmdo "devices/sysfs" systool -m "${MODULE##*/}" -v
        done
    fi

    #
    # Disks
    #
    scout_info "storage"
    scout_cmdo "disks" fdisk -l  # Units: cylinders
    scout_cmdo "disks" fdisk -lu # Units: sectors
    scout_cmdo "disks" parted -l
    scout_cmdo "disks" raw -qa
    scout_cmdo "disks" blkid

    # /proc
    scout_file "proc/scsi" /proc/scsi/scsi
    scout_file "proc" /proc/partitions

    # lsblk
    if scout_test -x /bin/lsblk; then
        scout_cmdo "disks" lsblk -a
        scout_cmdo "disks" lsblk -ab
        scout_cmdo "disks" lsblk -at
        scout_cmdo "disks" lsblk -am
    fi

    # MD
    scout_file "proc" /proc/mdstat
    scout_file "disks/md" /etc/mdadm/mdadm.conf

    # LVM
    if scout_test -s /sbin/lvm; then
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
    fi

    # Multipath
    if scout_test -x /sbin/multipath; then
        scout_cmdo "disks" multipath -ll
        scout_cmdo "disks" multipath -ll -v2
        scout_file "disks" /etc/multipath/
        scout_file "disks" /etc/multipath.conf
    fi

    # Device mapper
    scout_cmdo "disks/dm" dmsetup table
    scout_cmdo "disks/dm" dmsetup info
    scout_cmdo "disks/dm" dmsetup deps
    scout_cmdo "disks/dm" dmsetup targets
    scout_cmdo "disks/dm" dmsetup version
    scout_cmdo "disks/dm" dmsetup ls --tree

    #
    # Filesystems
    #
    scout_info "filesystems"
    scout_cmdo "filesystems" df -h
    scout_cmdo "filesystems" df -i
    scout_cmdo "filesystems" mount
    scout_cmdo "filesystems" findmnt
    scout_file "filesystems" /etc/fstab
    scout_file "filesystems" /etc/fstab.d
    scout_file "filesystems" /etc/exports

    # tune2fs
    for FS in $(scout_exec mount | awk '{ if ( $5 ~ "^ext.$" ) { print $1 } }' 2>/dev/null); do
        scout_cmdo "filesystems" tune2fs -l "${FS}"
    done

    #
    # Networking
    #
    scout_info "network"
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
    for IF in $(scout_exec ip -o link | awk -F': ' '{ print $2 }' 2>/dev/null); do
        scout_cmdo "network" ethtool "${IF}"
        scout_cmdo "network" ethtool -i "${IF}"
        scout_cmdo "network" ethtool -k "${IF}"
        scout_cmdo "network" ethtool -P "${IF}"
        scout_cmdo "network" ethtool -S "${IF}"
    done

    # Bridge
    scout_cmdo "network" brctl show

    # Bonding
    scout_file "proc/net" /proc/net/bonding
    scout_cmdo "network" ifenslave -a

    # iptables
    if scout_test -f /proc/net/ip_tables_names; then
        for TABLE in $(scout_exec cat /proc/net/ip_tables_names 2>/dev/null); do
            scout_cmdo "network/iptables" iptables -t "${TABLE}" -Lnv --line-numbers
        done
    fi

    # iproute2
    scout_cmdo "network" ip route show table all
    scout_cmdo "network" ip link
    scout_cmdo "network" ip address
    scout_file "network" /etc/iproute2

    # ss
    scout_cmdo "network" ss -s
    scout_cmdo "network" ss -an
    scout_cmdo "network" ss -manpie

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
    # XEN
    #
    if scout_test -d /proc/xen; then
        scout_info "xen"
        scout_cmdo "xen" xm info
        scout_cmdo "xen" xm dmesg
        scout_cmdo "xen" xm list
        scout_cmdo "xen" xm list --long
        scout_cmdo "xen" xm vcpu-list
        scout_cmdo "xen" xm log
        scout_file "xen" /etc/xen
        scout_file "proc" /proc/xen
    fi

    #
    # Logs
    #
    scout_info "logs"
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
    echo "Usage: scout [OPTION...]"
    echo ""
    echo "  -r, --remote=HOSTNAME  collect data from remote machine HOSTNAME"
    echo "  -t, --tag=tag          add a tag (for example case number)"
    echo "  -v, --verbose          show what is being done"
    echo "  -h, --help             give this help list"
    echo "  -V, --version          print program version"
    echo ""
    echo "Mandatory arguments to long options are also mandatory for any"
    echo "corresponding short options."
    exit ${1:-0}
}

scout_version() {
    echo "${VERSION}"
    exit 0
}

scout_exec() {
    if [ -n "${SSH_HOST}" ]; then
        ssh -S "${SSH_CTL}" "${SSH_HOST}" $@
    else
        $@
    fi
}

scout_test() {
    scout_exec test $@ >/dev/null 2>&1
}

scout_find() {
    scout_exec find $@ 2>/dev/null
}

scout_copy() {
    SRC=$1 DST=$2
    if [ -n "${SSH_HOST}" ]; then
        # scp fails to copy 0-sized files (/proc), so we need to use sftp
        # -b /dev/null is needed to switch sftp to batch mode to make it quiet
        sftp -b /dev/null -p -r -q -o ControlMaster=no -o "ControlPath=${SSH_CTL}" \
            "${SSH_USER}@${SSH_HOST}:${SRC}" "${DST}" > /dev/null
    else
        cp -a "${SRC}" "${DST}" > /dev/null
    fi
}

scout_cmdo() {
    SUBDIR=$1 CMD=$2
    shift 2
    ARGS="$@"

    # Create subdir
    mkdir -p "${SCOUT_DIR}/${SUBDIR}"

    # Construct outut name
    OUT="${CMD##*/}${ARGS:+ ${ARGS}}"   # Basename
    # Remove spaces and slashes
    OUT=$(echo "$OUT" | sed -re 's#([ /])+#_#g')
    OUT="${SCOUT_DIR}/${SUBDIR}/${OUT}"

    # Run command
    scout_log -vn "Saving output of ${CMD}${ARGS:+ ${ARGS}}: "
    if scout_exec "${CMD}" ${ARGS} > "${OUT}.out" 2> "${OUT}.err"; then
        scout_log -vs "success"
    else
        E=$?
        echo -n "$E" > "${OUT}.rc"
        if [ "$E" -lt 126 ]; then
            scout_log -vs "success"
        elif [ "$E" -eq 127 ]; then
            scout_log -vs "not found"
        else
            scout_log -vs "failure"
        fi
    fi
}

scout_file() {
    SUBDIR=$1 FILE=$2

    # Create subdir
    mkdir -p "${SCOUT_DIR}/${SUBDIR}"

    # Construct outut name
    OUT="${SCOUT_DIR}/${SUBDIR}/${FILE##*/}" # Basename

    # Copy file/dir
    scout_log -vn "Saving file/dir ${FILE}: "
    if scout_test -e "${FILE}"; then
        if scout_copy "${FILE}" "${OUT}" 2> /dev/null; then
            scout_log -vs "success"
        else
            scout_log -vs "failure"
        fi
    else
        scout_log -vs "not found"
    fi
}

scout_prep() {
    SCOUT_DIR=$(mktemp --directory)
    SCOUT_LOG="${SCOUT_DIR}/scout.log"

    echo "${VERSION}" > "${SCOUT_DIR}/version"

    # Start master SSH connection
    if [ -n "${SSH_HOST}" ]; then
        scout_log -v "Starting master SSH connection to ${SSH_USER}@${SSH_HOST}:${SSH_PORT}"
        SSH_CTL=$(mktemp --dry-run)
        ssh -N -f -M -S "${SSH_CTL}" -p "${SSH_PORT}" "${SSH_USER}@${SSH_HOST}"
    fi
}

scout_pack() {
    # Delete empty .err files
    find "${SCOUT_DIR}" -type f -name "*.err" -size 0 -delete

    # Create TBZ
    LONGNAME=$(scout_exec hostname)
    SHORTNAME=${LONGNAME%%.*}
    DATE=$(scout_exec date +%m%d%y.%H%M%S)
    NAME="scout-${SHORTNAME}${TAG:+.${TAG}}.${DATE}"
    tar -c -j -C "${SCOUT_DIR%/*}" -f "${NAME}.tbz" \
        --transform "s#${SCOUT_DIR##*/}#${NAME}#" "${SCOUT_DIR##*/}"

    scout_log "DONE: ${NAME}.tbz"
}

scout_cleanup() {
    # Stop master SSH connection
    # bugs.debian.org/563857
    [ -n "${SSH_HOST}" ] && ssh -S "${SSH_CTL}" -O exit -q "${SSH_HOST}" 2>/dev/null 

    # Remove output directory
    rm -rf "${SCOUT_DIR}"
}

scout_warn() {
    scout_log "WARNING: $*"
}

scout_info() {
    scout_log "RUNNING: $*"
}

scout_log() {
    OPTIND=0 N="" S=0 V=0
    while getopts "snv" OPTION; do
        case "${OPTION}" in
            "n") N="-n" ;;
            "s") S=1 ;;
            "v") V=1 ;;
        esac
        shift $(($OPTIND-1))
    done

    [ "$S" -eq 1 ] && MSG="$@" || MSG="$(date '+%m.%d.%y %H:%M:%S') $@"

    if [ "${V}" -eq 1 ]; then
        if [ "${VERBOSE}" -eq 1 ]; then
            echo $N "${MSG}"
        fi
    else
        echo $N "${MSG}"
    fi
    echo $N "${MSG}" >> "${SCOUT_LOG}"
}

# SSH
SSH_USER="root"
SSH_HOST=
SSH_PORT=22
SSH_CTL=

TAG=
VERBOSE=0

SCOUT_DIR=
SCOUT_LOG=

OPTIONS=$(getopt -n scout -o hr:t:vV -l help,remote:,tag:,verbose,version -- "$@") || exit 1
eval set -- $OPTIONS

while [ $# -gt 0 ]; do
    case $1 in
        "--") shift; break ;;
        -h|--help) scout_help ;;
        -r|--remote) SSH_HOST="$2"; shift ;;
        -t|--tag) TAG="$2"; shift ;;
        -v|--verbose) VERBOSE=1 ;;
        -V|--version) scout_version  ;;
        *) scout_help 1 ;;
    esac
    shift
done

scout_prep
trap scout_cleanup EXIT # Cleanup on exit
scout_recon
scout_pack
exit
