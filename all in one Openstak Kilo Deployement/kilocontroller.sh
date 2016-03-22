#!/bin/sh -i

#This Function checks the output of a command
check() {
 if [ $? -ne 0 ]
 then
  echo "Command Already executed skipping"
 fi
}


#This function Does the service operations
dservice(){
 echo "INFO: Serivce opeation performed systemctl $2 $1"
 systemctl $2 $1
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

#This function inserts values in file
finsert(){
  grep "$1" "$2" "$3"
  if [ $? -ne 0 ]
  then
    sed -i '/\[$3\]/s/$/\n$1/' $2
  else
    echo "Variable already in file Ignoring"
  fi
}

echo "Controller Openstack Automatic Installation Started Version:Kilo "
yum update -y &>/dev/null; check
yinstall "vim"
yinstall "screen"
yinstall "net-tools"
yinstall "wget"
#Disable Network Manager
#dservice "firewalld" "disable"
#dservice "firewalld" "stop"

#Set the hostname of the node to neede
hostnamectl set-hostname controller

#Adding contents to storage node and all other nodes
>/etc/hosts
echo "
88.88.88.3  controller
88.88.88.7    storage
88.88.88.5    network
88.88.88.6   compute
"  >> /etc/hosts

#Install NTP
yinstall "ntp"
#Start the NTP service
dservice "ntpd" "enable"
sleep 2
dservice "ntpd" "restart"

#To check the NTP Peer status
ntpq -c peers &>/dev/null; check
yinstall "http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm" "ignore"
yinstall "http://rdo.fedorapeople.org/openstack-kilo/rdo-release-kilo.rpm" "ignore"
yum -y upgrade -y &>/dev/null; check
yinstall "openstack-selinux"

#Database
yinstall "mariadb"
yinstall "mariadb-server"
yinstall "MySQL-python"

echo "
[mysqld]
bind-address = 0.0.0.0
[mysqld]
default-storage-engine = innodb
innodb_file_per_table
collation-server = utf8_general_ci
init-connect = 'SET NAMES utf8'
character-set-server = utf8
" > /etc/my.cnf.d/mariadb_openstack.cnf

dservice "mariadb" "enable"
sleep 2
dservice "mariadb" "restart"

# Make sure that NOBODY can access the server without a password
mysql -e "UPDATE mysql.user SET Password = PASSWORD('huawei123') WHERE User = 'root'"
# Kill the anonymous users
mysql -e "DROP USER ''@'localhost'"
# Because our hostname varies we'll use some Bash magic here.
mysql -e "DROP USER ''@'$(hostname)'"
# Kill off the demo database
mysql -e "DROP DATABASE test"
# Make our changes take effect
mysql -e "FLUSH PRIVILEGES"
# Any subsequent tries to run queries this way will get access denied because lack of usr/pwd param
echo "
SELINUX=disabled
SELINUXTYPE=minimum
" > /etc/selinux/config
# RabbitMQ
yinstall "rabbitmq-server"
dservice "rabbitmq-server" "enable"
sleep 2
dservice "rabbitmq-server" "restart"
rabbitmqctl add_user openstack guest
rabbitmqctl change_password openstack huawei123
rabbitmqctl set_permissions openstack ".*" ".*" ".*"


#Keystone Installation
mysql -u root -phuawei123 -e "CREATE DATABASE keystone"
mysql -u root -phuawei123 -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'huawei123'"
mysql -u root -phuawei123 -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'huawei123'"

#naga=$(openssl rand -hex 10 | tee sslbackupfile)
#echo "$naga"
yinstall "openstack-keystone"
yinstall "httpd"
yinstall " mod_wsgi"
yinstall "python-openstackclient"
yinstall "memcached"
yinstall "python-memcached"
yinstall "openstack-utils"
dservice "memcached" "enable"
sleep 2
dservice "memcached" "restart"

#finsert "connection = mysql:\/\/keystone:huawei123@controller\/keystone/" "/etc/keystone/keystone.conf" "database"
#sed -i '/\[database\]/s/$/\nconnection = mysql:\/\/keystone:huawei123@controller\/keystone/' /etc/keystone/keystone.conf

openstack-config --set /etc/keystone/keystone.conf DEFAULT  admin_token  huawei123
openstack-config --set /etc/keystone/keystone.conf database connection  mysql://keystone:huawei123@controller/keystone

#sed -i '/\[DEFAULT\]/s/$/\nadmin_token = huawei123 \nverbose = True/' /etc/keystone/keystone.conf

openstack-config --set /etc/keystone/keystone.conf DEFAULT verbose True
#sed -i '/\[memcache\]/s/$/\nservers = localhost:11211/' /etc/keystone/keystone.conf

openstack-config --set /etc/keystone/keystone.conf memcache servers localhost:11211

openstack-config --set /etc/keystone/keystone.conf token provider keystone.token.providers.uuid.Provider
openstack-config --set /etc/keystone/keystone.conf token driver  keystone.token.persistence.backends.memcache.Token
openstack-config --set /etc/keystone/keystone.conf revoke driver keystone.contrib.revoke.backends.sql.Revoke

#sed -i '/\[token\]/s/$/\nprovider = keystone.token.providers.uuid.Provider \ndriver = keystone.token.persistence.backends.memcache.Token/' /etc/keystone/keystone.conf
#sed -i '/\[revoke\]/s/$/\ndriver = keystone.contrib.revoke.backends.sql.Revoke/' /etc/keystone/keystone.conf

su -s /bin/sh -c "keystone-manage db_sync" keystone
##################check##########
sed -i '/s/ServerRoot "/etc/httpd"/\n ServerName controller/' /etc/httpd/conf/httpd.conf

echo "
Listen 5000
Listen 35357

<VirtualHost *:5000>
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-public
    WSGIScriptAlias / /var/www/cgi-bin/keystone/main
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    LogLevel info
    ErrorLog /var/log/httpd/keystone-error.log
    CustomLog /var/log/httpd/keystone-access.log combined
</VirtualHost>

<VirtualHost *:35357>
    WSGIDaemonProcess keystone-admin processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-admin
    WSGIScriptAlias / /var/www/cgi-bin/keystone/admin
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    LogLevel info
    ErrorLog /var/log/httpd/keystone-error.log
    CustomLog /var/log/httpd/keystone-access.log combined
</VirtualHost>
" > /etc/httpd/conf.d/wsgi-keystone.conf

mkdir -p /var/www/cgi-bin/keystone
curl http://git.openstack.org/cgit/openstack/keystone/plain/httpd/keystone.py?h=stable/kilo -o /var/www/cgi-bin/keystone/main
curl http://git.openstack.org/cgit/openstack/keystone/plain/httpd/keystone.py?h=stable/kilo -o /var/www/cgi-bin/keystone/admin

chown -R keystone:keystone /var/www/cgi-bin/keystone
chmod 755 /var/www/cgi-bin/keystone/*i

dservice "httpd" "enable"
sleep 2
dservice "httpd" "restart"

#Create the service entity and API endpoint
#Configure the authentication token:
#export OS_TOKEN=ADMIN_TOKEN
export OS_TOKEN=huawei123
export OS_URL=http://controller:35357/v2.0







openstack service create --name keystone --description "OpenStack Identity" identity; check
openstack endpoint create --publicurl http://controller:5000/v2.0 --internalurl http://controller:5000/v2.0 --adminurl http://controller:35357/v2.0 --region RegionOne identity

#Create projects, users, and roles
openstack project create --description "Admin Project" admin; check
openstack user create --password huawei123 admin; check
openstack role create admin; check
openstack role add --project admin --user admin admin; check
openstack project create --description "Service Project" service; check
openstack project create --description "Demo Project" demo; check
openstack user create --password huawei123 demo; check
openstack role create user; check
openstack role add --project demo --user demo user; check
#Unset the temporary OS_TOKEN and OS_URL environment variables:
unset OS_TOKEN OS_URL
openstack --os-auth-url http://controller:35357 --os-project-name admin --os-username admin --os-auth-type password  --os-password huawei123 token issue; check
openstack --os-auth-url http://controller:35357 --os-project-name admin --os-username admin --os-auth-type password  --os-password huawei123 project list; check
openstack --os-auth-url http://controller:35357 --os-project-name admin --os-username admin --os-auth-type password  --os-password huawei123 user list; check
openstack --os-auth-url http://controller:35357 --os-project-name admin --os-username admin --os-auth-type password  --os-password huawei123 role list; check

# Create OpenStack client environment scripts
mkdir -p opt
echo "
export OS_PROJECT_DOMAIN_ID=default
export OS_USER_DOMAIN_ID=default
export OS_PROJECT_NAME=admin
export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=huawei123
export OS_AUTH_URL=http://controller:35357/v3
" >/opt/admin-openrc.sh

echo "
export OS_PROJECT_DOMAIN_ID=default
export OS_USER_DOMAIN_ID=default
export OS_PROJECT_NAME=demo
export OS_TENANT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=huawei123
export OS_AUTH_URL=http://controller:5000/v3
" >/opt/demo-openrc.sh

#To load client environment scripts
source /opt/admin-openrc.sh
openstack token issue


#Install and config Image service
mysql -u root -phuawei123 -e "CREATE DATABASE glance"
mysql -u root -phuawei123 -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'huawei123'"
mysql -u root -phuawei123 -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'huawei123'"

source /opt/admin-openrc.sh
openstack user create --password huawei123 glance; check
openstack role add --project service --user glance admin; check
openstack service create --name glance --description "OpenStack Image service" image; check
openstack endpoint create --publicurl http://controller:9292 --internalurl http://controller:9292 --adminurl http://controller:9292 --region RegionOne image; check

#To install and configure the Image service components
yinstall "openstack-glance"
yinstall "python-glance"
yinstall "python-glanceclient"



openstack-config --set /etc/glance/glance-api.conf database connection mysql://glance:huawei123@controller/glance
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken  auth_uri http://controller:5000
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_url http://controller:35357
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_plugin password
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken project_domain_id default
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken user_domain_id default
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken project_name service
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken username glance
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken password huawei123

openstack-config --set /etc/glance/glance-api.conf paste_deploy flavor keystone

openstack-config --set /etc/glance/glance-api.conf glance_store default_store file

openstack-config --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images/


openstack-config --set /etc/glance/glance-api.conf DEFAULT verbose True


openstack-config --set /etc/glance/glance-registry.conf database connection mysql://glance:huawei123@controller/glance
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken  auth_uri http://controller:5000
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_url http://controller:35357
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_plugin password
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken project_domain_id default
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken user_domain_id default
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken project_name service
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken username glance
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken password huawei123

openstack-config --set /etc/glance/glance-registry.conf paste_deploy flavor keystone


openstack-config --set /etc/glance/glance-registry.conf DEFAULT verbose True



su -s /bin/sh -c "glance-manage db_sync" glance

dservice "openstack-glance-api" "enable"
dservice "openstack-glance-registry" "enable"
sleep 2
dservice "openstack-glance-api" "restart"
dservice "openstack-glance-registry" "restart"

##verify operation
echo "export OS_IMAGE_API_VERSION=2" | tee -a /opt/admin-openrc.sh /opt/demo-openrc.sh
source /opt/admin-openrc.sh
mkdir /tmp/images
wget -P /tmp/images http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
glance image-create --name "cirros-0.3.4-x86_64" --file /tmp/images/cirros-0.3.4-x86_64-disk.img --disk-format qcow2 --container-format bare --visibility public --progress
glance image-list
rm -r /tmp/images

yinstall openstack-dashboard
yinstall httpd mod_wsgi
yinstall memcached
yinstall python-memcached
##Make sure you have local_settings file in the current directory of the script
cp local_settings /etc/openstack-dashboard/local_settings
setsebool -P httpd_can_network_connect on;
chown -R apache:apache /usr/share/openstack-dashboard/static;
systemctl enable httpd.service memcached.service;
systemctl restart httpd.service memcached.service;
