>/etc/hosts
j=1
for i in `cat temp |awk '{print $1}' |grep 192`
do
 echo "$i slave-$j" >> /etc/hosts
 j=`expr $j + 1`
done
