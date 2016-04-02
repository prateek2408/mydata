#!/bin/bash

echo "Openstack Kilo instalation started"

echo -n "Enter the controller node management IP->"
read conmgmtip

echo -n "Enter the network node management IP ->"
read netmgmtip

echo -n "Enter the Compute node management IP ->"
read compmgmtip

echo -n "Enter the Compute node data IP"
read condataip

echo -n "Enter the Network node data  IP"
read netdataip

echo -n "Enter the Network node external IP"
read condataip

echo -n "Enter the cinder node management IP"
read cindmgmtip

echo "
$conmgmtip controller
$netmgmtip network
$compmgmtip compute
$cindmgmtip cinder

" > ~/hostfile
exit


echo "If passwordless Authentication is not enabled please enter the password when prompted"
echo "Starting to deploy openstack kilo on controller node"
scp kilocon*.sh root@$conmgmtip:
ssh root@$conmgmtip sh kilocontroller.sh
