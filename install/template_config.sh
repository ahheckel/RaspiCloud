#!/bin/bash
tmpdir=$(mktemp -d -t $(basename $0)-XXXXXXXXXX)
wdir="$(pwd)"
function finish {
	    rm -rf $tmpdir
	    rm -f $HOME/.$(basename $0).lock
	    cd "$wdir"
	    echo ""
	    exit
}
trap finish EXIT SIGHUP SIGINT SIGQUIT SIGTERM 

echo "$(basename $0) : config SYNC..."
echo ""

# parse input
if [ x"$1" == "x" ] ; then
      echo "$(basename $0) : no template file given... exiting."
      exit 1
else
      input0="$1"
      if [ ! -f "$input0" ] ; then
		echo "$(basename $0) : file '$input0' does not exist... exiting."
		exit 1
      fi
      cp "$input0" $tmpdir/
      input="$tmpdir/$(basename $input0)"
fi
read -e -p "syncfolders (on client): " -i '"storage/downloads/" "storage/dcim/Screenshots/" "storage/dcim/Camera/" "storage/dcim/Facebook/"' syncfolders
read -e -p "rsync-options:           " -i "-v --size-only -p -o -g --progress --chown=$USER1:$GRP --chmod=750" opts
read -e -p "syncscrpt (on client):   " -i ".shortcuts/push-to-cloud-tmp.sh" syncscrpt
read -e -p "post-scrpt (on server):  " -i "/home/$USER1/$SRVDIR/updatedb.sh $DSTDIR/tmp" scrpt

# replace
sed -i "s|xIPADDRESSx|$IP|g" $input
sed -i "s|xUSERx|$USER1|g" $input
sed -i "s|xSYNCFOLDERSx|$syncfolders|g" $input
sed -i "s|xDSTDIRx|$DSTDIR/tmp|g" $input
sed -i "s|xSCRPTx|$scrpt|g" $input
sed -i "s|xOPTSx|$opts|g" $input
sed -i "s|xCLIDIRx|$CLIDIR|g" $input
sed -i "s|xCKEYx|$CKEY|g" $input

# make executable
echo ""
cp -v $input $syncscrpt
chmod +x $syncscrpt

echo ""
echo "$(basename $0) : remember: you can change sync-folders in the script ${syncscrpt}."
echo "$(basename $0) : remember: you may want to run ${syncscrpt} once per minute or so with a termux cronjob (crontab -e)."
echo ""
read -p "Press enter to continue..."
##--------------
##--------------
#echo ""
#echo "$(basename $0) : config GPS..."

## parse input
#shift
#if [ x"$1" == "x" ] ; then
      #echo "$(basename $0) : no template file given... exiting."
      #exit 1
#else
      #input0="$1"
      #if [ ! -f "$input0" ] ; then
		#echo "$(basename $0) : file '$input0' does not exist... exiting."
		#exit 1
      #fi
      #cp "$input0" $tmpdir/
      #input="$tmpdir/$(basename $input0)"
#fi

#read -e -p "gpsfile on server: "   -i "/home/${user}/gps.txt" gpsfile
#read -e -p "gpsdelta: "		    -i "50" gpsdelta
#read -e -p "gps-www-dir: "	     -i "/home/${user}/cloud-NAS/tmp/.gps" dstdir
#read -e -p "gps-webpage: "	     -i "${dstdir}/index.html" webpage
#read -e -p "gps-global-dir: "      -i "/var/www/html/test/.gps" dstdir0
#read -e -p "scrpt on server: "     -i "/home/${user}/create-gps-html.sh $gpsfile $webpage" scrpt
#read -e -p "script-name: "    	 -i ".shortcuts/getgps.sh" syncscrpt

## replace
#sed -i "s|xIPADDRESSx|$ip|g" $input
#sed -i "s|xUSERx|$user|g" $input
#sed -i "s|xGPSFILEx|$gpsfile|g" $input
#sed -i "s|xWEBPAGEx|$webpage|g" $input
#sed -i "s|xSCRPTx|$scrpt|g" $input
#sed -i "s|xGPSDELTAx|$gpsdelta|g" $input

## make executable
#echo ""
#cp -v $input $syncscrpt
#chmod +x $syncscrpt

## create destination dir on server
#echo -n "$(basename $0) : "
#read -p "Create directory '$dstdir' on server ? [y/N]" yn
#if [ x"$yn" == x"y" ]; then
  #read -e -p "server admin user: " -i "$ADMIN" ADMIN
  #ssh ${ADMIN}@${ip} "sudo mkdir -p $dstdir && sudo chown ${user}:${grp} $dstdir && sudo chmod 750 $dstdir"
#fi
#echo -n "$(basename $0) : "
#read -p "Create file '$dstdir0/index.html' on server ? [y/N]" yn
#if [ x"$yn" == x"y" ]; then
  #read -e -p "server admin user: " -i "$ADMIN" ADMIN
  #ssh ${ADMIN}@${ip} "sudo mkdir -p $dstdir0 && sudo chown ${ADMIN}:${grp} $dstdir0 && sudo chmod 750 $dstdir0"
  #ssh ${ADMIN}@${ip} "sudo touch $dstdir0/index.html && sudo chown ${ADMIN}:${grp} $dstdir0/index.html && sudo chmod 760 $dstdir0/index.html"
  #fi

#echo ""
#echo "$(basename $0) : remember: Termux-API on PlayStore must be installed for GPS to work."
#echo "$(basename $0) : remember: you can change parameters in the script ${syncscrpt}."
#echo "$(basename $0) : remember: you may want to run ${synscrpt} once per minute or so with a termux cronjob (crontab -e)."
#echo "$(basename $0) : finished."
