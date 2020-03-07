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

# parse input
if [ x"$1" == "x" ] ; then
      echo "$(basename $0) : no directory name given - exiting..."
      exit 1
fi
i="$1"
shift
res_img="$1" ; if [ x"$res_img" == "x" ] ; then res_img=300 ; fi
shift
res_pdf="$1" ; if [ x"$res_pdf" == "x" ] ; then res_pdf=1000 ; fi
shift
refresh="$1" ; if [ x"$refresh" == "x" ] ; then refresh=1 ; fi
echo "$(basename $0) : directory : $i"
echo "$(basename $0) : size img  : $res_img"
echo "$(basename $0) : size pdf  : $res_pdf"
echo "$(basename $0) : overwrite : $refresh"

if [ -d $i/.thumbs ] ; then
	find $i/.thumbs -maxdepth 1 -type f > $tmpdir/list
	for j in  $(cat $tmpdir/list) ; do
  	fname=$(basename $j)
  	if [ -f $i/$fname ] ; then 
		continue
  	else
		echo "$(basename $0) : deleting deprecated thumbnail ${i}/.thumbs/${fname}"
		rm -f $i/.thumbs/$fname
  	fi
	done
fi

find $i -maxdepth 1 -not -type d > $tmpdir/list
for j in  $(cat $tmpdir/list) ; do
  fname=$(basename $j)
  if [ -f $i/.thumbs/$fname ] ; then 
	if [ $refresh -eq 0 ] ; then 
	  continue
	else
	  $(dirname $0)/create_thumbs.sh "${i}/${fname}" $res_img $res_pdf 1
	fi
  else
	$(dirname $0)/create_thumbs.sh "${i}/${fname}" $res_img $res_pdf 0
  fi
done

end=$(date +%s) ; elapsed=$(echo "($end - $start)" |bc)
echo "$(basename $0) : finished. - $(date) ($elapsed sec elapsed)"
