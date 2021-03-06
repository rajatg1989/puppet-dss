#!/bin/bash
# Copied from upstream logrotate
# Upstream source at https://github.com/ceph/ceph/blob/master/src/logrotate.conf
service rsyslog restart
if which invoke-rc.d > /dev/null 2>&1 && [ -x `which invoke-rc.d` ]; then
    invoke-rc.d ceph reload >/dev/null
elif which service > /dev/null 2>&1 && [ -x `which service` ]; then
    service ceph reload >/dev/null
fi
# Possibly reload twice, but depending on ceph.conf the reload above may be a no-op
if which initctl > /dev/null 2>&1 && [ -x `which initctl` ]; then
    for daemon in osd mon mds ; do
      find -L /var/lib/ceph/$daemon/ -mindepth 1 -maxdepth 1 -regextype posix-egrep -regex '.*/[A-Za-z0-9]+-[A-Za-z0-9._-]+' -printf '%P\n' \
        | while read f; do
            if [ -e "/var/lib/ceph/$daemon/$f/done" -o -e "/var/lib/ceph/$daemon/$f/ready" ] && [ -e "/var/lib/ceph/$daemon/$f/upstart" ] && [ ! -e "/var/lib/ceph/$daemon/$f/sysvinit" ]; then
              cluster="${f%%-*}"
              id="${f#*-}"

              initctl reload ceph-$daemon cluster="$cluster" id="$id" 2>/dev/null || :
            fi
          done
    done
fi

python /usr/local/bin/dump-logs.py
