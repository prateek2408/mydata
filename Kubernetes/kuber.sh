if [ $UID != 0 ]
then
 echo "This script only runs with user as root"
 exit
fi

if [ `cat /etc/os-release | grep "CentOS Linux" | wc -l` -gt 1 ]
then
 echo "This Script is compatible with Ubuntu Only"
 exit
fi

function pins(){
 echo "Installing $1"
 for i in $@
 do
  apt-get install -y $i &>/dev/null
  if [ $? != 0 ]
  then
   echo "Package installation failed for $i"
   exit
  fi
 done
}

function clonekuber(){
 mkdir ~/Kubernetes
 cd ~/Kubernetes
 git clone https://github.com/kubernetes/kubernetes.git
 cd kubernetes
 git checkout v1.0.1
 cd cluster/ubuntu
 ./build.sh
}
echo "====Kubernetes Installation Script===="
echo -n "Tell me the username of the kubernate cluter minion ->"
read kubclusUser
echo -n "Tell me the IP of the kubernate cluter minion ->"
read kubclusIp


apt-get update &>/dev/null
pins zip unzip tree git
clonekuber
sed 's/vcap@10.10.103.250 vcap@10.10.103.162 vcap@10.10.103.223/'$kubclusUser'@'$kubclusIp'/' ~/Kubernetes/kubernetes/cluster/ubuntu/config-default.sh >~/ana
mv ~/ana ~/Kubernetes/kubernetes/cluster/ubuntu/config-default.sh
