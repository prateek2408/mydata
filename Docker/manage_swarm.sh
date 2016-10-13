for i in `cat /etc/hosts | head -7 | awk '{print $1}'`
do
 #ssh -i temp.pem ubuntu@$i sudo rm -rf /var/lib/docker/network
 #ssh -i temp.pem ubuntu@$i sudo rm -f /etc/docker/key.json
 #ssh -i temp.pem ubuntu@$i sudo service docker status
 #scp -i temp.pem /etc/default/docker ubuntu@$i:
 #ssh -i temp.pem ubuntu@$i sudo cp ./docker  /etc/default/docker
 #ssh -i temp.pem ubuntu@$i sudo cat /etc/default/docker
 #read abc
 #telnet $i 2375
 #scp -i temp.pem /etc/resolv.conf ubuntu@$i:
 #ssh -i temp.pem ubuntu@$i sudo cp ./resolv.conf /etc/resolv.conf
 #ssh -i temp.pem ubuntu@$i sudo ping -c 4 google.com
 ssh -i temp.pem ubuntu@$i sudo docker run -d swarm join --advertise=$i:2375 consul://192.168.2.119:8500
 #echo $i
 #for j in `ssh -i temp.pem ubuntu@$i sudo docker ps -a|grep swarm|head -1`
 #do
 # ssh -i temp.pem ubuntu@$i sudo docker rm -f $j
 #done
 ssh -i temp.pem ubuntu@$i sudo docker ps -a
done
