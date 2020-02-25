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
touch $HOME/.$(basename $0).lock

#disclaimer
echo "WARNING"
echo "This is experimental software, which might damage your system."
echo "Please be careful!"
read -p "Press key to continue or abort with CTRL-C."
echo ""

#parse inputs
read -e -p "server admin user (for installation purposes): " -i "pi" admin
export ADMIN=$admin
read -e -p "server ip-address: " -i "172.16.0.10" ip
read -e -p "server installation files source: " -i "/home/$admin/client-install-files/" path

#install missing progs on server
echo "--------------------------"
echo "Install missing packages on server..."
echo "--------------------------"
read -p "Install missing packages on server ? [y/n]" yn
if [ x"$yn" == x"y" ]; then
  ssh ${admin}@${ip} "sudo apt-get install bc gawk fdupes"
fi

#download keys
echo "--------------------------"
echo "Download keys for install..."
echo "--------------------------"
mkdir -p $HOME/.ssh
scp ${admin}@${ip}:"$path/ssh/*" $HOME/.ssh/

#pkg upgrade
echo "--------------------------"
echo "Install basic Termux packages..."
echo "--------------------------"
pkg install openssh rsync lftp python neovim wget bc util-linux iconv
termux-setup-storage

#download scripts
echo "--------------------------"
echo "Download installation files..."
echo "--------------------------"
localinstall=$HOME/storage/downloads/data
mkdir -p $localinstall
opts="-v --size-only --no-perms --no-owner --no-group --progress"
rsync -r $opts -e ssh ${admin}@${ip}:$path --exclude=ssh/ --iconv=utf-8,ascii//TRANSLIT//IGNORE $localinstall

#install Termux packages
echo "--------------------------"
echo "Install further Termux packages..."
echo "--------------------------"
cp -f $localinstall/cpscr $HOME/
. $HOME/cpscr $localinstall

#create user account on server
echo "--------------------------"
echo "Create user's server account..."
echo "--------------------------"
read -e -p "user: "  -i "user" user1
export USER1=$user1
read -p "Create account for '$user1' on ${ip} ? [y/n]" yn
if [ x"$yn" == x"y" ]; then
	ssh ${admin}@${ip} "sudo adduser $user1 && sudo adduser $admin $user1" # add admin to private group
fi

#create cloud-dir
echo "--------------------------"
echo "Create user's cloud directory..."
echo "--------------------------"
read -e -p "cloud directory on NAS: " -i "/media/cloud-NAS/${user1}" dstdir
read -e -p "group owner: "            -i "$user1" grp
read -p "Create directory '${dstdir}/tmp' on server ? [y/n]" yn
if [ x"$yn" == x"y" ]; then
  ssh ${admin}@${ip} "sudo mkdir -p ${dstdir}/tmp && sudo chown ${user1}:${grp} ${dstdir}/tmp && sudo chmod 750 ${dstdir}/tmp && sudo chown ${user1}:${grp} $dstdir && sudo chmod 750 $dstdir"
fi
read -p "Create link to cloud storage in ${user1}'s home folder ? [y/n]" yn
if [ x"$yn" == x"y" ]; then
  read -e -p "command: " -i "ln -sfn $dstdir /home/${user1}/cloud-NAS" linkcmd
  ssh ${admin}@${ip} "sudo $linkcmd"
fi
read -p "Add admin user '$admin' to group 'www-data' on server ? [y/n]" yn
if [ x"$yn" == x"y" ]; then
  ssh ${admin}@${ip} "sudo adduser $admin www-data"
fi

#create cloud-dir 4 guests
echo "--------------------------"
echo "Create guests' cloud directory..."
echo "--------------------------"
read -e -p "cloud directory on NAS: " -i "/media/cloud-NAS/guest" gstdstdir
read -p "Create directory for guests on server ? [y/n]" yn
if [ x"$yn" == x"y" ]; then
  ssh ${admin}@${ip} "sudo mkdir -p ${gstdstdir} && sudo chown ${admin}:${grp} ${gstdstdir} && sudo chmod 750 ${gstdstdir}"
fi

#upload authorized_keys
echo "--------------------------"
echo "Upload public key..."
echo "--------------------------"
cat $HOME/.ssh/id_rsa.pub | ssh ${user1}@${ip} "mkdir -p /home/$user1/.ssh && cat >> /home/$user1/.ssh/authorized_keys && chmod -R 600 /home/$user1/.ssh/authorized_keys && chmod 700 /home/$user1/.ssh"
#ssh ${admin}@${ip} "sudo mkdir -p /home/$user1/.ssh && sudo chown -R $user1:$user1 /home/$user1/.ssh && sudo chmod -R 600 /home/$user1/.ssh && sudo chmod 700 /home/$user1/.ssh"

#adapt templates
echo "--------------------------"
echo "Adapt templates..."
echo "--------------------------"
$HOME/.shortcuts/template_config.sh $HOME/.shortcuts/template_push-to-cloud-tmp.sh #$HOME/.shortcuts/template_getgps.sh
echo "$(basename $0) : uploading to server..."
scp $HOME/.shortcuts/push-to-cloud-tmp.sh ${user1}@${ip}:"\$HOME/"
#scp $HOME/.shortcuts/getgps.sh ${user1}@${ip}:"\$HOME/"
#scp $HOME/.shortcuts/runscrpt.sh ${user1}@${ip}:"\$HOME/"
 
#copy scripts to user's home on server
echo "--------------------------"
echo "Copy user-specific scripts to home-folder on server..."
echo "--------------------------"
ssh ${admin}@${ip} "./update_cloud.sh $user1"

#create cronjob
echo "--------------------------"
echo "Create cronjob..."
echo "--------------------------"
read -p "Create cronjob ? [y/n]" yn
if [ x"$yn" == x"y" ]; then
    touch $HOME/../usr/var/spool/cron/crontabs/$(whoami) && cp $HOME/../usr/var/spool/cron/crontabs/$(whoami) $tmpdir/t
    cmd='* * * * * $HOME/.shortcuts/runscrpt.sh $HOME/.shortcuts/push-to-cloud-tmp.sh'
    echo "$cmd" >> $tmpdir/t
    #echo '* * * * * $HOME/.shortcuts/runscrpt.sh $HOME/.shortcuts/getgps.sh' >> $tmpdir/t
    #echo '*/5 * * * * $HOME/../usr/bin/sshd' >> $tmpdir/t
    cat $tmpdir/t | sort -u > $HOME/../usr/var/spool/cron/crontabs/$(whoami)
    crontab -l
fi
read -p "Autostart cron daemon on login ? [y/n]" yn
if [ x"$yn" == x"y" ]; then
	cp -v $localinstall/bash_profile $HOME/.bash_profile
	echo ""
	echo "Starting framework..."
	. $HOME/.bash_profile
fi

echo " "
echo "--------------------------"
echo "Replace ssh-keys with user-generated keys"
echo "   ssh-keygen -t rsa -b 2048 -f id_rsa"
echo "   cat ~/.ssh/id_rsa.pub | ssh ${user1}@${ip} \"cat >> /home/$user1/.ssh/authorized_keys && chmod 600 /home/$user1/.ssh/authorized_keys\""
#echo "and adapt authorized_keys file on the server"
echo "Restart Termux (with WakeLock enabled)."
echo "--------------------------"
end=$(date +%s) ; elapsed=$(echo "($end - $start)" |bc)
echo "$(basename $0) : finished. - $(date) ($elapsed sec elapsed)"
