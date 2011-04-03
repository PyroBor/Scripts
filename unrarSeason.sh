#!/bin/bash
#---
## by Bor Kraljič <pyrobor[at]ver[dot]si>
## Licence is GPL v2 or higher
#---

season_folder="$(pwd)"
target_folder="$season_folder-avi"
delrarfiles="no"
IKNOWWHATIMDOING="no"

USAGE="USAGE: [OPTIONS]:
in [] you can see the default settings:
--season-folder <path/to/season/>\t Unrar files [$season_folder]
--target-folder <path/to/season/>\t extract them to [$target_folder]
--del-rars <yes/no>\t\t Delete rar files after unraring [$delrarfiles]
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
	"--season-folder")
		season_folder="$2"
		shift
	;;
		"--target-folder")
		target_folder="$2"
		shift
	;;
	"--del-rars")
		delrarfiles="yes"
	;;
	"-h"|"--help"|*)
		echo -e "$USAGE"
		exit 0
	;;
	esac
	shift
done


if [[ $IKNOWWHATIMDOING == "no" ]]; then echo -e "$USAGE"; exit 42; fi

mkdir -p "$target_folder"
cd "$season_folder"
for rar_folder in *; do
	if [[ -d $rar_folder ]] ; then
		cd "$rar_folder"
# 		return_sfv="0"
# 		if [[ $sfv == "yes" ]] ; then
# 			sfv_file=$(ls *.sfv | head -n 1)
# 			cksfv -q -f $sfv_file
# 			return_sfv=$?
# 		fi
 		one_rar_file=$(ls *.rar | head -n 1)
# 		[[ $return_sfv == "0" ]] &&
		unrar e "$one_rar_file" "$target_folder" &> /dev/null && unrar_return="$?"
# 		echo "$rar_folder"
# 		echo "$one_rar_file"
		cd ..
		if [[ $delrarfiles == "yes" ]] && [[ $unrar_return == "0" ]]; then
			rm -rf "$rar_folder"
		fi
	fi
done

