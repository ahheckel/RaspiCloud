#!/bin/bash
if [ -f $HOME/.$(basename $0).lock ] ; then echo "$(basename $0) : An instance is already running - exiting." ; exit 9 ; fi
start=$(date +%s)
wdir="$(pwd)"
function finish {
	    rm -f $HOME/.$(basename $0).lock
	    cd "$wdir"
        exit
}
trap finish EXIT SIGHUP SIGINT SIGQUIT SIGTERM 
touch $HOME/.$(basename $0).lock

# absolute path of current script
SCRPTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"; SCRPTPATH="$(dirname $SCRPTPATH)"

Usage() {
    echo ""
    echo "Usage:   `basename $0` <webroot> <limit in MB>"
    echo "Example: `basename $0` /var/www/html/cloud 50000"
    echo ""
    exit 1
}

[ "$2" = "" ] && Usage
webroot="$1"
limit="$2"

#get folder of this script relative to home
cd $(dirname $0)
wdir0=$(pwd)
fldr=${wdir0#/home/$(whoami)/}
cd - 1>/dev/null

if [ ! -d $webroot ] ; then echo "$(basename $0) : $webroot does not exist - exiting" ; exit 1 ; fi  
users=$(ls -1p $webroot | grep /$ | rev | cut -c 2- | rev | grep -v guest)

$SCRPTPATH/update_cloud.sh "$users"
echo ""

for user in $users ; do 
  dir="$webroot/${user}/tmp"
  if [ ! -d $dir ] ; then echo "$(basename $0) : $dir does not exist - continuing..." ; continue ; fi
  sudo -u ${user} /home/${user}/${fldr}/parsefiles2link.sh $dir 0 &>/dev/null
  $SCRPTPATH/quota.sh $user cloud-NAS/tmp $limit
done

end=$(date +%s) ; elapsed=$(echo "($end - $start)" |bc)
echo "$(basename $0) : finished. - $(date) ($elapsed sec elapsed)"
