#!/bin/bash

if [ -f $HOME/.$(basename $0).lock ] ; then echo "$(basename $0) : An instance is already running - exiting." ; exit 9 ; fi
start=$(date +%s)
tmpdir=$(mktemp -d -t $(basename $0)-XXXXXXXXXX)
wdir="$(pwd)"
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
function currentpath {
  cd $(dirname $0)
  echo $(pwd)
  cd - 1>/dev/null # go back
}
function savfile {
  local file="$1"
  if [ -f "$file" ]; then
    read -p "$(basename $0) : $file already exists - save file ? [Y/n]" yn
    if [ $(checkyn) != x"n" ]; then
      sudo cp -v "$file" "$file".raspicloud$$.sav
    fi
  fi
}
function finish {
  rm -rf $tmpdir
  rm -f $HOME/.$(basename $0).lock
  cd "$wdir"
  echo "$(basename $0) : exited."
  exit
}
trap finish EXIT SIGHUP SIGINT SIGQUIT SIGTERM 
touch $HOME/.$(basename $0).lock

echo ""
echo "WARNING!"
echo "This is experimental software, which might damage your system."
echo "Please be careful!"
read -p "Press enter to continue or abort with CTRL-C."

echo ""
read -e -p "CUPS install dir:  "  -i "$(currentpath)/cups" srcdir
mkdir -p $srcdir
read -e -p "CUPS admin user:   "  -i "$(whoami)" admin
read -e -p "allowed ip-range:  "  -i "$(getownip | cut -d . -f 1-3).0/24" iprange

echo "--------------------------"
echo "CUPS: Install packages..."
echo "--------------------------"
sudo apt-get install cups usbutils
echo "--------------------------"
echo "CUPS: Create admin user..."
echo "--------------------------"
sudo adduser $admin
sudo adduser $admin lpadmin
echo "--------------------------"
echo "CUPS: Adapt config..."
echo "--------------------------"
conf=/etc/cups/cupsd.conf
orig=$conf
read -p "Adapt configuration in 'cupsd.conf' file ? [Y/n]" yn
if [ $(checkyn) != x"n" ]; then
  if [ ! -f $conf ] ; then
     echo "$conf does not exist - exiting..." ; exit 1
  fi
  savfile $conf

  dest=$tmpdir/conf
  echo "$(basename $0) : adapting $orig..."
  sudo cp $orig $dest && sudo chmod 777 $dest

  sed -i '/#inserted by RaspiCloud/d' $dest

  sed -i '/<Location\ \/>/,/<\/Location>/d' $dest
  sed -i "$ a #inserted by RaspiCloud" $dest
  sed -i "$ a \<Location\ /\>" $dest
  sed -i "$ a \ \ Order allow,deny" $dest
  sed -i "$ a \ \ Allow from $iprange" $dest
  sed -i "$ a \</Location\>" $dest

  sed -i '/<Location\ \/admin>/,/<\/Location>/d' $dest
  sed -i "$ a #inserted by RaspiCloud" $dest
  sed -i "$ a \<Location\ /admin>" $dest
  sed -i "$ a \ \ Order allow,deny" $dest
  sed -i "$ a \ \ Allow from $iprange" $dest
  sed -i "$ a \</Location\>" $dest

  sed -i '/Port 631/d' $dest
  sed -i "$ a #inserted by RaspiCloud" $dest
  sed -i "$ a Port 631" $dest

  sudo cp -v $dest $orig && sudo chmod 644 $orig
fi
# link conf/log-files
sudo ln -sfn $orig $srcdir/
if [ -f ${orig}.raspicloud$$.sav ]; then
        sudo ln -sfn ${orig}.raspicloud$$.sav $srcdir/
fi
mkdir -p $srcdir/log
sudo ln -sfn /var/log/cups/access_log $srcdir/log/
sudo ln -sfn /var/log/cups/error_log $srcdir/log/

echo "--------------------------"
echo "restarting CUPS..."
echo "--------------------------"
sudo service cups restart

end=$(date +%s) ; elapsed=$(echo "($end - $start)" |bc)
echo "$(basename $0) : finished. - $(date) ($elapsed sec elapsed)"
