# RaspiCloud
Simple script-based, Raspberry-Pi hosted cross-platform Cloud with tls/ssl-encrypted Web Interface.

## Features
  Syncs client directories automatically to private network access storage (NAS) with
  on-the-fly categorization of synced files (audio, video, documents and pictures)
  and thumbnail generation. Prints documents remotely via CUPS. Guest access possible.
  No 'rooting' of android devices is required.
- *lightweight:* based on *OpenSSH*, linux tools *rsync*, *cron* & bash scripts
- *secure:* using key-based encryption
- *convenient:* tls/ssl-encrypted web interface with instant search and image gallery functions for mobile browsing (see screenshots)
- *generic:* client-side linux environment available on many platforms, sftp-access supported by many file browsers (incl. Windows10 Explorer)
- *quick-install:* using command line script (~10 min)
- *low cost:* using Raspberry-Pi as server and standard USB drive as network access storage (NAS)

## Requirements
- linux server (tested with Raspian Stretch/Buster on a Raspberry Pi 3b+) 
- nginx web server (v1.10.3) and OpenSSH server (v7.4)
- CUPS server (v2.2.10) for remote printing
- NAS storage (tested with low cost 2.5 inch portbale, ext4-formatted USB-Harddisk attached to the Raspberry Pi)
- imagemagick (v6), libreoffice (v5) & ffmpeg (v3.2.14) for server-side thumbnail generation
- client requires termux (tested on android 7/8) or cygwin (windows) environment

  https://play.google.com/store/apps/details?id=com.termux  
  https://cygwin.com/
- a file manager with ssh support on the client (e.g. mxeplorer, solidexplorer and others under android support key-based authentication, see google playstore)
- a standard webbrowser on the client (e.g. firefox, opera, chrome)

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
- HTML / XSLT
- javascript & jquery
- bourne-shell

## Installation
### Install RaspiCloud Server:
  - Download and install Raspian for Raspberry Pi (see https://www.raspberrypi.org/downloads/raspbian)
  - Download and extract zipped project-repository in pi's home directory *(/home/pi)*, and mount USB harddisk 
    to *'/media/cloud-NAS'* (see https://www.raspberrypi.org/documentation/configuration/external-storage.md).

### Install RaspiCloud Client:
  **On Android Client:**
  - install Termux app (see google playstore).
  - open Termux console and install openssh:
  
    ```pkg install openssh```
  
  - copy install script from server:
  
    ```scp pi@IP-ADDRESS:RaspiCloud-master/install/install_client.sh $HOME/```
    
    ```chmod +x $HOME/install_client.sh```
  
  - execute it:
  
    ```./install_client.sh```
    
   
### Install Nginx Web Interface:
  **On Raspbian Server:**
  - open a terminal and make install-script executable:
  
    ```chmod +x ./RaspiCloud-master/websrv/install_nginx.sh```
  
  - execute it: 
    
    ```./RaspiCloud-master/websrv/install_nginx.sh```
  
  **On the Client:**  
  - go to *https://IP-ADDRESS/cloud/USER*, enter *USER*'s credentials and browse your cloud.

### Install CUPS:
  **On Raspbian Server:**
  - open a terminal and make install-script executable:
  
    ```chmod +x ./RaspiCloud-master/websrv/install_cups.sh```
  
  - execute it: 
    
    ```./RaspiCloud-master/websrv/install_cups.sh``` 
    
  - install printers using the CUPS-webinterface
  
  **On the Client:**  
  - install a cups printing service (e.g., CUPS Printing for android clients: https://play.google.com/store/apps/details?id=io.github.benoitduffez.cupsprint)

  
## Screenshots
<table>
<tr>
<td>Design and Layout inspired by <a href="https://gitlab.com/devCoster/BetterListing">BetterListing</a>.</td>
<td>Thumbnail view.</td>
<td>Gallery with Image Manipulation based on <a href="https://www.cssscript.com/css-only-minimal-responsive-image-gallery-lightbox-cssbox/">cssbox</a>.</td>
</tr>
<tr>
<td><img src="screenshot01.jpg" width="100%" </img></td>
<td><img src="screenshot02.jpg" width="97%" </img></td>
<td><img src="screenshot03.jpg" width="90%" </img></td>
</tr>
</table>

## Disclaimer
The material embodied in this software is provided to you "as-is" and without warranty of any kind, express, implied or otherwise, including 
without limitation, any warranty of fitness for a particular purpose. In no event shall the author be liable to you or anyone else for any 
direct, special, incidental, indirect or consequential damages of any kind, or any damages whatsoever, including without limitation,
loss of profit, loss of use, savings or revenue, or the claims of third parties, however caused and on any theory of liability, arising
out of or in connection with the possession, use or performance of this software.
