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

orig="$1"
destdir="$2"
webroot="$3"
if [ "$#" -ne 3 ]; then
  echo "$(basename $0) : ilegal number of parameters - exiting..." ; exit 1
fi
if [ ! -f $orig ] ; then
  echo "$(basename $0) : $orig does not exist - exiting..." ; exit 1
fi
if [ ! -d $destdir ] ; then
  echo "$(basename $0) : $destdir does not exist - exiting..." ; exit 1
fi
if [ ! -d $webroot ] ; then
  echo "$(basename $0) : $webroot does not exist - exiting..." ; exit 1
fi
users=$(ls -1p $webroot | grep /$ | rev | cut -c 2- | rev | grep -v guest)

#custom
dest=$tmpdir/custom
cp $orig $dest
n=$(cat $dest | grep -n  \<\!--\ ENTRY03 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s|.*| <link href=\"/cloud/.custom.css\" rel=\"stylesheet\" type=\"text/css\" media=\"all\"/>|g" $dest
n=$(cat $dest | grep -n  \<\!--\ ENTRY04 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s|.*| <script src=\"/cloud/.custom.js\"></script>|g" $dest
#gal
dest=$tmpdir/gal
cp $orig $dest
n=$(cat $dest | grep -n  \<\!--\ ENTRY03 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s|.*| <link href=\"/cloud/.gal.css\" rel=\"stylesheet\" type=\"text/css\" media=\"all\"/>|g" $dest
n=$(cat $dest | grep -n  \<\!--\ ENTRY04 | cut -d : -f 1)
n=$[$n+1]
sed -i "${n}s|.*| <script src=\"/cloud/.gal.js\"></script>|g" $dest

for file in custom gal ; do
      orig=$tmpdir/$file
      #01
      dest=$destdir/${file}01.xslt
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
      
      #02
      dest=$destdir/${file}02.xslt
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
      
      #03
      dest=$destdir/${file}03.xslt
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
      
      cp $destdir/${file}02.xslt $destdir/${file}.xslt
done

end=$(date +%s) ; elapsed=$(echo "($end - $start)" |bc)
echo "$(basename $0) : finished. - $(date) ($elapsed sec elapsed)"
