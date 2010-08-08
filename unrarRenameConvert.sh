#!/bin/bash
ripper="0tv|lol|aaf"
flags="dvdrip|repack|proper|-|xvid|iNTERNAL|rerip|hdtv"
#wanted_dir="/home/bor/video/Arrested.Development.S01.DVDRip.XviD-MEDiEVAL"
wanted_dir="$HOME"
ogmtoavi="no"
unrarfiles="no"
renamefiles="yes"
delrarfiles="no"
sfv="no"
del_nfo="no"

# colors
E="\e[0m" # end
Y="\e[33;1m"
R="\e[31;1m"
G="\e[32;1m"
B="\e[34;1m"

USAGE="${Y}USAGE: $0 [OPTIONS]:$E
in [] you can see the default settings:
${Y}--ripper <name>$E\t\t Define the ripper [${B}$ripper$E]
${Y}--wanted-dir <PATH>$E\t Dir of the release [${B}$wanted_dir$E]
${Y}--ogm-to-avi <yes/no>$E\t Conversion of ogm files to avi [${B}$ogmtoavi$E]
${Y}--del-nfo <yes/no>$E\t Delete the NFO file [${B}$del_nfo$E]
${Y}--unrar-files <yes/no>$E\t Unrar files [${B}$unrarfiles$E]
${Y}--del-rars <yes/no>$E\t Delete rar files after unraring [${B}$delrarfiles$E]
${Y}--sfv-check <yes/no>$E\t Do you want to perform sfc check of the rars [${B}$sfv$E]
"

while [[ "$1" == -* ]] # 2) params
do
case "$1" in
	"--ripper")
		ripper=$2
# 		shift # an extra shift is needed since we use two parameters
	;;
	"--wanted-dir")
		wanted_dir=$2
	;;
	"--ogm-to-avi")
		ogmtoavi=$2
	;;
	"--unrar-files")
		unrarfiles=$2
	;;
	"--del-rars")
		delrarfiles=$2
		;;
	"--del-nfo")
		del_nfo=$2
	;;
	"--sfv-check")
		sfv=$2
	;;
	"-h"|"--help"|*)
		echo -e "$USAGE"
		exit 0
	;;
	esac
	shift
done


if [[ $unrarfiles == "yes" ]] ; then
	season_folder="$wanted_dir"
	target_folder="$wanted_dir"
	cd "$season_folder"
	for rar_folder in *; do
		if [[ -d $rar_folder ]] ; then
			cd "$rar_folder"
# 			return_sfv="0"
# 			if [[ $sfv == "yes" ]] ; then
# 				sfv_file=$(ls *.sfv | head -n 1)
# 				cksfv -q -f $sfv_file
# 				return_sfv=$?
#  			fi
 			one_rar_file=$(ls *.rar | head -n 1)
# 			[[ $return_sfv == "0" ]] &&
			unrar e "$one_rar_file" "$target_folder" &> /dev/null && unrar_return="$?"
#  			echo "$rar_folder"
#  			echo "$one_rar_file"
			cd ..
			if [[ $delrarfiles == "yes" ]] ; then
				[[ $return_sfv == "0" ]] &&  [[ $unrar_return == "0" ]] && rm -rf "$rar_folder"
			fi
		fi
	done
	cd
fi


if [[ $renamefiles == "yes" ]] ; then
	cd "$wanted_dir"
	for oldname in *.avi *.ogm *.srt; do
		newname=$(sed -r -e "s/(S|s)?([0-9][0-9]?)(E|e|x|X)?([0-9][0-9]?)?/\2\4/" -e "s/\.0([0-9]{3})/\.\1/" -e "s/(\.|_)/ /g" -e "s/ (avi$)| (ogm$)|(srt$)/\.\1\2\3/" -e "s/($flags)//gi" -e "s/($ripper)//gi" -e "s/([a-z]{2,})/\u\1/g" -e "s/(\.Avi$)|(\.Ogm)|(\.Srt)/\L\1\2\3\E/" -e "s/\ {2,}/\ /g" -e "s/ \./\./g"  <<< "$oldname")
# 		newname=$(sed -r -e "s/(S|s)([0-9]{0,2})(E|e)([0-9]{0,2})/\2\4/" \  # da izločimo s in S pred
# 			-e "s/\.([^a])/ \1/g" \  # Znebimo se pik
# 			-e "s/($flags)//g" \  # Brezvezne oznake
# 			-e "s/($ripper)//g" \  # ne rabmo vedt kdo je ripper
# 			-e "s/([a-z]+)/\u\1/g" -e "s/\.Avi$/\.avi/" \  # Da se vsaka beseda zveliko začne razn pri .avi
# 			-e "s/\ \ /\ /g" -e "s/ \./\./g"  <<< $oldname)  # še skenslamo dvojne presledke in presledek pred piko od .avi
#		  j=$(echo $i|sed 's/\.txt/\.bmp/')
# 		echo $oldname
# 		echo $newname
		mv "$oldname" "$newname"
# 	
	done
	cd
fi

if [[ $del_nfo == "yes" ]]; then
	cd "$wanted_dir"
	rm *.nfo
	cd
fi

if [[ $ogmtoavi == "yes" ]]; then
	in_dir="$wanted_dir"
	out_dir="$in_dir.avi"
	mkdir "$out_dir"
	cd "$in_dir"
	for ogmfile in *; do
		avi_file="$(basename "$ogmfile" .ogm).avi"
		mencoder "$ogmfile" -oac mp3lame -lameopts vbr=0:q=4:mode=0 -srate 48000 -of avi -ovc copy -mc 0 -noskip -o "$out_dir/$avi_file"
	done
	cd
fi
