# RaspiCloud
Simple script-based private cross-platform Cloud using Raspberry PI as server with ssl-encrypted web interface.

## Features
- *generic:* based on linux tools 'rsync', 'cron' and bash scripts
- *secure:* ssh-based file transfer (password protected or key-based)
- *convenient:* nginx ssl-encrypted web interface for convenient file browsing with image gallery functions
- *cross-platform:* requires client side linux environmen available on many platforms
- *low cost:* using raspberry-pi as server with standard USB storage as NAS 
- syncs clients automatically to cloud storage
- automatic thumbnail generation
- automatic categorization of synced files in audio, video, documents and pictures
- no rooting of android devices required

## Requirements
- client-side (android) requires termux or cygwin (windows)  
  https://play.google.com/store/apps/details?id=com.termux&hl=en  
  https://cygwin.com/
- linux server (tested with raspberry 3b+ on Raspian Stretch) with nginx web server and ssh client installed
- NAS storage (tested with low cost 2.5 inch portbale USB-Harddisk attached to the raspberry pi)
- imagemagick v6 and libreoffice v5 for thumbnail generation (server-side)
- a file manager for browsing with ssh support (e.g. mxeplorer, solidexplorer and others under android support ssh including key based authentication and are available on google playstore)
- a standard webbrowser on the client, e.g. firefox

## Dependencies
### Web Interface:
  - *yall* lazy image loader by malchata:
   https://github.com/giventofly/yall
    
  - *Faenza Icons* theme by tiheum:
   https://www.deviantart.com/tiheum/art/Faenza-Icons-173323228
   
  - *Cssbox* image-gallery by TheLastProject:
   https://www.cssscript.com/css-only-minimal-responsive-image-gallery-lightbox-cssbox/
   
  - *BetterListing* by DevCoster:
   https://gitlab.com/devCoster/BetterListing
   
   - *jquery v3.4.1*:
   https://jquery.com/download/
   
## Coding
geany v1.29 under Raspian Stretch
- HTML / XML
- jquery & javascript
- bourne-shell

## Installation
### Install Client:
  **Raspbian Server:** 
  - create directory for client-installation files under a privileged user's account (e.g., 'pi'):
  
    ```mkdir ~/client-install-files```
    
    Copy the files in ./server to ~/ and the files in ./client-install-files to ~/client-install-files.
    
  - copy private/public keys of privileged user to ~/client-install-files/ssh (and remove them after installation is finished).
  - create user for client: 
  
    ```sudo useradd user1```
  
  **Android Client:**
  - Install Termux app (see google playstore).
  - open Termux and install openssh:
  
    ```pkg install openssh```
  
  - copy install script from server:
  
    ```scp pi@172.16.0.10:client-install-files/install_client.sh $HOME/```
    
    ```chmod +x $HOME/install_client.sh```
  
  - execute it:
  
    ```./install_client.sh```
  
  - after that, create new ssh keypair for the user:
  
    ```ssh-keygen -t rsa -b 2048 -f id_rsa```
    
    and update authorized_keys on server.
   
### Nginx Web-Server with Interface:
  - install nginx, openssl and apache2-utils(for htpasswd):
    
    ```sudo apt-get install nginx openssl apache2-utils```
  - create self signed certificate for ssl encryption:
   
    ```sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt```
  - choose www-root-directory and link to NAS storage, e.g.
   
    ```ln -s /media/nas-storage /var/www/html/cloud```
  - copy .css, .js, .xsl(t), ... files to www-root/cloud
  - create user/password pair:
   
    ```sudo htpasswd -c /path/to/.htpasswd username```
  - adapt nginx 'default' configuration file in /etc/nginx/sites-available (see example file above)
  - restart nginx:
   
    ```sudo service nginx restart```

## Status
 alpha

