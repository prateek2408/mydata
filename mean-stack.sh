#!/bin/sh
install()
{
 for i in $@
 do
  apt-get install -y $i
 done
}

install_docker()
{
 wget -qO- https://get.docker.com/ | sh
 usermod -aG docker $(whoami)
}

install_mongo()
{
 apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
 echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list
 apt-get update
 apt-get install -y mongodb-org
 if [ $# -gt 0 ]
 then
  echo "
[Unit]
Description=High-performance, schema-free document-oriented database
After=network.target
Documentation=https://docs.mongodb.org/manual

[Service]
User=mongodb
Group=mongodb
ExecStart=/usr/bin/mongod --quiet --auth --config /etc/mongod.conf

[Install]
WantedBy=multi-user.target
 " > /lib/systemd/system/mongod.service
 else
  echo "
[Unit]
Description=High-performance, schema-free document-oriented database
After=network.target
Documentation=https://docs.mongodb.org/manual

[Service]
User=mongodb
Group=mongodb
ExecStart=/usr/bin/mongod --quiet --config /etc/mongod.conf

[Install]
WantedBy=multi-user.target
 " > /lib/systemd/system/mongod.service
 fi
 systemctl daemon-reload
 systemctl start mongod
 systemctl enable mongod
}

install_nodejs()
{
 curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
 apt-get install -y nodejs
 apt-get install build-essential
}

configure_mongo()
{
 mongo --eval 'db.createUser({user:"admin", pwd:"admin123", roles:[{role:"root", db:"admin"}]})'
 install_mongo admin
}

ap-get update
install git ruby build-essential python-pip
install_docker
docker run -d -p 8081:8081 --name nexus -e JAVA_MAX_HEAP=1500m sonatype/nexus3
install_nodejs
install_mongo
configure_mongo
