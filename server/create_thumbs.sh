#!/bin/bash
start=$(date +%s)
tmpdir=$(mktemp -d -t $(basename $0)-XXXXXXXXXX)
wdir="$(pwd)"
function finish {
	    rm -rf $tmpdir
	    rm -f $HOME/.$(basename $0).lock
	    cd "$wdir"
}
trap finish EXIT SIGHUP SIGINT SIGQUIT SIGTERM 
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

# parse inputs
f="$1"
if [ ! -f $f ] || [ x"$f" == "x" ] ; then 
	echo "$(basename $0) : no file (exists) - exiting..."
    exit 1
fi
shift
res_img="$1" ; if [ x"$res_img" == "x" ] ; then res_img=300 ; fi
shift
res_pdf="$1" ; if [ x"$res_pdf" == "x" ] ; then res_pdf=1000 ; fi
shift
ow="$1" ; if [ x"$ow" == "x" ] ; then ow=1 ; fi # overwrite ?

# define vars
file=$(basename "$f")
dirn=$(dirname "$f")
ext="${file##*.}" ; ext="$(echo $ext | tr '[:upper:]' '[:lower:]')"
img=0

# check thumb directory
if [ ! -d $dirn/.thumbs ] ; then 
	mkdir -p $dirn/.thumbs
fi

# convert
for j in jpeg jpg png gif webp tif tiff psd bmp pdf doc ppt xls docx pptx xlsx txt pps ppsx jfif odt ; do # because of libreoffice convert bug
#for j in jpeg jpg png gif webp tif tiff psd bmp pdf jfif ; do
	if [ x"$ext" == "x${j}" ] ; then
		echo "$(basename $0) : creating thumbnail for ${dirn}/${file}..."
		if [ ${j} == "pdf" ] ; then
			if [ -f ${dirn}/.thumbs/${file} ] ; then
				if [ $ow -eq 1 ] ; then
					#convert -thumbnail x${res_pdf} -background white -alpha remove :${dirn}/${file}[0] ${dirn}/.thumbs/${file}.jpg && mv ${dirn}/.thumbs/${file}.jpg ${dirn}/.thumbs/${file}; # the colon before the filename is necessary, otw. command fails if filename contains a colon...
					convert -thumbnail x${res_pdf} -background white -alpha remove ${dirn}/${file}[0] ${dirn}/.thumbs/${file}.jpg && mv ${dirn}/.thumbs/${file}.jpg ${dirn}/.thumbs/${file}; # under raspbian buster, the colon leads to error
				else
					echo "$(basename $0) : thumbnail for ${dirn}/${file} already exists - is not overwritten..."
				fi
			else
				#convert -thumbnail x${res_pdf} -background white -alpha remove :${dirn}/${file}[0] ${dirn}/.thumbs/${file}.jpg && mv ${dirn}/.thumbs/${file}.jpg ${dirn}/.thumbs/${file}; # the colon before the filename is necessary, otw. command fails if filename contains a colon...
				convert -thumbnail x${res_pdf} -background white -alpha remove ${dirn}/${file}[0] ${dirn}/.thumbs/${file}.jpg && mv ${dirn}/.thumbs/${file}.jpg ${dirn}/.thumbs/${file}; # under raspbian buster, the colon leads to error
			fi
		elif [ ${j} == "doc" ] || [ ${j} == "ppt" ] || [ ${j} == "xls" ] || [ ${j} == "docx" ] || [ ${j} == "pptx" ] || [ ${j} == "xlsx" ] || [ ${j} == "txt" ] || [ ${j} == "pps" ] || [ ${j} == "ppsx" ] || [ ${j} == "odt" ] ; then
				if [ -f ${dirn}/.thumbs/${file} ] ; then
					if [ $ow -eq 1 ] ; then
						soffice  --headless --invisible --convert-to png "${dirn}/${file}" --outdir $tmpdir/
						convert -thumbnail x${res_pdf} -background white -alpha remove $tmpdir/"${file%.*}.png"[0] ${dirn}/.thumbs/${file}.jpg && mv ${dirn}/.thumbs/${file}.jpg ${dirn}/.thumbs/${file}; # the colon before the filename is necessary, otw. command fails if filename contains a colon...
					else
						echo "$(basename $0) : thumbnail for ${dirn}/${file} already exists - is not overwritten..."
					fi
				else
						soffice  --headless --invisible --convert-to png "${dirn}/${file}" --outdir $tmpdir/
						convert -thumbnail x${res_pdf} -background white -alpha remove $tmpdir/"${file%.*}.png"[0] ${dirn}/.thumbs/${file}.jpg && mv ${dirn}/.thumbs/${file}.jpg ${dirn}/.thumbs/${file}; # the colon before the filename is necessary, otw. command fails if filename contains a colon...
				fi	
		else
			if [ -f ${dirn}/.thumbs/${file} ] ; then
				if [ $ow -eq 1 ] ; then
					convert ${dirn}/${file} -thumbnail ${res_img} ${dirn}/.thumbs/${file}
				else
					echo "$(basename $0) : thumbnail already exists - is not overwritten..."
				fi
			else
				convert ${dirn}/${file} -thumbnail ${res_img} ${dirn}/.thumbs/${file}
			fi
		fi
		img=1;
		break;
	fi	
done

## done
#if [ $img -eq 0 ] ; then
	#echo "$(basename $0) : ...is no image file."
#fi


