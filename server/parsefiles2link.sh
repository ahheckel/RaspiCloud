#!/bin/bash
if [ -f $HOME/.$(basename $0).lock ] ; then echo "$(basename $0) : An instance is already running - exiting." ; exit 9 ; fi
start=$(date +%s)
tmpdir=$(mktemp -d -t $(basename $0)-XXXXXXXXXX)
wdir="$(pwd)"
function finish {
	    rm -rf $tmpdir
	    rm -f $HOME/.$(basename $0).lock
	    cd "$wdir"
}
trap finish EXIT SIGHUP SIGINT SIGQUIT SIGTERM 
touch $HOME/.$(basename $0).lock

IFSbak="$IFS"
IFS="
"

function issameinode () {
      if [ ! -f "$1" ] ; then
	    echo "0";
      elif [ $(stat -c %i "$1") -eq $(stat -c %i "$2") ] ; then
	    echo "1";
      else
	    echo "0";
      fi
}

# parse input
if [ x"$1" == "x" ] ; then
      echo "$(basename $0) : no directory name given... exiting."
else
      dir="$1"
fi
if [ ! -d "$dir" ] ; then
      echo "$(basename $0) : '$dir' does not exist... exiting."
      exit 1
fi
shift
if [ x"$1" == "x" ] ; then
      doall=1;
      cd $dir
      find ./ -maxdepth 1 -type f | cut -d / -f 2- > $tmpdir/list
else
      doall=0;
      if [ ! -f "$1" ] ; then
	    echo "$(basename $0) : file '$1' does not exist... exiting."
	    exit 1
      fi
      cat "$1" > $tmpdir/list
fi
shift
# end parse inputs

mkdir -p $dir/.thumbs
mkdir -p $dir/auds && ln -sf ../.thumbs $dir/auds
mkdir -p $dir/docs && ln -sf ../.thumbs $dir/docs
mkdir -p $dir/pics && ln -sf ../.thumbs $dir/pics
mkdir -p $dir/vids && ln -sf ../.thumbs $dir/vids

cd $dir
for i in $(cat $tmpdir/list) ; do 
      fullfile="$i"
      ext="${i##*.}"
      ext="$(echo $ext | tr '[:upper:]' '[:lower:]')"
      
      categ="auds"
      _dir="$dir/$categ"
      find ${_dir} -maxdepth 1 -type f -printf '%i\n' > $tmpdir/${categ}.inode
      for j in mp3 ogg oga mogg wma pcm flac m4a m4b m4p ; do
	    if [ x"$ext" = "x${j}" ] ; then		  
		  echo "$i" >> $tmpdir/${categ}
		  inode=$(stat -c %i "$i")		  
		  if [ -f "$_dir/$i" ] && [ $inode -eq $(stat -c %i "$_dir/$i") ] ; then 
			continue		  
		  elif [ ! -f "$_dir/$i" ] && [ $(cat $tmpdir/${categ}.inode | grep $inode | wc -l) -ne 0 ] ; then
			continue
		  else
			ln -vf "$i" "$_dir" ;	
		  fi
	    fi
      done

      categ="docs"
      _dir="$dir/$categ"
      find ${_dir} -maxdepth 1 -type f -printf '%i\n' > $tmpdir/${categ}.inode
      for j in pdf doc docx htm html odt xls xlsx ods ppt pptx txt pps ppsx ; do
	    if [ x"$ext" = "x${j}" ] ; then		  
		  echo "$i" >> $tmpdir/${categ}
		  inode=$(stat -c %i "$i")		  
		  if [ -f "$_dir/$i" ] && [ $inode -eq $(stat -c %i "$_dir/$i") ] ; then 
			continue		  
		  elif [ ! -f "$_dir/$i" ] && [ $(cat $tmpdir/${categ}.inode | grep $inode | wc -l) -ne 0 ] ; then
			continue
		  else
			ln -vf "$i" "$_dir" ;
			$HOME/create_thumbs.sh "$i"
		  fi
	    fi
      done

      categ="pics"
      _dir="$dir/$categ"
      find ${_dir} -maxdepth 1 -type f -printf '%i\n' > $tmpdir/${categ}.inode
      for j in  jpeg jpg png gif webp tif tiff psd bmp ; do
	    if [ x"$ext" = "x${j}" ] ; then		  
		  echo "$i" >> $tmpdir/${categ}
		  inode=$(stat -c %i "$i")		  
		  if [ -f "$_dir/$i" ] && [ $inode -eq $(stat -c %i "$_dir/$i") ] ; then 
			continue		  
		  elif [ ! -f "$_dir/$i" ] && [ $(cat $tmpdir/${categ}.inode | grep $inode | wc -l) -ne 0 ] ; then
			continue
		  else
			ln -vf "$i" "$_dir" ;	
			$HOME/create_thumbs.sh "$i"
		  fi
	    fi
      done
      
      categ="vids"
      _dir="$dir/$categ"
      find ${_dir} -maxdepth 1 -type f -printf '%i\n' > $tmpdir/${categ}.inode
      for j in  mp4 mov m4v f4v f4a m4r f4b 3gp ogx ogv wmv asf webm flv avi vob TS ts swf ; do
	    if [ x"$ext" = "x${j}" ] ; then		  
		  echo "$i" >> $tmpdir/${categ}
		  inode=$(stat -c %i "$i")		  
		  if [ -f "$_dir/$i" ] && [ $inode -eq $(stat -c %i "$_dir/$i") ] ; then 
			continue		  
		  elif [ ! -f "$_dir/$i" ] && [ $(cat $tmpdir/${categ}.inode | grep $inode | wc -l) -ne 0 ] ; then
			continue
		  else
			ln -vf "$i" "$_dir" ;	
		  fi
	    fi
      done
