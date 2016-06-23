#!/bin/sh



ctest() {
 if [ $? -ne 0 ]
 then
  echo "Command has failed, Shutting down"
 fi
}

dhcpd_conf() {
 echo "
ddns-update-style interim;
ignore client-updates;
authoritative;
allow booting;
allow bootp;
allow unknown-clients;
# A slightly different configuration for an internal subnet.
subnet $sub netmask $intermask {
range $Rstart $Rstop;
option domain-name-servers $interip;
option domain-name \"server1.example.com\";
option routers $interip;
option broadcast-address 10.5.5.31; #not important
default-lease-time 600;
max-lease-time 7200;
# PXE SERVER IP
next-server $interip; #  DHCP server ip
filename \"pxelinux.0\";
}" > /etc/dhcp/dhcpd.conf
}

tftp_conf() {
 echo "
service tftp
{
socket_type             = dgram
protocol                = udp
wait                    = yes
user                    = root
server                  = /usr/sbin/in.tftpd
server_args             = -s /tftpboot
disable                 = no
per_source              = 11
cps                     = 100 2
flags                   = IPv4
}
" > /etc/xinetd.d/tftp
}

ks_file() {
 echo "
#platform=x86, AMD64, or Intel EM64T
#version=DEVEL
# Firewall configuration
firewall --disabled
# Install OS instead of upgrade
install
# Use NFS installation media
url --url="ftp://$interip/pub/"
# Root password [i used here 000000]
rootpw --iscrypted $1$xYUugTf4$4aDhjs0XfqZ3xUqAg7fH3.
# System authorization information
auth  useshadow  passalgo=sha512
# Use graphical install
graphical
firstboot disable
# System keyboard
keyboard us
# System language
lang en_US
# SELinux configuration
selinux disabled
# Installation logging level
logging level=info
# System timezone
timezone Europe/Amsterdam
# System bootloader configuration
bootloader location=mbr
clearpart --all --initlabel
part swap --asprimary --fstype="swap" --size=1024
part /boot --fstype xfs --size=200
part pv.01 --size=1 --grow
volgroup rootvg01 pv.01
logvol / --fstype xfs --name=lv01 --vgname=rootvg01 --size=1 --grow
%packages
@core
wget
net-tools
%end
%post
%end
" > /var/ftp/pub/ks.cfg
}

pxe_menu() {
echo "
default coreos
prompt 1
timeout 15

display boot.msg

label coreos
  menu default
  kernel coreos_production_pxe.vmlinuz
  append initrd=coreos_production_pxe_image.cpio.gz cloud-config-url=http://$interip/pxe-cloud-config.yml
" > /tftpboot/pxelinux.cfg/default
}

cloud_yaml() {
 echo "
 #cloud-config
coreos:
  units:
    - name: etcd2.service
      command: start
    - name: fleet.service
      command: start
ssh_authorized_keys:
  - ssh-rsa 
 " > /var/www/html/pxe-cloud-config.yml
}

echo "=======>>>>>>================"
echo "A PXE server allows your client computers to boot and install a Linux distribution over the network, without the need of burning Linux iso images, or human interaction"

echo "Please fill the following"
echo "Interface name on which DHCP server will run ->"
read intername
echo "Enter the Subnet of the network"
read sub
echo "Enter the start subnet range"
read Rstart
echo "Enter the stop subnet range"
read Rstop

interip=`ifconfig $intername | grep -w  inet  | awk '{print $2}'`
intermask=`ifconfig $intername | grep -w  inet  | awk '{print $4}'`

echo "Installation has started"
yum install -y dhcp tftp tftp-server syslinux wget vsftpd httpd; ctest
dhcpd_conf
tftp_conf


mkdir -p /tftpboot
chmod 777 /tftpboot
cp -v /usr/share/syslinux/pxelinux.0 /tftpboot
cp -v /usr/share/syslinux/menu.c32 /tftpboot
cp -v /usr/share/syslinux/memdisk /tftpboot
cp -v /usr/share/syslinux/mboot.c32 /tftpboot
cp -v /usr/share/syslinux/chain.c32 /tftpboot

mkdir /tftpboot/pxelinux.cfg
mkdir -p /tftpboot/netboot/

cd /tftpboot/netboot/

wget https://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz
wget https://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz.sig
wget https://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe_image.cpio.gz
wget https://stable.release.core-os.net/amd64-usr/current/coreos_production_pxe_image.cpio.gz.sig
gpg --verify coreos_production_pxe.vmlinuz.sig
gpg --verify coreos_production_pxe_image.cpio.gz.sig

openssl passwd -1 "000000" $1$w2UlrRDP$rk9zBcY1PP3fUC3Xv6P6i/
ks_file
pxe_menu

chkconfig dhcpd on
chkconfig xinetd on
chkconfig vsftpd on
cloud_yaml

service vsftpd  restart
service dhcpd restart
service xinetd   restart



echo "=======>>>>>>================"

