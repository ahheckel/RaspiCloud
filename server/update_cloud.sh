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

if [ x"$1" == "x" ] ; then 
    users="user1 user2 user3" 
else
    users="$1"
fi

admin="pi" # admin user
srv=RaspiCloud-master/server
clnt=RaspiCloud-master/client
files="$srv/updatedb.sh $srv/_updatedb.sh $srv/parsefiles2link.sh $srv/create_thumbs.sh $srv/_create_thumbs.sh $clnt/runscrpt.sh"

mkdir -p $tmpdir/$srv ; mkdir -p $tmpdir/$clnt
for user in $users ; do
    echo "$(basename $0) : updating user ${user}..."
    sudo mkdir -p /home/$user/$srv ; sudo mkdir -p /home/$user/$clnt
	for file in $files ; do
		sudo cp /home/$admin/$file $tmpdir/$(dirname $file)/
		sudo cp -v $tmpdir/$file /home/${user}/$(dirname $file)/
		done
		
		sudo chown -R ${user}:${user} /home/${user}/$(dirname $file)
		sudo chmod -R 770 /home/${user}/$(dirname $file)
done

end=$(date +%s) ; elapsed=$(echo "($end - $start)" |bc)
echo "$(basename $0) : finished. - $(date) ($elapsed sec elapsed)"
