#!/bin/bash
basename -a /sys/class/net/* > ipconfigs.txt

while read p; do
  IPTEST=`ip addr show $p | grep "inet\b" | awk '{print $2}' | cut -d/ -f1`
  #echo $IPTEST
  SUB='10.0.0'

if [[ "$IPTEST" =~ .*"$SUB".* ]]; then
  export YOUR_IP=$IPTEST
  echo 'The identified baxter network IP is ' $YOUR_IP
fi
done <ipconfigs.txt

rm ipconfigs.txt
