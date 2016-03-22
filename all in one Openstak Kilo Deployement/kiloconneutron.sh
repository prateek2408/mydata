#!/bin/sh


yum -y install openstack-selinux

mysql -u root -phuawei123 -e "CREATE DATABASE neutron";

mysql -u root -phuawei123 -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'huawei123'" ;
mysql -u root -phuawei123 -e  "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'huawei123' ";

source /opt/admin-openrc.sh
openstack user create  --password huawei123 neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "OpenStack Networking" network
openstack endpoint create  --publicurl http://controller:9696  --adminurl http://controller:9696  --internalurl http://controller:9696 --region RegionOne network
yum install -y openstack-neutron openstack-neutron-ml2 python-neutronclient which ;

openstack-config --set /etc/neutron/neutron.conf database connection mysql://neutron:huawei123@controller/neutron

openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend rabbit


openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_host controller
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_userid openstack
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_password huawei123


openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone

openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://controller:5000

openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://controller:35357
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_plugin password
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_domain_id default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken user_domain_id default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_name service
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken username neutron
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken password huawei123
openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins router
openstack-config --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips True

openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True
openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_url http://controller:8774/v2

openstack-config --set /etc/neutron/neutron.conf nova auth_url http://controller:35357
openstack-config --set /etc/neutron/neutron.conf nova auth_plugin password
openstack-config --set /etc/neutron/neutron.conf nova project_domain_id default
openstack-config --set /etc/neutron/neutron.conf nova user_domain_id default
openstack-config --set /etc/neutron/neutron.conf nova region_name RegionOne
openstack-config --set /etc/neutron/neutron.conf nova project_name service
openstack-config --set /etc/neutron/neutron.conf nova username nova
openstack-config --set /etc/neutron/neutron.conf nova password huawei123


openstack-config --set /etc/neutron/neutron.conf DEFAULT verbose True

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,gre,vxlan
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types gre
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch



openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_gre tunnel_id_ranges 1:1000

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver

#To configure compute to use nova

openstack-config --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API


openstack-config --set /etc/nova/nova.conf DEFAULT security_group_api neutron

openstack-config --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver

openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver


openstack-config --set /etc/nova/nova.conf neutron url http://controller:9696

openstack-config --set /etc/nova/nova.conf neutron auth_strategy keystone
openstack-config --set /etc/nova/nova.conf neutron admin_auth_url http://controller:35357/v2.0
openstack-config --set /etc/nova/nova.conf neutron admin_tenant_name service
openstack-config --set /etc/nova/nova.conf neutron admin_username neutron
openstack-config --set /etc/nova/nova.conf neutron admin_password huawei123

##############verify 2 commands #####
openstack-config --set /etc/nova/nova.conf neutron service_metadata_proxy True
openstack-config --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret password

ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini;

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron ;
systemctl restart openstack-nova-api.service openstack-nova-scheduler.service \
    openstack-nova-conductor.service ;
systemctl enable neutron-server.service;
systemctl start neutron-server.service

