scrpt="$1"
scrptname=$(basename "$scrpt")
if ! pgrep -f "${scrpt}" > /dev/null ; then 
	echo "[${scrptname} : no instance is running (0)]"
	rm -f $HOME/.${scrptname}.lock
	${scrpt}
elif [ ! -f $HOME/.${scrptname}.lock ] ; then
	echo "[${scrptname} : no instance is running (1)]"
	for i in $(pgrep -f "${scrpt}") ; do 
		kill -9 $i
	done
	${scrpt}
else
	echo "[${scrptname} : an instance is running]"
	if [ ${scrptname} = "getgps.sh" ] ; then
		if [ -f $HOME/.${scrptname}.lock ] ; then
			t0=$(stat -c %Y $HOME/.${scrptname}.lock);
			t1=$(date +%s);
			dt=$(echo "$t1 - $t0" | bc -l);		
			echo "[${scrptname} : ...running since $dt seconds.]"	
			if [ $dt -gt 900 ] ; then
				echo "[${scrptname} : $HOME/.${scrptname}.lock file is old... deleting it.]"
				killall -9 termux-location
				killall -9 ${scrptname}
				for i in $(pgrep -f "${scrpt}") ; do 
					kill -9 $i
				done
				rm -f $HOME/.${scrptname}.lock
			fi			
		fi
		exit 1
	fi
fi
