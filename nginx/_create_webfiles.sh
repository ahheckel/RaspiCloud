#!/bin/bash
start=$(date +%s)
tmpdir=$(mktemp -d -t $(basename $0)-XXXXXXXXXX)
wdir="$(pwd)"
function finish {
	    rm -rf $tmpdir
	    cd "$wdir"
}
trap finish EXIT SIGHUP SIGINT SIGQUIT SIGTERM 
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

#get folder of this script
cd $(dirname $0)/
wdir0=$(pwd)
cd - 1>/dev/null

webroot="$1"
xsltdir="$wdir0/xslt"
orig_xsl="$xsltdir/template.xslt"
orig_js="$wdir0/webroot/cloud/.custom.js"
if [ "$#" -ne 1 ]; then
  echo "$(basename $0) : ilegal number of parameters - exiting..." ; exit 1
fi
if [ ! -d $xsltdir ] ; then
  echo "$(basename $0) : $xsltdir does not exist - exiting..." ; exit 1
fi
if [ ! -f $orig_xsl ] ; then
  echo "$(basename $0) : $orig_xsl does not exist - exiting..." ; exit 1
fi
if [ ! -d $webroot ] ; then
  echo "$(basename $0) : $webroot does not exist - exiting..." ; exit 1
fi
if [ ! -f $orig_js ] ; then
  echo "$(basename $0) : $orig_js does not exist - exiting..." ; exit 1
fi
users=$(ls -1p $webroot | grep /$ | rev | cut -c 2- | rev | grep -v guest)
echo "$(basename $0) : detected users for dropdown-list:"
for i in $users ; do echo "    $i" ; done

