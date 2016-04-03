#!/bin/bash

echo "Openstack Kilo instalation started"

echo -n "Enter the controller node management IP->"
read conmgmtip

echo -n "Enter the network node management IP ->"
read netmgmtip

echo -n "Enter the Compute node management IP ->"
read compmgmtip

echo -n "Enter the Compute node data IP ->"
read condataip

echo -n "Enter the Network node data  IP ->"
read netdataip

echo -n "Enter the Network node external IP ->"
read condataip

echo -n "Enter the cinder node management IP ->"
read cindmgmtip

echo "
$conmgmtip controller
$netmgmtip network
$compmgmtip compute
$cindmgmtip cinder

" > ~/hostfile


echo "If passwordless Authentication is not enabled please enter the password when prompted"
echo "Starting to deploy openstack kilo on controller node(Key and Glance)"
scp -o StrictHostKeyChecking=no ~/hostfile root@$conmgmtip:/etc/hosts
scp -o StrictHostKeyChecking=no kilocon*.sh root@$conmgmtip:
ssh -o StrictHostKeyChecking=no root@$conmgmtip sh kilocontroller.sh

echo "Starting to deploy openstack kilo on compute node(Nova part)"
scp -o StrictHostKeyChecking=no ~/hostfile root@$compmgmtip:/etc/hosts
scp -o StrictHostKeyChecking=no kilocomp*.sh root@$compmgmtip:
ssh -o StrictHostKeyChecking=noroot @$compmgmtip sh kilocompute.sh

echo "Starting to deploy openstack kilo on controller node(Compute Part)"
ssh -o StrictHostKeyChecking=no root@$conmgmtip sh kiloconcompute.sh
