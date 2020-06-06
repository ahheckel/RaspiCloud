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
function currentpath {
  cd $(dirname $0)
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
read -e -p "RaspiCloud root dir:     "  -i "$(dirname $(currentpath))" raspiroot
read -e -p "nginx install source:    "  -i "$(currentpath)/nginx" installdir
read -e -p "xslt-files location:     "  -i "$installdir/xslt" xsltpath
read -e -p "web-root dir:            "  -i "/var/www/html" webroot
read -e -p "NAS storage directory:   "  -i "/media/cloud-NAS" nasdir
#read -e -p "NAS guest's directory:   "  -i "/media/cloud-NAS/guest" gstdstdir
gstdstdir="/media/cloud-NAS/guest"
read -e -p "allowed ip-range:        "  -i "$(getownip | cut -d . -f 1-3).0/24" iprange
read -e -p "ip-address of router:    "  -i "$(getownip | cut -d . -f 1-3).1" iprouter
htpasswd_pref="$installdir/htpasswd/.htpasswd" #prefix filename
ssl_pref="$installdir/ssl/nginx" #prefix filename
mkdir -p $installdir/htpasswd
mkdir -p $installdir/ssl
mkdir -p $installdir/log
sudo ln -sfn /var/log/nginx/error.log $installdir/log/error.log
sudo ln -sfn /var/log/nginx/access.log $installdir/log/access.log
sudo ln -sfn /etc/nginx/nginx.conf $installdir/nginx.conf

echo "--------------------------"
echo "Install..."
echo "--------------------------"
read -p "Install apt packages? [Y/n]" yn
if [ $(checkyn) != x"n" ]; then
  sudo apt-get install nginx openssl apache2-utils imagemagick libreoffice coreutils
fi
echo "--------------------------"
read -p "Install web-interface? [Y/n]" yn
if [ $(checkyn) != x"n" ]; then
  if [ ! -d $nasdir ]; then
    echo "$(basename $0) : '$nasdir' does not exist... exiting."; exit 1
  fi
  sudo ln -sfn  $nasdir $webroot/cloud
  sudo ln -sfn  $webroot/cloud $webroot/.cloud01
  sudo ln -sfn  $webroot/cloud $webroot/.cloud02
  sudo ln -sfn  $webroot/cloud $webroot/.cloud03
  chmod +x $raspiroot/server/update_cloud.sh
  $raspiroot/server/update_cloud.sh
  echo "--------------------------"
  chmod +x $(dirname $0)/_create_webfiles.sh
  $(dirname $0)/_create_webfiles.sh $webroot/cloud $iprouter
  sudo rsync -r --exclude='guest/' $installdir/webroot/cloud/ $webroot/cloud/
fi

#create cloud-dir & webinterface 4 guests
echo "--------------------------"
echo "Create guests' access..."
echo "--------------------------"
read -p "Create guests' access in '$gstdstdir' ? [Y/n]" yn
if [ $(checkyn) != x"n" ]; then
  if [ ! -d $nasdir ]; then
      echo "$(basename $0) : '$nasdir' does not exist... exiting."; exit 1
  fi
  echo "$(basename $0) : installing web-interface to '$gstdstdir'..."
  sudo ln -sfn  $nasdir $webroot/cloud
  sudo mkdir -p ${gstdstdir} && sudo chown $(whoami):www-data ${gstdstdir} && sudo chmod 777 ${gstdstdir}
  sudo rsync -r $installdir/webroot/cloud/guest/ ${gstdstdir}/  
fi

echo "--------------------------"
echo "Adapt available sites..."
echo "--------------------------"
read -p "Adapt configuration in 'default' file ? [Y/n]" yn
if [ $(checkyn) != x"n" ]; then
  sudo cat $installdir/sites-available/default_template | sed -e "s|XXX.XXX.XXX.XXX/XX|$iprange|g" | sed -e "s|PPPPPPPPPP|$xsltpath|g" | sed -e "s|CCCCCCCCCC|$htpasswd_pref|g" | sed -e "s|SSSSSSSSSS|$ssl_pref|g" | sed -e "s|RRRRRRRRRR|$webroot|g" > $tmpdir/default
  savfile /etc/nginx/sites-available/default
  if [ -f /etc/nginx/sites-available/default.raspicloud$$.sav ]; then
    sudo ln -sfn /etc/nginx/sites-available/default.raspicloud$$.sav $installdir/sites-available/default.raspicloud$$.sav 
  fi
  sudo mv $tmpdir/default /etc/nginx/sites-available/default && sudo chmod 644 /etc/nginx/sites-available/default
  sudo ln -sfn /etc/nginx/sites-available/default $installdir/sites-available/default
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
echo "Create encrypted password for web-access..."
echo "--------------------------"
read -p "Create user password ? [Y/n]" yn
if [ $(checkyn) != x"n" ]; then
  savfile $htpasswd_pref
  read -e -p "user: "  -i "webmaster" user
  sudo htpasswd -c $htpasswd_pref $user
fi
echo "--------------------------"
read -p "Create guest password ? [Y/n]" yn
if [ $(checkyn) != x"n" ]; then
  savfile ${htpasswd_pref}-guest
  read -e -p "user: "  -i "guest" guest
  sudo htpasswd -c ${htpasswd_pref}-guest $guest
fi

echo "--------------------------"
echo "Restarting nginx..."
echo "--------------------------"
sudo service nginx restart

echo ""
echo "--------------------------"
echo "Install common unix printing system (CUPS)..."
echo "--------------------------"
read -p "Install ? [Y/n]" yn
if [ $(checkyn) != x"n" ]; then
  chmod +x $(dirname $0)/install_cups.sh
  $(dirname $0)/install_cups.sh
fi

echo ""
echo "--------------------------"
echo "Install SQUID server..."
echo "--------------------------"
read -p "Install ? [Y/n]" yn
if [ $(checkyn) != x"n" ]; then
  chmod +x $(dirname $0)/install_squid.sh
  $(dirname $0)/install_squid.sh
fi

echo ""
echo "--------------------------"
echo "Install PiHole..."
echo "--------------------------"
read -p "Install ? [Y/n]" yn
if [ $(checkyn) != x"n" ]; then
  chmod +x $(dirname $0)/install_pihole.sh
  $(dirname $0)/install_pihole.sh
fi

echo "--------------------------"
end=$(date +%s) ; elapsed=$(echo "($end - $start)" |bc)
echo "$(basename $0) : finished. - $(date) ($elapsed sec elapsed)"
