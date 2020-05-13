#!/bin/bash
start=$(date +%s)
tmpdir=$(mktemp -d -t $(basename $0)-XXXXXXXXXX)
wdir="$(pwd)"
function finish {
	    rm -rf $tmpdir
	    cd "$wdir"
	    exit 1
}
trap finish EXIT SIGHUP SIGINT SIGQUIT SIGTERM 

sudo apt-get install wget
wget -O basic-install.sh  https://install.pi-hole.net && mv basic-install.sh $tmpdir && sudo bash $tmpdir/basic-install.sh

#echo "Enter PiHole admin password:"
#sudo pihole -a -p