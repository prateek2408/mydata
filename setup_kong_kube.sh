#!/bin/sh
echo "---> Installing Docker"
wget http://get.docker.com
sh index.html
rm -rf index.html

echo "---> Installing Kubeadm"
apt-get update && apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm

echo "---> Install Kubeadm complete"
echo "---> Setup kubeadm"
kubeadm init
export KUBECONFIG=/etc/kubernetes/admin.conf 
kubectl taint nodes --all node-role.kubernetes.io/master-
echo "---> Kubeadm completed with master node tainted"

echo "Setting up Weave network"
export kubever=$(kubectl version | base64 | tr -d '\n')
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$kubever"
sleep 120 

echo "Setting up Kong HTTP Api Gateway"
git clone https://github.com/Mashape/kong-dist-kubernetes.git
cd kong-dist-kubernetes/
kubectl create -f postgres.yaml
sleep 50
kubectl create -f kong_migration_postgres.yaml
sleep 50
kubectl create -f kong_postgres.yaml
sleep 50

echo "KUBECONFIG=/etc/kubernetes/admin.conf" >> /etc/environment
