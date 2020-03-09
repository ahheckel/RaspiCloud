#!/bin/bash

if [ -f $HOME/.$(basename $0).lock ] ; then echo "$(basename $0) : An instance is already running - exiting." ; exit 9 ; fi
start=$(date +%s)
tmpdir=$(mktemp -d -t $(basename $0)-XXXXXXXXXX)
wdir="$(pwd)"
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
echo "Install packages..."
echo "--------------------------"
read -p "Press enter to continue..."
sudo apt-get install nginx openssl apache2-utils imagemagick libreoffice

echo "--------------------------"
echo "Install web interface..."
echo "--------------------------"
read -e -p "install source:          "  -i "$HOME/RaspiCloud-master/nginx" installdir
read -e -p "web-root directory:      "  -i "/var/www/html" webroot
read -e -p "NAS storage directory:   "  -i "/media/cloud-NAS" nasdir
read -e -p "allowed ip-range:        "  -i "172.16.0.0/24" iprange
read -e -p "xslt storage:            "  -i "$installdir/xslt" xsltpath
sudo ln -sfnv $nasdir $webroot/cloud
sudo ln -sfnv  $webroot/cloud $webroot/.cloud01
sudo ln -sfnv  $webroot/cloud $webroot/.cloud02
sudo ln -sfnv  $webroot/cloud $webroot/.cloud03
sudo rsync -rv $installdir/web-root/cloud/ $webroot/cloud/
sudo cat $installdir/sites-available/default | sed -e "s|XXX.XXX.XXX.XXX/XX|$iprange|g" | sed -e "s|PPPPPPPPPP|$xsltpath|g" > $tmpdir/default
sudo mv $tmpdir/default /etc/nginx/sites-available/default && sudo chmod 644 /etc/nginx/sites-available/default

echo "--------------------------"
echo "Create encrypted password for web access..."
echo "--------------------------"
read -p "Create password ? [Y/n]" yn
if [ x"$yn" != x"n" ]; then
  read -e -p "user: "  -i "johndoe" user
  sudo htpasswd -c /etc/nginx/.htpasswd $user
fi

echo "--------------------------"
echo "Create ssl-certificate..."
echo "--------------------------"
read -p "Create certificate ? [Y/n]" yn
if [ x"$yn" != x"n" ]; then
  sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/nginx.key -out /etc/nginx/nginx.crt
fi

echo "--------------------------"
echo "Restarting nginx..."
echo "--------------------------"
sudo service nginx restart

echo "--------------------------"
end=$(date +%s) ; elapsed=$(echo "($end - $start)" |bc)
echo "$(basename $0) : finished. - $(date) ($elapsed sec elapsed)"
