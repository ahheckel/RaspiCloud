#!/bin/bash

if [ -f $HOME/.$(basename $0).lock ] ; then echo "$(basename $0) : An instance is already running - exiting." ; exit 9 ; fi
start=$(date +%s)
tmpdir=$(mktemp -d -t $(basename $0)-XXXXXXXXXX)
wdir="$(pwd)"
key="$HOME/.ssh/RaspiCloud-tmp$$.rsa" # temp key for installation
ckey="$HOME/.ssh/raspicloud" # user's key
function remkeys {
	    if [ x"$key" != x"$HOME/.ssh/id_rsa" ] ; then
	      rm -fv $key ${key}.pub
	    else
	      echo "$(basename $0) : ...will not delete $key."
	    fi
}
function createuserkey {
  ssh-keygen -t rsa -b 2048 -f $ckey
  echo "uploading user ${user1}'s public key to server ($ip)..."
  cat $ckey| ssh ${user1}@${ip} "mkdir -p /home/$user1/.ssh && cat >> /home/$user1/.ssh/authorized_keys && chmod 600 /home/$user1/.ssh/authorized_keys && chmod 700 /home/$user1/.ssh"
}
function finish {
	    rm -rf $tmpdir
	    rm -f $HOME/.$(basename $0).lock
	    remkeys;
	    cd "$wdir"
	    echo "$(basename $0) : exited."
	    exit
}
trap finish EXIT SIGHUP SIGINT SIGQUIT SIGTERM 
touch $HOME/.$(basename $0).lock

#disclaimer
echo ""
echo "WARNING!"
echo "This is experimental software, which might damage your system."
echo "Please be careful!"
read -p "Press enter to continue or abort with CTRL-C."
echo ""

#export user's key
export CKEY=$ckey

#parse inputs
read -e -p "server ip-address: " -i "172.16.0.10" ip
export IP=$ip
read -e -p "server admin user (for installation purposes): " -i "pi" admin
export ADMIN=$admin
read -e -p "installation source (on server): " -i "/home/$admin/RaspiCloud-master/install/" path
read -e -p "client script dir (on server):   " -i "RaspiCloud-master/client" clidir
export CLIDIR=$clidir
read -e -p "server script dir (on server):   " -i "RaspiCloud-master/server" srvdir
export SRVDIR=$srvdir
read -e -p "current user:                    " -i "johndoe" user1
export USER1=$user1
read -e -p "user's cloud-dir on NAS:         " -i "/media/cloud-NAS/${user1}" dstdir
export DSTDIR=$dstdir
read -e -p "user's cloud-dir group owner:    " -i "$user1" grp
export GRP=$grp

#create keypair for installation
echo "--------------------------"
echo "Create temporary ssh-keypair for installation..."
echo "--------------------------"
read -p "Create keys ? [Y/n]" yn
if [ x"$yn" != x"n" ]; then
  ssh-keygen -t rsa -b 2048 -f $key
else
  key="$HOME/.ssh/id_rsa"
fi
echo -n "uploading public key..."
cat ${key}.pub | ssh ${admin}@${ip} "mkdir -p /home/$admin/.ssh && cat >> /home/$admin/.ssh/authorized_keys && chmod 600 /home/$admin/.ssh/authorized_keys && chmod 700 /home/$admin/.ssh" && echo "...done."

#install missing progs on server
echo "--------------------------"
echo "Install some packages on server ($ip)..."
echo "--------------------------"
read -p "Install packages ? [Y/n]" yn
if [ x"$yn" != x"n" ]; then
  ssh -i $key ${admin}@${ip} "sudo apt-get install bc gawk fdupes"
fi

#install Termux packages 1
echo "--------------------------"
echo "Install Termux packages on client (1/2)..."
echo "--------------------------"
read -p "Install packages ? [Y/n]" yn
if [ x"$yn" != x"n" ]; then
  pkg install openssh rsync lftp python neovim wget bc util-linux iconv
  termux-setup-storage
fi
echo ""

echo "downloading installation files from $ip (to temporary folder)..."
localinstall=$tmpdir
mkdir -p $localinstall
opts="-v --size-only --no-perms --no-owner --no-group --progress"
rsync -r $opts -e "ssh -i $key" ${admin}@${ip}:$path --exclude=ssh/ --iconv=utf-8,ascii//TRANSLIT//IGNORE $localinstall

#install Termux packages 2
echo "--------------------------"
echo "Install Termux packages on client (2/2)..."
echo "--------------------------"
read -p "Install packages ? [Y/n]" yn
if [ x"$yn" != x"n" ]; then
  cp -f $localinstall/cpscr $HOME/
  . $HOME/cpscr $localinstall
fi

#create user account on server
echo "--------------------------"
echo "Create user's account on server ($ip)..."
echo "--------------------------"
read -p "Press enter to continue..."
echo "creating account '$user1' on ${ip}..."
ssh -i $key ${admin}@${ip} "sudo adduser $user1 && sudo adduser $admin $user1 && sudo adduser $user1 www-data" # add admin to private group, and add user to www-data

