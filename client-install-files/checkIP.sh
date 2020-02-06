#!/bin/bash

j=$1
ping -c 1 -w 5 $j 1>/dev/null
if [ $? -ne 0 ] ; then ip1=0 ; else ip1=1 ; fi
echo $ip1

