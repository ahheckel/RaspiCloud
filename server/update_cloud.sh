#!/bin/bash

if [ -f $HOME/.$(basename $0).lock ] ; then echo "$(basename $0) : An instance is already running - exiting." ; exit 9 ; fi
start=$(date +%s)
tmpdir=$(mktemp -d -t $(basename $0)-XXXXXXXXXX)
wdir="$(pwd)"
function finish {
	    rm -rf $tmpdir
	    rm -f $HOME/.$(basename $0).lock
	    cd "$wdir"
	    exit
}
trap finish EXIT SIGHUP SIGINT SIGQUIT SIGTERM
function checkmd5dir () {
      if [[ $1 =~ [a-f0-9]{32}$ ]] ; then echo 1 ; else echo 0 ; fi
}
touch $HOME/.$(basename $0).lock

if [ x"$1" == "x" ] ; then 
    users="" # define default user-set here 
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
ngnx=$pfld/websrv/nginx/webroot/cloud
clouddir=cloud-NAS/tmp
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
sed -i "${n}s|.*|for j in jpeg jpg png gif webp tif tiff psd bmp pdf doc ppt xls docx pptx xlsx txt pps ppsx jfif odt avi wmv mp4 3gp ; do|g" $dest # all 2 thumbnail
n=$(cat $dest | grep -n  \<\!--\ ENTRY02 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s/.*/        elif [[ \${j} == +(doc|ppt|xls|docx|pptx|xlsx|txt|pps|ppsx|odt) ]] ; then/g" $dest # done by libreoffice
n=$(cat $dest | grep -n  \<\!--\ ENTRY03 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s/.*/        elif [[ \${j} == +(mp4|avi|wmv|3gp) ]] ; then/g" $dest # done by ffmpeg
cp $dest $orig

orig=$HOME/$ngnx/.custom.js
if [ ! -f $orig ] ; then echo "$(basename $0) : $orig not found - exiting..." ; exit 1 ; fi
dest=$tmpdir/tmp
echo "$(basename $0) : updating ${orig}..."
cp $orig $dest
n=$(cat $dest | grep -n  \<\!--\ ENTRY02 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s|.*|var imgformats = [\"jpg\", \"jpeg\", \"png\", \"bmp\", \"tif\", \"tiff\", \"gif\", \"fpx\", \"pcd\", \"svg\", \"pdf\", \"doc\", \"ppt\", \"xls\", \"docx\", \"pptx\", \"xlsx\", \"txt\", \"ppsx\", \"pps\", \"jfif\", \"odt\", \"wmv\", \"mp4\", \"avi\", \"3gp\"];|g" $dest # all
n=$(cat $dest | grep -n  \<\!--\ ENTRY03 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s/.*/if (fileExt == \"jpg\" || fileExt == \"jpeg\" || fileExt == \"jfif\" || fileExt == \"png\" || fileExt == \"bmp\" || fileExt == \"tif\" || fileExt == \"tiff\" || fileExt == \"gif\" || fileExt == \"fpx\" || fileExt == \"pcd\" || fileExt == \"svg\" ) {/g" $dest # pics
n=$(cat $dest | grep -n  \<\!--\ ENTRY04 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s/.*/if (fileExt == \"jpg\" || fileExt == \"jpeg\" || fileExt == \"jfif\" || fileExt == \"png\" || fileExt == \"bmp\" || fileExt == \"tif\" || fileExt == \"tiff\" || fileExt == \"gif\" || fileExt == \"fpx\" || fileExt == \"pcd\" || fileExt == \"svg\" ) {/g" $dest # pics
cp $dest $orig

# reload nginx
echo "$(basename $0) : reloading nginx..."
sudo service nginx reload

# update server scripts for given users
mkdir -p $tmpdir/$srv ; mkdir -p $tmpdir/$clnt
for user in $users ; do
    echo "$(basename $0) : updating cloud-user ${user}..."
    if [ ! -d /home/$user ] ; then echo "$(basename $0) : /home/$user not found - continuing..." ; continue ; fi
    sudo mkdir -p /home/$user/$srv ; sudo mkdir -p /home/$user/$clnt
    sudo chown ${user}:${user} /home/$user/$srv /home/$user/$clnt
    sudo chmod 750 /home/$user/$srv /home/$user/$clnt
    for file in $files ; do
      echo "$(basename $0) :   updating ${file}..."
      sudo cp /home/$admin/$file $tmpdir/$(dirname $file)/
      sudo cp $tmpdir/$file /home/${user}/$(dirname $file)/
      sudo chown ${user}:${user} /home/${user}/$file
      sudo chmod 750 /home/${user}/$file
    done
    echo "$(basename $0) : updating ${user}'s push-script..."
    pushscrpts=$(ls -1 $clnt/*push-to*.sh 2>/dev/null)
    if [ x"$pushscrpts" == "x" ] ; then echo "$(basename $0) : no push-script found..." ; continue ; fi
    dir=/home/${user}/"${clouddir}"
    md5fldrs=""
    for i in $(find $dir -maxdepth 1 -type d) ; do
      dname=$(basename "$i")
      if [ $(checkmd5dir "$dname") -eq 1 ] ; then
        md5fldrs="$md5fldrs \"$dname\""
      fi
    done
    for pushscrpt in $pushscrpts ; do
      n=$(cat $pushscrpt | grep -n \#\ ENTRY01 | cut -d : -f 1)
      if [ x$n != "x" ] ; then
        n=$[$n+1]
        sed -i "${n}s|.*|md5extrn=($md5fldrs)|g" $pushscrpt
      fi
    done
done

end=$(date +%s) ; elapsed=$(echo "($end - $start)" |bc)
echo "$(basename $0) : finished. - $(date) ($elapsed sec elapsed)"
