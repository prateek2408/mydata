#!/bin/bash
check() {
 while true
 do
  if [ "ACTIVE" == "`nova show $1 | grep status | awk '{print \$4}'`" ]
  then
   echo "VM $1 created and up"
   break;
  elif [ "ERROR" == "`nova show $1 | grep status | awk '{print \$4}'`" ]
  then
   echo "VM $1 failed to Come up"
   break;
  else
   echo "Waiting for VM $1 to come up"
   sleep 2
  fi
 done
}

vmcreate() {
  `nova boot --image $1 --flavor $2 --key-name $3 $4`&>/dev/null
   check $4
}

vmcreate <IMAGE_ID> <FLAVOR> <KEY_NAME> <VM_NAME>
