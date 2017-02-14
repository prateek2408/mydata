if [ "$1" = "image" ] || [ "$1" = "all" ]
then
 service glance-api $2
 service glance-registry $2
fi

if [ "$1" = "compute" ] || [ "$1" = "all" ]
then 
 service nova-api $2
 service nova-consoleauth $2
 service nova-scheduler $2
 service nova-conductor $2
 service nova-novncproxy $2
fi

if [ "$1" = "network" ] || [ "$1" = "all" ]
then
 service neutron-server $2
 service neutron-openvswitch-agent $2
 service neutron-dhcp-agent $2
 service neutron-metadata-agent $2
 service neutron-l3-agent $2
 service neutron-lbaas-agent $2
fi


if [ "$1" = "volume" ] || [ "$1" = "all" ]
then
  service cinder-scheduler $2
  service cinder-api $2
  service cinder-volume $2
  service tgt $2
fi

if [ "$1" = "heat" ] || [ "$1" = "all" ]
then
 service heat-api $2
 service heat-api-cfn $2
 service heat-engine $2
fi

if [ "$1" = "container" ] || [ "$1" = "all" ]
then
 service magnum-api $2
 service magnum-conductor $2
fi


