#!/bin/bash
if [ -f $HOME/.$(basename $0).lock ] ; then echo "$(basename $0) : An instance is already running - exiting." ; exit 9 ; fi
start=$(date +%s)
tmpdir=$(mktemp -d -t $(basename $0)-XXXXXXXXXX)
wdir="$(pwd)"
function finish {
	    rm -rf $tmpdir
	    rm -f $HOME/.$(basename $0).lock
	    cd "$wdir"
        exit
}
trap finish EXIT SIGHUP SIGINT SIGQUIT SIGTERM 
touch $HOME/.$(basename $0).lock

function cleanupdir () {
  DIRSIZE=0
  for i in $(find $dir -maxdepth 1) ; do  
    s=$(stat -c "%s" $i)
    DIRSIZE=$[$DIRSIZE+$s]
  done  
  echo "$dir contains $((echo $DIRSIZE / 1024 / 1024)| bc) MB. Limit is $((echo $LIMITSIZE / 1024 / 1024) | bc) MB"
  if [ "$DIRSIZE" -ge "$SOMELIMIT" ]
    then
      for f in `ls -trp $dir | grep -v /`; do
          FILESIZE=`stat -c "%s" $dir/$f`
          DIRSIZE=$(echo "$DIRSIZE-$FILESIZE"|bc -l)
          echo "  deleting $f"
          sudo -u ${user} rm $dir/$f
          if [ "$DIRSIZE" -lt "$LIMITSIZE" ]; then
              break
          fi
      done
  else
    echo -n "  No deletions made."
  fi
  NEWSIZE=0 ; for i in $(find $dir -maxdepth 1) ; do  
    s=$(stat -c "%s" $i)
    NEWSIZE=$[$NEWSIZE+$s]
  done 
  echo " $[$NEWSIZE / 1024 / 1024] MB remain."
}

Usage() {
    echo ""
    echo "Usage:   `basename $0` <USER> <cloud-dir[relative to user's home]> <limit in MB>"
    echo "Example: `basename $0` pi cloud-NAS/tmp 50000"
    echo ""
    exit 1
}

[ "$3" = "" ] && Usage
#get folder of this script relative to home
cd $(dirname $0)
wdir0=$(pwd)
fldr=${wdir0#/home/$(whoami)/}
cd - 1>/dev/null
#other vars
user="$1"
dir="/home/${user}/$2"
limit="$3"
SCRPTPATH="/home/${user}/${fldr}"
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

if [ ! -d $dir ] ; then echo "$(basename $0) : $dir does not exist - exiting" ; exit 1 ; fi  

echo "$(basename $0) : starting... - $(date)"
echo "--------------------------------"

LIMITSIZE=$[$limit*1024*1024]
SOMELIMIT=$LIMITSIZE
cleanupdir
sudo -u ${user} $SCRPTPATH/parsefiles2link.sh $dir -mkconsistent # &>/dev/null
IFS=$SAVEIFS

#echo "--------------------------------"
#echo "$(basename $0) : Cleaning up apt-get cache..."
#sudo apt-get clean
#echo "$(basename $0) : Removing superfluous packages..."
#sudo apt-get autoremove -y
#sudo apt-get autoclean
echo "--------------------------------"
end=$(date +%s) ; elapsed=$(echo "($end - $start)" |bc)
echo "$(basename $0) : finished. - $(date) ($elapsed sec elapsed)"
