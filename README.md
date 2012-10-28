Scout - Linux diagnostic data collection toolkit
================================================

Scout is a collection of tools to get linux system runtime diagnostic
information useful for technical support.

dmiostat
--------

Makes the automatic grouping of the disk devices in the iostat output
according to device mapper tables (requires sysstat version 10.0.5 or later):

    # dmiostat -dm 5
    Device:            tps    MB_read/s    MB_wrtn/s    MB_read    MB_wrtn
    sdc               0.00         0.00         0.00          0          0
    sdg               0.00         0.00         0.00          0          0
    sde               0.00         0.00         0.00          0          0
    sdi               0.00         0.00         0.00          0          0
     mpath2           0.00         0.00         0.00          0          0
    sdd             255.20         3.02        11.84         15         59
    sdh             267.60         3.91        11.70         19         58
    sdb               0.00         0.00         0.00          0          0
    sdf               0.00         0.00         0.00          0          0
     mpath1         522.80         6.93        23.54         34        117

fcinfo
------

Shows Fibre Channel Host/Target/LUN information:

    # fcinfo -h
    HOST     ADDR                    NWWN                    PWWN   STATE   SPEED
    3    0x011700 20:00:00:24:88:45:a3:d8 21:00:00:24:88:45:a3:d8  Online  8 Gbit
    4    0x011800 20:00:00:24:88:45:a3:d9 21:00:00:24:88:45:a3:d9  Online  8 Gbit
    5    0x011700 20:00:00:24:88:45:95:6e 21:00:00:24:88:45:95:6e  Online  8 Gbit
    6    0x011800 20:00:00:24:88:45:95:6f 21:00:00:24:88:45:95:6f  Online  8 Gbit

    # fcinfo -r
    HOST RPORT     ADDR                    NWWN                    PWWN   STATE
    3    0     0x011c00 50:06:04:90:be:a0:61:36 50:06:04:99:3e:a0:61:36  Online
    3    1     0x011d00 50:06:04:90:be:a0:61:36 50:06:04:97:3e:a0:61:36  Online
    4    0     0x010a00 50:06:04:90:c4:60:4a:2c 50:06:04:90:44:60:4a:2c  Online
    4    1     0x010e00 50:06:04:90:c4:60:4a:2c 50:06:04:99:44:60:4a:2c  Online
    5    0     0x010a00 50:06:04:90:c4:60:4a:2c 50:06:04:90:44:60:4a:2c  Online
    5    1     0x010e00 50:06:04:90:c4:60:4a:2c 50:06:04:99:44:60:4a:2c  Online
    6    0     0x011c00 50:06:04:90:be:a0:61:36 50:06:04:99:3e:a0:61:36  Online
    6    1     0x011d00 50:06:04:90:be:a0:61:36 50:06:04:97:3e:a0:61:36  Online

    # fcinfo -d
    HOST RPORT LUN              RPORT PWWN  NAME   VENDOR            MODEL REVISION    STATE
    3    0     0   50:06:04:99:3e:a0:61:36   sdb      DGC           RAID10     0532  running
    3    1     0   50:06:04:97:3e:a0:61:36   sdc      DGC           RAID10     0532  running
    4    0     0   50:06:04:90:44:60:4a:2c   sdh      DGC           RAID10     0429  running
    4    1     0   50:06:04:99:44:60:4a:2c   sdi      DGC           RAID10     0429  running
    5    0     0   50:06:04:90:44:60:4a:2c   sdn      DGC           RAID10     0429  running
    5    1     0   50:06:04:99:44:60:4a:2c   sdo      DGC           RAID10     0429  running
    6    0     0   50:06:04:99:3e:a0:61:36   sdt      DGC           RAID10     0532  running
    6    1     0   50:06:04:97:3e:a0:61:36   sdu      DGC           RAID10     0532  running

kmemstat
--------

Shows kernel slab allocator caches

    # kmemstat
                           CACHE     SIZE
                ext4_inode_cache   87323k
                     buffer_head   33612k
                          dentry   28279k
                 radix_tree_node    8868k
                     inode_cache    5385k
                 sysfs_dir_cache    2299k
                  vm_area_struct    2233k
                proc_inode_cache    2152k
                    kmalloc-2048    1376k
                      kmalloc-64    1372k
                    kmalloc-1024    1184k
    ...

netspeed
--------

Shows network interface utilization report:

    # netspeed
       IFACE       TX       RX
       wlan0      25K     997K
       wwan0       0K       0K
        ppp0       0K       0K
        eth0       0K       0K
          lo       0K       0K

       wlan0     122K     785K
       wwan0       0K       0K
        ppp0       0K       0K
        eth0       0K       0K
          lo       0K       0K
       wlan0      93K     276K
    ...

pmemstat
--------

Shows per-process memory stats including PSS (Proportional Set Size):

    # pmemstat
      PID     SIZE    RSS    PSS   SHR   PRIV  REF  ANON  HUGE  SWAP  LCK      SHM COMMAND
    15356  123116M  2834M  2524M  434M  2399M   0M    0M    0M    0M   0M   81922M oracle
    15360  123129M   290M   117M  269M    21M   0M    0M    0M    0M   0M   81922M oracle
    15366  123127M   257M   103M  238M    18M   0M    0M    0M    0M   0M   81922M oracle
    15362  123128M   239M    95M  222M    16M   0M    0M    0M    0M   0M   81922M oracle
    ...

scout
-----

Collects system runtime and diag data (similar to sosreport and sun explorer).
