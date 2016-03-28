if [ $UID != 0 ]
then
 echo "This script only runs with user as root"
 exit
fi



function pins(){
 echo "Installing $@"
 for i in $@
 do
  yum install -y $i &>/dev/null
  if [ $? != 0 ]
  then
   echo "Package installation failed for $i"
   exit
  fi
 done
}


function docker_repo(){
sudo tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/$releasever/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF
}


echo "====Docker and Docker Swarm Installation Script===="

if [ `cat /etc/os-release | grep "CentOS Linux" | wc -l` -gt 1 ]
then
 echo "This Script is compatible with Centos Only"
 yum -y update &>/dev/null
 pins docker-engine
 sudo service docker start
 sudo docker run hello-world
fi

