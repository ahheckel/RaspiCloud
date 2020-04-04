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

#get parentfolder of this script
cd $(dirname $0)/..
wdir0=$(pwd)
pfld=${wdir0#/home/$(whoami)/}
cd - 1>/dev/null

#def vars
srv=$pfld/server
clnt=$pfld/client
ngnx=$pfld/nginx/webroot/cloud
admin="$(whoami)" # this script should be run by the admin user
files="$srv/updatedb.sh $srv/_updatedb.sh $srv/parsefiles2link.sh $srv/create_thumbs.sh $srv/_create_thumbs.sh $clnt/runscrpt.sh"

#update file extension handling (to apply web-related changes execute nginx_install.sh afterwards)
orig=$HOME/$srv/parsefiles2link.sh
if [ ! -f $orig ] ; then echo "$(basename $0) : $orig not found - exiting..." ; exit 1 ; fi
dest=$tmpdir/tmp
echo "$(basename $0) : updating ${orig}..."
cp $orig $dest
n=$(cat $dest | grep -n  \<\!--\ ENTRY01 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s|.*|      for j in mp3 ogg oga mogg wma pcm flac m4a m4b m4p ; do|g" $dest # auds
n=$(cat $dest | grep -n  \<\!--\ ENTRY02 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s|.*|      for j in pdf doc docx htm html odt xls xlsx ods ppt pptx txt pps ppsx odt ; do|g" $dest # docs
n=$(cat $dest | grep -n  \<\!--\ ENTRY03 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s|.*|      for j in  jpeg jpg png gif webp tif tiff psd bmp jfif ; do|g" $dest # pics
n=$(cat $dest | grep -n  \<\!--\ ENTRY04 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s|.*|      for j in  mp4 mov m4v f4v f4a m4r f4b 3gp ogx ogv wmv asf webm flv avi vob TS ts swf ; do|g" $dest # vids
cp $dest $orig

orig=$HOME/$srv/create_thumbs.sh
if [ ! -f $orig ] ; then echo "$(basename $0) : $orig not found - exiting..." ; exit 1 ; fi
dest=$tmpdir/tmp
echo "$(basename $0) : updating ${orig}..."
cp $orig $dest
n=$(cat $dest | grep -n  \<\!--\ ENTRY01 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s|.*|for j in jpeg jpg png gif webp tif tiff psd bmp pdf doc ppt xls docx pptx xlsx txt pps ppsx jfif odt avi wmv mp4 ; do|g" $dest # all 2 thumbnail
n=$(cat $dest | grep -n  \<\!--\ ENTRY02 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s/.*/        elif [ \${j} == \"doc\" ] || [ \${j} == \"ppt\" ] || [ \${j} == \"xls\" ] || [ \${j} == \"docx\" ] || [ \${j} == \"pptx\" ] || [ \${j} == \"xlsx\" ] || [ \${j} == \"txt\" ] || [ \${j} == \"pps\" ] || [ \${j} == \"ppsx\" ] || [ \${j} == \"odt\" ] ; then/g" $dest # done by libreoffice
n=$(cat $dest | grep -n  \<\!--\ ENTRY03 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s/.*/        elif [ \${j} == \"avi\" ] || [ \${j} == \"wmv\" ] || [ \${j} == \"mp4\" ] ; then/g" $dest # done by ffmpeg
cp $dest $orig

orig=$HOME/$ngnx/.custom.js
if [ ! -f $orig ] ; then echo "$(basename $0) : $orig not found - exiting..." ; exit 1 ; fi
dest=$tmpdir/tmp
echo "$(basename $0) : updating ${orig}..."
cp $orig $dest
n=$(cat $dest | grep -n  \<\!--\ ENTRY02 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s|.*|var imgformats = [\"jpg\", \"jpeg\", \"png\", \"bmp\", \"tif\", \"tiff\", \"gif\", \"fpx\", \"pcd\", \"svg\", \"pdf\", \"doc\", \"ppt\", \"xls\", \"docx\", \"pptx\", \"xlsx\", \"txt\", \"ppsx\", \"pps\", \"jfif\", \"odt\", \"wmv\", \"mp4\", \"avi\"];|g" $dest # all
n=$(cat $dest | grep -n  \<\!--\ ENTRY03 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s/.*/if (fileExt == \"jpg\" || fileExt == \"jpeg\" || fileExt == \"jfif\" || fileExt == \"png\" || fileExt == \"bmp\" || fileExt == \"tif\" || fileExt == \"tiff\" || fileExt == \"gif\" || fileExt == \"fpx\" || fileExt == \"pcd\" || fileExt == \"svg\" ) {/g" $dest # pics
n=$(cat $dest | grep -n  \<\!--\ ENTRY04 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s/.*/if (fileExt == \"jpg\" || fileExt == \"jpeg\" || fileExt == \"jfif\" || fileExt == \"png\" || fileExt == \"bmp\" || fileExt == \"tif\" || fileExt == \"tiff\" || fileExt == \"gif\" || fileExt == \"fpx\" || fileExt == \"pcd\" || fileExt == \"svg\" ) {/g" $dest # pics
cp $dest $orig

# update server scripts for all users
mkdir -p $tmpdir/$srv ; mkdir -p $tmpdir/$clnt
for user in $users ; do
    echo "$(basename $0) : updating cloud-user ${user}..."
    if [ ! -d /home/$user ] ; then echo "$(basename $0) : /home/$user not found - continuing..." ; continue ; fi
    sudo mkdir -p /home/$user/$srv ; sudo mkdir -p /home/$user/$clnt
    sudo chown ${user}:${user} /home/$user/$srv /home/$user/$clnt
    sudo chmod 750 /home/$user/$srv /home/$user/$clnt
    for file in $files ; do
      sudo cp /home/$admin/$file $tmpdir/$(dirname $file)/
      sudo cp -v $tmpdir/$file /home/${user}/$(dirname $file)/
      sudo chown ${user}:${user} /home/${user}/$file
      sudo chmod 750 /home/${user}/$file
    done
done

end=$(date +%s) ; elapsed=$(echo "($end - $start)" |bc)
echo "$(basename $0) : finished. - $(date) ($elapsed sec elapsed)"
