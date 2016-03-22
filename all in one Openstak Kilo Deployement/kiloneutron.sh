#!/bin/sh

#Disable firewalld

systemctl disable firewalld
systemctl stop firewalld

#Set the hostname of the node to neede
hostnamectl set-hostname network
#Adding contents to storage node and all other nodes
echo "
88.88.88.3  controller
88.88.88.7    storage
88.88.88.8    network
88.88.88.6   compute
"  >> /etc/hosts
#Install NTP
yum -y install ntp
#sed -i 's/server 0.centos.pool.ntp.org iburst/#server 0.centos.pool.ntp.org iburst/' /etc/ntp.conf
#sed -i 's/server 1.centos.pool.ntp.org iburst/#server 1.centos.pool.ntp.org iburst/' /etc/ntp.conf
#sed -i 's/server 2.centos.pool.ntp.org iburst/#server 2.centos.pool.ntp.org iburst/' /etc/ntp.conf
#sed -i 's/server 3.centos.pool.ntp.org iburst/#server 3.centos.pool.ntp.org iburst/' /etc/ntp.conf
#sed -i '/#server 3.centos.pool.ntp.org iburst/s/$/\nserver INPUTREQ ibrust/' /etc/ntp.conf
#Start the NTP service
systemctl enable ntpd.service
systemctl start ntpd.service
#To check the NTP Peer status
ntpq -c peers
yum install -y yum-plugin-priorities yum-utils openstack-utils
yum -y install http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
yum -y install http://rdo.fedorapeople.org/openstack-kilo/rdo-release-kilo.rpm;
yum -y upgrade;
yum -y install openstack-selinux;

sysctl -p
echo "
net.ipv4.ip_forward=1
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
" > /etc/sysctl.conf
yum -y install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch;


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


###Ml2 driver configuration

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,gre,vxlan
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types gre
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch



openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_gre tunnel_id_ranges 1:1000

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver

###Note: Replace the IP Address with network node ip Address

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs local_ip 10.172.10.153
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs bridge_mappings external:br-ex

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini agent tunnel_types gre


####To configure the Layer-3 (L3) agent

openstack-config --set /etc/neutron/l3_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver

openstack-config --set /etc/neutron/l3_agent.ini DEFAULT external_network_bridge


openstack-config --set /etc/neutron/l3_agent.ini DEFAULT router_delete_namespaces True
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT verbose True

##To configure the DHCP agent
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_delete_namespaces True


###verify  dhcp MTU
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT dnsmasq_config_file  /etc/neutron/dnsmasq-neutron.conf

echo "
dhcp-option-force=26,1454
"> /etc/neutron/dnsmasq-neutron.conf



####To configure the metadata agent

openstack-config --set /etc/neutron/metadata_agent.ini keystone_authtoken auth_uri http://controller:5000

openstack-config --set /etc/neutron/metadata_agent.ini keystone_authtoken auth_url http://controller:35357
openstack-config --set /etc/neutron/metadata_agent.ini keystone_authtoken auth_plugin password
openstack-config --set /etc/neutron/metadata_agent.ini keystone_authtoken project_domain_id default
openstack-config --set /etc/neutron/metadata_agent.ini keystone_authtoken user_domain_id default
openstack-config --set /etc/neutron/metadata_agent.ini keystone_authtoken project_name service
openstack-config --set /etc/neutron/metadata_agent.ini keystone_authtoken username neutron
openstack-config --set /etc/neutron/metadata_agent.ini keystone_authtoken password huawei123

openstack-config --set /etc/neutron/metadata_agent.ini nova_metadata_ip controller

openstack-config --set /etc/neutron/metadata_agent.ini metadata_proxy_shared_secret huawei123

openstack-config --set /etc/neutron/metadata_agent.ini verbose True


systemctl enable openvswitch.service
systemctl start openvswitch.service

ovs-vsctl add-br br-ex



echo "DEVICE=br-ex
DEVICETYPE=ovs
TYPE=OVSBridge
BOOTPROTO=static
IPADDR=77.77.77.6
NETMASK=255.255.255.0
DNS1=8.8.8.8
ONBOOT=yes
" >> /etc/sysconfig/network-scripts/ifcfg-br-ex
ovs-vsctl add-port br-ex eth1
ifconfig eth1 0.0.0.0 up
ifdown br-ex
ifup br-ex


ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
cp /usr/lib/systemd/system/neutron-openvswitch-agent.service \
/usr/lib/systemd/system/neutron-openvswitch-agent.service.orig
sed -i 's,plugins/openvswitch/ovs_neutron_plugin.ini,plugin.ini,g' /usr/lib/systemd/system/neutron-openvswitch-agent.service
systemctl enable neutron-openvswitch-agent.service neutron-l3-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service neutron-ovs-cleanup.service
systemctl start neutron-openvswitch-agent.service neutron-l3-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service