#create cloud-dir
echo "--------------------------"
echo "Create user's cloud-dir on server ($ip)..."
echo "--------------------------"
read -p "Press enter to continue..."
echo "creating cloud-dir '${dstdir}/tmp' on NAS..."
ssh -i $key ${admin}@${ip} "sudo mkdir -p ${dstdir}/tmp && sudo chown -R ${user1}:${grp} ${dstdir} && sudo chmod -R 750 ${dstdir}"

echo "creating link to NAS in ${user1}'s home folder..."
cmd="ln -sfn $dstdir /home/${user1}/cloud-NAS"
echo "executing $cmd on server..."
ssh -i $key ${admin}@${ip} "sudo $cmd"

echo "adding admin user '$admin' to group 'www-data' on server..."
ssh -i $key ${admin}@${ip} "sudo adduser $admin www-data"

if [ x"$grp" != x"www-data" ]; then
  echo "adding user 'www-data' to group '$grp' on server..."
  ssh -i $key ${admin}@${ip} "sudo adduser www-data $grp"
fi

#create cloud-dir 4 guests
echo "--------------------------"
echo "Create guests' cloud-dir on server ($ip)..."
echo "--------------------------"
read -p "Create directory for guests ? [Y/n]" yn
if [ x"$yn" != x"n" ]; then
  read -e -p "guest directory on NAS: " -i "/media/cloud-NAS/guest" gstdstdir
  ssh -i $key ${admin}@${ip} "sudo mkdir -p ${gstdstdir} && sudo chown ${admin}:www-data ${gstdstdir} && sudo chmod 777 ${gstdstdir}"
fi

#copy scripts to user's home on server
echo "--------------------------"
echo "Install user's scripts on server ($ip)..."
echo "--------------------------"
read -p "Press enter to continue..."
ssh -i $key ${admin}@${ip} "chmod +x \$HOME/$srvdir/*.sh && \$HOME/$srvdir/update_cloud.sh $user1"

#upload authorized_keys
echo "--------------------------"
echo "Create user's ssh-keypair..."
echo "--------------------------"
if [ -f $ckey ]; then
  read -p "Create new keys ? [Y/n]" yn
  if [ x"$yn" != x"n" ]; then
    createuserkey
  fi
else
  echo "creating keys..."
  createuserkey
fi

#adapt templates
echo "--------------------------"
echo "Configure templates for user..."
echo "--------------------------"
read -p "Press enter to continue..."
$HOME/.shortcuts/template_config.sh $HOME/.shortcuts/template_push-to-cloud-tmp.sh
echo "uploading to server ($ip)..."
scp -i $ckey $HOME/.shortcuts/push-to-cloud-tmp.sh ${user1}@${ip}:"\$HOME/$clidir/"
 
#create cronjob
echo "--------------------------"
echo "Create cronjob on client..."
echo "--------------------------"
read -p "Create cronjob ? [Y/n]" yn
if [ x"$yn" != x"n" ]; then
    touch $HOME/../usr/var/spool/cron/crontabs/$(whoami) && cp $HOME/../usr/var/spool/cron/crontabs/$(whoami) $tmpdir/t
    cmd='* * * * * $HOME/.shortcuts/runscrpt.sh $HOME/.shortcuts/push-to-cloud-tmp.sh'
    echo "$cmd"
    read -p "Add above line to crontab ? [Y/n]" yn
    if [ x"$yn" != x"n" ]; then
        echo "$cmd" >> $tmpdir/t
    fi
    cat $tmpdir/t | sort -u > $HOME/../usr/var/spool/cron/crontabs/$(whoami)
    echo "Crontab:"
    crontab -l
fi

read -p "Autostart cron-daemon on login ? [Y/n]" yn
if [ x"$yn" != x"n" ]; then
	cp -v $localinstall/bash_profile $HOME/.bash_profile
	echo ""
	echo "Starting framework..."
	. $HOME/.bash_profile
fi

echo "--------------------------"
echo "Cleanup..."
echo "--------------------------"
read -p "Press enter to continue..."
str_tmp="$(cat ${key}.pub)"
echo "removing public key (that was used to authenticate this installation) from admin ${admin}'s authorized_keys file on server ($ip)..."
ssh -i $key ${admin}@${ip} "if test -f \$HOME/.ssh/authorized_keys; then if grep -v \"$str_tmp\" \$HOME/.ssh/authorized_keys > \$HOME/.ssh/tmp; then cat \$HOME/.ssh/tmp > \$HOME/.ssh/authorized_keys && rm \$HOME/.ssh/tmp; else rm \$HOME/.ssh/authorized_keys && rm \$HOME/.ssh/tmp; fi; fi"
echo "deleting temporary installation keys on client..."
remkeys;

echo " "
echo " "
echo "--------------------------"
echo "Now restart Termux (with 'WakeLock' enabled)."
echo "--------------------------"
end=$(date +%s) ; elapsed=$(echo "($end - $start)" |bc)
echo "$(basename $0) : finished. - $(date) ($elapsed sec elapsed)"
