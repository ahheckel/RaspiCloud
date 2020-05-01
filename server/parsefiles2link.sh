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

# absolute path of current script
SCRPTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"; SCRPTPATH="$(dirname $SCRPTPATH)"

function issameinode () {
      if [ ! -f "$1" ] ; then
	      echo "0";
      elif [ $(stat -c %i "$1") -eq $(stat -c %i "$2") ] ; then
	      echo "1";
      else
	      echo "0";
      fi
}
function checkmd5dir () {
      if [[ $1 =~ ^\.[a-f0-9]{32}$ ]] ; then echo 1 ; else echo 0 ; fi
}

# parse input
if [ x"$1" == "x" ] ; then
      echo "$(basename $0) : no directory name given... exiting."
      exit 1
else
      if [ $(echo "$1" | grep ^/ | wc -l) -eq 0 ] ; then
        echo "$(basename $0) : please enter absolute dir-path... exiting."
        exit 1
      fi
      dir="$1"
fi
if [ ! -d "$dir" ] ; then
      echo "$(basename $0) : '$dir' does not exist... exiting."
      exit 1
fi
shift
if [ x"$1" == "x" ] ; then
      clean=1; mode=1
      cd $dir ; dir="$(pwd)" ; find ./ -maxdepth 1 -type f | cut -d / -f 2- > $tmpdir/list
else
      if [ x"$1" == "x0" ] ; then
        mode=0; clean=1;
      elif [ x"$1" == "x-mkconsistent" ] ; then
        mode=99; clean=1;
      elif [ ! -f "$1" ] ; then
        echo "$(basename $0) : file '$1' does not exist... exiting."
        exit 1
      elif [ $(checkmd5dir $(basename "$dir")) -eq 1 ] ; then
        mode=2; clean=0; cat "$1" > $tmpdir/list
      else
        mode=1; clean=0; cat "$1" > $tmpdir/list
      fi
fi
shift

# begin script
if [ $mode -eq 0 ] ; then
  find $dir/ -maxdepth 1 -type f -printf '%i\n' > $tmpdir/root.inode
  touch $tmpdir/_list
  for i in $(find $dir -maxdepth 1 -type d) ; do
    dname=$(basename "$i")
    if [ $(checkmd5dir "$dname") -eq 1 ] ; then
      cd "$i"
      find ./ -maxdepth 1 -type f | cut -d / -f 2- > $tmpdir/$dname
      for j in $(cat $tmpdir/$dname) ; do
        inode=$(stat -c %i "$j") 
        if [ $(cat $tmpdir/root.inode | grep $inode | wc -l) -eq 0 ] ; then
          fn="${j%.*}" ; ext="${j##*.}"
          f="${fn}_$(echo $dname | cut -d . -f 2- | cut -c -5).${ext}"
          ln -vf "$j" "../${f}" && echo "$f" >> $tmpdir/_list
        fi
      done
      cd "$dir"
    fi
  done
  mv $tmpdir/_list $tmpdir/list
  cat $tmpdir/list
fi

if [ $mode -eq 2 ] ; then
  find "$(dirname $dir)" -maxdepth 1 -type f -printf '%i\n' > $tmpdir/root.inode
  touch $tmpdir/_list
  dname=$(basename "$dir")
  cd $dir
  for j in $(cat $tmpdir/list) ; do
    inode=$(stat -c %i "$j") 
    if [ $(cat $tmpdir/root.inode | grep $inode | wc -l) -eq 0 ] ; then
      fn="${j%.*}" ; ext="${j##*.}"
      f="${fn}_$(echo $dname | cut -d . -f 2- | cut -c -5).${ext}"
      ln -vf "$j" "../${f}" && echo "$f" >> $tmpdir/_list
    fi
  done
  mv $tmpdir/_list $tmpdir/list
fi

