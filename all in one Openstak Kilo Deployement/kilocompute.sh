#!/bin/sh
#################################################################

#This Function checks the output of a command
check() {
 if [ $? -ne 0 ]
 then
  echo "Command Already executed skipping"
 fi
}

yinstall(){
 echo "INFO: Installing $1"
 if [ "$2" == "ignore" ]
 then
  echo "INFO:: Package Installtion verification skipped for $1"
  yum -y install $1 &>/dev/null
 else
  yum -y install $1 &>/dev/null
  check
 fi
}

#This function Does the service operations
dservice(){
 echo "INFO: Serivce opeation performed systemctl $2 $1"
 systemctl $2 $1
}

echo "Compute Openstack Automatic Installation Started Version:Kilo "
yum update -y &>/dev/null; check
yinstall "vim"
yinstall "screen"
yinstall "net-tools"
yinstall "wget"
#Disable Network Manager
dservice "firewalld" "disable"
dservice "firewalld" "stop"

#Set the hostname of the node to neede
hostnamectl set-hostname compute

Adding contents to storage node and all other nodes
>/etc/hosts
echo "
88.88.88.3  controller
88.88.88.7    storage
88.88.88.5    network
88.88.88.6   compute
"  >> /etc/hosts

#Verify connectivity
ping -c 4 google.com
ping -c 4 controller


#Install NTP
yinstall "ntp"


#Edit the /etc/ntp.conf file:

#server controller iburst

#################
#Start the NTP service
dservice "ntpd" "enable"
sleep 2
dservice "ntpd" "restart"


#################add verification commands ntpq -c assoc peers #########

#Install the necessary yum packages, adjust the repository priority, and update


yum install -y yum-plugin-priorities yum-utils
yum install -y http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
yum install -y http://rdo.fedorapeople.org/openstack-kilo/rdo-release-kilo.rpm
yum upgrade -y
yum install -y openstack-nova-compute sysfsutils openstack-utils
yum install -y openstack-selinux



#Start the NTP service
systemctl enable ntpd.service
systemctl start ntpd.service
#To check the NTP Peer status
ntpq -c peers
ntpq -c assoc

#To install and configure the Compute hypervisor components

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


openstack-config --set /etc/nova/nova.conf DEFAULT my_ip `cat /etc/hosts | grep compute | awk '{print $1}'`

openstack-config --set /etc/nova/nova.conf DEFAULT vncserver_listen 0.0.0.0



openstack-config --set /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address `cat /etc/hosts | grep compute | awk '{print $1}'`
openstack-config --set /etc/nova/nova.conf DEFAULT verbose True
openstack-config --set /etc/nova/nova.conf DEFAULT vnc_enabled True
openstack-config --set /etc/nova/nova.conf DEFAULT novncproxy_base_url http://controller:6080/vnc_auto.html



openstack-config --set /etc/nova/nova.conf glance host controller
openstack-config --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

openstack-config --set /etc/nova/nova.conf libvirt virt_type qemu


#Start the Compute service
systemctl enable libvirtd.service openstack-nova-compute.service
systemctl start libvirtd.service openstack-nova-compute.service

#Verify
openstack-service status nova;