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
       echo "$(basename $0) : no directory given... exiting."
else
      dir="$1"
fi
if [ ! -d "$dir" ] ; then
      echo "$(basename $0) : directory '$dir' does not exist... exiting."
      exit 1
fi

cd $dir

touch .$(basename $0).list
cp .$(basename $0).list $tmpdir/listing
find ./ -maxdepth 1 -type f -printf '%i %p\n' > .$(basename $0).list
cat .$(basename $0).list >> $tmpdir/listing
cat $tmpdir/listing | sort | uniq -u | cut -d / -f 2- > $tmpdir/list.unique
if [ $(cat $tmpdir/list.unique | wc -l) -ne 0 ] ; then
      echo "content of $tmpdir/list.unique:" # for debugging
      cat $tmpdir/list.unique # for debugging
      echo "---------------"
      $(dirname $0)/parsefiles2link.sh "$dir" $tmpdir/list.unique
fi

end=$(date +%s) ; elapsed=$(echo "($end - $start)" |bc)
echo "$(basename $0) : finished. - $(date) ($elapsed sec elapsed)"