#custom.xslt
dest=$tmpdir/custom
cp $orig_xsl $dest
n=$(cat $dest | grep -n  \<\!--\ ENTRY03 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s|.*| <link href=\"/cloud/.custom.css\" rel=\"stylesheet\" type=\"text/css\" media=\"all\"/>|g" $dest
n=$(cat $dest | grep -n  \<\!--\ ENTRY04 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s|.*| <script src=\"/cloud/.custom.js\"></script>|g" $dest
#custom-guest.xslt
dest=$tmpdir/custom-guest
cp $orig_xsl $dest
n=$(cat $dest | grep -n  \<\!--\ ENTRY03 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s|.*| <link href=\"/cloud/guest/.custom.css\" rel=\"stylesheet\" type=\"text/css\" media=\"all\"/>|g" $dest
n=$(cat $dest | grep -n  \<\!--\ ENTRY04 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s|.*| <script src=\"/cloud/guest/.custom.js\"></script>|g" $dest
n=$(cat $dest | grep -n  \<\!--\ ENTRY06 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s|.*| <script src=\"/cloud/guest/.yall.min.js\"></script>|g" $dest
n=$(cat $dest | grep -n  \<\!--\ ENTRY07 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s|.*| <script src=\"/cloud/guest/.jquery.min.js\"></script>|g" $dest
#gal.xslt
dest=$tmpdir/gal
cp $orig_xsl $dest
n=$(cat $dest | grep -n  \<\!--\ ENTRY03 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s|.*| <link href=\"/cloud/.gal.css\" rel=\"stylesheet\" type=\"text/css\" media=\"all\"/>|g" $dest
n=$(cat $dest | grep -n  \<\!--\ ENTRY04 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s|.*| <script src=\"/cloud/.gal.js\"></script>|g" $dest
#custom.js
dest=$tmpdir/custom.js
cp $orig_js $dest
n=$(cat $dest | grep -n  \<\!--\ ENTRY01 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s|.*|var x = 0;|g" $dest
#gal.js
dest=$tmpdir/gal.js
cp $orig_js $dest
n=$(cat $dest | grep -n  \<\!--\ ENTRY01 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s|.*|var x = 1;|g" $dest

#xslt
      #01-guest
      orig=$tmpdir/custom-guest
      dest=$xsltdir/custom01-guest.xslt
      echo "$(basename $0) : creating $dest..."
      cp $orig $dest
      n=$(cat $dest | grep -n  \<\!--\ ENTRY01 | cut -d : -f 1)
      n=$[$n+1]
      sed -i "${n}s|.*|            <td class=\"header\" align=\"left\"><a class=\"high3\" href=\"/cloud/\" id=\"sortname\" style=\"color:#fff\">Name</a></td>|g" $dest
      n=$[$n+1]
      sed -i "${n}s|.*|            <td class=\"header\" align=\"left\"><a class=\"high3\" href=\"/cloud/\" id=\"sortsize\">Size</a></td>|g" $dest
      n=$[$n+1]
      sed -i "${n}s|.*|            <td class=\"header\" align=\"left\"><a class=\"high3\" href=\"/cloud/\" id=\"sortdate\">Date</a></td>|g" $dest
      n=$(cat $dest | grep -n  \<\!--\ ENTRY02 | cut -d : -f 1)
      n=$[$n+1]
      sed -i "${n}s|.*|        <xsl:sort order=\"ascending\" select=\"translate\(., 'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')\"/>|g" $dest
      sed -i "s|/cloud/.icons|/cloud/guest/.icons|g" $dest
      
      echo "--------------------------"

for file in custom gal ; do
      orig=$tmpdir/$file
      #01
      dest=$xsltdir/${file}01.xslt
      echo "$(basename $0) : creating $dest..."
      cp $orig $dest
      n=$(cat $dest | grep -n  \<\!--\ ENTRY01 | cut -d : -f 1)
      n=$[$n+1]
      sed -i "${n}s|.*|            <td class=\"header\" align=\"left\"><a class=\"high3\" href=\"/cloud/\" id=\"sortname\" style=\"color:#fff\">Name</a></td>|g" $dest
      n=$[$n+1]
      sed -i "${n}s|.*|            <td class=\"header\" align=\"left\"><a class=\"high3\" href=\"/cloud/\" id=\"sortsize\">Size</a></td>|g" $dest
      n=$[$n+1]
      sed -i "${n}s|.*|            <td class=\"header\" align=\"left\"><a class=\"high3\" href=\"/cloud/\" id=\"sortdate\">Date</a></td>|g" $dest
      n=$(cat $dest | grep -n  \<\!--\ ENTRY02 | cut -d : -f 1)
      n=$[$n+1]
      sed -i "${n}s|.*|        <xsl:sort order=\"ascending\" select=\"translate\(., 'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')\"/>|g" $dest
      #01 dropdown
      n=$(cat $dest | grep -n  \<\!--\ ENTRY05 | cut -d : -f 1)
      n=$[$n+1]
      sed -i "${n}i <a href=\"http://www.google.com\">Google</a>" $dest
      n=$[$n+1]
      sed -i "${n}i <p style=\"border-bottom: 4px solid #aa0\"></p>" $dest
      for user in $users ; do       
	  n=$[$n+1]
	  sed -i "${n}i <a href=\"/cloud/$user/tmp\">Cloud $user</a>" $dest
      done
      n=$[$n+1]
      sed -i "${n}i <p style=\"border-bottom: 4px solid #aa0\"></p>" $dest
      n=$[$n+1]
      sed -i "${n}i <a href=\"/cloud/guest\">Guest</a>" $dest
      #02
      dest=$xsltdir/${file}02.xslt
      echo "$(basename $0) : creating $dest..."
      cp $orig $dest
      n=$(cat $dest | grep -n  \<\!--\ ENTRY01 | cut -d : -f 1)
      n=$[$n+1]
      sed -i "${n}s|.*|            <td class=\"header\" align=\"left\"><a class=\"high3\" href=\"/cloud/\" id=\"sortname\">Name</a></td>|g" $dest
      n=$[$n+1]
      sed -i "${n}s|.*|            <td class=\"header\" align=\"left\"><a class=\"high3\" href=\"/cloud/\" id=\"sortsize\">Size</a></td>|g" $dest
      n=$[$n+1]
      sed -i "${n}s|.*|            <td class=\"header\" align=\"left\"><a class=\"high3\" href=\"/cloud/\" id=\"sortdate\" style=\"color:#fff\">Date</a></td>|g" $dest
      n=$(cat $dest | grep -n  \<\!--\ ENTRY02 | cut -d : -f 1)
      n=$[$n+1]
      sed -i "${n}s|.*|        <xsl:sort order=\"descending\" select=\"@mtime\"/>|g" $dest
      #02 dropdown
      n=$(cat $dest | grep -n  \<\!--\ ENTRY05 | cut -d : -f 1)
      n=$[$n+1]
      sed -i "${n}i <a href=\"http://www.google.com\">Google</a>" $dest
      n=$[$n+1]
      sed -i "${n}i <p style=\"border-bottom: 4px solid #aa0\"></p>" $dest
      for user in $users ; do       
	  n=$[$n+1]
	  sed -i "${n}i <a href=\"/cloud/$user/tmp\">Cloud $user</a>" $dest
      done
      n=$[$n+1]
      sed -i "${n}i <p style=\"border-bottom: 4px solid #aa0\"></p>" $dest
      n=$[$n+1]
      sed -i "${n}i <a href=\"/cloud/guest\">Guest</a>" $dest
      #03
      dest=$xsltdir/${file}03.xslt
      echo "$(basename $0) : creating $dest..."
      cp $orig $dest
      n=$(cat $dest | grep -n  \<\!--\ ENTRY01 | cut -d : -f 1)
      n=$[$n+1]
      sed -i "${n}s|.*|            <td class=\"header\" align=\"left\"><a class=\"high3\" href=\"/cloud/\" id=\"sortname\">Name</a></td>|g" $dest
      n=$[$n+1]
      sed -i "${n}s|.*|            <td class=\"header\" align=\"left\"><a class=\"high3\" href=\"/cloud/\" id=\"sortsize\" style=\"color:#fff\">Size</a></td>|g" $dest
      n=$[$n+1]
      sed -i "${n}s|.*|            <td class=\"header\" align=\"left\"><a class=\"high3\" href=\"/cloud/\" id=\"sortdate\">Date</a></td>|g" $dest
      n=$(cat $dest | grep -n  \<\!--\ ENTRY02 | cut -d : -f 1)
      n=$[$n+1]
      sed -i "${n}s|.*|        <xsl:sort order=\"descending\" select=\"@size\" data-type=\"number\"/>|g" $dest    
      #03 dropdown
      n=$(cat $dest | grep -n  \<\!--\ ENTRY05 | cut -d : -f 1)
      n=$[$n+1]
      sed -i "${n}i <a href=\"http://www.google.com\">Google</a>" $dest
      n=$[$n+1]
      sed -i "${n}i <p style=\"border-bottom: 4px solid #aa0\"></p>" $dest
      for user in $users ; do       
	  n=$[$n+1]
	  sed -i "${n}i <a href=\"/cloud/$user/tmp\">Cloud $user</a>" $dest
      done
      n=$[$n+1]
      sed -i "${n}i <p style=\"border-bottom: 4px solid #aa0\"></p>" $dest
      n=$[$n+1]
      sed -i "${n}i <a href=\"/cloud/guest\">Guest</a>" $dest
      
      cp $xsltdir/${file}02.xslt $xsltdir/${file}.xslt
done
      
      echo "--------------------------"
      
#js
      #gal.js
      orig=$tmpdir/custom.js
      dest=$(dirname $orig_js)/.custom.js
      echo "$(basename $0) : creating $dest..."
      cp $orig $dest
      
      orig=$tmpdir/gal.js
      dest=$(dirname $orig_js)/.gal.js
      echo "$(basename $0) : creating $dest..."
      cp $orig $dest


end=$(date +%s) ; elapsed=$(echo "($end - $start)" |bc)
echo "$(basename $0) : finished. - $(date) ($elapsed sec elapsed)"