if [ $mode -eq 1 ] || [ $mode -eq 2 ] || [ $mode -eq 0 ] ; then
  if [ $mode -eq 2 ] ; then
    dir="$(dirname $dir)"
  fi
  mkdir -p $dir/.thumbs
  mkdir -p $dir/auds && ln -sf ../.thumbs $dir/auds
  mkdir -p $dir/docs && ln -sf ../.thumbs $dir/docs
  mkdir -p $dir/pics && ln -sf ../.thumbs $dir/pics
  mkdir -p $dir/vids && ln -sf ../.thumbs $dir/vids
  mkdir -p $dir/.recent && ln -sf ../.thumbs $dir/.recent

  cd $dir
  for i in $(cat $tmpdir/list) ; do 
        fullfile="$i"
        ext="${i##*.}"
        ext="$(echo $ext | tr '[:upper:]' '[:lower:]')"
        
        categ="auds"
        _dir="$dir/$categ"
        find ${_dir} -maxdepth 1 -type f -printf '%i\n' > $tmpdir/${categ}.inode
        # <!-- ENTRY01 -->
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
        # <!-- ENTRY02 -->
        for j in pdf doc docx htm html odt xls xlsx ods ppt pptx txt pps ppsx odt ; do
          if [ x"$ext" = "x${j}" ] ; then		  
            echo "$i" >> $tmpdir/${categ}
            inode=$(stat -c %i "$i")		  
            if [ -f "$_dir/$i" ] && [ $inode -eq $(stat -c %i "$_dir/$i") ] ; then 
              continue		  
            elif [ ! -f "$_dir/$i" ] && [ $(cat $tmpdir/${categ}.inode | grep $inode | wc -l) -ne 0 ] ; then
              continue
            else
              ln -vf "$i" "$_dir" ;
              $SCRPTPATH/create_thumbs.sh "$i"
            fi
          fi
        done

        categ="pics"
        _dir="$dir/$categ"
        find ${_dir} -maxdepth 1 -type f -printf '%i\n' > $tmpdir/${categ}.inode
        # <!-- ENTRY03 -->
        for j in  jpeg jpg png gif webp tif tiff psd bmp jfif ; do
          if [ x"$ext" = "x${j}" ] ; then		  
            echo "$i" >> $tmpdir/${categ}
            inode=$(stat -c %i "$i")		  
            if [ -f "$_dir/$i" ] && [ $inode -eq $(stat -c %i "$_dir/$i") ] ; then 
              continue		  
            elif [ ! -f "$_dir/$i" ] && [ $(cat $tmpdir/${categ}.inode | grep $inode | wc -l) -ne 0 ] ; then
              continue
            else
              ln -vf "$i" "$_dir" ;	
              $SCRPTPATH/create_thumbs.sh "$i"
            fi
          fi
        done
        
        categ="vids"
        _dir="$dir/$categ"
        find ${_dir} -maxdepth 1 -type f -printf '%i\n' > $tmpdir/${categ}.inode
        # <!-- ENTRY04 -->
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
              $SCRPTPATH/create_thumbs.sh "$i"
            fi
          fi
        done
        
        categ=".recent"
        _dir="$dir/$categ"
        ftime=$(stat -c %Y "$i")
        ddays=$(( (start - ftime) / 86400 ))
        # link only recent files, newer than e.g. 15 days
        if [ $ddays -le 15 ] ; then 
          ln -svf "../$i" "$_dir"
        else
          rm -f "$_dir/$i"
        fi
        
  done
fi

if [ $clean -eq 1 ] ; then
  find $dir/ -maxdepth 1 -type f -printf '%i\n' > $tmpdir/root.inode
fi

# sync md5 subfolders with root
if [ $clean -eq 1 ] ; then
  for i in $(find $dir -maxdepth 1 -type d) ; do
    if [ $(checkmd5dir $(basename "$i")) -eq 1 ] ; then
      echo cd to $dir/$(basename "$i")
      cd "$i"
      find ./ -maxdepth 1 -type f | cut -d / -f 2- > $tmpdir/$(basename "$i")
      for j in $(cat $tmpdir/$(basename $i)) ; do
        inode=$(stat -c %i "$j") 
        #echo "$j"
        #echo $inode
        if [ $(cat $tmpdir/root.inode | grep $inode | wc -l) -eq 0 ] ; then
          echo "deleting deprecated link ./${i}/${j}"
          rm -f "$j"
        fi
      done
      cd "$dir"
    fi
  done
fi
 
# sync subfolders with root
if [ $clean -eq 1 ] ; then
  #find $dir/ -maxdepth 1 -type f -printf '%i\n' > $tmpdir/root.inode
  #for i in auds docs pics vids ; do # auds is left out because it contains files not present in root
  for i in docs pics vids ; do
    if [ ! -d $dir/${i} ] ; then continue ; fi
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
if [ $clean -eq 1 ] ; then
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
        $SCRPTPATH/create_thumbs.sh "${i}/${fname}"
      fi
    done
  done
fi

#delete broken symlinks
if [ $clean -eq 1 ] ; then
    if [ -d $dir/.recent ] ; then
      find -L $dir/.recent -maxdepth 1 -type l -delete
    fi
fi

#for sorting purposes
if [ -d $dir/vids ] ; then touch -d "6 seconds ago" $dir/vids ; fi
if [ -d $dir/pics ] ; then touch -d "4 seconds ago" $dir/pics ; fi
if [ -d $dir/docs ] ; then touch -d "2 seconds ago" $dir/docs ; fi
if [ -d $dir/auds ] ; then touch $dir/auds ; fi

cd "$wdir"

end=$(date +%s) ; elapsed=$(echo "($end - $start)" |bc)
echo "$(basename $0) : finished. - $(date) ($elapsed sec elapsed)"
