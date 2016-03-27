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

# Database Backup at controller node
echo "####################################################"
echo "start to backup mysql"
echo "##########################"
if [ -f /root/backup/openstack.sql ]; then
	rm /root/backup/openstack.sql
fi

if [ ! -f "~/.my.cnf" ]; then
	echo "[mysqldump]
			user=root
			password=conalab
		" >> ~/.my.cnf
	chmod 600 ~/.my.cnf
fi

# if you want to backup a single database, you can instead run: 
# mysqldump --opt --opt nova > openstack_nova.sql
mysqldump --opt --all-databases > /root/backup/openstack.sql
rm ~/.my.cnf

echo "##########################"
echo "finished backup mysql"
echo "####################################################"


echo "####################################################"
echo "start to backup nova"
echo "##########################"

# compute
# /root/backup/nova
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

echo "##########################"
echo "finished backup nova"
echo "####################################################"

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

echo "##########################"
echo "finished backup neutron"
echo "####################################################"

echo "####################################################"
echo "start to backup glance"
echo "##########################"
# image
# /root/backup/glance
if [ ! -d /root/backup/glance ]; then
	mkdir /root/backup/glance
else
	rm -r /root/backup/glance
	mkdir /root/backup/glance
fi
# /root/backup/glance/etc_glance
if [ ! -d /root/backup/glance/etc_glance ]; then
	cp -r /etc/glance /root/backup/glance/etc_glance
else
	rm -r /root/backup/glance/etc_glance
	cp -r /etc/glance /root/backup/glance/etc_glance
fi
# /root/backup/glance/log_glance
if [ ! -d /root/backup/glance/log_glance ]; then
	cp -r /var/log/glance /root/backup/glance/log_glance
else
	rm -r /root/backup/glance/log_glance
	cp -r /var/log/glance /root/backup/glance/log_glance
fi
# /root/backup/glance/lib_glance
if [ ! -d /root/backup/glance/lib_glance ]; then
	cp -r /var/lib/glance /root/backup/glance/lib_glance
else
	rm -r /root/backup/glance/lib_glance
	cp -r /var/lib/glance /root/backup/glance/lib_glance
fi

echo "##########################"
echo "finished backup glance"
echo "####################################################"

echo "####################################################"
echo "start to backup keystone"
echo "##########################"
# identity
# /root/backup/keystone
if [ ! -d /root/backup/keystone ]; then
	mkdir /root/backup/keystone
else
	rm -r /root/backup/keystone
	mkdir /root/backup/keystone
fi

# /root/backup/keystone/etc_keystone
if [ ! -d /root/backup/keystone/etc_keystone ]; then
	cp -r /etc/keystone /root/backup/keystone/etc_keystone
else
	rm -r /root/backup/keystone/etc_keystone
	cp -r /etc/keystone /root/backup/keystone/etc_keystone
fi
# /root/backup/keystone/log_keystone
if [ ! -d /root/backup/keystone/log_keystone ]; then
	cp -r /var/log/keystone /root/backup/keystone/log_keystone
else
	rm -r /root/backup/keystone/log_keystone
	cp -r /var/log/keystone /root/backup/keystone/log_keystone
fi

# /root/backup/keystone/lib_keystone
if [ ! -d /root/backup/keystone/lib_keystone ]; then
	cp -r /var/lib/keystone /root/backup/keystone/lib_keystone
else
	rm -r /root/backup/keystone/lib_keystone
	cp -r /var/lib/keystone /root/backup/keystone/lib_keystone
fi

echo "##########################"
echo "finished backup keystone"
echo "####################################################"

# block storage
#cp /etc/cinder /root/backup/cinder/etc_cinder
#cp /var/log/cinder /root/backup/cinder/log_cinder
#cp /var/lib/cinder /root/backup/cinder/lib_cinder

# echo "####################################################"
# echo "start to backup swift"
# echo "##########################"
# # object storage
# if [ ! -d /root/backup/swift ]; then
# 	mkdir /root/backup/swift
# else
# 	rm -r /root/backup/swift
# 	mkdir /root/backup/swift
# fi
# # /root/backup/swift/etc_swift
# if [ ! -d /root/backup/swift/etc_swift ]; then
# 	cp -r /etc/swift /root/backup/swift/etc_swift
# else
# 	rm -r /root/backup/swift/etc_swift
# 	cp -r /etc/swift /root/backup/swift/etc_swift
# fi
# echo "##########################"
# echo "finished backup swift"
# echo "####################################################"

# tar the folder /root/backup

####################################################
# recovery
####################################################

