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
	echo -n "$1" | md5sum | cut -d " " -f1
}
function checkmd5dir () {
      #if [[ $1 =~ ^\.[a-f0-9]{32}$ ]] ; then echo 1 ; else echo 0 ; fi
      if [[ $1 =~ [a-f0-9]{32}$ ]] ; then echo 1 ; else echo 0 ; fi
}
function getID () {
    local devid=$(echo "$1" | rev | cut -d . -f 1 | rev | cut -d - -f 1)
    local md5id=$(echo "$1" | rev | cut -d . -f 1 | rev | cut -d - -f 2)
    if [ x$devid == x$md5id ] ; then devid="" ; else devid="${devid}-" ; fi
    md5id=$(echo "$md5id" | cut -c -5)
    #echo ${devid}${md5id}
    echo ${md5id}
}

touch $HOME/.$(basename $0).lock
mkdir -p $HOME/.dirlists

# is device ID set ?
if [ x"$device" == x ] ; then dev="" ; else dev="${device}-" ; fi
# collect md5 suffixes
# ENTRY01
md5extrn=()
md5intrn=("${syncfolders[@]}")
tagsexcl=()
tagsuniq=()
md5excl=()
for ((i = 0; i < ${#md5intrn[@]}; i++)) ; do
    dir="${md5intrn[$i]}"
    if [ ! -d "$dir" ] ; then continue ; fi
    md5n=$(getmd5 "$dir")
    tagsexcl+=("$(getID $md5n)")
done
for ((i = 0; i < ${#md5extrn[@]}; i++)) ; do
    dir="${md5extrn[$i]}"
    dir="$(basename $dir)"
    tagsexcl+=("$(getID $dir)")
done
for i in $(printf "%s\n" ${tagsexcl[@]} | sort -u ) ; do tagsuniq+=("$i") ; done
for ((i = 0; i < ${#tagsuniq[@]}; i++)) ; do
    tag="${tagsuniq[$i]}"
    md5excl+=("--exclude=*${tag}")
done
for ((i = 0; i < ${#tagsuniq[@]}; i++)) ; do
    tag="${tagsuniq[$i]}"
    md5excl+=("--exclude=*${tag}*")
done

# sync...
for ((i = 0; i < ${#syncfolders[@]}; i++)) ; do
    dir="${syncfolders[$i]}"
    dstdir="${dstdirs[$i]}" ; if [ x"$dstdir" == "x" ] ; then dstdir="$_dstdir" ; else _dstdir="$dstdir" ; fi
    echo "selecting ${dir}..."
    if [ x"$dir" == "x" ] ; then continue ; fi 
    if [ ! -d "$dir" ] ; then continue ; fi
    md5n=$(getmd5 "$dir")
    if [ x"$md5n" == "x" ] ; then continue ; fi
    if [ $(checkmd5dir "$md5n") -eq 0 ] ; then continue ; fi
    md5=$HOME/.dirlists/${md5n}.dir ; _md5=$HOME/.dirlists/_${md5n}.dir
    touch $md5 $_md5
    ls -lpi --time-style=+%F "$dir/" | grep -v / > $_md5		
    if [ "$(cat $md5)" != "$(cat $_md5)" ] ; then 
        nc -w 10 -z $ip 22 2>/dev/null ; if [ $? -eq 1 ] ; then echo "netcat failed. - exiting." ; rm -f $HOME/.$(basename $0).lock ; exit 1 ; fi # is more robust than ping
		if [ $update -eq 1 ] ; then
		  echo "---updating cloud-scripts first..."     
		  rsync -v -L -c -i -e "ssh -i $ckey" ${user}@${ip}:$clidir/* $HOME/.shortcuts/ | grep ^\>f | cut -d " " -f 2- > $HOME/.dirlists/.update.scrpts
		  if [ $(cat $HOME/.dirlists/.update.scrpts | wc -l) -gt 0 ] ; then
		    chmod +x $HOME/.shortcuts/*.sh
		    echo "---cloud-scripts updated, syncing in next cycle - exiting..."
		    rm -f $HOME/.$(basename $0).lock ; exit 2
		  else
		    echo "   ...nothing to do."
		  fi
		  update=0
		fi
		echo "---deleting duplicates in $dir..."
		fdupes -dNA "$dir"
		echo "---syncing to $dstdir/.${dev}${md5n}..."
		rsync $opts "$dir"/* --exclude='*.*.part' --exclude='*.*.crdownload' --exclude=".*" --exclude='~*' "${md5excl[@]}" --iconv=utf-8,ascii//TRANSLIT//IGNORE -e "ssh -i $ckey" ${user}@$ip:$dstdir/.${dev}${md5n}/ | grep ^\<f | cut -d " " -f 2- | iconv -t ASCII//TRANSLIT//IGNORE -f UTF-8 > $HOME/.dirlists/.update.list
		#cat $HOME/.dirlists/.update.list
		if [ $(cat $HOME/.dirlists/.update.list | wc -l) -gt 0 ] ; then
		  echo "---updating database..."
		  rsync -av $HOME/.dirlists/.update.list -e "ssh -i $ckey" ${user}@${ip}:$dstdir/.${dev}${md5n}/
		  ssh -i $ckey ${user}@$ip -t $scrpt "$dstdir/.${dev}${md5n}" "$dstdir/.${dev}${md5n}/.update.list"
		fi
	fi
	mv -f $_md5 $md5
done

sleep 2
rm -f $HOME/.$(basename $0).lock