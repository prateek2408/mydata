#!/bin/bash
# http://docs.openstack.org/openstack-ops/content/backup_and_recovery.html

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "You need to be 'root'." 1>&2
   exit 1
fi

####################################################
# backup
####################################################

#create directory for backup files
if [ ! -d /root/backup ]; then  
	mkdir /root/backup
fi

cp /etc/cinder /root/backup/cinder/etc_cinder
cp /var/log/cinder /root/backup/cinder/log_cinder
cp /var/lib/cinder /root/backup/cinder/lib_cinder

if [ ! -d /root/backup/swift ]; then
        mkdir /root/backup/swift
else
 	rm -r /root/backup/swift
 	mkdir /root/backup/swift
fi

# # /root/backup/swift/etc_swift
if [ ! -d /root/backup/swift/etc_swift ]; then
	cp -r /etc/swift /root/backup/swift/etc_swift
else
	rm -r /root/backup/swift/etc_swift
	cp -r /etc/swift /root/backup/swift/etc_swift
fi

