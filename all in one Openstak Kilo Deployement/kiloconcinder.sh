#!/bin/sh
# Install and Configure Block storage on Compute Node

mysql -u root -phuawei123 -e "CREATE DATABASE cinder"
mysql -u root -phuawei123 -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY 'huawei123'"
mysql -u root -phuawei123 -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY 'huawei123'"

#Source the Admin Credentials
source /opt/admin-openrc.sh
# Create Cinder user
openstack user create --password huawei123 cinder
# Add the Admin Role to Cinder User
openstack role add --project service --user cinder admin
#Create Cinder Service for API version 1
openstack service create --name cinder --description "OpenStack Block Storage" volume
#Create Cinder Service for API version 2
openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2
#Block Storage Service for API Version 1
openstack endpoint create --publicurl http://controller:8776/v2/%\(tenant_id\)s --internalurl http://controller:8776/v2/%\(tenant_id\)s --adminurl http://controller:8776/v2/%\(tenant_id\)s --region RegionOne volume
#Block Storage Service for API Version 2
openstack endpoint create --publicurl http://controller:8776/v2/%\(tenant_id\)s --internalurl http://controller:8776/v2/%\(tenant_id\)s --adminurl http://controller:8776/v2/%\(tenant_id\)s --region RegionOne volumev2
#Install the packages
yum -y install openstack-cinder python-cinderclient python-oslo-db
#Copy the /usr/share/cinder/cinder-dist.conf file to /etc/cinder/cinder.conf
cp /usr/share/cinder/cinder-dist.conf /etc/cinder/cinder.conf
chown -R cinder:cinder /etc/cinder/cinder.conf

openstack-config --set /etc/cinder/cinder.conf database connection mysql://cinder:huawei123@controller/cinder

openstack-config --set /etc/cinder/cinder.conf DEFAULT rpc_backend rabbit

openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_host controller
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_userid openstack
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_password huawei123


openstack-config --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/cinder/cinder.conf DEFAULT my_ip `cat /etc/hosts | grep controller | awk '{print $1}'`
openstack-config --set /etc/cinder/cinder.conf DEFAULT verbose True


openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_url http://controller:35357
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_plugin password
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken project_domain_id default
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken user_domain_id default
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken project_name service
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken username cinder
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken password huawei123

openstack-config --set /etc/cinder/cinder.conf  oslo_concurrency lock_path /var/lock/cinder


#Populate the Block Storage database
su -s /bin/sh -c "cinder-manage db sync" cinder

#Start the Block Storage services
systemctl enable openstack-cinder-api.service openstack-cinder-scheduler.service
systemctl start openstack-cinder-api.service openstack-cinder-scheduler.service
