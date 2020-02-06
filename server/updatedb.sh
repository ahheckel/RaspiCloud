#!/bin/bash
if [ -f $HOME/.$(basename $0).lock ] ; then echo "$(basename $0) : An instance is already running - exiting." ; exit 9 ; fi
start=$(date +%s)
tmpdir=$(mktemp -d -t $(basename $0)-XXXXXXXXXX)
wdir="$(pwd)"
function finish {
	    rm -rf $tmpdir
	    rm -f $HOME/.$(basename $0).lock
	    cd "$wdir"
}
trap finish EXIT SIGHUP SIGINT SIGQUIT SIGTERM 
touch $HOME/.$(basename $0).lock

IFSbak="$IFS"
IFS="
"

$HOME/_updatedb.sh "$1"
EC=$?

i=0 ; cutoff=30
until [ ${EC} -ne 9 ] ; do 
      $HOME/_updatedb.sh "$1"
      EC=$?
      sleep 10
      i=$[$i+1]
      if [ $i -gt $cutoff ] ; then 
	    echo "$(basename $0) : having tried $cutoff times, another $(basename $0) process is still running..."
	    break
      fi
done

end=$(date +%s) ; elapsed=$(echo "($end - $start)" |bc)
echo "$(basename $0) : finished. - $(date) ($elapsed sec elapsed)"
