#!/bin/bash
bukla_path="/home/bor/tmp/bukla"
sha () { openssl dgst -sha512 "$@" | cut -d" " -f2; }
cd $(dirname $0)
function get_source {
local src_url=$1
	n_of_src_urls="${#src_url[@]}"
	x=0
	until [[ "$x" -gt $n_of_src_urls ]]; do
		if [[ -f $SOURCE ]]; then
			wget -q -c -t 2 -T 20 --passive-ftp --limit-rate=800k "${src_url[$x]}"
		else
		 	wget -q -t 2 -T 20 --passive-ftp --limit-rate=800k "${src_url[$x]}"
		fi
		let x++
	done
}


CTAN_URL[0]="ftp://tug.ctan.org/tex-archive"
CTAN_URL[1]="ftp://ctan.unsw.edu.au/tex-archive"
CTAN_URL[2]="ftp://mirror.aarnet.edu.au/pub/tex-archive"
SOURCEFORGE_URL="http://sourceforge.net/"

grepfind=$(grep -R -x -E "[[:space:]]*MD5\[[0-9]\]=[0-9,a-Z]*[[:space:]]*" $bukla_path | sed -r "s,[[:space:]]*MD5\[([0-9])\]=[0-9,a-Z]*[[:space:]]*,\1 ,g")


for detail_file_md5 in $grepfind; do
detail_file=$(cut -d":" -f1 <<< $detail_file_md5)
md5_no=$(cut -d":" -f2 <<< $detail_file_md5)
# echo $detail_file
# echo $md5_no
# source $detail_file &>/dev/null
sed -r "/(^| )(if|fi|else)( |$)/d" $detail_file > tmpfile
source tmpfile &>/dev/null
# echo $SOURCE
# echo $SOURCE_URL
case $md5_no in
	0) [[ $MD5 != "IGNORE" ]] && [[ $SOURCE_IGNORE != "volatile" ]] && get_source "$SOURCE_URL"
		 if [[ ! -f $SOURCE ]] ; then
			echo "0 ERROR downloading: $SOURCE from $SOURCE_URL"
		else
			echo "0 $SOURCE DOWNLOADED"
		fi
	;;
# 	echo "$SPELL -> ${SOURCE_URL[@]}"
	1) [[ $SOURCE2_URL != "" ]] && [[ $SOURCE2_IGNORE != "volatile" ]] && get_source "$SOURCE2_URL"; if [[ ! -f $SOURCE2 ]] ; then echo "ERROR downloading: $SOURCE2 from $SOURCE2_URL"; else echo "$SOURCE2 DOWNLOADED"; fi
	;;
	2) [[ $SOURCE3_URL != "" ]] && [[ $SOURCE3_IGNORE != "volatile" ]] && get_source "$SOURCE3_URL"; if [[ ! -f $SOURCE3 ]] ; then echo "ERROR downloading: $SOURCE3 from $SOURCE3_URL"; else echo "$SOURCE3 DOWNLOADED"; fi
	;;
	3) [[ $SOURCE4_URL != "" ]] && [[ $SOURCE4_IGNORE != "volatile" ]] && get_source "$SOURCE4_URL"; if [[ ! -f $SOURCE4 ]] ; then echo "ERROR downloading: $SOURCE4 from $SOURCE4_URL"; else echo "$SOURCE4 DOWNLOADED"; fi
	;;
	4) [[ $SOURCE5_URL != "" ]] && [[ $SOURCE5_IGNORE != "volatile" ]] && get_source "$SOURCE5_URL"; if [[ ! -f $SOURCE5 ]] ; then echo "ERROR downloading: $SOURCE5 from $SOURCE5_URL"; else echo "$SOURCE5 DOWNLOADED"; fi
	;;
	5) [[ $SOURCE6_URL != "" ]] && [[ $SOURCE6_IGNORE != "volatile" ]] && get_source "$SOURCE6_URL"; if [[ ! -f $SOURCE6 ]] ; then echo "ERROR downloading: $SOURCE6 from $SOURCE6_URL"; else echo "$SOURCE6 DOWNLOADED"; fi
	;;
	6) [[ $SOURCE7_URL != "" ]] && [[ $SOURCE7_IGNORE != "volatile" ]] && get_source "$SOURCE7_URL"; if [[ ! -f $SOURCE7 ]] ; then echo "ERROR downloading: $SOURCE7 from $SOURCE7_URL"; else echo "$SOURCE7 DOWNLOADED"; fi
	;;
	7) [[ $SOURCE8_URL != "" ]] && [[ $SOURCE8_IGNORE != "volatile" ]] && get_source "$SOURCE8_URL"; if [[ ! -f $SOURCE8 ]] ; then echo "ERROR downloading: $SOURCE8 from $SOURCE8_URL"; else echo "$SOURCE8 DOWNLOADED"; fi
	;;
	8) [[ $SOURCE9_URL != "" ]] && [[ $SOURCE9_IGNORE != "volatile" ]] && get_source "$SOURCE9_URL"; if [[ ! -f $SOURCE9 ]] ; then echo "ERROR downloading: $SOURCE9 from $SOURCE9_URL"; else echo "$SOURCE9 DOWNLOADED"; fi
	;;
	*) echo "what???";;
esac

# 	echo "no ERROR"
#  	sha512=$(sha $SOURCE)
#  	sed -r -i "s,[[:space:]]*MD5\[([0-9])\]=[0-9,a-Z]*[[:space:]]*,SOURCE\1_HASH=sha512:$sha512" $detail_file



unset SPELL SOURCE_URL SOURCE WEB_SITE ENTERED LICENSE KEYWORDS SHORT SOURCE_DIRECTORY VERSION SOURCE_IGNORE MD5 x SOURCE2 SOURCE3 SOURCE4 SOURCE5 SOURCE6 SOURCE7 SOURCE8 SOURCE9 SOURCE2_URL SOURCE3_URL SOURCE4_URL SOURCE5_URLSOURCE3_URL SOURCE5_URL SOURCE6_URL SOURCE7_URL SOURCE8_URL SOURCE9_URL

done