#!/bin/bash

ip="xIPADDRESSx"
user="xUSERx"
syncfolders=(xSYNCFOLDERSx)
dstdirs=(xDSTDIRSx)
scrpt="xSCRPTx"
clidir="xCLIDIRx"
ckey="xCKEYx"
update=0

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

opts="xOPTSx"

# collect md5 suffixes
md5excl=()
for ((i = 0; i < ${#syncfolders[@]}; i++)) ; do
    dir="${syncfolders[$i]}"
    if [ ! -d "$dir" ] ; then continue ; fi
    md5n=$(getmd5 "$dir")
    md5excl+=("--exclude=*_$(echo $md5n | cut -c -5).*")
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
		update=1
		echo "---deleting duplicates in $dir..."
		fdupes -dNA "$dir"
		echo "---syncing..."
		rsync $opts "$dir"/* --exclude='*.*.part' --exclude='*.*.crdownload' --exclude=".*" --exclude='~*' "${md5excl[@]}" --iconv=utf-8,ascii//TRANSLIT//IGNORE -e "ssh -i $ckey" ${user}@$ip:$dstdir/.${md5n} | grep ^\<f | cut -d " " -f 2- > $HOME/.dirlists/.update.list
		cat $HOME/.dirlists/.update.list
		if [ $(cat $HOME/.dirlists/.update.list | wc -l) -gt 0 ] ; then
		  echo "---updating database..."
		  #ssh ${user}@$ip -t $scrpt $dstdir/.${md5n}
		  rsync -av $HOME/.dirlists/.update.list -e "ssh -i $ckey" ${user}@${ip}:$dstdir/.${md5n}/
		  ssh -i $ckey ${user}@$ip -t $scrpt "$dstdir/.${md5n}" "$dstdir/.${md5n}/.update.list"
		fi
	fi
	mv -f $_md5 $md5
done
# update...
if [ $update -eq 1 ] ; then
    echo ""
    echo "updating cloud-scripts..."
    rsync -av -e "ssh -i $ckey" ${user}@${ip}:$clidir/* $HOME/.shortcuts/ && chmod +x $HOME/.shortcuts/*
fi

rm -f $HOME/.$(basename $0).lock
sleep 2
