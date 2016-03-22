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

echo -n "Enter the compute node management IP"
read cindmgmtip

scp kilocon*.sh root@$conmgmtip:
ssh root@$conmgmtip sh kilocontroller.sh

scp kilocom*.sh root@$compmgmtip:

scp kilcind*.sh root@$cindmgmtip:

ssh conmgmtip sh kilocontroller.sh


