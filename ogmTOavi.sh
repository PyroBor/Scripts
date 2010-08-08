#!/bin/bash
in_dir="$(pwd)"
out_dir="$in_dir.avi"
IKNOWWHATIMDOING="no"

USAGE="
Transforms *.ogm in one dir to *.avi files.
USAGE:
in [] you can see the default settings:
--in-dir <path>\t Folder of ogm files [$in_dir]
--out-dir <path>\t\t Folder of avi files [$out_dir]
 -y, --i-know-what-i-am-doing \t Just do it! [$IKNOWWHATIMDOING]
-h, --help \t Shows this help.
"
# if [[ -z "$1" ]]; then echo -e "$USAGE"; exit 0; fi # 1) no params
while [[ "$1" == -* ]] # 2) params
do
case "$1" in
 	"-y"|"--i-know-what-i-am-doing")
		 IKNOWWHATIMDOING="yes"
	;;
	"--in-dir")
		in_dir="$2"
		shift
	;;
	"--out-dir")
		out_dir="$2"
		shift
	;;
	"-h"|"--help"|*)
		echo -e "$USAGE"
		exit 0
	;;
	esac
	shift
done


if [[ $IKNOWWHATIMDOING == "no" ]]; then echo -e "$USAGE"; exit 42; fi

mkdir $out_dir
cd $in_dir
for ogmfile in *; do
	avi_file="$(basename "$ogmfile" .ogm).avi"
	mencoder "$ogmfile" -oac mp3lame -lameopts vbr=0:q=4:mode=0 -srate 48000 -of avi -ovc copy -mc 0 -noskip -o "$out_dir/$avi_file"
done