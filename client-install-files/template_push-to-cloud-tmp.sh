#!/bin/bash
#set -e

ip="xIPADDRESSx"
user="xUSERx"
syncfolders="xSYNCFOLDERSx"
dstdir="xDSTDIRx"
scrpt="xSCRPTx"

if [ -f $HOME/.$(basename $0).lock ] ; then echo "An instance is already running - exiting." ; exit 1 ; fi

function finish {
	    rm -f $HOME/.$(basename $0).lock
}
trap finish EXIT SIGHUP SIGINT SIGQUIT SIGTERM

touch $HOME/.$(basename $0).lock

dirs="$syncfolders"
opts="xOPTSx"
for dir in $dirs ; do
 if [ ! -d $dir ] ; then continue ; fi
	touch $dir/.$(basename $0).list
	ls -lpi --time-style=+%F $dir | grep -v / > $dir/._$(basename $0).list
	if [ "$(cat $dir/.$(basename $0).list)" != "$(cat $dir/._$(basename $0).list)" ] ; then		
		nc -w 10 -z $ip 22 2>/dev/null ; if [ $? -eq 1 ] ; then echo "netcat failed. - exiting." ; rm -f $HOME/.$(basename $0).lock ; exit 1 ; fi # is more robust than ping
		echo "deleting duplicates in $dir..."
		fdupes -dN $dir
		echo ""
		echo "syncing..."
		rsync $opts $dir/* --exclude='*.*.part' --iconv=utf-8,ascii//TRANSLIT//IGNORE -e ssh ${user}@$ip:$dstdir
		echo ""
		echo "updating cloud-scripts..."
		rsync -av -e ssh ${user}@${ip}:$(basename $0) $HOME/.shortcuts/ && chmod +x $HOME/.shortcuts/$(basename $0)
		#rsync -av -e ssh ${user}@${ip}:getgps.sh $HOME/.shortcuts/ && chmod +x $HOME/.shortcuts/getgps.sh
		rsync -av -e ssh ${user}@${ip}:runscrpt.sh $HOME/.shortcuts/ && chmod +x $HOME/.shortcuts/runscrpt.sh
		echo ""
		echo "updating database..."
		ssh ${user}@$ip -t $scrpt
	fi
	mv -f $dir/._$(basename $0).list $dir/.$(basename $0).list
done

rm -f $HOME/.$(basename $0).lock
sleep 2
