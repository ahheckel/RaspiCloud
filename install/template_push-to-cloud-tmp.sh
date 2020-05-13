#!/bin/bash

ip="xIPADDRESSx"
user="xUSERx"
device="xDEVICEx"
syncfolders=(xSYNCFOLDERSx)
dstdirs=(xDSTDIRSx)
scrpt="xSCRPTx"
clidir="xCLIDIRx"
ckey="xCKEYx"
opts="xOPTSx"
update=1

if [ -f $HOME/.$(basename $0).lock ] ; then echo "An instance is already running - exiting." ; exit 1 ; fi

function finish {
	rm -f $HOME/.$(basename $0).lock
}
trap finish EXIT SIGHUP SIGINT SIGQUIT SIGTERM

function getmd5 () {
	echo "$1" > $HOME/.$(basename $0).md5 ; echo $(md5sum $HOME/.$(basename $0).md5 | cut -d " " -f1)
	rm -f $HOME/.$(basename $0).md5
}

touch $HOME/.$(basename $0).lock
mkdir -p $HOME/.dirlists

# is device ID set ?
if [ x"$device" == x ] ; then dev="" ; else dev="${device}-" ; fi
# collect md5 suffixes
md5excl=()
for ((i = 0; i < ${#syncfolders[@]}; i++)) ; do
    dir="${syncfolders[$i]}"
    if [ ! -d "$dir" ] ; then continue ; fi
    md5n=$(getmd5 "$dir")
    md5excl+=("--exclude=*_${dev}$(echo $md5n | cut -c -5)")
done
for ((i = 0; i < ${#syncfolders[@]}; i++)) ; do
    dir="${syncfolders[$i]}"
    if [ ! -d "$dir" ] ; then continue ; fi
    md5n=$(getmd5 "$dir")
    md5excl+=("--exclude=*_${dev}$(echo $md5n | cut -c -5).*")
done
# sync...
for ((i = 0; i < ${#syncfolders[@]}; i++)) ; do
    dir="${syncfolders[$i]}"
    dstdir="${dstdirs[$i]}"; if [ x"$dstdir" == "x" ] ; then dstdir="$_dstdir" ; else _dstdir="$dstdir" ; fi
    echo "selecting ${dir}..."
    if [ ! -d "$dir" ] ; then continue ; fi
    md5n=$(getmd5 "$dir")
    md5=$HOME/.dirlists/${md5n}.dir ; _md5=$HOME/.dirlists/_${md5n}.dir
	touch $md5
	ls -lpi --time-style=+%F "$dir" | grep -v / > $_md5		
	if [ "$(cat $md5)" != "$(cat $_md5)" ] ; then
        nc -w 10 -z $ip 22 2>/dev/null ; if [ $? -eq 1 ] ; then echo "netcat failed. - exiting." ; rm -f $HOME/.$(basename $0).lock ; exit 1 ; fi # is more robust than ping
		if [ $update -eq 1 ] ; then
		  echo "---updating cloud-scripts first..."     
		  rsync -v -c -i -e "ssh -i $ckey" ${user}@${ip}:$clidir/* $HOME/.shortcuts/ | grep ^\>f | cut -d " " -f 2- > $HOME/.dirlists/.update.scrpts
		  if [ $(cat $HOME/.dirlists/.update.scrpts | wc -l) -gt 0 ] ; then
		    chmod +x $HOME/.shortcuts/*.sh
		    echo "---cloud-scripts updated, syncing in next cycle - exiting..."
		    exit 2
		  else
		    echo "   ...nothing to do."
		  fi
		  update=0
		fi
		echo "---deleting duplicates in $dir..."
		fdupes -dNA "$dir"
		echo "---syncing..."
		rsync $opts "$dir"/* --exclude='*.*.part' --exclude='*.*.crdownload' --exclude=".*" --exclude='~*' "${md5excl[@]}" --iconv=utf-8,ascii//TRANSLIT//IGNORE -e "ssh -i $ckey" ${user}@$ip:$dstdir/.${dev}${md5n} | grep ^\<f | cut -d " " -f 2- | iconv -t ASCII//TRANSLIT//IGNORE -f UTF-8 > $HOME/.dirlists/.update.list
		#cat $HOME/.dirlists/.update.list
		if [ $(cat $HOME/.dirlists/.update.list | wc -l) -gt 0 ] ; then
		  echo "---updating database..."
		  rsync -av $HOME/.dirlists/.update.list -e "ssh -i $ckey" ${user}@${ip}:$dstdir/.${dev}${md5n}/
		  ssh -i $ckey ${user}@$ip -t $scrpt "$dstdir/.${dev}${md5n}" "$dstdir/.${dev}${md5n}/.update.list"
		fi
	fi
	mv -f $_md5 $md5
done
# update...
#if [ $update -eq 1 ] ; then
#    echo ""
#    echo "updating cloud-scripts..."
#    rsync -av -e "ssh -i $ckey" ${user}@${ip}:$clidir/* $HOME/.shortcuts/ && chmod +x $HOME/.shortcuts/*
#fi

rm -f $HOME/.$(basename $0).lock
sleep 2
