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
files="updatedb.sh _updatedb.sh parsefiles2link.sh create_thumbs.sh _create_thumbs.sh runscript.sh"

for user in $users ; do
    echo "$(basename $0) : updating user ${user}..."
	for file in $files ; do
		sudo cp /home/$admin/$file $tmpdir/$(basename $file)
		sudo cp -v $tmpdir/$(basename $file) /home/${user}/
		sudo chmod 770 /home/${user}/$(basename $file)
		sudo chown ${user}:${user} /home/${user}/$(basename $file)
	done
done

end=$(date +%s) ; elapsed=$(echo "($end - $start)" |bc)
echo "$(basename $0) : finished. - $(date) ($elapsed sec elapsed)"
