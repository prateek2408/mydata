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

# Backup configuration files and databases taht the varous OpenStack components need to run

echo "####################################################"
echo "start to backup nova"
echo "##########################"

if [ ! -d /root/backup/nova ]; then
	mkdir /root/backup/nova
else
	rm -r /root/backup/nova
	mkdir /root/backup/nova
fi
# /root/backup/nova/etc_nova
if [ ! -d /root/backup/nova/etc_nova ]; then
	cp -r /etc/nova /root/backup/nova/etc_nova
else
	rm -r /root/backup/nova/etc_nova
	cp -r /etc/nova /root/backup/nova/etc_nova
fi
# /root/backup/nova/lib_nova
if [ ! -d /root/backup/nova/lib_nova ]; then
	cp -r /var/lib/nova /root/backup/nova/lib_nova
else
	rm -r /root/backup/nova/lib_nova
	cp -r /var/lib/nova /root/backup/nova/lib_nova
fi
# /root/backup/nova/log_nova
if [ ! -d /root/backup/nova/log_nova ]; then
	cp -r /var/log/nova /root/backup/nova/log_nova
else
	rm -r /root/backup/nova/log_nova
	cp -r /var/log/nova /root/backup/nova/log_nova
fi

echo "####################################################"
echo "start to backup neutron"
echo "##########################"
# /root/backup/neutron
if [ ! -d /root/backup/neutron ]; then
	mkdir /root/backup/neutron
else
	rm -r /root/backup/neutron
	mkdir /root/backup/neutron
fi

# /root/backup/neutron/etc_neutron
if [ ! -d /root/backup/neutron/etc_neutron ]; then
	cp -r /etc/neutron /root/backup/neutron/etc_neutron
else
	rm -r /root/backup/neutron/etc_neutron
	cp -r /etc/neutron /root/backup/neutron/etc_neutron
fi
