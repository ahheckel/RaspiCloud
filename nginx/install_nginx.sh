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
function savfile {
  local file="$1"
  if [ -f "$file" ]; then
    read -p "$(basename $0) : $file already exists - save file ? [Y/n]" yn
    if [ $(checkyn) != x"n" ]; then
      sudo cp -v "$file" "$file".raspicloud$$.sav
    fi
  fi
}
function parentpath {
  cd $(dirname $0)/..
  echo $(pwd)
  cd - 1>/dev/null # go back
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
echo "--------------------------"
echo "Define inputs..."
echo "--------------------------"
read -e -p "install source:          "  -i "$(parentpath)/nginx" installdir
read -e -p "web-root directory:      "  -i "/var/www/html" webroot
read -e -p "xslt storage:            "  -i "$installdir/xslt" xsltpath
read -e -p "NAS storage mountpoint:  "  -i "/media/cloud-NAS" nasdir
read -e -p "allowed ip-range:        "  -i "$(getownip | cut -d . -f 1-3).0/24" iprange
mkdir $installdir/htpasswd
mkdir $installdir/ssl
htpasswd_pref="$installdir/htpasswd/.htpasswd" #prefix filename
ssl_pref="$installdir/ssl/nginx" #prefix filename

echo "--------------------------"
echo "Install..."
echo "--------------------------"
read -p "Install apt packages? [Y/n]" yn
if [ $(checkyn) != x"n" ]; then
  sudo apt-get install nginx openssl apache2-utils imagemagick libreoffice
fi
read -p "Install webinterface? [Y/n]" yn
if [ $(checkyn) != x"n" ]; then
  sudo ln -sfn  $nasdir $webroot/cloud
  sudo ln -sfn  $webroot/cloud $webroot/.cloud01
  sudo ln -sfn  $webroot/cloud $webroot/.cloud02
  sudo ln -sfn  $webroot/cloud $webroot/.cloud03
  sudo rsync -r $installdir/webroot/cloud/ $webroot/cloud/
  sudo ln -sfn /etc/nginx/nginx.conf $installdir/nginx.conf
fi

echo "--------------------------"
echo "Adapt available sites ('default' file)..."
echo "--------------------------"
sudo cat $installdir/sites-available/default_template | sed -e "s|XXX.XXX.XXX.XXX/XX|$iprange|g" | sed -e "s|PPPPPPPPPP|$xsltpath|g" | sed -e "s|CCCCCCCCCC|$htpasswd_pref|g" | sed -e "s|SSSSSSSSSS|$ssl_pref|g" | sed -e "s|RRRRRRRRRR|$webroot|g" > $tmpdir/default
savfile /etc/nginx/sites-available/default
if [ -f /etc/nginx/sites-available/default.raspicloud$$.sav ]; then
  sudo ln -sfn /etc/nginx/sites-available/default.raspicloud$$.sav $installdir/sites-available/default.raspicloud$$.sav 
fi
sudo mv $tmpdir/default /etc/nginx/sites-available/default && sudo chmod 644 /etc/nginx/sites-available/default
sudo ln -sfn /etc/nginx/sites-available/default $installdir/sites-available/default

echo "--------------------------"
echo "Create encrypted password for web access..."
echo "--------------------------"
read -p "Create password ? [Y/n]" yn
if [ $(checkyn) != x"n" ]; then
  savfile $htpasswd_pref
  read -e -p "user: "  -i "webmaster" user
  sudo htpasswd -c $htpasswd_pref $user
fi

echo "--------------------------"
echo "Create ssl-certificate..."
echo "--------------------------"
read -p "Create certificate ? [Y/n]" yn
if [ $(checkyn) != x"n" ]; then
  savfile ${ssl_pref}.key
  savfile ${ssl_pref}.crt
  sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${ssl_pref}.key -out ${ssl_pref}.crt
fi

echo "--------------------------"
echo "Restarting nginx..."
echo "--------------------------"
sudo service nginx restart

echo "--------------------------"
end=$(date +%s) ; elapsed=$(echo "($end - $start)" |bc)
echo "$(basename $0) : finished. - $(date) ($elapsed sec elapsed)"
