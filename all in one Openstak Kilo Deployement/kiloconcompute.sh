#!/bin/sh
#################################################################
#Install and configure controller node
#To create the database

mysql -u root -phuawei123 -e "CREATE DATABASE nova"
mysql -u root -phuawei123 -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'huawei123'"
mysql -u root -phuawei123 -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'huawei123'"
#To gain access to admin CLI commands
source /opt/admin-openrc.sh

#To create the service credentials
#create nova user
openstack user create --password huawei123 nova

#Add admin to the nova user
openstack role add --project service --user nova admin

#Creating nova service activity
openstack service create --name nova --description "OpenStack Compute" compute

#Create compute service API endpoints
openstack endpoint create --publicurl http://controller:8774/v2/%\(tenant_id\)s --internalurl http://controller:8774/v2/%\(tenant_id\)s --adminurl http://controller:8774/v2/%\(tenant_id\)s --region RegionOne compute

#To install and configure Compute controller components

yum -y install openstack-nova-api openstack-nova-cert openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler python-novaclient

openstack-config --set /etc/nova/nova.conf database connection mysql://nova:huawei123@controller/nova
openstack-config --set /etc/nova/nova.conf DEFAULT  rpc_backend rabbit
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit  rabbit_host controller
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_userid openstack
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_password huawei123

openstack-config --set /etc/nova/nova.conf DEFAULT auth_strategy keystone

openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_url http://controller:35357
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_plugin password
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_domain_id default
openstack-config --set /etc/nova/nova.conf keystone_authtoken user_domain_id default
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_name service
openstack-config --set /etc/nova/nova.conf keystone_authtoken username nova
openstack-config --set /etc/nova/nova.conf keystone_authtoken password huawei123

openstack-config --set /etc/nova/nova.conf DEFAULT my_ip `cat /etc/hosts | grep controller | awk '{print $1}'`
openstack-config --set /etc/nova/nova.conf DEFAULT vncserver_listen  `cat /etc/hosts | grep controller | awk '{print $1}'`
openstack-config --set /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address `cat /etc/hosts | grep controller | awk '{print $1}'`
openstack-config --set /etc/nova/nova.conf DEFAULT verbose True



openstack-config --set /etc/nova/nova.conf glance host controller
openstack-config --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp


#Populate the Compute database:
su -s /bin/sh -c "nova-manage db sync" nova

systemctl enable openstack-nova-api.service openstack-nova-cert.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
systemctl start openstack-nova-api.service openstack-nova-cert.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
