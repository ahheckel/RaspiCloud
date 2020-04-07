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
read -e -p "SQUID install directory:  "  -i "$(currentpath)/squid" srcdir
read -e -p "SQUID localnet ip-range:  "  -i "$(getownip | cut -d . -f 1-3).0/24" iprange
read -e -p "SQUID listening port:     "  -i "3128" port
read -e -p "SQUID cache memory:       "  -i "cache_mem 140 MB" cache_mem
read -e -p "SQUID ramdisk:            "  -i "cache_dir ufs /mnt/ramdisk 140 16 256" ramdisk

echo "--------------------------"
echo "SQUID: Install packages..."
echo "--------------------------"
sudo apt-get install squid
echo "--------------------------"
echo "SQUID: Adapt config..."
echo "--------------------------"
orig=/etc/squid/squid.conf
tmpl=$srcdir/squid_template.conf
read -p "Adapt configuration in 'squid.conf' file ? [Y/n]" yn
if [ $(checkyn) != x"n" ]; then
    if [ ! -f $tmpl ] ; then
        echo "$tmpl does not exist - exiting..." ; exit 1
    fi
    sudo cat $tmpl | sed -e "s|XXX.XXX.XXX.XXX/XX|$iprange|g" | sed -e "s|PPPPPPPPPP|$port|g" | sed -e "s|CCCCCCCCCC|$cache_mem|g" | sed -e "s|RRRRRRRRRR|$ramdisk|g"  > $tmpdir/conf
    savfile $orig
    if [ -f ${orig}.raspicloud$$.sav ]; then
        sudo ln -sfn ${orig}.raspicloud$$.sav $srcdir/
    fi
    sudo mv $tmpdir/conf $orig && sudo chmod 644 $orig
    sudo ln -sfn $orig $srcdir/
fi
# link log-files
sudo ln -sfn $orig $srcdir/squid.conf
mkdir -p $srcdir/log
sudo ln -sfn /var/log/squid/access.log $srcdir/log/
sudo ln -sfn /var/log/squid/cache.log $srcdir/log/

echo "--------------------------"
echo "reloading SQUID..."
echo "--------------------------"
sudo service squid start
sudo service squid reload

end=$(date +%s) ; elapsed=$(echo "($end - $start)" |bc)
echo "$(basename $0) : finished. - $(date) ($elapsed sec elapsed)"
