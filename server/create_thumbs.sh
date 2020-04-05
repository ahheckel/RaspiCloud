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
function pic_thumb {
        convert ${dirn}/${file} -thumbnail ${res_img} ${dirn}/.thumbs/${file}
}
function vid_thumb {
		ss=10 ; vdur=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${dirn}/${file}" | cut -d . -f 1)
		if [ $vdur -lt 12 ] ; then ss=1 ; else ss=10 ; fi
		ffmpeg -an -ss $ss -i "${dirn}/${file}" -vframes 1 -vf "scale=-1:${res_img}" -f image2 $tmpdir/t.jpg
		mv $tmpdir/t.jpg ${dirn}/.thumbs/${file} &>/dev/null
}
function doc_thumb {
		soffice  --headless --invisible --convert-to png "${dirn}/${file}" --outdir $tmpdir/
		#convert -thumbnail x${res_pdf} -background white -alpha remove :$tmpdir/"${file%.*}.png"[0] ${dirn}/.thumbs/${file}.jpg && mv ${dirn}/.thumbs/${file}.jpg ${dirn}/.thumbs/${file}; # the colon before the filename is necessary, otw. command fails if filename contains a colon...
		convert -thumbnail x${res_pdf} -background white -alpha remove $tmpdir/"${file%.*}.png"[0] ${dirn}/.thumbs/${file}.jpg && mv ${dirn}/.thumbs/${file}.jpg ${dirn}/.thumbs/${file}; # under raspbian buster, the colon leads to error
}
function pdf_thumb {
		#convert -thumbnail x${res_pdf} -background white -alpha remove :${dirn}/${file}[0] ${dirn}/.thumbs/${file}.jpg && mv ${dirn}/.thumbs/${file}.jpg ${dirn}/.thumbs/${file}; # the colon before the filename is necessary, otw. command fails if filename contains a colon...
		convert -thumbnail x${res_pdf} -background white -alpha remove ${dirn}/${file}[0] ${dirn}/.thumbs/${file}.jpg && mv ${dirn}/.thumbs/${file}.jpg ${dirn}/.thumbs/${file}; # under raspbian buster, the colon leads to error
}

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
# <!-- ENTRY01 -->
for j in jpeg jpg png gif webp tif tiff psd bmp pdf doc ppt xls docx pptx xlsx txt pps ppsx jfif odt avi wmv mp4 3gp ; do 
#for j in jpeg jpg png gif webp tif tiff psd bmp pdf jfif ; do # because of libreoffice convert bug
	if [ x"$ext" == "x${j}" ] ; then
		echo "$(basename $0) : creating thumbnail for ${dirn}/${file}..."
		if [ ${j} == "pdf" ] ; then
			if [ -f ${dirn}/.thumbs/${file} ] ; then
				if [ $ow -eq 1 ] ; then
					pdf_thumb
				else
					echo "$(basename $0) : thumbnail for ${dirn}/${file} already exists - is not overwritten..."
				fi
			else
				pdf_thumb
			fi
		# <!-- ENTRY02 -->
		elif [[ ${j} == +(doc|ppt|xls|docx|pptx|xlsx|txt|pps|ppsx|odt) ]] ; then
				if [ -f ${dirn}/.thumbs/${file} ] ; then
					if [ $ow -eq 1 ] ; then
						doc_thumb
					else
						echo "$(basename $0) : thumbnail for ${dirn}/${file} already exists - is not overwritten..."
					fi
				else
					doc_thumb
				fi
		# <!-- ENTRY03 -->		
		elif [[ ${j} == +(mp4|avi|wmv|3gp) ]] ; then
				if [ -f ${dirn}/.thumbs/${file} ] ; then
					if [ $ow -eq 1 ] ; then
						vid_thumb
					else
						echo "$(basename $0) : thumbnail for ${dirn}/${file} already exists - is not overwritten..."
					fi
				else
				    vid_thumb
				fi	
		else
			if [ -f ${dirn}/.thumbs/${file} ] ; then
				if [ $ow -eq 1 ] ; then
					pic_thumb
				else
					echo "$(basename $0) : thumbnail already exists - is not overwritten..."
				fi
			else
				pic_thumb
			fi
		fi
		img=1;
		break;
	fi	
done

## done
#if [ $img -eq 0 ] ; then
	#echo "$(basename $0) : ...is not to be processed."
#fi


