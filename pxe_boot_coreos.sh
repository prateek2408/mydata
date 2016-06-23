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
 default menu.c32
prompt 0
timeout 30
MENU TITLE unixme.com PXE Menu
LABEL centos7_x64
MENU LABEL CentOS 7 X64
KERNEL /netboot/vmlinuz
APPEND  initrd=/netboot/initrd.img  inst.repo=ftp://$interip/pub  ks=ftp://$interip/pub/ks.cfg
" > /tftpboot/pxelinux.cfg/default
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
yum install -y dhcp tftp tftp-server syslinux wget vsftpd; ctest
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


wget http://ftp.iitm.ac.in/centos/7/isos/x86_64/CentOS-7-x86_64-Minimal-1511.iso
mount CentOS-7-x86_64-Minimal-1511.iso  /var/ftp/pub/

cp /var/ftp/pub/images/pxeboot/vmlinuz /tftpboot/netboot/
cp /var/ftp/pub/images/pxeboot/initrd.img /tftpboot/netboot/

umount /var/ftp/pub/

openssl passwd -1 "000000" $1$w2UlrRDP$rk9zBcY1PP3fUC3Xv6P6i/
ks_file
pxe_menu

chkconfig dhcpd on
chkconfig xinetd on
chkconfig vsftpd on


service vsftpd  restart
service dhcpd restart
service xinetd   restart



echo "=======>>>>>>================"

