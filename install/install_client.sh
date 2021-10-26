#!/bin/bash

if [ -f $HOME/.$(basename $0).lock ] ; then echo "$(basename $0) : An instance is already running - exiting." ; exit 9 ; fi
start=$(date +%s)
tmpdir=$(mktemp -d -t $(basename $0)-XXXXXXXXXX)
wdir="$(pwd)"
function remkeys {
  echo "$(basename $0) : removing installation keys on client..."
  if [ x"$key" != x"$HOME/.ssh/id_rsa" ] ; then
    rm -fv $key ${key}.pub
  else
    echo "$(basename $0) : ...will not delete $key."
  fi
}
function remauth {
  if [ -f "${key}.pub" ] && [ x"$admin" != "x" ] && [ x"$ip" != "x" ]; then
    echo "$(basename $0) : removing public installation key from admin ${admin}'s 'authorized_keys' on server ($ip)..."
    str_tmp="$(cat ${key}.pub)"
    ssh -i $key ${admin}@${ip} "if test -f \$HOME/.ssh/authorized_keys; then if grep -v \"$str_tmp\" \$HOME/.ssh/authorized_keys > \$HOME/.ssh/tmp; then cat \$HOME/.ssh/tmp > \$HOME/.ssh/authorized_keys && rm \$HOME/.ssh/tmp; else rm \$HOME/.ssh/authorized_keys && rm \$HOME/.ssh/tmp; fi; fi"
  fi
}
function createuserkey {
  if [ $1 -eq 1 ] ; then
    ssh-keygen -t rsa -b 2048 -f $ckey
  fi
  echo "$(basename $0) : uploading user ${user1}'s public key to server ($ip)..."
  cat ${ckey}.pub| ssh ${user1}@${ip} "mkdir -p /home/$user1/.ssh && cat >> /home/$user1/.ssh/authorized_keys && sort /home/$user1/.ssh/authorized_keys | uniq > /home/$user1/.ssh/authorized_keys.uniq && mv /home/$user1/.ssh/authorized_keys.uniq /home/$user1/.ssh/authorized_keys && chmod 600 /home/$user1/.ssh/authorized_keys && chmod 700 /home/$user1/.ssh" && echo "...done."
}
function getownip {
  ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'
}
function checkyn {
  if [ $(echo $yn | grep ^[Nn] | wc -l) -gt 0 ]; then 
    echo "xn"
  elif [ $(echo $yn | grep ^[Yy] | wc -l) -gt 0 ]; then 
    echo "xy"
  else
    echo "x"
  fi
}
function finish {
  rm -rf $tmpdir
  rm -f $HOME/.$(basename $0).lock
  #echo ""
  remauth;
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

#define keys
key="$HOME/.ssh/RaspiCloud-tmp$$.rsa" # temp key for installation
ckey="$HOME/.ssh/raspicloud" # user's key
export CKEY=$ckey

#parse inputs
read -e -p "server (Raspberry) ip-address:   " -i "$(getownip|cut -d . -f 1-3).1" ip
ping -c3 $ip
if [ $? -ne 0 ] ; then echo "PING failed." ; finish ; fi
export IP=$ip
echo ""
read -e -p "server admin user (for installation purposes): " -i "pi" admin
export ADMIN=$admin
read -e -p "installation source (on server):    " -i "/home/$admin/RaspiCloud-master/install/" path
read -e -p "client script subdir (on server):   " -i "$(dirname ${path#/home/$admin/})/client" clidir
export CLIDIR=$clidir
read -e -p "server script subdir (on server):   " -i "$(dirname ${path#/home/$admin/})/server" srvdir
export SRVDIR=$srvdir
##check dirs
#cdirs=("$path" "/home/$admin/$clidir" "/home/$admin/$srvdir"); 
#ssh $admin@$ip echo "checking directories..." ; for ((i=0; i < ${#cdirs[@]}; i++)) ; do if [ -d "${cdirs[$i]}" ] ; then echo "${cdirs[$i]} : exists." ; else echo "${cdirs[$i]} : does not exist!" ; fi ; done
#echo ""
#parse inputs
read -e -p "enter username:                     " -i "pi" user1
export USER1=$user1
read -e -p "user's cloud-dir (on server):       " -i "/media/cloud-NAS/${user1}" dstdir
export DSTDIR=$dstdir
read -e -p "user's cloud-dir group owner:       " -i "$user1" grp
export GRP=$grp
read -e -p "enter device-ID:                    " -i "T01" device
export DEVICE=$device

#create keypair for installation
echo "--------------------------"
echo "Create temporary ssh-keypair for installation..."
echo "--------------------------"
echo "creating temporary keys..."
ssh-keygen -t rsa -b 2048 -f $key
echo "uploading public key..."
cat ${key}.pub | ssh ${admin}@${ip} "mkdir -p /home/$admin/.ssh && cat >> /home/$admin/.ssh/authorized_keys && chmod 600 /home/$admin/.ssh/authorized_keys && chmod 700 /home/$admin/.ssh" && echo "...done."

#install missing progs on server
echo "--------------------------"
echo "Install packages on server ($ip)..."
echo "--------------------------"
read -p "Install packages ? [Y/n]" yn
if [ $(checkyn) != x"n" ]; then
  ssh -i $key ${admin}@${ip} "sudo apt-get install bc gawk fdupes"
fi

#install Termux packages
echo "--------------------------"
echo "Install termux packages on client..."
echo "--------------------------"
read -p "Press enter to continue..."
pkg update
pkg install openssh rsync bc util-linux iconv termux-api nano nmap fdupes busybox cronie
echo "--------------------------"
echo "downloading installation files from $ip (to temporary folder)..."
localinstall=$tmpdir
mkdir -p $localinstall
opts="-v --size-only --no-perms --no-owner --no-group --progress"
rsync -r $opts -e "ssh -i $key" ${admin}@${ip}:$path --exclude=ssh/ --iconv=utf-8,ascii//TRANSLIT//IGNORE $localinstall
echo "--------------------------"
echo "copying configs to termux..."
echo "--------------------------"
mkdir -p $HOME/.shortcuts
mkdir -p $HOME/.termux/tasker
cp ${localinstall}/* $HOME/.shortcuts/
cp ${localinstall}/* $HOME/.termux/tasker
chmod +x $HOME/.shortcuts/*
chmod +x $HOME/.termux/tasker/*
#ln -snf $HOME/.shortcuts $HOME/.termux/tasker #tasker-pulgin: link no longer accepted
cp ${localinstall}/bashrc $HOME/.bashrc
echo "--------------------------"
echo "executing termux-setup-storage..."
echo "--------------------------"
termux-setup-storage

#create user account on server
echo "--------------------------"
echo "Create user's account on server ($ip)..."
echo "--------------------------"
read -p "Press enter to continue..."
echo "creating account '$user1' on ${ip}..."
ssh -i $key ${admin}@${ip} "sudo adduser $user1 && sudo adduser $admin $user1 && sudo adduser $user1 www-data" # add admin to private group, and add user to www-data
echo "--------------------------"
echo "installing user's scripts on server ($ip)..."
ssh -i $key ${admin}@${ip} "chmod +x \$HOME/$srvdir/*.sh && \$HOME/$srvdir/update_cloud.sh $user1"

#create user's cloud-dir
echo "--------------------------"
echo "Create user's cloud-dir '${dstdir}/tmp' on server ($ip)..."
echo "--------------------------"
read -p "Press enter to continue..."
echo "creating cloud-dir ('${dstdir}/tmp') on NAS..."
ssh -i $key ${admin}@${ip} "sudo mkdir -p ${dstdir}/tmp && sudo chown -R ${user1}:${grp} ${dstdir} && sudo chmod -R 750 ${dstdir}"
echo "--------------------------"  
echo "creating symlink to NAS in ${user1}'s home folder..."
cmd="ln -sfnv $dstdir /home/${user1}/cloud-NAS"
#echo "executing $cmd on server..."
ssh -i $key ${admin}@${ip} "sudo $cmd"
echo "--------------------------"  
echo "adding admin user '$admin' to group 'www-data' on server..."
ssh -i $key ${admin}@${ip} "sudo adduser $admin www-data"
if [ x"$grp" != x"www-data" ]; then
  echo "--------------------------"  
  echo "adding user 'www-data' to group '$grp' on server..."
  ssh -i $key ${admin}@${ip} "sudo adduser www-data $grp"
fi
echo "--------------------------"  
echo "reloading webserver (if applicable)..."
ssh -i $key ${admin}@${ip} "sudo service nginx reload 2>/dev/null"

#create user's keys
echo "--------------------------"
echo "Create user's ssh-keypair..."
echo "--------------------------"
if [ -f $ckey ]; then
  read -p "Create new keys ? [y/N]" yn
  if [ $(checkyn) == x"y" ]; then
    createuserkey 1
  else
    createuserkey 0
  fi
else
  echo "creating keys..."
  createuserkey 1
fi

#adapt templates
echo "--------------------------"
echo "Configure templates for user..."
echo "--------------------------"
read -p "Press enter to continue..."
$HOME/.shortcuts/template_config.sh $HOME/.shortcuts/template_push-to-cloud-tmp.sh
echo "uploading to server ($ip)..."
scp -i $ckey $HOME/.shortcuts/${device}push-to-cloud-tmp.sh ${user1}@${ip}:"\$HOME/$clidir/" && echo "...done."

#create cronjob
echo "--------------------------"
echo "Create cronjob on client..."
echo "--------------------------"
read -p "Create cronjob ? [Y/n]" yn
if [ $(checkyn) != x"n" ]; then
    touch $HOME/../usr/var/spool/cron/$(whoami) && cp $HOME/../usr/var/spool/cron/$(whoami) $tmpdir/t
    cmd="* * * * * \$HOME/.shortcuts/runscrpt.sh \$HOME/.shortcuts/${device}push-to-cloud-tmp.sh"
    echo "$cmd"
    read -p "Add above line to crontab ? [Y/n]" yn
    if [ $(checkyn) != x"n" ]; then
        echo "$cmd" >> $tmpdir/t
    fi
    cat $tmpdir/t | sort -u > $HOME/../usr/var/spool/cron/$(whoami)
    mkdir -p $HOME/../usr/var/spool/cron/crontabs && cp $HOME/../usr/var/spool/cron/$(whoami) $HOME/../usr/var/spool/cron/crontabs/ # for busybox compatibility
    echo "--------------------------"
    echo "current crontab:"
    crontab -l
fi
echo "--------------------------"
read -p "Autostart cron-daemon on login ? [Y/n]" yn
if [ $(checkyn) != x"n" ]; then
	cp -v $localinstall/bash_profile $HOME/.bash_profile
	echo ""
	echo "starting framework..."
	. $HOME/.bash_profile
fi

echo "--------------------------"
echo "Cleanup..."
echo "--------------------------"
read -p "Press enter to continue..."
remauth;
remkeys;

echo "--------------------------"
echo "...type 'exit' & restart Termux"
echo "(consider enabling 'WakeLock')."
echo "--------------------------"
end=$(date +%s) ; elapsed=$(echo "($end - $start)" |bc)
echo "$(basename $0) : finished. - $(date) ($elapsed sec elapsed)"
