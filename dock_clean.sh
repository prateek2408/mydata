#!/bin/sh


docker_clear()
{
 con_cnt=`docker ps -a | grep -i $1 | grep -v "CONTAINER" | wc -l`
 if [ $con_cnt -gt 0 ]
 then
  docker ps -a | grep -i $1  | awk '{print $1 }' | xargs docker rm -f
 else
  echo "Not cleaning as no $1 container's found"
 fi
}

kube_clean()
{
 ns_cnt=`kubectl get namespaces | grep -v default |grep -v kube |grep -v NAME  | awk '{print $1}' | wc -l`
 if [ $ns_cnt -gt 0 ]
 then
  kubectl get namespaces | grep -v default |grep -v kube |grep -v NAME  | awk '{print $1}' | xargs kubectl delete namespace
 else
  echo "No namespaces found apart from default ones"
 fi
}

echo "-------------Checking for exsistance of docker on the system-------------"
docker_present=`which docker | wc -l`
if [ $docker_present -gt 0 ]
then
 echo "Docker found proceeding with clean"
else
 echo "I cannot see docker here sorry, time to go"
 exit
fi

echo "-------------Cleaning Exited containers-------------------"
docker_clear 'exit'

echo "-------------Cleaning created containers but not up-------"
docker_clear 'created'

echo "-------------Cleaning Kubernetes namespaces------------------------------"
kube_clean
