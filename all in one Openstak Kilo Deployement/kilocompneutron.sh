#!/bin/sh

#Disable firewalld

systemctl disable firewalld
systemctl stop firewalld

echo "
net.ipv4.ip_forward=1
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
" > /etc/sysctl.conf
sysctl -p
yum install -y openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch
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
openstack-config --set /etc/neutron/neutron.conf DEFAULT verbose True



#Ml2 driver configuration

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,gre,vxlan
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types gre
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch



openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_gre tunnel_id_ranges 1:1000

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver

#Note : Replace the ip address with compute host ip address
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs local_ip 88.88.88.6

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini agent tunnel_types gre

systemctl enable openvswitch.service
systemctl start openvswitch.service

#To configure Compute to use Networking

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

ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

 cp /usr/lib/systemd/system/neutron-openvswitch-agent.service  /usr/lib/systemd/system/neutron-openvswitch-agent.service.orig

sed -i 's,plugins/openvswitch/ovs_neutron_plugin.ini,plugin.ini,g'  /usr/lib/systemd/system/neutron-openvswitch-agent.service


systemctl restart openstack-nova-compute.service

 systemctl enable neutron-openvswitch-agent.service
 systemctl start neutron-openvswitch-agent.service