done

# sync subfolders with root
if [ $doall -eq 1 ] ; then
      find $dir/ -maxdepth 1 -type f -printf '%i\n' > $tmpdir/root.inode
      #for i in auds docs pics vids ; do # auds is left out because it contains files not present in root
      for i in docs pics vids ; do
	    cd $dir/${i}
	    find ./ -maxdepth 1 -type f | cut -d / -f 2- >> $tmpdir/${i}
	    #cat $tmpdir/${i} | sort | uniq -u > $tmpdir/${i}.unique
	    for j in $(cat $tmpdir/${i}) ; do
		  # check if same filename in root
		  if [ -f "$dir/$j" ] ; then continue ; fi
		  # check if same inode in root
		  inode=$(stat -c %i "$dir/$i/$j") 
		  if [ $(cat $tmpdir/root.inode | grep $inode | wc -l) -eq 0 ] ; then
			echo "deleting deprecated link ./${i}/${j}"
			cd $dir/${i} && rm -f $j
		  fi
	    done
      done
fi
# sync .thumbs folder with parentdir (and vice versa)
if [ $doall -eq 1 ] ; then
      for i in $dir ; do
	    if [ ! -d $i/.thumbs ] ; then continue ; fi
	    find $i/.thumbs -maxdepth 1 -type f > $tmpdir/list
	    for j in  $(cat $tmpdir/list) ; do
		  fname=$(basename $j)
		  if [ -f $i/$fname ] ; then 
			continue
		  else
			echo "deleting deprecated thumbnail ${i}/.thumbs/${fname}"
			rm -f $i/.thumbs/$fname
		  fi
	    done
	    find $i -maxdepth 1 -type f > $tmpdir/list
	    for j in  $(cat $tmpdir/list) ; do
		  fname=$(basename $j)
		  if [ -f $i/.thumbs/$fname ] ; then 
			continue
		  else
			$HOME/create_thumbs.sh "${i}/${fname}"
		  fi
	    done
      done
fi

#for sorting purposes
if [ -d $dir/timelapse ] ; then touch -d "8 seconds ago" $dir/timelapse ; fi
if [ -d $dir/vids ] ; then touch -d "6 seconds ago" $dir/vids ; fi
if [ -d $dir/pics ] ; then touch -d "4 seconds ago" $dir/pics ; fi
if [ -d $dir/gps ] ;  then touch -d "3 seconds ago" $dir/gps  ; fi
if [ -d $dir/docs ] ; then touch -d "2 seconds ago" $dir/docs ; fi
if [ -d $dir/auds ] ; then touch $dir/auds ; fi

cd "$wdir"

end=$(date +%s) ; elapsed=$(echo "($end - $start)" |bc)
echo "$(basename $0) : finished. - $(date) ($elapsed sec elapsed)"
